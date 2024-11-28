//
//  Rain.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    struct Rain: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        // (where available) Precipitation, mm/h.
        // Please note that only mm/h as units of measurement are available for this parameter
        let id: UUID = UUID()
        let oneHour: Measurement<UnitLength>?
        let threeHour: Measurement<UnitLength>?

        var rainDensity: RainDensity? {
            if self.oneHour != nil {
                return RainDensity.init(forecast: self.oneHour!)
            } else if self.threeHour != nil {
                return RainDensity.init(forecast: self.threeHour!)
            }
            return nil
        }

        var description: String {
            if let oneHour {
                return "RAIN 1H: \(oneHour)"
            } else if let threeHour {
                return "RAIN 3H: \(threeHour)"
            } else {
                return "NO RAIN"
            }
        }

        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
            case threeHour = "3h"
        }
        init(oneHour: Measurement<UnitLength>?, threeHour: Measurement<UnitLength>?) {
            self.oneHour = oneHour
            self.threeHour = threeHour
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let oneHour = try container.decodeIfPresent(Double.self, forKey: .oneHour) {
                self.oneHour = Measurement.rainfallStandardToUserLocale(oneHour, locale: .autoupdatingCurrent)
            } else {
                self.oneHour = nil
            }
            if let threeHour = try container.decodeIfPresent(Double.self, forKey: .threeHour) {
                self.threeHour = Measurement.rainfallStandardToUserLocale(threeHour, locale: .autoupdatingCurrent)
            } else {
                self.threeHour = nil
            }

        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let oneHour = self.oneHour?.converted(to: .millimeters)

            try container.encodeIfPresent(oneHour?.value, forKey: .oneHour)

            let threeHour = self.threeHour?.converted(to: .millimeters)

            try container.encodeIfPresent(threeHour?.value, forKey: .threeHour)
        }
    }
}

extension CurrentWeather.Rain {

    /// Rain Density
    enum RainDensity: CaseIterable {
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
            let rainDensity = forecast.converted(to: .millimeters).value
            if (0.01 ..< 2.5).contains(rainDensity) {
                self = .light
            } else if (2.5 ..< 7.5).contains(rainDensity) {
                self = .medium
            } else if (7.5 ..< 50.0).contains(rainDensity) {
                self = .heavy
            } else {
                self = .extreme
            }

        }
    }
}
