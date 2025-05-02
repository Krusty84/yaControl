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
            Text("Error: \(error)")
                .foregroundColor(.red)
            Text("Check your internet connection")
            Text("Check the validity of the OAuth key (go to application settings)")
            Text("Cloud may be pending - refresh data in a few seconds")
        }
        .padding()
    }
}
