//
//  Clouds.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    struct Clouds: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        /// % cloudiness
        let id = UUID()
        let cloudiness: Double

        var description: String {
            return "CLOUDS: \(cloudiness)"
        }
        enum CodingKeys: String, CodingKey {
            case cloudiness = "all"
        }

        init(cloudiness: Double = 0.0) {
            self.cloudiness = cloudiness
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let cloudCoverPercent = try container.decode(Double.self, forKey: CodingKeys.cloudiness)
            self.cloudiness = cloudCoverPercent / 100
        }
    }
}
