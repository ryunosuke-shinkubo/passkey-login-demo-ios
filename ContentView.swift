//
//  ContentView.swift
//  PasskeyRedirectDemo
//
//  Created by 新久保 on 2026/07/31.
//

import SafariServices
import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: PasskeyRedirectViewModel
    @State private var isPresentingSafariView = false

    var body: some View {
        NavigationStack {
            Form {
                Section("ログイン開始設定") {
                    TextField("https://example.com/passkey/login", text: $viewModel.loginPageURLText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("https://example.github.io/passkey-demo/auth/callback", text: $viewModel.redirectURLText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("ブラウザ起動方式", selection: $viewModel.browserLaunchMode) {
                        ForEach(PasskeyRedirectViewModel.BrowserLaunchMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    Button("ログイン開始") {
                        startLogin()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canStartLogin)

                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("送信されるリクエストパラメータ") {
                    KeyValueRow(title: "state", value: viewModel.pendingState)
                    KeyValueRow(title: "redirect_uri", value: viewModel.redirectURLText)
                    KeyValueRow(title: "起動方式", value: viewModel.browserLaunchMode.label)
                }

                if let loginURL = viewModel.launchedLoginURL {
                    Section("起動するブラウザURL") {
                        SelectableValueText(loginURL.absoluteString)
                    }
                }

                if let callbackPreviewURL = viewModel.callbackPreviewURL {
                    Section("コールバック例") {
                        SelectableValueText(callbackPreviewURL.absoluteString)

                        Text("認証完了後に Web 側からこの形式でリダイレクトすると、アプリが前面復帰して `shortTimeCode` と `state` を表示します。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("受信結果") {
                    KeyValueRow(title: "shortTimeCode", value: viewModel.receivedShortTimeCode ?? "未受信")
                    KeyValueRow(title: "state", value: viewModel.receivedState ?? "未受信")
                    KeyValueRow(title: "error", value: viewModel.receivedError ?? "未受信")

                    if let validationMessage = viewModel.stateValidationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(viewModel.didStateMatch == true ? .green : .orange)
                    }

                    if let callbackURL = viewModel.callbackURL {
                        SelectableValueText(callbackURL.absoluteString)
                    }

                    if viewModel.callbackURL != nil {
                        Button("受信結果をクリア") {
                            viewModel.clearResult()
                        }
                    }
                }
            }
            .navigationTitle("Passkey Redirect Demo")
            .sheet(isPresented: $isPresentingSafariView, onDismiss: {
                viewModel.markBrowserSheetDismissed()
            }) {
                if let safariURL = viewModel.launchedLoginURL {
                    SafariView(url: safariURL)
                        .ignoresSafeArea()
                }
            }
        }
    }

    private func startLogin() {
        guard let loginURL = viewModel.beginLogin() else {
            return
        }

        switch viewModel.browserLaunchMode {
        case .systemBrowser:
            openURL(loginURL) { accepted in
                if !accepted {
                    viewModel.markBrowserLaunchRejected()
                }
            }
        case .safariViewController:
            isPresentingSafariView = true
        }
    }
}

private struct KeyValueRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            SelectableValueText(value)
        }
    }
}

private struct SelectableValueText: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .font(.footnote.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    ContentView(viewModel: PasskeyRedirectViewModel())
}
