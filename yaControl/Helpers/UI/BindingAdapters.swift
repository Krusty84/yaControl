//
//  BindingAdapters.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import SwiftUI

enum BindingAdapters {
    static func restResponseToString(for intValue: Binding<Int?>) -> Binding<String> {
        Binding(
            get: {
                intValue.wrappedValue.map(String.init) ?? ""
            },
            set: { newValue in
                intValue.wrappedValue = Int(newValue)
            }
        )
    }
}

extension Binding where Value == Double {
    func toFormattedString(
        numberStyle: NumberFormatter.Style = .decimal,
        maximumFractionDigits: Int = 2
    ) -> Binding<String> {
        Binding<String>(
            get: {
                let formatter = NumberFormatter()
                formatter.numberStyle = numberStyle
                formatter.maximumFractionDigits = maximumFractionDigits
                return formatter.string(from: NSNumber(value: self.wrappedValue)) ?? ""
            },
            set: { newValue in
                let formatter = NumberFormatter()
                formatter.numberStyle = numberStyle
                if let number = formatter.number(from: newValue) {
                    self.wrappedValue = number.doubleValue
                }
            }
        )
    }
}
