//
//  AppDelegate.swift
//  MorphicMenuBar
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Cocoa
import OSLog
import MorphicCore
import MorphicService
import MorphicSettings

private let logger = OSLog(subsystem: "app", category: "delegate")

// MARK: - Custom Application

/// Has the responsibility of creating an `AppDelegate` since we aren't using a Main storyboard to create the delegate
class Application: NSApplication{
    
    /// The application delegate
    ///
    /// Created at application launch and retained with a strong reference so it never gets destroyed.
    /// Since we aren't using a Main storyboard, we have to create the delegate manually.
    var strongDelegate = AppDelegate()
    
    override init() {
        super.init()
        delegate = strongDelegate
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    static var shared: AppDelegate!
    
    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log(.info, log: logger, "applicationDidFinishLaunching")
        AppDelegate.shared = self
        os_log(.info, log: logger, "opening morphic session...")
        Session.shared.open {
            self.createStatusItem()
            if Session.shared.user == nil{
                os_log(.info, log: logger, "no user")
                UserDefaults.morphic.addObserver(self, forKeyPath: .morphicDefaultsKeyUserIdentifier, options: .new, context: nil)
                self.launchConfigurator()
            }else{
                os_log(.info, log: logger, "session open")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
     
    // MARK: - Status Bar Item

    /// The item that shows in the macOS menu bar
    var statusItem: NSStatusItem!
     
    /// Create our `statusItem` for the macOS menu bar
    ///
    /// Should be called during application launch
    func createStatusItem(){
        os_log(.info, log: logger, "Creating status item")
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        guard let button = statusItem.button else {
            return
        }
        button.image = NSImage(named: "MenuIcon")
        button.alternateImage = NSImage(named: "MenuIconAlternate")
        button.target = self
        button.action = #selector(toggleQuickStrip(_:))
    }
     
    // MARK: - Quick Strip
     
    /// The window controller for the morphic quick strip that is shown by clicking on the `statusItem`
    var quickStripWindow: NSWindow?
     
    /// Show or hide the morphic quick strip
    ///
    /// - parameter sender: The UI element that caused this action to be invoked
    @objc
    func toggleQuickStrip(_ sender: Any?){
        if let window = quickStripWindow{
            window.close()
        }else{
            guard let button = sender as? NSButton else{
                return
            }
            NSApplication.shared.activate(ignoringOtherApps: true)
            quickStripWindow = QuickStripWindow()
            let location = button.window!.convertPoint(toScreen: button.convert(NSPoint(x: 0, y: button.bounds.size.height), to: nil))
            quickStripWindow?.level = .floating
            quickStripWindow?.delegate = self
            quickStripWindow?.setFrameOrigin(location)
            quickStripWindow?.makeKeyAndOrderFront(button)
        }
    }
     
    func windowDidBecomeKey(_ notification: Notification) {
        os_log(.info, log: logger, "didBecomeKey")
    }
     
    func windowDidResignKey(_ notification: Notification) {
        os_log(.info, log: logger, "didResignKey")
        quickStripWindow?.close()
    }
     
    func windowWillClose(_ notification: Notification) {
        os_log(.info, log: logger, "willClose")
        quickStripWindow = nil
    }
     
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        toggleQuickStrip(statusItem.button!)
        UserDefaults.morphic.removeObserver(self, forKeyPath: .morphicDefaultsKeyUserIdentifier)
        os_log(.info, log: logger, "Configurator set user identifier, retrying session open")
        Session.shared.open {
            if Session.shared.user == nil{
                os_log(.error, log: logger, "no user, launching configurator")
            }else{
                os_log(.info, log: logger, "session open")
            }
        }
    }
     
    // MARK: - Configurator App
     
    func launchConfigurator(){
        os_log(.info, log: logger, "launching configurator")
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.raisingthefloor.MorphicConfigurator") else{
            os_log(.error, log: logger, "Configurator app not found")
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config){
            (app, error) in
            guard error == nil else{
                os_log(.error, log: logger, "Failed to launch configurator: %{public}s", error!.localizedDescription)
                return
            }
        }
    }

}
