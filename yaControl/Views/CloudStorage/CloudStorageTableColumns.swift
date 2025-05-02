//
//  CloudStorageTableColumns.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import AppKit

// 1. Name column: link + hover + copy
struct BucketNameColumn: View {
    let bucket: BucketTableData
    
    var body: some View {
        if let url = bucket.bucketUrl {
            Link(destination: url) {
                Text(bucket.name)
                    .foregroundColor(.blue)
                    .underline()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() }
                else      { NSCursor.pop() }
            }
            .contextMenu {
                Button("Copy name & ID") {
                    let s = "\(bucket.name) (\(bucket.id))"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s, forType: .string)
                }
            }
        } else {
            Text(bucket.name)
        }
    }
}

// 2. Folder column: link + hover
struct BucketFolderColumn: View {
    let bucket: BucketTableData
    
    var body: some View {
        if let url = bucket.folderUrl {
            Link(destination: url) {
                Text(bucket.folderName)
                    .foregroundColor(.blue)
                    .underline()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() }
                else      { NSCursor.pop() }
            }
        } else {
            Text(bucket.folderName)
        }
    }
}
