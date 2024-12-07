//
//  Forecast.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation
import CoreLocation

typealias ForecastList = Forecast.ForecastList


struct Forecast: WeatherData, Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {

    public static func decodeWithData(_ data: Data?, decoder: JSONDecoder? = .init()) async throws -> Forecast? {
        guard let data else {
            print("WeatherManager.decodeWeather(_:) failed - `data` is nil.")
            return nil
        }
        decoder?.dateDecodingStrategy = .secondsSince1970
        return try decoder!.decode(Forecast.self, from: data)
    }

    public func fiveDayForecast(timeOfDay: Date) async -> [Forecast.ForecastList] {
        var list = [Forecast.ForecastList]()
        let current = Date()
        let currentHour = Calendar.current.component(.hour, from: timeOfDay)
        var matchedDates = Set<Date>()
        for date in self.map.keys where Calendar.current.isDate(date,
                                                                equalTo: current,
                                                                toGranularity: .day) == false {
                // - Should we be getting a regular time like 12:00 PM for each forecast?
                //
                // - OpenWeather (free) doesn't seem to give daily high and low -
                // just a temp, and a min and max measured temp for the location.

                // Change the forecast date's day, month, year to today
                // so we can determine whether, regardless of the forecast date,
                // we have the closest *time* to the current:
                // E.g., if today @ 5:00 PM we check the weather for the week,
                // the weather for the week will be from within the 5:00 PM 3 hour window.
            let newDate = Calendar.current.copyComponents([.day, .month],
                                                              fromDate: current,
                                                              toDate: date)!

                // Get the hour value
                let forecastHour = Calendar.current.component(.hour, from: newDate)

                // Equalize all the times so we can be sure we aren't adding two
                // forecasts on the same day when two forecasts are both within 3 hours.
                // By equalizing the time, we can use a Set to validate that we only add one forecast per date.
                let equalTime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: date)!

                // Determine if the difference in hours is <= 3

                if abs(currentHour - forecastHour) <= 3 && !matchedDates.contains(equalTime) {
                    matchedDates.insert(equalTime)
                    list.append(self.map[date]!)
                }
        }
        return list.sorted(by: { listA, listB in
            return listA.forecastDate < listB.forecastDate
        })

    }

    struct ForecastLocation: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        let id = UUID()
        let position: CurrentWeather.Position
        let sunrise: Date
        let sunset: Date

        var description: String {
            let pos = position.description
                                  return  """
                                   ForecastLocation:
                                   --------------------------------
                                   SUNRISE: \(sunrise.formatted(date: .abbreviated, time: .standard))
                                   SUNSET:  \(sunrise.formatted(date: .abbreviated, time: .standard))
                                   \(pos)
                                   --------------------------------
                                   """
        }

        enum CodingKeys: String, CodingKey {
            case position = "coord"
            case sunrise = "sunrise"
            case sunset = "sunset"
        }

        init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, sunrise: Date, sunset: Date) {
            self.position = CurrentWeather.Position(longitude: longitude, latitude: latitude)
            self.sunrise = sunrise
            self.sunset = sunset
        }

        init(position: CurrentWeather.Position, sunrise: Date, sunset: Date) {
            self.position = position
            self.sunrise = sunrise
            self.sunset = sunset
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.position = try container.decode(CurrentWeather.Position.self, forKey: CodingKeys.position)
            self.sunrise = try container.decode(Date.self, forKey: CodingKeys.sunrise)
            self.sunset = try container.decode(Date.self, forKey: CodingKeys.sunset)

        }
    }

    struct ForecastList: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        enum CodingKeys: String, CodingKey {
            case forecastDate = "dt"            // Time of data forecasted, unix, UTC
            case main = "main"
            case conditions = "weather"
            case wind = "wind"
            case clouds = "clouds"
            case rain = "rain"               // Rain volume for last 3 hours, mm.
            case snow = "snow"               // Snow volume for last 3 hours.
                                                // Please note that only mm as units of measurement
                                                // are available for this parameter

            case visibility = "visibility"
            case precipitation = "pop"          // Probability of precipitation.
                                                // The values of the parameter vary between 0 and 1,
                                                // where 0 is equal to 0%, 1 is equal to 100%
            /**
            #NOTE#
             - dayNight isn't available when decoding forecast data from OpenWeather
             
            case dayNight = "sys.pod"           // list.sys.pod Part of the day (n - night, d - day)
             */
            case forecastDateText = "dt_txt"    // Time of data forecasted, ISO, UTC

        }
        let id = UUID()
        let forecastDate: Date
        let main: CurrentWeather.MainWeather
        let conditions: [CurrentWeather.WeatherConditions]
        let wind: CurrentWeather.Wind?
        let clouds: CurrentWeather.Clouds?
        let rain: CurrentWeather.Rain?
        let snow: CurrentWeather.Snow?
        let visibility: Double?
        let precipitation: Double
