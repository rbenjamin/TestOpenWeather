//
//  Measurement+Extension.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import Foundation

extension UnitDispersion {
    internal static let microgramsPerCubicMetre = UnitDispersion(symbol: "µg/㎥", converter: UnitConverterLinear(coefficient: 1e-6))
    static func microgramsPerCMFromValue(value: Double) -> Measurement<UnitDispersion> {
        Measurement<UnitDispersion>(value: value, unit: .microgramsPerCubicMetre)
    }

}

extension UnitSpeed {
    static let milimetersPerHour: UnitSpeed = UnitSpeed(symbol: "mm/h", converter: UnitConverterLinear(coefficient: 0.001 / 3600.0))
    static let inchesPerHour: UnitSpeed = UnitSpeed(symbol: "in/h", converter: UnitConverterLinear(coefficient: 0.0254 / 3600.0))
    static func speed(value: Double, unit: UnitSpeed) -> Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: value, unit: unit)
    }
    static func metersPerSecond(_ value: Double) -> Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: value, unit: .metersPerSecond)
    }
    static func milesPerHour(_ value: Double) -> Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: value, unit: .milesPerHour)
    }
}

extension UnitLength {
    static func inchesSnowfall(_ value: Double) -> Measurement<UnitLength> {
            let measurement = Measurement<UnitLength>(value: value, unit: .inches)
        return measurement.converted(to: UnitLength(forLocale: .current, usage: .snowfall))

    }
    static func millimetersSnowfall(_ value: Double) -> Measurement<UnitLength> {
        let measurement = Measurement<UnitLength>(value: value, unit: .millimeters)
        return measurement.converted(to: UnitLength(forLocale: .current, usage: .snowfall))
    }

    static func inchesRain(_ value: Double) -> Measurement<UnitLength> {
            let measurement = Measurement<UnitLength>(value: value, unit: .inches)
        return measurement.converted(to: UnitLength(forLocale: .current, usage: .rainfall))

    }

    static func millimetersRain(_ value: Double) -> Measurement<UnitLength> {
        let measurement = Measurement<UnitLength>(value: value, unit: .millimeters)
        return measurement.converted(to: UnitLength(forLocale: .current, usage: .rainfall))
    }
}

extension UnitTemperature {
    static func temperature(value: Double, unit: UnitTemperature) -> Measurement<UnitTemperature> {
        Measurement<UnitTemperature>(value: value, unit: unit)
    }
    static func fahrenheit(value: Double) -> Measurement<UnitTemperature> {
        Measurement<UnitTemperature>(value: value, unit: .fahrenheit)
    }
    static func celcius(value: Double) -> Measurement<UnitTemperature> {
        Measurement<UnitTemperature>(value: value, unit: .celsius)
    }
}

extension Measurement<UnitTemperature> {
    func formattedWeatherString(width: Measurement<UnitTemperature>.FormatStyle.UnitWidth = .abbreviated,
                                hidesScale: Bool = false) -> String {
        return self.formatted(.measurement(width: width,
                                           usage: .weather,
                                           hidesScaleName: hidesScale,
                                           numberFormatStyle: .number))
    }
}

extension Measurement<UnitSpeed> {
    func formattedWeatherString(width: Measurement<UnitSpeed>.FormatStyle.UnitWidth = .abbreviated,
                                hidesScale: Bool = false) -> String {
        return self.formatted(.measurement(width: width,
                                           usage: .wind,
                                           numberFormatStyle: .number))
    }
}

extension Measurement<UnitPressure> {

    static var pressureFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.locale = Locale.autoupdatingCurrent
        formatter.numberFormatter = numberFormatter
        return formatter
    }
}

extension Measurement {
    static func range(startValue: Double, endValue: Double, unit: UnitType) -> ClosedRange<Measurement<Unit>> {
        let lowerBound = Measurement<Unit>.init(value: startValue, unit: unit)
        let upperBound = Measurement<Unit>.init(value: endValue, unit: unit)
        return lowerBound ... upperBound
    }
}

extension Measurement {

    /// Creates a closed range between two values of the same `unit`:
    /// Converts from `openWeather` API `standard` temperature Unit,
    /// which is `Kelvin`, into the Device Locale's `UnitTemperature`
    ///
    static func temperatureStandardToUserLocale(_ value: Double,
                                                locale: Locale = .current) -> Measurement<UnitTemperature> {
        var current = Measurement<UnitTemperature>(value: value, unit: UnitTemperature.kelvin)
        current.convert(to: UnitTemperature(forLocale: locale, usage: .weather))
        return current
    }
    /// Converts from `openWeather` API `standard` speed Unit, which is `meter/second`,
    /// into the Device Locale's `UnitTemperature`

    static func speedStandardToUserLocale(_ value: Double,
                                          locale: Locale = .current) -> Measurement<UnitSpeed> {
        var current = Measurement<UnitSpeed>(value: value, unit: UnitSpeed.metersPerSecond)
        current.convert(to: UnitSpeed(forLocale: locale, usage: .asProvided))
        return current
    }
    /// Converts from `openWeather` API `standard` pressure Unit, which is `hectopascals` (`hPa`),
    /// into the Device Locale's `UnitPressure`

    static func pressureStandardToUserLocale(_ value: Double,
                                             initialUnit: UnitPressure = .hectopascals,
                                             locale: Locale = .current) -> Measurement<UnitPressure> {
        // 1. Create pressure as hectopascals (hPa) -- this is what OpenWeather returns.
        let fromAPI = Measurement<UnitPressure>.init(value: value, unit: initialUnit)
        // 2. Convert to local pressure unit:
        let toLocal = fromAPI.converted(to: UnitPressure(forLocale: locale, usage: .barometric))
        return toLocal
    }
    static func rainfallStandardToUserLocale(_ value: Double,
                                             locale: Locale = .current) -> Measurement<UnitLength> {
        var current = Measurement<UnitLength>(value: value, unit: .millimeters)
        current.convert(to: UnitLength(forLocale: locale, usage: .rainfall))
        return current
    }

    static func snowfallStandardToUserLocale(_ value: Double,
                                             locale: Locale = .current) -> Measurement<UnitLength> {
        var current = Measurement<UnitLength>(value: value, unit: .millimeters)
        current.convert(to: UnitLength(forLocale: locale, usage: .snowfall))
        return current
    }

    static func visibilityStandardToUserLocale(_ value: Double,
                                               locale: Locale = .current) -> Measurement<UnitLength> {
        var current = Measurement<UnitLength>(value: value, unit: .meters)
        current.convert(to: UnitLength(forLocale: locale, usage: MeasurementFormatUnitUsage<UnitLength>.visibility))
        return current
    }
}
