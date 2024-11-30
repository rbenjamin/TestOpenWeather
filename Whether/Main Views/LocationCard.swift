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

    @ObservedObject var weatherManager: WeatherManager
    private let locations: [WeatherLocation]
    private let index: Int
    private let location: WeatherLocation
    private let isGPS: Bool
//    let session: URLSession
    private let date: Date
    private let locality: String

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

    init(weatherManager: WeatherManager,
         locations: [WeatherLocation],
         index: Int,
         currentWeather: Binding<CurrentWeather?>,
         currentLocation: Binding<WeatherLocation?>,
         isDaytime: Binding<Bool>,
         backgroundColor: Binding<Color>,
         date: Date = Date(),
         shouldReload: Binding<Bool>,
         error: Binding<LocalizedError?>,
         scrollTo: @escaping (WeatherLocation?) -> Void) {
        self.weatherManager = weatherManager
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
        self.date = date
    }

    @ViewBuilder
    var backgroundView: some View {
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
        return self.isDaytime ? Color.dayTextColor : Color.nightTextColor
    }

    #if DEBUG
    var debugView: some View {
        DebugView(main: self.$main,
                  conditions: self.$conditions,
                  pollution: self.$pollution,
                  textColor: self.textColor,
                  isDaytime: self.isDaytime,
                  locality: self.locality)
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
                                     percentFormatter: self.weatherManager.percentFormatter)

                MainWeatherDetails(mainWeather: self.$main,
                                   currentWeather: self.$currentWeather,
                                   pollution: self.$pollution,
                                   isDaytime: self.isDaytime,
                                   pressureFormatter: self.weatherManager.pressureFormatter,
                                   percentFormatter: self.weatherManager.percentFormatter,
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
            self.backgroundView
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
        let decoder = weatherManager.decoder

        do {
            if let forecast = try await location.existingWeather(type: .fiveDay,
                                                                 decoder: decoder) as? Forecast {

                let forecastAtTime = await forecast.fiveDayForecast(timeOfDay: self.date)
                Task { @MainActor in
                    withAnimation {
                        self.fiveDay = forecastAtTime
                    }
                }
            }

            if let current = try await location.existingWeather(type: .now,
                                                                decoder: decoder) as? CurrentWeather {
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
                                                                  decoder: decoder) as? Pollution {
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

        let daytime = currentWeather.system.isDaytime
        if self.isDaytime != daytime {
            self.isDaytime = daytime
        }

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
        self.rain = currentWeather.rain
        self.wind = currentWeather.wind
        self.snow = currentWeather.snow
    }

    private func downloadData(force: Bool) async {
        let decoder = weatherManager.decoder
        let key = APIKey.key
        let manager = self.weatherManager.downloadManager

        do {
            guard let location = self.currentLocation else { return }
            if let currentWeather = try await location.download(type: .now,
                                                                   apiKey: key,
                                                                   download: manager,
                                                                   decoder: decoder,
                                                                force: force) as? CurrentWeather {
                Task { @MainActor in
                    self.updateView(currentWeather: currentWeather)
                }
            }
            if let forecast = try await location.download(type: .fiveDay,
                                                             apiKey: key,
                                                             download: manager,
                                                             decoder: decoder,
                                                          force: force) as? Forecast {

                let normalized = await forecast.fiveDayForecast(timeOfDay: self.date)
                Task { @MainActor in
                    self.fiveDay = normalized
                }
            }

            if let pollution = try await location.download(type: .pollution,
                                                           apiKey: key,
                                                           download: manager,
                                                           decoder: decoder,
                                                           force: force) as? Pollution {
                Task { @MainActor in
                    self.pollution = pollution
                }
            }

            Task { @MainActor in
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
        case .emptyAPIKey:
            print("API key is empty!  Add an API key to OpenWeather+Key.")
        }
    }
}

#Preview {
    LocationCard(weatherManager: WeatherManager(locationManager: LocationManager()),
                 locations: [],
                 index: 0,
                 currentWeather: .constant(nil),
                 currentLocation: .constant(nil),
                 isDaytime: .constant(false),
                 backgroundColor: .constant(Color("ClearSkyColdDay")),
                 date: Date(),
                 shouldReload: .constant(false),
                 error: .constant(nil)
    ) { _ in
    }
}
