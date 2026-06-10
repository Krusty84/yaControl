//
//  CloudComputing.swift - Yandex Cloud Serverless Functions
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @State private var model = ServerlessFunctionModel()
    @State private var selectedSlf: ServerLessFunctionTableData.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            headerView

            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            StatusPanel(
                lastUpdateTime: model.lastUpdateTime,
                currentBalance: model.currentBalance,
                currency: model.currency,
                billingUrl: model.billingUrl
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            await model.loadIfNeeded()
        }
    }

    private var headerView: some View {
        HStack {
            Text(String(
                format: LocalizedStringHelper.string(L10n.Serverless.totalFunctions, language: SettingsManager.shared.appLanguage),
                Int64(model.totalSLFs)
            ))
                .font(.subheadline).bold()
            Text(String(
                format: LocalizedStringHelper.string(L10n.Serverless.active, language: SettingsManager.shared.appLanguage),
                Int64(model.activeSLFs)
            ))
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchServerLessFunctions() }
            } label: {
                Label(LocalizedStringKey(L10n.Serverless.refresh), systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help(LocalizedStringHelper.string(L10n.Serverless.refresh, language: SettingsManager.shared.appLanguage))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Serverless.search))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(LocalizedStringHelper.string(L10n.Common.loading, language: SettingsManager.shared.appLanguage))
                .padding()
        } else if let err = model.errorMessage {
            ContentUnavailableView {
                Label(LocalizedStringKey(L10n.Serverless.errorTitle), systemImage: "exclamationmark.triangle")
            } description: {
                Text(err)
            } actions: {
                Button(LocalizedStringKey(L10n.Common.retry)) {
                    Task { await model.fetchServerLessFunctions() }
                }
            }
        } else if model.filteredSLFs.isEmpty {
            ContentUnavailableView(
                LocalizedStringKey(L10n.Serverless.emptyTitle),
                systemImage: "function",
                description: Text(LocalizedStringKey(L10n.Serverless.emptyDescription))
            )
        } else {
            Table(model.filteredSLFs, selection: $selectedSlf) {
                TableColumn(LocalizedStringKey(L10n.Table.name)) { slf in
                    SLFNameColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.status)) { slf in
                    SLFStatusColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.createdAt), value: \.createdAt)
                TableColumn(LocalizedStringKey(L10n.Table.invoke)) { slf in
                    SLFInvokeColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.folder)) { slf in
                    SLFFolderColumn(slf: slf)
                }
            }
            .padding(.vertical, 6)
            .refreshable {
                await model.fetchServerLessFunctions()
            }
        }
    }
}
