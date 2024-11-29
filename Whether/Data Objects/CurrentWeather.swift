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

protocol WeatherIDEnum {
    var stringLabel: String { get }
}

protocol WeatherData: Identifiable, Codable, Equatable, Hashable {}

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
                    .clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.value))
                    .backgroundFillColor
        }
        return WeatherMeshColors
                .clearSkyNight(ConditionModifier(temperature: self.mainWeather.feelsLike.value))
                .backgroundFillColor

    }

    func backgroundUIColor(daytime: Bool) -> UIColor {
        if daytime {
            return WeatherMeshColors
                    .clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.value))
                    .backgoundFillUIColor

        }
        return WeatherMeshColors
                .clearSkyNight(ConditionModifier(temperature: self.mainWeather.feelsLike.value))
                .backgoundFillUIColor

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

    public static func decodeWithData(_ data: Data?, decoder: JSONDecoder? = .init()) async throws -> CurrentWeather? {
        guard let data else {
            print("WeatherManager.decodeWeather(_:) failed - `data` is nil.")
            return nil
        }

        do {
            return (try decoder!.decode(CurrentWeather.self, from: data))
        } catch let error {
            throw error
        }
    }

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

extension CurrentWeather.Snow {

    /// Snow Density
    enum SnowDensity: CaseIterable {
        case light
        case medium
        case heavy
        case extreme

        var localizedString: String {
            switch self {
            case .light: return "light"
            case .medium: return "medium"
            case .heavy: return "heavy"
            case .extreme: return "extreme"
            }
        }

        init(forecast: Measurement<UnitLength>) {
           // Ensure we're in mm/h
            let snowDensity = forecast.converted(to: .millimeters).value
            if (0.01 ..< 1.0).contains(snowDensity) {
                self = .light
            } else if (1.0 ..< 2.5).contains(snowDensity) {
                self = .medium
            } else if (2.5 ..< 5.0).contains(snowDensity) {
                self = .heavy
            } else {
                self = .extreme
            }
        }
    }
}

extension CurrentWeather.Wind {
    /// `WindDirection` enumeration normalizes wind direction (in meteorological degrees).  Currently used for internal logic; not used for user-facing data.
    ///

    enum WindDirection: CaseIterable, CustomStringConvertible {
        /// 22.5 degree difference between `WindDirection` cases
        ///
        case north              // 0 deg
        case northNorthEast     // 22.5 deg between north and north-east
        case northEast          // 45 deg
        case eastNorthEast      // 67.5 between east and north-east
        case east               // 90
        case eastSouthEast      // betweeen east and south-east
        case southEast
        case southSouthEast     // betweeen south and south-east
        case south
        case southSouthWest     // between south and south-west
        case southWest
        case westSouthWest      // betweeen west and south-west
        case west
        case westNorthWest      // between west and north-west
        case northWest
        case northNorthWest     // between north and north-west

        var description: String {
            return self.stringLabel
        }
        init(degrees: Double) {
            self = Self.windDirectionForDegrees(degrees)
        }

        static func windDirectionForDegrees(_ degrees: Double) -> WindDirection {
            if (348.75 ... 360.0).contains(degrees) || (0 ..< 11.25).contains(degrees) { return .north
            } else if (11.25 ..< 33.75).contains(degrees) { return .northNorthEast
            } else if (33.75 ..< 56.25).contains(degrees) { return .northEast
            } else if (56.25 ..< 78.75).contains(degrees) { return .eastNorthEast
            } else if (78.75 ..< 101.25).contains(degrees) { return .east
            } else if (101.25 ..< 123.75).contains(degrees) { return .eastSouthEast
            } else if (123.75 ..< 146.25).contains(degrees) { return .southEast
            } else if (146.25 ..< 168.75).contains(degrees) { return .southSouthEast
            } else if (168.75 ..< 191.25).contains(degrees) { return .south
            } else if (191.25 ..< 213.75).contains(degrees) { return .southSouthWest
            } else if (213.75 ..< 236.25).contains(degrees) { return .southWest
            } else if (236.25 ..< 258.75).contains(degrees) { return .westSouthWest
            } else if (258.75 ..< 281.25).contains(degrees) { return .west
            } else if (281.25 ..< 303.75).contains(degrees) { return .westNorthWest
            } else if (303.75 ..< 326.25).contains(degrees) { return .northWest
            } else { return .northNorthWest
            }
        }

