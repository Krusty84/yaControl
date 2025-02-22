//
//  APIConfig.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 20/02/2025.
//

import Foundation

struct APIConfig {
    static let yaAuthEndpoint = "https://iam.api.cloud.yandex.net/iam/v1/tokens"
    static let yaCloudsEndpoint = "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/clouds"
    static let yaFoldersEndpoint = "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/folders"
    static let yaVMInstancesEndpoint = "https://compute.api.cloud.yandex.net/compute/v1/instances"
}
