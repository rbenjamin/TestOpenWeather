//
//  CurrentWeather.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import CoreFoundation
import CoreLocation
import SwiftUI

struct CurrentWeather: Identifiable, Codable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case timeZone = "timezone"
        case position = "coord"
        case conditions = "weather"
        case mainWeather = "main"
        case wind = "wind"
        case clouds = "clouds"
        case rain = "rain"
        case snow = "snow"
        case visibility = "visibility"
        case system = "sys"
        case code = "cod"
    }
    
    /// `Modifiers` converts degrees Kelvin into an enum.
    /// Used for design calculations, not user-visible data.
    ///
    enum ConditionModifier: Int, CaseIterable {
        case hot
        case normal
        case cold
        
        var localizedString: String {
            switch self {
            case .hot:
                return "hot"
            case .normal:
                return "normal"
            case .cold:
                return "cold"
            }
        }
        
        init(temperature: Double) {
            if (0 ..< 288.15) ~= (temperature) { self = .cold }
            else if (288.15 ..< 298.15) ~= (temperature) { self = .normal }
            else { self = .hot }
        }
        
        
        
    }
    
    var meshColors: [Color] {
        return WeatherMeshColors.clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.value)).meshColors
    }
    
    var meshBackgroundColor: Color {
        return WeatherMeshColors.clearSkyDay(ConditionModifier(temperature: self.mainWeather.feelsLike.value)).backgroundFillColor
    }
    
    let id: UUID = UUID()
    
    let position: CurrentWeather.Position
    let conditions: [WeatherConditions]
    let mainWeather: MainWeather
    let wind: Wind?
    let clouds: Clouds?
    let rain: Rain?
    let snow: Snow?
    let visibility: Double
    let system: CurrentWeather.System
    let timeZone: Double
    let code: Double
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timeZone = try container.decode(Double.self, forKey: .timeZone)
        self.position = try container.decode(CurrentWeather.Position.self, forKey: .position)
        let conditions = try container.decode(Array<WeatherConditions>.self, forKey: .conditions)
        
        
        self.conditions = conditions
        
        self.mainWeather = try container.decode(CurrentWeather.MainWeather.self, forKey: .mainWeather)
        self.wind = try container.decodeIfPresent(CurrentWeather.Wind.self, forKey: .wind)
        self.clouds = try container.decodeIfPresent(CurrentWeather.Clouds.self, forKey: .clouds)
        self.rain = try container.decodeIfPresent(CurrentWeather.Rain.self, forKey: .rain)
        self.snow = try container.decodeIfPresent(CurrentWeather.Snow.self, forKey: .snow)
        self.visibility = try container.decode(Double.self, forKey: .visibility)
        self.system = try container.decode(CurrentWeather.System.self, forKey: .system)
        self.code = try container.decode(Double.self, forKey: .code)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.timeZone, forKey: .timeZone)
        try container.encode(self.position, forKey: .position)
        try container.encode(self.conditions, forKey: .conditions)
        try container.encode(self.mainWeather, forKey: .mainWeather)
        try container.encode(self.wind, forKey: .wind)
        try container.encode(self.clouds, forKey: .clouds)
        try container.encode(self.rain, forKey: .rain)
        try container.encode(self.snow, forKey: .snow)
        try container.encode(self.visibility, forKey: .visibility)
        try container.encode(self.system, forKey: .system)
        try container.encode(self.code, forKey: .code)
    }
    
    
    
    init(position: CurrentWeather.Position, conditions: [WeatherConditions], mainWeather: MainWeather, wind: Wind, clouds: Clouds, rain: Rain, snow: Snow, visibility: Double, system: CurrentWeather.System, timeZone: Double, code: Double) {
        self.position = position
        self.conditions = conditions
        self.mainWeather = mainWeather
        self.wind = wind
        self.clouds = clouds
        self.rain = rain
        self.snow = snow
        self.visibility = visibility
        self.system = system
        self.timeZone = timeZone
        self.code = code
    }
    
    
    
    struct Position: Identifiable, Codable, Equatable {
        let id = UUID()
        let longitude: CLLocationDegrees
        let latitude: CLLocationDegrees
        
        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitude = "lat"
        }
        
        init(longitude: CLLocationDegrees, latitude: CLLocationDegrees) {
            self.longitude = longitude
            self.latitude = latitude
        }
        
        var coordinates: CLLocation {
            return CLLocation(latitude: self.latitude, longitude: self.longitude)
        }
    }
    
    struct WeatherConditions: Identifiable, Codable, Equatable {
        let id: Double
        let mainLabel: String
        let description: String
        let icon: String
        
        var iconURL: URL {
            URL(string: "https://openweathermap.org/img/wn/\(self.icon)@2x.png")!
        }
        
        init(id: Double, mainLabel: String, description: String, icon: String) {
            self.id = id
            self.mainLabel = mainLabel
            self.description = description
            self.icon = icon
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case mainLabel = "main"
            case description = "description"
            case icon = "icon"
        }
        
        
    }
    
    struct MainWeather: Identifiable, Codable, Equatable {
        let id = UUID()
        let temperature: Measurement<UnitTemperature>
        let feelsLike: Measurement<UnitTemperature>
        let minTemp: Measurement<UnitTemperature>
        let maxTemp: Measurement<UnitTemperature>
        let pressure: Measurement<UnitPressure>
        let humidity: Double
        let seaLevel: Measurement<UnitPressure>
        let groundLevel: Measurement<UnitPressure>
        
        init(from decoder: any Decoder) throws {
            
            let container: KeyedDecodingContainer<CurrentWeather.MainWeather.CodingKeys> = try decoder.container(keyedBy: CurrentWeather.MainWeather.CodingKeys.self)
            
            
            /// OpenWeather - returns in kelvin (we want to convert based on device settings, rather than requesting a specific unit from OpenWeather.
            let kTemp = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.temperature).rounded()
            self.temperature = Measurement.temperatureStandardToUserLocale(kTemp)
            
            
            let kFeelsLike = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.feelsLike).rounded()
            self.feelsLike = Measurement.temperatureStandardToUserLocale(kFeelsLike)
          
            let kMinTemp = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.minTemp).rounded()
            self.minTemp = Measurement.temperatureStandardToUserLocale(kMinTemp)
           
            let kMaxTemp = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.maxTemp).rounded()
            self.maxTemp = Measurement.temperatureStandardToUserLocale(kMaxTemp)
           
            let hPaPressure = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.pressure)
            self.pressure = Measurement.pressureStandardToUserLocale(hPaPressure)
            
            self.humidity = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.humidity).rounded()
          
            let hPaSeaLevel = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.seaLevel)
            self.seaLevel = Measurement.pressureStandardToUserLocale(hPaSeaLevel)
         
            let hPaGroundLevel = try container.decode(Double.self, forKey: CurrentWeather.MainWeather.CodingKeys.groundLevel)
            self.groundLevel = Measurement.pressureStandardToUserLocale(hPaGroundLevel)
        }
        
        init(temperature: Measurement<UnitTemperature>,
             feelsLike: Measurement<UnitTemperature>,
             minTemp: Measurement<UnitTemperature>,
             maxTemp: Measurement<UnitTemperature>,
             pressure: Measurement<UnitPressure>,
             humidity: Double,
             seaLevel: Measurement<UnitPressure>,
             groundLevel: Measurement<UnitPressure>) {
            
            self.temperature = temperature
            self.feelsLike = feelsLike
            self.minTemp = minTemp
            self.maxTemp = maxTemp
            self.pressure = pressure
            self.humidity = humidity
            self.seaLevel = seaLevel
            self.groundLevel = groundLevel
        }
        
        enum CodingKeys: String, CodingKey {
            case temperature = "temp"
            case feelsLike = "feels_like"
            case minTemp = "temp_min"
            case maxTemp = "temp_max"
            case pressure = "pressure"
            case humidity = "humidity"
            case seaLevel = "sea_level"
            case groundLevel = "grnd_level"
        }
    }
    
    struct Wind: Identifiable, Codable, Equatable {
        
        /// `WindDirection` enumeration normalizes wind direction (in meteorological degrees).  Currently used for internal logic; not used for user-facing data.
        ///

        enum WindDirection: CaseIterable {
            /// 22.5 degree difference between `WindDirection` cases
            ///
                case north              // 0 deg
                case northNorthEast     // 22.5 deg between north and north-east
                case northEast          // 45 deg
                case eastNorthEast      // 67.5 between east and north-east
                case east               // 90
                case eastSouthEast      // betweeen east and south-east
                case southEast
                case southSouthEast     // betweeen south and south-east
                case south
                case southSouthWest     // between south and south-west
                case southWest
                case westSouthWest      // betweeen west and south-west
                case west
                case westNorthWest      // between west and north-west
                case northWest
                case northNorthWest     // between north and north-west
                
                init(degrees: Double) {
                    self = Self.windDirectionForDegrees(degrees)
                }
            }
            
        /// `WindSpeed` enumeration converts speed (meters/second) into categories.  Currently used for internal logic; not used for user-facing data.
        ///
        /// case `none`: 0 m/s
        /// case `slow`: 1 - 3 m/s (rustling leaves, drifting smoke, outdoor activities)
        /// case `normal`: 3 - 8 m/s (small branches move, flags extend, typical wind conditions)
        /// case `fast`: 8 - 15 m/s (large branches move, umbrellas fail, difficulty walking)
        /// case `extreme`: 15+ m/s (trees fall, structural damage, dangerous for outdoor activities)
        ///
            enum WindSpeedCategory: CaseIterable {
                case none
                case slow
                case normal
                case fast
                case extreme
                
                init(speed: Double) {
                    if (0 ..< 1) ~= speed { self = .none }
                    else if (1 ..< 3) ~= speed { self = .slow }
                    else if (3 ..< 8) ~= speed { self = .normal }
                    else if (8 ..< 15) ~= speed { self = .fast }
                    else {
                        self = .extreme
                    }
                }
            }
        
            let id = UUID()
            let windSpeed: Measurement<UnitSpeed>
            /// wind direction, degrees meteorological
            let direction: Double
            let gustLevel: Double
        
            var speedCategory: WindSpeedCategory {
                .init(speed: self.windSpeed.value)
            }
        
            var cardinalDirection: WindDirection {
                .init(degrees: self.direction)
            }
            
            enum CodingKeys: String, CodingKey {
                case windSpeed = "speed"
                case direction = "deg"
                case gustLevel = "gust"
            }
            
            init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<CurrentWeather.Wind.CodingKeys> = try decoder.container(keyedBy: CurrentWeather.Wind.CodingKeys.self)
                let doubleSpeed = try container.decode(Double.self, forKey: CurrentWeather.Wind.CodingKeys.windSpeed)
                self.windSpeed = Measurement.speedStandardToUserLocale(doubleSpeed)
                self.direction = try container.decode(Double.self, forKey: CurrentWeather.Wind.CodingKeys.direction)
                self.gustLevel = try container.decode(Double.self, forKey: CurrentWeather.Wind.CodingKeys.gustLevel)
            }
    
            init(windSpeed: Measurement<UnitSpeed>, direction: Double, gustLevel: Double) {
                self.windSpeed = windSpeed
                self.direction = direction
                self.gustLevel = gustLevel
            }
        }
    
        struct Clouds: Identifiable, Codable, Equatable {
            /// % cloudiness
            let id = UUID()
            let cloudiness: Double
            
            enum CodingKeys: String, CodingKey {
                case cloudiness = "all"
            }
    
            init(cloudiness: Double = 0.0) {
                self.cloudiness = cloudiness
            }
        }
    
        struct Rain: Identifiable, Codable, Equatable {
            /// (where available) Precipitation, mm/h. Please note that only mm/h as units of measurement are available for this parameter
            let id: UUID = UUID()
            let oneHour: Double
            
            enum CodingKeys: String, CodingKey {
                case oneHour = "1h"
            }
            init(oneHour forecast: Double) {
                self.oneHour = forecast
            }
        }
        /// `Snow` (where available) Precipitation, mm/h.
        /// Please note that only mm/h as units of measurement are available for this parameter.
        ///
        struct Snow: Identifiable, Codable, Equatable {
            
            /// `WindSpeed` enumeration converts speed (meters/second) into categories.  Currently used for internal logic; not used for user-facing data.
            ///
            /// case `none`: 0 m/s
            /// case `slow`: 1 - 3 m/s (rustling leaves, drifting smoke, outdoor activities)
            /// case `normal`: 3 - 8 m/s (small branches move, flags extend, typical wind conditions)
            /// case `fast`: 8 - 15 m/s (large branches move, umbrellas fail, difficulty walking)
            /// case `extreme`: 15+ m/s (trees fall, structural damage, dangerous for outdoor activities)
            ///
                enum SnowDensity: CaseIterable {
                    case light
                    case medium
                    case heavy
                    case extreme
                    
                    var localizedString: String {
                        switch self {
                        case .light:
                            return "light"
                        case .medium:
                            return "medium"
                        case .heavy:
                            return "heavy"
                        case .extreme:
                            return "extreme"
                        }
                    }
                    
                    init(oneHour forecast: Double) {
                        if (0 ..< 1) ~= forecast { self = .light }
                        else if (1 ..< 4) ~= forecast { self = .medium }
                        else if (4 ..< 7) ~= forecast { self = .heavy }
                        else {
                            self = .extreme
                        }
                    }
                }
            var snowDensity: SnowDensity {
                .init(oneHour: self.oneHour)
            }

            let id: UUID = UUID()
            let oneHour: Double
            
            enum CodingKeys: String, CodingKey {
                case oneHour = "1h"
            }
            
            init(oneHour forecast: Double) {
                self.oneHour = forecast
            }
        }
    
        struct System: Identifiable, Codable, Equatable {
            let id = UUID()
            let country: String
            let sunrise: Date
            let sunset: Date
            
            enum CodingKeys: String, CodingKey {
                case country = "country"
                case sunrise = "sunrise"
                case sunset = "sunset"
            }
            
            init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<CurrentWeather.System.CodingKeys> = try decoder.container(keyedBy: CurrentWeather.System.CodingKeys.self)
                self.country = try container.decode(String.self, forKey: CodingKeys.country)
                self.sunrise = try container.decode(Date.self, forKey: CodingKeys.sunrise)
                self.sunset = try container.decode(Date.self, forKey: CodingKeys.sunset)
            }
    
            init(country: String, sunrise: Date, sunset: Date) {
                self.country = country
                self.sunrise = sunrise
                self.sunset = sunset
            }
        }

    

}

