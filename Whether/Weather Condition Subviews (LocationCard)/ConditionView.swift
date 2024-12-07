//
//  ConditionView.swift
//  Whether
//
//  Created by Ben Davis on 11/7/24.
//

import SwiftUI

/// `ConditionView` is the "Summary" view - contains icon, locality, temperature, weather descriptions.
///

struct ConditionView: View {
    let condition: CurrentWeather.WeatherConditions?
    let isDaytime: Bool
    let mainWeather: CurrentWeather.MainWeather?
    let locality: String
    let isGPSWeather: Bool

    @State private var tempString: String = ""
    @State private var gaugeTemp: Measurement<UnitTemperature>?
    @State private var mainLabel: String = ""
    @State private var weatherDetails: String = ""
    @State private var conditionImage: Image?

    init(condition: CurrentWeather.WeatherConditions?,
         mainWeather: CurrentWeather.MainWeather?,
         locality: String,
         isGPSWeather: Bool,
         isDaytime: Bool) {
        self.condition = condition
        self.mainWeather = mainWeather
        self.locality = locality

        self.isGPSWeather = isGPSWeather
        self.isDaytime = isDaytime
    }

    var textColor: Color {
        return self.isDaytime ? Color.dayTextColor : Color.nightTextColor
    }

    var body: some View {
        ZStack {
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(self.locality)
                                .font(.system(.title, design: .rounded, weight: .regular))
                                .foregroundStyle(self.isDaytime ? Color.black : Color.white)
                            +
                            Text(self.isGPSWeather ? " \(Image(systemName: "location"))" : "")
                                .font(.system(.headline, design: .rounded, weight: .regular))
                                .foregroundStyle(Color.blue)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(self.locality))
                        .accessibilityHint(self.isGPSWeather ? Text("Current Location") : Text("Visible Location"))

                        Text(tempString)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(self.textColor)
                            .accessibilityHint(Text("Current Temperature"))
                        Text(self.mainLabel)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(self.textColor)
                            .accessibilityHint(Text("Weather Conditions"))
                        Text(self.weatherDetails)
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(self.textColor)
                            .accessibilityHint(Text("Detailed Conditions"))
                    }
                    Spacer()

                    HStack(spacing: 0) {
                        if let conditionImage {
                            conditionImage
                                .resizable()
                                .offset(y: 12)
                                .transition(.blurReplace.combined(with: .scale))
                        }
                    }
                    .frame(width: 120, height: 120)
                    .accessibilityHint(Text("Image of Current Weather Conditions"))

                    TemperatureGauge(temperature: self.$gaugeTemp,
                                     width: 14.0)
                    .frame(height: 110)
                }
            }
            .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime, shouldHighlight: true))
            .accessibilityLabel(Text("Weather Overview"))
            .onChange(of: self.condition) { oldValue, newValue in
//                print("condition changed (\(self.locality))")
                if oldValue != newValue, let newValue {
                    withAnimation(.bouncy) {
                        let details = newValue.weatherDetails.capitalized
                        self.mainLabel = newValue.mainLabel.capitalized
                        self.weatherDetails = newValue.condition?.stringLabel ?? details
                        self.conditionImage = newValue.image(forDaytime: self.isDaytime)
                    }
                }
            }
            .onChange(of: self.mainWeather) { oldValue, newValue in
                if oldValue != newValue, let newValue {
                    self.tempString = newValue.temperature.formattedWeatherString()
                    withAnimation(.interpolatingSpring.delay(0.5)) {
                        self.gaugeTemp = newValue.temperature
                    }
                }
            }
            .onAppear {
                if let condition {
                    let details = condition.weatherDetails.capitalized
                    withAnimation(.bouncy) {
                        self.mainLabel = condition.mainLabel.capitalized
                        self.weatherDetails = condition.condition?.stringLabel ?? details

                        self.conditionImage = condition.image(forDaytime: self.isDaytime)
                    }
                }
                if let mainWeather {
                    withAnimation(.bouncy) {
                        self.tempString = mainWeather.temperature.formattedWeatherString()
                    }
                    withAnimation(.interpolatingSpring.delay(0.5)) {
                        self.gaugeTemp = mainWeather.temperature.converted(to: .celsius)
                    }
                }
            }
        }
    }
}

#Preview {
    let conditions = CurrentWeather.WeatherConditions(id: CurrentWeather.WeatherConditions.RainConditions.moderate.rawValue,
                                                      mainLabel: "Moderate Rain",
                                                      description: "Moderate Rain",
                                                      icon: "")
    let curr = Measurement<UnitTemperature>(value: 74.0, unit: .fahrenheit)
    let feelsLike = Measurement<UnitTemperature>(value: 76.0, unit: .fahrenheit)

    let min = Measurement<UnitTemperature>(value: 74.0, unit: .fahrenheit)
    let max = Measurement<UnitTemperature>(value: 78.0, unit: .fahrenheit)
    let pressure = Measurement<UnitPressure>(value: 1, unit: .hectopascals)
    let mainWeather = CurrentWeather.MainWeather(temperature: curr,
                                                 feelsLike: feelsLike,
                                                 minTemp: min,
                                                 maxTemp: max,
                                                 pressure: pressure,
                                                 humidity: 40.0,
                                                 seaLevel: pressure,
                                                 groundLevel: pressure)
    ConditionView(condition: conditions,
                         mainWeather: mainWeather,
                         locality: "Asheville",
                         isGPSWeather: false,
                         isDaytime: true)
}
