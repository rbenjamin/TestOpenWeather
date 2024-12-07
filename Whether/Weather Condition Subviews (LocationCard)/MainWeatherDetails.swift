//
//  MainWeatherDetails.swift
//  Whether
//
//  Created by Ben Davis on 11/12/24.
//

import SwiftUI

/// `MainWeatherDetails` contains temperature, feels like, humidity, min/max
/// 

struct MainWeatherDetails: View {
    @Binding var mainWeather: CurrentWeather.MainWeather?
    @Binding var pollution: Pollution?
    @Binding var currentWeather: CurrentWeather?
    let pressureFormatter: MeasurementFormatter
    let percentFormatter: NumberFormatter
    let isDaytime: Bool
    let locationName: String

    init(mainWeather: Binding<CurrentWeather.MainWeather?>,
         currentWeather: Binding<CurrentWeather?>,
         pollution: Binding<Pollution?>,
         isDaytime: Bool,
         pressureFormatter: MeasurementFormatter,
         percentFormatter: NumberFormatter,
         locationName: String) {
        _currentWeather = currentWeather
        self.locationName = locationName
        _pollution = pollution
        self.isDaytime = isDaytime
        _mainWeather = mainWeather
        self.pressureFormatter = pressureFormatter
        self.percentFormatter = percentFormatter
    }

    @State private var temperature: String?
    @State private var feelsLike: String?
    @State private var minTemp: String?
    @State private var maxTemp: String?
    @State private var humidity: String?
    @State private var cloudiness: String?
    @State private var airQualityLabel: String?
    @State private var airQualityNumber: Int?

    @State private var pressure: Measurement<UnitPressure>?
    @State private var guagePressure = Measurement<UnitPressure>(value: 0, unit: .hectopascals)
    @State private var pressureString: String?
    @State private var gaugeTemp: Measurement<UnitTemperature>?

    let fillGradient = LinearGradient(colors: [Color("HighPressureColor"),
                                               Color("LowPressureColor")],
                                      startPoint: .bottomLeading,
                                      endPoint: .bottomTrailing)

    let pressureRange = Measurement<UnitPressure>.range(startValue: 960,
                                                        endValue: 1020,
                                                        unit: .hectopascals)
    var textColor: Color {
        return self.isDaytime ? Color.dayTextColor : Color.nightTextColor
    }

    var body: some View {

        GroupBox("Today") {
                LoadableLabel(value: self.$temperature,
                             label: "Temperature", textColor: self.textColor)

                LoadableLabel(value: self.$feelsLike,
                             label: "Feels Like", textColor: self.textColor)

                TemperatureGauge(temperature: self.$gaugeTemp,
                                 height: 24.0)
                Divider()
                    .padding([.top, .bottom], 8)
                LoadableLabel(value: self.$airQualityLabel,
                             label: "Air Quality", textColor: self.textColor)
                LoadableLabel(value: self.$cloudiness,
                             label: "Cloud Cover", textColor: self.textColor)
                LoadableLabel(value: self.$humidity,
                             label: "Humidity", textColor: self.textColor)
                HStack {
                    /// Since low pressure is consistent with storm or weather event,
                    /// and "high" pressure is consistent with fair weather,
                    /// We style the gauge so low pressure is red and high pressure is blue.
                    ///
                    LoadableLabelContent("Pressure", value: self.$pressure, textColor: self.textColor) { pressure in
                        let pressureFormatted = self.pressureFormatter.string(from: pressure)
                        return pressureFormatted
                    } content: { pressure in
                        HStack {
                            Spacer()
                            GaugeView(value: self.$guagePressure,
                                      fill: self.fillGradient,
                                      range: self.pressureRange)
                            .labels(leading: {
                                Text(Image(systemName: "cloud.bolt"))
                                    .font(.caption)
                                    .foregroundStyle(self.textColor)
                            }, leadingOffset: CGPoint(x: -2, y: 0),
                                    trailing: {
                                Text(Image(systemName: "hand.thumbsup"))
                                    .font(.caption)
                                    .foregroundStyle(self.textColor)
                            }, trailingOffset: CGPoint(x: 3, y: -2))
                            .frame(width: 88, height: 68)

                            VStack {
                                Text(self.pressureFormatter.string(from: pressure))
                                    .foregroundStyle(self.textColor)
                                if let mainWeather {
                                    Text(mainWeather.condition(for: pressure).stringLabel)
                                        .font(.system(.caption, design: .monospaced, weight: .regular))
                                        .foregroundStyle(self.textColor)
                                }
                            }
                        }
                    }
                    .id(self.isDaytime)
                }
        }
        .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))
        .accessibilityElement(children: AccessibilityChildBehavior.contain)
        .accessibilityLabel(Text("Today's Weather"))
        .onChange(of: self.mainWeather) { _, newValue in
            if let newValue {
                withAnimation(.bouncy.delay(0.5)) {
                    self.temperature = newValue.temperature.formattedWeatherString()
                    self.feelsLike = newValue.feelsLike.formattedWeatherString()
                    self.humidity = self.percentFormatter.string(from: NSNumber(value: newValue.humidity))!
                    self.pressure = newValue.pressure

                    self.gaugeTemp = newValue.temperature.converted(to: .celsius)
                }
            } else {
                withAnimation(.bouncy.delay(0.5)) {
                    self.guagePressure = Measurement<UnitPressure>(value: 0, unit: .hectopascals)
                    self.gaugeTemp = nil
                    self.temperature = nil
                    self.feelsLike = nil
                    self.humidity = nil
                    self.pressure = nil

                }
            }
        }
        .onChange(of: self.pollution) { _, newValue in
            if let newValue {
//                print("readings.count: \(newValue.readings.count)")
                if let reading = newValue.readings.first {
                    withAnimation(.bouncy.delay(1)) {
                        self.airQualityLabel = reading.qualityState.stringValue
                        self.airQualityNumber = reading.airQuality

                    }
                }
            } else {
                self.airQualityLabel = nil
                self.airQualityNumber = nil
            }
        }
        .onChange(of: self.currentWeather) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if let newValue {
//                print("location name: \(self.locationName)")
                if let cloudCover = newValue.clouds?.cloudiness {
                    withAnimation(.bouncy.delay(1)) {
                        self.cloudiness = self.percentFormatter.string(from: NSNumber(value: cloudCover))!
                    }
                }
            }
        }
    }
}

#Preview {
    MainWeatherDetails(mainWeather: .constant(nil),
                       currentWeather: .constant(nil),
                       pollution: .constant(nil),
                       isDaytime: true,
                       pressureFormatter: Measurement.pressureFormatter,
                       percentFormatter: NumberFormatter.percentFormatter,
                       locationName: "")
}
