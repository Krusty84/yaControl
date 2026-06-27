//
//  InternetConnectionMonitor.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation
import Network

enum InternetConnectionMonitor {
    static func runWhenConnected(_ completion: @escaping @MainActor @Sendable () -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                LoggerHelper.info("Internet access is available")
                Task { @MainActor in
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

    static func waitUntilConnected(timeout: Duration) async -> Bool {
        let stateBox = InternetConnectionWaitStateBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let monitor = NWPathMonitor()
                let queue = DispatchQueue(label: "InternetConnectionMonitor")
                let state = InternetConnectionWaitState(
                    monitor: monitor,
                    continuation: continuation
                )

                stateBox.setState(state)

                let timeoutTask = Task {
                    do {
                        try await Task.sleep(for: timeout)
                        LoggerHelper.error("Internet connection wait timed out")
                        state.finish(false)
                    } catch {
                        state.finish(false)
                    }
                }

                state.setTimeoutTask(timeoutTask)

                monitor.pathUpdateHandler = { path in
                    if path.status == .satisfied {
                        LoggerHelper.info("Internet access is available")
                        state.finish(true)
                    } else {
                        LoggerHelper.error("The Internet access does not work")
                    }
                }

                monitor.start(queue: queue)
            }
        } onCancel: {
            stateBox.cancel()
        }
    }
}

private final class InternetConnectionWaitStateBox: @unchecked Sendable {
    private let lock = NSLock()
    private var state: InternetConnectionWaitState?

    func setState(_ state: InternetConnectionWaitState) {
        lock.lock()
        self.state = state
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let state = state
        lock.unlock()

        state?.finish(false)
    }
}

private final class InternetConnectionWaitState: @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let continuation: CheckedContinuation<Bool, Never>
    private let lock = NSLock()
    private var didFinish = false
    private var timeoutTask: Task<Void, Never>?

    init(
        monitor: NWPathMonitor,
        continuation: CheckedContinuation<Bool, Never>
    ) {
        self.monitor = monitor
        self.continuation = continuation
    }

    func setTimeoutTask(_ task: Task<Void, Never>) {
        lock.lock()
        timeoutTask = task
        lock.unlock()
    }

    func finish(_ isConnected: Bool) {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        let timeoutTask = timeoutTask
        lock.unlock()

        timeoutTask?.cancel()
        monitor.cancel()
        continuation.resume(returning: isConnected)
    }
}
