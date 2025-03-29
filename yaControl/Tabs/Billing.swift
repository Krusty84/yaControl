//
//  Billing.swift - Yandex Cloud Billing Data (TBD)
//  yaControl
//
//  Created by Sedoykin Alexey on 12/03/2025.
//

import SwiftUI

struct BillingTabContent: View {
    @ObservedObject var yandexApi = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @State private var iamToken: String = ""
    @State private var bucketTableData: [BucketTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedBucket: BucketTableData.ID? = nil
    //
    @State private var sortKey: KeyPath<BucketTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<BucketTableData>] = []
    //
    var filteredBuckets: [BucketTableData] {
        if searchText.isEmpty {
            return bucketTableData
        } else {
            return bucketTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var sortedBuckets: [BucketTableData] {
        return filteredBuckets.sorted(using: sortOrder)
    }
    var totalBuckets: Int {
        return bucketTableData.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
        }
        Text("FFFFF")
    }
}

