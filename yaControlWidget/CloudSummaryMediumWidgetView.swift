//
//  CloudSummaryMediumWidgetView.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import SwiftUI

struct CloudSummaryMediumWidgetView: View {
    let snapshot: CloudSummarySnapshot
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            MetricRow(
                title: "widget.virtualMachines",
                systemImage: "desktopcomputer",
                value: String(
                    format: NSLocalizedString(
                        "widget.totalRunningFormat",
                        comment: ""
                    ),
                    String(snapshot.totalVMsCount),
                    String(snapshot.runningVMsCount)
                ),
                isStale: isStale
            )

            MetricRow(
                title: "widget.functions",
                systemImage: "function",
                value: String(
                    format: NSLocalizedString(
                        "widget.totalActiveFormat",
                        comment: ""
                    ),
                    String(snapshot.totalFunctionsCount),
                    String(snapshot.activeFunctionsCount)
                ),
                isStale: isStale
            )

            MetricRow(
                title: "widget.buckets",
                systemImage: "archivebox",
                value: String(
                    format: NSLocalizedString(
                        "widget.totalOnlyFormat",
                        comment: ""
                    ),
                    String(snapshot.totalBucketsCount)
                ),
                isStale: isStale
            )
        }
    }
}

private struct MetricRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String
    let isStale: Bool

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
                .strikethrough(isStale)
        }
        .accessibilityElement(children: .combine)
    }
}
