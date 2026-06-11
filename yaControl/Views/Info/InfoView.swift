//
//  InfoView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct InfoWindow: View {
    @Environment(\.locale) private var locale

    @State private var model = InfoWindowModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedStringKey(L10n.Info.title))
                .font(.headline)
                .padding(.top, 8)

            if model.isLoading {
                ProgressView(localized(L10n.Info.loading))
                    .frame(maxHeight: .infinity)
            } else if let error = model.errorMessage {
                ContentUnavailableView {
                    Label(LocalizedStringKey(L10n.Info.errorTitle), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button(LocalizedStringKey(L10n.Common.retry)) {
                        Task { await model.loadAllData() }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if model.hasNoResources {
                ContentUnavailableView(
                    LocalizedStringKey(L10n.Info.emptyTitle),
                    systemImage: "tray",
                    description: Text(LocalizedStringKey(L10n.Info.emptyDescription))
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Billing
                        StatsBillingSection(
                            title: localized(L10n.Info.billingInformation),
                            icon: "creditcard",
                            stats: [
                                (localized(L10n.Info.currentBalance), BillingFormattingHelper.balanceAttributedString(amount: model.currentBalance, currency: model.currency, warningThreshold:SettingsManager.shared.billingThreshold)),
                                (localized(L10n.Info.details), AttributedString(localized(L10n.Info.viewBilling)))
    
                            ],
                            url: model.billingUrl
                        )

                        Divider()

                        // VMs
                        StatsSection(
                            title: localized(L10n.Info.virtualMachines),
                            icon: "desktopcomputer",
                            stats: [
                                (localized(L10n.Info.totalVMs), "\(model.totalVMsCount)"),
                                (localized(L10n.Info.runningVMs), "\(model.runningVMsCount)"),
                                (localized(L10n.Info.stoppedVMs), "\(model.totalVMsCount - model.runningVMsCount)")
                            ]
                        )

                        Divider()

                        // Serverless
                        StatsSection(
                            title: localized(L10n.Info.serverlessFunctions),
                            icon: "function",
                            stats: [
                                (localized(L10n.Info.totalFunctions), "\(model.totalSLFsCount)"),
                                (localized(L10n.Info.activeFunctions), "\(model.activeSLFsCount)"),
                                (localized(L10n.Info.inactiveFunctions), "\(model.totalSLFsCount - model.activeSLFsCount)")
                            ]
                        )

                        Divider()

                        // Buckets
                        StatsSection(
                            title: localized(L10n.Info.storageBuckets),
                            icon: "archivebox",
                            stats: [
                                (localized(L10n.Info.totalBuckets), "\(model.totalBucketsCount)")
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
            }

            Text(LocalizedStringHelper.formatted(
                L10n.Info.lastUpdated,
                locale: locale,
                model.lastUpdated.formatted(date: .omitted, time: .shortened)
            ))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 340, height: 460)
        .task {
            await model.loadIfNeeded()
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
