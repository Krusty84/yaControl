//
//  YandexAPIService.swift - Yandex Cloud compatibility facade
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import Foundation

final class YandexAPIService: @unchecked Sendable {
    static let shared = YandexAPIService()

    private let authAPI: YandexAuthAPI
    private let resourceManagerAPI: YandexResourceManagerAPI
    private let inventoryService: YandexInventoryService
    private let vmPowerService: VMPowerService
    private let billingService: BillingSummaryService

    private init(
        authAPI: YandexAuthAPI = YandexAuthAPI(),
        resourceManagerAPI: YandexResourceManagerAPI = YandexResourceManagerAPI(),
        inventoryService: YandexInventoryService = .shared,
        vmPowerService: VMPowerService = .shared,
        billingService: BillingSummaryService = .shared
    ) {
        self.authAPI = authAPI
        self.resourceManagerAPI = resourceManagerAPI
        self.inventoryService = inventoryService
        self.vmPowerService = vmPowerService
        self.billingService = billingService
    }

    func checkOauthKey(yandexPassportOauthToken: String) async throws -> AuthResponse {
        try await authAPI.checkOAuthToken(yandexPassportOauthToken)
    }

    func getClouds(iamToken: String) async throws -> CloudsResponse {
        try await resourceManagerAPI.getClouds(iamToken: iamToken)
    }

    func getFolders(iamToken: String, cloudId: String) async throws -> [FolderDTO] {
        try await resourceManagerAPI.getFolders(iamToken: iamToken, cloudId: cloudId)
    }

    func getVMs(iamToken: String) async throws -> [VMTableData] {
        try await inventoryService.loadVMTableData(iamToken: iamToken)
    }

    func getBuckets(iamToken: String) async throws -> [BucketTableData] {
        try await inventoryService.loadBucketTableData(iamToken: iamToken)
    }

    func getServerLessFunctions(iamToken: String) async throws -> [ServerLessFunctionTableData] {
        try await inventoryService.loadServerlessFunctionTableData(iamToken: iamToken)
    }

    func getCosts(iamToken: String) async throws -> [BillingTableData] {
        try await billingService.loadBillingTableData(iamToken: iamToken)
    }

    func startVM(iamToken: String, vmId: String) async throws {
        try await vmPowerService.startVM(iamToken: iamToken, vmId: vmId)
    }

    func stopVM(iamToken: String, vmId: String) async throws {
        try await vmPowerService.stopVM(iamToken: iamToken, vmId: vmId)
    }
}
