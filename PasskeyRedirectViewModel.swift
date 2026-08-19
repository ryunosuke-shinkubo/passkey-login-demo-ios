//
//  PasskeyRedirectViewModel.swift
//  PasskeyRedirectDemo
//
//  Created by 新久保 on 2026/07/31.
//

import Combine
import Foundation

@MainActor
final class PasskeyRedirectViewModel: ObservableObject {
    enum BrowserLaunchMode: String, CaseIterable, Identifiable {
        case systemBrowser
        case safariViewController

        var id: String { rawValue }

        var label: String {
            switch self {
            case .systemBrowser:
                return "OS既定ブラウザ"
            case .safariViewController:
                return "SFSafariViewController"
            }
        }
    }

    @Published var loginPageURLText = "https://sinfo.stg-trade.sbifxt.co.jp:1443/mpage/pf-login.html"
    @Published var redirectURLText = "https://ryunosuke-shinkubo.github.io/auth/callback.html"
    @Published var browserLaunchMode: BrowserLaunchMode = .systemBrowser
    @Published private(set) var pendingState = PasskeyRedirectViewModel.makeState()
    @Published private(set) var launchedLoginURL: URL?
    @Published private(set) var callbackURL: URL?
    @Published private(set) var receivedShortTimeCode: String?
    @Published private(set) var receivedState: String?
    @Published private(set) var receivedError: String?
    @Published private(set) var stateValidationMessage: String?
    @Published private(set) var didStateMatch: Bool?
    @Published private(set) var statusMessage = "ログインを押すと外部ブラウザを開きます。"

    var canStartLogin: Bool {
        URLComponents(string: loginPageURLText)?.url != nil &&
        URLComponents(string: redirectURLText)?.url != nil
    }

    var callbackPreviewURL: URL? {
        guard var components = URLComponents(string: redirectURLText) else {
            return nil
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "shortTimeCode" || $0.name == "state" }
        queryItems.append(URLQueryItem(name: "shortTimeCode", value: "shortTimeCode"))
        queryItems.append(URLQueryItem(name: "state", value: pendingState))
        components.queryItems = queryItems
        return components.url
    }

    func beginLogin() -> URL? {
        pendingState = Self.makeState()

        guard var components = URLComponents(string: loginPageURLText),
              URLComponents(string: redirectURLText)?.url != nil else {
            statusMessage = "ログイン先 URL または redirect_uri の形式が不正です。"
            return nil
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "state" || $0.name == "redirect_uri" }
        queryItems.append(URLQueryItem(name: "state", value: pendingState))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectURLText))
        components.queryItems = queryItems

        guard let loginURL = components.url else {
            statusMessage = "ブラウザ起動用 URL の生成に失敗しました。"
            return nil
        }

        launchedLoginURL = loginURL
        callbackURL = nil
        receivedShortTimeCode = nil
        receivedState = nil
        receivedError = nil
        stateValidationMessage = nil
        didStateMatch = nil
        statusMessage = browserLaunchMode == .systemBrowser
            ? "既定ブラウザを起動しました。認証完了後のコールバックを待機しています。"
            : "SFSafariViewController を表示しました。認証完了後のコールバックを待機しています。"
        return loginURL
    }

    func markBrowserLaunchRejected() {
        statusMessage = "OS からブラウザを起動できませんでした。URL 設定を確認してください。"
    }

    func markBrowserSheetDismissed() {
        if callbackURL == nil {
            statusMessage = "ブラウザ画面を閉じました。必要なら再度ログインを開始してください。"
        }
    }

    func handleCallback(_ url: URL) {
        callbackURL = url

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        receivedShortTimeCode = queryItems.first(where: { $0.name == "shortTimeCode" })?.value
        if receivedShortTimeCode == nil {
            receivedShortTimeCode = queryItems.first(where: { $0.name == "code" })?.value
        }
        receivedState = queryItems.first(where: { $0.name == "state" })?.value
        receivedError = queryItems.first(where: { $0.name == "error" })?.value

        if let receivedState {
            didStateMatch = receivedState == pendingState
            stateValidationMessage = didStateMatch == true
                ? "state が一致しました。"
                : "state が一致しません。別セッションの戻り値か、改ざんの可能性があります。"
        } else {
            didStateMatch = nil
            stateValidationMessage = "state を受信できませんでした。"
        }

        if let receivedError {
            statusMessage = "コールバックでエラーを受信しました: \(receivedError)"
        } else if receivedShortTimeCode == nil {
            statusMessage = "コールバックは受信しましたが、shortTimeCode が含まれていません。"
        } else {
            statusMessage = "コールバックを受信しました。"
        }
    }

    func clearResult() {
        callbackURL = nil
        receivedShortTimeCode = nil
        receivedState = nil
        receivedError = nil
        stateValidationMessage = nil
        didStateMatch = nil
        statusMessage = "結果をクリアしました。再度ログインを開始できます。"
    }

    private static func makeState() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
