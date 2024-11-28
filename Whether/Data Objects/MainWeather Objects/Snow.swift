//
//  Snow.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    /// `Snow` (where available) Precipitation, mm/h.
    /// Please note that only mm/h as units of measurement are available for this parameter.
    ///
    struct Snow: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {

    /// `SnowDensity` isn't setup to work with mm/h -- these cases were designed with values for meters / second.
    /// To get this to work I need to convert it to use mm/h.

        var snowDensity: SnowDensity? {
            if self.oneHour != nil {
                return SnowDensity.init(forecast: self.oneHour!)
            } else if self.threeHour != nil {
                return SnowDensity.init(forecast: self.threeHour!)
            }
            return nil
        }

        let id: UUID = UUID()
        let oneHour: Measurement<UnitLength>?
        let threeHour: Measurement<UnitLength>?

        var description: String {
            if let oneHour {
                return "SNOW 1H: \(oneHour)"
            } else if let threeHour {
                return "SNOW 3H: \(threeHour)"
            } else { return "NO SNOW" }
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
                self.oneHour = Measurement.snowfallStandardToUserLocale(oneHour, locale: .autoupdatingCurrent)
            } else {
                self.oneHour = nil
            }

            if let threeHour = try container.decodeIfPresent(Double.self, forKey: .threeHour) {
                self.threeHour = Measurement.snowfallStandardToUserLocale(threeHour, locale: .autoupdatingCurrent)
            } else {
                self.threeHour = nil
            }

        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let oneHour = self.oneHour?.converted(to: .millimeters)

            try container.encodeIfPresent(oneHour, forKey: .oneHour)

            let threeHour = self.threeHour?.converted(to: .millimeters)
            try container.encodeIfPresent(threeHour, forKey: .threeHour)
        }

    }

}
