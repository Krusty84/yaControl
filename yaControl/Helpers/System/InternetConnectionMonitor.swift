//
//  InternetConnectionMonitor.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation
import Network

enum InternetConnectionMonitor {
    static func runWhenConnected(_ completion: @escaping () -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                LoggerHelper.info("Internet access is available")
                DispatchQueue.main.async {
                    completion()
                }
                monitor.cancel()
            } else {
                LoggerHelper.error("The Internet access does not work")
            }
        }

        monitor.start(queue: queue)
    }

    static func waitUntilConnected() async {
        await withCheckedContinuation { continuation in
            runWhenConnected {
                continuation.resume()
            }
        }
    }
}
