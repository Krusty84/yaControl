//
//  ServerLessFunctionViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class ServerlessFunctionModel {
    var slfTableData: [ServerLessFunctionTableData] = []
    var isLoading = false
    var error: Error?
    var searchText = ""
    var lastUpdateTime = Date()
    var billingData: [BillingTableData] = []
    var currentBalance = ""
    var currency = ""
    var billingUrl: URL? = nil

    private let api = YandexAPIService.shared
    private var iamToken = ""
    private var hasLoaded = false

    // Computed helpers
    var filteredSLFs: [ServerLessFunctionTableData] {
        guard !searchText.isEmpty else { return slfTableData }
        return slfTableData.filter { $0.name.localizedStandardContains(searchText) }
    }

    var totalSLFs: Int { slfTableData.count }
    var activeSLFs: Int { slfTableData.filter { $0.status == "ACTIVE" }.count }
    var showError: Bool { error != nil }
    var errorMessage: String? { error?.localizedDescription }

    // Public method to load data
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await fetchServerLessFunctions()
    }

    func fetchServerLessFunctions() async {
        isLoading = true
        error = nil

        do {
            // 1. Get IAM token
            let auth = try await api.checkOauthKey(
                yandexPassportOauthToken: SettingsManager.shared.oAuthKey
            )
            iamToken = auth.iamToken

            // 2. Get functions and cost in parallel
            async let slfs = api.getServerLessFunctions(iamToken: iamToken)
            async let bills = api.getCosts(iamToken: iamToken)

            let (list, billings) = try await (slfs, bills)

            // 3. Update published properties
            slfTableData = list
            billingData = billings
            if let first = billings.first {
                currentBalance = first.balance
                currency = first.currency
                billingUrl = first.billingUrl
            }
            lastUpdateTime = Date()
            isLoading = false

        } catch {
            self.error = error
            isLoading = false
            LoggerHelper.error("Fetch SLFs failed: \(error.localizedDescription)")
        }
    }
}
