//
//  MockWeather.swift
//  Whether
//
//  Created by Ben Davis on 11/29/24.
//

import Foundation
import CoreLocation

struct MockWeatherValue {
    let mainWeather: CurrentWeather.MainWeather
    let conditions: CurrentWeather.WeatherConditions
    init(tempF: Double,
         pressure: CurrentWeather.MainWeather.PressureConditions,
         humidity: Double,
         conditions: (any WeatherIDEnum)) {

        let temp = UnitTemperature.fahrenheit(value: tempF)
        let pressure = UnitPressure.hectopascal(value: pressure.mockPressureValue())
        self.mainWeather = CurrentWeather.MainWeather(temperature: temp,
                                                      feelsLike: temp,
                                                      minTemp: temp,
                                                      maxTemp: temp,
                                                      pressure: pressure,
                                                      humidity: humidity,
                                                      seaLevel: pressure,
                                                      groundLevel: pressure)

        self.conditions = .init(id: conditions.rawValue,
                                mainLabel: conditions.stringLabel,
                                description: conditions.stringLabel,
                                icon: "")
    }
}

// MARK: - Mock Values -

extension Pollution {

    /// `UI Testing`
    static func mockPollution(date: Date, quality: Readings.AirQualityReading) -> Pollution {
        return Pollution(readings: [Readings.mockReadings(date: date, airQuality: quality)])
    }

}

extension Pollution.Readings {
    /**
                        SO2         NO2       PM10       PM2.5        O3          CO
     Good        1    [0; 20)     [0; 40)    [0; 20)    [0; 10)     [0; 60)     [0; 4400)
     Fair        2    [20; 80)    [40; 70)   [20; 50)   [10; 25)    [60; 100)   [4400; 9400)
   
     Moderate    3    [80; 250)   [70; 150)  [50; 100)  [25; 50)    [100; 140)  [9400-12400)
     Poor        4    [250; 350)  [150; 200) [100; 200) [50; 75)    [140; 180)  [12400; 15400)
     Very Poor   5       ⩾350        ⩾200       ⩾200       ⩾75         ⩾180         ⩾15400
     
     
        Other parameters that do not affect the AQI calculation:

        NH3: min value 0.1 - max value 200
        NO: min value 0.1 - max value 100

     */

    /// `UI Testing`
    static func mockReadings(date: Date,
                             airQuality: AirQualityReading) -> Pollution.Readings {
        var comps: [ComponentCodingKeys: Double]?
        switch airQuality {
        case .good:
            comps = [.sulphurDioxide: 10,
                     .nitrogenDioxide: 20,
                     .courseParticulate: 10,
                     .fineParticle: 5,
                     .ozone: 30,
                     .carbonMonoxide: 300,
                     .ammonia: 12,
                     .nitrogenMonoxide: 15]
        case .fair:
            comps = [.sulphurDioxide: 30,
                     .nitrogenDioxide: 55,
                     .courseParticulate: 30,
                     .fineParticle: 18,
                     .ozone: 85,
                     .carbonMonoxide: 4800,
                     .ammonia: 12,
                     .nitrogenMonoxide: 15]
        case .moderate:
            comps = [.sulphurDioxide: 90,
                     .nitrogenDioxide: 120,
                     .courseParticulate: 75,
                     .fineParticle: 35,
                     .ozone: 120,
                     .carbonMonoxide: 9800,
                     .ammonia: 12,
                     .nitrogenMonoxide: 15]
        case .poor:
            comps = [.sulphurDioxide: 290,
                     .nitrogenDioxide: 180,
                     .courseParticulate: 150,
                     .fineParticle: 65,
                     .ozone: 165,
                     .carbonMonoxide: 12800,
                     .ammonia: 12,
                     .nitrogenMonoxide: 15]
        default:
            comps = [.sulphurDioxide: 380,
                     .nitrogenDioxide: 250,
                     .courseParticulate: 220,
                     .fineParticle: 95,
                     .ozone: 190,
                     .carbonMonoxide: 15500,
                     .ammonia: 12,
                     .nitrogenMonoxide: 15]
        }
        let finalComps: [ComponentCodingKeys: Measurement<UnitDispersion>] = comps!.mapValues({
            UnitDispersion.microgramsPerCMFromValue(value: $0)
        })
        return Pollution.Readings(date: date,
                                  qualityState: airQuality,
                                  components: finalComps)
    }

}

