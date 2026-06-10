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
    @AppStorage("com.krusty84.yaControl.settings.appLanguage")
    private var appLanguageRawValue: String = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some View {
        GoodProperTabsView(content: [
                (title: localized(L10n.Tabs.computing), icon: "system:desktopcomputer", view: AnyView(CloudComputingTabContent().environmentObject(AppState.shared))),
                (title: localized(L10n.Tabs.functions), icon: "system:function", view: AnyView(ServerLessFunctionTabContent())),
                (title: localized(L10n.Tabs.storage), icon: "system:archivebox", view: AnyView(BucketTabContent())),
                //TODO: for future, maybe, for that is need to add gRPC support
                //(title: "Billing", icon: "system:creditcard", view: AnyView(BillingTabContent())),
                (title: localized(L10n.Tabs.settings), icon: "system:gear", view: AnyView(SettingsTabContent())),
                (title: localized(L10n.Tabs.about), icon: "system:info", view: AnyView(AboutTabContent()))
                ])
                .frame(minWidth: 800, idealWidth: 900, minHeight: 420, idealHeight: 520)
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, language: appLanguage)
    }
}
