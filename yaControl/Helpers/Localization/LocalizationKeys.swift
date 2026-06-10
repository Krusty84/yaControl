//
//  LocalizationKeys.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum L10n {
    enum Settings {
        static let generalTab = "settings.tab.general"
        static let vmManagementTab = "settings.tab.vmManagement"
        static let billingManagementTab = "settings.tab.billingManagement"

        static let applicationPreferencesTitle = "settings.applicationPreferences.title"
        static let launchAtLoginHelp = "settings.launchAtLogin.help"
        static let applicationLogging = "settings.applicationLogging"
        static let applicationLoggingHelp = "settings.applicationLogging.help"
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
        static let oauthVerifyEmptyHelp = "settings.oauth.verify.emptyHelp"
        static let oauthVerifyHelp = "settings.oauth.verify.help"
        static let oauthRequired = "settings.oauth.required"
        static let oauthValid = "settings.oauth.valid"
        static let oauthInvalid = "settings.oauth.invalid"
        static let oauthEmptyError = "settings.oauth.emptyError"
        static let oauthInvalidCode = "settings.oauth.invalidCode"
        static let oauthGetKey = "settings.oauth.getKey"

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
        static let vmUsernameHelp = "settings.vm.username.help"

        static let billingThresholdTitle = "settings.billing.threshold.title"
        static let billingThresholdPlaceholder = "settings.billing.threshold.placeholder"
        static let billingThresholdHelp = "settings.billing.threshold.help"
    }

    enum Tabs {
        static let computing = "tabs.computing"
        static let function = "tabs.function"
        static let storage = "tabs.storage"
        static let settings = "tabs.settings"
        static let about = "tabs.about"
    }

    enum Common {
        static let refresh = "common.refresh"
        static let retry = "common.retry"
        static let cancel = "common.cancel"
        static let loading = "common.loading"
        static let lastUpdated = "common.lastUpdated"
        static let currentBalance = "common.currentBalance"
        static let emptyDescription = "common.empty.description"
    }

    enum Computing {
        static let totalVMs = "computing.totalVMs"
        static let running = "computing.running"
        static let search = "computing.search"
        static let refresh = "computing.refresh"
        static let stopAll = "computing.stopAll"
        static let stopAllHelp = "computing.stopAll.help"
        static let stopAllConfirmTitle = "computing.stopAll.confirmTitle"
        static let stopAllConfirmMessage = "computing.stopAll.confirmMessage"
        static let emptyTitle = "computing.empty.title"
        static let emptyDescription = "computing.empty.description"
        static let errorTitle = "computing.error.title"
    }

    enum Storage {
        static let totalBuckets = "storage.totalBuckets"
        static let search = "storage.search"
        static let refresh = "storage.refresh"
        static let emptyTitle = "storage.empty.title"
        static let emptyDescription = "storage.empty.description"
        static let errorTitle = "storage.error.title"
    }

    enum Serverless {
        static let totalFunctions = "serverless.totalFunctions"
        static let active = "serverless.active"
        static let search = "serverless.search"
        static let refresh = "serverless.refresh"
        static let emptyTitle = "serverless.empty.title"
        static let emptyDescription = "serverless.empty.description"
        static let errorTitle = "serverless.error.title"
    }

    enum VMStart {
        static let afterAppLaunched = "vm.start.afterAppLaunched"
        static let afterMacOSStarted = "vm.start.afterMacOSStarted"
        static let afterWakeup = "vm.start.afterWakeup"
    }

    enum VMShutdown {
        static let afterAppExit = "vm.shutdown.afterAppExit"
        static let afterMacOSShutdown = "vm.shutdown.afterMacOSShutdown"
        static let afterMacOSSleep = "vm.shutdown.afterMacOSSleep"
    }

    enum Table {
        static let autoStart = "table.column.autoStart"
        static let name = "table.column.name"
        static let status = "table.column.status"
        static let createdAt = "table.column.createdAt"
        static let updatedAt = "table.column.updatedAt"
        static let cores = "table.column.cores"
        static let ram = "table.column.ram"
        static let publicIP = "table.column.publicIP"
        static let folder = "table.column.folder"
        static let maxSizeGb = "table.column.maxSizeGb"
        static let usedSizeGb = "table.column.usedSizeGb"
        static let files = "table.column.files"
        static let invoke = "table.column.invoke"

        static let autoPowerManagement = "table.action.autoPowerManagement"
        static let copyNameAndID = "table.action.copyNameAndID"
        static let copyIPs = "table.action.copyIPs"
        static let goToSettingsSetUsername = "table.action.goToSettingsSetUsername"
        static let openSSH = "table.action.openSSH"
        static let openRDP = "table.action.openRDP"
        static let copyInvokeURL = "table.action.copyInvokeURL"
        static let callViaYandexCloudCLI = "table.action.callViaYandexCloudCLI"
    }

    enum Notifications {
        static let vmStarted = "notification.vm.started"
        static let vmStopped = "notification.vm.stopped"
        static let vmError = "notification.vm.error"
        static let vmTimeoutName = "notification.vm.timeout.name"
        static let vmTimeoutID = "notification.vm.timeout.id"
    }
}
