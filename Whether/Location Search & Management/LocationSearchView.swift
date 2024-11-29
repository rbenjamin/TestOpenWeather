//
//  LocationSearchView.swift
//  Whether
//
//  Created by Ben Davis on 11/18/24.
//

import SwiftUI
import CoreLocation

struct LocationSearchView: View {

    struct LocationListPlacemark: Identifiable {
        let id = UUID()
        let placemark: CLPlacemark

        init(placemark: CLPlacemark) {
            self.placemark = placemark
        }
    }

    let backgroundColor: Color
    let isDaytime: Bool
    let listRowBackground: Color
    let foregroundStyle: Color

    @ObservedObject var weatherManager: WeatherManager
    @Binding var locationName: String
    @Binding var pickedPlacemark: CLPlacemark?
    @Binding var dismiss: Bool
    @FocusState var focused: Bool
    @State private var placemarks = [LocationListPlacemark]()

    init(weatherManager: WeatherManager,
         locationName: Binding<String>,
         pickedPlacemark: Binding<CLPlacemark?>,
         dismiss: Binding<Bool>,
         backgroundColor: Color,
         isDaytime: Bool) {
        self.weatherManager = weatherManager
        _locationName = locationName
        _pickedPlacemark = pickedPlacemark
        _dismiss = dismiss
        self.backgroundColor = backgroundColor
        self.isDaytime = isDaytime
        self.listRowBackground = isDaytime ? Color.white.opacity(0.50) : Color.black.opacity(0.50)
        self.foregroundStyle = isDaytime ? Color.dayTextColor : Color.nightTextColor

    }

    func geocodeLocation(fromString: String) async -> [CLPlacemark] {
        do {
            let placemarks = try await self.weatherManager.reverseGeocode(addressString: fromString)
            return placemarks
        } catch let error {
            self.weatherManager.error = error as? LocalizedError
            self.weatherManager.dataErrorType = nil
        }
        return []
    }

    func submit() {
        Task {
            let placemarks = await self.geocodeLocation(fromString: self.locationName)

            Task { @MainActor in
                self.placemarks = placemarks.map({ LocationListPlacemark(placemark: $0) })
            }
        }
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                TextField("New Location", text: $locationName)
                    .onSubmit(self.submit)
                    .focused($focused)
                    .textFieldStyle(.plain)
                    .foregroundStyle(self.foregroundStyle)
                Button {
                    self.submit()
                } label: {
                    Text(Image(systemName: "location.magnifyingglass"))
                        .foregroundStyle(self.foregroundStyle)
                        .disabled(self.locationName.isEmpty)
                }
            }
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
            .background {
                Capsule().foregroundStyle(self.listRowBackground)
            }
            .padding([.leading, .trailing], 4)
            .padding(.top, 8)

            Divider()

            List {
                if self.placemarks.isEmpty {
                    Text("No Matched Locations.")
                        .listRowBackground(self.listRowBackground)
                        .foregroundStyle(self.foregroundStyle)
                }
                ForEach(self.placemarks, id: \.id) { placemark in
                    let location = placemark.placemark
                    Button {
                        self.pickedPlacemark = location
                        self.dismiss.toggle()
                    } label: {
                        if let locality = location.locality, let adminArea = location.administrativeArea {

                            HStack {
                                Text(locality)
                                Text(adminArea).foregroundStyle(Color.secondary)
                            }
                        } else if let name = location.name {
                            Text(name)
                        }
                    }
                }
                .listRowBackground(self.listRowBackground)
                .foregroundStyle(self.foregroundStyle)
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(self.backgroundColor, for: .navigationBar)
        .navigationTitle(Text("Search for Location"))
        .toolbarColorScheme(self.isDaytime ? .light : .dark, for: .navigationBar)
        .background(self.backgroundColor)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.dismiss.toggle()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(self.foregroundStyle)
                }
            }
        }
        .onAppear {
            self.focused = true
        }
    }
}

#Preview {
    LocationSearchView(weatherManager: WeatherManager(locationManager: LocationManager()),
                       locationName: .constant(""),
                       pickedPlacemark: .constant(nil),
                       dismiss: .constant(false),
                       backgroundColor: .white,
                       isDaytime: true)
}
