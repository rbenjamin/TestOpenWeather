//
//  WeatherManager.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation
import Combine
import CoreLocation
import Contacts
import SwiftData

@MainActor
class WeatherManager: NSObject, ObservableObject {
    let settings: Settings
    /// Currently required for pressure readings: Need number formatter to get 2 decimals in inHG and mmHG.
    let pressureFormatter: MeasurementFormatter
    let percentFormatter: NumberFormatter
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    let locationManager: LocationManager
    let downloadManager = DownloadManager()
    lazy var geocoder = CLGeocoder()
    lazy var postalFormatter = CNPostalAddressFormatter()
    var coordinateSink: AnyCancellable?
    var selectedMarkSink: AnyCancellable?
    var locationsEnabledSink: AnyCancellable?
    var mainContext: ModelContext?
    @Published var previouslyRetrievedGPS: CLLocation?
    @Published var selectedPlacemark: CLPlacemark?
    @Published var currentWeatherLocation: WeatherLocation?
    @Published var gpsWeatherLocation: WeatherLocation?
    @Published var dataErrorType: WeatherDataType?
    @Published var gpsButtonDisabled: Bool = false
    @Published var databaseError: DatabaseError?
    @Published var downloadError: DownloadError?

    var error: LocalizedError? {
        didSet {
            if let dbError = error as? DatabaseError {
                self.databaseError = dbError
                NotificationCenter.default.post(name: .databaseError, object: nil /*db*/)
            } else if let dlError = error as? DownloadError {
                self.downloadError = dlError
                NotificationCenter.default.post(name: .downloadError, object: nil /*db*/)
            }
        }
    }
    /// Called by `LocationsList` when the user sets the current weather view to the current GPS position, rather than a searched location.
    ///
    @MainActor
    func loadCurrentLocation() {
        if let gpsWeatherLocation {
            self.currentWeatherLocation = gpsWeatherLocation
        } else {
            #if DEBUG
            fatalError("WeatherManager.gpsWeatherLocation == nil:  gpsWeatherLocation should be set!")
            #else
            print("WeatherManager.gpsWeatherLocation == nil:  gpsWeatherLocation should be set!")
            #endif
        }
    }

    /// `updateFromExisting(_:)` is called when user changes locations manually.
    ///
    /// - Updates the current weather view with an existing location that isn't the user's current coordinates.
    /// - Updates the default weather view shown in `Settings`, so if the user leaves the app this weather location
    ///   is used as a default.
    /// - Downloads fresh weather data for the picked location.
    ///

    func updateFromExisting(_ existing: WeatherLocation) {
#if DEBUG
        precondition(mainContext != nil, "MainContext == nil!  Cannot update from existing.")
#endif
        self.currentWeatherLocation = existing
        if existing.persistentModelID == settings.gpsLocationObjectID {
            self.gpsWeatherLocation = existing
        }
    }

    /// Called after user picks a CLPlacemark when adding a new location.  Called by `selectedMarkSink` `sink()` in init.
    /// Downloads fresh weather data for the location and updates the existing WeatherLocation object.
    ///
    func loadDataUpdateExisting(_ placemark: CLPlacemark, existing: WeatherLocation) {
        guard let location = placemark.location else { return }

        existing.lastUpdated = Date()
        existing.setLocation(location)
        existing.gpsLocation = false
        if existing.locationName == nil && placemark.name != nil {
            existing.locationName = placemark.name
        }
    }

    func updateGPSLocation() {
        if self.settings.locationEnabled == true {
            self.gpsButtonDisabled = true
            let success = self.locationManager.updateCurrentLocation()
            if !success {
                self.gpsButtonDisabled = false
            }
        } else if self.settings.locationEnabled == nil {
            self.locationManager.requestAuthorization()
        }
    }

    /// Load default location and GPS location (if available)
    @MainActor
    func beginUpdatingWeather(userReload: Bool = false) {

        guard self.currentWeatherLocation == nil else {
            return
        }
        // First load exising default -- may be
        if let existingDefault = settings.defaultLocation(context: self.mainContext) {
                self.currentWeatherLocation = existingDefault
        }
        guard let gpsDefault = settings.gpsLocation(context: self.mainContext) else {
            self.updateGPSLocation()
            return
        }
        if self.currentWeatherLocation == nil {
            self.currentWeatherLocation = gpsDefault
            self.gpsWeatherLocation = gpsDefault
        } else {
            self.gpsWeatherLocation = gpsDefault
        }
        self.updateGPSLocation()
    }

