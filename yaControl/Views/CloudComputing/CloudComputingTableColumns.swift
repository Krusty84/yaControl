//
//  CloudComputingTableColumns.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import AppKit

struct VMAutoStartColumn: View {
    @Environment(\.locale) private var locale

    let vm: VMTableData
    let isOn: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle("", isOn: Binding(
            get: { isOn },
            set: { onToggle($0) }
        ))
        .toggleStyle(CheckboxToggleStyle())
        .help(LocalizedStringHelper.string(L10n.Table.autoPowerManagement, locale: locale))
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
            .buttonStyle(.plain)
            .onHover { hover in
                if hover { NSCursor.pointingHand.push() }
                else   { NSCursor.pop() }
            }
            .contextMenu {
                Button(LocalizedStringKey(L10n.Table.copyNameAndID)) {
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
        .buttonStyle(.plain)
        .disabled(isProcessing || !vm.status.isActionable)
    }

    private var statusIcon: String {
        switch vm.status {
            case .running: "stop.fill"
            case .stopped: "play.fill"
            case .starting, .stopping, .provisioning, .restarting, .updating: "arrow.triangle.2.circlepath"
            case .error: "exclamationmark.triangle.fill"
            case .crashed: "exclamationmark.octagon.fill"
            default: "questionmark"
        }
    }

    private var statusColor: Color {
        switch vm.status {
            case .running: .red
            case .stopped: .green
            case .starting, .stopping, .provisioning, .restarting, .updating: .gray
            case .error, .crashed: .orange
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
                Button(LocalizedStringKey(L10n.Table.copyIPs)) {
                    let s = vm.addresses.joined(separator: ", ")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(s, forType: .string)
                }
                if let ipAddress = vm.addresses.first {
                    Button(action: {
                        let cmd = "ssh -l \(SettingsManager.shared.generalUsername4VMs) \(ipAddress)"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cmd, forType: .string)
                        TerminalLauncher.openTerminal()
                    }) {
                        Text(
                            LocalizedStringKey(
                                SettingsManager.shared.generalUsername4VMs.isEmpty
                                ? L10n.Table.goToSettingsSetUsername
                                : L10n.Table.openSSH
                            )
                        )
                    }
                    .disabled(SettingsManager.shared.generalUsername4VMs.isEmpty)
                    
                    Button(LocalizedStringKey(L10n.Table.openRDP)) {
                        RDPFileLauncher.openRDPClient(
                            to: ipAddress,
                            username: SettingsManager.shared.generalUsername4VMs
                        )
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
            .buttonStyle(.plain)
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        } else {
            Text(vm.folderName)
        }
    }
}
