//
//  About.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import AppKit

struct AboutTabContent: View {
    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(10)

            // Description
            Text("WavesVista")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                Text("This simple application will help you quickly learn about the state of the ionosphere.")
                    .font(.body)
                    .multilineTextAlignment(.center)

                Text("Its suitability for long-distance QSOs. 73! de UB3ARM")
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
                        Text("License: MIT")
                        Text("Author: Alexey Sedoykin")
                        Text("Contact: www.linkedin.com/in/sedoykin")
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
                        Text("Exit")
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
}
