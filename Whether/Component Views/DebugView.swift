//
//  DebugView.swift
//  Whether
//
//  Created by Ben Davis on 11/29/24.
//

import SwiftUI

struct DebugView: View {
    @Binding var main: CurrentWeather.MainWeather?
    @Binding var conditions: CurrentWeather.WeatherConditions?
    @Binding var pollution: Pollution?
    let textColor: Color
    let isDaytime: Bool
    let locality: String

    init(main: Binding<CurrentWeather.MainWeather?>,
         conditions: Binding<CurrentWeather.WeatherConditions?>,
         pollution: Binding<Pollution?>,
         textColor: Color,
         isDaytime: Bool,
         locality: String) {
        _main = main
        _conditions = conditions
        _pollution = pollution
        self.textColor = textColor
        self.isDaytime = isDaytime
        self.locality = locality
    }

    var body: some View {
        GroupBox("Debug View") {
            LabeledContent("Current Default: ") {
                Text(self.locality)
            }
            .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))

            if let main {
                LabeledContent("Min:",
                               value: main.minTemp.formatted(.measurement(usage: .weather)))
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
                LabeledContent("Max:",
                               value: main.maxTemp.formatted(.measurement(usage: .weather)))
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
                Divider()

                LabeledContent("Ground Pressure:",
                               value: main.groundLevel.formatted(.measurement(width: .abbreviated,
                                                                              usage: .barometric)))
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))

                LabeledContent("Sea Pressure:",
                               value: main.seaLevel.formatted(.measurement(width: .abbreviated,
                                                                           usage: .barometric)))
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
            }
            Divider()
            if let label = conditions?.condition?.stringLabel {
                LabeledContent("Conditions:", value: label)
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
            }
            Divider()
            if let comps = self.pollution?.readings.first?.components {
                let keys = Array(comps.keys)
                ForEach(0 ..< keys.count, id: \.self) { idx in
                    let key = keys[idx]
                    let value: Measurement<UnitDispersion> = comps[key]!
                    LabeledContent(key.rawValue,
                                   value: value.formatted(.measurement(width: .abbreviated,
                                                                       usage: .asProvided)))
                    .labeledContentStyle(WeatherLabelStyle(foregroundStyle: self.textColor))
                }
            }

        }
        .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))

    }
}

#Preview {
    DebugView(main: .constant(nil),
              conditions: .constant(nil),
              pollution: .constant(Pollution.mockPollution(date: Date(), quality: .fair)),
              textColor: .primary,
              isDaytime: true,
              locality: "New York")
}
