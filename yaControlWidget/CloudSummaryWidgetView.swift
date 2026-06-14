//
//  CloudSummaryWidgetView.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import SwiftUI
import WidgetKit

struct CloudSummaryWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: CloudSummaryWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                if snapshot.errorMessage == nil {
                    summaryView(snapshot)
                } else {
                    unavailableView(
                        title: "widget.errorTitle",
                        message: "widget.errorMessage",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            } else {
                unavailableView(
                    title: "widget.noDataTitle",
                    message: "widget.noDataMessage",
                    systemImage: "tray"
                )
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func summaryView(_ snapshot: CloudSummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(snapshot)

            balanceView(snapshot)

            if widgetFamily == .systemSmall {
                smallMetrics(snapshot)
            } else {
                mediumMetrics(snapshot)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private func header(_ snapshot: CloudSummarySnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("widget.title")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Text(snapshot.lastUpdated, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("widget.updated"))
        }
    }

    private func balanceView(_ snapshot: CloudSummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("widget.balance", systemImage: "creditcard")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(balanceAttributedString(snapshot))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityLabel(Text("widget.balance"))
                .accessibilityValue(Text(balanceText(snapshot)))
        }
    }

    private func smallMetrics(_ snapshot: CloudSummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CompactMetricRow(
                title: "widget.virtualMachines",
                systemImage: "desktopcomputer",
                value: "\(snapshot.runningVMsCount)/\(snapshot.totalVMsCount)"
            )

            CompactMetricRow(
                title: "widget.functions",
                systemImage: "function",
                value: "\(snapshot.activeFunctionsCount)/\(snapshot.totalFunctionsCount)"
            )

            CompactMetricRow(
                title: "widget.buckets",
                systemImage: "archivebox",
                value: "\(snapshot.totalBucketsCount)"
            )
        }
    }

    private func mediumMetrics(_ snapshot: CloudSummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            MetricRow(
                title: "widget.virtualMachines",
                systemImage: "desktopcomputer",
                value: String(
                    format: NSLocalizedString("widget.totalRunningFormat", comment: ""),
                    String(snapshot.totalVMsCount),
                    String(snapshot.runningVMsCount)
                )
            )

            MetricRow(
                title: "widget.functions",
                systemImage: "function",
                value: String(
                    format: NSLocalizedString("widget.totalActiveFormat", comment: ""),
                    String(snapshot.totalFunctionsCount),
                    String(snapshot.activeFunctionsCount)
                )
            )

            MetricRow(
                title: "widget.buckets",
                systemImage: "archivebox",
                value: String(
                    format: NSLocalizedString("widget.totalOnlyFormat", comment: ""),
                    String(snapshot.totalBucketsCount)
                )
            )
        }
    }

    private func unavailableView(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }

    private func balanceText(_ snapshot: CloudSummarySnapshot) -> String {
        [snapshot.currentBalance, snapshot.currency]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    private func balanceAttributedString(_ snapshot: CloudSummarySnapshot) -> AttributedString {
        BillingFormattingHelper.balanceAttributedString(
            amount: snapshot.currentBalance,
            currency: snapshot.currency
        )
    }
}

private struct MetricRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CompactMetricRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 14)
                .accessibilityHidden(true)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(value)
                .font(.caption.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(as: .systemMedium) {
    CloudSummaryWidget()
} timeline: {
    CloudSummaryWidgetEntry.placeholder
    CloudSummaryWidgetEntry.noData()
}
