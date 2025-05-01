//
//  CloudComputingView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @StateObject private var vm = CloudComputingViewModel()
      @EnvironmentObject var appState: AppState
      @State private var selectedVM: VMTableData.ID? = nil

      var body: some View {
          VStack(spacing: 0) {
              HStack {
                  Text("Total VMs: \(vm.totalVMs)")
                      .font(.subheadline).bold()
                  Text("Running: \(vm.runningVMs)")
                      .font(.subheadline).bold()
                  Spacer()
                  Button {
                      Task { await vm.fetchVMs() }
                  } label: {
                      Image(systemName: "arrow.clockwise")
                  }
                  .buttonStyle(PlainButtonStyle())
                  .help("Refresh VMs")
                  //
                  Button {
                      vm.stopAllAndPoll()
                  } label: {
                      HStack {
                          Image(systemName: "stop.fill")
                              .foregroundColor(.red)
                          Text("Stop All")
                              .foregroundColor(.red)
                      }
                      .padding(.horizontal, 10)
                      .padding(.vertical, 5)
                      .background(Color.red.opacity(0.2))
                      .cornerRadius(5)
                  }
                  .disabled(vm.runningVMs == 0)
                  .help("Stop all running VMs")    // ← updated help
                  .buttonStyle(PlainButtonStyle())
              }
              .padding(.horizontal)
              .padding(.vertical, 6)
              .searchable(text: $vm.searchText, prompt: "Search VMs")

              if vm.isLoading {
                  ProgressView("Loading…")
                      .padding()
              } else if let err = vm.errorMessage {
                  Text("Error: \(err)")
                      .foregroundColor(.red)
                      .padding()
              } else if vm.filteredVMs.isEmpty {
                  Text("No VMs found")
                      .padding()
              } else {
                  Table(vm.filteredVMs, selection: $selectedVM) {
                      TableColumn("AS") { item in
                          VMAutoStartColumn(
                              vm: item,
                              isOn: item.isAutoStarted,
                              onToggle: { vm.setAutoStart(for: item.id, isOn: $0) }
                          )
                      }
                      .width(min: 20, max: 20)

                      TableColumn("Name") { VMNameColumn(vm: $0) }
                          .width(min: 150, max: 200)

                      TableColumn("Status") { item in
                          let processing = vm.processingStates[item.id] == true
                          VMStatusColumn(
                              vm: item,
                              isProcessing: processing,
                              onAction: { vm.toggleVM(item) }
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
                  .refreshable { await vm.fetchVMs() }
              }

              StatusPanel(
                  lastUpdateTime: vm.lastUpdateTime,
                  currentBalance: vm.currentBalance,
                  currency: vm.currency,
                  billingUrl: vm.billingUrl
              )
          }
          .onAppear { Task { await vm.fetchVMs() } }
      }
  }
