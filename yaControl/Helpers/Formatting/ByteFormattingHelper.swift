//
//  ByteFormattingHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum ByteFormattingHelper {
    static func convertBytesToGB(bytes: String) -> String {
        guard let bytesValue = Double(bytes) else {
            return "0"
        }

        let bytesInGB: Double = 1024 * 1024 * 1024
        let sizeInGB = bytesValue / bytesInGB
        return String(format: "%.2f", sizeInGB)
    }
}
