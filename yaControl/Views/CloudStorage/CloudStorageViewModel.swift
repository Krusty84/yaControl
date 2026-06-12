//
//  CloudStorageViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class CloudStorageModel {
    // MARK: – State
    var bucketTableData: [BucketTableData] = []
    var billingData: [BillingTableData] = []
    var isLoading = false
    var error: Error?
    var searchText = ""
    var currentBalance = ""
    var currency = ""
    var billingUrl: URL? = nil
    var lastUpdateTime = Date()
    
    private let api = YandexAPIService.shared
    private var iamToken = ""
    private var hasLoaded = false
    
    // MARK: – Computed helpers
    var filteredBuckets: [BucketTableData] {
        guard !searchText.isEmpty else { return bucketTableData }
        return bucketTableData.filter {
            $0.name.localizedStandardContains(searchText)
        }
    }
    var totalBuckets: Int { bucketTableData.count }
    var showError: Bool { error != nil }
    var errorMessage: String? { error?.localizedDescription }
    
    // MARK: – Data loading
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await fetchBuckets()
    }

    func fetchBuckets() async {
        isLoading = true
        error = nil
        
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
            self.error = error
            isLoading = false
            LoggerHelper.error("Error fetching buckets: \(error.localizedDescription)")
        }
    }
}
