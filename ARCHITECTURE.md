# Architecture

## Overview

yaControl is a macOS SwiftUI menu bar utility for viewing and controlling selected Yandex Cloud resources. The main runtime surface is a `MenuBarExtra` window, not a normal dock application window. The app authenticates with a user-provided Yandex OAuth token, exchanges it for an IAM token, then loads virtual machines, serverless functions, object storage buckets, and billing summaries from Yandex Cloud APIs.

The most important runtime behavior is VM power management. Users can start or stop VMs manually from the Computing tab, and the app can also start or stop selected VMs automatically on app launch, app exit, macOS sleep, and macOS wake events.

The app is currently organized as one Xcode app target named `yaControl`. A `yaControlLoginItemHelper` source folder exists in the repository, but the checked-in Xcode project currently exposes one native target and one shared scheme for the main app.

## Repository Structure

```text
.
+-- yaControl.xcodeproj/
|   `-- xcshareddata/xcschemes/yaControl.xcscheme
+-- yaControl/
|   +-- API/
|   |   +-- DTO/
|   |   +-- YandexAPIClient.swift
|   |   +-- YandexAPIService.swift
|   |   `-- Yandex*API.swift
|   +-- DataStorage/
|   |   `-- SecureStorage/
|   +-- Helpers/
|   +-- Models/
|   +-- Resources/
|   |   `-- Localizable.xcstrings
|   +-- Services/
|   +-- VMPowerMgt/
|   +-- Views/
|   +-- MainWindow.swift
|   +-- SettingsManager.swift
|   +-- StateIndicator.swift
|   `-- yaControlApp.swift
`-- yaControlLoginItemHelper/
```

The top-level `yaControl/` folder contains the app target source. The repository does not currently have separate test targets.

## Main Runtime Components

### App Entry and Menu Bar UI

`yaControlApp` is the `@main` entry point. It installs `AppDelegate` through `@NSApplicationDelegateAdaptor`, initializes `AppLifecycleObserver`, starts launch-time VM automation, and renders a `MenuBarExtra` with `.menuBarExtraStyle(.window)`.

The menu bar content switches between:

- `MainWindow`, the normal tabbed application surface.
- `InfoWindow`, a compact summary view shown when the Option key is held while opening the menu.

`StateIndicator.swift` renders the menu bar icon. Its color is driven by `AppState.shared`, including a blinking orange state while VM power operations are active.

### Main Window and Views

`MainWindow` uses `ElegantTabsView` to host these tabs:

- Computing: `CloudComputingTabContent`
- Serverless Functions: `ServerLessFunctionTabContent`
- Storage: `BucketTabContent`
- Settings: `SettingsTabContent`
- About: `AboutTabContent`

The resource tabs are SwiftUI table-based views. They own main-actor `@Observable` models in `@State`, load data with `.task`, support search and refresh, and show `ContentUnavailableView` for error and empty states. Each resource tab ends with `StatusPanel`, which displays the last update time and billing balance.

### UI State Models

The main resource screens use feature-specific models:

- `CloudComputingModel`
- `CloudStorageModel`
- `ServerlessFunctionModel`
- `InfoWindowModel`

These models authenticate through `YandexAPIService`, keep local loading/error/search state, and transform service results into UI-ready table rows.

There is also shared singleton state:

- `AppState` tracks whether any VM is running and whether VM power operations are active.
- `SettingsManager` reads and writes persisted user preferences.
- `NotificationManager` wraps local user notifications.

This means the codebase has a mixed state model: newer feature screens use Observation, while app-wide state and some services still use `ObservableObject`, `@Published`, and singletons.

### API Layer

The API boundary is in `yaControl/API/`.

