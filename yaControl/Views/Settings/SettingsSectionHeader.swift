//
//  SettingsSectionHeader.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsSectionHeader: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())

            Spacer()
        }
        .padding(.bottom, SettingsLayout.headerBottomPadding)
    }
}
