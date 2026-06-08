//
//  InfoViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class InfoWindowModel {
    // MARK: - Stats
    var totalVMsCount = 0
    var runningVMsCount = 0
    var totalSLFsCount = 0
    var activeSLFsCount = 0
    var totalBucketsCount = 0
    var currentBalance: String = "Loading..."
    var currency: String = ""
    var billingUrl: URL? = nil
    var isLoading = false
    var error: Error?
    var lastUpdated = Date()

    private let api = YandexAPIService.shared
    private var hasLoaded = false

    var showError: Bool { error != nil }
    var errorMessage: String? { error?.localizedDescription }
    var hasNoResources: Bool {
        totalVMsCount == 0
            && totalSLFsCount == 0
            && totalBucketsCount == 0
            && billingUrl == nil
            && currentBalance == "Loading..."
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await loadAllData()
    }

    func loadAllData() async {
        isLoading = true
        error = nil
        do {
            // 1. Authenticate
            let auth = try await api.checkOauthKey(
                yandexPassportOauthToken: SettingsManager.shared.oAuthKey
            )
            let token = auth.iamToken

            // 2. Fetch all stats in parallel
            async let vms     = api.getVMs(iamToken: token)
            async let slfs    = api.getServerLessFunctions(iamToken: token)
            async let buckets = api.getBuckets(iamToken: token)
            async let bills   = api.getCosts(iamToken: token)

            let (vmsData, slfData, bucketData, billData) = try await (
                vms, slfs, buckets, bills
            )

            // 3. Update published values
            totalVMsCount    = vmsData.count
            runningVMsCount  = vmsData.filter { $0.status.isRunning }.count

            totalSLFsCount   = slfData.count
            activeSLFsCount  = slfData.filter { $0.status == "ACTIVE" }.count

            totalBucketsCount = bucketData.count

            if let first = billData.first {
                currentBalance = first.balance
                currency       = first.currency
                billingUrl     = first.billingUrl
            }

            lastUpdated = Date()
            isLoading   = false
        } catch {
            self.error = error
            isLoading   = false
        }
    }
}
