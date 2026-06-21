//
//  CloudComputingView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    let isActive: Bool
    let refreshToken: UUID

    @State private var model = CloudComputingModel()
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
            await model.refreshIfStale(maxAge: 30)
        }
        .onAppear {
            guard isActive else { return }
            
            Task {
                await model.refreshIfStale(maxAge: 30)
            }
        }
        .onChange(of: isActive) { _, active in
            guard active else { return }
            
            Task {
                await model.refreshIfStale(maxAge: 15)
            }
        }
        .onChange(of: refreshToken) { _, _ in
            guard isActive else { return }
            
            Task {
                await model.refreshIfStale(maxAge: 15)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vmInventoryDidChange)) { _ in
            guard isActive else { return }
            
            Task {
                await model.fetchVMs()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text(LocalizedStringHelper.formatted(
                L10n.Computing.totalVMs,
                locale: locale,
                Int64(model.totalVMs)
            ))
                .font(.subheadline).bold()
            Text(LocalizedStringHelper.formatted(
                L10n.Computing.runningVMs,
                locale: locale,
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
            .help(localized(L10n.Computing.refreshHelp))

            Button {
                isStopAllConfirmationPresented = true
            } label: {
                Label(LocalizedStringKey(L10n.Computing.stopAll), systemImage: "stop.fill")
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 2))
            }
            .disabled(model.runningVMs == 0)
            .help(localized(L10n.Computing.stopAllHelp))
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
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Computing.searchPrompt))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(localized(L10n.Computing.loading))
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
            ContentUnavailableView {
                Label(
                    LocalizedStringKey(L10n.Computing.emptyTitle),
                    systemImage: "desktopcomputer"
                )
            } description: {
                Text(LocalizedStringKey(L10n.Computing.emptyDescription))
            } actions: {
                Button(LocalizedStringKey(L10n.Computing.createFirstVM)) {
                    openCreateVMPage()
                }
                .buttonStyle(.link)
                .disabled(createVMURL == nil)
            }
        } else {
            Table(model.filteredVMs, selection: $selectedVM) {
                TableColumn(LocalizedStringKey(L10n.Table.vmAutoStart)) { item in
                    VMAutoStartColumn(
                        vm: item,
                        isOn: item.isAutoStarted,
                        onToggle: { model.setAutoStart(for: item.id, isOn: $0) }
                    )
                }
                .width(min: 20, max: 20)

                TableColumn(LocalizedStringKey(L10n.Table.vmName)) { VMNameColumn(vm: $0) }
                    .width(min: 150, max: 150)

                TableColumn(LocalizedStringKey(L10n.Table.vmStatus)) { item in
                    let processing = model.processingStates[item.id] == true
                    VMStatusColumn(
                        vm: item,
                        isProcessing: processing,
                        onAction: { model.toggleVM(item) }
                    )
                }
                .width(min: 40, max: 40)

                TableColumn(LocalizedStringKey(L10n.Table.vmCreatedAt), value: \.createdAt)
                    .width(min: 120, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.vmCores), value: \.cores)
                    .width(min: 40, max: 40)
                TableColumn(LocalizedStringKey(L10n.Table.vmRam), value: \.memoryGB)
                    .width(min: 30, max: 30)

                TableColumn(LocalizedStringKey(L10n.Table.vmPublicIP)) { VMPublicIPColumn(vm: $0) }
                    .width(min: 120, max: 120)

                TableColumn(LocalizedStringKey(L10n.Table.vmFolder)) { VMFolderColumn(vm: $0) }
                    .width(min: 120, max: 120)
            }
            .padding(.vertical, 6)
            .id(locale.identifier)
            .refreshable { await model.fetchVMs() }
            .contextMenu {
                Button {
                    openCreateVMPage()
                } label: {
                    Label(
                        LocalizedStringKey(L10n.Table.createVM),
                        systemImage: "plus.rectangle.on.rectangle"
                    )
                }
                .disabled(createVMURL == nil)
            }
        }
    }
    
    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
    
    private var createVMFolderId: String? {
        if let selectedVM,
           let selected = model.vmTableData.first(where: { $0.id == selectedVM }) {
            return selected.folderId
        }

        if let folderId = model.filteredVMs.first?.folderId ?? model.vmTableData.first?.folderId {
            return folderId
        }

        let defaultFolderId = SettingsManager.shared.defaultFolderIdForCreation
        return defaultFolderId.isEmpty ? nil : defaultFolderId
    }

    private var createVMURL: URL? {
        guard let folderId = createVMFolderId else { return nil }
        return URL(string: APIConfig.yaCreateVMWebUrl(folderID: folderId))
    }

    private func openCreateVMPage() {
        guard let createVMURL else { return }
        openURL(createVMURL)
    }
}
