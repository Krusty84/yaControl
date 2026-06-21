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
        let isStale = CloudSummaryWidgetFreshness.isStale(
            snapshot,
            at: entry.date
        )

        return VStack(alignment: .leading, spacing: 10) {
            header(snapshot, isStale: isStale)

            balanceView(snapshot, isStale: isStale)

            if widgetFamily == .systemSmall {
                CloudSummarySmallWidgetView(
                    snapshot: snapshot,
                    isStale: isStale
                )
            } else {
                CloudSummaryMediumWidgetView(
                    snapshot: snapshot,
                    isStale: isStale
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.vertical)
        .padding(.horizontal, 0)
        .overlay(alignment: .topTrailing) {
            if isStale {
                staleIndicator
                    .padding(.top, 16)
                    .padding(.horizontal, 0)
            }
        }
    }

    private func header(
        _ snapshot: CloudSummarySnapshot,
        isStale: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("widget.title")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 0) {
                Text("widget.updated")
                Text(": ")

                Text(
                    snapshot.lastUpdated,
                    format: .dateTime.hour().minute()
                )
                .strikethrough(isStale)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var staleIndicator: some View {
        Image(systemName: "clock.badge.exclamationmark")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.orange)
            .padding(4)
            .background(Color.clear)
            .accessibilityLabel(Text("widget.stale"))
    }

    private func balanceView(
        _ snapshot: CloudSummarySnapshot,
        isStale: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("widget.balance", systemImage: "creditcard")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(balanceAttributedString(snapshot))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .strikethrough(isStale)
                .accessibilityLabel(Text("widget.balance"))
                .accessibilityValue(Text(balanceText(snapshot)))
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

#Preview(as: .systemMedium) {
    CloudSummaryWidget()
} timeline: {
    CloudSummaryWidgetEntry.placeholder
    CloudSummaryWidgetEntry.noData()
}
