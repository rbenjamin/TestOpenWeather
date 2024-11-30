//
//  WeatherLocation.swift
//  Whether
//
//  Created by Ben Davis on 11/4/24.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class WeatherLocation: CustomStringConvertible {
    var timestamp: Date = Date()
    var weatherData: Data?
    var forecastData: Data?
    var pollutionData: Data?
    var lastUpdated: Date = Date()
    var latitude: Double?
    var longitude: Double?
    var addressString: String?
    var locationName: String?
    var defaultLocation: Bool = false
    var gpsLocation: Bool = false
    var forecastDownloadDate: Date?
    var weatherDownloadDate: Date?
    var pollutionDownloadDate: Date?

    var description: String {
        return "(NAME: \(locationName ?? "N/A"), LASTUPDATED: \(lastUpdated.formatted(date: .numeric, time: .shortened)), DEFAULT: \(defaultLocation), GPS: \(gpsLocation))"
    }

    var location: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    func setLocation(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }

    func existingWeather(type: WeatherDataType, decoder: JSONDecoder) async throws -> (any WeatherData)? {
        switch type {
        case .now:
            guard let data = self.weatherData else { return nil }
            return try await CurrentWeather.decodeWithData(data, decoder: decoder)
        case .pollution:
            guard let data = self.pollutionData else { return nil }
            return try await Pollution.decodeWithData(data, decoder: decoder)
        case .fiveDay:
            guard let data = self.forecastData else { return nil }
            return try await Forecast.decodeWithData(data, decoder: decoder)
        }
    }

    private func urlForType(_ type: WeatherDataType,
                            apiKey key: String,
                            location: CLLocation) throws -> URL? {
        var url: URL?
        switch type {
        case .now:
            do {
                url = try OpenWeatherURLBuilder.resolve(type: .now(language: nil),
                                                        key: key,
                                                        location: location)
            } catch let error {
                throw DownloadError.resolveFailed(type: type,
                                                  location: self,
                                                  error: error)
            }
        case .pollution:
            do {
                url = try OpenWeatherURLBuilder.resolve(type: .pollution,
                                                        key: key,
                                                        location: location)
            } catch let error {
                throw DownloadError.resolveFailed(type: type,
                                                  location: self,
                                                  error: error)
            }
        case .fiveDay:
            do {
                url = try OpenWeatherURLBuilder.resolve(type: .forecast(hourly: false,
                                                                language: nil),
                                                        key: key,
                                                        location: location)
            } catch let error {
                throw DownloadError.resolveFailed(type: type,
                                                  location: self,
                                                  error: error)
            }
        }
        return url
    }

    func download(type: WeatherDataType,
                  apiKey key: String,
                  download manager: DownloadManager,
                  decoder: JSONDecoder,
                  force: Bool = false) async throws -> (any WeatherData)? {

        guard !key.isEmpty else { throw DownloadError.emptyAPIKey }
        let date = Date()

        // 1) Determine if we've already downloaded this type recently --
        // if so, and `force = false`, we simply return the most recent data, decoded.
        switch type {
        case .now:
            if !force, let recent = weatherDownloadDate {
                let distance = recent.distance(to: date)
                print("time intervals since last weather download for \(self.locationName): \(distance)")
            }
            if force == false, let recent = weatherDownloadDate,
                recent.distance(to: date) < 600,
                let data = self.weatherData {
                return try await CurrentWeather.decodeWithData(data,
                                                               decoder: decoder)
            }
        case .pollution:
            if !force, let recent = pollutionDownloadDate {
                let distance = recent.distance(to: date)
                print("time intervals since last weather download for \(self.locationName): \(distance)")
            }
            if force == false,
                let recent = pollutionDownloadDate,
                recent.distance(to: date) < 600,
                let data = self.pollutionData {
                return try await Pollution.decodeWithData(data,
                                                          decoder: decoder)
            }
        case .fiveDay:
            if !force, let recent = forecastDownloadDate {
                let distance = recent.distance(to: date)
                print("time intervals since last weather download for \(self.locationName): \(distance)")
            }
            if force == false,
                let recent = forecastDownloadDate,
                recent.distance(to: date) < 600,
                let data = self.forecastData {
                return try await Forecast.decodeWithData(data,
                                                         decoder: decoder)
            }
        }
        /// 2) Get the `location` for the download, we need the coordinates.
        guard let location = self.location else {
            throw DownloadError.locationIsNil(location: self)
        }

        /// 3) Retrieve the right `URL` for the `type` requested.
        var url: URL?
        do {
            url = try self.urlForType(type, apiKey: key, location: location)
        } catch let error {
            throw error
        }
        guard let url else {
            throw DownloadError.resolveFailed(type: type,
                                              location: self,
                                              error: URLError(.badURL))
        }
        do {
            Task { @MainActor in
                /// 4) Alert the rest of the app that we're networking
                NotificationCenter.default.post(name: .networkingOn, object: nil)

            }
            /// 5) Begin the download

            guard let data = try await manager.download(url: url) else {
                print("data is nil!")
                return nil
            }
            /// Updates to SwiftData object on the main thread.
            Task { @MainActor in
                /// Notify the app we're done networking
                NotificationCenter.default.post(name: .networkingOff, object: nil)
                self.updateWithData(data, downloadDate: date, type: type)
            }

            return try await self.decodeDataForType(data, type: type, decoder: decoder)

        } catch let error as NSError {
            Task { @MainActor in
                NotificationCenter.default.post(name: .networkingOff, object: nil)
            }
            throw DownloadError.downloadFailed(type: type,
                                               location: self,
                                               error: error)
        }
    }

    /// Private function called by `download(type: ...)` to

    private func decodeDataForType(_ data: Data,
                                   type: WeatherDataType,
                                   decoder: JSONDecoder) async throws -> (any WeatherData)? {
        /// Return the results of the decoding, based on `type`.
        switch type {
        case .now:
            return try await CurrentWeather.decodeWithData(data,
                                                           decoder: decoder)
        case .pollution:
            return try await Pollution.decodeWithData(data,
                                                      decoder: decoder)
        case .fiveDay:
            return try await Forecast.decodeWithData(data,
                                                     decoder: decoder)
        }
    }

    /// Private function called by `download(type: ...)` to update `self` with the downloaded data object and the recent download date, based on weather data type.
    @MainActor
    private func updateWithData(_ data: Data, downloadDate date: Date, type: WeatherDataType) {
        switch type {
        case .now:
            self.weatherData = data
        case .pollution:
            self.pollutionData = data
        case .fiveDay:
            self.forecastData = data
        }

        /// Update recently downloaded `date`, based on property `type`
        switch type {
        case .now:
            self.weatherDownloadDate = date
        case .pollution:
            self.pollutionDownloadDate = date
        case .fiveDay:
            self.forecastDownloadDate = date
        }
    }

    init() {

    }

}
