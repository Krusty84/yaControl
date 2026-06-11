//
//  ErrorPanel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct ErrorView: View {
    @Environment(\.locale) private var locale

    let error: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringHelper.formatted(
                L10n.Errors.errorFormat,
                locale: locale,
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
