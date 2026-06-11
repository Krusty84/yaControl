//
//  About.swift - About as is
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import AppKit

struct AboutTabContent: View {
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(10)

            // Description
            Text(LocalizedStringKey(L10n.About.title))
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                Text(LocalizedStringKey(L10n.About.description))
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            Divider()

            // Two Columns
            HStack(alignment: .top, spacing: 32) {
                // License & Author
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        Text(String(format: localized(L10n.About.license), "MIT"))
                        Text(String(format: localized(L10n.About.author), "Alexey Sedoykin"))
                        Text(String(format: localized(L10n.About.contact), "www.linkedin.com/in/sedoykin"))
                            .onHover { hovering in
                                if hovering { NSCursor.pointingHand.push() }
                                else       { NSCursor.pop() }
                            }
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // Exit Button
                VStack {
                    Spacer()
                    Spacer()
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text(LocalizedStringKey(L10n.About.exit))
                            //.font(.system(size: 12, weight: .medium))
                            .font(.caption)
                            //.foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            //.background(Color.red)
                            .cornerRadius(6)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }

            Spacer()
        }
        .padding(.vertical, 16)
        //.frame(width: 300, height: 300)
        .onAppear {
            // Any additional setup when the view appears
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
