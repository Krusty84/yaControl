//
//  Settings.swift - Application Settings
//  yaControl
//
//  Created by Sedoykin Alexey on 18/02/2025.
//

import SwiftUI
import LaunchAtLogin

struct SettingsTabContent: View {
    @AppStorage("oAuthKey") private var oAuthKey: String = SettingsManager.shared.oAuthKey
    @State private var responseCode: Int? = nil
    @State private var errorMessage: String? = nil
    var body: some View {
        
        VStack (spacing: 0) {
            HStack {
                VStack {
                    TextField("OAuth Key", text: $oAuthKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //isabled(!isEditingEnabled)
                    LaunchAtLogin.Toggle()
                }
                VStack {
                    Button(action: {
                        // Call the API directly from the button action
                        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: oAuthKey) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let response):
                                        if(response.code == 200){
                                            responseCode = response.code
                                            print(response.iamToken)
                                            errorMessage = nil
                                        }else{
                                            oAuthKey.removeAll()
                                        }
                                    responseCode = response.code
                                    errorMessage = nil
                                case .failure(let error):
                                    errorMessage = error.localizedDescription
                                    responseCode = nil
                                }
                            }
                        }
                    }, label: {
                        Text("Check")
                            .clipped()
                    })
                    .buttonStyle(.automatic)
                    //
                }
            }
            TextField("Result", text: Helpers.shared.restResponseToString(for: $responseCode))
        }
        .onAppear {
            // Sync SettingsManager to ensure consistency
            oAuthKey = SettingsManager.shared.oAuthKey
        }
    }
}
