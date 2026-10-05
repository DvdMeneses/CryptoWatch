//
//  CryptoWatchApp.swift
//  CryptoWatch
//
//  Created by NUT - NUCLEO DE TECNOLOGIA on 04/10/26.
//

import SwiftUI
import SwiftData

@main
struct CryptoWatchApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [FavoriteCoin.self, PriceAlert.self])
    }
}
