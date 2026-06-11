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

    @AppStorage("com.krusty84.yaControl.settings.generalUsername4VMs")
    private var generalUsername4VMs: String = SettingsManager.shared.generalUsername4VMs

    @AppStorage("com.krusty84.yaControl.settings.billingThreshold")
    private var billingThreshold: Double = SettingsManager.shared.billingThreshold

    @AppStorage("com.krusty84.yaControl.settings.appLanguage")
    private var appLanguageRawValue: String = AppLanguage.system.rawValue

    @State private var oAuthKey = ""
    @State private var appLogging = false
    @State private var ycCLIInstalled = false

    @State private var responseCode: Int?
    @State private var errorMessage: String?
    @State private var selectedTab: SettingsTab = .general

    @State private var autoStartVM = false
    @State private var startOptions: [StartOption] = []
    @State private var shutdownOptions: [ShutdownOption] = []

    private enum SettingsTab: Hashable {
        case general
        case virtualMachineManagement
        case billingManagement
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

    private var trimmedOAuthKey: String {
        oAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isOAuthTokenEmpty: Bool {
        trimmedOAuthKey.isEmpty
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    private var selectedAppLanguageBinding: Binding<AppLanguage> {
        Binding(
            get: {
                appLanguage
            },
            set: { newValue in
                appLanguageRawValue = newValue.rawValue
                SettingsManager.shared.appLanguage = newValue
            }
        )
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
        .onAppear(perform: loadSettings)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            settingsTabButton(
                LocalizedStringKey(L10n.Settings.generalTab),
                tab: .general
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.vmManagementTab),
                tab: .virtualMachineManagement
            )

            settingsTabButton(
                LocalizedStringKey(L10n.Settings.billingManagementTab),
                tab: .billingManagement
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

        case .virtualMachineManagement:
            vmManagementTab

        case .billingManagement:
            billingManagementTab
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

                yandexAuthenticationSection

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

                Toggle(LocalizedStringKey(L10n.Settings.appLoggingTitle), isOn: $appLogging)
                    .toggleStyle(.switch)
                    .onChange(of: appLogging) { _, newValue in
                        SettingsManager.shared.appLoggingEnabled = newValue
                    }
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
                selection: selectedAppLanguageBinding
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
                    TextField(LocalizedStringKey(L10n.Settings.oauthPlaceholder), text: $oAuthKey)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(Text(LocalizedStringKey(L10n.Settings.oauthAccessibilityLabel)))
                        .help(localized(L10n.Settings.oauthHelp))

                    oAuthStatusIndicator

                    Button(LocalizedStringKey(L10n.Settings.oauthVerify), action: checkOAuthKey)
                        .frame(minWidth: SettingsLayout.verifyButtonMinWidth)
                        .disabled(isOAuthTokenEmpty)
                        .help(
                            isOAuthTokenEmpty
                            ? localized(L10n.Settings.oauthVerifyDisabledHelp)
                            : localized(L10n.Settings.oauthVerifyEnabledHelp)
                        )
                }

                if isOAuthTokenEmpty {
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

    private var yandexCLiSection: some View {
        Section {
            VStack(alignment: .leading, spacing: SettingsLayout.compactRowSpacing) {
                Toggle(LocalizedStringKey(L10n.Settings.ycCliInstalled), isOn: $ycCLIInstalled)
                    .toggleStyle(.switch)
                    .onChange(of: ycCLIInstalled) { _, newValue in
                        SettingsManager.shared.ycCLIInstalled = newValue
                    }
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
            Toggle(LocalizedStringKey(L10n.Settings.vmEnablePowerManagement), isOn: $autoStartVM)
                .toggleStyle(.switch)
                .onChange(of: autoStartVM) { _, newValue in
                    SettingsManager.shared.autoStartEnabled = newValue
                }
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
                            isOn: Binding(
                                get: { startOptions.contains(option) },
                                set: { isOn in
                                    withAnimation {
                                        if isOn {
                                            startOptions.append(option)
                                        } else {
                                            startOptions.removeAll { $0 == option }
                                        }

                                        SettingsManager.shared.startOptions = startOptions
                                    }
                                }
                            )
                        )
                        .toggleStyle(.checkbox)
                        .disabled(!autoStartVM || option == .afterMacOSStarted)
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
                            isOn: Binding(
                                get: { shutdownOptions.contains(option) },
                                set: { isOn in
                                    withAnimation {
                                        if isOn {
                                            shutdownOptions.append(option)
                                        } else {
                                            shutdownOptions.removeAll { $0 == option }
                                        }

                                        SettingsManager.shared.shutdownOptions = shutdownOptions
                                    }
                                }
                            )
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
            TextField(LocalizedStringKey(L10n.Settings.vmUsernameTitle), text: $generalUsername4VMs)
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
                            value: $billingThreshold,
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

    // MARK: - OAuth Status Indicator

    private var oAuthStatusIndicator: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.compactRowSpacing) {
            if let code = responseCode {
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

            if let errorMessage {
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

    private func loadSettings() {
        oAuthKey = SettingsManager.shared.oAuthKey
        generalUsername4VMs = SettingsManager.shared.generalUsername4VMs
        autoStartVM = SettingsManager.shared.autoStartEnabled
        appLogging = SettingsManager.shared.appLoggingEnabled
        ycCLIInstalled = SettingsManager.shared.ycCLIInstalled
        startOptions = SettingsManager.shared.startOptions
        shutdownOptions = SettingsManager.shared.shutdownOptions
        billingThreshold = SettingsManager.shared.billingThreshold
    }

    private func checkOAuthKey() {
        let token = trimmedOAuthKey

        guard !token.isEmpty else {
            responseCode = nil
            errorMessage = localized(L10n.Settings.oauthEmptyError)
            return
        }

        Task {
            do {
                let response = try await YandexAPIService.shared
                    .checkOauthKey(yandexPassportOauthToken: token)

                if response.code == 200 {
                    try KeychainTokenStore.shared.saveOAuthToken(token)
                }

                await MainActor.run {
                    responseCode = response.code

                    if response.code == 200 {
                        oAuthKey = token
                        errorMessage = nil
                    } else {
                        errorMessage = LocalizedStringHelper.formatted(
                            L10n.Settings.oauthInvalidWithCode,
                            locale: locale,
                            Int64(response.code)
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    responseCode = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

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
}
