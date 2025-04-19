//
//  Settings.swift - Application Settings
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import LaunchAtLogin

struct SettingsTabContent: View {
    @AppStorage("com.krusty84.yaControl.settings.oAuthKey") private var oAuthKey: String = SettingsManager.shared.oAuthKey
    @State private var responseCode: Int? = nil
    @State private var errorMessage: String? = nil
    @State private var selectedTab: Int = 0
    
    // VM Management State
    @State private var autoStartVM: Bool = SettingsManager.shared.autoStartEnabled
    @State private var startOptions: [StartOption] = SettingsManager.shared.startOptions
    @State private var shutdownOptions: [ShutdownOption] = SettingsManager.shared.shutdownOptions
    
    //Billing Management State
    @AppStorage("com.krusty84.yaControl.settings.billingThreshold") private var billingThreshold: Double = SettingsManager.shared.billingThreshold
    
    enum StartOption: String, CaseIterable {
        case afterAppLaunched = "After app launched"
        case afterMacOSStarted = "After macOS started"
        case afterWakeup = "After wakeup"
    }
    
    enum ShutdownOption: String, CaseIterable {
        case afterAppExit = "After app exit"
        case afterMacOSShutdown = "After macOS shutdown"
        case afterMacOSSleep = "After macOS sleep"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker at the top
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                    .help("Configure general application settings and preferences")
                Text("Virtual Machine Management").tag(1)
                    .help("Manage your virtual machines and compute resources")
                Text("Billing Management").tag(2)
                    .help("View and manage your billing information and usage")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Tab content area
            Group {
                switch selectedTab {
                    case 0:
                        generalSettingsTab
                    case 1:
                        vmManagementTab
                    case 2:
                        billingManagementTab
                    default:
                        EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            oAuthKey = SettingsManager.shared.oAuthKey
        }
    }
    
    // MARK: - Tab Views
    
    private var generalSettingsTab: some View {

        ScrollView {
            VStack(spacing: 10) {
                // Application Preferences Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            LaunchAtLogin.Toggle()
                                .toggleStyle(.switch)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .help("Launch this app automatically when you log in")
                            //Spacer()
                            // Add more preferences here
                            // ExampleToggle("Some Option", isOn: $someOption)
                        }
                        }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Application Preferences", systemImage: "gearshape.fill")
                }
                Spacer()
                Divider()
                // Authentication Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("OAuth Key", text: $oAuthKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: checkOAuthKey) {
                                Text("Verify")
                                    .frame(minWidth: 60)
                            }
                        }
                        statusIndicator
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
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(20)
        }
    }
    
    private var vmManagementTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Auto Start VM Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("", isOn: $autoStartVM)
                                .toggleStyle(.switch)
                                .onChange(of: autoStartVM) { newValue in
                                    SettingsManager.shared.autoStartEnabled = newValue
                                }
                                .help("Enable/disable virtual machine power management by monitoring the status of your Mac")
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Auto Start/Stop Mode", systemImage: "power")
                }
                
                Divider()
                
                // Two Column Layout
                HStack(alignment: .top, spacing: 30) {
                    // Startup Options Column
                    VStack(alignment: .leading, spacing: 12) {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to start VM")
                                    .font(.subheadline)
                                    .padding(.bottom, 4)
                                
                                ForEach(StartOption.allCases, id: \.self) { option in
                                    HStack {
                                        Toggle(option.rawValue, isOn: Binding(
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
                                        .disabled(!autoStartVM) // Disable when autoStartVM is false
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                        } header: {
                            SectionHeader(title: "Startup Options", systemImage: "play.fill")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    // Shutdown Options Column
                    VStack(alignment: .leading, spacing: 12) {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to shutdown VM")
                                    .font(.subheadline)
                                    .padding(.bottom, 4)
                                
                                ForEach(ShutdownOption.allCases, id: \.self) { option in
                                    HStack {
                                        Toggle(option.rawValue, isOn: Binding(
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
                                        .disabled(!autoStartVM) // Disable when autoStartVM is false
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                        } header: {
                            SectionHeader(title: "Shutdown Options", systemImage: "stop.fill")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                
                Spacer()
            }
            .padding(10)
        }
    }
    
    private var billingManagementTab: some View {
         ScrollView {
             VStack(spacing: 10) {
                 Section {
                     VStack(alignment: .leading, spacing: 12) {
                         HStack {
                             TextField("The Lower Limit", text: $billingThreshold.toFormattedString())
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                 .help("Set the minimum balance threshold for pay attention")
                             
                         }
                     }
                     .padding(.horizontal, 8)
                 } header: {
                     SectionHeader(title: "Billing Threshold", systemImage: "dollarsign.circle.fill")
                 }
                 Spacer()
             }
             .padding(20)
         }
     }
    
    
    private var statusIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let code = responseCode {
                HStack(spacing: 4) {
                    Image(systemName: code == 200 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(code == 200 ? .green : .red)
                    Text(code == 200 ? "Valid credentials" : "Invalid credentials")
                        .foregroundColor(code == 200 ? .green : .red)
                }
                .font(.caption)
            }
            
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.orange)
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Subviews
    
    private struct SectionHeader: View {
        let title: String
        let systemImage: String
        
        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Actions
    
    private func checkOAuthKey() {
        
        Task {
            do {
                let response = try await YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: oAuthKey)
                
                await MainActor.run {
                    responseCode = response.code
                    if response.code == 200 {
                        errorMessage = nil
                        print(response.iamToken)
                    } else {
                        errorMessage = "Invalid OAuth key (Code: \(response.code))"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    responseCode = nil
                }
            }
        }
    }
}
