//
//  ForecastListView.swift
//  Whether
//
//  Created by Ben Davis on 11/8/24.
//

import SwiftUI
import CoreLocation

struct ForecastRow: View {
    @Binding var list: [Forecast.ForecastList]
    @State private var forecast: Forecast.ForecastList?

    let index: Int
    let isDaytime: Bool
    let percentFormatter: NumberFormatter
    let textColor: Color
    init(list: Binding<[Forecast.ForecastList]>, index: Int, isDaytime: Bool, percentFormatter: NumberFormatter) {
        _list = list
        self.index = index
        self.isDaytime = isDaytime
        self.percentFormatter = percentFormatter
        self.textColor = isDaytime ? Color.dayTextColor : Color.nightTextColor
    }

    func animate(_ forecast: Forecast.ForecastList) {
        withAnimation(.bouncy.delay(0.5)) {
            self.forecastTemp = forecast.main.temperature
        }
    }
    @State private var forecastTemp: Measurement<UnitTemperature>?

    @State private var expandRow: Bool = false
    @State private var mainLabel: String = ""
    @State private var detailedLabel: String = ""
    @State private var feelsLikeLabel: String = ""
    @State private var windSpeed: String = ""
    @State private var pressureString: String = ""
    @State private var humidityString = ""
    @State private var forecastDateLabel: String = ""

    func showDetails() {
        withAnimation(.bouncy) {
            self.expandRow.toggle()
        }
    }

    var body: some View {
        VStack {
            Button {
                self.showDetails()
            } label: {
                HStack {
                    if self.forecast != nil {
                        Text(self.forecastDateLabel)
                            .font(.system(.caption,
                                          design: .monospaced,
                                          weight: .regular))
                            .transition(.scale)
                            .accessibilityHint(Text("Forecast Date"))
                    } else {
                        ProgressView()
                            .progressViewStyle(TailProgressStyle(size: 12.0))
                            .transition(.scale)
                    }
                    TemperatureGauge(temperature: self.$forecastTemp,
                                     height: 12.0)

                    if let first = self.forecast?.conditions.first {
                        first.image(forDaytime: self.isDaytime)
                            .resizable()
                            .frame(width: 33.0, height: 33.0)
                            .offset(y: 3)
                            .transition(.scale)
                    }
                    if let forecast {
                        Text(forecast.main.temperature, format: .measurement(width: .abbreviated, usage: .weather))
                            .font(.system(.caption,
                                          design: .monospaced,
                                          weight: .bold))
                            .foregroundStyle(self.textColor)
                            .transition(.scale)
                            .accessibilityHint(Text("Temperature"))

                    } else {
                        ProgressView()
                            .progressViewStyle(TailProgressStyle(size: 12.0))
                            .transition(.scale)
                    }
                }
                .frame(minHeight: 32,
                       idealHeight: 32,
                       maxHeight: .infinity)
            }
            .buttonStyle(.borderless)
            .accessibilityElement(children: AccessibilityChildBehavior.combine)
            .accessibilityLabel(Text("Expand Date \(self.forecastDateLabel)"))
            .accessibilityHint(Text("Show additional weather conditions for this day."))

            if self.expandRow && self.forecast != nil {
                Divider()
                    .padding(.bottom, 4)

                HStack {

                    VStack(alignment: .leading) {
                        Text(self.detailedLabel)
                            .accessibilityHint(Text("Weather Conditions"))
                            .accessibilityHint(Text(self.forecastDateLabel))

                        HStack {
                            Text("Feels Like")
                                .fontWeight(.bold)
                            Text(self.feelsLikeLabel)
                                .fontWeight(.regular)
                        }
                        .accessibilityElement(children: AccessibilityChildBehavior.combine)
                        .accessibilityLabel(Text("Feels Like: \(self.feelsLikeLabel)"))
                        .accessibilityHint(Text(self.forecastDateLabel))

                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Wind")
                                .fontWeight(.bold)
                            Text(self.windSpeed)
                                .fontWeight(.regular)
                        }
                        .accessibilityElement(children: AccessibilityChildBehavior.combine)
                        .accessibilityLabel(Text("Wind Speed: \(self.windSpeed)"))
                        .accessibilityHint(Text(self.forecastDateLabel))

                        HStack {
                            Text("Humidity")
                                .fontWeight(.bold)
                            Text(self.humidityString)
                                .fontWeight(.regular)
                        }
                        .accessibilityElement(children: AccessibilityChildBehavior.combine)
                        .accessibilityLabel(Text("Humidity: \(self.humidityString)"))
                        .accessibilityHint(Text(self.forecastDateLabel))
                    }
                }
                .font(.system(.caption,
                              design: .monospaced,
                              weight: .bold))
                .foregroundStyle(self.textColor)
                .padding(.bottom, 4.0)
                .accessibilityElement(children: AccessibilityChildBehavior.contain)
                .accessibilityHint(Text("Details:"))
            }
        }
        .accessibilityElement(children: AccessibilityChildBehavior.contain)
        .foregroundStyle(self.textColor)
        .padding([.leading, .trailing], 4.0)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 6.0)
                .fill(self.isDaytime ? Color.white.opacity(0.30) : Color.black.opacity(0.30))
        }

        .onChange(of: self.list, { oldValue, newValue in
            if self.index < newValue.count, oldValue != newValue {
                withAnimation {
                    self.forecast = newValue[self.index]
                }
            }
        })
        .onChange(of: self.forecast, { oldValue, newValue in
            if let newValue, oldValue != newValue {
                self.animate(newValue)
                if let first = newValue.conditions.first {
                    self.mainLabel = first.mainLabel.localizedCapitalized
                    self.detailedLabel = first.weatherDetails.localizedCapitalized
                }
                self.feelsLikeLabel = newValue.main.feelsLike.formattedWeatherString()
                self.windSpeed = newValue.wind?.windSpeed.formattedWeatherString() ?? ""
                self.humidityString = self.percentFormatter.string(from: NSNumber(value: newValue.main.humidity))!
                self.forecastDateLabel = newValue.forecastDate.formatted(.dateTime.weekday(.abbreviated).day())
            }
        })
        .onAppear {
            if index < list.count {
                self.forecast = list[index]
            }
        }
    }
}

struct Forecast5DayListView: View {
    @Binding var list: [Forecast.ForecastList]
    let percentFormatter: NumberFormatter
    let isDaytime: Bool

    init(fiveDay: Binding<[Forecast.ForecastList]>,
         isDaytime: Bool,
         percentFormatter: NumberFormatter) {
        _list = fiveDay
        self.isDaytime = isDaytime
        self.percentFormatter = percentFormatter
    }

    var body: some View {
        GroupBox("5 Day Forecast") {
            ForEach(0 ..< 5, id: \.self, content: { idx in
                ForecastRow(list: $list, index: idx, isDaytime: self.isDaytime, percentFormatter: self.percentFormatter)
            })
            .transition(.push(from: .leading))
        }
        .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))
        .accessibilityElement(children: AccessibilityChildBehavior.contain)
        .accessibilityLabel(Text("Five Day Forecast"))
        .transition(.scale)
    }
}

#Preview {
    Forecast5DayListView(fiveDay: .constant([]),
                         isDaytime: true,
                         percentFormatter: NumberFormatter.percentFormatter)
}
