//
//  WeatherColors.swift
//  Whether
//
//  Created by Ben Davis on 11/29/24.
//

import Foundation
import SwiftUI

// MARK: - Weather Colors -
/// Returns a color based on the current weather condition (`CurrentWeather.ConditionModifier`). This converts the current temperature into an enum value of `hot`, `normal`, or `cold` to return a color based on the temperature.  Used for app background views.
extension CurrentWeather {

    enum WeatherMeshColors {

        /** Returns a Color object for the current condition.
            - parameter weatherMesh: Provide either `.clearSkyDay` or `.clearSkyNight` with the current condition modifier.
            - returns: The color for the specified temperature.
         
            #Note:#
            - Can be called directly from the ``CurrentWeather`` object with the function `backgroundColor(daytime: Bool)`.
         */
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

        /** Returns a UIColor object for the current condition.
            - parameter weatherMesh: Provide either `.clearSkyDay` or `.clearSkyNight` with the current condition modifier.
            - returns: The color for the specified temperature.
         
             #Note:#
             - Can be called directly from the ``CurrentWeather`` object with the function `backgroundUIColor(daytime: Bool)`.
         */
        private func uiColorForMeshTemperature(_ weatherMesh: WeatherMeshColors) -> UIColor {
            switch weatherMesh {
            case .clearSkyDay(let conditionModifier):
                switch conditionModifier {
                case .hot: return UIColor(named: "ClearSkyHotDay")!
                case .normal: return UIColor(named: "ClearSkyNormalDay")!
                case .cold: return UIColor(named: "ClearSkyColdDay")!
                }
            case .clearSkyNight(let conditionModifier):
                switch conditionModifier {
                case .hot: return UIColor(named: "ClearSkyHotNight")!
                case .normal: return UIColor(named: "ClearSkyNormalNight")!
                case .cold: return UIColor(named: "ClearSkyColdNight")!
                }
            }
        }

        case clearSkyDay(CurrentWeather.ConditionModifier)
        case clearSkyNight(CurrentWeather.ConditionModifier)

        var backgoundFillUIColor: UIColor {
            return uiColorForMeshTemperature(self)
        }

        var backgroundFillColor: Color {
            return colorForMeshTemperature(self)
        }
    }
}
