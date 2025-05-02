//
//  CloudComputingTableColumns.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import AppKit

struct VMAutoStartColumn: View {
    let vm: VMTableData
    let isOn: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle("", isOn: Binding(
            get: { isOn },
            set: { onToggle($0) }
        ))
        .toggleStyle(CheckboxToggleStyle())
        .help("Auto power management")
    }
}

struct VMNameColumn: View {
    let vm: VMTableData

    var body: some View {
        if let url = vm.vmUrl {
            Link(destination: url) {
                Text(vm.name)
                    .foregroundColor(.blue)
                    .underline()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .help(vm.name)                      // <-- tooltip here
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hover in
                if hover { NSCursor.pointingHand.push() }
                else   { NSCursor.pop() }
            }
            .contextMenu {
                Button("Copy name & ID") {
                    let s = "\(vm.name) (\(vm.id))"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s, forType: .string)
                }
            }
        } else {
            Text(vm.name)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .help(vm.name)                      // <-- tooltip here too
        }
    }
}



struct VMStatusColumn: View {
    let vm: VMTableData
    let isProcessing: Bool
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            Image(systemName: isProcessing ? "arrow.triangle.2.circlepath" : statusIcon)
                .foregroundColor(statusColor)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing)
    }

    private var statusIcon: String {
        switch vm.status {
            case "RUNNING": "stop.fill"
            case "STOPPED": "play.fill"
            case "STARTING", "STOPPING", "PROVISIONING", "RESTARTING","UPDATING": "arrow.triangle.2.circlepath"
            case "ERROR": "exclamationmark.triangle.fill"
            case "CRASHED": "exclamationmark.octagon.fill"
            default: "questionmark"
        }
    }

    private var statusColor: Color {
        switch vm.status {
            case "RUNNING": .red
            case "STOPPED": .green
            case "STARTING", "STOPPING", "PROVISIONING", "RESTARTING","UPDATING":.gray
            case "ERROR", "CRASHED": .orange
            default: .gray
        }
    }
}

struct VMPublicIPColumn: View {
    let vm: VMTableData

    var body: some View {
        Text(vm.addresses.joined(separator: ", "))
            .fixedSize(horizontal: false, vertical: true)
            .contextMenu {
                Button("Copy IPs") {
                    let s = vm.addresses.joined(separator: ", ")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s, forType: .string)
                }
                if let ipAddress = vm.addresses.first {
                    Button(action: {
                        let cmd = "ssh -l \(SettingsManager.shared.generalUsername4VMs) \(ipAddress)"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cmd, forType: .string)
                        Helpers.shared.openTerminal()
                    }) {
                        Text(SettingsManager.shared.generalUsername4VMs.isEmpty ? "Go to settings to set username" : "Open SSH")
                    }
                    .disabled(SettingsManager.shared.generalUsername4VMs.isEmpty)
                    
                    Button("Open RDP") {
                        Helpers.shared.openRDPClient(to: ipAddress,
                                                    username: SettingsManager.shared.generalUsername4VMs)
                    }
                    //.disabled(SettingsManager.shared.generalUsername4VMs.isEmpty)
                }
            }
    }
}

struct VMFolderColumn: View {
    let vm: VMTableData

    var body: some View {
        if let url = vm.folderUrl {
            Link(destination: url) {
                Text(vm.folderName)
                    .foregroundColor(.blue)
                    .underline()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        } else {
            Text(vm.folderName)
        }
    }
}
