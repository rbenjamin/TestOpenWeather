//
//  LocationsList.swift
//  Whether
//
//  Created by Ben Davis on 11/4/24.
//

import SwiftUI
import SwiftData
import CoreLocation

struct LocationsList: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var weatherManager: WeatherManager
    let settings: Settings
    @Query(FetchDescriptor<WeatherLocation>(predicate: #Predicate<WeatherLocation> {
        $0.gpsLocation == false
    }, sortBy: [SortDescriptor(\WeatherLocation.lastUpdated)])) var locations: [WeatherLocation]

    @Binding var dismiss: Bool

    @FocusState private var fieldFocus: Bool
    @State private var showOverlay: Bool = false
    @State private var showOverlayField: Bool = false

    @State private var newlocationAddy: String = ""
    @State private var overlayHeight: CGFloat = 0
    @State private var bodyFrame: CGRect = .zero
    @State private var overlayOpacity: CGFloat = 0.0
    @State private var geocodedMarks: [CLPlacemark] = []
    @State private var isGeocoding: Bool = false
    @State private var showDownloadedMarks: Bool = false
    @State private var pickedLocation: WeatherLocation?

    init(dismiss: Binding<Bool>, manager: WeatherManager) {
        _dismiss = dismiss
        self.settings = Settings.shared
        self.weatherManager = manager
    }

    var body: some View {
        NavigationStack {
            List {
                if let gpsLocation = weatherManager.gpsWeatherLocation {
                    let name = gpsLocation.locationName ?? "Unknown Location"
                    Button {
                        self.weatherManager.loadCurrentLocation()

                    } label: {
                        HStack {
                                Image(systemName: "checkmark")
                                    .opacity(gpsLocation == self.weatherManager.currentWeatherLocation ? 1.0 : 0.0)
                            Text(name)
                            Spacer()
                            Image(systemName: "location.fill")

                        }
                    }
                }
                ForEach(self.locations, id: \.id) { location in
                    if let name = location.locationName {
                        Button {
                            self.pickedLocation = location
                            self.weatherManager.updateFromExisting(location)

                            self.dismiss.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(location == self.weatherManager.currentWeatherLocation ? 1.0 : 0.0)
                                Text(name)
                                Spacer()
                            }
                        }
                        .deleteDisabled(location.gpsLocation == true)
                    } else {
                        Text("Unknown Location")
                            .deleteDisabled(location.gpsLocation == true)

                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let location = self.locations[index]
                        if location.gpsLocation == false {
                            self.modelContext.delete(self.locations[index])
                            try? self.modelContext.save()

                        }
                    }
                }
            }
            .background(Color.systemGroupedBackground.ignoresSafeArea())
            .toolbar {
                self.toolbarContents
            }
            .navigationTitle(Text("All Locations"))
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .sheet(isPresented: self.$showOverlay, content: {
            NavigationStack {
                LocationSearchView(weatherManager: self.weatherManager,
                                   locationName: self.$newlocationAddy,
                                   pickedPlacemark: self.$weatherManager.selectedPlacemark,
                                   dismiss: $showOverlay)
            }
        })
        .onChange(of: self.weatherManager.currentWeatherLocation, { _, newValue in
            if newValue != self.pickedLocation {
                self.dismiss.toggle()
            }
        })
    }

    @ToolbarContentBuilder
    var toolbarContents: some ToolbarContent {
        ToolbarItem {
            Button {
                self.showOverlay.toggle()
            } label: {
                Label("New", systemImage: "plus")

            }
        }
    }
    // MARK: - Text Field Overlay -
    @ViewBuilder
    var textFieldOverlay: some View {
        HStack {
            TextField("Location Search", text: $newlocationAddy, prompt: Text("Location Search"))
                .focused($fieldFocus)
            LocationSearchButton {
                print("search executed!")
                self.isGeocoding = true
                self.geocodeLocation(fromString: self.newlocationAddy)
            }
            .disabled(self.newlocationAddy.isEmpty == true)

        }
        .padding([.leading, .trailing], 12)

    }

    func geocodeLocation(fromString: String) {
        Task {
            do {
                let placemarks = try await self.weatherManager.reverseGeocode(addressString: fromString)

                Task { @MainActor in
                    self.showDownloadedMarks.toggle()
                    self.geocodedMarks = placemarks
                }
            } catch let error {
                print("error reverse geocoding: \(error)")
                self.weatherManager.error = error as? LocalizedError
            }
        }
    }

    func label(placemark: CLPlacemark) -> String? {
        if let locality = placemark.locality {
            return locality
        } else if let name = placemark.name {
            return name
        } else  if let address = placemark.formattedAddress(formatter: self.weatherManager.postalFormatter) {
            return address
        }
        return nil
    }
}

#Preview {
    let settings = Settings()
    LocationsList(dismiss: .constant(false), manager: WeatherManager(locationManager: LocationManager()))
}
