//
//  CloudComputingView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @State private var model = CloudComputingModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedVM: VMTableData.ID? = nil
    @State private var isStopAllConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Total VM's: \(model.totalVMs)")
                    .font(.subheadline).bold()
                Text("Running: \(model.runningVMs)")
                    .font(.subheadline).bold()
                Spacer()
                Button {
                    Task { await model.fetchVMs() }
                } label: {
                    Label("Refresh VMs", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .help("Refresh VM's")

                Button {
                    isStopAllConfirmationPresented = true
                } label: {
                    Label("Stop All", systemImage: "stop.fill")
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 2))
                }
                .disabled(model.runningVMs == 0)
                .help("Stop all running VMs")
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Stop all running VMs?",
                    isPresented: $isStopAllConfirmationPresented
                ) {
                    Button("Stop All", role: .destructive) {
                        model.stopAllAndPoll()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will stop all currently running virtual machines visible to yaControl.")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .searchable(text: $model.searchText, prompt: "Search VMs")

            if model.isLoading {
                ProgressView("Loading…")
                    .padding()
            } else if let err = model.errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Load VMs", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(err)
                } actions: {
                    Button("Retry") {
                        Task { await model.fetchVMs() }
                    }
                }
            } else if model.filteredVMs.isEmpty {
                ContentUnavailableView(
                    "No VMs Found",
                    systemImage: "desktopcomputer",
                    description: Text("Refresh the list or check your Yandex Cloud credentials.")
                )
            } else {
                Table(model.filteredVMs, selection: $selectedVM) {
                    TableColumn("AS") { item in
                        VMAutoStartColumn(
                            vm: item,
                            isOn: item.isAutoStarted,
                            onToggle: { model.setAutoStart(for: item.id, isOn: $0) }
                        )
                    }
                    .width(min: 20, max: 20)

                    TableColumn("Name") { VMNameColumn(vm: $0) }
                        .width(min: 150, max: 150)

                    TableColumn("Status") { item in
                        let processing = model.processingStates[item.id] == true
                        VMStatusColumn(
                            vm: item,
                            isProcessing: processing,
                            onAction: { model.toggleVM(item) }
                        )
                    }
                    .width(min: 40, max: 40)

                    TableColumn("Created At", value: \.createdAt)
                        .width(min: 120, max: 120)
                    TableColumn("Cores", value: \.cores)
                        .width(min: 40, max: 40)
                    TableColumn("RAM", value: \.memoryGB)
                        .width(min: 30, max: 30)

                    TableColumn("Public IP") { VMPublicIPColumn(vm: $0) }
                        .width(min: 120, max: 120)

                    TableColumn("Folder") { VMFolderColumn(vm: $0) }
                        .width(min: 120, max: 120)
                }
                .padding(.vertical, 6)
                .refreshable { await model.fetchVMs() }
            }

            StatusPanel(
                lastUpdateTime: model.lastUpdateTime,
                currentBalance: model.currentBalance,
                currency: model.currency,
                billingUrl: model.billingUrl
            )
        }
        .task {
            await model.loadIfNeeded()
        }
    }
}
