//
//  SettingsViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsModel {
    var oAuthKey = ""
    var responseCode: Int?
    var errorMessage: String?

    var appLogging = false {
        didSet {
            settingsManager.appLoggingEnabled = appLogging
        }
    }

    var ycCLIInstalled = false {
        didSet {
            settingsManager.ycCLIInstalled = ycCLIInstalled
        }
    }

    var autoStartVM = false {
        didSet {
            settingsManager.autoStartEnabled = autoStartVM
        }
    }

    var startOptions: [StartOption] = [] {
        didSet {
            settingsManager.startOptions = startOptions
        }
    }

    var shutdownOptions: [ShutdownOption] = [] {
        didSet {
            settingsManager.shutdownOptions = shutdownOptions
        }
    }

    var generalUsername4VMs = "" {
        didSet {
            settingsManager.generalUsername4VMs = generalUsername4VMs
        }
    }

    var billingThreshold = 0.0 {
        didSet {
            settingsManager.billingThreshold = billingThreshold
        }
    }

    var appLanguage: AppLanguage = .system {
        didSet {
            settingsManager.appLanguage = appLanguage
        }
    }

    @ObservationIgnored
    private let settingsManager: SettingsManager

    @ObservationIgnored
    private let api: YandexAPIService

    @ObservationIgnored
    private let tokenStore: KeychainTokenStore

    init(
        settingsManager: SettingsManager = .shared,
        api: YandexAPIService = .shared,
        tokenStore: KeychainTokenStore = .shared
    ) {
        self.settingsManager = settingsManager
        self.api = api
        self.tokenStore = tokenStore
        loadSettings()
    }

    var trimmedOAuthKey: String {
        oAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isOAuthTokenEmpty: Bool {
        trimmedOAuthKey.isEmpty
    }

    func loadSettings() {
        oAuthKey = settingsManager.oAuthKey
        generalUsername4VMs = settingsManager.generalUsername4VMs
        autoStartVM = settingsManager.autoStartEnabled
        appLogging = settingsManager.appLoggingEnabled
        ycCLIInstalled = settingsManager.ycCLIInstalled
        startOptions = settingsManager.startOptions
        shutdownOptions = settingsManager.shutdownOptions
        billingThreshold = settingsManager.billingThreshold
        appLanguage = settingsManager.appLanguage
    }

    func setStartOption(_ option: StartOption, isOn: Bool) {
        if isOn {
            guard !startOptions.contains(option) else { return }
            startOptions.append(option)
        } else {
            startOptions.removeAll { $0 == option }
        }
    }

    func setShutdownOption(_ option: ShutdownOption, isOn: Bool) {
        if isOn {
            guard !shutdownOptions.contains(option) else { return }
            shutdownOptions.append(option)
        } else {
            shutdownOptions.removeAll { $0 == option }
        }
    }

    func checkOAuthKey(locale: Locale) async {
        let token = trimmedOAuthKey

        guard !token.isEmpty else {
            responseCode = nil
            errorMessage = LocalizedStringHelper.string(L10n.Settings.oauthEmptyError, locale: locale)
            return
        }

        do {
            let response = try await api.checkOauthKey(yandexPassportOauthToken: token)

            if response.code == 200 {
                try tokenStore.saveOAuthToken(token)
            }

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
        } catch {
            responseCode = nil
            errorMessage = error.localizedDescription
            LoggerHelper.error("OAuth verification failed: \(error.localizedDescription)")
        }
    }
}
