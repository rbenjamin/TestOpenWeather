//
//  SnowView.swift
//  Whether
//
//  Created by Ben Davis on 12/7/24.
//

import Foundation
import SwiftUI

struct SnowView: View {
    let snow: CurrentWeather.Snow
    let snowAmount: String
    let hourLabel: String
    let hasSnow: Bool
    let isDaytime: Bool
    var textColor: Color {
        return self.isDaytime ? Color.dayTextColor : Color.nightTextColor
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

