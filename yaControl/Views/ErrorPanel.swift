//
//  ErrorPanel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct ErrorView: View {
    let error: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(
                format: LocalizedStringHelper.string(L10n.Errors.errorFormat, language: SettingsManager.shared.appLanguage),
                error
            ))
                .foregroundColor(.red)
            Text(LocalizedStringKey(L10n.Errors.checkConnection))
            Text(LocalizedStringKey(L10n.Errors.checkOAuth))
            Text(LocalizedStringKey(L10n.Errors.cloudPending))
        }
        .padding()
    }
}
