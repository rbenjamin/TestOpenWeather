//
//  CurrentWeather+Conditions.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension CurrentWeather {
    struct WeatherConditions: Identifiable, Codable, Equatable, Hashable, CustomStringConvertible {
        let id: Int
        let mainLabel: String
        let weatherDetails: String
        let icon: String
        var clearConditions: ClearConditions?
        var thunderstormConditions: ThunderstormConditions?
        var rainConditions: RainConditions?
        var drizzleConditions: DrizzleConditions?
        var snowConditions: SnowConditions?
        var atmosphereConditions: AtmosphereConditions?
        var cloudConditions: CloudConditions?

        var hasStorm: Bool { thunderstormConditions != nil }
        var hasRain: Bool { rainConditions != nil }
        var hasDrizzle: Bool { drizzleConditions != nil }
        var hasSnow: Bool { snowConditions != nil }
        var hasAtmosphere: Bool { atmosphereConditions != nil }
        var hasClouds: Bool { cloudConditions != nil }
        var hasClear: Bool { clearConditions != nil }

        var description: String {
            return "CONDITIONS: \(self.id) \(self.mainLabel) (\(self.weatherDetails)) ATMOS: "
        }

        var iconURL: URL {
            URL(string: "https://openweathermap.org/img/wn/\(self.icon)@2x.png")!
        }

        init(id: Int, mainLabel: String, description: String, icon: String) {
            self.id = id
            self.mainLabel = mainLabel
            self.weatherDetails = description
            self.icon = icon
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(Int.self, forKey: WeatherConditions.CodingKeys.id)
            self.id = id
            self.mainLabel = try container.decode(String.self, forKey: CodingKeys.mainLabel)
            self.weatherDetails = try container.decode(String.self, forKey: CodingKeys.weatherDetails)
            self.icon = try container.decode(String.self, forKey: CodingKeys.icon)

            let intValue = Int(self.id)

            if let clear = Self.ClearConditions(rawValue: intValue) {
                self.clearConditions = clear
            } else if let storm = Self.ThunderstormConditions(rawValue: intValue) {
                self.thunderstormConditions = storm
            } else if let drizzle = Self.DrizzleConditions(rawValue: intValue) {
                self.drizzleConditions = drizzle
            } else if let rain = Self.RainConditions(rawValue: intValue) {
                self.rainConditions = rain
            } else if let snow = Self.SnowConditions(rawValue: intValue) {
                self.snowConditions = snow
            } else if let atmos = Self.AtmosphereConditions(rawValue: intValue) {
                self.atmosphereConditions = atmos
            } else if let clouds = Self.CloudConditions(rawValue: intValue) {
                self.cloudConditions = clouds
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.id, forKey: CodingKeys.id)
            try container.encode(self.mainLabel, forKey: CodingKeys.mainLabel)
            try container.encode(self.weatherDetails, forKey: CodingKeys.weatherDetails)
            try container.encode(self.icon, forKey: CodingKeys.icon)
        }

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case mainLabel = "main"
            case weatherDetails = "description"
            case icon = "icon"
        }

        var condition: (any WeatherIDEnum)? {
            let intValue = Int(self.id)
            if let clear = Self.ClearConditions(rawValue: intValue) {
                return clear
            } else if let storm = Self.ThunderstormConditions(rawValue: intValue) {
                return storm
            } else if let drizzle = Self.DrizzleConditions(rawValue: intValue) {
                return drizzle
            } else if let rain = Self.RainConditions(rawValue: intValue) {
                return rain
            } else if let snow = Self.SnowConditions(rawValue: intValue) {
                return snow
            } else if let atmos = Self.AtmosphereConditions(rawValue: intValue) {
                return atmos
            } else if let clouds = Self.CloudConditions(rawValue: intValue) {
                return clouds
            }
            return nil
        }
    }
}

// MARK: - Normalize Values -

/// Converts measurements into `enum` categories.
///

extension CurrentWeather.WeatherConditions {
    enum ThunderstormConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case withLightRain = 200
        case withRain = 201
        case withHeavyRain = 202
        case light = 210
        case normal = 211
        case heavy = 212
        case ragged = 221
        case withLightDrizzle = 230
        case withDrizzle = 231
        case withHeavyDrizzle = 232

