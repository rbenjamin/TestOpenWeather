//
//  RainView.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import SwiftUI

struct RainView: View {
    let rain: CurrentWeather.Rain
    let rainAmount: String
    let hourLabel: String
    let hasRain: Bool
    let isDaytime: Bool

    var textColor: Color {
        return self.isDaytime ? Color.secondary : Color("NightTextColor")
    }

    init(rain: CurrentWeather.Rain, isDaytime: Bool) {
        self.isDaytime = isDaytime
        if let oneHour = rain.oneHour {
            self.rainAmount = oneHour.formatted(.measurement(width: .abbreviated,
                                                             usage: .rainfall,
                                                             numberFormatStyle: .number))
            self.hourLabel = "Hour"
            self.hasRain = true
        } else {
            let hasRain = rain.threeHour != nil

            self.rainAmount = hasRain ? rain.threeHour!.formatted(.measurement(width: .abbreviated,
                                                                               usage: .rainfall,
                                                                               numberFormatStyle: .number)) : ""
            self.hourLabel = hasRain ? "3 Hours" : ""
            self.hasRain = hasRain
        }
        self.rain = rain
    }

    var body: some View {
        if hasRain {
            GroupBox("Rain") {
                LabeledContent("Rain / \(hourLabel)", value: self.rainAmount)
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
            }
            .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))
        }
    }
}

#Preview {
    RainView(rain: CurrentWeather.Rain(oneHour: nil,
                                       threeHour: Measurement.rainfallStandardToUserLocale(0.85, locale: .current)),
             isDaytime: true)
}

struct SnowView: View {
    let snow: CurrentWeather.Snow
    let snowAmount: String
    let hourLabel: String
    let hasSnow: Bool
    let isDaytime: Bool
    var textColor: Color {
        return self.isDaytime ? Color.secondary : Color("NightTextColor")
    }

    init(snow: CurrentWeather.Snow, isDaytime: Bool) {

        self.isDaytime = isDaytime
        self.snow = snow
        if let oneHour = snow.oneHour {
            self.snowAmount = oneHour.formatted(.measurement(width: .abbreviated,
                                                             usage: .snowfall,
                                                             numberFormatStyle: .number))
            self.hourLabel = "Hour"
            self.hasSnow = true
        } else {
            let hasSnow = snow.threeHour != nil
            self.snowAmount =  hasSnow ? snow.threeHour!.formatted(.measurement(width: .abbreviated, usage: .snowfall, numberFormatStyle: .number)) : ""
            self.hourLabel = hasSnow ? "3 Hours" : ""
            self.hasSnow = hasSnow
        }
    }

    var body: some View {
        if hasSnow {
            GroupBox("Snow") {

                LabeledContent("Snow / \(hourLabel)", value: self.snowAmount)
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
            }
            .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))

        }
    }
}

#Preview {
    SnowView(snow: CurrentWeather.Snow(oneHour: Measurement.snowfallStandardToUserLocale(0.85, locale: .current),
                                       threeHour: Measurement.snowfallStandardToUserLocale(0.85, locale: .current)),
             isDaytime: true)
}
