//
//  BillingFormattingHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import SwiftUI

enum BillingFormattingHelper {
    static func balanceAttributedString(
        amount: String,
        currency: String,
        warningThreshold: Double = 50.0
    ) -> AttributedString {
        guard !amount.isEmpty, !currency.isEmpty else {
            var result = AttributedString("N/A")
            result.foregroundColor = .primary
            return result
        }

        let cleanedAmount = amount.replacingOccurrences(
            of: "[^0-9.-]",
            with: "",
            options: .regularExpression
        )

        if let balanceValue = Double(cleanedAmount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.roundingMode = .halfUp

            if let formattedString = formatter.string(from: NSNumber(value: balanceValue)) {
                let fullString = "\(formattedString) \(currency)"
                var result = AttributedString(fullString)

                if balanceValue < 0 {
                    result.foregroundColor = .red
                } else if balanceValue > 0 && balanceValue < warningThreshold {
                    result.foregroundColor = .orange
                } else {
                    result.foregroundColor = .green
                }

                return result
            }
        }

        var result = AttributedString("\(amount) \(currency)")
        result.foregroundColor = .primary
        return result
    }
}
