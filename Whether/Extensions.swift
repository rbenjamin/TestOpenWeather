//
//  Extensions.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import Combine
import SwiftUI


extension CGRect {
    
    init(frame: CGRect, insetBy: CGFloat) {
        let insetWidth = frame.size.width - (insetBy * 2)
        let insetHeight = frame.size.height - (insetBy * 2)
        
        self.init(origin: CGPoint(x: (frame.origin.x + insetBy), y: (frame.origin.y + insetBy)),
                  size: CGSize(width: insetWidth, height: insetHeight))
        
    }

}

extension Double {
    
    static func % (lhs: Double, rhs: Double) -> Int {
        let lhs = abs(lhs)
        let rhs = abs(rhs)
        
        var mod = lhs
        while mod >= rhs {
            mod -= rhs
        }
        if lhs < 0 {
            return Int(mod * -1)
        }
        return Int(mod)
    }
}


struct NetworkResponse<Wrapped: Decodable>: Decodable {
    var result: Wrapped
}


extension URLSession {
    func publisher<T: Decodable>(
        for url: URL,
        responseType: T.Type = T.self,
        decoder: JSONDecoder = .init()
    ) -> AnyPublisher<T, Error> {
        dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NetworkResponse<T>.self, decoder: decoder)
            .map(\.result)
            .eraseToAnyPublisher()
    }
}

extension Measurement {
    
    /// Converts from `openWeather` API `standard` temperature Unit,
    /// which is `Kelvin`, into the Device Locale's `UnitTemperature`
    ///
    static func temperatureStandardToUserLocale(_ value: Double, locale: Locale = .autoupdatingCurrent) -> Measurement<UnitTemperature> {
        var current = Measurement<UnitTemperature>(value: value, unit: UnitTemperature.kelvin)
        current.convert(to: UnitTemperature(forLocale: locale))
        return current
    }
    /// Converts from `openWeather` API `standard` speed Unit, which is `meter/second`,
    /// into the Device Locale's `UnitTemperature`

    static func speedStandardToUserLocale(_ value: Double, locale: Locale = .autoupdatingCurrent) -> Measurement<UnitSpeed> {
        var current = Measurement<UnitSpeed>(value: value, unit: UnitSpeed.metersPerSecond)
        current.convert(to: UnitSpeed(forLocale: locale))
        return current
    }
    
    /// Converts from `openWeather` API `standard` pressure Unit, which is `hectopascals` (`hPa`),
    /// into the Device Locale's `UnitPressure`

    static func pressureStandardToUserLocale(_ value: Double, locale: Locale = .autoupdatingCurrent) -> Measurement<UnitPressure> {
        var current = Measurement<UnitPressure>(value: value, unit: UnitPressure.hectopascals)
        current.convert(to: UnitPressure(forLocale: locale))
        return current
    }
    
    static func precipitationStandardToUserLocale(_ value: Double, locale: Locale = .autoupdatingCurrent) -> Measurement<UnitSpeed> {
        let current = Measurement<UnitSpeed>(value: value, unit: UnitSpeed.milimetersPerHour)
        return current
        
    }
}

extension UnitSpeed {
    static let milimetersPerHour: UnitSpeed = UnitSpeed(symbol: "mm/h", converter: UnitConverterLinear(coefficient: 0.001 / 3600.0))
    
    static let inchesPerHour: UnitSpeed = UnitSpeed(symbol: "in/h", converter: UnitConverterLinear(coefficient: 0.0254 / 3600.0))
    
    
}
//
//class UnitPrecipitation: Dimension {
//    static let milimetersPerHour = UnitPrecipitation(symbol: "mm/h", converter: UnitConverterLinear(coefficient: 0.001 / 3600.0))
//    
//    static let baseUnit = milimetersPerHour
//    static let inchesPerHour = UnitPrecipitation(symbol: "in/h", converter: UnitConverterLinear(coefficient: 0.0254 / 3600.0))
//    
//    override var converter: UnitConverter {
//        
//    }
//    
//    override init(forLocale: Locale) {
//        let region = forLocale.region
//        if region == .unitedStates || region == .liberia || region == .myanmar {
//            return UnitPrecipitation.inchesPerHour
//        }
//        
//    }
//}
