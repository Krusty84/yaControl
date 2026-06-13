//
//  Settings.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation

struct CloudFolderOption: Identifiable, Hashable {
    let id: String
    let name: String
    let cloudId: String
    let status: String

    var displayName: String {
        "\(name) (\(id))"
    }
}
