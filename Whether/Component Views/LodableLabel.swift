//
//  LodableLabel.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import SwiftUI

struct LodableLabel<Value: StringProtocol>: View {
    @Binding var value: Value?
    let label: LocalizedStringKey
//    let fontStyle: Font.TextStyle

    let font: Font
    @State private var timeoutReached = false
    let placeholder: LocalizedStringKey

    let timeout: TimeInterval

    let textColor: Color
    @State private var id = UUID()

    init(value: Binding<Value?>,
         label: LocalizedStringKey,
         fontStyle: Font.TextStyle? = .body,
         fontSize: CGFloat? = nil,
         fontWeight: Font.Weight? = .regular,
         timeout: TimeInterval = 10,
         timeoutPlaceholder: LocalizedStringKey = "N/A",
         textColor: Color = .secondary) {

        self.textColor = textColor
        _value = value
        self.label = label
        self.timeout = timeout
        self.placeholder = timeoutPlaceholder
        self.font = Self.font(forStyle: fontStyle, fontSize: fontSize, fontWeight: fontWeight)
    }

    private static func font(forStyle fontStyle: Font.TextStyle?,
                             fontSize: CGFloat?,
                             fontWeight: Font.Weight?) -> Font {
        if fontSize == nil, let fontStyle {

            if let fontWeight {
                return .system(fontStyle, design: .monospaced, weight: fontWeight)
            } else {
                return .system(fontStyle, design: .monospaced, weight: .regular)
            }
        } else if let fontSize {
            if let fontWeight {
                return .system(size: fontSize, weight: fontWeight, design: .monospaced)
            } else {
                return .system(size: fontSize, weight: .regular, design: .monospaced)

            }
        } else {
            if let fontWeight {
                return .system(.body, design: .monospaced, weight: fontWeight)
            } else {
                return .system(.body, design: .monospaced, weight: .regular)
            }
        }
    }

    var body: some View {

        LabeledContent {
            if let value {
                Text(value)
                    .font(self.font)
                    .transition(.scale)
                    .foregroundStyle(textColor)
                    .transition(.scale)
//                    .id(self.id)
            } else if !timeoutReached {
                ProgressView()
                    .progressViewStyle(TailProgressStyle(category: .medium))
            } else {
                Text(self.placeholder)
                    .font(self.font)
                    .foregroundStyle(textColor)
                    .transition(.scale)
//                    .id(self.id)
            }
        } label: {
            Text(self.label)
                .foregroundStyle(textColor)
//                .id(self.id)
        }
        .onAppear {
            self.id = UUID()

            guard timeout > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                withAnimation(.bouncy.delay(0.5)) {
                    self.timeoutReached = true
                }
            }
        }
    }
}

#Preview {
    LodableLabel(value: .constant(100.0.formatted()), label: "Label")
}

struct LodableText<Value: StringProtocol>: View {
    @Binding var value: Value?
    let timeout: TimeInterval
    let timeoutPlaceholder: LocalizedStringKey
    @State private var timeoutReached: Bool = false

    init(_ value: Binding<Value?>, timeout: TimeInterval = 10, timeoutPlaceholder: LocalizedStringKey = "N/A") {
        _value = value
        self.timeout = timeout
        self.timeoutPlaceholder = timeoutPlaceholder
    }

    var body: some View {
        HStack {
            if let value {
                Text(value)
                    .transition(.scale)
            } else if !timeoutReached {
                ProgressView()
                    .progressViewStyle(TailProgressStyle(category: .medium))
            } else {
                Text(self.timeoutPlaceholder)
                    .transition(.scale)
            }
        }
        .onAppear {
            guard timeout > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                withAnimation(.bouncy.delay(0.5)) {
                    self.timeoutReached = true
                }
            }
        }
    }
}

#Preview {
    LodableText(.constant("Test"))
}
