//
//  YandexAPIService.swift - Yandex Cloud Interaction
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import Foundation

class YandexAPIService:ObservableObject {
    static let shared = YandexAPIService() // Singleton for reusability
    @Published var lastUpdateTime: String = ""
    private init() {}
    
    //MARK: - Get IAM token (step 1)
    //  func checkOauthKey(yandexPassportOauthToken: String, completion: @escaping (Result<(code: Int, iamToken: String, expiresAt: String), Error>) -> Void) {
    //        guard let url = URL(string: APIConfig.yaAuthEndpoint) else {
    //                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            let payload = ["yandexPassportOauthToken": yandexPassportOauthToken]
    //            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
    //                completion(.failure(NSError(domain: "Invalid payload", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            var request = URLRequest(url: url)
    //            request.httpMethod = "POST"
    //            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    //            request.httpBody = jsonData
    //
    //            URLSession.shared.dataTask(with: request) { data, response, error in
    //                if let error = error {
    //                    completion(.failure(error))
    //                    return
    //                }
    //
    //                // Check HTTP response code
    //                guard let httpResponse = response as? HTTPURLResponse else {
    //                    completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
    //                    return
    //                }
    //
    //                // Check if the status code is successful (e.g., 200)
    //                guard (200...299).contains(httpResponse.statusCode) else {
    //                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
    //                    return
    //                }
    //
    //                // Parse JSON data
    //                guard let data = data else {
    //                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                    return
    //                }
    //
    //                do {
    //                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
    //                       let iamToken = json["iamToken"] as? String,
    //                       let expiresAt = json["expiresAt"] as? String {
    //                        // Return the HTTP status code along with the JSON data
    //                        completion(.success((code: httpResponse.statusCode, iamToken: iamToken, expiresAt: expiresAt)))
    //                    } else {
    //                        completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
    //                    }
    //                } catch {
    //                    completion(.failure(error))
    //                }
    //            }.resume()
    //        }
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
    //  func getClouds(iamToken: String, completion: @escaping (Result<(code: Int, clouds: [Cloud]), Error>) -> Void) {
    //        guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
    //               completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //               return
    //           }
    //
    //           var request = URLRequest(url: url)
    //           request.httpMethod = "GET"
    //           request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //           URLSession.shared.dataTask(with: request) { data, response, error in
    //               if let error = error {
    //                   completion(.failure(error))
    //                   return
    //               }
    //
    //               // Check HTTP response code
    //               guard let httpResponse = response as? HTTPURLResponse else {
    //                   completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
    //                   return
    //               }
    //
    //               // Check if the status code is successful (e.g., 200)
    //               guard (200...299).contains(httpResponse.statusCode) else {
    //                   completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
    //                   return
    //               }
    //
    //               // Parse JSON data
    //               guard let data = data else {
    //                   completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                   return
    //               }
    //
    //               do {
    //                   if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
    //                      let cloudsArray = json["clouds"] as? [[String: Any]] {
    //                       // Map the JSON array to an array of `Cloud` objects
    //                       let clouds = cloudsArray.compactMap { cloudDict in
    //                           Cloud(
    //                               id: cloudDict["id"] as? String ?? "",
    //                               createdAt: cloudDict["createdAt"] as? String ?? "",
    //                               name: cloudDict["name"] as? String ?? "",
    //                               organizationId: cloudDict["organizationId"] as? String ?? ""
    //                           )
    //                       }
    //                       // Return the HTTP status code along with the list of clouds
    //                       completion(.success((code: httpResponse.statusCode, clouds: clouds)))
    //                   } else {
    //                       completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
    //                   }
    //               } catch {
    //                   completion(.failure(error))
    //               }
    //           }.resume()
    //       }
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
    
