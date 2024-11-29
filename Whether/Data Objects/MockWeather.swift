//
//  MockWeather.swift
//  Whether
//
//  Created by Ben Davis on 11/29/24.
//

import Foundation

/// `MockWeather` contains all the "mock" weather objects, for testing UI and view previews.
// MARK: - Mock Values -

extension Pollution {

    #if DEBUG
    /// `UI Testing`
    static func mockPollutionWithQuality(date: Date, quality: Readings.AirQualityReading) -> Pollution {
        return Pollution(readings: [Readings.mockReadings(date: date, airQuality: quality)])
    }
    #endif

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
    #if DEBUG
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
    #endif

}

extension CurrentWeather.Wind {
    #if DEBUG
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
    #endif

}
