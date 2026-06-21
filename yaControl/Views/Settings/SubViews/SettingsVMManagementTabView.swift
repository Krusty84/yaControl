//
//  SettingsVMManagementTabView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsVMManagementTabView: View {
    @Environment(\.locale) private var locale
    @Bindable var model: SettingsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                autoStartModeSection

                Divider()

                vmAutomationOptionsSection

                Divider()

                generalVMUsernameSection
            }
            .padding(SettingsLayout.vmOuterPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var autoStartModeSection: some View {
        Section {
            Toggle(LocalizedStringKey(L10n.Settings.vmEnablePowerManagement), isOn: $model.autoStartVM)
                .toggleStyle(.switch)
                .help(localized(L10n.Settings.vmEnablePowerManagementHelp))
                .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: LocalizedStringKey(L10n.Settings.vmAutoStartStopTitle),
                systemImage: "power"
            )
        }
    }

    private var vmAutomationOptionsSection: some View {
        HStack(alignment: .top, spacing: SettingsLayout.columnSpacing) {
            VStack(alignment: .leading, spacing: SettingsLayout.columnRowSpacing) {
                Section {
                    Text(LocalizedStringKey(L10n.Settings.vmStartModeTitle))
                        .font(.subheadline)
                        .padding(.bottom, SettingsLayout.compactRowSpacing)

                    ForEach(StartOption.allCases, id: \.self) { option in
                        Toggle(
                            option.localizedTitle(locale: locale),
                            isOn: startOptionBinding(for: option)
                        )
                        .toggleStyle(.checkbox)
                        .disabled(!model.autoStartVM || option == .afterMacOSStarted)
                    }
                }
                .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: SettingsLayout.columnRowSpacing) {
                Section {
                    Text(LocalizedStringKey(L10n.Settings.vmShutdownModeTitle))
                        .font(.subheadline)
                        .padding(.bottom, SettingsLayout.compactRowSpacing)

                    ForEach(ShutdownOption.allCases, id: \.self) { option in
                        Toggle(
                            option.localizedTitle(locale: locale),
                            isOn: shutdownOptionBinding(for: option)
                        )
                        .toggleStyle(.checkbox)
                        .disabled(option == .afterMacOSShutdown)
                    }
                }
                .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
    }

    private var generalVMUsernameSection: some View {
        Section {
            TextField(LocalizedStringKey(L10n.Settings.vmUsernameTitle), text: $model.generalUsername4VMs)
                .textFieldStyle(.roundedBorder)
                .help(localized(L10n.Settings.vmUsernameHelp))
                .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: LocalizedStringKey(L10n.Settings.vmUsernameTitle),
                systemImage: "person.fill"
            )
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }

    private func startOptionBinding(for option: StartOption) -> Binding<Bool> {
        Binding(
            get: { model.startOptions.contains(option) },
            set: { isOn in
                withAnimation {
                    model.setStartOption(option, isOn: isOn)
                }
            }
        )
    }

    private func shutdownOptionBinding(for option: ShutdownOption) -> Binding<Bool> {
        Binding(
            get: { model.shutdownOptions.contains(option) },
            set: { isOn in
                withAnimation {
                    model.setShutdownOption(option, isOn: isOn)
                }
            }
        )
    }
}
