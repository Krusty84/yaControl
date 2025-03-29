//
//  AutoStartStopVMs.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 29/03/2025.
//
import SwiftUI


class AutoStartStopMVs:ObservableObject {
    static let shared = AutoStartStopMVs()
    @ObservedObject var yandexApi = YandexAPIService.shared
    
    func startAllAutostartedVMs(
        oauthToken: String,
           vmIds: [String],
           isAutostarted: @escaping (String) -> Bool,
           completion: @escaping (Result<Void, Error>) -> Void
       ) {
           // First get IAM token
           yandexApi.checkOauthKey(yandexPassportOauthToken: oauthToken) { authResult in
               switch authResult {
               case .success(let authData):
                   let iamToken = authData.iamToken
                   
                   // Now start all VMs
                   let dispatchGroup = DispatchGroup()
                   var lastError: Error?
                   let autostartedVMs = vmIds.filter { isAutostarted($0) }
                   
                   guard !autostartedVMs.isEmpty else {
                       completion(.success(()))
                       return
                   }
                   
                   for vmId in autostartedVMs {
                       dispatchGroup.enter()
                       
                       self.yandexApi.startVM(iamToken: iamToken, vmId: vmId) { result in
                           switch result {
                           case .failure(let error):
                               lastError = error
                           case .success:
                               break
                           }
                           dispatchGroup.leave()
                       }
                   }
                   
                   dispatchGroup.notify(queue: .main) {
                       if let error = lastError {
                           completion(.failure(error))
                       } else {
                           completion(.success(()))
                       }
                   }
                   
               case .failure(let error):
                   completion(.failure(error))
               }
           }
       }
    
}
