//
//  CloudComputing.swift - Yandex Cloud Serverless Functions
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @StateObject private var vm = ServerLessFunctionViewModel()
    @State private var selectedSlf: ServerLessFunctionTableData.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Top stats and refresh
            HStack {
                Text("Total SLF's: \(vm.totalSLFs)")
                    .font(.subheadline).bold()
                Text("Active: \(vm.activeSLFs)")
                    .font(.subheadline).bold()
                Spacer()
                Button { Task { await vm.fetchServerLessFunctions() } }
                label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh SLF's")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .searchable(text: $vm.searchText, prompt: "Search SLF's")

            // Main content
            if vm.isLoading {
                ProgressView("Loading…")
                    .padding()
            } else if let err = vm.errorMessage {
                ErrorView(error: err)
            } else if vm.filteredSLFs.isEmpty {
                Text("No SLF's found")
                    .padding()
            } else {
                Table(vm.filteredSLFs, selection: $selectedSlf) {
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
                    await vm.fetchServerLessFunctions()
                }
            }

            // Billing / status panel
            StatusPanel(
                lastUpdateTime: vm.lastUpdateTime,
                currentBalance: vm.currentBalance,
                currency: vm.currency,
                billingUrl: vm.billingUrl
            )
        }
        .onAppear {
            Task { await vm.fetchServerLessFunctions() }
        }
    }
}
