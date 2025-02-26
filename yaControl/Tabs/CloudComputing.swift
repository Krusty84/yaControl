//
//  CloudComputing.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @State private var iamToken: String = ""
    @State private var vmTableData: [VMTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var selectedVM: VMTableData? = nil
    
    var filteredVMs: [VMTableData] {
        if searchText.isEmpty {
            return vmTableData
        } else {
            return vmTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    
    
    var body: some View {
         VStack(spacing: 0) {
             // Search Bar
//             SearchBar(text: $searchText)
//                 .padding(.horizontal)
             
             // Table Header
             TableHeader()
             
             // Table Content
             if isLoading {
                 LoadingView()
             } else if let errorMessage = errorMessage {
                 ErrorView(errorMessage: errorMessage)
             } else if filteredVMs.isEmpty {
                 EmptyView()
             } else {
                 TableContent(iamToken: $iamToken,filteredVMs: filteredVMs, selectedVM: $selectedVM)
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
                    iamToken=response.iamToken
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search VMs", text: $text)
                .padding(8)
                .background(Color(.lightGray))
                .cornerRadius(8)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
}


struct TableHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Name").frame(width: 100, alignment: .leading)
            Text("Status").frame(width: 50, alignment: .leading)
            Text("Created At").frame(width: 150, alignment: .leading)
            Text("№ CPU").frame(width: 50, alignment: .leading)
            Text("RAM").frame(width: 50, alignment: .leading)
            Text("Addresses").frame(width: 150, alignment: .leading)
            Text("Folder").frame(width: 100, alignment: .leading)
        }
        .font(.headline)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}
struct TableContent: View {
    @Binding var iamToken: String
    let filteredVMs: [VMTableData]
    @Binding var selectedVM: VMTableData?
    var body: some View {
        List(filteredVMs, id: \.name) { vm in
            TableRow(iamToken: $iamToken, vm: vm, selectedVM: $selectedVM)
        }
        //.listStyle(PlainListStyle())
    }
}

struct TableRow: View {
    @Binding var iamToken: String
    let vm: VMTableData
    @Binding var selectedVM: VMTableData?
    @Environment(\.openURL) private var openURL
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            //Text(vm.name).frame(width: 100, alignment: .leading)
            Text(vm.name)
                           .frame(width: 100, alignment: .leading)
                           .foregroundColor(.blue)
                           .underline()
                           .onHover { hovering in
                                        isHovering = hovering
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                           .onTapGesture {
                               if let url = URL(string: vm.vmUrl) {
                                   openURL(url)
                               }
                           }
            Button(action: {
                startStopVM(iamToken:iamToken,for: vm)
                        }) {
                            Image(systemName: vm.status == "RUNNING" ? "stop.fill" : "play.fill")
                                .foregroundColor(vm.status == "RUNNING" ? .red : .green)
                                .frame(width: 30, alignment: .leading)
                        }
            Text(vm.createdAt).frame(width: 150, alignment: .leading)
            Text(vm.cores).frame(width: 50, alignment: .leading)
            Text("\(vm.memoryGB) GB").frame(width: 50, alignment: .leading)
            Text(vm.addresses.joined(separator: ", ")).frame(width: 150, alignment: .leading)
            Text(vm.folderName)
                           .frame(width: 100, alignment: .leading)
                           .foregroundColor(.blue)
                           .underline()
                           .onHover { hovering in
                                        isHovering = hovering
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                           .onTapGesture {
                               if let url = URL(string: vm.folderUrl) {
                                   openURL(url)
                               }
                           }
        }
        .contentShape(Rectangle())
        //.font(.subheadline)
       // .padding(.vertical, 4)
        .background(selectedVM?.id == vm.id ? Color.blue.opacity(0.2) : Color.clear)
        .onTapGesture {
            selectedVM = vm
            print("Selected VM ID: \(vm.id)")
        }
    }
}


struct LoadingView: View {
    var body: some View {
        ProgressView("Loading...")
            .padding()
    }
}

struct ErrorView: View {
    let errorMessage: String
    
    var body: some View {
        Text("Error: \(errorMessage)")
            .foregroundColor(.red)
            .padding()
    }
}

struct EmptyView: View {
    var body: some View {
        Text("No VMs found")
            .padding()
    }
}

