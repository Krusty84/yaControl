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
            headerView

            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            StatusPanel(
                lastUpdateTime: model.lastUpdateTime,
                currentBalance: model.currentBalance,
                currency: model.currency,
                billingUrl: model.billingUrl
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            await model.loadIfNeeded()
        }
    }

    private var headerView: some View {
        HStack {
            Text(String(
                format: LocalizedStringHelper.string(L10n.Computing.totalVMs, language: SettingsManager.shared.appLanguage),
                Int64(model.totalVMs)
            ))
                .font(.subheadline).bold()
            Text(String(
                format: LocalizedStringHelper.string(L10n.Computing.running, language: SettingsManager.shared.appLanguage),
                Int64(model.runningVMs)
            ))
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchVMs() }
            } label: {
                Label(LocalizedStringKey(L10n.Computing.refresh), systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help(LocalizedStringHelper.string(L10n.Computing.refresh, language: SettingsManager.shared.appLanguage))

            Button {
                isStopAllConfirmationPresented = true
            } label: {
                Label(LocalizedStringKey(L10n.Computing.stopAll), systemImage: "stop.fill")
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 2))
            }
            .disabled(model.runningVMs == 0)
            .help(LocalizedStringHelper.string(L10n.Computing.stopAllHelp, language: SettingsManager.shared.appLanguage))
            .buttonStyle(.plain)
            .confirmationDialog(
                LocalizedStringKey(L10n.Computing.stopAllConfirmTitle),
                isPresented: $isStopAllConfirmationPresented
            ) {
                Button(LocalizedStringKey(L10n.Computing.stopAll), role: .destructive) {
                    model.stopAllAndPoll()
                }
                Button(LocalizedStringKey(L10n.Common.cancel), role: .cancel) {}
            } message: {
                Text(LocalizedStringKey(L10n.Computing.stopAllConfirmMessage))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Computing.search))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(LocalizedStringHelper.string(L10n.Common.loading, language: SettingsManager.shared.appLanguage))
                .padding()
        } else if let err = model.errorMessage {
            ContentUnavailableView {
                Label(LocalizedStringKey(L10n.Computing.errorTitle), systemImage: "exclamationmark.triangle")
            } description: {
                Text(err)
            } actions: {
                Button(LocalizedStringKey(L10n.Common.retry)) {
                    Task { await model.fetchVMs() }
                }
            }
        } else if model.filteredVMs.isEmpty {
            ContentUnavailableView(
                LocalizedStringKey(L10n.Computing.emptyTitle),
                systemImage: "desktopcomputer",
                description: Text(LocalizedStringKey(L10n.Computing.emptyDescription))
            )
        } else {
            Table(model.filteredVMs, selection: $selectedVM) {
                TableColumn(LocalizedStringKey(L10n.Table.autoStart)) { item in
                    VMAutoStartColumn(
                        vm: item,
                        isOn: item.isAutoStarted,
                        onToggle: { model.setAutoStart(for: item.id, isOn: $0) }
                    )
                }
                .width(min: 20, max: 20)

                TableColumn(LocalizedStringKey(L10n.Table.name)) { VMNameColumn(vm: $0) }
                    .width(min: 150, max: 150)

                TableColumn(LocalizedStringKey(L10n.Table.status)) { item in
                    let processing = model.processingStates[item.id] == true
                    VMStatusColumn(
                        vm: item,
                        isProcessing: processing,
                        onAction: { model.toggleVM(item) }
                    )
                }
                .width(min: 40, max: 40)

                TableColumn(LocalizedStringKey(L10n.Table.createdAt), value: \.createdAt)
                    .width(min: 120, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.cores), value: \.cores)
                    .width(min: 40, max: 40)
                TableColumn(LocalizedStringKey(L10n.Table.ram), value: \.memoryGB)
                    .width(min: 30, max: 30)

                TableColumn(LocalizedStringKey(L10n.Table.publicIP)) { VMPublicIPColumn(vm: $0) }
                    .width(min: 120, max: 120)

                TableColumn(LocalizedStringKey(L10n.Table.folder)) { VMFolderColumn(vm: $0) }
                    .width(min: 120, max: 120)
            }
            .padding(.vertical, 6)
            .refreshable { await model.fetchVMs() }
        }
    }
}
