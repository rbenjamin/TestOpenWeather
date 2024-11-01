//
//  WeatherConnection.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import CoreLocation
import Combine

enum WhetherError: Error {
    case failedURL(String)
    case failedGeocoding(String)
    
    
    var localizedDescription: String {
        switch self {
        case .failedURL(let label):
            return "Failed to resolve URL: \(label)"
        case .failedGeocoding(let label):
            return "Failed to geocode current location: \(label)"
        }
    }
}

enum WeatherUnits: String, CodingKey {
    case standard
    case metric
    case imperial
}

struct NetworkConnection {
    var urlSession = URLSession.shared
    
    func retrieve(location: CLLocation,
                  key: String,
                  language: String? = nil) throws -> AnyPublisher<CurrentWeather, Error> {
       
        
        guard let matchedURL = resolve(location: location, key: key, language: language) else {
#if DEBUG
            fatalError("Failed to resolve URL with \(location) key: \(key)")
#else
            throw WhetherError.failedURL("Failed to resolve URL with \(location) key: \(key)")
#endif
        }
        
        return URLSession.shared.dataTaskPublisher(for: matchedURL)
            .map(\.data)
            .decode(type: CurrentWeather.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()

    }
    
    
    private func resolve(location: CLLocation, key: String, language: String? = nil) -> URL? {
        if let language {
            return URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)&lang=\(language)")
        }
        return URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)")
    }
}
