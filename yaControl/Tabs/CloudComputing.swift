//
//  CloudComputing.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @State private var vmTableData: [VMTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if vmTableData.isEmpty {
                Text("No VMs found")
                    .padding()
            } else {
                List(vmTableData, id: \.name) { vm in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(vm.name)")
                            .font(.headline)
                        Text("Status: \(vm.status)")
                            .foregroundColor(vm.status == "RUNNING" ? .green : .red)
                        Text("Created At: \(vm.createdAt)")
                        Text("Cores: \(vm.cores)")
                        Text("Memory: \(vm.memoryGB) GB")
                        Text("Preemptible: \(vm.preemptible ? "Yes" : "No")")
                        Text("Addresses: \(vm.addresses.joined(separator: ", "))")
                        Text("Folder: \(vm.folderName)")
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            fetchVMs()
        }
    }
    
    private func fetchVMs() {
        isLoading = true
        errorMessage = nil
        
        // Step 1: Get IAM Token
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Step 2: Get VMs using the IAM Token
                    YandexAPIService.shared.getVMs(iamToken: response.iamToken) { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            switch result {
                            case .success(let allVMs):
                                print("result: ", allVMs)
                                vmTableData = allVMs
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                case .failure(let error):
                    isLoading = false
                    print(error.localizedDescription)
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
