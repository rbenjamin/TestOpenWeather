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

enum DefaultsKey : String {
    case latitude
    case longitude
    case language
    case units
    case locationEnabled
    case locationLabelName
    
}

@MainActor
class Settings : ObservableObject {
//    static let shared = Settings()
    
    @AppStorage(DefaultsKey.latitude.rawValue) var latitude: Double?
    @AppStorage(DefaultsKey.longitude.rawValue) var longitude: Double?
    @AppStorage(DefaultsKey.language.rawValue) var language: String = "EN"
    @AppStorage(DefaultsKey.units.rawValue) var units: String = "standard"
    @AppStorage(DefaultsKey.locationEnabled.rawValue) var locationEnabled: Bool?
    @AppStorage(DefaultsKey.locationLabelName.rawValue) var locationName: String?

    @Published var coordinates: CLLocation?
  
    
    init() {
        /// Set the default coordinates -- allows us to update the location using the most recent location data (if any exists).
        /// LocationManager will update `coordinates` with the most recent location data when `CLLocationManager` finished updating location.
        if let latitude, let longitude {
            self.coordinates = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
  


}
