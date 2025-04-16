//
//  InfoWindow.swift - The short info about Yandex Cloud, hold Option key and click on App Icon
//  yaControl
//
//  Created by Sedoykin Alexey on 24/03/2025.
//

import SwiftUI

struct InfoWindow: View {
    // VM's Data
    @State private var vmTableData: [VMTableData] = []
    @State private var runningVMsCount = 0
    @State private var totalVMsCount = 0
    
    // Serverless Functions Data
    @State private var slfTableData: [ServerLessFunctionTableData] = []
    @State private var activeSLFsCount = 0
    @State private var totalSLFsCount = 0
    
    // Bucket Data
    @State private var bucketTableData: [BucketTableData] = []
    @State private var totalBucketsCount = 0
    
    // Billing Data
    @State private var billingData: [BillingTableData] = []
    @State private var currentBalance: String = "Loading..."
    @State private var currency: String = ""
    @State private var billingUrl: URL? = nil
    
    // Common Data
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated = Date()
    @State private var iamToken: String = ""
    @State private var isHovering = false
    
    //MARK: - UI Infowindow
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
                        StatsBillingSection(
                            title: "Billing Information",
                            icon: "creditcard",
                            stats: [
                                ("Current Balance", Helpers.billingBalanceFormatter(amount: currentBalance, currency: currency, warningThreshold:SettingsManager.shared.billingThreshold)),
                                ("Details", "View Billing")
                            ],
                            url: billingUrl
                        )

                        Divider()
                        
                        // VM's Section
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
    
    // MARK: - Infowindow Subviews
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
    
    
    private struct StatsBillingSection: View {
        let title: String
        let icon: String
        let stats: [(String, Any)]  // Changed to accept Any (String or AttributedString)
        var url: URL?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                    Text(title)
                        .font(.subheadline.bold())
                    Spacer()
                }
                
                ForEach(stats.indices, id: \.self) { index in
                    let stat = stats[index]
                    if stat.0 == "Details", let url = url {
                        Link(destination: url) {
                            StatBillingRow(label: stat.0, value: AttributedString(stat.1 as? String ?? ""), isLink: true)
                        }
                    } else {
                        if let attributedValue = stat.1 as? AttributedString {
                            StatBillingRow(label: stat.0, value: attributedValue)
                        } else {
                            StatBillingRow(label: stat.0, value: AttributedString(stat.1 as? String ?? ""))
                        }
                    }
                }
            }
        }
    }

    struct StatBillingRow: View {
        let label: String
        let value: AttributedString
        var isLink: Bool = false
        @State private var isHovering = false
        
        var body: some View {
            HStack {
                Text(label).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(value).font(.subheadline.bold())
            }
            .onHover { hovering in
                if isLink {
                    isHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
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

    
    //MARK: - Getting all stat data
    private func loadAllData() {
        isLoading = true
        errorMessage = nil
        
        // Getting IAM token and pushing it via other calls in the conveyor
//        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let response):
//                    self.iamToken = response.iamToken
//                    self.dataLoadingConveyor()
//                case .failure(let error):
//                    self.isLoading = false
//                    self.errorMessage = error.localizedDescription
//                }
//            }
//        }
        
        Task {
            do {
                // 1. Get IAM token
                let response = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                
                // 2. Update state on main thread
                await MainActor.run {
                    self.iamToken = response.iamToken
                    self.dataLoadingConveyor()
                }
                
            } catch {
                // 3. Handle errors on main thread
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    //MARK: - Data loading conveyor
    private func dataLoadingConveyor() {
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
    
    // MARK: - Get VM's
    private func getVMsStat(completion: @escaping () -> Void) {
//        YandexAPIService.shared.getVMs(iamToken: iamToken) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let allVMs):
//                    self.vmTableData = allVMs
//                    self.getStatData(with: allVMs)
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                }
//                completion()
//            }
//        }
        
        Task {
            do {
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: iamToken)
                await MainActor.run {
                    self.vmTableData = allVMs
                    self.getStatData(with: allVMs)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            completion()
        }
    }
    
    private func getStatData(with vms: [VMTableData]) {
        runningVMsCount = vms.filter { $0.status == "RUNNING" }.count
        totalVMsCount = vms.count
    }
    
    // MARK: - Get Serverless Functions
    private func getServerLessFunctionsStat(completion: @escaping () -> Void) {
//        YandexAPIService.shared.getServerLessFunctions(iamToken: iamToken) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let allSLFs):
//                    self.slfTableData = allSLFs
//                    self.getSLFsStatData(with: allSLFs)
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                }
//                completion()
//            }
//        }
        
        Task {
            do {
                let allSLFs = try await YandexAPIService.shared.getServerLessFunctions(iamToken: iamToken)
                await MainActor.run {
                    self.slfTableData = allSLFs
                    self.getSLFsStatData(with: allSLFs)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            completion()
        }
    }
    
    private func getSLFsStatData(with slf: [ServerLessFunctionTableData]) {
        activeSLFsCount = slf.filter { $0.status == "ACTIVE" }.count
        totalSLFsCount = slf.count
    }
    
    // MARK: - Get Buckets
    private func getBucketsStat(completion: @escaping () -> Void) {
//        YandexAPIService.shared.getBuckets(iamToken: iamToken) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let allBuckets):
//                    self.bucketTableData = allBuckets
//                    self.getBucketsStatData(with: allBuckets)
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                }
//                completion()
//            }
//        }
        
        Task {
            do {
                // 1. Fetch buckets asynchronously
                let allBuckets = try await YandexAPIService.shared.getBuckets(iamToken: iamToken)
                
                // 2. Update UI on main thread
                await MainActor.run {
                    self.bucketTableData = allBuckets
                    self.getBucketsStatData(with: allBuckets)
                }
            } catch {
                // 3. Handle errors on main thread
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            
            // 4. Call completion handler
            completion()
        }
    }
    
    private func getBucketsStatData(with bucketTableData: [BucketTableData]) {
        totalBucketsCount = bucketTableData.count
    }
    
    // MARK: - Get Billing
    private func getCosts(completion: @escaping () -> Void) {
//        YandexAPIService.shared.getCosts(iamToken: iamToken) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let billings):
//                    self.billingData = billings
//                    if let firstBilling = billings.first {
//                        self.currentBalance = firstBilling.balance
//                        self.currency = firstBilling.currency
//                        self.billingUrl = firstBilling.billingUrl
//                    }
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                }
//                completion() // Make sure to call completion in all cases
//            }
//        }
        
        Task {
            do {
                // 1. Fetch billing data asynchronously
                let billings = try await YandexAPIService.shared.getCosts(iamToken: iamToken)
                
                // 2. Update UI state on main thread
                await MainActor.run {
                    self.billingData = billings
                    if let firstBilling = billings.first {
                        self.currentBalance = firstBilling.balance
                        self.currency = firstBilling.currency
                        self.billingUrl = firstBilling.billingUrl
                    }
                }
            } catch {
                // 3. Handle errors on main thread
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            
            // 4. Call completion handler
            completion()
        }
    }
}



