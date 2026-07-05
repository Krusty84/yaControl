//
//  SettingsCloudTabView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsCloudTabView: View {
    @Environment(\.locale) private var locale
    @Bindable var model: SettingsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                yandexAuthenticationSection

                Divider()

                defaultFolderForCreationSection

                Divider()

                widgetSettingsSection
            }
            .padding(SettingsLayout.outerPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var yandexAuthenticationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: SettingsLayout.rowSpacing) {
                HStack(spacing: SettingsLayout.horizontalRowSpacing) {
                    TextField(LocalizedStringKey(L10n.Settings.oauthPlaceholder), text: $model.oAuthKey)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(Text(LocalizedStringKey(L10n.Settings.oauthAccessibilityLabel)))
                        .help(localized(L10n.Settings.oauthHelp))

                    oAuthStatusIndicator

                    Button(LocalizedStringKey(L10n.Settings.oauthVerify)) {
                        Task {
                            await model.checkOAuthKey(locale: locale)
                        }
                    }
                    .frame(minWidth: SettingsLayout.verifyButtonMinWidth)
                    .disabled(model.isOAuthTokenEmpty)
                    .help(
                        model.isOAuthTokenEmpty
                        ? localized(L10n.Settings.oauthVerifyDisabledHelp)
                        : localized(L10n.Settings.oauthVerifyEnabledHelp)
                    )
                }

                if model.isOAuthTokenEmpty {
                    Text(LocalizedStringKey(L10n.Settings.oauthRequired))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            HStack {
                Label(LocalizedStringKey(L10n.Settings.oauthTitle), systemImage: "key.fill")
                    .font(.subheadline.bold())

                Spacer()

                if let url = URL(string: APIConfig.yaGetOAuthKey) {
                    Link(LocalizedStringKey(L10n.Settings.oauthGetKey), destination: url)
                        .font(.caption)
                }
            }
            .padding(.bottom, SettingsLayout.headerBottomPadding)
        }
    }

    private var defaultFolderForCreationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: SettingsLayout.compactRowSpacing) {
                HStack(spacing: SettingsLayout.compactRowSpacing) {
                    Picker(
                        LocalizedStringKey(L10n.Settings.defaultFolderPlaceholder),
                        selection: $model.defaultFolderIdForCreation
                    ) {
                        ForEach(model.folderOptions) { folder in
                            Text(folder.displayName)
                                .tag(folder.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 420, alignment: .leading)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            loadFoldersForCreationIfAvailable()
                        }
                    )
                    .disabled(model.isOAuthTokenEmpty || model.isLoadingFolders)
                    .help(localized(L10n.Settings.defaultFolderHelp))

                    Spacer()
                }

                if model.folderOptions.isEmpty && !model.isLoadingFolders {
                    Text(LocalizedStringKey(L10n.Settings.defaultFolderEmpty))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let folderLoadErrorMessage = model.folderLoadErrorMessage {
                    Text(folderLoadErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: LocalizedStringKey(L10n.Settings.defaultFolderTitle),
                systemImage: "folder.fill"
            )
        }
    }

    private var widgetSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: SettingsLayout.rowSpacing) {
                Toggle(
                    LocalizedStringKey(L10n.Settings.widgetAutoRefreshEnabled),
                    isOn: $model.widgetAutoRefreshEnabled
                )
                .toggleStyle(.switch)
                .help(localized(L10n.Settings.widgetAutoRefreshEnabledHelp))

                Picker(
                    LocalizedStringKey(L10n.Settings.widgetRefreshInterval),
                    selection: $model.widgetRefreshIntervalMinutes
                ) {
                    ForEach(WidgetRefreshInterval.allCases) { interval in
                        Text(interval.localizedTitle(locale: locale))
                            .tag(interval.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!model.widgetAutoRefreshEnabled)
                .help(localized(L10n.Settings.widgetRefreshIntervalHelp))

                Button(LocalizedStringKey(L10n.Settings.widgetRefreshNow)) {
                    Task {
                        await CloudSummarySnapshotUpdater.shared.refreshSnapshot()
                    }
                }
                .help(localized(L10n.Settings.widgetRefreshNowHelp))
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SettingsSectionHeader(
                title: "Widget",
                systemImage: "square.grid.2x2"
            )
        }
    }

    private var oAuthStatusIndicator: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.compactRowSpacing) {
            if let code = model.responseCode {
                HStack(spacing: SettingsLayout.compactRowSpacing) {
                    Image(systemName: code == 200 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(code == 200 ? .green : .red)

                    Text(
                        LocalizedStringKey(
                            code == 200
                            ? L10n.Settings.oauthValid
                            : L10n.Settings.oauthInvalid
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(code == 200 ? .green : .red)
                }
            }

            if let errorMessage = model.errorMessage {
                HStack(spacing: SettingsLayout.compactRowSpacing) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func loadFoldersForCreationIfAvailable() {
        guard !model.isOAuthTokenEmpty, !model.isLoadingFolders else {
            return
        }

        Task {
            await model.loadFoldersForCreation(locale: locale)
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
