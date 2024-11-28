//
//  LocationCard.swift
//  Whether
//
//  Created by Ben Davis on 11/15/24.
//

import SwiftUI

struct LocationCard: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase

    let locations: [WeatherLocation]
    let index: Int
    let location: WeatherLocation
    let isGPS: Bool
    let apiKey: String
//    let session: URLSession
    let decoder: JSONDecoder
    let date: Date
    let locality: String
    let percentFormatter: NumberFormatter
    let pressureFormatter: MeasurementFormatter
    let downloadManager: DownloadManager

    /// Ensures we don't begin downloading weather data until a location is visible.
    @Binding private var visibleWeather: CurrentWeather?
    @Binding private var currentLocation: WeatherLocation?
    @Binding private var error: LocalizedError?
    @Binding private var isDaytime: Bool
    @Binding private var backgroundColor: Color

    /// This is the variable used to setup the weather privately from existing data, if it exists.
    @State private var currentWeather: CurrentWeather?
    @State private var forecast: Forecast?
    @State private var fiveDay: [Forecast.ForecastList] = []
    @State private var pollution: Pollution?
    @State private var conditions: CurrentWeather.WeatherConditions?
    @State private var main: CurrentWeather.MainWeather?
    @State private var wind: CurrentWeather.Wind?
    @State private var rain: CurrentWeather.Rain?
    @State private var snow: CurrentWeather.Snow?
    @State private var backgroundUIColor: UIColor = UIColor(named: "ClearSkyNormalDay")!
    @State private var didUpdateDefault: Bool = false

    @State private var particleViewSettings: ParticleSettings?

    @Binding private var shouldReload: Bool

    let scrollTo: (WeatherLocation?) -> Void

    init(locations: [WeatherLocation],
         index: Int,
         currentWeather: Binding<CurrentWeather?>,
         currentLocation: Binding<WeatherLocation?>,
         isDaytime: Binding<Bool>,
         backgroundColor: Binding<Color>,
         apiKey: String,
         downloadManager: DownloadManager,
         decoder: JSONDecoder,
         date: Date = Date(),
         percentFormatter: NumberFormatter,
         pressureFormatter: MeasurementFormatter,
         shouldReload: Binding<Bool>,
         error: Binding<LocalizedError?>,
         scrollTo: @escaping (WeatherLocation?) -> Void) {
        _backgroundColor = backgroundColor
        _isDaytime = isDaytime
        _visibleWeather = currentWeather
        _currentLocation = currentLocation
        self.scrollTo = scrollTo
        self.locations = locations
        self.location = locations[index]
        self.index = index
        _shouldReload = shouldReload
        _error = error
        self.locality = location.locationName ?? "Unknown Location"
        self.isGPS = location.gpsLocation
        self.apiKey = apiKey
        self.downloadManager = downloadManager
        self.decoder = decoder
        self.date = date
        self.percentFormatter = percentFormatter
        self.pressureFormatter = pressureFormatter
    }

    @ViewBuilder
    var backgroundGradient: some View {
        ZStack {
            self.backgroundColor
                .edgesIgnoringSafeArea(.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if let particleViewSettings {
                ParticleSceneKitView(settings: particleViewSettings, backgroundColor: self.backgroundUIColor)
                    .transition(.opacity)
            }
        }
        .transition(.opacity)
    }

    var textColor: Color {
        return self.isDaytime ? Color.secondary : Color("NightTextColor")
    }

    #if DEBUG
    var debugView: some View {
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
    #endif

    var body: some View {

        ScrollView([.vertical], content: {
            VStack(alignment: .center, spacing: 12) {

                LocationPositionHeader(isDaytime: self.isDaytime,
                                       previousLocation: index > 0 ? locations[index - 1] : nil,
                                       current: self.location,
                                       nextLocation: index + 1 < locations.count ? locations[index + 1] : nil,
                                       scrollTo: self.scrollTo)
                .transition(.slide)
                .padding(.top, 120)

                ConditionView(condition: self.conditions,
                              mainWeather: self.main,
                              locality: self.locality,
                              isGPSWeather: self.isGPS,
                              isDaytime: self.isDaytime)

                Forecast5DayListView(fiveDay: self.$fiveDay,
                                     isDaytime: self.isDaytime,
                                     percentFormatter: self.percentFormatter)

                MainWeatherDetails(mainWeather: self.$main,
                                   currentWeather: self.$currentWeather,
                                   pollution: self.$pollution,
                                   isDaytime: self.isDaytime,
                                   pressureFormatter: self.pressureFormatter,
                                   percentFormatter: self.percentFormatter,
                                   locationName: self.locality)

                WindView(wind: self.$wind,
                         isDaytime: self.isDaytime)
                    .id(self.location)
                if let rain {
                    RainView(rain: rain,
                             isDaytime: self.isDaytime)
                }
                if let snow {
                    SnowView(snow: snow,
                             isDaytime: self.isDaytime)
                }

                Spacer()
                    .frame(height: 24)
            }

        })
        .background {
            self.backgroundGradient

        }
        .onDisappear {
            self.particleViewSettings = nil

        }
        .onChange(of: self.shouldReload, { oldValue, newValue in
            if newValue != oldValue && newValue == true {
                self.shouldReload = false
                Task {
                    await self.downloadData(force: true)
                }
            }
        })
        .onChange(of: self.currentLocation, { oldValue, newValue in
            if let newValue, newValue != oldValue, newValue == self.location {
//                print("downloading for curentLocation: \(newValue) self.location: \(self.location)")

                Task(priority: .userInitiated) {

                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.downloadData(force: false)

                }
            }
        })
        .task {
            if self.currentLocation == self.location {
                Task(priority: .userInitiated) {
//                    print("currentLocation: \(currentLocation!) location: \(self.location)")
                    await self.downloadData(force: false)
                }
            }
        }
    }

    private func loadExistingData() async {
        do {
            if let forecast = try await location.existingWeather(type: .fiveDay,
                                                                 decoder: self.decoder) as? Forecast {

                let forecastAtTime = await forecast.fiveDayForecast(timeOfDay: self.date)
                Task { @MainActor in
                    withAnimation {
                        self.fiveDay = forecastAtTime
                    }
                }
            }

            if let current = try await location.existingWeather(type: .now,
                                                                decoder: self.decoder) as? CurrentWeather {
                Task { @MainActor in
                    self.currentWeather = current
                    self.isDaytime = current.system.isDaytime
                    let color = current.backgroundColor(daytime: self.isDaytime)
                    withAnimation {
                        self.backgroundColor = color
                    }
                    self.backgroundUIColor = current.backgroundUIColor(daytime: self.isDaytime)
                    self.main = current.mainWeather

                    if let first = current.conditions.first {
                        self.conditions = first
                    }

                    self.wind = current.wind
                    self.snow = current.snow
                    self.rain = current.rain
                    withAnimation {
                        self.particleViewSettings = ParticleSettings.new(rain: self.rain,
                                                                         snow: self.snow,
                                                                         wind: self.wind,
                                                                         conditions: self.conditions)
                    }
                }
            }

            if let pollution = try await location.existingWeather(type: .pollution,
                                                                  decoder: self.decoder) as? Pollution {
                Task { @MainActor in
                    self.pollution = pollution
                }
            }
        } catch let error {
#if DEBUG
            fatalError("Failed to retrieve / decode exiting data for LocationCard: error: \(error)")
#else
            print("Failed to retrieve / decode exiting data for LocationCard: error: \(error)")
#endif
        }
    }

    func updateView(currentWeather: CurrentWeather) {
        self.currentWeather = currentWeather
        self.visibleWeather = currentWeather
        let color = currentWeather.backgroundColor(daytime: self.isDaytime)
        withAnimation {
            self.backgroundColor = color
        }

        self.backgroundUIColor = currentWeather.backgroundUIColor(daytime: self.isDaytime)
        self.main = currentWeather.mainWeather
        if let first = currentWeather.conditions.first {
            self.conditions = first
        }
        self.wind = currentWeather.wind
        self.snow = currentWeather.snow
        self.rain = currentWeather.rain
    }

    private func downloadData(force: Bool) async {
        do {
            guard let location = self.currentLocation else { return }
            guard let currentWeather = try await location.download(type: .now,
                                                                   apiKey: self.apiKey,
                                                                   download: self.downloadManager,
                                                                   decoder: self.decoder,
                                                                   force: force) as? CurrentWeather
            else { return }
            guard let forecast = try await location.download(type: .fiveDay,
                                                             apiKey: self.apiKey,
                                                             download: self.downloadManager,
                                                             decoder: self.decoder,
                                                             force: force) as? Forecast
            else { return }
            if let pollution = try await location.download(type: .pollution,
                                                           apiKey: self.apiKey,
                                                           download: self.downloadManager,
                                                           decoder: self.decoder,
                                                           force: force) as? Pollution {
                Task { @MainActor in
                    self.pollution = pollution
                }
            }
            let normalized = await forecast.fiveDayForecast(timeOfDay: self.date)

            Task { @MainActor in
                let daytime = currentWeather.system.isDaytime
                if self.isDaytime != daytime {
                    self.isDaytime = daytime
                }
                self.fiveDay = normalized

                self.updateView(currentWeather: currentWeather)
                // Builds an optional `ParticleSettings` object _if_ there is `Rain`, `Snow`, or `Conditions.mist`.
                // Uses `Wind` to determine how much to angle the particle effect.
                self.particleViewSettings = ParticleSettings.new(rain: self.rain,
                                                                 snow: self.snow,
                                                                 wind: self.wind,
                                                                 conditions: self.conditions)
            }
        } catch let error as DownloadError {
            self.error = error
            self.printErrorDescription(downloadError: error)
        } catch let error {
            print("WeatherLocation.download failed: Unknown Error: \(error)")
        }

    }

    func printErrorDescription(downloadError: DownloadError) {
        switch downloadError {
        case .locationIsNil(let location):
            print("WeatherLocation \(location.locationName ?? "N/A") download failed: WeatherLocation.location (\(location.location?.description ?? "N/A")) is nil.")
        case .resolveFailed(let type, let location, let error):
            print("WeatherLocation \(location.locationName ?? "Unknown name") download failed: URL resolution failed for \(type) error: \(error)")
        case .downloadFailed(let type, let location, let error):
            print("WeatherLocation \(location.locationName ?? "Unknown name") download failed: URLSession failed for \(type) error: \(error)")
        case .geocodeFailed(let error):
            print("Geocode failed: error: \(error)")

        case .decodeFailed(let type, let location, let error):
            print("WeatherLocation \(location.locationName ?? "Unknown name") download failed: Decode failed for \(type) error: \(error)")
        case .mimeTypeFailure(let reason):
            print("WeatherLocation \(location.locationName ?? "Unknown name") mime type failure: \(reason)")
        }
    }
}

#Preview {
    LocationCard(locations: [],
                 index: 0,
                 currentWeather: .constant(nil),
                 currentLocation: .constant(nil),
                 isDaytime: .constant(false),
                 backgroundColor: .constant(Color("ClearSkyColdDay")),
                 apiKey: "",
                 downloadManager: DownloadManager(),
                 decoder: JSONDecoder(),
                 date: Date(),
                 percentFormatter: NumberFormatter.percentFormatter,
                 pressureFormatter: Measurement<UnitPressure>.pressureFormatter,
                 shouldReload: .constant(false),
                 error: .constant(nil)
    ) { _ in
    }
}
