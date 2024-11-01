//
//  RainView.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import SwiftUI

struct RainView: View {
    let rain: CurrentWeather.Rain
    let rainAmount: String
    
    init(rain: CurrentWeather.Rain) {
        self.rainAmount = rain.oneHour.formatted()
        self.rain = rain
    }
    
    var body: some View {
        LabeledContent("Rain / Hour:", value: self.rainAmount)
        
    }
}

#Preview {
    RainView(rain: CurrentWeather.Rain(oneHour: 0.0))
}

struct SnowView: View {
    let snow: CurrentWeather.Snow
    let snowAmount: String
    
    init(snow: CurrentWeather.Snow) {
        self.snowAmount = snow.oneHour.formatted()
        self.snow = snow
    }
    
    var body: some View {
        LabeledContent("Rain / Hour:", value: self.snowAmount)
        
    }
}

#Preview {
    SnowView(snow: CurrentWeather.Snow(oneHour: 0.0))
}