    // Get Raw Exists Folders in Cloud
    //  func getFolders(iamToken: String, cloudId: String, completion: @escaping (Result<[Folder], Error>) -> Void) {
    //    guard let url = URL(string: "\(APIConfig.yaFoldersEndpoint)?cloudId=\(cloudId)") else {
    //        completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //        return
    //    }
    //
    //    var request = URLRequest(url: url)
    //    request.httpMethod = "GET"
    //    request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //    URLSession.shared.dataTask(with: request) { data, response, error in
    //        if let error = error {
    //            completion(.failure(error))
    //            return
    //        }
    //
    //        guard let data = data else {
    //            completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        // Print raw JSON response for debugging
    ////                        if let jsonString = String(data: data, encoding: .utf8) {
    ////                            print("Raw JSON Response (Folders): \(jsonString)")
    ////                        }
    ////
    //
    //        do {
    //            let response = try JSONDecoder().decode([String: [Folder]].self, from: data)
    //            completion(.success(response["folders"] ?? []))
    //        } catch {
    //            completion(.failure(error))
    //        }
    //    }.resume()
    //}
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
    //    func getVMs(iamToken: String, completion: @escaping (Result<[VMTableData], Error>) -> Void) {
    //        // Step 1: Get Clouds
    //        getClouds(iamToken: iamToken) { result in
    //            switch result {
    //            case .success(let response):
    //                let clouds = response.clouds
    //                var allVMs: [VMTableData] = []
    //                let group = DispatchGroup()
    //
    //                for cloud in clouds {
    //                    group.enter()
    //                    // Step 2: Get Folders for each Cloud
    //                    self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
    //                        switch result {
    //                        case .success(let folders):
    //                            for folder in folders {
    //                                group.enter()
    //                                // Step 3: Get VMs for each Folder
    //                                self.getVMInstances(iamToken: iamToken, folderId: folder.id) { result in
    //                                    switch result {
    //                                    case .success(let instances):
    //                                        // Create VMTableData with their saved states
    //                                        let vmTableData = instances.map { instance in
    //                                            let memoryGB = String(Int(instance.resources.memory)! / 1024 / 1024 / 1024)
    //                                            let addresses = instance.networkInterfaces.compactMap { $0.primaryV4Address.oneToOneNat?.address }
    //                                            let dateFormatter = DateFormatter()
    //                                            dateFormatter.dateFormat = "HH:mm:ss"
    //                                            self.lastUpdateTime = dateFormatter.string(from: Date())
    //                                            return VMTableData(
    //                                                id: instance.id,
    //                                                name: instance.name,
    //                                                status: instance.status,
    //                                                createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: instance.createdAt),
    //                                                cores: instance.resources.cores,
    //                                                memoryGB: memoryGB,
    //                                                preemptible: instance.schedulingPolicy.preemptible,
    //                                                addresses: addresses,
    //                                                folderName: folder.name,
    //                                                folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
    //                                                vmUrl: URL(string: APIConfig.yaVMsWebUrl(folderID: folder.id, instanceID: instance.id)),
    //                                                isAutoStarted: SettingsManager.shared.getAutostartedVMs(for: instance.id)
    //                                            )
    //                                        }
    //                                        allVMs.append(contentsOf: vmTableData)
    //                                    case .failure(let error):
    //                                        completion(.failure(error))
    //                                    }
    //                                    group.leave()
    //                                }
    //                            }
    //                        case .failure(let error):
    //                            completion(.failure(error))
    //                        }
    //                        group.leave()
    //                    }
    //                }
    //
    //                group.notify(queue: .main) {
    //                    // After collecting all VMs, clean up orphaned settings
    //                    let currentVMIds = Set(allVMs.map { $0.id })
    //                    SettingsManager.shared.cleanupAutostartSettings(validVMIds: currentVMIds)
    //
    //                    completion(.success(allVMs))
    //                }
    //
    //            case .failure(let error):
    //                completion(.failure(error))
    //            }
    //        }
    //    }
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
                                    
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "HH:mm:ss"
                                    self.lastUpdateTime = dateFormatter.string(from: Date())
                                    
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
                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
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
    //    func getServerLessFunctions(iamToken: String, completion: @escaping (Result<[ServerLessFunctionTableData], Error>) -> Void) {
    //            // Step 1: Get Clouds
    //            getClouds(iamToken: iamToken) { result in
    //                switch result {
    //                case .success(let clouds):
    //                    var allSLFs: [ServerLessFunctionTableData] = []
    //                    let group = DispatchGroup()
    //
    //                    for cloud in clouds {
    //                        group.enter()
    //                        // Step 2: Get Folders for each Cloud
    //                        self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
    //                            switch result {
    //                            case .success(let folders):
    //                                for folder in folders {
    //                                    group.enter()
    //                                    // Step 3: Get ServerLess Functions for each Folder
    //                                    self.getSLFs(iamToken: iamToken, folderId: folder.id) { result in
    //                                        switch result {
    //                                        case .success(let functions):
    //                                            // Map functions to ServerLessFunctionTableData
    //                                            let functionTableData = functions.map { function in
    //                                                let dateFormatter = DateFormatter()
    //                                                dateFormatter.dateFormat = "HH:mm:ss"
    //                                                self.lastUpdateTime = dateFormatter.string(from: Date())
    //                                                return ServerLessFunctionTableData(
    //                                                    id: function.id,
    //                                                    name: function.name,
    //                                                    status: function.status,
    //                                                    createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: function.createdAt),
    //                                                    folderName: folder.name,
    //                                                    folderUrl: URL(string:APIConfig.yaFoldersWebUrl+folder.id),
    //                                                    httpInvokeUrl:function.httpInvokeUrl,
    //                                                    slfUrl:URL(string:APIConfig.yaSLFsWebUrl(folderID: folder.id, slfID: function.id))
    //                                                )
    //                                            }
    //                                            allSLFs.append(contentsOf: functionTableData)
    //                                        case .failure(let error):
    //                                            completion(.failure(error))
    //                                        }
    //                                        group.leave()
    //                                    }
    //                                }
    //                            case .failure(let error):
    //                                completion(.failure(error))
    //                            }
    //                            group.leave()
    //                        }
    //                    }
    //
    //                    group.notify(queue: .main) {
    //                        completion(.success(allSLFs))
    //                    }
    //                case .failure(let error):
    //                    completion(.failure(error))
    //                }
    //            }
    //        }
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
                                
