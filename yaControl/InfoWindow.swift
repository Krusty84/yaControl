//
//  InfoWindow.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 24/03/2025.
//

import SwiftUI

struct InfoWindow: View {
    // VM States
    @State private var vmTableData: [VMTableData] = []
    @State private var runningVMsCount = 0
    @State private var totalVMsCount = 0
    
    // Serverless Functions States
    @State private var slfTableData: [ServerLessFunctionTableData] = []
    @State private var activeSLFsCount = 0
    @State private var totalSLFsCount = 0
    
    // Bucket States
    @State private var bucketTableData: [BucketTableData] = []
    @State private var totalBucketsCount = 0
    
    // Billing States
    @State private var billingData: [BillingTableData] = []
    @State private var currentBalance: String = "Loading..."
    @State private var currency: String = ""
    @State private var billingUrl: URL? = nil
    
    // Common States
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated = Date()
    @State private var iamToken: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Yandex Cloud Statistics")
                .font(.headline)
                .padding(.top, 8)
            
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        loadAllData()
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Billing Section (added at top)
                        StatsSection(
                            title: "Billing Information",
                            icon: "creditcard",
                            stats: [
                                ("Current Balance", Helpers.formattedBalance(amount: currentBalance, currency: currency)),
                                ("Details", "View Billing")
                            ],
                            url: billingUrl
                        )

                        
                        Divider()
                        
                        // VM Statistics Section
                        StatsSection(
                            title: "Virtual Machines",
                            icon: "desktopcomputer",
                            stats: [
                                ("Total VMs", "\(totalVMsCount)"),
                                ("Running", "\(runningVMsCount)"),
                                ("Stopped", "\(totalVMsCount - runningVMsCount)")
                            ]
                        )
                        
                        Divider()
                        
                        // Serverless Functions Section
                        StatsSection(
                            title: "Serverless Functions",
                            icon: "function",
                            stats: [
                                ("Total Functions", "\(totalSLFsCount)"),
                                ("Active", "\(activeSLFsCount)"),
                                ("Inactive", "\(totalSLFsCount - activeSLFsCount)")
                            ]
                        )
                        
                        Divider()
                        
                        // Buckets Section
                        StatsSection(
                            title: "Storage Buckets",
                            icon: "archivebox",
                            stats: [
                                ("Total Buckets", "\(totalBucketsCount)")
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
            }
            
            Text("Last updated: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 340, height: 460)  // Adjusted size to accommodate billing section
        .onAppear {
            loadAllData()
        }
    }
    
    private func loadAllData() {
        isLoading = true
        errorMessage = nil
        
        // First get IAM token once and reuse it
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.iamToken = response.iamToken
                    self.loadResourcesWithToken()
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadResourcesWithToken() {
        let group = DispatchGroup()
        
        group.enter()
        getVMsStat {
            group.leave()
        }
        
        group.enter()
        getServerLessFunctionsStat {
            group.leave()
        }
        
        group.enter()
        getBucketsStat {
            group.leave()
        }
        
        group.enter()
        getCosts {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            self.lastUpdated = Date()
        }
    }
    
    // MARK: - VM Functions
    private func getVMsStat(completion: @escaping () -> Void) {
        YandexAPIService.shared.getVMs(iamToken: iamToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allVMs):
                    self.vmTableData = allVMs
                    self.getStatData(with: allVMs)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                completion()
            }
        }
    }
    
    private func getStatData(with vms: [VMTableData]) {
        runningVMsCount = vms.filter { $0.status == "RUNNING" }.count
        totalVMsCount = vms.count
    }
    
    // MARK: - Serverless Functions
    private func getServerLessFunctionsStat(completion: @escaping () -> Void) {
        YandexAPIService.shared.getServerLessFunctions(iamToken: iamToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allSLFs):
                    self.slfTableData = allSLFs
                    self.getSLFsStatData(with: allSLFs)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                completion()
            }
        }
    }
    
    private func getSLFsStatData(with slf: [ServerLessFunctionTableData]) {
        activeSLFsCount = slf.filter { $0.status == "ACTIVE" }.count
        totalSLFsCount = slf.count
    }
    
    // MARK: - Bucket Functions
    private func getBucketsStat(completion: @escaping () -> Void) {
        YandexAPIService.shared.getBuckets(iamToken: iamToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let allBuckets):
                    self.bucketTableData = allBuckets
                    self.getBucketsStatData(with: allBuckets)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                completion()
            }
        }
    }
    
    private func getBucketsStatData(with bucketTableData: [BucketTableData]) {
        totalBucketsCount = bucketTableData.count
    }
    
    // MARK: - Billing Functions
    private func getCosts(completion: @escaping () -> Void) {
        YandexAPIService.shared.getCosts(iamToken: iamToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let billings):
                    self.billingData = billings
                    if let firstBilling = billings.first {
                        self.currentBalance = firstBilling.balance
                        self.currency = firstBilling.currency
                        self.billingUrl = firstBilling.billingUrl
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                completion() // Make sure to call completion in all cases
            }
        }
    }
}

// MARK: - Subviews (same as before)
private struct StatsSection: View {
    let title: String
    let icon: String
    let stats: [(String, String)]
    var url: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
            }
            
            ForEach(stats, id: \.0) { stat in
                if stat.0 == "Details", let url = url {
                    Link(destination: url) {
                        StatRow(label: stat.0, value: stat.1)
                    }
                } else {
                    StatRow(label: stat.0, value: stat.1)
                }
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

