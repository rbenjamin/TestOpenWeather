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
    
    init(value: Binding<Value?>, label: LocalizedStringKey) {
        _value = value
        self.label = label
    }
    
    var body: some View {
        LabeledContent {
            if let value {
                Text(value)
            }
            else {
                ProgressView()
            }
        } label: {
            Text(self.label)
        }
        .transition(.scale)
    }
}

#Preview {
    LodableLabel(value: .constant(100.0.formatted()), label: "Label")
}
struct LodableText<Value: StringProtocol>: View {
    @Binding var value: Value?
    
    init(_ value: Binding<Value?>) {
        _value = value
    }
    
    var body: some View {
        HStack {
            if let value {
                Text(value)
            }
            else {
                ProgressView()
            }
        }
        .transition(.scale)
    }
}
