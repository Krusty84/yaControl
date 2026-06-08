//
//  CloudComputing.swift - Yandex Cloud Serverless Functions
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @State private var model = ServerlessFunctionModel()
    @State private var selectedSlf: ServerLessFunctionTableData.ID? = nil

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
            Text("Total SLF's: \(model.totalSLFs)")
                .font(.subheadline).bold()
            Text("Active: \(model.activeSLFs)")
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchServerLessFunctions() }
            } label: {
                Label("Refresh SLF's", systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help("Refresh SLF's")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: "Search SLF's")
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView("Loading…")
                .padding()
        } else if let err = model.errorMessage {
            ContentUnavailableView {
                Label("Couldn’t Load Functions", systemImage: "exclamationmark.triangle")
            } description: {
                Text(err)
            } actions: {
                Button("Retry") {
                    Task { await model.fetchServerLessFunctions() }
                }
            }
        } else if model.filteredSLFs.isEmpty {
            ContentUnavailableView(
                "No Serverless Functions Found",
                systemImage: "function",
                description: Text("Refresh the list or check your Yandex Cloud credentials.")
            )
        } else {
            Table(model.filteredSLFs, selection: $selectedSlf) {
                TableColumn("Name") { slf in
                    SLFNameColumn(slf: slf)
                }
                TableColumn("Status") { slf in
                    SLFStatusColumn(slf: slf)
                }
                TableColumn("Created At", value: \.createdAt)
                TableColumn("Invoke") { slf in
                    SLFInvokeColumn(slf: slf)
                }
                TableColumn("Folder") { slf in
                    SLFFolderColumn(slf: slf)
                }
            }
            .padding(.vertical, 6)
            .refreshable {
                await model.fetchServerLessFunctions()
            }
        }
    }
}
