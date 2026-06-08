//
//  InfoView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI
import AppKit

struct InfoWindow: View {
    @StateObject private var vm = InfoWindowViewModel()
    @State private var isHoveringLink = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Yandex Cloud Statistics")
                .font(.headline)
                .padding(.top, 8)

            if vm.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task { await vm.loadAllData() }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Billing
                        StatsBillingSection(
                            title: "Billing Information",
                            icon: "creditcard",
                            stats: [
                                ("Current Balance", BillingFormattingHelper.balanceAttributedString(amount: vm.currentBalance, currency: vm.currency, warningThreshold:SettingsManager.shared.billingThreshold)),
                                ("Details", "View Billing")
    
                            ],
                            url: vm.billingUrl
                        )

                        Divider()

                        // VMs
                        StatsSection(
                            title: "Virtual Machines",
                            icon: "desktopcomputer",
                            stats: [
                                ("Total VMs", "\(vm.totalVMsCount)"),
                                ("Running", "\(vm.runningVMsCount)"),
                                ("Stopped", "\(vm.totalVMsCount - vm.runningVMsCount)")
                            ]
                        )

                        Divider()

                        // Serverless
                        StatsSection(
                            title: "Serverless Functions",
                            icon: "function",
                            stats: [
                                ("Total Functions", "\(vm.totalSLFsCount)"),
                                ("Active", "\(vm.activeSLFsCount)"),
                                ("Inactive", "\(vm.totalSLFsCount - vm.activeSLFsCount)")
                            ]
                        )

                        Divider()

                        // Buckets
                        StatsSection(
                            title: "Storage Buckets",
                            icon: "archivebox",
                            stats: [
                                ("Total Buckets", "\(vm.totalBucketsCount)")
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
            }

            Text("Last updated: \(vm.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 340, height: 460)
        .onAppear {
            Task { await vm.loadAllData() }
        }
    }
}
