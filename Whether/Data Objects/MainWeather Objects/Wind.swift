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
