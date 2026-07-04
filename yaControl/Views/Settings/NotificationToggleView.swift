//
//  NotificationToggleView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import SwiftUI

struct NotificationToggleView: View {
    @State private var isOn = false
    @State private var resetTask: Task<Void, Never>?

    private let animationDuration = 0.25

    var body: some View {
        Toggle(
            LocalizedStringKey(L10n.Settings.enableNotifications),
            isOn: $isOn
        )
            .toggleStyle(.switch)
            .onChange(of: isOn) { _, newValue in
                if newValue {
                    NotificationManager.shared.requestAuthorization()
                    resetTask?.cancel()
                    resetTask = Task { @MainActor in
                        do {
                            try await Task.sleep(for: .milliseconds(250))
                        } catch {
                            return
                        }

                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isOn = false
                        }
                    }
                }
            }
            .onDisappear {
                resetTask?.cancel()
                resetTask = nil
            }
    }
}