extension CurrentWeather {
    
    enum WeatherMeshColors {
        
        private func colorForMeshTemperature(_ weatherMesh: WeatherMeshColors) -> Color {
            switch weatherMesh {
            case .clearSkyDay(let conditionModifier):
                switch conditionModifier {
                case .hot:
                    return .clearSkyHotDay
                case .normal:
                    return .clearSkyNormalDay
                case .cold:
                    return .clearSkyColdDay
                }
            case .clearSkyNight(let conditionModifier):
                switch conditionModifier {
                case .hot:
                    return .clearSkyHotNight
                case .normal:
                    return .clearSkyNormalNight
                case .cold:
                    return .clearSkyColdNight
                }
            }
        }
        
        case clearSkyDay(CurrentWeather.ConditionModifier)
        case clearSkyNight(CurrentWeather.ConditionModifier)
        
        
        var backgroundFillColor: Color {
            return colorForMeshTemperature(self)
        }
        
        var meshColors: [Color] {
            let colorValue = colorForMeshTemperature(self)
            switch self {
            case .clearSkyDay(let modifiers):
                switch modifiers {
                case .hot:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .red,       colorValue,
                            colorValue, colorValue, colorValue
                           ]
                case .normal:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .yellow,    colorValue,
                            colorValue, colorValue, colorValue
                           ]
                case .cold:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .yellow,    colorValue,
                            colorValue, colorValue, colorValue
                           ]
                }
            case .clearSkyNight(let modifiers):
                switch modifiers {
                case .hot:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .red,    colorValue,
                            colorValue, colorValue, colorValue
                           ]
                case .normal:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .yellow,    colorValue,
                            colorValue, colorValue, colorValue
                           ]
                case .cold:
                    return [
                            colorValue, colorValue, colorValue,
                            colorValue, .yellow,    colorValue,
                            colorValue, colorValue, colorValue
                           ]
                }
            }
        }
        
    }
    
   
}

