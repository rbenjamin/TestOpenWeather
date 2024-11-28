//
//  WhetherApp.swift
//  Whether
//
//  Created by Ben Davis on 10/22/24.
//

import SwiftUI
import SwiftData

@main
struct WhetherApp: App {
    @Environment(\.scenePhase) var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WeatherLocation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: self.scenePhase) { _, newValue in
            switch newValue {
            case .background:
                try? self.sharedModelContainer.mainContext.save()
            default: break
            }
        }
    }
}
