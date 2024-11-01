//
//  LocationManager.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager: CLLocationManager = CLLocationManager()
    let settings: Settings
    
    init(settings: Settings) {
        self.settings = settings

        super.init()
        self.manager.delegate = self
        
        self.manager.requestWhenInUseAuthorization()
    }
    
    @MainActor
    private func enableLocationFeatures() {
        self.settings.locationEnabled = true
    }
    
    @MainActor
    private func disableLocationFeatures() {
        self.settings.locationEnabled = false
    }
    
    @MainActor
    public func updateCurrentLocation() {
        if self.settings.locationEnabled == true {
            Task.detached {
                self.manager.requestLocation()
            }
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            Task { @MainActor in
                settings.latitude = location.coordinate.latitude
                settings.longitude = location.coordinate.longitude
                
                settings.coordinates = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if let error = error as? CLError, error.code == CLError.Code.denied {
            manager.stopUpdatingLocation()
            Task { @MainActor in
                
                self.settings.locationEnabled = false
            }
        }
        else if let error = error as? CLError {
            print(error.localizedDescription)
        }
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            Task { @MainActor in
                
                enableLocationFeatures()
            }
            break
            
        case .restricted, .denied:  // Location services currently unavailable.
            Task { @MainActor in
                
                disableLocationFeatures()
            }
            break
            
        case .notDetermined:        // Authorization not determined yet.
           manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }

}
