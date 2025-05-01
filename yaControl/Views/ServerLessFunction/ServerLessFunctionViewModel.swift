//
//  ServerLessFunctionViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import Combine

@MainActor
class ServerLessFunctionViewModel: ObservableObject {
    // Published properties replace your @State vars
    @Published var slfTableData: [ServerLessFunctionTableData] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var lastUpdateTime = Date()
    @Published var billingData: [BillingTableData] = []
    @Published var currentBalance = ""
    @Published var currency = ""
    @Published var billingUrl: URL? = nil

    private let api = YandexAPIService.shared
    private let helpers = Helpers.shared
    private var iamToken = ""

    // Computed helpers
    var filteredSLFs: [ServerLessFunctionTableData] {
        guard !searchText.isEmpty else { return slfTableData }
        return slfTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var totalSLFs: Int { slfTableData.count }
    var activeSLFs: Int { slfTableData.filter { $0.status == "ACTIVE" }.count }

    // Public method to load data
    func fetchServerLessFunctions() async {
        isLoading = true
        errorMessage = nil

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
            errorMessage = error.localizedDescription
            isLoading = false
            LoggerHelper.error("Fetch SLFs failed: \(error.localizedDescription)")
        }
    }
}
