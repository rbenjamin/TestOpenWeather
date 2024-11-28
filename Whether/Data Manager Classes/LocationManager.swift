//
//  LocationManager.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager: CLLocationManager = CLLocationManager()
    @Published var error: CLError?
    let coordinates = PassthroughSubject<CLLocation, Never>()

    override init() {
        super.init()
        self.manager.delegate = self

    }
    @MainActor
    public func requestAuthorization() {
        self.manager.requestWhenInUseAuthorization()
    }

    @MainActor
    private func enableLocationFeatures() {
        Settings.shared.locationEnabled = true
    }

    @MainActor
    private func disableLocationFeatures() {
        Settings.shared.locationEnabled = false
    }
    /**
     `updateCurrentLocation`
     - Returns: `true` if it has been long enough since the last `request` to make another request.  Otherwise, returns `false`.
     
     
     This function's return value *is not* the success or failure of the underlying `CLLocationManager` request: It only describes whether the user *can make* a request.
     */
    @MainActor
    public func updateCurrentLocation() -> Bool {
        let date = Date()
        if let previous = Settings.shared.previousGPSAccessDate, previous.distance(to: date) < 60 {
            return false
        }

        Task { [weak self] in
            self?.manager.requestLocation()
        }
        return true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            Task { @MainActor in
                let settings = Settings.shared
                settings.latitude = location.coordinate.latitude
                settings.longitude = location.coordinate.longitude
                settings.previousGPSAccessDate = Date()

                settings.coordinates = location
                self.coordinates.send(location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if let error = error as? CLError, error.code == CLError.Code.denied {
            manager.stopUpdatingLocation()
            Task { @MainActor in
                Settings.shared.locationEnabled = false
            }
        } else if let error = error as? CLError {
            print(error.localizedDescription)
            self.error = error
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            Task { @MainActor in
                enableLocationFeatures()
            }
        case .restricted, .denied:  // Location services currently unavailable.
            Task { @MainActor in
                disableLocationFeatures()
            }
        case .notDetermined:        // Authorization not determined yet.
           manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

}
