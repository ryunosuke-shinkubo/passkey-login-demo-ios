//
//  PasskeyRedirectDemoApp.swift
//  PasskeyRedirectDemo
//
//  Created by 新久保 on 2026/07/31.
//

import SwiftUI

@main
struct PasskeyRedirectDemoApp: App {
    @StateObject private var viewModel = PasskeyRedirectViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onOpenURL { url in
                    viewModel.handleCallback(url)
                }
        }
    }
}
