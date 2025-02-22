//
//  YandexAPIService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import Foundation

class YandexAPIService {
    static let shared = YandexAPIService() // Singleton for reusability
    
    private init() {}
    
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
    
    func getVMs(iamToken: String, completion: @escaping (Result<[VMTableData], Error>) -> Void) {
            // Step 1: Get Clouds
            getClouds(iamToken: iamToken) { result in
                switch result {
                case .success(let clouds):
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
                                    // Step 3: Get Instances for each Folder
                                    self.getInstances(iamToken: iamToken, folderId: folder.id) { result in
                                        switch result {
                                        case .success(let instances):
                                            // Map instances to VMTableData
                                            let vmTableData = instances.map { instance in
                                                let memoryGB = String(Int(instance.resources.memory)! / 1024 / 1024 / 1024)
                                                let addresses = instance.networkInterfaces.map { $0.primaryV4Address.address }
                                                return VMTableData(
                                                    name: instance.name,
                                                    status: instance.status,
                                                    createdAt: instance.createdAt,
                                                    cores: instance.resources.cores,
                                                    memoryGB: memoryGB,
                                                    preemptible: instance.schedulingPolicy.preemptible,
                                                    addresses: addresses,
                                                    folderName: folder.name
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
        
        // Helper function to get Clouds
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
        
        // Helper function to get Folders
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
        
        // Helper function to get Instances
//        private func getInstances(iamToken: String, folderId: String, completion: @escaping (Result<[VMInstance], Error>) -> Void) {
//            guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)?folderId=\(folderId)") else {
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
//                        if let jsonString = String(data: data, encoding: .utf8) {
//                            print("Raw JSON Response (VMs): \(jsonString)")
//                        }
//                        
//                
//                
//                do {
//                    let response = try JSONDecoder().decode([String: [VMInstance]].self, from: data)
//                    completion(.success(response["instances"] ?? []))
//                } catch {
//                    completion(.failure(error))
//                }
//            }.resume()
//        }
    
    private func getInstances(iamToken: String, folderId: String, completion: @escaping (Result<[VMInstance], Error>) -> Void) {
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
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response (Instances): \(jsonString)")
            }
            
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
    
    }
