//
//  TemperatureGauge.swift
//  Whether
//
//  Created by Ben Davis on 11/1/24.
//

import SwiftUI

/**
 
`TemperatureGuage` uses Measurement<UnitTemperature> to display the current temperature
 within a temperature range.
 Uses `CurrentWeather.ConditionModifier` to determine the gradient coloring of the gauge.
 */

struct TemperatureGauge: View {

    private struct KeyframeRotation {
        var angle = Angle.zero
    }

    private enum GaugeDirection {
        case horizontal
        case vertical
    }

    @Binding var temperature: Measurement<UnitTemperature>?
    let width: Double
    let height: Double
    private let direction: GaugeDirection
    @State private var rotationAngle: Double = 0.0
    @State private var condition: CurrentWeather.ConditionModifier?
    @State private var animationTimeout: Bool = false
    @State private var accessibilityValue = ""
    let range = UnitTemperature.celcius(value: -30) ... UnitTemperature.celcius(value: 50)

    /** Initializes `TemperatureGauge` as a *verticle* gauge, with height determined by the  containing view and with width specified here.
     
        - parameter temperature: The temperature measurement, in celcius.
        - parameter width: The width of the verticle view.
     */
    init(temperature: Binding<Measurement<UnitTemperature>?>,
         width: Double) {
        _temperature = temperature
        self.width = width
        self.height = 0.0
        self.direction = .vertical
    }

    /** Initializes `TemperatureGauge` as a *horizontal* gauge, with width determined by the  containing view and with height specified here.
     
        - parameter temperature: The temperature measurement, in celcius.
        - parameter height: The height of the horizontal view.
     */
    init(temperature: Binding<Measurement<UnitTemperature>?>,
         height: Double) {
        _temperature = temperature

        self.height = height
        self.width = 0.0
        self.direction = .horizontal
    }

    func transition(_ edge: Edge) -> AnyTransition {
        return .push(from: edge).combined(with: .opacity)
    }