- `YandexAPIClient` is the common HTTP client. It builds `URLRequest`s, attaches bearer tokens, uses `URLSession.shared.data(for:)`, validates HTTP responses, and sanitizes Yandex API error messages.
- `YandexAuthAPI` exchanges a Yandex OAuth token for an IAM token.
- `YandexResourceManagerAPI` loads clouds and folders.
- `YandexComputeAPI` loads VM instances and sends VM start/stop commands.
- `YandexServerlessAPI` loads serverless functions.
- `YandexStorageAPI` loads buckets and bucket details.
- `YandexBillingAPI` loads billing accounts.
- DTO files under `API/DTO/` model raw Yandex API responses.

`YandexAPIService` is a compatibility facade used by view models and shared app state. It composes the endpoint-specific API classes with higher-level services and exposes operations such as `getVMs`, `getBuckets`, `getServerLessFunctions`, `getCosts`, `startVM`, and `stopVM`.

### Services

`yaControl/Services/` contains higher-level workflows above the endpoint APIs.

- `YandexInventoryService` loads clouds, folders, and per-folder resources, then maps raw DTOs into `VMTableData`, `BucketTableData`, and `ServerLessFunctionTableData`.
- `BillingSummaryService` maps billing accounts into `BillingTableData`.
- `VMPowerService` sends VM start/stop operations, including batch operations with task groups.
- `VMPollingService` polls inventory until VM status transitions, times out, or fails.
- `VMPowerOperationRegistry` is an actor that prevents concurrent power operations for the same VM and updates `AppState` activity indicators.
- `VMPowerAutomationService` coordinates automatic VM start/stop behavior for app and macOS lifecycle events.

Inventory loading uses Swift task groups to fetch folders and folder resources concurrently.

### Lifecycle and Automation

`VMPowerMgt/AppLifeCycleHelper.swift` contains the AppKit lifecycle bridge:

- `AppDelegate.applicationShouldTerminate(_:)` delays app termination while shutdown automation runs.
- `AppLifecycleObserver` listens for launch, sleep, and wake notifications from `NotificationCenter` and `NSWorkspace`.

Lifecycle events call `VMPowerAutomationService`:

- App launch -> start selected VMs when the configured start option allows it.
- App exit -> stop running VMs when the configured shutdown option allows it.
- macOS sleep -> stop running VMs when sleep shutdown is enabled.
- macOS wake -> start selected VMs when wake start is enabled.

Before auto-starting VMs, the service waits for network connectivity through `InternetConnectionMonitor`. For app exit and sleep, stop commands are sent without waiting for polling to finish, because the process or system may be terminating.

### Persistence and Local System Integration

`SettingsManager` persists non-sensitive settings in `UserDefaults`, including:

- app language
- logging enabled
- billing threshold
- Yandex CLI installed flag
- VM auto-start enabled flag
- start and shutdown automation options
- selected VM IDs for auto-start
- default VM username

The OAuth token is stored in Keychain through `KeychainTokenStore`. `SettingsManager` migrates the legacy OAuth token from `UserDefaults` into Keychain when initialized.

System helpers include:

- `TerminalLauncher`, which opens Terminal.
- `RDPFileLauncher`, which writes a temporary `.rdp` file and opens it with the default handler.
- `InternetConnectionMonitor`, which uses `NWPathMonitor`.
- `LoggerHelper`, which writes OSLog entries only when app logging is enabled.

## Data Flow

### Resource Loading

1. A tab model starts loading from `.task` or a refresh action.
2. The model reads the OAuth token from `SettingsManager`.
3. `YandexAPIService.checkOauthKey` calls `YandexAuthAPI` to obtain an IAM token.
4. The model calls the relevant `YandexAPIService` methods.
5. Inventory services load clouds and folders, then load per-folder resources.
6. DTOs are mapped into table data models.
7. The model updates main-actor UI state and the view re-renders.

Most resource tabs also load billing data in parallel with the main resource query.

### Manual VM Power Operation

1. The user clicks the VM status/action control in the Computing tab.
2. `CloudComputingModel` asks `VMPowerOperationRegistry` to lock the VM.
3. The model refreshes VM inventory to avoid acting on stale status.
4. `VMPowerService` sends a start or stop request through `YandexComputeAPI`.
5. `VMPollingService` polls inventory until the VM reaches a new status, fails, or times out.
6. The model updates the table row, notifications are posted when appropriate, and the VM lock is released.