        func normalizedDegrees() -> Double {
            switch self {
            case .north: return 0.0
            case .northNorthEast: return 22.5
            case .northEast: return 45
            case .eastNorthEast: return 67.5
            case .east: return 90
            case .eastSouthEast: return 112.5
            case .southEast: return 135
            case .southSouthEast: return 157.5
            case .south: return 180
            case .southSouthWest: return 202.5
            case .southWest: return 225
            case .westSouthWest: return 247.5
            case .west: return 270
            case .westNorthWest: return 292.5
            case .northWest: return 315
            case .northNorthWest: return 337.5
            }
        }

        var stringLabel: String {
            switch self {
            case .north: return "N"
            case .northNorthEast: return "NNE"
            case .northEast: return "NE"
            case .eastNorthEast: return "ENE"
            case .east: return "E"
            case .eastSouthEast: return "ESE"
            case .southEast: return "SE"
            case .southSouthEast: return "SSE"
            case .south: return "S"
            case .southSouthWest: return "SSW"
            case .southWest: return "SW"
            case .westSouthWest: return "WSW"
            case .west: return "W"
            case .westNorthWest: return "WNW"
            case .northWest: return "NW"
            case .northNorthWest: return "NNW"
            }
        }

    }
    /// `WindSpeed` enumeration converts speed (meters/second) into categories.
    /// Currently used for internal logic; not used for user-facing data.
    ///
    /// case `none`: 0 m/s
    /// case `slow`: 1 - 3 m/s (rustling leaves, drifting smoke, outdoor activities)
    /// case `normal`: 3 - 8 m/s (small branches move, flags extend, typical wind conditions)
    /// case `fast`: 8 - 15 m/s (large branches move, umbrellas fail, difficulty walking)
    /// case `extreme`: 15+ m/s (trees fall, structural damage, dangerous for outdoor activities)
    ///
    enum WindSpeedCategory: CaseIterable {
        case none
        case slow
        case normal
        case fast
        case extreme

        init(speed: Double) {
            if (0 ..< 1) ~= speed {
                self = .none
            } else if (1 ..< 3) ~= speed {
                self = .slow
            } else if (3 ..< 8) ~= speed {
                self = .normal
            } else if (8 ..< 15) ~= speed {
                self = .fast
            } else {
                self = .extreme
            }
        }
    }

}

// MARK: - Weather Colors -

extension CurrentWeather {

    enum WeatherMeshColors {

        private func colorForMeshTemperature(_ weatherMesh: WeatherMeshColors) -> Color {
            switch weatherMesh {
            case .clearSkyDay(let conditionModifier):
                switch conditionModifier {
                case .hot:
                    return .clearSkyHotDay
                case .normal:
                    return .clearSkyNormalDay
                case .cold:
                    return .clearSkyColdDay
                }
            case .clearSkyNight(let conditionModifier):
                switch conditionModifier {
                case .hot:
                    return .clearSkyHotNight
                case .normal:
                    return .clearSkyNormalNight
                case .cold:
                    return .clearSkyColdNight
                }
            }
        }
        private func uiColorForMeshTemperature(_ weatherMesh: WeatherMeshColors) -> UIColor {
            switch weatherMesh {
            case .clearSkyDay(let conditionModifier):
                switch conditionModifier {
                case .hot: return UIColor(named: "ClearSkyHotDay")!
                case .normal: return UIColor(named: "ClearSkyNormalDay")!
                case .cold: return UIColor(named: "ClearSkyColdDay")!
                }
            case .clearSkyNight(let conditionModifier):
                switch conditionModifier {
                case .hot: return UIColor(named: "ClearSkyHotNight")!
                case .normal: return UIColor(named: "ClearSkyNormalNight")!
                case .cold: return UIColor(named: "ClearSkyColdNight")!
                }
            }
        }

        case clearSkyDay(CurrentWeather.ConditionModifier)
        case clearSkyNight(CurrentWeather.ConditionModifier)

        var backgoundFillUIColor: UIColor {
            return uiColorForMeshTemperature(self)
        }

        var backgroundFillColor: Color {
            return colorForMeshTemperature(self)
        }
    }
}
