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

enum WeatherURLType {
    case now(language: String?)
    case forecast(hourly: Bool, language: String?)
    case pollution
}

struct OpenWeatherURLBuilder {

    func retrieve(location: CLLocation,
                  key: String,
                  language: String? = nil) throws -> AnyPublisher<CurrentWeather, Error> {

        guard let matchedURL = Self.resolve(forecast: false, location: location, key: key, language: language) else {
#if DEBUG
            fatalError("Failed to resolve URL with \(location) key: \(key)")
#else
            throw WhetherError.failedURL("Failed to resolve URL with \(location)")
#endif
        }
        return URLSession.shared.dataTaskPublisher(for: matchedURL)
            .map(\.data)
            .decode(type: CurrentWeather.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()

    }
    static func resolve(type: WeatherURLType,
                        key: String,
                        location: CLLocation) throws -> URL? {
        var baseURLStr = "https://api.openweathermap.org/data/2.5/"
        var params = ["lat": "\(location.coordinate.latitude)",
                     "lon": "\(location.coordinate.longitude)",
                     "appid": key]

        switch type {
        case .now(let language):
            baseURLStr.append("weather")
            if let language {
                params["lang"] = language
            }
        case .forecast(let hourly, let language):
            baseURLStr.append("forecast")
            if hourly {
                baseURLStr.append("/hourly")
            }
            if let language {
                params["lang"] = language
            }
        case .pollution:
            baseURLStr.append("air_pollution")
        }
        var comps = URLComponents(string: baseURLStr)
        comps?.queryItems = params.map({ URLQueryItem(name: $0, value: $1) })
        guard let url = comps?.url else {
            throw URLError(.badURL)
        }
        return url
    }

    public static func airQuality(location: CLLocation,
                                  key: String) -> URL? {
        return URL(string: "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)")
    }

    public static func resolve(forecast: Bool,
                               hourly: Bool = false,
                               location: CLLocation,
                               key: String,
                               language: String? = nil) -> URL? {

        let modifier = forecast == true ? "forecast" : "weather"

        if let language {
            if forecast == true && hourly == true {
                return URL(string: "https://api.openweathermap.org/data/2.5/\(modifier)/hourly?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)&lang=\(language)")
            }
            return URL(string: "https://api.openweathermap.org/data/2.5/\(modifier)?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)&lang=\(language)")
        }

        if forecast == true && hourly == true {
            return URL(string: "https://api.openweathermap.org/data/2.5/\(modifier)/hourly?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)")
        }

        return URL(string: "https://api.openweathermap.org/data/2.5/\(modifier)?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(key)")
    }
}