                                // Convert to ServerLessFunctionTableData
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "HH:mm:ss"
                                self.lastUpdateTime = dateFormatter.string(from: Date())
                                
                                return functions.map { function in
                                    ServerLessFunctionTableData(
                                        id: function.id,
                                        name: function.name,
                                        status: function.status,
                                        createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: function.createdAt),
                                        folderName: folder.name,
                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
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
    //    func getBuckets(iamToken: String, completion: @escaping (Result<[BucketTableData], Error>) -> Void) {
    //        // Step 1: Get Clouds
    //        getClouds(iamToken: iamToken) { result in
    //            switch result {
    //            case .success(let cloudResult):
    //                var allBuckets: [BucketTableData] = []
    //                let group = DispatchGroup()
    //                let clouds = cloudResult.clouds
    //
    //                for cloud in clouds {
    //                    group.enter()
    //                    // Step 2: Get Folders for each Cloud
    //                    self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
    //                        switch result {
    //                        case .success(let folders):
    //                            for folder in folders {
    //                                group.enter()
    //                                // Step 3: Get Buckets for each Folder
    //                                self.getBuckets(iamToken: iamToken, folderId: folder.id) { result in
    //                                    switch result {
    //                                    case .success(let buckets):
    //                                        for bucket in buckets {
    //                                            group.enter()
    //                                            // Step 4: Get Bucket Info (getStats) for each Bucket
    //                                            self.getBucketInfo(iamToken: iamToken, bucketName: bucket.name) { result in
    //                                                switch result {
    //                                                case .success(let bucketInfo):
    //                                                    // Map bucket and bucketInfo to BucketTableData
    //                                                    let dateFormatter = DateFormatter()
    //                                                    dateFormatter.dateFormat = "HH:mm:ss"
    //                                                    self.lastUpdateTime = dateFormatter.string(from: Date())
    //
    //                                                    let bucketTableData = BucketTableData(
    //                                                        id: UUID(),
    //                                                        name: bucketInfo.name,
    //                                                        maxSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.maxSize),
    //                                                        usedSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.usedSize),
    //                                                        totalObjectCount: bucketInfo.totalObjectCount,
    //                                                        createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.createdAt),
    //                                                        updatedAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.updatedAt),
    //                                                        folderName: folder.name,
    //                                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
    //                                                        bucketUrl: URL(string: APIConfig.yaBucketsWebUrl(folderID: folder.id,bucketName: bucket.name))
    //                                                    )
    //                                                    allBuckets.append(bucketTableData)
    //                                                case .failure(let error):
    //                                                    completion(.failure(error))
    //                                                }
    //                                                group.leave()
    //                                            }
    //                                        }
    //                                    case .failure(let error):
    //                                        completion(.failure(error))
    //                                    }
    //                                    group.leave()
    //                                }
    //                            }
    //                        case .failure(let error):
    //                            completion(.failure(error))
    //                        }
    //                        group.leave()
    //                    }
    //                }
    //
    //                group.notify(queue: .main) {
    //                    completion(.success(allBuckets))
    //                }
    //            case .failure(let error):
    //                completion(.failure(error))
    //            }
    //        }
    //    }
    
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
                                            let dateFormatter = DateFormatter()
                                            dateFormatter.dateFormat = "HH:mm:ss"
                                            self.lastUpdateTime = dateFormatter.string(from: Date())
                                            
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
                                                folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
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
    //    func getCosts(iamToken: String, completion: @escaping (Result<[BillingTableData], Error>) -> Void) {
    //        self.getBillings(iamToken: iamToken) { result in
    //            switch result {
    //            case .success(let billings):
    //                let billingTableData = billings.map { billing in
    //                    BillingTableData(
    //                        id: UUID(),
    //                        currency: billing.currency,
    //                        balance: billing.balance,
    //                        billingUrl: URL(string: APIConfig.yaBillingWebUrl(billingID: billing.id))
    //                    )
    //                }
    //                completion(.success(billingTableData)) // This was missing
    //
    //            case .failure(let error):
    //                completion(.failure(error))
    //            }
    //        }
    //    }
    
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
    // Get Raw Exists Clouds Data
    //    private func getClouds(iamToken: String, completion: @escaping (Result<[Cloud], Error>) -> Void) {
    //            guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
    //                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            var request = URLRequest(url: url)
    //            request.httpMethod = "GET"
    //            request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //            URLSession.shared.dataTask(with: request) { data, response, error in
    //                if let error = error {
    //                    completion(.failure(error))
    //                    return
    //                }
    //
    //                guard let data = data else {
    //                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                    return
    //                }
    //
    //                // Print raw JSON response for debugging
    ////                        if let jsonString = String(data: data, encoding: .utf8) {
    ////                            print("Raw JSON Response (Clouds): \(jsonString)")
    ////                        }
    //
    //
    //                do {
    //                    let response = try JSONDecoder().decode([String: [Cloud]].self, from: data)
    //                    completion(.success(response["clouds"] ?? []))
    //                } catch {
    //                    completion(.failure(error))
    //                }
    //            }.resume()
    //        }
    
    // Get Raw Exists VM Instances
    //    private func getVMInstances(iamToken: String, folderId: String, completion: @escaping (Result<[VMInstance], Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)?folderId=\(folderId)") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "GET"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let data = data else {
    //                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            // Print raw JSON response for debugging
    ////            if let jsonString = String(data: data, encoding: .utf8) {
    ////                print("Raw JSON Response (Instances): \(jsonString)")
    ////            }
    //
    //            do {
    //                // Try to decode the response as a dictionary
    //                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    //                    // Check if the response contains an error
    //                    if let errorDict = json["error"] as? [String: Any],
    //                       let errorCode = errorDict["code"] as? Int,
    //                       let errorMessage = errorDict["message"] as? String {
    //                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    //                        completion(.failure(error))
    //                        return
    //                    }
    //
    //                    // Check if the "instances" key exists
    //                    if let instancesArray = json["instances"] as? [[String: Any]] {
    //                        let instances = try JSONDecoder().decode([VMInstance].self, from: JSONSerialization.data(withJSONObject: instancesArray, options: []))
    //                        completion(.success(instances))
    //                    } else {
    //                        // If "instances" key is missing, return an empty array
    //                        print("No instances found for folderId: \(folderId)")
    //                        completion(.success([]))
    //                    }
    //                } else {
    //                    print("Error: Invalid JSON format")
    //                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
    //                }
    //            } catch {
    //                print("Decoding Error (Instances): \(error)")
    //                completion(.failure(error))
    //            }
    //        }.resume()
    //    }
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
                debugPrint("Decoding Error:", decodingError)
            }
            throw VMInstanceError.decodingError
        }
    }
    
    // Get Raw Exists Serverless Functions
    //    private func getSLFs(iamToken: String, folderId: String, completion: @escaping (Result<[ServerLessFunction], Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaFunctionsEndpoint)?folderId=\(folderId)") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "GET"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let data = data else {
    //                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            // Print raw JSON response for debugging
    ////            if let jsonString = String(data: data, encoding: .utf8) {
    ////                print("Raw JSON Response (Functions): \(jsonString)")
    ////            }
    //
    //            do {
    //                // Try to decode the response as a dictionary
    //                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    //                    // Check if the response contains an error
    //                    if let errorDict = json["error"] as? [String: Any],
    //                       let errorCode = errorDict["code"] as? Int,
    //                       let errorMessage = errorDict["message"] as? String {
    //                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    //                        completion(.failure(error))
    //                        return
    //                    }
    //
    //                    // Check if the "functions" key exists
    //                    if let functionsArray = json["functions"] as? [[String: Any]] {
    //                        let functions = try JSONDecoder().decode([ServerLessFunction].self, from: JSONSerialization.data(withJSONObject: functionsArray, options: []))
    //                        completion(.success(functions))
    //                    } else {
    //                        // If "functions" key is missing, return an empty array
    //                        print("No functions found for folderId: \(folderId)")
    //                        completion(.success([]))
    //                    }
    //                } else {
    //                    print("Error: Invalid JSON format")
    //                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
    //                }
    //            } catch {
    //                print("Decoding Error (Functions): \(error)")
    //                completion(.failure(error))
    //            }
    //        }.resume()
    //    }
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
                debugPrint("Decoding Error:", decodingError)
            }
            throw ServerlessFunctionError.decodingError
        }
    }
    
    // Get Raw Exists Buckets
    //    private func getBuckets(iamToken: String, folderId: String, completion: @escaping (Result<[Bucket], Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)?folderId=\(folderId)") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "GET"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let data = data else {
    //                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            // Print raw JSON response for debugging
    ////            if let jsonString = String(data: data, encoding: .utf8) {
    ////                print("Raw JSON Response (Functions): \(jsonString)")
    ////            }
    //
    //            do {
    //                // Try to decode the response as a dictionary
    //                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    //                    // Check if the response contains an error
    //                    if let errorDict = json["error"] as? [String: Any],
    //                       let errorCode = errorDict["code"] as? Int,
    //                       let errorMessage = errorDict["message"] as? String {
    //                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    //                        completion(.failure(error))
    //                        return
    //                    }
    //
    //                    // Check if the "functions" key exists
    //                    if let bucketsArray = json["buckets"] as? [[String: Any]] {
    //                        let buckets = try JSONDecoder().decode([Bucket].self, from: JSONSerialization.data(withJSONObject: bucketsArray, options: []))
    //                        completion(.success(buckets))
    //                    } else {
    //                        // If "functions" key is missing, return an empty array
    //                        print("No buckets found for folderId: \(folderId)")
    //                        completion(.success([]))
    //                    }
    //                } else {
    //                    print("Error: Invalid JSON format")
    //                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
    //                }
    //            } catch {
    //                print("Decoding Error (Functions): \(error)")
    //                completion(.failure(error))
    //            }
    //        }.resume()
    //    }
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
                debugPrint("Decoding Error:", decodingError)
            }
            throw BucketError.decodingError
        }
    }
    
    // Get Raw Buckets Details
    //    private func getBucketInfo(iamToken: String, bucketName: String, completion: @escaping (Result<BucketInfo, Error>) -> Void) {
    //        // Construct the URL
    //        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)/\(bucketName):getStats") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        // Set up the request
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "GET"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        // Perform the data task
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            // Handle errors
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            // Ensure data is received
    //            guard let data = data else {
    //                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            // Print raw JSON response for debugging (optional)
    ////            if let jsonString = String(data: data, encoding: .utf8) {
    ////                print("Raw JSON Response: \(jsonString)")
    ////            }
    //
    //            do {
    //                // Decode the JSON response into the BucketInfo struct
    //                let bucketInfo = try JSONDecoder().decode(BucketInfo.self, from: data)
    //                completion(.success(bucketInfo))
    //            } catch {
    //                // Handle decoding errors
    //                print("Decoding Error: \(error)")
    //                completion(.failure(error))
    //            }
    //        }.resume()
    //    }
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
            debugPrint("Decoding Error:", error)
            throw BucketInfoError.decodingError(error)
        }
    }
    
    // Get Raw Exists Billings Data
    //    private func getBillings(iamToken: String, completion: @escaping (Result<[Billing], Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaBillingEndpoint)") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "GET"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let data = data else {
    //                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            // Print raw JSON response for debugging
    ////            if let jsonString = String(data: data, encoding: .utf8) {
    ////                print("Raw JSON Response (Billing): \(jsonString)")
    ////            }
    //
    //            do {
    //                // Try to decode the response as a dictionary
    //                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    //                    // Check if the response contains an error
    //                    if let errorDict = json["error"] as? [String: Any],
    //                       let errorCode = errorDict["code"] as? Int,
    //                       let errorMessage = errorDict["message"] as? String {
    //                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    //                        completion(.failure(error))
    //                        return
    //                    }
    //
    //                    // Check if the "billingAccounts" key exists
    //                    if let billingsArray = json["billingAccounts"] as? [[String: Any]] {
    //                        let billings = try JSONDecoder().decode([Billing].self, from: JSONSerialization.data(withJSONObject: billingsArray, options: []))
    //                        completion(.success(billings))
    //                    } else {
    //                        // If "billingAccounts" key is missing, return an empty array
    //                        print("No billings found")
    //                        completion(.success([]))
    //                    }
    //                } else {
    //                    print("Error: Invalid JSON format")
    //                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
    //                }
    //            } catch {
    //                print("Decoding Error (Functions): \(error)")
    //                completion(.failure(error))
    //            }
    //        }.resume()
    //    }
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
                debugPrint("Decoding Error:", decodingError)
            }
            throw BillingError.decodingError
        }
    }
    
    // Start VM instance
    //    func startVM(iamToken: String,vmId: String, completion: @escaping (Result<Void, Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):start") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "POST"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
    //                completion(.failure(NSError(domain: "API Error", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            completion(.success(()))
    //        }.resume()
    //    }
    
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
    
    // Stop VM Instance
    //    func stopVM(iamToken: String,vmId: String, completion: @escaping (Result<Void, Error>) -> Void) {
    //        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):stop") else {
    //            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
    //            return
    //        }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "POST"
    //        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                completion(.failure(error))
    //                return
    //            }
    //
    //            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
    //                completion(.failure(NSError(domain: "API Error", code: -1, userInfo: nil)))
    //                return
    //            }
    //
    //            completion(.success(()))
    //        }.resume()
    //    }
    
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
        
        // Success - implicit Void return
    }
}
