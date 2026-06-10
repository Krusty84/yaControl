//
//  NotificationToggleView.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//


import SwiftUI

struct NotificationToggleView: View {
    @State private var isOn = false
    private let animationDuration = 0.25

    var body: some View {
        Toggle(
            LocalizedStringKey(L10n.Settings.enableNotifications),
            isOn: $isOn.animation(.easeInOut(duration: animationDuration))
        )
            .toggleStyle(.switch)
            .onChange(of: isOn) { _, newValue in
                if newValue {
                    NotificationManager.shared.requestAuthorization()
                    // After the slide-on finishes, slide it back off
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isOn = false
                        }
                    }
                }
            }
    }
}
