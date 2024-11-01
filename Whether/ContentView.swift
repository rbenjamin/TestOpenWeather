//
//  ContentView.swift
//  Whether
//
//  Created by Ben Davis on 10/22/24.
//

import SwiftUI
import SwiftData
import Combine
import CoreLocation


class WeatherManager: NSObject, ObservableObject {
    let settings: Settings
    var locationSink: AnyCancellable?
    var coordinateSink: AnyCancellable?
    private let apiKey = "02c210e0ad431e1510f2ebacd7e4e918"

    let connection = NetworkConnection()
    
    @Published var currentWeather: CurrentWeather?
    
    @Published var coordinatesLastUpdated: Date?
    @Published var geocoderLastUpdated: Date?
    
    @Published var wind: CurrentWeather.Wind?
    
    @Published var meshColors: [Color] = [
        .red, .red, .red,
        .red, .orange, .red,
        .red, .red, .red
    ]
    
    @Published var backgroundColor: Color = .red
    
    init(settings: Settings) {
        self.settings = settings
        super.init()
        
        
        
        Task { @MainActor in
            
            coordinateSink = self.settings.$coordinates.sink { [weak self] location in
                guard let `self` = self else { return }
                if let location {
                    Task.detached {
                        do {
                            
                            self.locationSink?.cancel()
                            
                            self.locationSink = try self.connection.retrieve(location: location, key: self.apiKey)
                                .sink(receiveCompletion: { failure in
                                print("failure: \(failure)")
                            }, receiveValue: { weather in
                                Task { @MainActor in
                                        self.currentWeather = weather
                                        self.wind = weather.wind
                                    let modifier = CurrentWeather.ConditionModifier(temperature: weather.mainWeather.feelsLike.value)
                                    print(modifier.localizedString)
                                        self.meshColors = weather.meshColors
                                    self.backgroundColor = weather.meshBackgroundColor
                                    print(weather)
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    func geocodeLocation(_ location: CLLocation) async throws {
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: .autoupdatingCurrent)
            
            if let first = placemarks.first?.locality {
                print("reversed geocode results: \(first)")
                Task { @MainActor in
                    self.settings.locationName = first
                }
            }
        }
        catch {
#if DEBUG
            fatalError("Failed to reverse geocode \(location.description): \(error)")
#else
            throw error
#endif
        }
    }
    
    
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: Settings
    let locationManager: LocationManager
    @StateObject var weatherManager: WeatherManager
    
    @State private var description: String?
    @State private var mainLabel: String?
    @State private var locality: String = "Unknown Location"
    @State private var temperatureLabel: String?
    @State private var feelsLike: String?
    @State private var minTemp: String?
    @State private var maxTemp: String?
    @State private var humidity: String?
    @State private var windDirection: String?
    @State private var windSpeed: String?
    @State private var rain: CurrentWeather.Rain?
    @State private var snow: CurrentWeather.Snow?
    @State private var conditions: CurrentWeather.WeatherConditions?


    init() {
        let settings = Settings()
        self.settings = settings
        self.locationManager = LocationManager(settings: settings)
        _weatherManager = StateObject(wrappedValue: WeatherManager(settings: settings))
    }
    
    @Query private var items: [Item]
    
    @ViewBuilder
    var backgroundGradient: some View {

        ZStack {
//            Color.black
            self.weatherManager.backgroundColor
                .edgesIgnoringSafeArea(.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    VStack(spacing: 0) {
                        Spacer()
                        MeshGradient(width: 3, height: 3, points: [
                            [0, 0], [0.5, 0], [1, 0],
                            [0, 0.5], [0.5, 0.50], [1, 0.5],
                            [0, 1], [0.5, 1], [1, 1]
                        ], colors: self.weatherManager.meshColors)
                        .frame(maxHeight: 400.0)
                        Spacer()
                    }.frame(maxWidth: .infinity, alignment: .center)
                }
            
//            SnowEffect(snow: CurrentWeather.Snow(oneHour: 1), wind: CurrentWeather.Wind(windSpeed: Measurement<UnitSpeed>(value: 8, unit: UnitSpeed.metersPerSecond), direction: 125.0, gustLevel: 0.0), speed: CurrentWeather.Wind.WindSpeedCategory.extreme)
            
        }
        
        
    }

    var body: some View {
        NavigationSplitView {
            ScrollView([.vertical]) {
                VStack(spacing: 12) {
                    VStack {
                        
                        GroupBox {
                            LabeledContent("Location:", value: self.settings.locationName ?? "Unknown Location")
                            
                            HStack {
                                VStack {
                                    LodableLabel(value: self.$mainLabel, label: "Current Conditions:")
                                    
                                    LodableText(self.$description)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .offset(x: 4, y: -4)
                                        
                                }
                                if let conditions {
                                    AsyncImage(url: conditions.iconURL) { image in
                                        image
                                            .resizable()
                                            .frame(width: 22, height: 22)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    
                                }
                            }
                        }
                        .groupBoxStyle(TransparentGroupBox())

                        
                        GroupBox {
                            LodableLabel(value: self.$temperatureLabel, label: "Temperature:")
                            
                            LodableLabel(value: self.$feelsLike, label: "Feels Like:")

                            if let minTemp, let maxTemp, minTemp != maxTemp {
                                
                                
                                HStack {
                                    VStack {
                                        Text("Min:")
                                        Text(minTemp)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack {
                                        Text("Max:")
                                        Text(maxTemp)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.system(.caption))
                            }
                            
                            LodableLabel(value: self.$humidity, label: "Humidity:")

                        }
                        .groupBoxStyle(TransparentGroupBox())

                        
                        GroupBox("Wind") {
                            VStack {
                                LodableLabel(value: self.$windSpeed, label: "Wind Speed:")

                                HStack(alignment: .center) {
                                    
                                    LodableLabel(value: self.$windDirection, label: "Wind Direction:")
                                    CardinalView(wind: self.$weatherManager.wind)
                                        .frame(width: 40, height: 40, alignment: .center)

                                    
                                }
                            }

                        }
                        .groupBoxStyle(TransparentGroupBox())

                        if let rain {
                            RainView(rain: rain)
                        }
                        
                        if let snow {
                            SnowView(snow: snow)
                        }
                        
    //                        Text("Humidity: \(humidity)%")
                       
                    }
                }
                .padding()
                
                
            }
            .background {
                self.backgroundGradient

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: reload) {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onChange(of: self.weatherManager.currentWeather) { _, newValue in
                if let newValue {
                    if let conditions = newValue.conditions.first {
                        print("condition code: \(conditions.id)")
                        
                        self.conditions = conditions
                        self.mainLabel = conditions.mainLabel
                        self.description = conditions.description
                    }
                    self.temperatureLabel = newValue.mainWeather.temperature.formatted()
                    self.feelsLike = newValue.mainWeather.feelsLike.formatted()
                    self.minTemp = newValue.mainWeather.minTemp.formatted()
                    self.maxTemp = newValue.mainWeather.maxTemp.formatted()
                    self.humidity = Int(newValue.mainWeather.humidity).formatted()
                    self.windDirection = newValue.wind?.cardinalDirection.stringLabel
                    self.windSpeed = newValue.wind?.windSpeed.formatted()
                    self.rain = newValue.rain
                    self.snow = newValue.snow
                    
                    if let degrees = newValue.wind?.cardinalDirection.normalizedDegrees() {
                        print("cardinal direction: \(degrees) direction:  \(CurrentWeather.Wind.WindDirection.windDirectionForDegrees(degrees))")
                    }
                }
            }
            .onChange(of: self.settings.locationName) { _, newValue in
                if let newValue {
                    self.locality = newValue
                }
                else {
                    self.locality = "Unknown Location"
                }
            }
            .onChange(of: self.settings.coordinates) { _, newValue in
                if let newValue {
                    Task.detached {
                        do {
                            try await self.weatherManager.geocodeLocation(newValue)
                        }
                        catch {
#if DEBUG
                            fatalError("Failed to geocode")
#else
                            #error("Need to handle these errors!")
#endif
                        }
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear {
            self.locationManager.updateCurrentLocation()
            self.locality = settings.locationName ?? "Unknown Location"
        }
    }
    private func reload() {
        self.locationManager.updateCurrentLocation()
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
