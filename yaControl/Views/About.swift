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

    private static let homeURLString = "https://www.sedoykin.com"
    private static let gitHubURLString = "https://github.com/Krusty84/yaControl"
    private static let privacyPolicyURLString = "https://www.sedoykin.com/published_app/yaControl/legal/Privacy_Policy.html"

    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(.rect(cornerRadius: 10))

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
                        if let homeURL = URL(string: Self.homeURLString) {
                            linkRow(
                                title: LocalizedStringKey(L10n.About.linkHome),
                                icon: "house",
                                url: homeURL
                            )
                        }

                        if let gitHubURL = URL(string: Self.gitHubURLString) {
                            linkRow(
                                title: LocalizedStringKey(L10n.About.linkGitHub),
                                icon: "chevron.left.forwardslash.chevron.right",
                                url: gitHubURL
                            )
                        }

                        if let privacyPolicyURL = URL(string: Self.privacyPolicyURLString) {
                            linkRow(
                                title: LocalizedStringKey(L10n.About.linkPrivacy),
                                icon: "hand.raised",
                                url: privacyPolicyURL
                            )
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
                            .clipShape(.rect(cornerRadius: 6))
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
    
    private func linkRow(
         title: LocalizedStringKey,
         icon: String,
         url: URL
     ) -> some View {
         Link(destination: url) {
             HStack(spacing: 12) {
                 Image(systemName: icon)
                     .frame(width: 28, alignment: .leading)
                     .foregroundStyle(.primary)

                 Text(title)
                     .foregroundStyle(.primary)

                 Spacer()
             }
             .contentShape(Rectangle())
         }
         .font(.body)
         .buttonStyle(.plain)
         .pointingHandCursor()
     }

     private var version: String {
         let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

         return LocalizedStringHelper.formatted(L10n.About.version, locale: locale, version)
     }
}