    init(locationManager: LocationManager) {
        self.settings = Settings.shared
        self.locationManager = locationManager
        // Setup measurement formatter
        self.pressureFormatter = Measurement.pressureFormatter
        self.percentFormatter = NumberFormatter.percentFormatter
        super.init()

        /// Track when location services are enabled: Especially for first launch, we need to be able to see when the user has approved location services, so we can pull the coordinate.
        locationsEnabledSink = self.settings.$locationEnabled.sink(receiveValue: { newValue in
            if self.settings.locationEnabled == nil && newValue == true {
                self.gpsButtonDisabled = true
                let success = self.locationManager.updateCurrentLocation()
                if !success {
                    self.gpsButtonDisabled = false
                }
            } else if self.settings.locationEnabled == false && newValue == true {
                let success = self.locationManager.updateCurrentLocation()
                if !success {
                    self.gpsButtonDisabled = false
                }
            }
        })

        /// Track when the user has changed the location from the current (coordinate) weather to a saved weather location.
        selectedMarkSink = self.$selectedPlacemark.sink(receiveValue: { placemark in
            guard let placemark else { return }
            guard let name = placemark.name else { return }

            var descriptor = FetchDescriptor(predicate: #Predicate<WeatherLocation>{ $0.locationName == name },
                                             sortBy: [SortDescriptor(\WeatherLocation.lastUpdated)])
            descriptor.fetchLimit = 1
            do {
                if let existing = (try self.mainContext?.fetch(descriptor))?.first {
                    self.loadDataUpdateExisting(placemark,
                                                existing: existing)
                    self.updateFromExisting(existing)
                } else {
                    let newLocation = WeatherLocation()
                    self.loadDataUpdateExisting(placemark, existing: newLocation)

                    self.mainContext?.insert(newLocation)
                    try? self.mainContext?.save()

                    self.updateFromExisting(newLocation)
                }
            } catch let error as NSError {
                self.error = DatabaseError.failedFetch(backgroundContext: false, error: error)
                print("error fetching existing locations that match the placemark \(placemark.description): \(error)")
            }

        })
        /// Track when location services has updated Settings with new coordinates for the default weather
        ///
        coordinateSink = self.locationManager.coordinates.sink { [weak self] location in
            guard let `self` = self else { return }
            self.gpsButtonDisabled = false
            // Ensure this is a new location, greater than a mile (in meters) from previous location.
            self.updateFromCLLocation(location: location)
        }
    }

    /// Called when `LocationManager` finishes determining coordinates for the GPS location.
    func updateFromCLLocation(location: CLLocation) {
        if let oldLocation = self.previouslyRetrievedGPS, location.distance(from: oldLocation) < 1609.344 {
            return
        }
        if let gpsLocation = self.gpsWeatherLocation {
            gpsLocation.setLocation(location)
        } else if let first = self.settings.gpsLocation(context: self.mainContext) {
            first.setLocation(location)
            self.gpsWeatherLocation = first
        } else {
            let loc = WeatherLocation()
            loc.lastUpdated = Date()
            loc.setLocation(location)
            loc.gpsLocation = true
            mainContext?.insert(loc)

            Task { [weak self] in
                guard let `self` = self else { return }
                /// Update Location Name:
                do {
                    if let locationName = try await self.geocodeLocation(location) {
                        /// Return to main thread to edit the loc CoreData object:
                        Task { @MainActor in
                            loc.locationName = locationName
//                            self.locationName = locationName

                        }
                    }
                } catch let error {
                    self.error = DownloadError.geocodeFailed(error: error)
                    #if DEBUG
                                    fatalError("Failed to geocode \(error)")
                    #endif
                }
                /// Update the view:
                Task { @MainActor in
                    do {
                        try self.mainContext?.save()
                        /// Update `Settings` gps location to this object
                        self.settings.setGPSLocationObjectID(loc.persistentModelID, encoder: self.encoder)
                        self.settings.setDefaultLocationID(loc.persistentModelID, encoder: self.encoder)

                        self.currentWeatherLocation = loc
                        self.gpsWeatherLocation = loc
                    } catch let error as NSError {
                        self.error = DatabaseError.failedSave(backgroundContext: false, error: error)
        #if DEBUG
                        fatalError("Failed to save main context  \(error)")
        #endif
                    }
                }
            }
        }
        self.previouslyRetrievedGPS = location
    }

    func geocodeLocation(_ location: CLLocation) async throws -> String? {
        let currDate = Date()
        if let prev = self.settings.previousReverseGeocodeDate {
            if prev.distance(to: currDate) < 100 {
                return nil
            }
        }
        do {
            let placemarks = try await self.geocoder.reverseGeocodeLocation(location, preferredLocale: .autoupdatingCurrent)
            if let first = placemarks.first {
                    /// Only update the date if the geocode was a success:
                self.settings.previousReverseGeocodeDate = currDate
                return first.locality
            }
        } catch let error as CLError {
            if error.code.rawValue == CLError.Code.network.rawValue {
                print("Too many Geocode requests - rate limited: \(error)")
            }
            throw DownloadError.geocodeFailed(error: error)
        }
        return nil
    }

    func reverseGeocode(addressString: String)  async throws -> [CLPlacemark] {
        let currDate = Date()
        if let prev = self.settings.previousGeocodeDate {
            if prev.distance(to: currDate) < 5 {
                return []
            }
        }

        do {
            let placemarks = try await self.geocoder.geocodeAddressString(addressString)
            Task { @MainActor in
                self.settings.previousGeocodeDate = currDate
            }
            return placemarks
        } catch let error as CLError {
            let downloadError = DownloadError.geocodeFailed(error: error)
            self.error = downloadError

            let errorCode = error.code
            if errorCode == CLError.Code.network {
                print("Too many Geocode requests - rate limited: \(error)")
            } else if errorCode == CLError.Code.locationUnknown {
                print("Location Unknown: \(error)")
            } else if errorCode == CLError.Code.geocodeFoundNoResult {
                print("Geocoding returned no results!: \(error)")
            } else if errorCode == CLError.Code.geocodeFoundPartialResult {
                print("Geocoding returned partial results!: \(error)")

            } else {
#if DEBUG
            fatalError("Failed to geocode \(addressString): \(error)")
#endif
            }
        }
        return []
    }
}
