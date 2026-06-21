//
//  SettingsBillingManagementTabView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsBillingManagementTabView: View {
    @Environment(\.locale) private var locale
    @Bindable var model: SettingsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                Section {
                    HStack {
                        TextField(
                            LocalizedStringKey(L10n.Settings.billingThresholdPlaceholder),
                            value: $model.billingThreshold,
                            format: .number.precision(.fractionLength(2))
                        )
                        .textFieldStyle(.roundedBorder)
                        .help(localized(L10n.Settings.billingThresholdHelp))
                    }
                    .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
                } header: {
                    SettingsSectionHeader(
                        title: LocalizedStringKey(L10n.Settings.billingThresholdTitle),
                        systemImage: "dollarsign.circle.fill"
                    )
                }

                Spacer()
            }
            .padding(SettingsLayout.outerPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
