//
//  APIConfig.swift - Yandex Cloud Endpoints
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
    static let yaBillingEndpoint = "https://billing.api.cloud.yandex.net/billing/v1/billingAccounts"
    static let yaBillingConsoleUrl = "https://center.yandex.cloud/billing/accounts"
    static let yaGetOAuthKey = "https://yandex.cloud/en-ru/docs/iam/concepts/authorization/oauth-token"
    static let yaGetYCCLI = "https://yandex.cloud/en/docs/cli/operations/install-cli"

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
    static func yaBillingWebUrl(billingID: String) -> String {
        return "\(yaBillingConsoleUrl)/\(billingID)/overview"
    }
}

