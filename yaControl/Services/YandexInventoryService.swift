//
//  YandexInventoryService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexInventoryService: @unchecked Sendable {
    static let shared = YandexInventoryService()

    private let resourceManagerAPI: YandexResourceManagerAPI
    private let computeAPI: YandexComputeAPI
    private let storageAPI: YandexStorageAPI
    private let serverlessAPI: YandexServerlessAPI

    init(
        resourceManagerAPI: YandexResourceManagerAPI = YandexResourceManagerAPI(),
        computeAPI: YandexComputeAPI = YandexComputeAPI(),
        storageAPI: YandexStorageAPI = YandexStorageAPI(),
        serverlessAPI: YandexServerlessAPI = YandexServerlessAPI()
    ) {
        self.resourceManagerAPI = resourceManagerAPI
        self.computeAPI = computeAPI
        self.storageAPI = storageAPI
        self.serverlessAPI = serverlessAPI
    }

    func loadVMTableData(iamToken: String) async throws -> [VMTableData] {
        let folders = try await loadFolders(iamToken: iamToken)
        var allVMs: [VMTableData] = []

        try await withThrowingTaskGroup(of: [VMTableData].self) { group in
            for folder in folders {
                group.addTask {
                    let instances = try await self.computeAPI.getVMInstances(
                        iamToken: iamToken,
                        folderId: folder.id
                    )

                    return instances.map { instance in
                        self.makeVMTableData(instance: instance, folder: folder)
                    }
                }
            }

            for try await vms in group {
                allVMs.append(contentsOf: vms)
            }
        }

        let currentVMIds = Set(allVMs.map(\.id))
        SettingsManager.shared.cleanupAutostartSettings(validVMIds: currentVMIds)

        return allVMs
    }

    func loadBucketTableData(iamToken: String) async throws -> [BucketTableData] {
        let folders = try await loadFolders(iamToken: iamToken)
        var allBuckets: [BucketTableData] = []

        try await withThrowingTaskGroup(of: [BucketTableData].self) { group in
            for folder in folders {
                group.addTask {
                    let buckets = try await self.storageAPI.getBuckets(
                        iamToken: iamToken,
                        folderId: folder.id
                    )
                    var folderBuckets: [BucketTableData] = []

                    try await withThrowingTaskGroup(of: BucketTableData.self) { bucketGroup in
                        for bucket in buckets {
                            bucketGroup.addTask {
                                let bucketInfo = try await self.storageAPI.getBucketInfo(
                                    iamToken: iamToken,
                                    bucketName: bucket.name
                                )

                                return self.makeBucketTableData(
                                    bucket: bucket,
                                    bucketInfo: bucketInfo,
                                    folder: folder
                                )
                            }
                        }

                        for try await bucket in bucketGroup {
                            folderBuckets.append(bucket)
                        }
                    }

                    return folderBuckets
                }
            }

            for try await buckets in group {
                allBuckets.append(contentsOf: buckets)
            }
        }

        return allBuckets
    }

    func loadServerlessFunctionTableData(
        iamToken: String
    ) async throws -> [ServerLessFunctionTableData] {
        let folders = try await loadFolders(iamToken: iamToken)
        var allFunctions: [ServerLessFunctionTableData] = []

        try await withThrowingTaskGroup(of: [ServerLessFunctionTableData].self) { group in
            for folder in folders {
                group.addTask {
                    let functions = try await self.serverlessAPI.getFunctions(
                        iamToken: iamToken,
                        folderId: folder.id
                    )

                    return functions.map { function in
                        self.makeServerlessFunctionTableData(function: function, folder: folder)
                    }
                }
            }

            for try await functions in group {
                allFunctions.append(contentsOf: functions)
            }
        }

        return allFunctions
    }

    private func loadFolders(iamToken: String) async throws -> [FolderDTO] {
        let cloudsResponse = try await resourceManagerAPI.getClouds(iamToken: iamToken)
        var folders: [FolderDTO] = []

        try await withThrowingTaskGroup(of: [FolderDTO].self) { group in
            for cloud in cloudsResponse.clouds {
                group.addTask {
                    try await self.resourceManagerAPI.getFolders(
                        iamToken: iamToken,
                        cloudId: cloud.id
                    )
                }
            }

            for try await cloudFolders in group {
                folders.append(contentsOf: cloudFolders)
            }
        }

        return folders
    }

    private func makeVMTableData(instance: VMInstanceDTO, folder: FolderDTO) -> VMTableData {
        let memoryGB: String
        if let memoryBytes = Int64(instance.resources.memory) {
            memoryGB = String(memoryBytes / 1024 / 1024 / 1024)
        } else {
            memoryGB = "N/A"
            LoggerHelper.error("Invalid VM memory value for VM \(instance.id)")
        }

        let addresses = instance.networkInterfaces.compactMap {
            $0.primaryV4Address.oneToOneNat?.address
        }

        return VMTableData(
            id: instance.id,
            name: instance.name,
            status: instance.status,
            createdAt: DateFormattingHelper.convertGMTToLocalTime(utcDateString: instance.createdAt),
            cores: instance.resources.cores,
            memoryGB: memoryGB,
            preemptible: instance.schedulingPolicy.preemptible,
            addresses: addresses,
            folderId: folder.id,
            folderName: folder.name,
            folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id + "/compute/instances"),
            vmUrl: URL(string: APIConfig.yaVMsWebUrl(folderID: folder.id, instanceID: instance.id)),
            isAutoStarted: SettingsManager.shared.getAutostartedVMs(for: instance.id)
        )
    }

    private func makeBucketTableData(
        bucket: BucketDTO,
        bucketInfo: BucketInfoDTO,
        folder: FolderDTO
    ) -> BucketTableData {
        BucketTableData(
            id: UUID(),
            name: bucketInfo.name,
            maxSize: ByteFormattingHelper.convertBytesToGB(bytes: bucketInfo.maxSize),
            usedSize: ByteFormattingHelper.convertBytesToGB(bytes: bucketInfo.usedSize),
            totalObjectCount: bucketInfo.totalObjectCount,
            createdAt: DateFormattingHelper.convertGMTToLocalTime(utcDateString: bucketInfo.createdAt),
            updatedAt: DateFormattingHelper.convertGMTToLocalTime(utcDateString: bucketInfo.updatedAt),
            folderName: folder.name,
            folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id + "/storage/buckets"),
            bucketUrl: URL(string: APIConfig.yaBucketsWebUrl(folderID: folder.id, bucketName: bucket.name))
        )
    }

    private func makeServerlessFunctionTableData(
        function: ServerlessFunctionDTO,
        folder: FolderDTO
    ) -> ServerLessFunctionTableData {
        ServerLessFunctionTableData(
            id: function.id,
            name: function.name,
            status: function.status,
            createdAt: DateFormattingHelper.convertGMTToLocalTime(utcDateString: function.createdAt),
            folderId: folder.id,
            folderName: folder.name,
            folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id + "/functions/functions"),
            httpInvokeUrl: function.httpInvokeUrl,
            slfUrl: URL(string: APIConfig.yaSLFsWebUrl(folderID: folder.id, slfID: function.id))
        )
    }
}
