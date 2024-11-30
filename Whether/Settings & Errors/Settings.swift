//
//  Settings.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import SwiftData

enum DefaultsKey: String {
    case latitude
    case longitude
    case language
    case units
    case locationEnabled
    case locationLabelName
    case defaultLocationID
    case gpsLocationObjectID
    case previousGeocodeDate
    case previousReverseGeocodeDate
    case previousDownloadDate
    case previousGPSAccessDate
}

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    private let defaults = UserDefaults.standard

//    @AppStorage(DefaultsKey.latitude.rawValue) var latitude: Double?
//    @AppStorage(DefaultsKey.longitude.rawValue) var longitude: Double?
    @AppStorage(DefaultsKey.language.rawValue) var language: String = "EN"
    @AppStorage(DefaultsKey.units.rawValue) var units: String = "standard"
//    @AppStorage(DefaultsKey.locationEnabled.rawValue) var locationEnabled: Bool?
    @AppStorage(DefaultsKey.locationLabelName.rawValue) var locationName: String?
    @AppStorage(DefaultsKey.previousGeocodeDate.rawValue) var previousGeocodeDate: Date?
    @AppStorage(DefaultsKey.previousReverseGeocodeDate.rawValue) var previousReverseGeocodeDate: Date?
    @AppStorage(DefaultsKey.previousDownloadDate.rawValue) var previousDownloadDate: Date?

    @Published var coordinates: CLLocation?

    @Published var previousGPSAccessDate: Date? {
        willSet {
            if newValue != previousGPSAccessDate {
                self.defaults.set(newValue, forKey: DefaultsKey.previousGPSAccessDate.rawValue)
            }
        }
    }

    @Published var locationEnabled: Bool? {
        willSet {
            self.defaults.set(newValue, forKey: DefaultsKey.locationEnabled.rawValue)

        }
    }

    @Published fileprivate(set) var defaultLocationID: PersistentIdentifier?

    func setDefaultLocationID(_ id: PersistentIdentifier, encoder: JSONEncoder) {
        let data = try? encoder.encode(id)
        self.defaults.set(data, forKey: DefaultsKey.defaultLocationID.rawValue)
    }

    @Published fileprivate(set) var gpsLocationObjectID: PersistentIdentifier?

    func setGPSLocationObjectID(_ id: PersistentIdentifier, encoder: JSONEncoder) {
        let data = try? encoder.encode(id)
        self.defaults.set(data, forKey: DefaultsKey.gpsLocationObjectID.rawValue)
    }

    func defaultLocation(context: ModelContext?) -> WeatherLocation? {
        guard let id = self.defaultLocationID, let context else { return nil }
        return context.model(for: id) as? WeatherLocation
    }

    func gpsLocation(context: ModelContext?) -> WeatherLocation? {
        guard let id = self.gpsLocationObjectID, let context else { return nil }
        return context.model(for: id) as? WeatherLocation
    }

    init() {
        /// Set the default coordinates -- allows us to update the location using the most recent location data (if any exists).
        /// LocationManager will update `coordinates` with the most recent location data when `CLLocationManager` finished updating location.

        let decoder = JSONDecoder()

        if let existing = self.defaults.object(forKey: DefaultsKey.locationEnabled.rawValue) as? Bool {
            self.locationEnabled = existing
        }

        if let existingDate = self.defaults.object(forKey: DefaultsKey.previousGPSAccessDate.rawValue) as? Date {
            self.previousGPSAccessDate = existingDate
        }

        if let existing = self.defaults.object(forKey: DefaultsKey.defaultLocationID.rawValue) as? Data {

            do {
                let identifier = try decoder.decode(PersistentIdentifier.self, from: existing)
                self.defaultLocationID = identifier

            } catch let error {
                print("JSONDecoder failed for PersistentIdentifier in UserDefaults (DefaultsKey.defaultLocationID) with error: \(error)")
            }
        }

        if let existing = self.defaults.object(forKey: DefaultsKey.gpsLocationObjectID.rawValue) as? Data {

            do {
                let identifier = try decoder.decode(PersistentIdentifier.self, from: existing)
                self.gpsLocationObjectID = identifier

            } catch let error {
                print("JSONDecoder failed for PersistentIdentifier in UserDefaults (DefaultsKey.gpsLocationObjectID) with error: \(error)")
            }
        }
    }
}
