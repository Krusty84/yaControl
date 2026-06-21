//
//  SettingsDebugTabView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsDebugTabView: View {
    @Environment(\.locale) private var locale
    @Bindable var model: SettingsModel
    @Bindable var apiDebugStore: APIDebugStore

    var body: some View {
        GeometryReader { proxy in
            let editorHeight = max(120, min(320, proxy.size.height - 150))

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                    Section {
                        Toggle(LocalizedStringKey(L10n.Settings.apiDebugEnabled), isOn: $model.apiDebugEnabled)
                            .toggleStyle(.switch)
                            .help(localized(L10n.Settings.apiDebugEnabledHelp))
                            .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
                    } header: {
                        SettingsSectionHeader(
                            title: LocalizedStringKey(L10n.Settings.debugTitle),
                            systemImage: "ladybug.fill"
                        )
                    }

                    Divider()

                    Section {
                        VStack(alignment: .leading, spacing: SettingsLayout.rowSpacing) {
                            TextEditor(text: $apiDebugStore.messages)
                                .font(.system(.caption, design: .monospaced))
                                .frame(height: editorHeight)
                                .border(.separator)

                            HStack {
                                Button(LocalizedStringKey(L10n.Settings.debugSaveToFile)) {
                                    apiDebugStore.saveToExternalFile()
                                }
                                .disabled(apiDebugStore.messages.isEmpty)

                                Button(LocalizedStringKey(L10n.Settings.debugClear)) {
                                    apiDebugStore.clear()
                                }
                                .disabled(apiDebugStore.messages.isEmpty)

                                Spacer()
                            }
                        }
                        .padding(.horizontal, SettingsLayout.innerHorizontalPadding)
                    } header: {
                        SettingsSectionHeader(
                            title: LocalizedStringKey(L10n.Settings.debugMessagesTitle),
                            systemImage: "doc.text.magnifyingglass"
                        )
                    }
                }
                .padding(SettingsLayout.outerPadding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }
}
