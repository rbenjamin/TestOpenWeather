//
//  Errors.swift
//  Whether
//
//  Created by Ben Davis on 11/20/24.
//

import Foundation
import SwiftData

public enum DatabaseError: Error, LocalizedError {
    case identifierFailure(backgroundContext: Bool, id: PersistentIdentifier)
    case failedSave(backgroundContext: Bool, error: Error)
    case failedFetch(backgroundContext: Bool, error: Error)

    public var errorDescription: String? {
        switch self {
        case .identifierFailure(let isInBackground, let id):
            let label = isInBackground ? "Background" : "Main"
            return "No object returned in (\(label) Context) for identifier \(id)."

        case .failedSave(let isInBackground, let error):
            let label = isInBackground ? "Background" : "Main"
            return "Save failed (\(label) Context): \(error.localizedDescription)"
        case .failedFetch(let isInBackground, let error):
            let label = isInBackground ? "Background" : "Main"
            return "Fetch failed (\(label) Context): \(error.localizedDescription)"
        }
    }

    public var errorCode: String? {
        switch self {
        case .identifierFailure:
            return "200"
        case .failedSave:
            return "201"
        case .failedFetch:
            return "202"
        }
    }

    public var recoverySuggestion: String? {
        return "Try restarting the app. If you continue to see this error, please contact support."
    }
}

enum DownloadError: Error, LocalizedError {
    case emptyAPIKey
    case locationIsNil(location: WeatherLocation)
    case resolveFailed(type: WeatherDataType, location: WeatherLocation, error: Error)
    case downloadFailed(type: WeatherDataType, location: WeatherLocation, error: Error)
    case geocodeFailed(error: Error)
    case decodeFailed(type: WeatherDataType, location: WeatherLocation, error: Error)
    case mimeTypeFailure(failureReason: String)


    public var errorDescription: String? {
        switch self {
        case .emptyAPIKey:
            return "API Key is empty. Add an OpenWeather API Key to use."
        case .locationIsNil(let location):
            return "WeatherLocation \(location.locationName ?? "Unknown name") location (\(location.location?.description ?? "N/A")) is nil. Cannot load location without coordinates."
        case .resolveFailed(let type, let location, let error):
            return "URL Resolution failed for WeatherLocation \(location.locationName ?? "Unknown name"). Cannot form URL for type: \(type.description) error details: \(error.localizedDescription)"
        case .downloadFailed(let type, let location, let error):
            return "Download failed for WeatherLocation \(location.locationName ?? "Unknown name"). Cannot form URL for type: \(type.description) error details: \(error.localizedDescription)"

        case .geocodeFailed(let error):
            return "Geocode failed. Cannot form URL for error details: \(error.localizedDescription)"

        case .decodeFailed(let type, let location, let error):
            return "URL Resolution failed for WeatherLocation \(location.locationName ?? "Unknown name"). Cannot form URL for type: \(type.description) error details: \(error.localizedDescription)"
        case .mimeTypeFailure(let failure):
            return "Download failed: mime-type doesn't match required: \(failure)"
        }
    }
    
    public var errorCode: String? {
        switch self {
        case .locationIsNil: return "300"
        case .resolveFailed: return "301"
        case .downloadFailed: return "302"
        case .geocodeFailed: return "303"
        case .decodeFailed: return "304"
        case .mimeTypeFailure: return "305"
        case .emptyAPIKey: return "306"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .emptyAPIKey:
            return "Add API Key to Project."
        case .locationIsNil:
            return "Try deleting and recreating this location."
        default:
            return "Try again soon."
        }
    }
}
