//
//  GrammarFixApp.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//
import AppKit
import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(
        _ aNotification: Notification
    ) {
        FirebaseApp.configure()
        NSApplication.shared.servicesProvider = GrammarFixServiceProvider()
    }
}

@main
struct GrammarFixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label {
                Text("Grammar Fix")
            } icon: {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 18
                    $0.size.width = 18 / ratio
                    return $0
                }(NSImage(named: "MenuBarIcon")!)
                
                Image(nsImage: image)
            }
        }
        .menuBarExtraStyle(.window)
    }
}



