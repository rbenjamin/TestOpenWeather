//
//  HighlightableRoundedRect.swift
//  Whether
//
//  Created by Ben Davis on 12/7/24.
//

import Foundation
import SwiftUI

struct HighlightableRoundedRect<S>: View where S: ShapeStyle {
    let cornerRadius: CGFloat
    let style: RoundedCornerStyle
    let highlight: Bool
    let fill: S
    let fillStyle: FillStyle

    init(cornerRadius: CGFloat,
         style: RoundedCornerStyle = .continuous,
         highlight: Bool = false,
         fill: S = .foreground,
         fillStyle: FillStyle = FillStyle()) {
        self.cornerRadius = cornerRadius
        self.style = style
        self.highlight = highlight
        self.fill = fill
        self.fillStyle = fillStyle
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: self.style)
                .fill(self.fill, style: self.fillStyle)
            // Overlay highlight: Highlights the top of the rounded rect with a line.
            // Uses a gradient to fade the line as it approaches end of path.
            // Path is inset by 1 into the rounded rect.
            Canvas { context, size in

                var overlay = Path()

                // Top Left
                let topLCenter = CGPoint(x: cornerRadius, y: cornerRadius + 1)

                overlay.move(to: CGPoint(x: 0, y: cornerRadius + 1))
                overlay.addArc(center: topLCenter,
                               radius: cornerRadius,
                               startAngle: .degrees(180.0),
                               endAngle: .degrees(270.0),
                               clockwise: false)
    //            // Connect corners
                overlay.addLine(to: CGPoint(x: size.width - cornerRadius,
                                            y: 1))
    //            // Top Right
                let topRCenter = CGPoint(x: size.width - cornerRadius,
                                         y: cornerRadius + 1)
    //
                overlay.addArc(center: topRCenter,
                               radius: cornerRadius,
                               startAngle: .degrees(270),
                               endAngle: .degrees(0),
                               clockwise: false)
                let gradientColors: [Color] = [.white.opacity(0.75), .clear]
                let gradient: GraphicsContext.Shading = .linearGradient(Gradient(colors: gradientColors),
                                                                        startPoint: CGPoint(x: 0,
                                                                                            y: 0),
                                                                        endPoint: CGPoint(x: 0,
                                                                                          y: cornerRadius / 2))
                context.stroke(overlay,
                               with: gradient,
                               style: .init(lineWidth: 1))
            }
            .opacity(highlight ? 1 : 0)
        }
    }
}
