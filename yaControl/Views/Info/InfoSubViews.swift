//
//  InfoSubViews.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct StatsSection: View {
    let title: String
    let icon: String
    let stats: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.subheadline.bold())
                Spacer()
            }
            ForEach(stats, id: \.0) { label, value in
                StatRow(label: label, value: value)
            }
        }
    }
}

struct StatsBillingSection: View {
    @Environment(\.locale) private var locale

    let title: String
    let icon: String
    let stats: [(String, AttributedString)]
    var url: URL?
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.subheadline.bold())
                Spacer()
            }
            ForEach(stats, id: \.0) { label, value in
                if label == LocalizedStringHelper.string(L10n.Info.details, locale: locale),
                   let link = url {
                    Link(destination: link) {
                        StatBillingRow(label: label, value: value, isLink: true)
                    }
                } else {
                    StatBillingRow(label: label, value: value)
                }
            }
        }
    }
}
struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

struct StatBillingRow: View {
    let label: String
    let value: AttributedString
    var isLink: Bool = false
    @State private var isHovering = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .onHover { hovering in
            guard isLink else { return }
            isHovering = hovering
            if hovering { NSCursor.pointingHand.push() }
            else { NSCursor.pop() }
        }
    }
}
