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
            Text("Total Buckets: \(model.totalBuckets)")
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchBuckets() }
            } label: {
                Label("Refresh Buckets", systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help("Refresh Buckets")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: "Search buckets")
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView("Loading…").padding()
        } else if let err = model.errorMessage {
            ContentUnavailableView {
                Label("Couldn’t Load Buckets", systemImage: "exclamationmark.triangle")
            } description: {
                Text(err)
            } actions: {
                Button("Retry") {
                    Task { await model.fetchBuckets() }
                }
            }
        } else if model.filteredBuckets.isEmpty {
            ContentUnavailableView(
                "No Buckets Found",
                systemImage: "archivebox",
                description: Text("Refresh the list or check your Yandex Cloud credentials.")
            )
        } else {
            Table(model.filteredBuckets, selection: $selectedBucket) {
                TableColumn("Name") { BucketNameColumn(bucket: $0) }
                TableColumn("Max Size (Gb)", value: \.maxSize)
                    .width(min: 80, max: 80)
                TableColumn("Used Size (Gb)", value: \.usedSize)
                    .width(min: 90, max: 90)
                TableColumn("Files", value: \.totalObjectCountString)
                    .width(min: 40, ideal: 40, max: 120)
                TableColumn("Created At", value: \.createdAt)
                    .width(min: 110, max: 120)
                TableColumn("Updated At", value: \.updatedAt)
                    .width(min: 110, max: 120)
                TableColumn("Folder") { BucketFolderColumn(bucket: $0) }
                    .width(min: 80, max: 150)
            }
            .padding(.vertical, 6)
            .refreshable {
                await model.fetchBuckets()
            }
        }
    }
}
