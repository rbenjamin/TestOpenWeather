//
//  ForecastListView.swift
//  Whether
//
//  Created by Ben Davis on 11/8/24.
//

import SwiftUI
import CoreLocation

struct ForecastFiveDayListView: View {
    @Binding var list: [Forecast.ForecastList]
    let percentFormatter: NumberFormatter
    let isDaytime: Bool

    init(fiveDay: Binding<[Forecast.ForecastList]>,
         isDaytime: Bool,
         percentFormatter: NumberFormatter) {
        _list = fiveDay
        self.isDaytime = isDaytime
        self.percentFormatter = percentFormatter
    }

    var body: some View {
        GroupBox("5 Day Forecast") {
            ForEach(0 ..< 5, id: \.self, content: { idx in
                ForecastRow(list: $list, index: idx, isDaytime: self.isDaytime, percentFormatter: self.percentFormatter)
            })
            .transition(.push(from: .leading))
        }
        .groupBoxStyle(TransparentGroupBox(isDaytime: self.isDaytime))
        .accessibilityElement(children: AccessibilityChildBehavior.contain)
        .accessibilityLabel(Text("Five Day Forecast"))
        .transition(.scale)
    }
}

#Preview {
    ForecastFiveDayListView(fiveDay: .constant([]),
                         isDaytime: true,
                         percentFormatter: NumberFormatter.percentFormatter)
}