extension CurrentWeather {
    struct NetworkResponse: Codable {
        
        enum CodingKeys: String, CodingKey {
            case result = "result"
        }
        var result: CurrentWeather
    }
}

extension CurrentWeather.Wind.WindDirection {
    typealias WindDirection = CurrentWeather.Wind.WindDirection
    static func windDirectionForDegrees(_ degrees: Double) -> WindDirection {
        if (348.75 ... 360.0).contains(degrees) || (0 ..< 11.25).contains(degrees) { return .north
        } else if (11.25 ..< 33.75).contains(degrees) { return .northNorthEast
        } else if (33.75 ..< 56.25).contains(degrees) { return .northEast
        } else if (56.25 ..< 78.75).contains(degrees) { return .eastNorthEast
        } else if (78.75 ..< 101.25).contains(degrees) { return .east
        } else if (101.25 ..< 123.75).contains(degrees) { return .eastSouthEast
        } else if (123.75 ..< 146.25).contains(degrees) { return .southEast
        } else if (146.25 ..< 168.75).contains(degrees) { return .southSouthEast
        } else if (168.75 ..< 191.25).contains(degrees) { return .south
        } else if (191.25 ..< 213.75).contains(degrees) { return .southSouthWest
        } else if (213.75 ..< 236.25).contains(degrees) { return .southWest
        } else if (236.25 ..< 258.75).contains(degrees) { return .westSouthWest
        } else if (258.75 ..< 281.25).contains(degrees) { return .west
        } else if (281.25 ..< 303.75).contains(degrees) { return .westNorthWest
        } else if (303.75 ..< 326.25).contains(degrees) { return .northWest
        } else { return .northNorthWest
        }
    }

    func normalizedDegrees() -> Double {
        switch self {
        case .north: return 0.0
        case .northNorthEast: return 22.5
        case .northEast: return 45
        case .eastNorthEast: return 67.5
        case .east: return 90
        case .eastSouthEast: return 112.5
        case .southEast: return 135
        case .southSouthEast: return 157.5
        case .south: return 180
        case .southSouthWest: return 202.5
        case .southWest: return 225
        case .westSouthWest: return 247.5
        case .west: return 270
        case .westNorthWest: return 292.5
        case .northWest: return 315
        case .northNorthWest: return 337.5
        }
    }

    
    var stringLabel: String {
        switch self {
        case .north: return "N"
        case .northNorthEast: return "NNE"
        case .northEast: return "NE"
        case .eastNorthEast: return "ENE"
        case .east: return "E"
        case .eastSouthEast: return "ESE"
        case .southEast: return "SE"
        case .southSouthEast: return "SSE"
        case .south: return "S"
        case .southSouthWest: return "SSW"
        case .southWest: return "SW"
        case .westSouthWest: return "WSW"
        case .west: return "W"
        case .westNorthWest: return "WNW"
        case .northWest: return "NW"
        case .northNorthWest: return "NNW"
        }
    }

}
