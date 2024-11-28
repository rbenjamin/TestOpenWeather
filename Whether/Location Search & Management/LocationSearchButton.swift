//
//  LocationSearchButton.swift
//  Whether
//
//  Created by Ben Davis on 11/28/24.
//

import SwiftUI

struct LocationSearchButton: View {
    @Environment(\.isEnabled) var isEnabled: Bool

    private struct RotateScaleKeyframeValues {
        var scale = 1.0
        var rotationAngle = Angle.zero
    }

    let action: () -> Void
    @State private var beginAnimation: Bool = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button {
            self.beginAnimation.toggle()
            self.action()
        } label: {
            Label("Search", systemImage: "location.magnifyingglass")
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundStyle(.green)
                .keyframeAnimator(initialValue: RotateScaleKeyframeValues(),
                                  trigger: self.beginAnimation) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .rotationEffect(value.rotationAngle)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(2.0, duration: 0.25)
                        CubicKeyframe(1.0, duration: 0.25)
                    }
                    KeyframeTrack(\.rotationAngle) {
                        CubicKeyframe(Angle(degrees: -180), duration: 0.15)
                        CubicKeyframe(Angle(degrees: 0), duration: 0.15)
                    }
                }
        }
    }
}

#Preview {
    LocationSearchButton {
        print("tapped")
    }
}
