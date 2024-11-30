//
//  Wind.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    struct Wind: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {

        let id = UUID()
        let windSpeed: Measurement<UnitSpeed>
        /// wind direction, degrees meteorological
        let direction: Double
        let gustLevel: Measurement<UnitSpeed>?

        var description: String {
            return "WIND SPEED: \(windSpeed.formatted()) \(self.cardinalDirection.description)"
        }

        var speedCategory: WindSpeedCategory {
            .init(speed: self.windSpeed.value)
        }

        var cardinalDirection: WindDirection {
            .init(degrees: self.direction)
        }

        enum CodingKeys: String, CodingKey {
            case windSpeed = "speed"
            case direction = "deg"
            case gustLevel = "gust"
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            let doubleSpeed = try container.decode(Double.self,
                                                   forKey: Wind.CodingKeys.windSpeed)
            self.windSpeed = Measurement.speedStandardToUserLocale(doubleSpeed)

            self.direction = try container.decode(Double.self,
                                                  forKey: Wind.CodingKeys.direction)

            if let doubleGust = try container.decodeIfPresent(Double.self,
                                                              forKey: Wind.CodingKeys.gustLevel) {
                self.gustLevel = Measurement.speedStandardToUserLocale(doubleGust)
            } else {
                self.gustLevel = nil
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let windSpeed = self.windSpeed.converted(to: .metersPerSecond).value
            try container.encode(windSpeed, forKey: .windSpeed)
            try container.encode(self.direction, forKey: .direction)
            if let gust = self.gustLevel {
                let gustSpeed = gust.converted(to: .metersPerSecond).value
                try container.encode(gustSpeed, forKey: .gustLevel)

            }
        }

        init(windSpeed: Measurement<UnitSpeed>, direction: Double, gustLevel: Measurement<UnitSpeed>) {
            self.windSpeed = windSpeed
            self.direction = direction
            self.gustLevel = gustLevel
        }
    }
}

extension CurrentWeather.Wind {
    /**
        `WindDirection` converts wind direction degrees into an enum cardinal direction category based on ranges the wind direction matches.  Used primarily for the `CardinalView`.
     */

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

        var longLabel: String {
            switch self {
            case .north: return "North"
            case .northNorthEast: return "North-North-East"
            case .northEast: return "North-East"
            case .eastNorthEast: return "East-North-East"
            case .east: return "East"
            case .eastSouthEast: return "East-South-East"
            case .southEast: return "South-East"
            case .southSouthEast: return "South-South-East"
            case .south: return "South"
            case .southSouthWest: return "South-South-West"
            case .southWest: return "South-West"
            case .westSouthWest: return "West-South-West"
            case .west: return "West"
            case .westNorthWest: return "West-North-West"
            case .northWest: return "North-West"
            case .northNorthWest: return "North-North-West"
            }
        }

    }
    /// `WindSpeed` enumeration converts speed (meters/second) into categories.
    /// Currently used for SceneKit particle view to determine how much to accelerate the particles as they fall.
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
