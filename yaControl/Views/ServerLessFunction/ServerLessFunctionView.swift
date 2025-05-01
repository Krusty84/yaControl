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
                Text("Total: \(vm.totalSLFs)")
                    .bold()
                Text("Active: \(vm.activeSLFs)")
                    .bold()
                Spacer()
                Button { Task { await vm.fetchServerLessFunctions() } }
                label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh")
            }
            .padding()

            // Search field
            .searchable(text: $vm.searchText, prompt: "Search SLFs")

            // Main content
            if vm.isLoading {
                ProgressView("Loading…")
                    .padding()
            } else if let err = vm.errorMessage {
                Text("Error: \(err)")
                    .foregroundColor(.red)
                    .padding()
            } else if vm.filteredSLFs.isEmpty {
                Text("No SLFs found")
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
