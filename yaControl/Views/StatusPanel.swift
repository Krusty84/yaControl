//
//  StatusPanel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/04/2025.
//

import SwiftUI

struct StatusPanel: View {
    let lastUpdateTime: Date
    let currentBalance: String
    let currency: String
    let billingUrl: URL?
    
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Text(String(
                format: LocalizedStringHelper.string(L10n.Common.lastUpdated, language: SettingsManager.shared.appLanguage),
                lastUpdateTime.formatted(date: .omitted, time: .shortened)
            ))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            if let url = billingUrl {
                Link(destination: url) {
                    HStack(spacing: 0) {
                        Text(LocalizedStringHelper.string(L10n.Common.currentBalance, language: SettingsManager.shared.appLanguage) + " ")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(BillingFormattingHelper.balanceAttributedString(
                            amount: currentBalance,
                            currency: currency,
                            warningThreshold: SettingsManager.shared.billingThreshold
                        ))
                        .font(.subheadline)
                        .foregroundColor(.red)
                    }
                    .onHover { hovering in
                        isHovering = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 0) {
                    Text(LocalizedStringHelper.string(L10n.Common.currentBalance, language: SettingsManager.shared.appLanguage) + " ")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(BillingFormattingHelper.balanceAttributedString(
                        amount: currentBalance,
                        currency: currency,
                        warningThreshold: SettingsManager.shared.billingThreshold
                    ))
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
