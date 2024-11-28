//
//  ContentView.swift
//  Whether
//
//  Created by Ben Davis on 10/22/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    private struct ToolbarRotateKeyframe {
        var rotationAngle = Angle.zero
    }

    @Environment(\.modelContext) private var modelContext

    let settings = Settings.shared

    @StateObject var weatherManager: WeatherManager
    @StateObject var locationManager: LocationManager

    @State private var locality: String = "Unknown Location"
    @State private var currentWeather: CurrentWeather?
    @State private var presentList: Bool = false
    @State private var isDaytime: Bool = false
    @State private var showReloadNameView: Bool = false
    @State private var networkingState: Bool = false
    @State private var shouldReloadWeather: Bool = false
    @State private var showDownloadErrorView: Bool = false
    @State private var showDataErrorView: Bool = false
    @State private var visibleLocation: WeatherLocation?
    @State private var backgroundColor: Color = Color("ClearSkyNormalDay")
    @State private var gpsButtonTapped: Bool = false
    @State private var reloadButtonTapped: Bool = false

    @Query(sort: [SortDescriptor(\WeatherLocation.lastUpdated)], animation: .easeIn) var locations: [WeatherLocation]

    @Query(FetchDescriptor<WeatherLocation>(predicate: #Predicate<WeatherLocation> {
        $0.gpsLocation == false
    }, sortBy: [SortDescriptor(\WeatherLocation.lastUpdated)])) var listLocations: [WeatherLocation]

    init() {
        let manager = LocationManager()
        _locationManager = StateObject(wrappedValue: manager)

        let weatherManager = WeatherManager(locationManager: manager)
        _weatherManager = StateObject(wrappedValue: weatherManager)
    }

    @ViewBuilder
    var backgroundView: some View {
        ZStack {
            Color.white
            Group {
                self.backgroundColor
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
            .opacity(0.75)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {

                Button {
                    self.gpsButtonTapped.toggle()
                    print("GPS Location Tapped!")
                    self.weatherManager.currentWeatherLocation = self.weatherManager.gpsWeatherLocation
                    self.weatherManager.updateGPSLocation()
                } label: {
                    Image(systemName: "location")
                        .keyframeAnimator(initialValue: ToolbarRotateKeyframe(),
                                          trigger: self.gpsButtonTapped)
                    { image, value in
                            image.rotationEffect(value.rotationAngle)
                    } keyframes: { _ in
                            KeyframeTrack(\.rotationAngle) {
                                CubicKeyframe(Angle(degrees: 355), duration: 0.45)
                                CubicKeyframe(Angle(degrees: 0), duration: 0.15)

                            }
                        }
                }
                .buttonStyle(.borderless)
                .disabled(self.settings.locationEnabled == false ||  self.weatherManager.gpsButtonDisabled == true)
                .accessibilityLabel("Refresh Current Location")
            Circle()
                .fill(Color.green)
                .stroke(Color.white)
                .frame(width: 12, height: 12)
                .scaleEffect(self.networkingState ? CGSize(width: 1, height: 1) : CGSize(width: 0, height: 0),
                             anchor: .center)

        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: reload) {
                Image(systemName: "arrow.clockwise")
                    .keyframeAnimator(initialValue: ToolbarRotateKeyframe(),
                                      trigger: self.shouldReloadWeather) { image, value in
                        image.rotationEffect(value.rotationAngle)
                    } keyframes: { _ in
                        KeyframeTrack(\.rotationAngle) {
                            CubicKeyframe(Angle(degrees: 355), duration: 0.45)
                            CubicKeyframe(Angle(degrees: 0), duration: 0.15)
                        }
                    }
            }
            .disabled(self.shouldReloadWeather == true)
            .accessibilityLabel(Text("Reload"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                self.presentList.toggle()
            } label: {
                Label("All Locations", systemImage: "list.bullet")
            }
        }

    }
    private func updateVisibleLocation(oldValue: WeatherLocation?, newValue: WeatherLocation?) {
        if let newValue, newValue != oldValue {
            withAnimation {
                self.visibleLocation = newValue
            }
        }

    }

    @ViewBuilder
    func scrollContent(proxy: ScrollViewProxy) -> some View {
        LazyHStack(alignment: .center, spacing: 0) {
            ForEach(0 ..< self.locations.count, id: \.self) { idx in
                LocationCard(locations: self.locations,
                                 index: idx,
                                 currentWeather: self.$currentWeather,
                                 currentLocation: self.$visibleLocation,
                                 isDaytime: self.$isDaytime,
                                 backgroundColor: self.$backgroundColor,
                                 apiKey: APIKey.key,
                                 downloadManager: self.weatherManager.downloadManager,
                                 decoder: self.weatherManager.decoder,
                                 percentFormatter: self.weatherManager.percentFormatter,
                                 pressureFormatter: self.weatherManager.pressureFormatter,
                                 shouldReload: self.$shouldReloadWeather,
                                 error: self.$weatherManager.error,
                                 scrollTo: { weatherLocation in

                    if let weatherLocation {
                        withAnimation {
                            self.visibleLocation = weatherLocation

                            proxy.scrollTo(weatherLocation, anchor: .center)
                        }

                    }
                })
                .environment(\.modelContext, self.modelContext)
                .safeAreaPadding([.leading, .trailing], 4)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .frame(maxHeight: .infinity)
                .id(locations[idx])
            }
        }
    }

    var body: some View {
        NavigationStack {

            ScrollViewReader(content: { proxy in
                ScrollView([.horizontal]) {
                    self.scrollContent(proxy: proxy)
                        .scrollTargetLayout()

                    .onChange(of: self.visibleLocation, { old, new in
                        if old != new, let new {
                            self.locality = new.locationName ?? "Unknown Location"
                            self.settings.setDefaultLocationID(new.persistentModelID,
                                                               encoder: self.weatherManager.encoder)
                        } else if new == nil {
                            self.locality = "Unknown Location"
                        }
                    })
                    .onChange(of: self.weatherManager.currentWeatherLocation, { old, new in
                        if old != new, let new {
                            self.visibleLocation = new
                            proxy.scrollTo(new)
                        }
                    })
                }
                .background {
                    self.backgroundColor
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: self.$visibleLocation, anchor: .center)
            })
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()

            .toolbar {
                self.toolbarContent
            }
            .navigationTitle(self.$locality)
            .toolbarColorScheme(self.isDaytime ? .light : .dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(self.backgroundColor, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $presentList,
                   content: {
                LocationsList(dismiss: self.$presentList, manager: self.weatherManager)
                    .environment(\.modelContext, self.modelContext)
            })
        }
        .onAppear {
            self.weatherManager.mainContext = self.modelContext
            self.weatherManager.beginUpdatingWeather()
        }
        .onChange(of: self.locality, { oldValue, newValue in
            if oldValue != newValue {
                self.visibleLocation?.locationName = newValue
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .networkingOn), perform: { _ in
            Task { @MainActor in
                withAnimation(.easeIn(duration: 0.25)) {
                    self.networkingState = true
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .networkingOff), perform: { _ in
            // Delay turning the notification icon off for 1 second to ensure visiblity of the icon before networking finishes.
            Timer.scheduledTimer(withTimeInterval:  1, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.easeIn(duration: 0.25)) {                        self.networkingState = false
                    }
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .downloadError), perform: { _ in
            self.showDownloadErrorView.toggle()
        })
        .onReceive(NotificationCenter.default.publisher(for: .databaseError), perform: { _ in
            self.showDataErrorView.toggle()
        })
        .alert(isPresented: self.$showDownloadErrorView, error: self.weatherManager.downloadError, actions: {
            Button("OK") {
                self.showDownloadErrorView.toggle()
            }
        })
        .alert(isPresented: self.$showDataErrorView, error: self.weatherManager.databaseError, actions: {
            Button("OK") {
                self.showDataErrorView.toggle()
            }
        })

        .onChange(of: self.locationManager.error) { _, newValue in
            /// Encountered an error determining user location
            if newValue != nil {
                /// Attempt to load the most recently downloaded weather data:

#if !DEBUG
                #warning("NEed to handle errors!")
#endif
            }
        }
    }

    private func reload() {
        self.shouldReloadWeather.toggle()
//        self.weatherManager.beginUpdatingWeather(userReload: true)
    }

}

#Preview {
    ContentView()
        .modelContainer(for: WeatherLocation.self, inMemory: true)
}
 
