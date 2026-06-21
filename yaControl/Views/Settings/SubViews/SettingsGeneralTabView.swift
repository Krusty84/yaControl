//
//  SettingsGeneralTabView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import LaunchAtLogin

struct SettingsGeneralTabView: View {
    @Environment(\.locale) private var locale
    @Bindable var model: SettingsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                applicationPreferencesSection

                Divider()

                interfaceLanguageSection

                Divider()

                yandexCLiSection
            }
            .padding(SettingsLayout.outerPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var applicationPreferencesSection: some View {
        Section {
            HStack(spacing: SettingsLayout.horizontalRowSpacing) {
                LaunchAtLogin.Toggle()
                    .toggleStyle(.switch)
                    .help(localized(L10n.Settings.launchAtLoginHelp))
                
// TODO: Maybe for future release, I am not sure about real reasons...
//                Toggle(LocalizedStringKey(L10n.Settings.appLoggingTitle), isOn: $model.appLogging)
//                    .toggleStyle(.switch)
//                    .help(localized(L10n.Settings.appLoggingHelp))

                NotificationToggleView()
                    .help(localized(L10n.Settings.notificationsHelp))

                Spacer()
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: LocalizedStringKey(L10n.Settings.applicationPreferencesTitle),
                systemImage: "gearshape.fill"
            )
        }
    }

    private var interfaceLanguageSection: some View {
        Section {
            Picker(
                LocalizedStringKey(L10n.Settings.languageTitle),
                selection: $model.appLanguage
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName(locale: locale))
                        .tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 260, alignment: .leading)
            .help(localized(L10n.Settings.languageHelp))
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: LocalizedStringKey(L10n.Settings.languageTitle),
                systemImage: "globe"
            )
        }
    }

    private var yandexCLiSection: some View {
        Section {
            VStack(alignment: .leading, spacing: SettingsLayout.compactRowSpacing) {
                Toggle(LocalizedStringKey(L10n.Settings.ycCliInstalled), isOn: $model.ycCLIInstalled)
                    .toggleStyle(.switch)
                    .help(localized(L10n.Settings.ycCliInstalledHelp))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            HStack {
                Label(LocalizedStringKey(L10n.Settings.ycCliTitle), systemImage: "terminal.fill")
                    .font(.subheadline.bold())

                Spacer()

                if let url = URL(string: APIConfig.yaGetYCCLI) {
                    Link(LocalizedStringKey(L10n.Settings.ycCliGet), destination: url)
                        .font(.caption)
                }
            }
            .padding(.bottom, SettingsLayout.headerBottomPadding)
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
