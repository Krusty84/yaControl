//
//  CloudComputing.swift - Yandex Cloud Serverless Functions
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @Environment(\.locale) private var locale

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
            Text(localizedFormat(L10n.Serverless.totalFunctions, Int64(model.totalSLFs)))
                .font(.subheadline).bold()
            Text(localizedFormat(L10n.Serverless.activeFunctions, Int64(model.activeSLFs)))
                .font(.subheadline).bold()
            Spacer()
            Button {
                Task { await model.fetchServerLessFunctions() }
            } label: {
                Label(LocalizedStringKey(L10n.Serverless.refresh), systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .help(localized(L10n.Serverless.refreshHelp))
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .searchable(text: $model.searchText, prompt: LocalizedStringKey(L10n.Serverless.searchPrompt))
    }

    @ViewBuilder
    private var contentArea: some View {
        if model.isLoading {
            ProgressView(localized(L10n.Serverless.loading))
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
                TableColumn(LocalizedStringKey(L10n.Table.serverlessName)) { slf in
                    SLFNameColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.serverlessStatus)) { slf in
                    SLFStatusColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.serverlessCreatedAt), value: \.createdAt)
                TableColumn(LocalizedStringKey(L10n.Table.serverlessInvoke)) { slf in
                    SLFInvokeColumn(slf: slf)
                }
                TableColumn(LocalizedStringKey(L10n.Table.serverlessFolder)) { slf in
                    SLFFolderColumn(slf: slf)
                }
            }
            .padding(.vertical, 6)
            .id(locale.identifier)
            .refreshable {
                await model.fetchServerLessFunctions()
            }
        }
    }

    private func localized(_ key: String) -> String {
        LocalizedStringHelper.string(key, locale: locale)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: localized(key),
            locale: locale,
            arguments: arguments
        )
    }
}
