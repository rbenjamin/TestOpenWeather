//
//  CurrentWeather.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import CoreFoundation
import CoreLocation
import SwiftUI

public enum WeatherDataType: Int, CustomStringConvertible {
    case now
    case pollution
    case fiveDay

    public var description: String {
        switch self {
        case .now:
            return "Now"
        case .pollution:
            return "Pollution"
        case .fiveDay:
            return "Five Day"
        }
    }
}

protocol WeatherIDEnum: RawRepresentable where RawValue == Int {
    var stringLabel: String { get }
}

protocol WeatherData: Identifiable, Codable, Equatable, Hashable {}

typealias MainWeather = CurrentWeather.MainWeather

typealias WeatherConditions = CurrentWeather.WeatherConditions

struct CurrentWeather: WeatherData, Identifiable, Codable, Hashable, Equatable {

    public static func == (lhs: CurrentWeather, rhs: CurrentWeather) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case timeZone = "timezone"
        case position = "coord"
        case conditions = "weather"
        case mainWeather = "main"
        case wind = "wind"
        case clouds = "clouds"
        case rain = "rain"
        case snow = "snow"
        case visibility = "visibility"
        case system = "sys"
        case code = "cod"
    }

    let id: UUID = UUID()

    let position: CurrentWeather.Position
    let conditions: [WeatherConditions]
    let mainWeather: MainWeather
    let wind: Wind?
    let clouds: Clouds?
    let rain: Rain?
    let snow: Snow?
    let visibility: Double
    let system: CurrentWeather.System
    let timeZone: Double
    let code: Double

    init(position: CurrentWeather.Position,
         conditions: [WeatherConditions],
         mainWeather: MainWeather,
         wind: Wind,
         clouds: Clouds,
         rain: Rain,
         snow: Snow,
         visibility: Double,
         system: CurrentWeather.System,
         timeZone: Double,
         code: Double) {
        self.position = position
        self.conditions = conditions
        self.mainWeather = mainWeather
        self.wind = wind
        self.clouds = clouds
        self.rain = rain
        self.snow = snow
        self.visibility = visibility
        self.system = system
        self.timeZone = timeZone
        self.code = code
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timeZone = try container.decode(Double.self, forKey: .timeZone)
        self.position = try container.decode(CurrentWeather.Position.self, forKey: .position)
        let conditions = try container.decode(Array<WeatherConditions>.self, forKey: .conditions)

        self.conditions = conditions
        self.mainWeather = try container.decode(CurrentWeather.MainWeather.self, forKey: .mainWeather)
        self.wind = try container.decodeIfPresent(CurrentWeather.Wind.self, forKey: .wind)
        self.clouds = try container.decodeIfPresent(CurrentWeather.Clouds.self, forKey: .clouds)
        self.rain = try container.decodeIfPresent(CurrentWeather.Rain.self, forKey: .rain)
        self.snow = try container.decodeIfPresent(CurrentWeather.Snow.self, forKey: .snow)
        self.visibility = try container.decode(Double.self, forKey: .visibility)
        self.system = try container.decode(CurrentWeather.System.self, forKey: .system)
        self.code = try container.decode(Double.self, forKey: .code)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.timeZone, forKey: .timeZone)
        try container.encode(self.position, forKey: .position)
        try container.encode(self.conditions, forKey: .conditions)
        try container.encode(self.mainWeather, forKey: .mainWeather)
        try container.encode(self.wind, forKey: .wind)
        try container.encode(self.clouds, forKey: .clouds)
        try container.encode(self.rain, forKey: .rain)
        try container.encode(self.snow, forKey: .snow)
        try container.encode(self.visibility, forKey: .visibility)
        try container.encode(self.system, forKey: .system)
        try container.encode(self.code, forKey: .code)
    }

    // MARK: - Decoding from Data -
    public static func decodeWithData(_ data: Data?, decoder: JSONDecoder? = .init()) async throws -> CurrentWeather? {
        guard let data else {
            print("WeatherManager.decodeWeather(_:) failed - `data` is nil.")
            return nil
        }
        decoder?.dateDecodingStrategy = .secondsSince1970
        do {
            return (try decoder!.decode(CurrentWeather.self, from: data))
        } catch let error {
            throw error
        }
    }
    /// `Modifiers` converts degrees Kelvin into an enum.
    /// Used for design calculations, not user-visible data.
    ///
    enum ConditionModifier: Int, CaseIterable {
        case hot
        case normal
        case cold

        var localizedString: String {
            switch self {
            case .hot: return "hot"
            case .normal: return "normal"
            case .cold: return "cold"
            }
        }

        init(temperature: Double) {
            if (0 ..< 288.15) ~= (temperature) {
                self = .cold
            } else if (288.15 ..< 298.15) ~= (temperature) {
                self = .normal
            } else {
                self = .hot
            }
        }
    }

    func backgroundColor(daytime: Bool) -> Color {
        if daytime {
            return WeatherMeshColors
                .clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.converted(to: .kelvin).value))
                    .backgroundFillColor
        }
        return WeatherMeshColors
                .clearSkyNight(ConditionModifier(temperature: self.mainWeather.feelsLike.converted(to: .kelvin).value))
                .backgroundFillColor

    }

    func backgroundUIColor(daytime: Bool) -> UIColor {
        if daytime {
            return WeatherMeshColors
                    .clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.converted(to: .kelvin).value))
                    .backgoundFillUIColor

        }
        return WeatherMeshColors
                .clearSkyNight(ConditionModifier(temperature: self.mainWeather.feelsLike.converted(to: .kelvin).value))
                .backgoundFillUIColor

    }

    /**
        Position corresponds to OpenWeather API key _"coord"_ which contains the latitude and longitude of the weather position.
     */
    struct Position: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        let id = UUID()
        let longitude: CLLocationDegrees
        let latitude: CLLocationDegrees
        var coordinates: CLLocation

        var description: String {
            return """
                   Position:
                   --------------------------------
                   latitude: \(latitude) longitude: \(longitude)
                   --------------------------------
                   """

        }

        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitude = "lat"
        }

        init(longitude: CLLocationDegrees, latitude: CLLocationDegrees) {
            self.longitude = longitude
            self.latitude = latitude
            self.coordinates = CLLocation(latitude: latitude, longitude: longitude)

        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.latitude = try container.decode(CLLocationDegrees.self, forKey: CodingKeys.latitude)
            self.longitude = try container.decode(CLLocationDegrees.self, forKey: CodingKeys.longitude)
            self.coordinates = CLLocation(latitude: self.latitude, longitude: self.longitude)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.longitude, forKey: CodingKeys.longitude)
            try container.encode(self.latitude, forKey: CodingKeys.latitude)
        }
    }
}
