//
//  Extensions.swift
//  Whether
//
//  Created by Ben Davis on 10/23/24.
//

import Foundation
import Combine
import SwiftUI
import CoreLocation
import Contacts

extension Notification.Name {
    public static var networkingOn = Notification.Name("networkingOn")
    public static var networkingOff = Notification.Name("networkingOff")
    public static var databaseError = Notification.Name("databaseError")
    public static var downloadError = Notification.Name("downloadError")
}

extension NumberFormatter {
    static var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

extension CGPoint {

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        var rhs = rhs
        rhs.x += lhs.x
        rhs.y += lhs.y
        return rhs
    }
}

extension Calendar {
    func copyComponents(_ components: [Calendar.Component],
                        fromDate: Date,
                        toDate: Date) -> Date? {
        let fromComps = self.dateComponents(in: .current, from: fromDate)
        var toComps = self.dateComponents(in: .current, from: toDate)
        for component in components {
            switch component {
            case .era:
                toComps.era = fromComps.era
            case .year:
                toComps.year = fromComps.year
            case .month:
                toComps.month = fromComps.month
            case .day:
                toComps.day = fromComps.day
            case .hour:
                toComps.hour = fromComps.hour
            case .minute:
                toComps.minute = fromComps.minute
            case .second:
                toComps.second = fromComps.second
            case .weekday:
                toComps.weekday = fromComps.weekday
            case .weekdayOrdinal:
                toComps.weekdayOrdinal = fromComps.weekdayOrdinal
            case .quarter:
                toComps.quarter = fromComps.quarter
            case .weekOfMonth:
                toComps.weekOfMonth = fromComps.weekOfMonth
            case .weekOfYear:
                toComps.weekOfYear = fromComps.weekOfYear
            case .yearForWeekOfYear:
                toComps.yearForWeekOfYear = fromComps.yearForWeekOfYear
            case .nanosecond:
                toComps.nanosecond = fromComps.nanosecond
            case .calendar:
                toComps.calendar = fromComps.calendar
            case .timeZone:
                toComps.timeZone = fromComps.timeZone
            case .isLeapMonth:
                toComps.isLeapMonth = fromComps.isLeapMonth
            case .dayOfYear:
                toComps.dayOfYear = fromComps.dayOfYear
            @unknown default:
                fatalError("\(#function): Unhandled Calendar.Component.")
            }
        }
        let newDate = Calendar.current.date(from: toComps)
        return newDate
    }
}

extension Color {
    static var nightTextColor: Color {
        Color("NightTextColor")
    }
    static var dayTextColor: Color {
        Color("DayTextColor")
    }
    static var systemGroupedBackground: Color {
        return Color(uiColor: UIColor.systemGroupedBackground)
    }
    static var label: Color {
        return Color(uiColor: UIColor.label)
    }
    static var secondaryLabel: Color {
        return Color(uiColor: UIColor.secondaryLabel)
    }
    static var tertiaryLabel: Color {
        return Color(uiColor: UIColor.tertiaryLabel)
    }
    static var quaternaryLabel: Color {
        return Color(uiColor: UIColor.quaternaryLabel)
    }
    static var placeholderText: Color {
        return Color(uiColor: UIColor.placeholderText)
    }
}

extension CLPlacemark {
    /**
     Returns a formatted address via `CNPostalAddressFormatter`.
     
     #Warning:#
     This variable creates a `CNPostalAddressFormatter` every time it is called.
     Only use `formattedAddress` function if the function isn't called multiple times.
     */
    var formattedAddress: String? {
        guard let address = postalAddress else { return nil }
        return CNPostalAddressFormatter().string(from: address)
    }
    /**
     Returns a formatted address via `CNPostalAddressFormatter`.
     Store the `CNPostalAddressFormatter` locally and supply it to this function before calling.
     Prevents function from creating multiple `CNPostalAddressFormatter` objects.
     Creating formatters is expensive.
     */
    func formattedAddress(formatter: CNPostalAddressFormatter? = nil,
                          style: CNPostalAddressFormatterStyle? = nil) -> String? {
        guard let address = postalAddress else { return nil }
        let formatter = formatter ?? CNPostalAddressFormatter()
        if let style {
            formatter.style = style
        }
        return formatter.string(from: address)
    }
}

/**
 Read a view's size. The closure is called whenever the size itself changes.

 From https://stackoverflow.com/a/66822461/14351818
 */
extension View {
    func readSize(size: @escaping (CGSize) -> Void) -> some View {
        return background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ContentSizeReaderPreferenceKey.self, value: geometry.size)
                    .onPreferenceChange(ContentSizeReaderPreferenceKey.self) { newValue in
                        Task { @MainActor in
                            size(newValue)
                        }
                    }
            }
            .hidden()
        )
    }
}

struct ContentSizeReaderPreferenceKey: PreferenceKey {
    static var defaultValue: CGSize { return CGSize() }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

struct FramePreferenceKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

extension View {

    nonisolated public func maxMinimumSize(alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    /// `readFrame(coordinateSpace: onChange:)` provides the frame of the modified view, as defined within the supplied coordinate space.
    ///
    /// - parameter coordinateSpace: The coordinate space in which to determine the modified view's frame.
    /// - parameter onChange: Closure to respond to the frame once it has been determined by the GeometryProxy.
    ///
    func readFrame(coordinateSpace: CoordinateSpace, onChange: @escaping (CGRect) -> Void) -> some View {
        background(
          GeometryReader { geometryProxy in
            Color.clear
                  .preference(key: FramePreferenceKey.self, value: geometryProxy.frame(in: coordinateSpace))
                  .onPreferenceChange(FramePreferenceKey.self, perform: { newValue in
                      Task { @MainActor in
                          onChange(newValue)
                      }
                  })
          }
          .hidden()
        )
  }
}

extension CGRect {
    init(frame: CGRect, insetBy: CGFloat) {
        let insetWidth = frame.size.width - (insetBy * 2)
        let insetHeight = frame.size.height - (insetBy * 2)
       self.init(origin: CGPoint(x: (frame.origin.x + insetBy),
                                 y: (frame.origin.y + insetBy)),
                  size: CGSize(width: insetWidth,
                               height: insetHeight))
    }
}

extension Double {
    static func % (lhs: Double, rhs: Double) -> Int {
        let lhs = abs(lhs)
        let rhs = abs(rhs)
        var mod = lhs
        while mod >= rhs {
            mod -= rhs
        }
        if lhs < 0 {
            return Int(mod * -1)
        }
        return Int(mod)
    }
}
