//
//  BillingDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct BillingAccountDTO: Decodable {
    let id: String
    let currency: String
    let balance: String
}
