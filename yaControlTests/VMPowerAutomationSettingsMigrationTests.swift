//
//  VMPowerAutomationSettingsMigrationTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 28/06/2026.
//

import XCTest
@testable import yaControl

final class VMPowerAutomationSettingsMigrationTests: XCTestCase {
    private let startOptionsKey = "com.krusty84.yaControl.settings.startOptions"
    private let shutdownOptionsKey = "com.krusty84.yaControl.settings.shutdownOptions"

    func testStartMigrationRemovesAfterMacOSStartedAndPreservesSupportedOptions() throws {
        let harness = try makeHarness()
        try harness.store(["after_macos_started", "after_app_launched", "after_wakeup"], forKey: startOptionsKey)

        XCTAssertEqual(harness.settings.startOptions, [.afterAppLaunched, .afterWakeup])
        XCTAssertEqual(try harness.rawValues(forKey: startOptionsKey), ["after_app_launched", "after_wakeup"])
    }

    func testOldSleepAndShutdownValuesAreMigrated() throws {
        let harness = try makeHarness()
        try harness.store(["after_macos_sleep", "after_macos_shutdown"], forKey: shutdownOptionsKey)

        XCTAssertEqual(harness.settings.shutdownOptions, [.beforeMacOSSleep, .beforeMacOSShutdown])
        XCTAssertEqual(try harness.rawValues(forKey: shutdownOptionsKey), ["before_macos_sleep", "before_macos_shutdown"])
    }

    func testDuplicateOptionsAreRemoved() throws {
        let harness = try makeHarness()
        try harness.store(
            ["after_app_exit", "after_app_exit", "after_macos_sleep", "before_macos_sleep"],
            forKey: shutdownOptionsKey
        )

        XCTAssertEqual(harness.settings.shutdownOptions, [.afterAppExit, .beforeMacOSSleep])
        XCTAssertEqual(try harness.rawValues(forKey: shutdownOptionsKey), ["after_app_exit", "before_macos_sleep"])
    }

    func testMissingShutdownSettingsDefaultToEmptyArray() throws {
        let harness = try makeHarness()

        XCTAssertEqual(harness.settings.shutdownOptions, [])
    }

    func testMigrationIsIdempotent() throws {
        let harness = try makeHarness()
        try harness.store(["after_macos_shutdown", "after_macos_shutdown"], forKey: shutdownOptionsKey)

        XCTAssertEqual(harness.settings.shutdownOptions, [.beforeMacOSShutdown])
        XCTAssertEqual(harness.settings.shutdownOptions, [.beforeMacOSShutdown])
        XCTAssertEqual(try harness.rawValues(forKey: shutdownOptionsKey), ["before_macos_shutdown"])
    }

    private func makeHarness() throws -> SettingsMigrationHarness {
        let suiteName = "yaControlTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsMigrationHarness(
            suiteName: suiteName,
            defaults: defaults,
            settings: SettingsManager(defaults: defaults)
        )
    }
}

private struct SettingsMigrationHarness {
    let suiteName: String
    let defaults: UserDefaults
    let settings: SettingsManager

    func store(_ values: [String], forKey key: String) throws {
        let data = try JSONEncoder().encode(values)
        defaults.set(data, forKey: key)
    }

    func rawValues(forKey key: String) throws -> [String] {
        let data = try XCTUnwrap(defaults.data(forKey: key))
        return try JSONDecoder().decode([String].self, from: data)
    }
}
