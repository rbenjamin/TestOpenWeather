//
//  CardinalView.swift
//  Whether
//
//  Created by Ben Davis on 10/24/24.
//

import SwiftUI
import CoreGraphics

struct CardinalView: View {

    let design: CardinalViewBackground.Design
    let cardinalPointerBackgroundColor: Color
    let cardinalPointerStrokeColor: Color

    @Binding var wind: CurrentWeather.Wind?

    @State private var animate: Bool = false
    @State private var handAngle: Angle = Angle.zero
    @State private var windIconAngle: Angle = Angle(degrees: 0)

    init(design: CardinalViewBackground.Design = .init(),
         wind: Binding<CurrentWeather.Wind?>,
         cardinalPointerBackgroundColor: Color,
         cardinalPointerStrokeColor: Color) {
        self.design = design
        _wind = wind
        self.cardinalPointerBackgroundColor = cardinalPointerBackgroundColor
        self.cardinalPointerStrokeColor = cardinalPointerStrokeColor
    }

    private struct KeyframeRotationValues {
//        var scale = 1.0
        var rotationAngle = Angle.zero
    }

    private let lineWidth = 2.0
    private let handColor = Color.purple

    func lineCardinalHand(context: GraphicsContext, size: CGSize) {
        var line1 = Path()
        let height = size.height
        let lineHeight = (height * 0.14)

        let rect1 = CGRect(origin: CGPoint.zero,
                           size: CGSize(width: lineWidth, height: lineHeight))
        line1.addRoundedRect(in: rect1, cornerSize: CGSize(width: 2.0, height: 2.0))
        let offset = lineWidth * 2.0

        var line2 = Path()
        let rect2 = CGRect(x: lineWidth, y: 0.0, width: lineWidth, height: lineHeight + 1)
        line2.addRect(rect2)

        var line3 = Path()
        let rect3 = CGRect(x: offset, y: 0, width: lineWidth, height: lineHeight)
        line3.addRoundedRect(in: rect3, cornerSize: CGSize(width: 2.0, height: 2.0))
        context.fill(line1, with: .color(handColor))
        context.fill(line2, with: .color(.white))
        context.fill(line3, with: .color(handColor))
    }

    @ViewBuilder
    var cardinalHand: some View {
        Canvas(renderer: { context, size in
            lineCardinalHand(context: context, size: size)
        })
    }

    var body: some View {

            ZStack {
                CardinalViewBackground(design: self.design,
                                       degrees: self.handAngle.degrees)
                CircularPillShape(startAngle: Angle(degrees: 247.5),
                                  endAngle: Angle(degrees: 292.5),
                                  thickness: 4.0)
                .fill(self.cardinalPointerBackgroundColor)
                .stroke(self.cardinalPointerStrokeColor, style: StrokeStyle(lineWidth: 1, lineJoin: .round))
                .rotationEffect(self.handAngle, anchor: .center)

                Image(systemName: "wind")
                    .imageScale(.small)
                    .foregroundStyle(self.cardinalPointerStrokeColor)
                    .rotationEffect(self.windIconAngle, anchor: .center)
            }
            .padding(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: self.wind?.direction) { _, newValue in
                if let newValue {
                    let direction = CurrentWeather.Wind.WindDirection.init(degrees: newValue)
                    withAnimation(.interpolatingSpring.delay(2.0)) {
                        self.handAngle = Angle(degrees: direction.normalizedDegrees())
                        self.windIconAngle = Angle(degrees: direction.normalizedDegrees() - 90)
                    }
                }
            }
            .onAppear {
                if let dir = self.wind?.direction {
                    let direction = CurrentWeather.Wind.WindDirection.init(degrees: dir)
                    withAnimation(.interpolatingSpring.delay(2.0)) {
                        self.handAngle = Angle(degrees: direction.normalizedDegrees())
                        self.windIconAngle = Angle(degrees: direction.normalizedDegrees() - 90)

                    }
                }
            }
    }
}

#Preview {
    CardinalView(design: .init(),
                 wind: .constant(nil),
                 cardinalPointerBackgroundColor: Color.purple.opacity(0.75),
                 cardinalPointerStrokeColor: Color.purple)
}

struct CardinalViewBackground: View {

    struct Design {
        let borderColor: Color
        let borderWidth: CGFloat
        let mainCardinalHatchColor: Color
        let secondaryCardinalHatchColor: Color
        let hatchLineWidth: CGFloat
        let useLabelShadow: Bool
        let labelColor: Color
        let usePrimaryHatchMarks: Bool
        let useLabels: Bool