extension CurrentWeather.Wind {
    /// `UI Testing`
    static func mockWindWithCategory(_ category: WindSpeedCategory, direction: WindDirection) -> CurrentWeather.Wind {
        var speed: Double = 0.0
        var gustLevel: Double = 0.0
        let trueDirection: Double = direction.normalizedDegrees()

        switch category {
        case .none:
            speed = 0
            gustLevel = 1
        case .slow:
            speed = 2
            gustLevel = 2.5
        case .normal:
            speed = 4
            gustLevel = 5.5
        case .fast:
            speed = 9
            gustLevel = 8.5
        case .extreme:
            speed = 18
            gustLevel = 12
        }
        return CurrentWeather.Wind(windSpeed: UnitSpeed.metersPerSecond(speed),
                                   direction: trueDirection,
                                   gustLevel: UnitSpeed.metersPerSecond(gustLevel))
    }

}

extension CurrentWeather.MainWeather.PressureConditions {
    
    func mockPressureValue() -> Double {
        switch self {
        case .veryLow:
            return 970.0
//            return UnitPressure.hectopascal(value: 970)
        case .low:
            return 990.5
//            return UnitPressure.hectopascal(value: 990.5)
        case .belowNormal:
            return 1005.5
//            return UnitPressure.hectopascal(value: 1005.5)
        case .normal:
            return 1015.5
//            return UnitPressure.hectopascal(value: 1015.5)
        case .high:
            return 1021.0
//            return UnitPressure.hectopascal(value: 1021)
        }
    }
}

extension CurrentWeather {
    static func mockWeather(date: Date,
                            value: MockWeatherValue,
                            windCategory: Wind.WindSpeedCategory,
                            windDirection: Wind.WindDirection,
                            cloudCover: Double,
                            rainOneHour: Measurement<UnitLength>?,
                            snowOneHour: Measurement<UnitLength>?) -> CurrentWeather {
        let current = Calendar.current
        let position = CurrentWeather.Position.init(longitude: CLLocationDegrees(38.82132),
                                                     latitude: CLLocationDegrees(82.77531))
        let sunrise = current.date(bySettingHour: 6, minute: 41, second: 0, of: date)!
        let sunset = current.date(bySettingHour: 19, minute: 30, second: 0, of: date)!
        let wind = CurrentWeather.Wind.mockWindWithCategory(windCategory, direction: windDirection)
        let system = CurrentWeather.System.init(country: "us", sunrise: sunrise, sunset: sunset)

        let weather = CurrentWeather(position: position,
                                     conditions: [],
                                     mainWeather: value.mainWeather,
                                     wind: wind,
                                     clouds: CurrentWeather.Clouds(cloudiness: 0.50),
                                     rain: CurrentWeather.Rain(oneHour: rainOneHour, threeHour: nil),
                                     snow: CurrentWeather.Snow(oneHour: snowOneHour, threeHour: nil),
                                     visibility: 1.0,
                                     system: system,
                                     timeZone: Double(-28800.0),
                                     code: 0)
        return weather
    }
}

extension Forecast.ForecastList {

    static func mockForecast(date: Date,
                             value: MockWeatherValue) -> Forecast.ForecastList {
        return Forecast.ForecastList(forecastDate: date,
                                     main: value.mainWeather,
                                     conditions: [value.conditions],
                                     visibility: nil,
                                     precipitation: 0.0,
                                     dateString: date.formatted(date: .abbreviated, time: .shortened))
    }

    static func mockListStartingFrom(date: Date,
                                     mockValues: [MockWeatherValue]) -> [Forecast.ForecastList]? {

        var forecastList = [Forecast.ForecastList]()

        let calendar = Calendar.current
        guard mockValues.count == 5 else { return nil }
        for dayIndex in 1 ... 5 {
            guard let nextDate = calendar.date(byAdding: .day,
                                               value: dayIndex,
                                               to: date,
                                               wrappingComponents: false) else {
                return nil
            }
            let list = Forecast.ForecastList(forecastDate: nextDate,
                                             main: mockValues[dayIndex - 1].mainWeather,
                                             conditions: [mockValues[dayIndex - 1].conditions],
                                             visibility: nil,
                                             precipitation: 0.0,
                                             dateString: nextDate.formatted(date: .abbreviated, time: .shortened))
            forecastList.append(list)

        }
        return forecastList
    }
}
