//
//  InfoView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct InfoWindow: View {
    @State private var model = InfoWindowModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Yandex Cloud Statistics")
                .font(.headline)
                .padding(.top, 8)

            if model.isLoading {
                ProgressView("Loading…")
                    .frame(maxHeight: .infinity)
            } else if let error = model.errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Load Statistics", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await model.loadAllData() }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if model.hasNoResources {
                ContentUnavailableView(
                    "No Resources Found",
                    systemImage: "tray",
                    description: Text("Refresh statistics or check your Yandex Cloud credentials.")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Billing
                        StatsBillingSection(
                            title: "Billing Information",
                            icon: "creditcard",
                            stats: [
                                ("Current Balance", BillingFormattingHelper.balanceAttributedString(amount: model.currentBalance, currency: model.currency, warningThreshold:SettingsManager.shared.billingThreshold)),
                                ("Details", "View Billing")
    
                            ],
                            url: model.billingUrl
                        )

                        Divider()

                        // VMs
                        StatsSection(
                            title: "Virtual Machines",
                            icon: "desktopcomputer",
                            stats: [
                                ("Total VMs", "\(model.totalVMsCount)"),
                                ("Running", "\(model.runningVMsCount)"),
                                ("Stopped", "\(model.totalVMsCount - model.runningVMsCount)")
                            ]
                        )

                        Divider()

                        // Serverless
                        StatsSection(
                            title: "Serverless Functions",
                            icon: "function",
                            stats: [
                                ("Total Functions", "\(model.totalSLFsCount)"),
                                ("Active", "\(model.activeSLFsCount)"),
                                ("Inactive", "\(model.totalSLFsCount - model.activeSLFsCount)")
                            ]
                        )

                        Divider()

                        // Buckets
                        StatsSection(
                            title: "Storage Buckets",
                            icon: "archivebox",
                            stats: [
                                ("Total Buckets", "\(model.totalBucketsCount)")
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
            }

            Text("Last updated: \(model.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 340, height: 460)
        .task {
            await model.loadIfNeeded()
        }
    }
}
