//
//  Settings.swift - Application Settings
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import LaunchAtLogin

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

    private enum SettingsLayout {
        static let tabHorizontalPadding: CGFloat = 16
        static let tabTopPadding: CGFloat = 12

        static let outerPadding: CGFloat = 12
        static let vmOuterPadding: CGFloat = 10
        static let innerHorizontalPadding: CGFloat = 8

        static let sectionSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 6
        static let compactRowSpacing: CGFloat = 4

        static let horizontalRowSpacing: CGFloat = 12
        static let columnSpacing: CGFloat = 20
        static let columnRowSpacing: CGFloat = 8

        static let headerBottomPadding: CGFloat = 4
        static let dividerVerticalPadding: CGFloat = 0

        static let verifyButtonMinWidth: CGFloat = 60
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
            generalSettingsTab

        case .cloud:
            cloudSettingsTab

        case .virtualMachineManagement:
            vmManagementTab

        case .billingManagement:
            billingManagementTab
                
        case .debug:
            debugTab
        }
    }

    // MARK: - General Tab

    private var generalSettingsTab: some View {
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
    
    // MARK: - Cloud Tab

    private var cloudSettingsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                yandexAuthenticationSection

                Divider()

                defaultFolderForCreationSection
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

                Toggle(LocalizedStringKey(L10n.Settings.appLoggingTitle), isOn: $model.appLogging)
                    .toggleStyle(.switch)
                    .help(localized(L10n.Settings.appLoggingHelp))

                NotificationToggleView()
                    .help(localized(L10n.Settings.notificationsHelp))

                Spacer()
            }
            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
        } header: {
            SectionHeader(
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
            SectionHeader(
                title: LocalizedStringKey(L10n.Settings.languageTitle),
                systemImage: "globe"
            )
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
                HStack(spacing: SettingsLayout.horizontalRowSpacing) {
                    Picker(
                        LocalizedStringKey(L10n.Settings.defaultFolderPlaceholder),
                        selection: $model.defaultFolderIdForCreation
                    ) {
                        Text(LocalizedStringKey(L10n.Settings.defaultFolderPlaceholder))
                            .tag("")

                        ForEach(model.folderOptions) { folder in
                            Text(folder.displayName)
                                .tag(folder.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 420, alignment: .leading)
                    .disabled(model.isLoadingFolders || model.folderOptions.isEmpty)
                    .help(localized(L10n.Settings.defaultFolderHelp))

                    Button {
                        Task {
                            await model.loadFoldersForCreation(locale: locale)
                        }
                    } label: {
                        if model.isLoadingFolders {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label(
                                LocalizedStringKey(L10n.Settings.defaultFolderReload),
                                systemImage: "arrow.clockwise"
                            )
                            .labelStyle(.iconOnly)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isOAuthTokenEmpty || model.isLoadingFolders)
                    .help(localized(L10n.Settings.defaultFolderReload))

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
            SectionHeader(
                title: LocalizedStringKey(L10n.Settings.defaultFolderTitle),
                systemImage: "folder.fill"
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

    // MARK: - VM Management Tab

    private var vmManagementTab: some View {
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
            SectionHeader(
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
            SectionHeader(
                title: LocalizedStringKey(L10n.Settings.vmUsernameTitle),
                systemImage: "person.fill"
            )
        }
    }

    // MARK: - Billing Tab

    private var billingManagementTab: some View {
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
                    SectionHeader(
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
    
    // MARK: - Debug Tab

    private var debugTab: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
            Section {
                Toggle(LocalizedStringKey(L10n.Settings.apiDebugEnabled), isOn: $model.apiDebugEnabled)
                    .toggleStyle(.switch)
                    .help(localized(L10n.Settings.apiDebugEnabledHelp))
                    .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
            } header: {
                SectionHeader(
                    title: LocalizedStringKey(L10n.Settings.debugTitle),
                    systemImage: "ladybug.fill"
                )
            }

            Divider()

            Section {
                VStack(alignment: .leading, spacing: SettingsLayout.rowSpacing) {
                    TextEditor(text: $apiDebugStore.messages)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 280)
                        .border(.separator)

                    HStack {
                        Button(LocalizedStringKey(L10n.Settings.debugSaveToFile)) {
                            apiDebugStore.saveToExternalFile()
                        }
                        .disabled(apiDebugStore.messages.isEmpty)

                        Button(LocalizedStringKey(L10n.Settings.debugClear)) {
                            apiDebugStore.clear()
                        }
                        .disabled(apiDebugStore.messages.isEmpty)

                        Spacer()
                    }
                }
                .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
            } header: {
                SectionHeader(
                    title: LocalizedStringKey(L10n.Settings.debugMessagesTitle),
                    systemImage: "doc.text.magnifyingglass"
                )
            }

            Spacer()
        }
        .padding(SettingsLayout.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - OAuth Status Indicator

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

    // MARK: - Helpers

    private struct SectionHeader: View {
        let title: LocalizedStringKey
        let systemImage: String

        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())

                Spacer()
            }
            .padding(.bottom, SettingsLayout.headerBottomPadding)
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
