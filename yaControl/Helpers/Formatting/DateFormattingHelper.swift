//
//  DateFormattingHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum DateFormattingHelper {
    static func convertGMTToLocalTime(utcDateString: String) -> String {
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mmZ",
            "yyyy-MM-dd HH:mm:ss Z",
            "yyyy-MM-dd HH:mm Z"
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: utcDateString) {
                dateFormatter.timeZone = TimeZone.current
                dateFormatter.dateFormat = "dd.MM.yy (HH:mm)"
                return dateFormatter.string(from: date)
            }
        }

        LoggerHelper.error("Failed to parse the date string")
        return ""
    }
}
