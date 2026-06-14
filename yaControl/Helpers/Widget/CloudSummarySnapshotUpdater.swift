//
//  CloudSummarySnapshotUpdater.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 14/06/2026.
//

import Foundation
import WidgetKit

struct CloudSummarySnapshotUpdater: Sendable {
    static let shared = CloudSummarySnapshotUpdater()

    func refreshSnapshot() async {
        do {
            let api = YandexAPIService.shared
            let auth = try await api.checkOauthKey(
                yandexPassportOauthToken: SettingsManager.shared.oAuthKey
            )
            let token = auth.iamToken

            async let vms = api.getVMs(iamToken: token)
            async let functions = api.getServerLessFunctions(iamToken: token)
            async let buckets = api.getBuckets(iamToken: token)
            async let bills = api.getCosts(iamToken: token)

            let (vmsData, functionsData, bucketsData, billsData) = try await (
                vms,
                functions,
                buckets,
                bills
            )

            let firstBill = billsData.first
            let snapshot = CloudSummarySnapshot(
                currentBalance: firstBill?.balance ?? "—",
                currency: firstBill?.currency ?? "",
                totalVMsCount: vmsData.count,
                runningVMsCount: vmsData.filter { $0.status.isRunning }.count,
                totalFunctionsCount: functionsData.count,
                activeFunctionsCount: functionsData.filter { $0.status == "ACTIVE" }.count,
                totalBucketsCount: bucketsData.count,
                lastUpdated: .now,
                errorMessage: nil
            )

            try CloudSummarySnapshotStore.shared.save(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: CloudSummaryWidgetKind.cloudSummary)
 
        } catch {
            LoggerHelper.error("Failed to refresh widget snapshot: \(error.localizedDescription)")
        }
    }
}
