//
//  ParticleViews.swift
//  Whether
//
//  Created by Ben Davis on 10/24/24.
//

import SwiftUI
import Vortex

struct SnowEffect: View {
    private let wind: CurrentWeather.Wind
    private let snow: CurrentWeather.Snow
    
    let density: CurrentWeather.Snow.SnowDensity
    let speed: CurrentWeather.Wind.WindSpeedCategory
    
    init(snow: CurrentWeather.Snow, wind: CurrentWeather.Wind, speed: CurrentWeather.Wind.WindSpeedCategory? = nil) {
        self.snow = snow
        self.wind = wind
        self.speed = speed ?? wind.speedCategory
        self.density = snow.snowDensity
        print("density: \(density.localizedString)")
    }
    
    var body: some View {
        VortexView(.snow) {
            Circle()
                .fill(.white)
                .frame(width: 6.0)
                .tag("circle")
            
            Circle()
                .fill(.white)
                .frame(width: 8.0)
                .tag("circle2")
        }
    }
    
    func createSnow() -> VortexSystem {
        let system = VortexSystem(tags: ["circle2"])
        system.position = [0.5, 0]

        switch speed {
        case .none:
            system.angle = .degrees(180)
            system.angleRange = .degrees(0)

        case .slow:
            system.angle = .degrees(168.75)
            system.angleRange = .degrees(10)

        case .normal:
            system.angle = .degrees(168.75)
            system.angleRange = .degrees(20)

        case .fast:
            system.angle = .degrees(101.0)
            system.angleRange = .degrees(30)

        case .extreme:
            system.angle = .degrees(90.0)
            system.angleRange = .degrees(0)
        }
        
        switch self.density {
        case .light: // 0-1 mm/hr
            system.speed = 1
            system.speedVariation = 0.25
            system.lifespan = 4
            system.size = 0.5
            system.sizeVariation = 0.25
            system.idleDuration = 0
            system.emissionDuration = 1.0

        case .medium: // 1-4 mm/hr
            system.speed = 0.75
            system.speedVariation = 0.25
            system.lifespan = 6
            system.size = 0.25
            system.sizeVariation = 0.25
            system.idleDuration = 0.50
            system.emissionDuration = 0.50

        case .heavy: // 4-7 mm/hr
            system.speed = 0.40
            system.speedVariation = 0.25
            system.lifespan = 10
            system.size = 0.20
            system.sizeVariation = 0.25
            system.secondarySystems = [.snow]
            system.idleDuration = 0.1
            system.emissionLimit = nil
            system.emissionDuration = 0.1

        case .extreme: // 7+ mm/hr
            system.speed = 0.20
            system.speedVariation = 0.05
            system.acceleration = SIMD2<Double>(2.0, 2.0)
            system.idleDuration = 0.0
            system.emissionLimit = nil
            system.emissionDuration = 0.0

            system.lifespan = 10
            system.size = 0.750
            system.sizeVariation = 0.25
            system.secondarySystems = [.snow]

        }
        system.shape = .box(width: 1, height: 1)
        return system
    }

}

#Preview {
    SnowEffect(snow: CurrentWeather.Snow(oneHour: 0.5),
               wind: CurrentWeather.Wind(windSpeed: Measurement<UnitSpeed>(value: 1.5, unit: .metersPerSecond),
                                         direction: 22.5,
                                         gustLevel: 0.0))
}