        public var stringLabel: String {
            switch self {
            case .withLightRain: return "Thunderstorm (Light Rain)"
            case .withRain: return "Thunderstorm (Normal Rain)"
            case .withHeavyRain: return "Thunderstorm (Heavy Rain)"
            case .light: return "Light Thunderstorm"
            case .normal: return "Moderate Thunderstorm"
            case .heavy: return "Heavy Thunderstorm"
            case .ragged: return "Thunderstorm (Ragged, Unstable Conditions)"
            case .withLightDrizzle: return "Thunderstorm (Light Drizzle)"
            case .withDrizzle: return "Thunderstorm (Drizzle)"
            default: return "Thunderstorm (Heavy Drizzle)"
            }
        }

        var description: String {
            switch self {
            case .withLightRain: return "Thunderstorm (Light Rain)"
            case .withRain: return "Thunderstorm (Normal Rain)"
            case .withHeavyRain: return "Thunderstorm (Heavy Rain)"
            case .light: return "Thunderstorm (Light)"
            case .normal: return "Thunderstorm (Normal)"
            case .heavy: return "Thunderstorm (Heavy)"
            case .ragged: return "Thunderstorm (Ragged)"
            case .withLightDrizzle: return "Thunderstorm (Light Drizzle)"
            case .withDrizzle: return "Thunderstorm (Drizzle)"
            default: return "Thunderstorm (Heavy Drizzle)"
            }
        }

    }

    /// `Drizzles` consist of very small and fine water droplets, typically less than 0.5 mm diameter.
    /// `Rain` is composed of larger droplets.
    enum DrizzleConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case light = 300
        case moderate = 301
        case heavy = 302
        /// The `Drizzle` occurs with `Rain`
        case lightDrizzleRain = 310
        case normalDrizzleRain = 311
        case heavyDrizzleRain = 312

        /// The `Drizzle` occurs in the same area as a rain `Shower`
        case withShowerRain = 313
        case withHeavyShowerRain = 314

        /// The `Drizzle` event is a `Shower` (small and brief localized event)
        case showerDrizzle = 321

        public var stringLabel: String {
            switch self {
            case .light: return "Light Drizzle"
            case .moderate: return "Moderate Drizzle"
            case .heavy: return "Heavy Drizzle"
            case .lightDrizzleRain: return "Drizzle, Light Rain"
            case .normalDrizzleRain: return "Drizzle, Rain"
            case .heavyDrizzleRain: return "Drizzle, Heavy Rain"
            case .withShowerRain: return "Drizzle, Rain Shower"
            case .withHeavyShowerRain: return "Drizzle, Heavy Rain Shower"
            case .showerDrizzle: return "Drizzle Shower"
            }
        }

        var description: String {
            switch self {
            case .light: return "Drizzle (Light)"
            case .moderate: return "Drizzle (Moderate)"
            case .heavy: return "Drizzle (Heavy)"
            case .lightDrizzleRain: return "Drizzle + Rain (Light)"
            case .normalDrizzleRain: return "Drizzle + Rain (Normal)"
            case .heavyDrizzleRain: return "Drizzle + Rain (Heavy)"
            case .withShowerRain: return "Drizzle + Rain Shower"
            case .withHeavyShowerRain: return "Drizzle + Rain Shower (Heavy)"
            case .showerDrizzle: return "Drizzle Shower"
            }
        }
    }

    /// `Rain` is composed of larger droplets than `Drizzles`
    enum RainConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case light = 500
        case moderate = 501
        case heavy = 502
        case veryHeavy = 503
        case extreme = 504
        case freezing = 511
        /// `Shower + Rain`
        /// `Showers` are localized and brief, `Rain` is widespread.
        /// These cases are a combination of these two events occuring in a single weather area.
        case lightShowerRain = 520
        case showerRain = 521
        case heavyShowerRain = 522
        case raggedShowerRain = 531

        var stringLabel: String {
            switch self {
            case .light: return "Light Rain"
            case .moderate: return "Moderate Rain"
            case .heavy: return "Heavy Rain"
            case .veryHeavy: return "Very Heavy Rain"
            case .extreme: return "Extreme Rain"
            case .freezing: return "Freezing Rain"
            case .lightShowerRain: return "Rain (Light Shower)"
            case .showerRain: return "Rain (Moderate Shower)"
            case .heavyShowerRain: return "Rain (Heavy Shower)"
            case .raggedShowerRain: return "Rain (Ragged, Unstable Conditions)"
            }
        }

        var description: String {
            switch self {
            case .light: return "Rain (Light)"
            case .moderate: return "Rain (Moderate)"
            case .heavy: return "Rain (Heavy)"
            case .veryHeavy: return "Rain (Very Heavy)"
            case .extreme: return "Rain (Exteme)"
            case .freezing: return "Rain (Freezing)"
            case .lightShowerRain: return "Rain (Light Shower)"
            case .showerRain: return "Rain (Moderate Shower)"
            case .heavyShowerRain: return "Rain (Heavy Shower)"
            case .raggedShowerRain: return "Rain (Ragged)"
            }
        }
    }

    enum SnowConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case light = 600
        case moderate = 601
        case heavy = 602
        /// `Sleet`
        case sleet = 611
        case lightSleetShower = 612
        case moderateSleetShower = 613
        /// `Snow` with `Rain`
        case withLightRainAndSnow = 615
        case withModerateRainAndSnow = 616
        /// `Snow` is a `Shower`
        case lightSnowShower = 620
        case moderateSnowShower = 621
        case heavySnowShower = 622

        var stringLabel: String {
            switch self {
            case .light: return "Light Snow"
            case .moderate: return "Moderate Snow"
            case .heavy: return "Heavy Snow"
            case .sleet: return "Sleet"
            case .lightSleetShower: return "Sleet (Light Shower)"
            case .moderateSleetShower: return "Sleet (Moderate Shower)"
            case .withLightRainAndSnow: return "Snow & Light Rain"
            case .withModerateRainAndSnow: return "Snow & Moderate Rain"
            case .lightSnowShower: return "Light Snow Shower"
            case .moderateSnowShower: return "Moderate Snow Shower"
            case .heavySnowShower: return "Heavy Snow Shower"
            }
        }

        var description: String {
            switch self {
            case .light: return "Snow  (Light)"
            case .moderate: return "Snow  (Moderate)"
            case .heavy: return "Snow  (Heavy)"
            case .sleet: return "Sleet"
            case .lightSleetShower: return "Sleet (Light Shower)"
            case .moderateSleetShower: return "Sleet (Moderate Shower)"
            case .withLightRainAndSnow: return "Snow + Rain (Light)"
            case .withModerateRainAndSnow: return "Snow + Rain (Moderate)"
            case .lightSnowShower: return "Snow (Light Shower)"
            case .moderateSnowShower: return "Snow (Moderate Shower)"
            case .heavySnowShower: return "Snow (Heavy Shower)"
            }
        }

    }

    enum AtmosphereConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case mist = 701
        case smoke = 711
        case haze = 721
        case sandDustSwirls = 731
        case fog = 741
        case sand = 751
        case dust = 761
        case ash = 762
        case squall = 771
        case tornado = 781

        var stringLabel: String {
            switch self {
            case .mist: return "Mist"
            case .smoke: return "Smoke"
            case .haze: return "Haze"
            case .sandDustSwirls: return "Sand & Dust Swirls"
            case .fog: return "Fog"
            case .sand: return "Sand"
            case .dust: return "Dust"
            case .ash: return "Ash"
            case .squall: return "Squall"
            case .tornado: return "Tornado"
            }
        }

        var description: String {
            switch self {
            case .mist: return "Mist"
            case .smoke: return "Smoke"
            case .haze: return "Haze"
            case .sandDustSwirls: return "Sand + Dust Swirls"
            case .fog: return "Fog"
            case .sand: return "Sand"
            case .dust: return "Dust"
            case .ash: return "Ash"
            case .squall: return "Squall"
            case .tornado: return "Tornado"
            }
        }
    }

    enum DayNightModifier: Int, CustomStringConvertible {
        case day = 0
        case night

        var description: String {
            return self == .day ? "Day" : "Night"
        }
    }

    enum ClearConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case clearSky = 800

        var stringLabel: String {
            return "Clear Sky"
        }

        var description: String {
            return "Clear Sky"
        }
    }

    enum CloudConditions: Int, WeatherIDEnum, CustomStringConvertible {
        case few = 801
        case scattered = 802
        case broken = 803
        case overcast = 804

        var stringLabel: String {
            switch self {
            case .few: "Few Clouds"
            case .scattered: "Scattered Clouds"
            case .broken: "Broken Clouds"
            case .overcast: "Overcast"
            }
        }
        var description: String {
            switch self {
            case .few: "Clouds (Few)"
            case .scattered: "Clouds (Scattered)"
            case .broken: "Clouds (Broken)"
            case .overcast: "Clouds (Overcast)"
            }
        }
    }
}
