//
//  CloudStorageViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI

@MainActor
class CloudStorageViewModel: ObservableObject {
    // MARK: – Published state
    @Published var bucketTableData: [BucketTableData] = []
    @Published var billingData: [BillingTableData] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var currentBalance = ""
    @Published var currency = ""
    @Published var billingUrl: URL? = nil
    @Published var lastUpdateTime = Date()
    
    private let api = YandexAPIService.shared
    private var iamToken = ""
    
    // MARK: – Computed helpers
    var filteredBuckets: [BucketTableData] {
        guard !searchText.isEmpty else { return bucketTableData }
        return bucketTableData.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    var totalBuckets: Int { bucketTableData.count }
    
    // MARK: – Data loading
    func fetchBuckets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Authenticate
            let auth = try await api.checkOauthKey(
                yandexPassportOauthToken: SettingsManager.shared.oAuthKey
            )
            iamToken = auth.iamToken
            
            // 2. Load buckets and billing in parallel
            async let buckets = api.getBuckets(iamToken: iamToken)
            async let bills   = api.getCosts(iamToken: iamToken)
            
            let (list, billings) = try await (buckets, bills)
            
            // 3. Publish results
            bucketTableData = list
            billingData      = billings
            if let first = billings.first {
                currentBalance = first.balance
                currency       = first.currency
                billingUrl     = first.billingUrl
            }
            lastUpdateTime = Date()
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            LoggerHelper.error("Error fetching buckets: \(error.localizedDescription)")
        }
    }
}
