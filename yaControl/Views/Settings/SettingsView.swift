//
//  Settings.swift - Application Settings
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import LaunchAtLogin

struct SettingsTabContent: View {
    // General Settings
    @AppStorage("com.krusty84.yaControl.settings.generalUsername4VMs")
    private var generalUsername4VMs: String = SettingsManager.shared.generalUsername4VMs

    @State private var oAuthKey: String = ""
    @State private var appLogging: Bool = false
    
    @State private var ycCLIInstalled: Bool = false
    
    // VM Management State
    @State private var responseCode: Int? = nil
    @State private var errorMessage: String? = nil
    @State private var selectedTab: Int = 0
    @State private var autoStartVM: Bool = false
    @State private var startOptions: [StartOption] = []
    @State private var shutdownOptions: [ShutdownOption] = []

    // Billing Management
    @AppStorage("com.krusty84.yaControl.settings.billingThreshold")
    private var billingThreshold: Double = SettingsManager.shared.billingThreshold

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Virtual Machine Management").tag(1)
                Text("Billing Management").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            Group {
                switch selectedTab {
                case 0: generalSettingsTab
                case 1: vmManagementTab
                case 2: billingManagementTab
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // sync all state vars from SettingsManager
            oAuthKey = SettingsManager.shared.oAuthKey
            generalUsername4VMs = SettingsManager.shared.generalUsername4VMs
            autoStartVM = SettingsManager.shared.autoStartEnabled
            appLogging = SettingsManager.shared.appLoggingEnabled
            ycCLIInstalled = SettingsManager.shared.ycCLIInstalled
            startOptions = SettingsManager.shared.startOptions
            shutdownOptions = SettingsManager.shared.shutdownOptions
            billingThreshold = SettingsManager.shared.billingThreshold
        }
    }

    // MARK: – General Tab
    private var generalSettingsTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                Section {
                    HStack(spacing: 20) {  // Adjust spacing as needed
                        LaunchAtLogin.Toggle()
                            .toggleStyle(.switch)
                            .help("Launch this app automatically when you log in")
                        
                        Toggle("Application Logging", isOn: $appLogging)
                            .toggleStyle(.switch)
                            .onChange(of: appLogging) { SettingsManager.shared.appLoggingEnabled = $0 }
                            .help("Enable/disable application logging")
                        
                        // ← Your notification toggle goes here
                        NotificationToggleView()
                            .help("Request permission for user notifications")
                        
                        Spacer() // Pushes content to the left
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Application Preferences", systemImage: "gearshape.fill")
                }


                Divider()

                Section {
                    HStack {
                        TextField("OAuth Key", text: $oAuthKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        oAuthStatusIndicator
                        Button("Verify", action: checkOAuthKey)
                            .frame(minWidth: 60)
                    }
                    .padding(.horizontal, 8)
                } header: {
                    HStack {
                        Label("Yandex Cloud Authentication", systemImage: "key.fill")
                            .font(.headline)
                        Spacer()
                        Link("Get OAuth Key", destination: URL(string: APIConfig.yaGetOAuthKey)!)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .onHover { hovering in
                                isHovering = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                    .padding(.bottom, 8)
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Installed", isOn: $ycCLIInstalled)
                            .toggleStyle(.switch)
                            .onChange(of: ycCLIInstalled) { SettingsManager.shared.ycCLIInstalled = $0 }
                            .help("Enable/disable application logging")
                            // make the toggle fill its container, and align its label to the left
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8)
                } header: {
                    HStack {
                        Label("Yandex Cloud CLI", systemImage: "terminal.fill")
                            .font(.headline)
                        Spacer()
                        Link("Get Yandex Cloud CLI", destination: URL(string: APIConfig.yaGetYCCLI)!)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .onHover { hovering in
                                isHovering = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(20)
        }
 
    }

    // MARK: – VM Management Tab
    private var vmManagementTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    Toggle("", isOn: $autoStartVM)
                        .toggleStyle(.switch)
                        .onChange(of: autoStartVM) { SettingsManager.shared.autoStartEnabled = $0 }
                        .help("Enable/disable VM power management")
                        .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Auto Start/Stop Mode", systemImage: "power")
                }

                Divider()

                HStack(alignment: .top, spacing: 30) {
                    // Startup Options
                    VStack(alignment: .leading, spacing: 12) {
                        Section {
                            Text("How to start VM")
                                .font(.subheadline)
                                .padding(.bottom, 4)

                            ForEach(StartOption.allCases, id: \.self) { option in
                                Toggle(option.rawValue,
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
                                       ))
                                .toggleStyle(.checkbox)
                                .disabled(!autoStartVM || option == .afterMacOSStarted)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)

                    // Shutdown Options
                    VStack(alignment: .leading, spacing: 12) {
                        Section {
                            Text("How to shutdown VM")
                                .font(.subheadline)
                                .padding(.bottom, 4)

                            ForEach(ShutdownOption.allCases, id: \.self) { option in
                                Toggle(option.rawValue,
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
                                       ))
                                .toggleStyle(.checkbox)
                                .disabled(option == .afterMacOSShutdown)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)

                Divider()
                
                Section {
                    TextField("General VM's Username", text: $generalUsername4VMs)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .help("Username for managing your virtual machines")
                        .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "General VM's Username", systemImage: "person.fill")
                }
                //Spacer()
            }
            .padding(10)
        }
    }

    // MARK: – Billing Tab
    private var billingManagementTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                Section {
                    HStack {
                        TextField(
                            "The Lower Limit",
                            value: $billingThreshold,
                            format: .number.precision(.fractionLength(2))
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .help("Set the minimum balance threshold")
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(
                        title: "Billing Threshold",
                        systemImage: "dollarsign.circle.fill"
                    )
                }
                Spacer()
            }
            .padding(20)
        }
    }


    // MARK: – OAuth Status Indicator
    private var oAuthStatusIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let code = responseCode {
                HStack(spacing: 4) {
                    Image(systemName: code == 200 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(code == 200 ? .green : .red)
                    Text(code == 200 ? "Valid credentials" : "Invalid credentials")
                        .font(.caption)
                        .foregroundColor(code == 200 ? .green : .red)
                }
            }
            if let err = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: – Helpers
    private struct SectionHeader: View {
        let title: String
        let systemImage: String
        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }

    private func checkOAuthKey() {
        let token = oAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
            responseCode = nil
            errorMessage = "OAuth token is empty."
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
                        errorMessage = "Invalid OAuth key (Code \(response.code))"
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
}
