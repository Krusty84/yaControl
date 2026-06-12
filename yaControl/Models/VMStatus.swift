//
//  VMStatus.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum VMStatus: String, Decodable, Equatable {
    case provisioning = "PROVISIONING"
    case running = "RUNNING"
    case stopping = "STOPPING"
    case stopped = "STOPPED"
    case starting = "STARTING"
    case restarting = "RESTARTING"
    case updating = "UPDATING"
    case error = "ERROR"
    case crashed = "CRASHED"
    case deleting = "DELETING"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = VMStatus(rawValue: rawValue) ?? .unknown
    }

    var isRunning: Bool {
        self == .running
    }

    var isStopped: Bool {
        self == .stopped
    }

    var isFailure: Bool {
        self == .error || self == .crashed
    }

    var isActionable: Bool {
        isRunning || isStopped
    }

    var isTransitioning: Bool {
        switch self {
        case .starting, .stopping, .provisioning, .restarting, .updating:
            return true
        case .running, .stopped, .error, .crashed, .deleting, .unknown:
            return false
        }
    }
}