//        let isDay: Bool
        let dateString: String

        var description: String {
            let date = forecastDate.formatted(date: .abbreviated, time: .standard)
            let main = main.description
            let conditions = conditions.map({ $0.description }).joined(separator: "\n")
            let visibility = self.visibility?.formatted() ?? "N/A"
            return """
                   ======================
                   FORECAST DATE: \(date)
                   ~~~~~~~~~~~~~~~~~~~~~~
                   MAIN: \(main)
                   \(conditions)
                   VIS: \(visibility)
                   PRECIPITATION: \(self.precipitation)
                   ======================
                   """
        }

        init(forecastDate: Date,
             main: CurrentWeather.MainWeather,
             conditions: [CurrentWeather.WeatherConditions],
             wind: CurrentWeather.Wind? = nil,
             clouds: CurrentWeather.Clouds? = nil,
             rain: CurrentWeather.Rain? = nil,
             snow: CurrentWeather.Snow? = nil,
             visibility: Double?,
             precipitation: Double,
             dateString: String) {
            self.forecastDate = forecastDate
            self.main = main
            self.conditions = conditions
            self.wind = wind
            self.clouds = clouds
            self.rain = rain
            self.snow = snow
            self.visibility = visibility
            self.precipitation = precipitation
            self.dateString = dateString
        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Be sure dateDecodingStrategy is set to secondsSince1970
            self.forecastDate = try container.decode(Date.self, forKey: CodingKeys.forecastDate)

            self.main = try container.decode(CurrentWeather.MainWeather.self, forKey: CodingKeys.main)
            let conditions = try container.decode(Array<CurrentWeather.WeatherConditions>.self, forKey: .conditions)

            self.conditions = conditions
            self.wind = try container.decodeIfPresent(CurrentWeather.Wind.self, forKey: CodingKeys.wind)
            self.clouds = try container.decodeIfPresent(CurrentWeather.Clouds.self, forKey: CodingKeys.clouds)
            self.rain = try container.decodeIfPresent(CurrentWeather.Rain.self, forKey: CodingKeys.rain)
            self.snow = try container.decodeIfPresent(CurrentWeather.Snow.self, forKey: CodingKeys.snow)
            self.visibility = try container.decodeIfPresent(Double.self, forKey: CodingKeys.visibility)
            self.precipitation = try container.decode(Double.self, forKey: CodingKeys.precipitation)
//            let dayStr = try container.decode(String.self, forKey: CodingKeys.dayNight)
//            self.isDay = dayStr.lowercased() == "d" ? true : false
            self.dateString = try container.decode(String.self, forKey: CodingKeys.forecastDateText)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.forecastDate, forKey: CodingKeys.forecastDate)
            try container.encode(self.main, forKey: CodingKeys.main)
            try container.encode(self.conditions, forKey: CodingKeys.conditions)
            try container.encodeIfPresent(self.wind, forKey: CodingKeys.wind)
            try container.encodeIfPresent(self.clouds, forKey: CodingKeys.clouds)
            try container.encodeIfPresent(self.rain, forKey: CodingKeys.rain)
            try container.encodeIfPresent(self.snow, forKey: CodingKeys.snow)
            try container.encode(self.visibility, forKey: CodingKeys.visibility)
            try container.encode(self.precipitation, forKey: CodingKeys.precipitation)
//            try container.encode(self.isDay ? "d" : "n", forKey: CodingKeys.dayNight)
            try container.encode(self.dateString, forKey: CodingKeys.forecastDateText)
        }
    }

    enum CodingKeys: String, CodingKey {
        case code = "cod"
        case message = "message"
        case count = "cnt"
        case list = "list"
        case position = "city"
    }

    let id = UUID()
    var list: [ForecastList]
    var map: [Date: ForecastList]
    let location: Forecast.ForecastLocation

    var description: String {
        let list = list.map({ $0.description }).joined(separator: "\n")
        return """
               FORECAST: \(list)
               """
    }

    init(list: [ForecastList], location: ForecastLocation) {
        self.list = list
        self.map = [:]
        self.location = location
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let list = try container.decode(Array<ForecastList>.self, forKey: CodingKeys.list)
        self.list = list
        self.map = list.reduce(into: [Date: ForecastList](), { partialResult, forecast in
            partialResult[forecast.forecastDate] = forecast
        })

        self.location = try container.decode(Forecast.ForecastLocation.self, forKey: CodingKeys.position)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.list, forKey: CodingKeys.list)
        try container.encode(self.location, forKey: CodingKeys.position)
    }
}
