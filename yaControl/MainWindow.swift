//
//  MainWindow.swift - The collector of the application tabs
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
                (title: "Computing", icon: "system:desktopcomputer", view: AnyView(CloudComputingTabContent().environmentObject(AppState.shared))),
                (title: "Function", icon: "system:function", view: AnyView(ServerLessFunctionTabContent())),
                (title: "Storage", icon: "system:archivebox", view: AnyView(BucketTabContent())),
                //TODO: for future, maybe, for that is need to add gRPC support
                //(title: "Billing", icon: "system:creditcard", view: AnyView(BillingTabContent())),
                (title: "Settings", icon: "system:gear", view: AnyView(SettingsTabContent())),
                (title: "About", icon: "system:info", view: AnyView(AboutTabContent()))
                ]).onAppear {
                    //Stubs for something in future
                }
                .frame(width: 800, height: 400)
    }
}
