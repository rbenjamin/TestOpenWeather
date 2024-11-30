//
//  WrapperView.swift
//  Whether
//
//  Created by Ben Davis on 11/12/24.
//

import SwiftUI
import Combine

/**
 `LoadableLabelContent` supports `async` content without requiring the container view to manage
 and track when to show the progress view, manage accessibility labels, or to format the value
 with onChange modifiers.
 
 `LoadableLabelContent` uses a closure to supply the bound value (when it updates to a non-nil
 value) to the `@ViewBuilder` `content`.
 
 It does the same for the `accessibilityLabel`, providing a "Loading" label when `value` is
 `nil`, and changing to the provided formatted string when `value` is __not__ `nil`.
 
  - parameter titleKey: Label title.
  - parameter value: The bound value to be tracked.
  - parameter placeholder: Content shown shown when the timeout is reached.
  - parameter timeout: How long to await the `value` binding before presenting `placeholder`
  - parameter textColor: The color to use for the label.
  - parameter accessibilityLabel: This closure allows the containing view to provide a formatted accessibility label once `value` has loaded.
  - parameter content: View to be displayed when `value` is set.  Allows access to `value` via the view closure.
 
 */

struct LoadableLabelContent<Content: View, BoundValue: Equatable>: View, Equatable {
    @ViewBuilder var content: (BoundValue) -> Content
    private let label: LocalizedStringKey
    @Binding var bound: BoundValue?
    @State private var timeoutReached: Bool = false
    @State private var accessibilityLabel: String?
    let textColor: Color
    let placeholder: LocalizedStringKey
    let timeout: TimeInterval
    let getAccessibilityLabel: (BoundValue) -> String

    init(_ titleKey: LocalizedStringKey,
         value: Binding<BoundValue?>,
         failedPlaceholder: LocalizedStringKey = "N/A",
         timeout: TimeInterval = 10.0,
         textColor: Color = .secondary,
         accessibilityLabel: @escaping (BoundValue) -> String,
         @ViewBuilder
         content: @escaping (BoundValue) -> Content) {
        self.textColor = textColor
        self.label = titleKey
        self.content = content
        self.timeout = timeout
        self.getAccessibilityLabel = accessibilityLabel
        self.placeholder = failedPlaceholder
        _bound = value
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
         lhs.bound == rhs.bound
     }

    var body: some View {
        LabeledContent {
            Group {
                if let bound {
                    content(bound)
                } else if !timeoutReached {
                    ProgressView()
                        .progressViewStyle(TailProgressStyle(category: .medium))
                } else {
                    Text(self.placeholder)
                        .foregroundStyle(self.textColor.secondary)
                }
            }
        } label: {
            Text(self.label)
                .foregroundStyle(self.textColor)
        }
        .transition(.scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel == nil ? Text("Loading ") + Text(self.label) : Text(self.label) + Text(" \(self.accessibilityLabel!)"))

        .onChange(of: self.bound, { oldValue, newValue in
            if oldValue != newValue, let newValue {
                self.accessibilityLabel = self.getAccessibilityLabel(newValue)
            }
        })
        .onAppear {
            guard timeout > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self.timeoutReached = true
            }
        }
    }
}

#Preview {
    LoadableLabelContent<Text, String>("Preview", value: Binding(get: {
        return "test"
    }, set: { _ in
    })) { value in
        return value
    } content: { value in
        Text(value)
    }

}