        init(borderColor: Color = .secondary,
             borderWidth: CGFloat = 1.0,
             mainCardinalHatchColor: Color = .secondary,
             secondaryCardinalHatchColor: Color = .secondary,
             hatchLineWidth: CGFloat = 1,
             useLabelShadow: Bool = false,
             useLabels: Bool = true,
             labelColor: Color = .secondary,
             usePrimaryHatchMarks: Bool = true) {

            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.mainCardinalHatchColor = mainCardinalHatchColor
            self.secondaryCardinalHatchColor = secondaryCardinalHatchColor
            self.hatchLineWidth = hatchLineWidth
            self.useLabelShadow = useLabelShadow
            self.useLabels = useLabels
            self.labelColor = labelColor
            self.usePrimaryHatchMarks = usePrimaryHatchMarks
        }

    }
    let design: CardinalViewBackground.Design
    let labels: [String]
    let degrees: Double

    init(design: CardinalViewBackground.Design = .init(),
         labels: [String] = ["N", "E", "S", "W"],
         degrees: Double) {
        self.design = design
        self.labels = labels
        self.degrees = degrees
    }

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let rect = CGRect(frame: CGRect(origin: .zero, size: CGSize(width: side, height: side)), insetBy: 2.0)

            let borderPath = Path(ellipseIn: rect)
            context.stroke(borderPath,
                           with: .color(self.design.borderColor),
                           style: StrokeStyle(lineWidth: self.design.borderWidth))

            drawHatchMarks(in: context, frame: rect)
            if self.design.useLabels {
                drawLabels(in: context, frame: rect)
            }
//            drawDirection(in: context, frame: rect)
        }
    }

    private func drawDirection(in context: GraphicsContext,
                               frame: CGRect) {
        let path = self.directionalPath(degrees: self.degrees, frame: frame)
        context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 1, lineCap: .round))

    }

    private func directionalPath(degrees: Double, frame: CGRect) -> Path {
        let widthScale = 1.0

        let midX = frame.midX
        let midY = frame.midY
        let radius = (frame.size.width / 2)
        var cardinalDegrees = degrees
        cardinalDegrees = (-cardinalDegrees / 4.0) * .pi
        let startPoint = CGPoint(x: midX, y: midY)

        let endX = (widthScale * radius) * sin(cardinalDegrees) + midX
        let endY = (widthScale * radius) * cos(cardinalDegrees) + midY

        let endPoint = CGPoint(x: endX, y: endY)
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
    }

    private func drawLabels(in context: GraphicsContext,
                            frame: CGRect) {

        // radius of inner circle that will define label origin:
        // 75% of outer frame
        let radius = min(frame.width, frame.height) / 2 * 0.50

        let fontSize = min(frame.width, frame.height) / 4
        // NOTE: Having trouble ensuring the "10" is offset from the hatch mark at the same distance as "2".
        // * Tried using the size of the NSAttributedString to offset (x,y) but this makes the problem worse.

        let labelCount = self.labels.count

        for index in 0 ..< labelCount {
            let angle = CGFloat(index) * .pi * 2 / Double(labelCount) - (.pi / 2)
            let xPos = cos(angle) * radius + frame.midX + 0.5

            let yPos = sin(angle) * radius + frame.midY

            var attributedString = AttributedString(stringLiteral: self.labels[index])
            attributedString.foregroundColor = self.design.labelColor
            attributedString.font = .system(size: fontSize, weight: .semibold, design: .monospaced)
            context.draw(Text(attributedString), at: CGPoint(x: xPos, y: yPos))
        }
    }

    private func drawHatchMarks(in context: GraphicsContext, frame: CGRect, hatchCount: Int = 16) {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let radius = min(frame.width, frame.height) / 2 * 0.95

        for index in 0 ..< hatchCount {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(hatchCount) - .pi / 2
            let isPrimaryCardinal = (index % 4 == 0)
            let isSecondaryCardinal = (index % 2 == 0)
            var hatchLength = (radius * 0.05)

            if isPrimaryCardinal {
                hatchLength = (radius * 0.10)
            } else if isSecondaryCardinal {
                hatchLength = (radius * 0.20)
            }

            let startRadius = radius - hatchLength
            let endRadius = radius

            let trueStartRadius = isPrimaryCardinal ? startRadius - hatchLength : startRadius

            let startPoint = CGPoint(x: (center.x + cos(angle) * trueStartRadius),
                                     y: (center.y + sin(angle) * trueStartRadius))

            let endPoint = CGPoint(x: center.x + cos(angle) * endRadius,
                                   y: center.y + sin(angle) * endRadius)
//            if isPrimaryCardinal {
//                print("angle: \(angle)")
//            }
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            let color = GraphicsContext.Shading.color(isPrimaryCardinal ? self.design.mainCardinalHatchColor : self.design.secondaryCardinalHatchColor)
            context.stroke(path,
                           with: color,
                           style: StrokeStyle(lineWidth: self.design.hatchLineWidth,
                                              lineCap: .round))
        }
    }
}

#Preview {
    CardinalViewBackground(design: CardinalViewBackground.Design(), degrees: 323.0)
}
