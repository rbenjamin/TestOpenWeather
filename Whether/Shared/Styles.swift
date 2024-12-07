//
//  Styles.swift
//  Whether
//
//  Created by Ben Davis on 10/24/24.
//

import Foundation
import SwiftUI
struct TransparentGroupBox: GroupBoxStyle {
    let isDaytime: Bool
    let shouldHighlight: Bool

    init(isDaytime: Bool, shouldHighlight: Bool = false) {
        self.isDaytime = isDaytime
        self.shouldHighlight = shouldHighlight
    }
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack {
                configuration.label
                    .font(.headline)
                    .foregroundStyle(self.isDaytime ? .black.opacity(0.75) : .white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            configuration.content
        }
        .padding()
        .background {
            HighlightableRoundedRect(cornerRadius: 8,
                                     style: .continuous,
                                     highlight: self.shouldHighlight,
                                     fill: Material.ultraThinMaterial.opacity(isDaytime ? 0.75 : 0.75))

        }
    }
}

#Preview {
    GroupBox("Wind") {
        Text("Test preview of transparant group box")
    }
    .groupBoxStyle(TransparentGroupBox(isDaytime: true))
}

struct TailProgressStyle: ProgressViewStyle {

    enum TailSizeCategory: CGFloat {
        case small = 12
        case medium = 18
        case large = 24
        case xLarge = 48
    }

    let size: CGFloat
    let colors: [Color]

    init(size: CGFloat,
         colors: [Color] = [Color.clear, Color.white]) {
        self.size = size
        self.colors = colors
    }

    init(category: TailSizeCategory,
         colors: [Color] = [Color.clear, Color.white]) {
        self.size = category.rawValue
        self.colors = colors
    }
    private struct KeyframeRotation {
        var angle = Angle.zero
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            CircularPillShape(startAngle: Angle(degrees: 90),
                              endAngle: Angle(degrees: 270),
                              thickness: 2)
            .fill(AngularGradient(colors: self.colors,
                                  center: .center,
                                  startAngle: .degrees(90),
                                  endAngle: .degrees(270)))
        }
        .frame(width: size,
               height: size)
        .keyframeAnimator(initialValue: KeyframeRotation(),
                          repeating: true,
                          content: { content, value in
            content
                .rotationEffect(value.angle, anchor: .center)
        }, keyframes: { _ in
            KeyframeTrack(\.angle) {
                LinearKeyframe(.degrees(360.0), duration: 1.0)
            }
        })
    }
}

struct WeatherLabelStyle: LabeledContentStyle {
    let foregroundStyle: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundStyle(self.foregroundStyle)
            Spacer()
            configuration.content
                .monospaced()
                .foregroundStyle(self.foregroundStyle)

        }
    }
}
