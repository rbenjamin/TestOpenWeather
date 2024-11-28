//
//  WeatherConditions+Extended.swift
//  Whether
//
//  Created by Ben Davis on 11/8/24.
//

import Foundation
import SwiftUI

extension CurrentWeather.WeatherConditions {
    /// Returns condition image for condition.
    ///
    func image(forDaytime: Bool) -> Image {
        if self.hasRain, let rain = self.rainConditions {
            return image(forRain: rain, forDaytime: forDaytime)
        } else if self.hasDrizzle, let drizzle = self.drizzleConditions {
            return image(forDrizzle: drizzle, forDaytime: forDaytime)
        } else if self.hasClouds == true, let cloudType = self.cloudConditions {
            return image(forClouds: cloudType, forDaytime: forDaytime)
        } else if self.hasSnow, let snow = self.snowConditions {
            return image(forSnow: snow, forDaytime: forDaytime)
        } else if self.hasStorm, let thunder = self.thunderstormConditions {
            return image(forStorm: thunder, forDaytime: forDaytime)
        } else {
            return Image(forDaytime ? "ClearSkyDay" : "ClearSkyNight")
        }
    }
    private func image(forRain rain: CurrentWeather.WeatherConditions.RainConditions,
                       forDaytime: Bool) -> Image {
        switch rain {
        case .light:
            return Image(forDaytime ? "RainLightDay" : "RainLightNight")
        case .heavy, .veryHeavy, .extreme:
            return Image("RainHeavy")
        case .lightShowerRain, .showerRain, .heavyShowerRain:
            return Image("RainShower")
        default:
            return Image(forDaytime ? "RainModerateDay" : "RainModerateNight")
        }
    }
    private func image(forDrizzle drizzle: CurrentWeather.WeatherConditions.DrizzleConditions,
                       forDaytime: Bool) -> Image {
        switch drizzle {
        case .lightDrizzleRain, .normalDrizzleRain, .heavyDrizzleRain:
            return Image(forDaytime ? "RainDrizzleDay" : "RainDrizzleNight")
        case .showerDrizzle:
            return Image("DrizzleShower")
        default:
            return Image(forDaytime ? "DrizzleDay" : "DrizzleNight")
        }
    }
    private func image(forClouds clouds: CurrentWeather.WeatherConditions.CloudConditions,
                       forDaytime: Bool) -> Image {
        switch clouds {
        case .few:
            return Image(forDaytime ? "CloudFewDay" : "CloudFewNight")
        case .scattered:
            return Image(forDaytime ? "CloudScatteredDay" : "CloudScatteredNight")
        case .broken:
            return Image(forDaytime ? "CloudBrokenDay" : "CloudBrokenNight")
        case .overcast:
            return Image("CloudOvercast")
        }
    }
    private func image(forSnow snow: CurrentWeather.WeatherConditions.SnowConditions,
                       forDaytime: Bool) -> Image {
        switch snow {
        case .withLightRainAndSnow, .withModerateRainAndSnow:
            return Image("SnowRain")
        default:
            return Image(forDaytime ? "SnowDay" : "SnowNight")
        }
    }
    private func image(forStorm storm: CurrentWeather.WeatherConditions.ThunderstormConditions,
                       forDaytime: Bool) -> Image {
        switch storm {
        case .withLightRain, .withRain, .withHeavyRain:
            return Image("ThunderRain")
        case .withLightDrizzle, .withDrizzle, .withHeavyDrizzle:
            return Image("ThunderDrizzle")
        default:
            return Image("Thunderstorm")
        }
    }

}
