//
//  GaugeView.swift
//  Whether
//
//  Created by Ben Davis on 11/12/24.
//

import SwiftUI

/**
 `GaugeView` is a gauge, similar to what is available on WatchOS, used to represent Measurement values.
 
 - parameter value: Measurement to be shown on the gauge.
 - parameter range: Range of measurements used to determine position of `value` in the gauge.
 - parameter fill:  The color or gradient to use as the fill for the gauge.
 
 Add labels to the gauge with the function `labels(leading: trailing:)`.
 
 The parameters `leadingOffset` and `trailingOffset` are important to offset the label when an `Image` is used for the leading or trailing labels.
 
 If you are providing `Text` to the `labels(:)` function, __offsets__ aren't needed.
 
 ## Warning: ##
 - Ensure the provided `range` and `value` are both the same measurement system.
 
 ## Notes: ##
 1. Some of the design code for this view is modified based on project https://github.com/kkla320/GaugeProgressViewStyle by `kkla320` on GitHub.
 */

struct GaugeView<UnitType: Unit, FillShape: ShapeStyle & View>: View {

    private struct GaugeLabelView<Label: View>: View {
        @ViewBuilder let label: Label

        let fillShape: Color
        let angle: Angle
        let position: GaugeView.LabelPosition
        let size: CGSize
        let width: CGFloat
        let leadingOffset: CGPoint
        let trailingOffset: CGPoint

        init(@ViewBuilder
             label: () -> Label,
             fill: Color,
             angle: Angle,
             position: GaugeView.LabelPosition,
             size: CGSize,
             width: CGFloat,
             leadingOffset: CGPoint = .zero,
             trailingOffset: CGPoint = .zero) {
            self.label = label()
            self.fillShape = fill
            self.angle = angle
            self.size = size
            self.position = position
            self.width = width
            self.leadingOffset = leadingOffset
            self.trailingOffset = trailingOffset
        }
        var body: some View {
            let rect = self.position.rect(of: self.size,
                                          angle: self.angle,
                                          shapeWidth: self.width)
            self.label
                .frame(width: rect.width,
                       height: rect.height,
                       alignment: self.position == LabelPosition.leading ? Alignment.leading : Alignment.trailing)
                .position(x: rect.midX,
                          y: rect.midY)
                .offset(x: self.position == .leading ? self.leadingOffset.x : self.trailingOffset.x,
                        y: self.position == .leading ? self.leadingOffset.y : self.trailingOffset.y)
                .foregroundStyle(self.fillShape)
        }
    }

    private enum LabelPosition {
        case leading
        case trailing

        func rect(of size: CGSize, angle: Angle, shapeWidth: CGFloat) -> CGRect {
            let widthOffset = (shapeWidth / 2)

            let offset = self == .leading ? widthOffset : -widthOffset

            let minSide = min(size.width, size.height) / 2
            let hypothenuse = (minSide - widthOffset)

            var topRight = CGPoint(angle: angle,
                                   hypothenuse: hypothenuse)
            topRight.x += offset

            let width = abs(topRight.x)
            let height = minSide - abs(topRight.y)
            let xPos = min((size.width / 2) + topRight.x, (size.width / 2))
            let yPos = (size.height / 2) + topRight.y

            let frame = CGRect(x: xPos, y: yPos, width: width, height: height)

            return frame
        }
    }

    private struct GaugeShape: Shape {
        let insetSize: CGFloat
        let startAngle: Angle
        let endAngle: Angle

        func path(in rect: CGRect) -> Path {

            let radius = min(rect.size.width, rect.size.height) / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)

            var path = Path()
            // Top-curve from left to right
            path.addArc(center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)

            // Rounded corner (right side)
            var point = center + CGPoint(angle: endAngle,
                                         hypothenuse: (radius - (insetSize / 2)))

            path.addArc(center: point,
                        radius: insetSize / 2,
                        startAngle: endAngle,
                        endAngle: endAngle + .radians(.pi),
                        clockwise: false)

            // Inner circle
            path.addArc(center: center,
                        radius: radius - insetSize,
                        startAngle: endAngle,
                        endAngle: startAngle,
                        clockwise: true)

            // Rounded corner (left side)
            point = center + CGPoint(angle: startAngle,
                                     hypothenuse: (radius - (insetSize / 2)))

            path.addArc(center: point,
                        radius: insetSize / 2,
                        startAngle: startAngle - .radians(.pi),
                        endAngle: startAngle,
                        clockwise: false)

