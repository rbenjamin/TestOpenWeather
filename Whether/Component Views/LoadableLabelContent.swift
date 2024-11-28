//
//  WrapperView.swift
//  Whether
//
//  Created by Ben Davis on 11/12/24.
//

import SwiftUI
import Combine

/// `LoadableLabelContent` is an `async` label view that supports custom content.
///
///  title: Label title
///  placeholder: Content shown shown when the timeout is reached.
///  timeout: How long to await the `value` binding before presenting `placeholder`
///  content: View to be displayed when `BoundValue` is set.  Allows access to `BoundValue` via the view closure
///
struct LoadableLabelContent<Content: View, BoundValue: Equatable>: View, Equatable {
    @ViewBuilder var content: (BoundValue) -> Content
    private let label: LocalizedStringKey
    @Binding var bound: BoundValue?
    @State private var timeoutReached: Bool = false
    let textColor: Color
    let placeholder: LocalizedStringKey
    let timeout: TimeInterval

    init(_ titleKey: LocalizedStringKey,
         value: Binding<BoundValue?>,
         failedPlaceholder: LocalizedStringKey = "N/A",
         timeout: TimeInterval = 10.0,
         textColor: Color = .secondary,
         @ViewBuilder
         content: @escaping (BoundValue) -> Content) {
        self.textColor = textColor
        self.label = titleKey
        self.content = content
        self.timeout = timeout
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
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Text(self.label)
                .foregroundStyle(self.textColor)
        }
        .transition(.scale)
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
    })) { text in
        Text(text)
    }
}
