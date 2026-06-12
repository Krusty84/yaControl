//
//  BillingSummaryService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class BillingSummaryService: @unchecked Sendable {
    static let shared = BillingSummaryService()

    private let billingAPI: YandexBillingAPI

    init(billingAPI: YandexBillingAPI = YandexBillingAPI()) {
        self.billingAPI = billingAPI
    }

    func loadBillingTableData(iamToken: String) async throws -> [BillingTableData] {
        let billings = try await billingAPI.getBillingAccounts(iamToken: iamToken)

        return billings.map { billing in
            BillingTableData(
                id: UUID(),
                currency: billing.currency,
                balance: billing.balance,
                billingUrl: URL(string: APIConfig.yaBillingWebUrl(billingID: billing.id))
            )
        }
    }
}
