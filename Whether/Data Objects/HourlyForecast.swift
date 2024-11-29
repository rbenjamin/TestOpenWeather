//
//  HourlyForecast.swift
//  Whether
//
//  Created by Ben Davis on 11/29/24.
//

import Foundation

// MARK: - Hourly Forecast (Unused) -

/// #NOTE#
/// `HourlyForecast` is __unused__: Don't have the OpenWeather subscription to support.
///
struct HourlyForecast: Identifiable, Codable, Equatable, Hashable {

    public static func decodeWithData(_ data: Data?, decoder: JSONDecoder? = .init()) async throws -> HourlyForecast? {
        guard let data else {
            print("WeatherManager.decodeWeather(_:) failed - `data` is nil.")
            return nil
        }

        return try decoder!.decode(HourlyForecast.self, from: data)

    }

    enum CodingKeys: String, CodingKey {
    case list
    case sunrise
    case sunset
    }

    typealias ForecastList = Forecast.ForecastList

    let id = UUID()
    var list: [ForecastList]?

    var map: [Date: ForecastList]

//    let location: Forecast.ForecastLocation
    let sunrise: Date
    let sunset: Date

    init(list: [ForecastList],
         map: [Date: ForecastList],
         sunrise: Date,
         sunset: Date) {
        self.list = list
        self.map = map
        self.sunrise = sunrise
        self.sunset = sunset
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let list = try container.decodeIfPresent(Array<ForecastList>.self, forKey: CodingKeys.list)
        self.list = list
        self.map = list?.reduce(into: [Date: ForecastList](), { partialResult, forecast in
            partialResult[forecast.forecastDate] = forecast
        }) ?? [:]
        self.sunrise = try container.decode(Date.self, forKey: .sunrise)
        self.sunset = try container.decode(Date.self, forKey: .sunset)

    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.list, forKey: CodingKeys.list)
        try container.encode(self.sunset, forKey: CodingKeys.sunset)
        try container.encode(self.sunrise, forKey: CodingKeys.sunrise)
    }
}
