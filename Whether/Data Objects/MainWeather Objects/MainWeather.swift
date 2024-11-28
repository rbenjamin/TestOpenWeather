//
//  MainWeather.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation
import SwiftUICore

extension CurrentWeather {
    struct MainWeather: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {

        func condition(for pressure: Measurement<UnitPressure>) -> CurrentWeather.MainWeather.PressureConditions {
            return CurrentWeather.MainWeather.PressureConditions.init(pressure.converted(to: .hectopascals))
        }

        enum PressureConditions: CustomStringConvertible {
            case veryLow
            case low
            case belowNormal
            case normal
            case high

            enum PressureForecastIndications {
                case severeStormConditions
                case stormyConditions
                case rainConditions
                case transitionalConditions
                case fairConditions

                var stringLabel: LocalizedStringKey {
                    switch self {
                    case .severeStormConditions: return "Severe Storm Conditions"
                    case .stormyConditions: return "Stormy Conditions"
                    case .rainConditions: return "Rain Conditions"
                    case .transitionalConditions: return "Transitional Conditions"
                    case .fairConditions: return "Fair Conditions"
                    }
                }
            }

            var stringLabel: LocalizedStringKey {
                switch self {
                case .veryLow: return "Very Low"
                case .low: return "Low"
                case .belowNormal: return "Below Normal"
                case .normal: return "Normal"
                case .high: return "High"
                }
            }

            /// General Indications received from current barometric pressure:
            func indication(from pressure: Measurement<UnitPressure>) -> PressureForecastIndications {
                let condition = PressureConditions(pressure)
                switch condition {
                case .veryLow: return .severeStormConditions
                case .low: return .stormyConditions
                case .belowNormal: return .rainConditions
                case .normal: return .transitionalConditions
                case .high: return .fairConditions
                }
            }
            /// Convert actual pressure value into a low/med/high range:
            init(_ value: Measurement<UnitPressure>) {
                let hectoValue = value.converted(to: .hectopascals).value
                if (960 ... 980) ~= hectoValue {
                    self = .veryLow
                } else if (981 ... 1000) ~= hectoValue {
                    self = .low
                } else if (1001 ... 1010) ~= hectoValue {
                    self = .belowNormal
                } else if (1011 ... 1020) ~= hectoValue {
                    self = .normal
                } else {
                    self = .high
                }
            }

            var description: String {
                switch self {
                case .veryLow: return "very low pressure (960 ... 980)"
                case .low: return "low pressure (980 ... 1000)"
                case .belowNormal: return "below normal (1001 ... 1010)"
                case .normal: return "normal (1011 ... 1020)"
                case .high: return "high (> 1020)"
                }
            }
        }
        let id = UUID()
        let temperature: Measurement<UnitTemperature>
        let feelsLike: Measurement<UnitTemperature>
        let minTemp: Measurement<UnitTemperature>
        let maxTemp: Measurement<UnitTemperature>
        let pressure: Measurement<UnitPressure>
        let humidity: Double
        let seaLevel: Measurement<UnitPressure>
        let groundLevel: Measurement<UnitPressure>

        var description: String {
            let temp = "TEMP: \(temperature.formatted()) FEELS LIKE: \(feelsLike.formatted())"
            let pressure = "PRES: \(pressure.formatted()) HUM: \(humidity)"
            return """
                   \(temp)
                   \(pressure)
                   """
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let kTemp = self.temperature.converted(to: .kelvin).value

            try container.encode(kTemp, forKey: CurrentWeather.MainWeather.CodingKeys.temperature)

            let kFeels = self.feelsLike.converted(to: .kelvin).value
            try container.encode(kFeels, forKey: CurrentWeather.MainWeather.CodingKeys.feelsLike)

            let kMin = self.minTemp.converted(to: .kelvin).value
            try container.encode(kMin, forKey: CurrentWeather.MainWeather.CodingKeys.minTemp)

            let kMax = self.maxTemp.converted(to: .kelvin).value
            try container.encode(kMax, forKey: CurrentWeather.MainWeather.CodingKeys.maxTemp)

            let pressure = self.pressure.converted(to: .hectopascals).value
            try container.encode(pressure, forKey: CurrentWeather.MainWeather.CodingKeys.pressure)

            try container.encode(self.humidity, forKey: .humidity)

            let seaLevel = self.seaLevel.converted(to: .hectopascals).value
            try container.encode(seaLevel, forKey: .seaLevel)

            let groundLevel = self.groundLevel.converted(to: .hectopascals).value
            try container.encode(groundLevel, forKey: .groundLevel)

        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CurrentWeather.MainWeather.CodingKeys> = try decoder.container(keyedBy: CurrentWeather.MainWeather.CodingKeys.self)
            /// OpenWeather - returns in kelvin
            /// (we want to convert based on device settings,
            /// rather than requesting a specific unit from OpenWeather.
            let kTemp = try container.decode(Double.self,
                                             forKey: CodingKeys.temperature).rounded()
            self.temperature = Measurement.temperatureStandardToUserLocale(kTemp)
            let kFeelsLike = try container.decode(Double.self,
                                                  forKey: CodingKeys.feelsLike).rounded()
            self.feelsLike = Measurement.temperatureStandardToUserLocale(kFeelsLike)

            let kMinTemp = try container.decode(Double.self,
                                                forKey: CodingKeys.minTemp).rounded()
            self.minTemp = Measurement.temperatureStandardToUserLocale(kMinTemp)

            let kMaxTemp = try container.decode(Double.self,
                                                forKey: CodingKeys.maxTemp).rounded()
            self.maxTemp = Measurement.temperatureStandardToUserLocale(kMaxTemp)

            /// OpenWeather - returns in hectopascals
            /// (we want to convert based on device settings,
            /// rather than requesting a specific unit from OpenWeather).

            let hPaPressure = try container.decode(Double.self,
                                                   forKey: CodingKeys.pressure)

            self.pressure = Measurement.pressureStandardToUserLocale(hPaPressure)

            let humidity = try container.decode(Double.self,
                                                forKey: CodingKeys.humidity).rounded()

            /// We need to convert the incoming value into a true fraction
            /// that can be represented by NumberFormatter correctly.
            self.humidity = humidity / 100

            let hPaSeaLevel = try container.decode(Double.self,
                                                   forKey: CodingKeys.seaLevel)
            self.seaLevel = Measurement.pressureStandardToUserLocale(hPaSeaLevel)

            let hPaGroundLevel = try container.decode(Double.self,
                                                      forKey: CodingKeys.groundLevel)
            self.groundLevel = Measurement.pressureStandardToUserLocale(hPaGroundLevel)
        }

        init(temperature: Measurement<UnitTemperature>,
             feelsLike: Measurement<UnitTemperature>,
             minTemp: Measurement<UnitTemperature>,
             maxTemp: Measurement<UnitTemperature>,
             pressure: Measurement<UnitPressure>,
             humidity: Double,
             seaLevel: Measurement<UnitPressure>,
             groundLevel: Measurement<UnitPressure>) {

            self.temperature = temperature
            self.feelsLike = feelsLike
            self.minTemp = minTemp
            self.maxTemp = maxTemp
            self.pressure = pressure
            self.humidity = humidity
            self.seaLevel = seaLevel
            self.groundLevel = groundLevel
        }

        enum CodingKeys: String, CodingKey {
            case temperature = "temp"
            case feelsLike = "feels_like"
            case minTemp = "temp_min"
            case maxTemp = "temp_max"
            case pressure = "pressure"
            case humidity = "humidity"
            case seaLevel = "sea_level"
            case groundLevel = "grnd_level"
        }
    }
}
