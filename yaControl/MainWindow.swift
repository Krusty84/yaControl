//
//  MainWindow.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import GoodProperTabs

struct MainWindow: View {
   // @EnvironmentObject var propagationModel: PropagationModel
    var body: some View {
        GoodProperTabsView(content: [
            (title: "Computing", icon: "ComputingIcon", view: AnyView(CloudComputingTabContent())),
                (title: "Serverless Function", icon: "ServerLessIcon", view: AnyView(CloudComputingTabContent())),
                (title: "Storage", icon: "StorageIcon", view: AnyView(CloudComputingTabContent())),
                (title: "Settings", icon: "system:gear", view: AnyView(SettingsTabContent())),
                (title: "About", icon: "system:info", view: AnyView(AboutTabContent()))
                ]).onAppear {
                    // Reset the "forecastChanged" so next time it shows normal icon
                    //propagationModel.forecastChanged = false
                }
    }
}
