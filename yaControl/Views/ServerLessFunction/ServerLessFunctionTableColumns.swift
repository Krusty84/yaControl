//
//  ServerLessFunctionTableColumns.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import AppKit  // for NSPasteboard and NSCursor

// 1. Name column: a tappable link + copy menu
struct SLFNameColumn: View {
    let slf: ServerLessFunctionTableData

    var body: some View {
        if let url = slf.slfUrl {
            Link(destination: url) {
                Text(slf.name)
                    .foregroundColor(.blue)
                    .underline()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .help(slf.name)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() }
                else       { NSCursor.pop() }
            }
            .contextMenu {
                Button(LocalizedStringKey(L10n.Table.copyNameAndID)) {
                    let s = "\(slf.name) (\(slf.id))"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s, forType: .string)
                }
            }
        } else {
            Text(slf.name)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .help(slf.name)
        }
    }
}



// 2. Status column: colored icon
struct SLFStatusColumn: View {
    let slf: ServerLessFunctionTableData

    var body: some View {
        Image(systemName: slf.status == "ACTIVE"
              ? "arrow.up.square.fill"
              : "arrow.down.square.fill")
        .foregroundColor(slf.status == "ACTIVE" ? .green : .red)
    }
}


// 3. Invoke column: show ID + two menu actions
struct SLFInvokeColumn: View {
    let slf: ServerLessFunctionTableData

    var body: some View {
        Text(slf.id)
            .contextMenu {
                Button(LocalizedStringKey(L10n.Table.copyInvokeURL)) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(slf.httpInvokeUrl,
                                                   forType: .string)
                }

                Button(LocalizedStringKey(L10n.Table.copyYCCommand)) {
                    let cmd = "yc serverless function invoke \(slf.id)"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    //May be it will not be good for App Store review
                    //TerminalLauncher.openTerminal()
                }
                .disabled(!SettingsManager.shared.ycCLIInstalled)
            }
    }
}



// 4. Folder column: link to folder + hover effect
struct SLFFolderColumn: View {
    let slf: ServerLessFunctionTableData

    var body: some View {
        if let url = slf.folderUrl {
            Link(destination: url) {
                Text(slf.folderName)
                    .foregroundColor(.blue)
                    .underline()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() }
                else      { NSCursor.pop() }
            }
        } else {
            Text(slf.folderName)
        }
    }
}
