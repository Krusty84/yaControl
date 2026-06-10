//
//  CloudStorage.swift - Yandex Cloud Storage
//  yaControl
//
//  Created by Sedoykin Alexey on 09/03/2025.
//

import SwiftUI

struct BucketTabContent: View {
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
            await model.loadIfNeeded()
        }
    }

    private var headerView: some View {
        HStack {
            Text(String(
                format: LocalizedStringHelper.string(L10n.Storage.totalBuckets, language: SettingsManager.shared.appLanguage),
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
            .help(LocalizedStringHelper.string(L10n.Storage.refresh, language: SettingsManager.shared.appLanguage))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Storage.search))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(LocalizedStringHelper.string(L10n.Common.loading, language: SettingsManager.shared.appLanguage)).padding()
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
            ContentUnavailableView(
                LocalizedStringKey(L10n.Storage.emptyTitle),
                systemImage: "archivebox",
                description: Text(LocalizedStringKey(L10n.Storage.emptyDescription))
            )
        } else {
            Table(model.filteredBuckets, selection: $selectedBucket) {
                TableColumn(LocalizedStringKey(L10n.Table.name)) { BucketNameColumn(bucket: $0) }
                TableColumn(LocalizedStringKey(L10n.Table.maxSizeGb), value: \.maxSize)
                    .width(min: 80, max: 80)
                TableColumn(LocalizedStringKey(L10n.Table.usedSizeGb), value: \.usedSize)
                    .width(min: 90, max: 90)
                TableColumn(LocalizedStringKey(L10n.Table.files), value: \.totalObjectCountString)
                    .width(min: 40, ideal: 40, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.createdAt), value: \.createdAt)
                    .width(min: 110, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.updatedAt), value: \.updatedAt)
                    .width(min: 110, max: 120)
                TableColumn(LocalizedStringKey(L10n.Table.folder)) { BucketFolderColumn(bucket: $0) }
                    .width(min: 80, max: 150)
            }
            .padding(.vertical, 6)
            .refreshable {
                await model.fetchBuckets()
            }
        }
    }
}
