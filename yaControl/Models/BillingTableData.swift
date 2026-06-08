//
//  BillingTableData.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct BillingTableData: Decodable, Identifiable, Equatable {
    let id: UUID
    let currency: String
    let balance: String
    let billingUrl: URL?
}
