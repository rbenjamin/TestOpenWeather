//
//  WindView.swift
//  Whether
//
//  Created by Ben Davis on 11/11/24.
//

import SwiftUI

struct WindView: View {

    @Binding var wind: CurrentWeather.Wind?
    @State private var windSpeed: String?
    @State private var gustLevel: String?
    @State private var direction: String?
    let isDaytime: Bool
    var textColor: Color {
        return self.isDaytime ? Color.secondary : Color.nightTextColor
    }
    var cardinalBackgroundColor: Color {
        return self.isDaytime ? Color("CardinalColorDay").opacity(0.75) : Color("CardinalColorNight").opacity(0.75)
    }
    var cardinalStrokeColor: Color {
        return self.isDaytime ? Color("CardinalColorDay") : Color("CardinalColorNight")
    }

    init(wind: Binding<CurrentWeather.Wind?>, isDaytime: Bool) {
        _wind = wind
        self.isDaytime = isDaytime
    }
    var body: some View {
        GroupBox("Wind") {

            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    LodableLabel(value: self.$windSpeed,
                                 label: "Speed",
                                 textColor: self.textColor)
//                        .id(self.isDaytime)
                    LodableLabel(value: self.$gustLevel,
                                 label: "Gusts",
                                 textColor: self.textColor)
//                        .id(self.isDaytime)
                    LodableLabel(value: self.$direction,
                                 label: "Direction",
                                 textColor: self.textColor)
//                        .id(self.isDaytime)

                }
                .padding(.trailing, 24)
//                    .layoutPriority(1)

//                .padding(.trailing, 12)
                let design = CardinalViewBackground.Design(borderColor: self.textColor,
                                                           mainCardinalHatchColor: self.textColor,
                                                           secondaryCardinalHatchColor: self.textColor,
                                                           labelColor: self.textColor)
                CardinalView(design: design,
                             wind: self.$wind,
                             cardinalPointerBackgroundColor: self.cardinalBackgroundColor,
                             cardinalPointerStrokeColor: self.cardinalStrokeColor)
                    .frame(width: 88, height: 88, alignment: .center)
            }
        }
        .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))
        .onChange(of: self.wind) { _, newValue in
            if let newValue {
                withAnimation(.bouncy) {
                    self.windSpeed = newValue.windSpeed.formatted()
                    self.gustLevel = newValue.gustLevel?.formatted()
                }

                withAnimation(.bouncy.delay(0.5)) {
                    self.direction = newValue.cardinalDirection.stringLabel
                }
            }
        }
        .onAppear {
            if let wind {
                withAnimation(.bouncy) {
                    self.windSpeed = wind.windSpeed.formatted()
                    self.gustLevel = wind.gustLevel?.formatted()
                }
                withAnimation(.bouncy.delay(0.5)) {
                    self.direction = wind.cardinalDirection.stringLabel
                }
            }
        }
    }
}

#Preview {
    WindView(wind: .constant(nil), isDaytime: true)
}
