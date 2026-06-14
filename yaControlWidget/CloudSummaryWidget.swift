//
//  CloudSummaryWidget.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import SwiftUI
import WidgetKit

@main
struct CloudSummaryWidget: Widget {
    static let kind = CloudSummaryWidgetKind.cloudSummary

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: CloudSummaryWidgetProvider()) { entry in
            CloudSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("yaControl")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
