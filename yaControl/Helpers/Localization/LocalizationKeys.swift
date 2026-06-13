//
//  LocalizationKeys.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum L10n {
    enum Tabs {
        static let computing = "tabs.computing"
        static let functions = "tabs.functions"
        static let storage = "tabs.storage"
        static let settings = "tabs.settings"
        static let about = "tabs.about"
    }

    enum Common {
        static let loading = "common.loading"
        static let retry = "common.retry"
        static let cancel = "common.cancel"
        static let refresh = "common.refresh"
        static let close = "common.close"
        static let open = "common.open"
        static let copy = "common.copy"
        static let status = "common.status"
        static let name = "common.name"
        static let createdAt = "common.createdAt"
        static let updatedAt = "common.updatedAt"
        static let folder = "common.folder"
        static let error = "common.error"
        static let empty = "common.empty"
        static let underConstruction = "common.underConstruction"
    }

    enum Computing {
        static let totalVMs = "computing.totalVMs"
        static let runningVMs = "computing.runningVMs"
        static let refresh = "computing.refresh"
        static let refreshHelp = "computing.refresh.help"
        static let stopAll = "computing.stopAll"
        static let stopAllHelp = "computing.stopAll.help"
        static let stopAllConfirmTitle = "computing.stopAll.confirmTitle"
        static let stopAllConfirmMessage = "computing.stopAll.confirmMessage"
        static let searchPrompt = "computing.searchPrompt"
        static let loading = "computing.loading"
        static let errorTitle = "computing.error.title"
        static let emptyTitle = "computing.empty.title"
        static let emptyDescription = "computing.empty.description"

    }

    enum Storage {
        static let totalBuckets = "storage.totalBuckets"
        static let refresh = "storage.refresh"
        static let refreshHelp = "storage.refresh.help"
        static let searchPrompt = "storage.searchPrompt"
        static let loading = "storage.loading"
        static let errorTitle = "storage.error.title"
        static let emptyTitle = "storage.empty.title"
        static let emptyDescription = "storage.empty.description"
    }

    enum Serverless {
        static let totalFunctions = "serverless.totalFunctions"
        static let activeFunctions = "serverless.activeFunctions"
        static let refresh = "serverless.refresh"
        static let refreshHelp = "serverless.refresh.help"
        static let searchPrompt = "serverless.searchPrompt"
        static let loading = "serverless.loading"
        static let errorTitle = "serverless.error.title"
        static let emptyTitle = "serverless.empty.title"
        static let emptyDescription = "serverless.empty.description"
    }

    enum StatusPanel {
        static let lastUpdated = "status.lastUpdated"
        static let currentBalance = "status.currentBalance"
    }

    enum Settings {
        static let generalTab = "settings.tab.general"
        static let vmManagementTab = "settings.tab.vmManagement"
        static let billingManagementTab = "settings.tab.billingManagement"

        static let applicationPreferencesTitle = "settings.applicationPreferences.title"
        static let launchAtLoginHelp = "settings.launchAtLogin.help"
        static let appLoggingTitle = "settings.appLogging.title"
        static let appLoggingHelp = "settings.appLogging.help"
        static let enableNotifications = "settings.notifications.enable"
        static let notificationsHelp = "settings.notifications.help"

        static let languageTitle = "settings.language.title"
        static let languageHelp = "settings.language.help"
        static let languageSystem = "settings.language.system"
        static let languageEnglish = "settings.language.english"
        static let languageRussian = "settings.language.russian"
        static let languageKazakh = "settings.language.kazakh"

        static let oauthTitle = "settings.oauth.title"
        static let oauthPlaceholder = "settings.oauth.placeholder"
        static let oauthAccessibilityLabel = "settings.oauth.accessibilityLabel"
        static let oauthHelp = "settings.oauth.help"
        static let oauthVerify = "settings.oauth.verify"
        static let oauthVerifyDisabledHelp = "settings.oauth.verify.disabledHelp"
        static let oauthVerifyEnabledHelp = "settings.oauth.verify.enabledHelp"
        static let oauthRequired = "settings.oauth.required"
        static let oauthGetKey = "settings.oauth.getKey"
        static let oauthValid = "settings.oauth.valid"
        static let oauthInvalid = "settings.oauth.invalid"
        static let oauthEmptyError = "settings.oauth.emptyError"
        static let oauthInvalidWithCode = "settings.oauth.invalidWithCode"

        static let ycCliTitle = "settings.ycCli.title"
        static let ycCliInstalled = "settings.ycCli.installed"
        static let ycCliInstalledHelp = "settings.ycCli.installed.help"
        static let ycCliGet = "settings.ycCli.get"

        static let vmAutoStartStopTitle = "settings.vm.autoStartStop.title"
        static let vmEnablePowerManagement = "settings.vm.enablePowerManagement"
        static let vmEnablePowerManagementHelp = "settings.vm.enablePowerManagement.help"
        static let vmStartModeTitle = "settings.vm.startMode.title"
        static let vmShutdownModeTitle = "settings.vm.shutdownMode.title"
        static let vmUsernameTitle = "settings.vm.username.title"
        static let vmUsernamePlaceholder = "settings.vm.username.placeholder"
        static let vmUsernameHelp = "settings.vm.username.help"

        static let billingThresholdTitle = "settings.billing.threshold.title"
        static let billingThresholdPlaceholder = "settings.billing.threshold.placeholder"
        static let billingThresholdHelp = "settings.billing.threshold.help"
    }

    enum Table {
        static let vmAutoStart = "table.vm.autoStart"
        static let vmName = "table.vm.name"
        static let vmStatus = "table.vm.status"
        static let vmCreatedAt = "table.vm.createdAt"
        static let vmCores = "table.vm.cores"
        static let vmRam = "table.vm.ram"
        static let vmPublicIP = "table.vm.publicIP"
        static let vmFolder = "table.vm.folder"

        static let storageName = "table.storage.name"
        static let storageMaxSizeGB = "table.storage.maxSizeGB"
        static let storageUsedSizeGB = "table.storage.usedSizeGB"
        static let storageFiles = "table.storage.files"
        static let storageCreatedAt = "table.storage.createdAt"
        static let storageUpdatedAt = "table.storage.updatedAt"
        static let storageFolder = "table.storage.folder"

        static let serverlessName = "table.serverless.name"
        static let serverlessStatus = "table.serverless.status"
        static let serverlessCreatedAt = "table.serverless.createdAt"
        static let serverlessInvoke = "table.serverless.invoke"
        static let serverlessFolder = "table.serverless.folder"

        static let autoPowerManagement = "table.action.autoPowerManagement"
        static let copyNameAndID = "table.action.copyNameAndID"
        static let copyIPs = "table.action.copyIPs"
        static let goToSettingsSetUsername = "table.action.goToSettingsSetUsername"
        static let openSSH = "table.action.openSSH"
        static let openRDP = "table.action.openRDP"
        static let copyInvokeURL = "table.action.copyInvokeURL"
        static let copyYCCommand = "table.action.copyYCCommand"
        static let createVM = "table.action.createVM"
        static let createFunction = "table.action.createFunction"
        static let createBucket = "table.action.createBucket"
    }

    enum Notifications {
        static let vmStarted = "notification.vm.started"
        static let vmStopped = "notification.vm.stopped"
        static let vmError = "notification.vm.error"
        static let vmTimeout = "notification.vm.timeout"
        static let vmTimeoutID = "notification.vm.timeout.id"
        static let vmShutdownCompleted = "notification.vm.shutdownCompleted"
        static let vmShutdownFinishedWithErrors = "notification.vm.shutdownFinishedWithErrors"
        static let vmAutoStartFailed = "notification.vm.autoStartFailed"
    }

    enum About {
        static let title = "about.title"
        static let description = "about.description"
        static let license = "about.license"
        static let author = "about.author"
        static let contact = "about.contact"
        static let exit = "about.exit"
    }

    enum Info {
        static let title = "info.title"
        static let loading = "info.loading"
        static let errorTitle = "info.error.title"
        static let emptyTitle = "info.empty.title"
        static let emptyDescription = "info.empty.description"
        static let billingInformation = "info.billingInformation"
        static let currentBalance = "info.currentBalance"
        static let details = "info.details"
        static let viewBilling = "info.viewBilling"
        static let virtualMachines = "info.virtualMachines"
        static let totalVMs = "info.totalVMs"
        static let runningVMs = "info.runningVMs"
        static let stoppedVMs = "info.stoppedVMs"
        static let serverlessFunctions = "info.serverlessFunctions"
        static let totalFunctions = "info.totalFunctions"
        static let activeFunctions = "info.activeFunctions"
        static let inactiveFunctions = "info.inactiveFunctions"
        static let storageBuckets = "info.storageBuckets"
        static let totalBuckets = "info.totalBuckets"
        static let lastUpdated = "info.lastUpdated"
    }

    enum Errors {
        static let errorFormat = "errors.errorFormat"
        static let checkConnection = "errors.checkConnection"
        static let checkOAuth = "errors.checkOAuth"
        static let cloudPending = "errors.cloudPending"
    }

    enum VMAutomation {
        static let startAfterAppLaunched = "vmAutomation.start.afterAppLaunched"
        static let startAfterMacOSStarted = "vmAutomation.start.afterMacOSStarted"
        static let startAfterWakeup = "vmAutomation.start.afterWakeup"
        static let shutdownAfterAppExit = "vmAutomation.shutdown.afterAppExit"
        static let shutdownAfterMacOSShutdown = "vmAutomation.shutdown.afterMacOSShutdown"
        static let shutdownAfterMacOSSleep = "vmAutomation.shutdown.afterMacOSSleep"
    }
}
