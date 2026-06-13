//
//  CloudSummarySnapshot.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation

struct CloudSummarySnapshot: Codable, Equatable {
    let currentBalance: String
    let currency: String
    let totalVMsCount: Int
    let runningVMsCount: Int
    let totalFunctionsCount: Int
    let activeFunctionsCount: Int
    let totalBucketsCount: Int
    let lastUpdated: Date
    let errorMessage: String?

    static let placeholder = CloudSummarySnapshot(
        currentBalance: "—",
        currency: "",
        totalVMsCount: 0,
        runningVMsCount: 0,
        totalFunctionsCount: 0,
        activeFunctionsCount: 0,
        totalBucketsCount: 0,
        lastUpdated: .now,
        errorMessage: nil
    )
}
