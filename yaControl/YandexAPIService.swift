//
//  YandexAPIService.swift - Yandex Cloud Interaction
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import Foundation

class YandexAPIService:ObservableObject {
    static let shared = YandexAPIService() // Singleton for reusability
    //@Published var lastUpdateTime: String = ""
    @Published var lastUpdateTime = Date ()
    private init() {}
    
    //MARK: - Get IAM token (step 1)
        
    func checkOauthKey(yandexPassportOauthToken: String) async throws -> AuthResponse {
        guard let url = URL(string: APIConfig.yaAuthEndpoint) else {
            throw AuthError.invalidURL
        }
        
        let payload = ["yandexPassportOauthToken": yandexPassportOauthToken]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.httpError(statusCode: httpResponse.statusCode)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let iamToken = json["iamToken"] as? String,
           let expiresAt = json["expiresAt"] as? String {
            return AuthResponse(code: httpResponse.statusCode, iamToken: iamToken, expiresAt: expiresAt)
        } else {
            throw AuthError.invalidResponseFormat
        }
    }
    
    //MARK: - Get Exists Clouds (step 2)
        
    func getClouds(iamToken: String) async throws -> CloudsResponse {
        // 1. Validate URL
        guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
            throw CloudError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw CloudError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            let decoder = JSONDecoder()
            // If the response has a root "clouds" key
            let response = try decoder.decode([String: [Cloud]].self, from: data)
            guard let clouds = response["clouds"] else {
                throw CloudError.invalidResponseFormat
            }
            return CloudsResponse(code: httpResponse.statusCode, clouds: clouds)
        } catch {
            throw CloudError.invalidResponseFormat
        }
    }
        
    func getFolders(iamToken: String, cloudId: String) async throws -> [Folder] {
        // 1. Construct URL with query parameter
        guard var urlComponents = URLComponents(string: APIConfig.yaFoldersEndpoint) else {
            throw FolderError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "cloudId", value: cloudId)]
        
        guard let url = urlComponents.url else {
            throw FolderError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FolderError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw FolderError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // If you want to keep the debug print, uncomment this:
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            let response = try JSONDecoder().decode([String: [Folder]].self, from: data)
            return response["folders"] ?? []
        } catch {
            throw FolderError.decodingError
        }
    }
    
    
    
    //MARK: - Get Final Virtual Machines Data (step 3.1)
        
    func getVMs(iamToken: String) async throws -> [VMTableData] {
        // Step 1: Get Clouds
        let cloudsResponse = try await getClouds(iamToken: iamToken)
        let clouds = cloudsResponse.clouds
        
        var allVMs: [VMTableData] = []
        
        // Process each cloud concurrently
        try await withThrowingTaskGroup(of: [VMTableData].self) { group in
            for cloud in clouds {
                group.addTask {
                    // Step 2: Get Folders for each Cloud
                    let folders = try await self.getFolders(iamToken: iamToken, cloudId: cloud.id)
                    var cloudVMs: [VMTableData] = []
                    
                    // Process each folder concurrently
                    try await withThrowingTaskGroup(of: [VMTableData].self) { innerGroup in
                        for folder in folders {
                            innerGroup.addTask {
                                // Step 3: Get VMs for each Folder
                                let instances = try await self.getVMInstances(iamToken: iamToken, folderId: folder.id)
                                
                                // Convert to VMTableData
                                return instances.map { instance in
                                    let memoryGB = String(Int(instance.resources.memory)! / 1024 / 1024 / 1024)
                                    let addresses = instance.networkInterfaces.compactMap {
                                        $0.primaryV4Address.oneToOneNat?.address
                                    }
                                  //  self.lastUpdateTime = Date ()
                                    
                                    DispatchQueue.main.async {
                                        self.lastUpdateTime = Date()
                                    }
                                    
                                    return VMTableData(
                                        id: instance.id,
                                        name: instance.name,
                                        status: instance.status,
                                        createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: instance.createdAt),
                                        cores: instance.resources.cores,
                                        memoryGB: String(memoryGB),
                                        preemptible: instance.schedulingPolicy.preemptible,
                                        addresses: addresses,
                                        folderName: folder.name,
                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id+"/compute/instances"),
                                        vmUrl: URL(string: APIConfig.yaVMsWebUrl(folderID: folder.id, instanceID: instance.id)),
                                        isAutoStarted: SettingsManager.shared.getAutostartedVMs(for: instance.id)
                                    )
                                }
                            }
                        }
                        
                        // Collect results from all folder tasks
                        for try await vms in innerGroup {
                            cloudVMs.append(contentsOf: vms)
                        }
                    }
                    
                    return cloudVMs
                }
            }
            
            // Collect results from all cloud tasks
            for try await vms in group {
                allVMs.append(contentsOf: vms)
            }
        }
        
        // Clean up orphaned settings
        let currentVMIds = Set(allVMs.map { $0.id })
        SettingsManager.shared.cleanupAutostartSettings(validVMIds: currentVMIds)
        
        return allVMs
    }
    
    //MARK: - Get Final Serverless Functions Data (step 3.2)
        
    func getServerLessFunctions(iamToken: String) async throws -> [ServerLessFunctionTableData] {
        // Step 1: Get Clouds
        let cloudsResponse = try await getClouds(iamToken: iamToken)
        let clouds = cloudsResponse.clouds
        
        var allSLFs: [ServerLessFunctionTableData] = []
        
        // Process each cloud concurrently
        try await withThrowingTaskGroup(of: [ServerLessFunctionTableData].self) { group in
            for cloud in clouds {
                group.addTask {
                    // Step 2: Get Folders for each Cloud
                    let folders = try await self.getFolders(iamToken: iamToken, cloudId: cloud.id)
                    var cloudSLFs: [ServerLessFunctionTableData] = []
                    
                    // Process each folder concurrently
                    try await withThrowingTaskGroup(of: [ServerLessFunctionTableData].self) { innerGroup in
                        for folder in folders {
                            innerGroup.addTask {
                                // Step 3: Get Serverless Functions for each Folder
                                let functions = try await self.getSLFs(iamToken: iamToken, folderId: folder.id)
                                
                                //self.lastUpdateTime = Date ()
                                
                                DispatchQueue.main.async {
                                    self.lastUpdateTime = Date ()
                                       }
                                
                                return functions.map { function in
                                    ServerLessFunctionTableData(
                                        id: function.id,
                                        name: function.name,
                                        status: function.status,
                                        createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: function.createdAt),
                                        folderName: folder.name,
                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id+"/functions/functions"),
                                        httpInvokeUrl: function.httpInvokeUrl,
                                        slfUrl: URL(string: APIConfig.yaSLFsWebUrl(folderID: folder.id, slfID: function.id))
                                    )
                                }
                            }
                        }
                        
                        // Collect results from all folder tasks
                        for try await slfs in innerGroup {
                            cloudSLFs.append(contentsOf: slfs)
                        }
                    }
                    
                    return cloudSLFs
                }
            }
            
            // Collect results from all cloud tasks
            for try await slfs in group {
                allSLFs.append(contentsOf: slfs)
            }
        }
        
        return allSLFs
    }
    
    //MARK: - Get Final Buckets Data (step 3.3)
    
    func getBuckets(iamToken: String) async throws -> [BucketTableData] {
        // Step 1: Get Clouds
        let cloudsResponse = try await getClouds(iamToken: iamToken)
        let clouds = cloudsResponse.clouds
        
        var allBuckets: [BucketTableData] = []
        
        // Process each cloud concurrently
        try await withThrowingTaskGroup(of: [BucketTableData].self) { group in
            for cloud in clouds {
                group.addTask {
                    // Step 2: Get Folders for each Cloud
                    let folders = try await self.getFolders(iamToken: iamToken, cloudId: cloud.id)
                    var cloudBuckets: [BucketTableData] = []
                    
                    // Process each folder concurrently
                    try await withThrowingTaskGroup(of: [BucketTableData].self) { innerGroup in
                        for folder in folders {
                            innerGroup.addTask {
                                // Step 3: Get Buckets for each Folder
                                let buckets = try await self.getBuckets(iamToken: iamToken, folderId: folder.id)
                                var folderBuckets: [BucketTableData] = []
                                
                                // Process each bucket concurrently
                                try await withThrowingTaskGroup(of: BucketTableData.self) { bucketGroup in
                                    for bucket in buckets {
                                        bucketGroup.addTask {
                                            // Step 4: Get Bucket Info for each Bucket
                                            let bucketInfo = try await self.getBucketInfo(iamToken: iamToken, bucketName: bucket.name)
                                            
                                            // Update last update time
                                            //self.lastUpdateTime = Date ()
                                            
                                            DispatchQueue.main.async {
                                                self.lastUpdateTime = Date ()
                                                   }
                                            
                                            // Create BucketTableData
                                            return BucketTableData(
                                                id: UUID(),
                                                name: bucketInfo.name,
                                                maxSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.maxSize),
                                                usedSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.usedSize),
                                                totalObjectCount: bucketInfo.totalObjectCount,
                                                createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.createdAt),
                                                updatedAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.updatedAt),
                                                folderName: folder.name,
                                                folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id+"/storage/buckets"),
                                                bucketUrl: URL(string: APIConfig.yaBucketsWebUrl(folderID: folder.id, bucketName: bucket.name))
                                            )
                                        }
                                    }
                                    
                                    // Collect bucket results
                                    for try await bucketTableData in bucketGroup {
                                        folderBuckets.append(bucketTableData)
                                    }
                                }
                                
                                return folderBuckets
                            }
                        }
                        
                        // Collect folder results
                        for try await buckets in innerGroup {
                            cloudBuckets.append(contentsOf: buckets)
                        }
                    }
                    
                    return cloudBuckets
                }
            }
            
            // Collect cloud results
            for try await buckets in group {
                allBuckets.append(contentsOf: buckets)
            }
        }
        
        return allBuckets
    }
    
    //MARK: - Get Final Billing Data (step 3.4)

    func getCosts(iamToken: String) async throws -> [BillingTableData] {
        // Get billings using async/await
        let billings = try await self.getBillings(iamToken: iamToken)
        
        // Transform to BillingTableData
        return billings.map { billing in
            BillingTableData(
                id: UUID(),
                currency: billing.currency,
                balance: billing.balance,
                billingUrl: URL(string: APIConfig.yaBillingWebUrl(billingID: billing.id))
            )
        }
    }
    
    // MARK: - Helpers

    private func getVMInstances(iamToken: String, folderId: String) async throws -> [VMInstance] {
        // 1. Construct URL with query parameter
        guard var urlComponents = URLComponents(string: APIConfig.yaVMInstancesEndpoint) else {
            throw VMInstanceError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "folderId", value: folderId)]
        
        guard let url = urlComponents.url else {
            throw VMInstanceError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VMInstanceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw VMInstanceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // For debugging (uncomment if needed)
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            // First check if the response contains an error
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let errorCode = errorDict["code"] as? Int,
               let errorMessage = errorDict["message"] as? String {
                throw VMInstanceError.apiError(code: errorCode, message: errorMessage)
            }
            
            // Try to decode the instances array
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let instancesArray = json["instances"] as? [[String: Any]] {
                
                let instancesData = try JSONSerialization.data(withJSONObject: instancesArray)
                return try JSONDecoder().decode([VMInstance].self, from: instancesData)
            } else {
                // No instances found - return empty array
                return []
            }
        } catch {
            if let decodingError = error as? DecodingError {
                //debugPrint("Decoding Error:", decodingError)
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw VMInstanceError.decodingError
        }
    }
    
    private func getSLFs(iamToken: String, folderId: String) async throws -> [ServerLessFunction] {
        // 1. Construct URL with query parameter
        guard var urlComponents = URLComponents(string: APIConfig.yaFunctionsEndpoint) else {
            throw ServerlessFunctionError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "folderId", value: folderId)]
        
        guard let url = urlComponents.url else {
            throw ServerlessFunctionError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerlessFunctionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServerlessFunctionError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // Debugging (uncomment if needed)
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            // First check for API errors
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let errorCode = errorDict["code"] as? Int,
               let errorMessage = errorDict["message"] as? String {
                throw ServerlessFunctionError.apiError(code: errorCode, message: errorMessage)
            }
            
            // Try to decode the functions array
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let functionsArray = json["functions"] as? [[String: Any]] {
                
                let functionsData = try JSONSerialization.data(withJSONObject: functionsArray)
                return try JSONDecoder().decode([ServerLessFunction].self, from: functionsData)
            } else {
                // No functions found - return empty array
                return []
            }
        } catch {
            if let decodingError = error as? DecodingError {
                //debugPrint("Decoding Error:", decodingError)
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw ServerlessFunctionError.decodingError
        }
    }
    
    private func getBuckets(iamToken: String, folderId: String) async throws -> [Bucket] {
        // 1. Construct URL with query parameter
        guard var urlComponents = URLComponents(string: APIConfig.yaBucketsEndpoint) else {
            throw BucketError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "folderId", value: folderId)]
        
        guard let url = urlComponents.url else {
            throw BucketError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BucketError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BucketError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // Debugging (uncomment if needed)
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            // First check for API errors
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let errorCode = errorDict["code"] as? Int,
               let errorMessage = errorDict["message"] as? String {
                throw BucketError.apiError(code: errorCode, message: errorMessage)
            }
            
            // Try to decode the buckets array
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let bucketsArray = json["buckets"] as? [[String: Any]] {
                
                let bucketsData = try JSONSerialization.data(withJSONObject: bucketsArray)
                return try JSONDecoder().decode([Bucket].self, from: bucketsData)
            } else {
                // No buckets found - return empty array
                return []
            }
        } catch {
            if let decodingError = error as? DecodingError {
                //debugPrint("Decoding Error:", decodingError)
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw BucketError.decodingError
        }
    }
    
    private func getBucketInfo(iamToken: String, bucketName: String) async throws -> BucketInfo {
        // 1. Construct URL
        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)/\(bucketName):getStats") else {
            throw BucketInfoError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BucketInfoError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BucketInfoError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // Debugging (uncomment if needed)
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            return try JSONDecoder().decode(BucketInfo.self, from: data)
        } catch {
            //debugPrint("Decoding Error:", error)
            LoggerHelper.error("Decoding Error: \(error)")
            throw BucketInfoError.decodingError(error)
        }
    }
    
    private func getBillings(iamToken: String) async throws -> [Billing] {
        // 1. Construct URL
        guard let url = URL(string: APIConfig.yaBillingEndpoint) else {
            throw BillingError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BillingError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BillingError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 5. Parse JSON
        do {
            // Debugging (uncomment if needed)
            // debugPrint("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            
            // First check for API errors
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let errorCode = errorDict["code"] as? Int,
               let errorMessage = errorDict["message"] as? String {
                throw BillingError.apiError(code: errorCode, message: errorMessage)
            }
            
            // Try to decode the billings array
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let billingsArray = json["billingAccounts"] as? [[String: Any]] {
                
                let billingsData = try JSONSerialization.data(withJSONObject: billingsArray)
                return try JSONDecoder().decode([Billing].self, from: billingsData)
            } else {
                // No billings found - return empty array
                return []
            }
        } catch {
            if let decodingError = error as? DecodingError {
                //debugPrint("Decoding Error:", decodingError)
                LoggerHelper.error("Decoding Error: \(decodingError)")
                
            }
            throw BillingError.decodingError
        }
    }
    
    func startVM(iamToken: String, vmId: String) async throws {
        // 1. Construct URL
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):start") else {
            throw VMOperationError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VMOperationError.operationFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            throw VMOperationError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Implicit return of Void on success
    }
        
    func stopVM(iamToken: String, vmId: String) async throws {
        // 1. Construct URL
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):stop") else {
            throw VMOperationError.invalidURL
        }
        
        // 2. Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Make network request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VMOperationError.operationFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            throw VMOperationError.apiError(statusCode: httpResponse.statusCode)
        }
    }
}
