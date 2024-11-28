//
//  System.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    struct System: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
            let id = UUID()
            let country: String
            let sunrise: Date
            let sunset: Date

            var description: String {
                return """
                       System:
                       --------------------------------
                       SUNRISE: \(sunrise.formatted(date: .abbreviated, time: .standard))
                       SUNSET:  \(sunrise.formatted(date: .abbreviated, time: .standard))
                       --------------------------------
                       """
            }

            var isDaytime: Bool {

                let current = Date()
                let comps: [Calendar.Component] = [.year, .month, .day, .yearForWeekOfYear]
                let sunset = Calendar.current.copyComponents(comps,
                                                             fromDate: current,
                                                             toDate: self.sunset)!
                let sunrise = Calendar.current.copyComponents(comps,
                                                              fromDate: current,
                                                              toDate: self.sunrise)!

                return current > sunrise && current < sunset
            }

            enum CodingKeys: String, CodingKey {
                case country
                case sunrise
                case sunset
            }

            init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<CurrentWeather.System.CodingKeys> = try decoder.container(keyedBy: CurrentWeather.System.CodingKeys.self)
                self.country = try container.decode(String.self, forKey: CodingKeys.country)
                self.sunrise = try container.decode(Date.self, forKey: CodingKeys.sunrise)
                self.sunset = try container.decode(Date.self, forKey: CodingKeys.sunset)

            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.country, forKey: .country)
                try container.encode(self.sunrise, forKey: .sunrise)
                try container.encode(self.sunset, forKey: .sunset)
            }

            init(country: String, sunrise: Date, sunset: Date) {
                self.country = country
                self.sunrise = sunrise
                self.sunset = sunset
            }
        }
}
