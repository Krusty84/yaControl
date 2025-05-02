//
//  InfoViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

@MainActor
class InfoWindowViewModel: ObservableObject {
    // MARK: - Published stats
    @Published var totalVMsCount = 0
    @Published var runningVMsCount = 0
    @Published var totalSLFsCount = 0
    @Published var activeSLFsCount = 0
    @Published var totalBucketsCount = 0
    @Published var currentBalance: String = "Loading..."
    @Published var currency: String = ""
    @Published var billingUrl: URL? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdated = Date()

    private let api = YandexAPIService.shared

    func loadAllData() async {
        isLoading = true
        errorMessage = nil
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
            runningVMsCount  = vmsData.filter { $0.status == "RUNNING" }.count

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
            errorMessage = error.localizedDescription
            isLoading   = false
        }
    }
}