            return path
        }
    }

    private struct GaugeIndicator<Shape: ShapeStyle>: View {
        let diameter: CGFloat
        let fill: Shape
        let fillStyle: FillStyle
        let stroke: Shape
        let strokeStyle: StrokeStyle
        let angle: Angle
        let inset: CGFloat

        init(diameter: CGFloat,
             inset: CGFloat = 3,
             fill: Shape = Color.clear,
             fillStyle: FillStyle = .init(eoFill: true, antialiased: true),
             stroke: Shape = Color.white,
             strokeStyle: StrokeStyle = .init(lineWidth: 1),
             angle: Angle) {

            self.diameter = diameter
            self.fill = fill
            self.inset = inset
            self.fillStyle = fillStyle
            self.stroke = stroke
            self.strokeStyle = strokeStyle
            self.angle = angle
        }

        var body: some View {
            GeometryReader { proxy in
                let minSide = min(proxy.size.width, proxy.size.height) / 2
                let radius = self.diameter / 2

                Circle()
                    .stroke(self.stroke, style: self.strokeStyle)
                    .fill(self.fill, style: self.fillStyle)
                    .frame(width: self.diameter - self.strokeStyle.lineWidth - inset,
                           height: self.diameter - self.strokeStyle.lineWidth - inset)
                    .offset(x: CGPoint(angle: self.angle, hypothenuse: (minSide - radius)).x,
                            y: CGPoint(angle: self.angle, hypothenuse: (minSide - radius)).y)
                    .frame(width: proxy.size.width,
                           height: proxy.size.height)
            }
        }
    }
    typealias GaugeMeasurement = Measurement<UnitType>

    @Binding private var value: GaugeMeasurement
    private let range: ClosedRange<Measurement<Unit>>
    private let fill: FillShape

    init(value: Binding<GaugeMeasurement>,
         fill: FillShape,
         range: ClosedRange<Measurement<Unit>>) {

        _value = value
        self.fill = fill
        self.range = range
    }

    public func labels<Label: View>(@ViewBuilder
                                    leading: @escaping () -> Label,
                                    leadingColor: Color = Color.secondary,
                                    leadingOffset: CGPoint = .zero,
                                    @ViewBuilder
                                    trailing: @escaping () -> Label,
                                    trailingColor: Color = Color.secondary,
                                    trailingOffset: CGPoint = .zero) -> some View {
        ZStack {
            self
            GeometryReader { proxy in
                    GaugeLabelView(label: {
                        leading()
                    }, fill: leadingColor,
                                   angle: .radians(.pi),
                                   position: .leading,
                                   size: proxy.size,
                                   width: 0,
                                   leadingOffset: leadingOffset)
                    GaugeLabelView(label: {
                        trailing()
                    }, fill: trailingColor,
                                   angle: .zero,
                                   position: .trailing,
                                   size: proxy.size,
                                   width: 0,
                                   trailingOffset: trailingOffset)
            }
        }
    }

    private func rotate(_ value: Double) -> Angle {
        var modifiedValue = value
        /// Clamp the value to the min/max if self.value extends below or above `self.range`
        ///
        modifiedValue = max(min(self.value.value, self.range.upperBound.value), self.range.lowerBound.value)

        let normalized = self.normalize(modifiedValue, range: self.range)

        return ((.degrees(360) - (.radians(.pi) - .zero)) * normalized)

    }

    private func normalize(_ value: Double, range: ClosedRange<Measurement<Unit>>) -> Double {
        let (min, max) = (range.lowerBound.value, range.upperBound.value)
        if max - min == 0 { return 1 }
        return (value - min) / (max - min)
    }

    var body: some View {

            ZStack {
                GaugeShape(insetSize: 10,
                           startAngle: .radians(.pi),
                           endAngle: .zero)
                    .fill(self.fill)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1))

                GaugeIndicator(diameter: 10,
                               fill: .white.opacity(0.75),
                               angle: .radians(.pi))
                .rotationEffect(rotate(self.value.value), anchor: UnitPoint.center)
            }

    }
}
#Preview {
    let pressure = Measurement<UnitPressure>(value: 20, unit: .inchesOfMercury)
    let range = Measurement<UnitPressure>.range(startValue: 800, endValue: 1200, unit: .inchesOfMercury)
    GaugeView(value: .constant(pressure), fill: .red, range: range)
}
