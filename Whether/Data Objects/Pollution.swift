//
//  Pollution.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation
struct Pollution: WeatherData, CustomStringConvertible {
    public static func decodeWithData(_ data: Data?, decoder: JSONDecoder? = .init()) async throws -> Pollution? {
        guard let data else {
            print("WeatherManager.decodeWeather(_:) failed - `data` is nil.")
            return nil
        }
        decoder?.dateDecodingStrategy = .secondsSince1970

        return try decoder!.decode(Pollution.self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case coordinates = "coord"
        case readings = "list"
    }
    let id = UUID()
    let readings: [Readings]

    var description: String {
        return self.readings.description
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.readings = try container.decode(Array<Readings>.self, forKey: .readings)
    }

    func encode(to encoder: any Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.readings, forKey: CodingKeys.readings)
    }

    init(readings: [Readings]) {
        self.readings = readings
    }

    struct Readings: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        let id = UUID()
        let date: Date
        let airQuality: Int
        let qualityState: AirQualityReading
        let components: [ComponentCodingKeys: Measurement<UnitDispersion>]

        init(date: Date,
             qualityState: AirQualityReading,
             components: [ComponentCodingKeys: Measurement<UnitDispersion>]) {
            self.date = date
            self.airQuality = qualityState.rawValue
            self.qualityState = qualityState
            self.components = components
        }

        var description: String {
            let formatted = date.formatted(date: .abbreviated, time: .standard)
            return "Pollution.Reading: Date: \(formatted) AQI: \(self.airQuality) State: \(qualityState.stringValue)"
        }

        enum CodingKeys: String, CodingKey {
            case date = "dt"
            case main = "main"
            case airQuality = "aqi"
            case components = "components"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let date = try container.decode(Date.self, forKey: CodingKeys.date)
            self.date = date

            let main = try container.decode(Dictionary<String, Int>.self, forKey: CodingKeys.main)
            self.airQuality = main[CodingKeys.airQuality.rawValue]!
            self.qualityState = AirQualityReading(rawValue: self.airQuality) ?? AirQualityReading.unknown
            var finalComps = [Readings.ComponentCodingKeys: Measurement<UnitDispersion>]()

            if let comps = try container.decodeIfPresent(Dictionary<String, Double>.self,
                                                         forKey: CodingKeys.components) {
                for (key, value) in comps {
                    if let codingKey = Readings.ComponentCodingKeys(rawValue: key) {
                       finalComps[codingKey] = Measurement<UnitDispersion>(value: value, unit: .microgramsPerCubicMetre)
                    }
                }
            }
            self.components = finalComps
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.date,
                                 forKey: CodingKeys.date)

            try container.encode([CodingKeys.airQuality.rawValue: self.airQuality],
                                 forKey: CodingKeys.main)
            var encodedComps = [String: Double]()

            for (key, value) in self.components {
                encodedComps[key.rawValue] = value.value
            }
            try container.encode(encodedComps,
                                 forKey: CodingKeys.components)
        }
    }
}

extension Pollution.Readings {

    /// Pollution reading components: The reading components that make up the Air Quality Index
    enum ComponentCodingKeys: String, CodingKey {
        case carbonMonoxide = "co"
        case nitrogenMonoxide = "no"
        case nitrogenDioxide = "no2"
        case ozone = "o3"
        case sulphurDioxide = "so2"
        case fineParticle = "pm2_5"
        case courseParticulate = "pm10"
        case ammonia = "nh3"

        var stringValue: String {
            switch self {
            case .carbonMonoxide: return "Carbon Monoxide"
            case .nitrogenMonoxide: return "Nitrogen Monoxide"
            case .nitrogenDioxide: return "Nitrogen Dioxide"
            case .ozone: return "Ozone"
            case .sulphurDioxide: return "Sulphur Dioxide"
            case .fineParticle: return "Fine Particulate"
            case .courseParticulate: return "Course Particulate"
            case .ammonia: return "Ammonia"
            }
        }
    }

    /// Air Quality Index
    enum AirQualityReading: Int {
        case unknown = -1
        case good = 1
        case fair = 2
        case moderate = 3
        case poor = 4
        case veryPoor = 5

        var stringValue: String {
            switch self {
            case .unknown: return "Unknown"
            case .good: return "1: Good"
            case .fair: return "2: Fair"
            case .moderate: return "3: Moderate"
            case .poor: return "4: Poor"
            case .veryPoor: return "5: Very Poor"
            }
        }
    }
}