    var body: some View {
        GeometryReader { proxy in
            let midWidth = direction == .horizontal ? (0) : width / 2
            let midHeight = direction == .vertical ? (0) : height / 2

            RoundedRectangle(cornerRadius: self.direction == .vertical ? midWidth  : midHeight)
                     .stroke(Color.white, lineWidth: 1.0)
                     .frame(maxHeight: .infinity)
                     .frame(width: self.height == 0 ? self.width : nil,
                            height: self.width == 0 ? self.height : nil)
                     .background {

                    if self.direction == .vertical {
                        LinearGradient(colors: self.gradientValues,
                                       startPoint: .top,
                                       endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: self.direction == .vertical ? midWidth : midHeight))
                    } else {
                        LinearGradient(colors: self.gradientValues,
                                       startPoint: .leading,
                                       endPoint: .trailing)
                        .clipShape(RoundedRectangle(cornerRadius: self.direction == .vertical ? midWidth : midHeight))
                    }
                }
                .overlay {
                    // Show the current temperature indicator if we have a temperature:
                    // Otherwise, show an activity indicator (ProgressView)
                    let size = proxy.size

                    if let temp = self.temperature {
                        let origin = position(in: size, temperature: temp)

                        Circle()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 1))
                            .fill(.white.opacity(0.60))
                            .frame(width: self.direction == .vertical ? self.width : midHeight,
                                   height: self.direction == .vertical ? midWidth : self.height,
                                   alignment: .center)
                            .position(x: self.direction == .horizontal ? origin.x + (midHeight / 2) : midWidth,
                                      y: self.direction == .vertical ? origin.y + (midWidth / 2) : midHeight)
                            .transition(self.transition(self.width == 0 ? .leading : .top))
                    } else if self.animationTimeout == false {
                        let minSide = min(size.width, size.height) - 4.0
                        let halfMinSide = minSide / 2

                        let origin = position(in: size,
                                              temperature: self.range.lowerBound)
                        let quarterW = midWidth / 2
                        let quarterH = midHeight / 2
                        let offset = self.direction == .horizontal ? origin.x + 2.0 : origin.y + 2.0
                        let xPos = self.direction == .horizontal ? offset + quarterH + halfMinSide : midWidth + 0.5
                        let yPos = self.direction == .vertical ? offset + quarterW + halfMinSide : midHeight + 0.5
                        HStack(spacing: 0) {
                            CircularPillShape(startAngle: .degrees(90),
                                              endAngle: .degrees(270),
                                              thickness: 2)
                            .fill(AngularGradient(colors: [Color.clear, Color.white],
                                                  center: .center,
                                                  startAngle: .degrees(90),
                                                  endAngle: .degrees(270)))
                        }
                        .keyframeAnimator(initialValue: KeyframeRotation(),
                                          repeating: true,
                                          content: { content, value in
                            content
                                .rotationEffect(value.angle)
                        }, keyframes: { _ in
                            KeyframeTrack(\.angle) {
                                LinearKeyframe(.degrees(360.0), duration: 1.0)
                            }
                        })
                        .frame(width: minSide,
                               height: minSide,
                               alignment: .center)
                        .position(x: xPos,
                                  y: yPos)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: self.direction == .vertical ? midWidth  : midHeight))
        }
        .frame(width: direction == .horizontal ? nil : self.width)
        .frame(height: direction == .vertical ? nil : self.height)
        .accessibilityLabel(Text("Temperature Gauge"))
        .accessibilityValue(Text(self.accessibilityValue))
        .onChange(of: self.temperature) { oldValue, newValue in
            if let newValue, newValue != oldValue {
                self.condition = CurrentWeather.ConditionModifier(temperature: newValue.converted(to: .kelvin).value)
                let converted = newValue.converted(to: UnitTemperature(forLocale: .current, usage: .weather))
                self.accessibilityValue = converted.formattedWeatherString()

            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.animationTimeout = true
            }
            if let temperature {
                self.accessibilityValue = temperature.formatted(.measurement(width: .abbreviated, usage: .asProvided))
            }
        }
    }
    /// `normalize(_:, range:)` converts the temperature value between `range` into a value between 0 and 1; this way it can be used to determine the position of the overlay.
    private func normalize(_ value: Double,
                           range: ClosedRange<Measurement<UnitTemperature>>) -> Double {
        let (min, max) = (range.lowerBound.value, range.upperBound.value)
        if max - min == 0 { return 1 }
        return (value - min) / (max - min)
    }

    func position(in size: CGSize,
                  temperature: Measurement<UnitTemperature>) -> CGPoint {
        var tempValue = temperature.converted(to: .celsius).value
        tempValue = min(max(tempValue, self.range.lowerBound.value), self.range.upperBound.value)
        tempValue = normalize(tempValue, range: self.range)

        // if self.width == 0, we're looking @ temperature gauge horizontal: the width is variable and the height is static.
        // So we want to use the variable width in our conversion
        let modifier = self.width == 0 ? size.width : size.height
        let positioned = modifier * tempValue
        return self.height == 0 ? CGPoint(x: 0, y: positioned) : CGPoint(x: positioned, y: 0)
    }
    var gradientValues: [Color] {
        let normal = [Color("CoolColor"), Color("NormalColor"), Color("WarmColor")]
        if let condition {
            switch condition {
            case .hot:
                return [Color("NormalColor"), Color("WarmColor"), Color("HotColor")]
            case .normal:
                return normal
            case .cold:
                return [Color("ColdColor"), Color("CoolColor"), Color("NormalColor")]
            }
        } else {
            return normal
        }
    }
}

#Preview {
    let temp = Measurement<UnitTemperature>(value: 72.5, unit: .fahrenheit)
    TemperatureGauge(temperature: .constant(temp), width: 12.0)
}
