//
//  Settings.swift - Application Settings
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsTabContent: View {
    @Environment(\.locale) private var locale

    @State private var model = SettingsModel()
    @State private var selectedTab: SettingsTab = .general
    @State private var apiDebugStore = APIDebugStore.shared

    private enum SettingsTab: Hashable {
        case general
        case cloud
        case virtualMachineManagement
        case billingManagement
        case debug
    }

    var body: some View {
        VStack(spacing: 0) {
            tabPicker

            Divider()

            selectedTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            model.loadSettings()

            if selectedTab == .cloud {
                Task {
                    await model.loadFoldersForCreation(locale: locale)
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .cloud else { return }

            Task {
                await model.loadFoldersForCreation(locale: locale)
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            settingsTabButton(
                LocalizedStringKey(L10n.Settings.generalTab),
                tab: .general
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.cloudTab),
                tab: .cloud
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.vmManagementTab),
                tab: .virtualMachineManagement
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.billingManagementTab),
                tab: .billingManagement
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.debugTab),
                tab: .debug
            )
        }
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: 6))
        .padding(.horizontal, SettingsLayout.tabHorizontalPadding)
        .padding(.top, SettingsLayout.tabTopPadding)
        .padding(.bottom, SettingsLayout.rowSpacing)
    }

    private func settingsTabButton(
        _ title: LocalizedStringKey,
        tab: SettingsTab
    ) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(
            selectedTab == tab
            ? Color.accentColor.opacity(0.22)
            : Color.clear
        )
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .general:
            SettingsGeneralTabView(model: model)

        case .cloud:
            SettingsCloudTabView(model: model)

        case .virtualMachineManagement:
            SettingsVMManagementTabView(model: model)

        case .billingManagement:
            SettingsBillingManagementTabView(model: model)

        case .debug:
            SettingsDebugTabView(
                model: model,
                apiDebugStore: apiDebugStore
            )
        }
    }
}
