//
//  MainWindow.swift - The collector of the application tabs
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import ElegantTabs

struct MainWindow: View {
    let refreshToken: UUID
    @State private var selectedTab = 0
    
    var body: some View {
        ElegantTabsView(selection: $selectedTab) {
            TabItem(
                localizedTitle: LocalizedStringKey(L10n.Tabs.computing),
                icon: .system(name: "desktopcomputer")
            ) {
                CloudComputingTabContent(
                    isActive: selectedTab == 0,
                    refreshToken: refreshToken
                )
            }

            TabItem(
                localizedTitle: LocalizedStringKey(L10n.Tabs.functions),
                icon: .system(name: "function")
            ) {
                ServerLessFunctionTabContent(
                    isActive: selectedTab == 1,
                    refreshToken: refreshToken
                )
            }

            TabItem(
                localizedTitle: LocalizedStringKey(L10n.Tabs.storage),
                icon: .system(name: "archivebox")
            ) {
                BucketTabContent(
                    isActive: selectedTab == 2,
                    refreshToken: refreshToken
                )
            }

            TabItem(
                localizedTitle: LocalizedStringKey(L10n.Tabs.settings),
                icon: .system(name: "gear")
            ) {
                SettingsTabContent()
            }

            TabItem(
                localizedTitle: LocalizedStringKey(L10n.Tabs.about),
                icon: .system(name: "info")
            ) {
                AboutTabContent()
            }
        }
        .frame(minWidth: 800, idealWidth: 900, minHeight: 420, idealHeight: 520)
        
    }
}
