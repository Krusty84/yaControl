//
//  StatusPanel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/04/2025.
//

import SwiftUI

struct StatusPanel: View {
    @Environment(\.locale) private var locale

    let lastUpdateTime: Date
    let currentBalance: String
    let currency: String
    let billingUrl: URL?
    let billingWarningThreshold: Double

    var body: some View {
        HStack {
            Text(LocalizedStringHelper.formatted(
                L10n.StatusPanel.lastUpdated,
                locale: locale,
                lastUpdateTime.formatted(date: .omitted, time: .shortened)
            ))
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Spacer()
            
            if let url = billingUrl {
                Link(destination: url) {
                    balanceView
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
                .buttonStyle(.plain)
            } else {
                balanceView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var balanceView: some View {
        HStack(spacing: 4) {
            Text(LocalizedStringHelper.string(L10n.StatusPanel.currentBalance, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text(BillingFormattingHelper.balanceAttributedString(
                amount: currentBalance,
                currency: currency,
                warningThreshold: billingWarningThreshold
            ))
                .font(.subheadline)
                .foregroundStyle(.red)
        }
    }
}
