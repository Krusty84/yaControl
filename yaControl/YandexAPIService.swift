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
    func checkOauthKey(yandexPassportOauthToken: String, completion: @escaping (Result<(code: Int, iamToken: String, expiresAt: String), Error>) -> Void) {
        guard let url = URL(string: APIConfig.yaAuthEndpoint) else {
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }
            
            let payload = ["yandexPassportOauthToken": yandexPassportOauthToken]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                completion(.failure(NSError(domain: "Invalid payload", code: -1, userInfo: nil)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check HTTP response code
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                    return
                }
                
                // Check if the status code is successful (e.g., 200)
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
                
                // Parse JSON data
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let iamToken = json["iamToken"] as? String,
                       let expiresAt = json["expiresAt"] as? String {
                        // Return the HTTP status code along with the JSON data
                        completion(.success((code: httpResponse.statusCode, iamToken: iamToken, expiresAt: expiresAt)))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
    
    //MARK: - Get Exists Clouds (step 2)
    func getClouds(iamToken: String, completion: @escaping (Result<(code: Int, clouds: [Cloud]), Error>) -> Void) {
        guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
               completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
               return
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = "GET"
           request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
           
           URLSession.shared.dataTask(with: request) { data, response, error in
               if let error = error {
                   completion(.failure(error))
                   return
               }
               
               // Check HTTP response code
               guard let httpResponse = response as? HTTPURLResponse else {
                   completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                   return
               }
               
               // Check if the status code is successful (e.g., 200)
               guard (200...299).contains(httpResponse.statusCode) else {
                   completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                   return
               }
               
               // Parse JSON data
               guard let data = data else {
                   completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                   return
               }
               
               do {
                   if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let cloudsArray = json["clouds"] as? [[String: Any]] {
                       // Map the JSON array to an array of `Cloud` objects
                       let clouds = cloudsArray.compactMap { cloudDict in
                           Cloud(
                               id: cloudDict["id"] as? String ?? "",
                               createdAt: cloudDict["createdAt"] as? String ?? "",
                               name: cloudDict["name"] as? String ?? "",
                               organizationId: cloudDict["organizationId"] as? String ?? ""
                           )
                       }
                       // Return the HTTP status code along with the list of clouds
                       completion(.success((code: httpResponse.statusCode, clouds: clouds)))
                   } else {
                       completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                   }
               } catch {
                   completion(.failure(error))
               }
           }.resume()
       }
    
    //MARK: - Get Final Virtual Machines Data (step 3.1)
    func getVMs(iamToken: String, completion: @escaping (Result<[VMTableData], Error>) -> Void) {
            // Step 1: Get Clouds
        getClouds(iamToken: iamToken) { result in
            switch result {
            case .success(let response):
                let clouds = response.clouds  // Extract the array from the tuple
                var allVMs: [VMTableData] = []
                let group = DispatchGroup()
                
                for cloud in clouds {
                        group.enter()
                        // Step 2: Get Folders for each Cloud
                        self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
                            switch result {
                            case .success(let folders):
                                for folder in folders {
                                    group.enter()
                                    // Step 3: Get VMs for each Folder
                                    self.getVMInstances(iamToken: iamToken, folderId: folder.id) { result in
                                        switch result {
                                        case .success(let instances):
                                            // First create all VMTableData with their saved states
                                            let vmTableData = instances.map { instance in
                                                let memoryGB = String(Int(instance.resources.memory)! / 1024 / 1024 / 1024)
                                                let addresses = instance.networkInterfaces.compactMap { $0.primaryV4Address.oneToOneNat?.address }
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "HH:mm:ss"
                                                self.lastUpdateTime = dateFormatter.string(from: Date())
                                                SettingsManager.shared.cleanupAutostartSettings(activeVMIds: instance.id)
                                                return VMTableData(
                                                    id: instance.id,
                                                    name: instance.name,
                                                    status: instance.status,
                                                    createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: instance.createdAt),
                                                    cores: instance.resources.cores,
                                                    memoryGB: memoryGB,
                                                    preemptible: instance.schedulingPolicy.preemptible,
                                                    addresses: addresses,
                                                    folderName: folder.name,
                                                    folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
                                                    vmUrl: URL(string: APIConfig.yaVMsWebUrl(folderID: folder.id, instanceID: instance.id)),
                                                    isAutoStarted: SettingsManager.shared.getAutostartedVMs(for: instance.id) // Load before cleanup
                                                )
                                            }
                                            allVMs.append(contentsOf: vmTableData)
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                        group.leave()
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        completion(.success(allVMs))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    //MARK: - Get Final Serverless Functions Data (step 3.2)
    func getServerLessFunctions(iamToken: String, completion: @escaping (Result<[ServerLessFunctionTableData], Error>) -> Void) {
            // Step 1: Get Clouds
            getClouds(iamToken: iamToken) { result in
                switch result {
                case .success(let clouds):
                    var allSLFs: [ServerLessFunctionTableData] = []
                    let group = DispatchGroup()
                    
                    for cloud in clouds {
                        group.enter()
                        // Step 2: Get Folders for each Cloud
                        self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
                            switch result {
                            case .success(let folders):
                                for folder in folders {
                                    group.enter()
                                    // Step 3: Get ServerLess Functions for each Folder
                                    self.getSLFs(iamToken: iamToken, folderId: folder.id) { result in
                                        switch result {
                                        case .success(let functions):
                                            // Map functions to ServerLessFunctionTableData
                                            let functionTableData = functions.map { function in
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "HH:mm:ss"
                                                self.lastUpdateTime = dateFormatter.string(from: Date())
                                                return ServerLessFunctionTableData(
                                                    id: function.id,
                                                    name: function.name,
                                                    status: function.status,
                                                    createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: function.createdAt),
                                                    folderName: folder.name,
                                                    folderUrl: URL(string:APIConfig.yaFoldersWebUrl+folder.id),
                                                    httpInvokeUrl:function.httpInvokeUrl,
                                                    slfUrl:URL(string:APIConfig.yaSLFsWebUrl(folderID: folder.id, slfID: function.id))
                                                )
                                            }
                                            allSLFs.append(contentsOf: functionTableData)
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                        group.leave()
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        completion(.success(allSLFs))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    //MARK: - Get Final Buckets Data (step 3.3)
    func getBuckets(iamToken: String, completion: @escaping (Result<[BucketTableData], Error>) -> Void) {
        // Step 1: Get Clouds
        getClouds(iamToken: iamToken) { result in
            switch result {
            case .success(let cloudResult):
                var allBuckets: [BucketTableData] = []
                let group = DispatchGroup()
                let clouds = cloudResult.clouds
                
                for cloud in clouds {
                    group.enter()
                    // Step 2: Get Folders for each Cloud
                    self.getFolders(iamToken: iamToken, cloudId: cloud.id) { result in
                        switch result {
                        case .success(let folders):
                            for folder in folders {
                                group.enter()
                                // Step 3: Get Buckets for each Folder
                                self.getBuckets(iamToken: iamToken, folderId: folder.id) { result in
                                    switch result {
                                    case .success(let buckets):
                                        for bucket in buckets {
                                            group.enter()
                                            // Step 4: Get Bucket Info (getStats) for each Bucket
                                            self.getBucketInfo(iamToken: iamToken, bucketName: bucket.name) { result in
                                                switch result {
                                                case .success(let bucketInfo):
                                                    // Map bucket and bucketInfo to BucketTableData
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "HH:mm:ss"
                                                    self.lastUpdateTime = dateFormatter.string(from: Date())
                                                    
                                                    let bucketTableData = BucketTableData(
                                                        id: UUID(),
                                                        name: bucketInfo.name,
                                                        maxSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.maxSize),
                                                        usedSize: Helpers.shared.convertBytesToGB(bytes: bucketInfo.usedSize),
                                                        totalObjectCount: bucketInfo.totalObjectCount,
                                                        createdAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.createdAt),
                                                        updatedAt: Helpers.shared.convertGMTToLocalTime(utcDateString: bucketInfo.updatedAt),
                                                        folderName: folder.name,
                                                        folderUrl: URL(string: APIConfig.yaFoldersWebUrl + folder.id),
                                                        bucketUrl: URL(string: APIConfig.yaBucketsWebUrl(folderID: folder.id,bucketName: bucket.name))
                                                    )
                                                    allBuckets.append(bucketTableData)
                                                case .failure(let error):
                                                    completion(.failure(error))
                                                }
                                                group.leave()
                                            }
                                        }
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                    group.leave()
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(allBuckets))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //MARK: - Get Final Billing Data (step 3.4)
    func getCosts(iamToken: String, completion: @escaping (Result<[BillingTableData], Error>) -> Void) {
        self.getBillings(iamToken: iamToken) { result in
            switch result {
            case .success(let billings):
                let billingTableData = billings.map { billing in
                    BillingTableData(
                        id: UUID(),
                        currency: billing.currency,
                        balance: billing.balance,
                        billingUrl: URL(string: APIConfig.yaBillingWebUrl(billingID: billing.id))
                    )
                }
                completion(.success(billingTableData)) // This was missing
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

        
    // MARK: - Helpers
    // Get Raw Exists Clouds Data
    private func getClouds(iamToken: String, completion: @escaping (Result<[Cloud], Error>) -> Void) {
            guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }
                
                // Print raw JSON response for debugging
//                        if let jsonString = String(data: data, encoding: .utf8) {
//                            print("Raw JSON Response (Clouds): \(jsonString)")
//                        }
                        
                
                do {
                    let response = try JSONDecoder().decode([String: [Cloud]].self, from: data)
                    completion(.success(response["clouds"] ?? []))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
        
        // Get Raw Exists Folders in Cloud
        private func getFolders(iamToken: String, cloudId: String, completion: @escaping (Result<[Folder], Error>) -> Void) {
            guard let url = URL(string: "\(APIConfig.yaFoldersEndpoint)?cloudId=\(cloudId)") else {
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }
                
                // Print raw JSON response for debugging
//                        if let jsonString = String(data: data, encoding: .utf8) {
//                            print("Raw JSON Response (Folders): \(jsonString)")
//                        }
//                        
                
                do {
                    let response = try JSONDecoder().decode([String: [Folder]].self, from: data)
                    completion(.success(response["folders"] ?? []))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
        
    // Get Raw Exists VM Instances
    private func getVMInstances(iamToken: String, folderId: String, completion: @escaping (Result<[VMInstance], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)?folderId=\(folderId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Print raw JSON response for debugging
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response (Instances): \(jsonString)")
//            }
            
            do {
                // Try to decode the response as a dictionary
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Check if the response contains an error
                    if let errorDict = json["error"] as? [String: Any],
                       let errorCode = errorDict["code"] as? Int,
                       let errorMessage = errorDict["message"] as? String {
                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(.failure(error))
                        return
                    }
                    
                    // Check if the "instances" key exists
                    if let instancesArray = json["instances"] as? [[String: Any]] {
                        let instances = try JSONDecoder().decode([VMInstance].self, from: JSONSerialization.data(withJSONObject: instancesArray, options: []))
                        completion(.success(instances))
                    } else {
                        // If "instances" key is missing, return an empty array
                        print("No instances found for folderId: \(folderId)")
                        completion(.success([]))
                    }
                } else {
                    print("Error: Invalid JSON format")
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
                }
            } catch {
                print("Decoding Error (Instances): \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // Get Raw Exists Serverless Functions
    private func getSLFs(iamToken: String, folderId: String, completion: @escaping (Result<[ServerLessFunction], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaFunctionsEndpoint)?folderId=\(folderId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Print raw JSON response for debugging
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response (Functions): \(jsonString)")
//            }
            
            do {
                // Try to decode the response as a dictionary
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Check if the response contains an error
                    if let errorDict = json["error"] as? [String: Any],
                       let errorCode = errorDict["code"] as? Int,
                       let errorMessage = errorDict["message"] as? String {
                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(.failure(error))
                        return
                    }
                    
                    // Check if the "functions" key exists
                    if let functionsArray = json["functions"] as? [[String: Any]] {
                        let functions = try JSONDecoder().decode([ServerLessFunction].self, from: JSONSerialization.data(withJSONObject: functionsArray, options: []))
                        completion(.success(functions))
                    } else {
                        // If "functions" key is missing, return an empty array
                        print("No functions found for folderId: \(folderId)")
                        completion(.success([]))
                    }
                } else {
                    print("Error: Invalid JSON format")
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
                }
            } catch {
                print("Decoding Error (Functions): \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Get Raw Exists Buckets
    private func getBuckets(iamToken: String, folderId: String, completion: @escaping (Result<[Bucket], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)?folderId=\(folderId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Print raw JSON response for debugging
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response (Functions): \(jsonString)")
//            }
            
            do {
                // Try to decode the response as a dictionary
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Check if the response contains an error
                    if let errorDict = json["error"] as? [String: Any],
                       let errorCode = errorDict["code"] as? Int,
                       let errorMessage = errorDict["message"] as? String {
                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(.failure(error))
                        return
                    }
                    
                    // Check if the "functions" key exists
                    if let bucketsArray = json["buckets"] as? [[String: Any]] {
                        let buckets = try JSONDecoder().decode([Bucket].self, from: JSONSerialization.data(withJSONObject: bucketsArray, options: []))
                        completion(.success(buckets))
                    } else {
                        // If "functions" key is missing, return an empty array
                        print("No buckets found for folderId: \(folderId)")
                        completion(.success([]))
                    }
                } else {
                    print("Error: Invalid JSON format")
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
                }
            } catch {
                print("Decoding Error (Functions): \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Get Raw Buckets Details
    private func getBucketInfo(iamToken: String, bucketName: String, completion: @escaping (Result<BucketInfo, Error>) -> Void) {
        // Construct the URL
        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)/\(bucketName):getStats") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        // Set up the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        // Perform the data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure data is received
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Print raw JSON response for debugging (optional)
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response: \(jsonString)")
//            }
            
            do {
                // Decode the JSON response into the BucketInfo struct
                let bucketInfo = try JSONDecoder().decode(BucketInfo.self, from: data)
                completion(.success(bucketInfo))
            } catch {
                // Handle decoding errors
                print("Decoding Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Get Raw Exists Billings Data
    private func getBillings(iamToken: String, completion: @escaping (Result<[Billing], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaBillingEndpoint)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Print raw JSON response for debugging
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response (Billing): \(jsonString)")
//            }
            
            do {
                // Try to decode the response as a dictionary
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Check if the response contains an error
                    if let errorDict = json["error"] as? [String: Any],
                       let errorCode = errorDict["code"] as? Int,
                       let errorMessage = errorDict["message"] as? String {
                        let error = NSError(domain: "API Error", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(.failure(error))
                        return
                    }
                    
                    // Check if the "billingAccounts" key exists
                    if let billingsArray = json["billingAccounts"] as? [[String: Any]] {
                        let billings = try JSONDecoder().decode([Billing].self, from: JSONSerialization.data(withJSONObject: billingsArray, options: []))
                        completion(.success(billings))
                    } else {
                        // If "billingAccounts" key is missing, return an empty array
                        print("No billings found")
                        completion(.success([]))
                    }
                } else {
                    print("Error: Invalid JSON format")
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
                }
            } catch {
                print("Decoding Error (Functions): \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Start VM instance
    func startVM(iamToken: String,vmId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):start") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "API Error", code: -1, userInfo: nil)))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
    
    // Stop VM Instance
    func stopVM(iamToken: String,vmId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):stop") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "API Error", code: -1, userInfo: nil)))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
}