The Stop All action follows the same registry, service, and polling path, but batches requests for all currently running VMs.

### Automatic VM Power Operation

1. AppKit or workspace lifecycle notifications trigger `VMPowerAutomationService`.
2. The service checks `SettingsManager` for enabled automation, selected VM IDs, and active start/shutdown options.
3. The service authenticates, loads current VM inventory, and cleans up auto-start selections for VMs that no longer exist.
4. Actionable VMs are locked in `VMPowerOperationRegistry`.
5. Start or stop requests are sent through `VMPowerService`.
6. For launch and wake start operations, the service polls to completion. For app exit and sleep shutdown operations, it sends stop commands and returns.

## Key Design Decisions

- The app is menu-bar-first. The project sets `LSUIElement = YES`, and `yaControlApp` exposes the UI through `MenuBarExtra`.
- Yandex Cloud access is implemented directly with Foundation networking rather than a generated SDK.
- Endpoint-specific API classes keep HTTP details separate from UI models, while `YandexAPIService` preserves a single facade for existing call sites.
- UI table models are separate from raw DTOs. `YandexInventoryService` is responsible for shaping API responses into display-ready data.
- VM power operations are guarded by an actor-backed registry so manual and automatic workflows do not operate on the same VM at the same time.
- Sensitive OAuth credentials are stored in Keychain. Regular preferences remain in `UserDefaults`.
- Localization is centralized in `Localizable.xcstrings`, with `L10n` string keys and `LocalizedStringHelper` supporting explicit app language selection.

## External Dependencies and Integrations

Swift Package dependencies are resolved in `Package.resolved`:

- `LaunchAtLogin-Modern` 1.1.0
- `ElegantTabs` 1.1.0

External services and platform integrations:

- Yandex IAM, Resource Manager, Compute, Serverless Functions, Storage, and Billing APIs.
- Yandex Cloud Console web URLs for opening resource detail pages.
- macOS Keychain for OAuth token storage.
- macOS UserNotifications for local VM operation notifications.
- macOS OSLog for optional logging.
- AppKit and NSWorkspace for menu-bar app behavior, lifecycle notifications, Terminal/RDP launching, and app termination handling.
- Network framework for internet connectivity checks.

## Build and Validation Notes

- The project uses `yaControl.xcodeproj`.
- The shared scheme is `yaControl`.
- The configured SDK is macOS, with `MACOSX_DEPLOYMENT_TARGET = 15.2`.
- The project build setting currently declares `SWIFT_VERSION = 5.0`, even though the repository instructions prefer Swift 6+ for future work.
- The app bundle identifier is `com.krusty84.yaControl`.
- The app is sandboxed and has the network client entitlement enabled.
- The app generates its Info.plist from build settings; the checked-in `yaControl/Info.plist` is currently empty.
- There are no checked-in test targets visible in the project.

For build validation, inspect schemes first and use the shared `yaControl` scheme. Do not assume extra targets beyond what the project file currently contains.

## Known Constraints

- The codebase mixes `@Observable` feature models with singleton `ObservableObject` app-wide state. Contributors should follow nearby patterns unless they are explicitly changing the state model.
- Many workflows depend on `SettingsManager.shared` and other shared singletons, so dependency injection is partial rather than universal.
- API calls assume the user has supplied a valid OAuth token and that the token can be exchanged for a Yandex IAM token.
- The app discovers resources by traversing all clouds and folders visible to the token. Large accounts may produce many concurrent API requests.
- VM shutdown during app exit or macOS sleep sends stop commands but intentionally does not poll to completion.
- Logging is disabled unless the user enables app logging in settings.
- `yaControlLoginItemHelper/` contains SwiftUI helper app source, but it is not represented as a native target in the current `project.pbxproj`.
