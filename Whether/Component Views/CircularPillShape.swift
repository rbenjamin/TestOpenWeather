//
//  CircularPillShape.swift
//  Whether
//
//  Created by Ben Davis on 11/18/24.
//

import Foundation
import SwiftUI

struct CircularPillShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let thickness: CGFloat

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
                                     hypothenuse: (radius - (thickness / 2)))

        path.addArc(center: point,
                    radius: thickness / 2,
                    startAngle: endAngle,
                    endAngle: endAngle + .radians(.pi),
                    clockwise: false)

        // Inner circle
        path.addArc(center: center,
                    radius: radius - thickness,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true)

        // Rounded corner (left side)
        point = center + CGPoint(angle: startAngle,
                                 hypothenuse: (radius - (thickness / 2)))

        path.addArc(center: point,
                    radius: thickness / 2,
                    startAngle: startAngle - .radians(.pi),
                    endAngle: startAngle,
                    clockwise: false)

        return path
    }
}
