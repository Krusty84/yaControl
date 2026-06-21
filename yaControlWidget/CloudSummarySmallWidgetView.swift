//
//  CloudSummarySmallWidgetView.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import SwiftUI

struct CloudSummarySmallWidgetView: View {
    let snapshot: CloudSummarySnapshot
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CompactMetricRow(
                title: "widget.virtualMachines",
                systemImage: "desktopcomputer",
                value: "\(snapshot.totalVMsCount)/\(snapshot.runningVMsCount)",
                isStale: isStale
            )

            CompactMetricRow(
                title: "widget.functions",
                systemImage: "function",
                value: "\(snapshot.activeFunctionsCount)/\(snapshot.totalFunctionsCount)",
                isStale: isStale
            )

            CompactMetricRow(
                title: "widget.buckets",
                systemImage: "archivebox",
                value: "\(snapshot.totalBucketsCount)",
                isStale: isStale
            )
        }
    }
}

private struct CompactMetricRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String
    let isStale: Bool

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
                .strikethrough(isStale)
        }
        .accessibilityElement(children: .combine)
    }
}
