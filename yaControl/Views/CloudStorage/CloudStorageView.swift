//
//  CloudStorage.swift - Yandex Cloud Storage
//  yaControl
//
//  Created by Sedoykin Alexey on 09/03/2025.
//

import SwiftUI

struct BucketTabContent: View {
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    
    let isActive: Bool
    let refreshToken: UUID

    @State private var model = CloudStorageModel()
    @State private var selectedBucket: BucketTableData.ID? = nil

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
            await model.refreshIfStale(maxAge: 120)
        }
        .onAppear {
            guard isActive else { return }

            Task {
                await model.refreshIfStale(maxAge: 120)
            }
        }
        .onChange(of: isActive) { _, active in
            guard active else { return }

            Task {
                await model.refreshIfStale(maxAge: 120)
            }
        }
        .onChange(of: refreshToken) { _, _ in
            guard isActive else { return }

            Task {
                await model.refreshIfStale(maxAge: 120)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text(LocalizedStringHelper.formatted(
                L10n.Storage.totalBuckets,
                locale: locale,
                Int64(model.totalBuckets)
            ))
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchBuckets() }
            } label: {
                Label(LocalizedStringKey(L10n.Storage.refresh), systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help(localized(L10n.Storage.refreshHelp))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Storage.searchPrompt))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(localized(L10n.Storage.loading)).padding()
        } else if let err = model.errorMessage {
            ContentUnavailableView {
                Label(LocalizedStringKey(L10n.Storage.errorTitle), systemImage: "exclamationmark.triangle")
            } description: {
                Text(err)
            } actions: {
                Button(LocalizedStringKey(L10n.Common.retry)) {
                    Task { await model.fetchBuckets() }
                }
            }
        } else if model.filteredBuckets.isEmpty {
            ContentUnavailableView {
                Label(
                    LocalizedStringKey(L10n.Storage.emptyTitle),
                    systemImage: "archivebox"
                )
            } description: {
                Text(LocalizedStringKey(L10n.Storage.emptyDescription))
            } actions: {
                Button(LocalizedStringKey(L10n.Storage.createFirstBucket)) {
                    openCreateBucketPage()
                }
                .buttonStyle(.link)
                .disabled(createBucketURL == nil)
            }
        } else {
            Table(model.filteredBuckets, selection: $selectedBucket) {
                TableColumn(LocalizedStringKey(L10n.Table.storageName)) { BucketNameColumn(bucket: $0) }
                TableColumn(LocalizedStringKey(L10n.Table.storageMaxSizeGB), value: \.maxSize)
                    .width(min: 80, max: 80)
                TableColumn(LocalizedStringKey(L10n.Table.storageUsedSizeGB), value: \.usedSize)
                    .width(min: 90, max: 90)
                TableColumn(LocalizedStringKey(L10n.Table.storageFiles), value: \.totalObjectCountString)
                    .width(min: 40, ideal: 40, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.storageCreatedAt), value: \.createdAt)
                    .width(min: 110, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.storageUpdatedAt), value: \.updatedAt)
                    .width(min: 110, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.storageFolder)) { BucketFolderColumn(bucket: $0) }
                    .width(min: 80, max: 150)
            }
            .padding(.vertical, 6)
            .id(locale.identifier)
            .refreshable {
                await model.fetchBuckets()
            }
            .contextMenu {
                Button {
                    openCreateBucketPage()
                } label: {
                    Label(
                        LocalizedStringKey(L10n.Table.createBucket),
                        systemImage: "plus.rectangle.on.rectangle"
                    )
                }
                .disabled(createBucketURL == nil)
            }
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
    
    private var createBucketFolderId: String? {
        if let selectedBucket,
           let selected = model.bucketTableData.first(where: { $0.id == selectedBucket }) {
            return selected.folderId
        }

        if let folderId = model.filteredBuckets.first?.folderId ?? model.bucketTableData.first?.folderId {
            return folderId
        }

        let defaultFolderId = SettingsManager.shared.defaultFolderIdForCreation
        return defaultFolderId.isEmpty ? nil : defaultFolderId
    }

    private var createBucketURL: URL? {
        guard let folderId = createBucketFolderId else { return nil }
        return URL(string: APIConfig.yaCreateBucketWebUrl(folderID: folderId))
    }

    private func openCreateBucketPage() {
        guard let createBucketURL else { return }
        openURL(createBucketURL)
    }
}
