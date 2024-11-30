//
//  LocationPositionHeader.swift
//  Whether
//
//  Created by Ben Davis on 11/15/24.
//

import SwiftUI

struct LocationPositionHeader: View {
    let previousLocation: WeatherLocation?
    let nextLocation: WeatherLocation?
    let current: WeatherLocation
    let isDaytime: Bool

    private let previousLabel: String?
    private let nextLabel: String?
    let scrollTo: (WeatherLocation?) -> Void

    init(isDaytime: Bool,
         previousLocation: WeatherLocation?,
         current: WeatherLocation,
         nextLocation: WeatherLocation?,
         scrollTo: @escaping (WeatherLocation?) -> Void) {
        self.isDaytime = isDaytime
        self.previousLocation = previousLocation
        self.nextLocation = nextLocation
        self.previousLabel = previousLocation?.locationName
        self.nextLabel = nextLocation?.locationName
        self.scrollTo = scrollTo
        self.current = current
    }

    var locationLabel: some View {
        Canvas { context, size in
            let label = self.current.locationName ?? "Unknown Name"

            let text = NSMutableAttributedString(string: label)
            let textFont = UIFont.systemFont(ofSize: UIFont.labelFontSize,
                                             weight: .semibold,
                                             width: .standard)
            text.addAttributes([
                                NSAttributedString.Key.foregroundColor: UIColor.white,
                                NSAttributedString.Key.font: textFont
                               ],
                               range: NSRange.init(location: 0, length: label.count))

            let storage = NSTextStorage(attributedString: text)
            let manager = NSLayoutManager()
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0
            manager.addTextContainer(container)
            storage.addLayoutManager(manager)
            manager.glyphRange(for: container)
            let layoutSize = manager.usedRect(for: container).size
            let textRect = CGRect(origin: CGPoint(x: layoutSize.width / 2, y: 0),
                                  size: CGSize(width: size.width + layoutSize.width / 2, height: size.height))

            context.draw(Text(AttributedString(text)), in: textRect)
            context.addFilter(.shadow(color: Color.black.opacity(0.50), radius: 1.0, x: 1, y: 1))

        }
    }

    func loadPrevious() {
        if let previousLocation {
            self.scrollTo(previousLocation)
        }
    }

    func loadNext() {
        if let nextLocation {
            self.scrollTo(nextLocation)
        }
    }

    var body: some View {
        let columns = [GridItem(alignment: .leading),
                       GridItem(alignment: .center),
                       GridItem(alignment: .trailing)]
        LazyVGrid(columns: columns) {
            Button {
                self.loadPrevious()
            } label: {
                Image(systemName: "chevron.compact.left")
                    .imageScale(.medium)
                    .foregroundStyle(Color.accentColor)

                Text("\(previousLabel ?? "...")")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .allowsTightening(true)
                    .truncationMode(.tail)
            }
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor)
                    .fill(self.isDaytime ? Color.white.opacity(0.30) : Color.black.opacity(0.30))
            }
            .opacity(previousLocation != nil ? 1 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(previousLabel ?? "...")"), isEnabled: previousLabel != nil)
            .accessibilityHint(Text("Previous Location"), isEnabled: previousLabel != nil)
            .accessibilityAddTraits(.isButton)

//            self.locationLabel
            Text(self.current.locationName ?? "Unknown Name")
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(alignment: .center)
                .allowsTightening(true)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.50), radius: 1.0, x: 1, y: 1)
                .accessibilityHint(Text("Current Location"))

            Button {
                self.loadNext()
            } label: {
                Text("\(nextLabel ?? "...")")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .allowsTightening(true)
                    .truncationMode(.tail)

                Image(systemName: "chevron.compact.right")
                    .imageScale(.medium)
                    .foregroundStyle(Color.accentColor)

            }
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor)
                    .fill(self.isDaytime ? Color.white.opacity(0.30) : Color.black.opacity(0.30))
            }
            .opacity(nextLocation != nil ? 1 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(nextLabel ?? "...")"), isEnabled: previousLabel != nil)
            .accessibilityHint(Text("Next Location"), isEnabled: previousLabel != nil)
            .accessibilityAddTraits(.isButton)
        }
            .padding([.leading, .trailing], 12)
    }
}

#Preview {
    LocationPositionHeader(isDaytime: true, previousLocation: nil, current: WeatherLocation(), nextLocation: nil) {_ in
    }
}
