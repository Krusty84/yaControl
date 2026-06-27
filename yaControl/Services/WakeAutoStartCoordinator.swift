//
//  WakeAutoStartCoordinator.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import Foundation

actor WakeAutoStartCoordinator {
    static let shared = WakeAutoStartCoordinator()

    private var activeTask: Task<Void, Never>?

    func start(work: @escaping @Sendable () async -> Void) {
        activeTask?.cancel()
        activeTask = Task {
            LoggerHelper.info("Wake auto-start workflow started")
            await work()
        }
    }

    func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    func waitForActiveTask() async {
        await activeTask?.value
    }
}
