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
    static let yaFunctionsEndpoint = "https://serverless-functions.api.cloud.yandex.net/functions/v1/functions"
    static let yaBucketsEndpoint = "https://storage.api.cloud.yandex.net/storage/v1/buckets"

    //
    static let yaFoldersWebUrl = "https://console.yandex.cloud/folders/"
    static func yaVMsWebUrl(folderID: String, instanceID: String) -> String {
          return "\(yaFoldersWebUrl)\(folderID)/compute/instance/\(instanceID)/overview"
    }
    static func yaSLFsWebUrl(folderID: String, slfID: String) -> String {
          return "\(yaFoldersWebUrl)\(folderID)/functions/functions/\(slfID)/overview"
    }
    static func yaBucketsWebUrl(folderID: String, bucketName: String) -> String {
          return "\(yaFoldersWebUrl)\(folderID)/storage/buckets/\(bucketName)"
    }
}
//https://console.yandex.cloud/folders/b1gqcrohfu85p2fc6fkc
//https://console.yandex.cloud/folders/b1gqcrohfu85p2fc6fkc/functions/functions/d4e38851c0ofsnkki9f7/overview
//https://console.yandex.cloud/folders/b1gqcrohfu85p2fc6fkc/storage/buckets/archive1
