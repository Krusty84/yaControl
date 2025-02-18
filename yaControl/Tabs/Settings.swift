//
//  Settings.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI

struct SettingsTabContent: View {
    @AppStorage("oAuthKey") private var oAuthKey: String = SettingsManager.shared.oAuthKey
    var body: some View {
        
        VStack (spacing: 0) {
            HStack {
                VStack {
                    TextField("OAuth Key", text: $oAuthKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //isabled(!isEditingEnabled)
                }
                VStack {
                    Button(action: { }, label: {
                        Text("Check")
                        
                            .clipped()
                    })
                    .buttonStyle(.automatic)
                    
                }
            }
        }
        .onAppear {
            // Sync SettingsManager to ensure consistency
            oAuthKey = SettingsManager.shared.oAuthKey
        }
    }
}
