// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Carbon.HIToolbox
import Cocoa
import MorphicCore
import MorphicSettings
import MorphicService

public class MorphicBarItem {
    
    var interoperable: [String: Interoperable?]
    
    public init(interoperable: [String: Interoperable?]) {
        self.interoperable = interoperable
    }
    
    func view() -> MorphicBarItemViewProtocol? {
        return nil
    }
    
    public static func items(from interoperables: [Interoperable?]) -> [MorphicBarItem] {
        var items = [MorphicBarItem]()
        for i in 0..<interoperables.count {
            if let dict = interoperables.dictionary(at: i) {
                if let item_ = item(from: dict) {
                    items.append(item_)
                }
            }
        }
        return items
    }
    
    public static func item(from interoperable: [String: Interoperable?]) -> MorphicBarItem? {
        switch interoperable.string(for: "type") {
        case "control":
            return MorphicBarControlItem(interoperable: interoperable)
        case "link":
            return MorphicBarLinkItem(interoperable: interoperable)
        default:
            return nil
        }
    }
    
}

class MorphicBarLinkItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var imageUrl: String?
    var url: URL?
     
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        imageUrl = interoperable.string(for: "imageUrl")
        //
        // NOTE: argument 'url' should never be nil, but we use an empty string as a backup
        if let urlAsString = interoperable.string(for: "url") {
            // NOTE: if the url was malformed, that may result in a "nil" URL
            // SECURITY NOTE: we should strongly consider filtering urls by scheme (or otherwise) here
            url = URL(string: urlAsString)
        } else {
            url = nil
        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }
        
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, icon: icon, iconColor: color)
        view.target = self
        view.action = #selector(MorphicBarLinkItem.openLink(_:))
        return view
    }
    
    @objc
    func openLink(_ sender: Any?) {
        if let url = self.url {
            NSWorkspace.shared.open(url)
        }
    }
}

class MorphicBarControlItem: MorphicBarItem {
    
    enum Feature: String {
        case resolution
        case magnifier
        case reader
        case readselected
        case volume
        case contrast
        case nightshift
        case unknown
        
        init(string: String?) {
            if let known = Feature(rawValue: string ?? "") {
                self = known
            } else {
                self = .unknown
            }
        }
    }
    
    var feature: Feature
    
    override init(interoperable: [String : Interoperable?]) {
        feature = Feature(string: interoperable.string(for: "feature"))
        super.init(interoperable: interoperable)
    }
    
    override func view() -> MorphicBarItemViewProtocol? {
        switch feature {
        case .resolution:
            let localized = LocalizedStrings(prefix: "control.feature.resolution")
            let segments = [
                MorphicBarSegmentedButton.Segment(icon: .plus(), isPrimary: true, helpProvider: QuickHelpTextSizeBiggerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "bigger.help.title")),
                MorphicBarSegmentedButton.Segment(icon: .minus(), isPrimary: false, helpProvider: QuickHelpTextSizeSmallerProvider(display: Display.main, localized: localized), accessibilityLabel: localized.string(for: "smaller.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.zoom(_:))
            return view
        case .magnifier:
            let localized = LocalizedStrings(prefix: "control.feature.magnifier")
            let showHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "show.help.title"), message: localized.string(for: "show.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "hide.help.title"), message: localized.string(for: "hide.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "show"), isPrimary: true, helpProvider: showHelpProvider, accessibilityLabel: localized.string(for: "show.help.title")),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "hide"), isPrimary: false, helpProvider: hideHelpProvider, accessibilityLabel: localized.string(for: "hide.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.magnifier(_:))
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), isPrimary: true, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title")),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), isPrimary: false, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.reader(_:))
            return view
        case .readselected:
            let localized = LocalizedStrings(prefix: "control.feature.readselected")
            let playStopHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "playstop.help.title"), message: localized.string(for: "playstop.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "playstop"), isPrimary: true, helpProvider: playStopHelpProvider, accessibilityLabel: localized.string(for: "playstop.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.readselected)
            return view
        case .volume:
            let localized = LocalizedStrings(prefix: "control.feature.volume")
            let segments = [
                MorphicBarSegmentedButton.Segment(icon: .plus(), isPrimary: true, helpProvider: QuickHelpVolumeUpProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "up.help.title")),
                MorphicBarSegmentedButton.Segment(icon: .minus(), isPrimary: false, helpProvider: QuickHelpVolumeDownProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "down.help.title")),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "mute"), isPrimary: true, helpProvider: QuickHelpVolumeMuteProvider(audioOutput: AudioOutput.main, localized: localized), accessibilityLabel: localized.string(for: "mute.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.volume(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), isPrimary: true, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title")),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), isPrimary: false, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrast(_:))
            return view
        case .nightshift:
            let localized = LocalizedStrings(prefix: "control.feature.nightshift")
            let onHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider{ (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "on"), isPrimary: true, helpProvider: onHelpProvider, accessibilityLabel: localized.string(for: "on.help.title")),
                MorphicBarSegmentedButton.Segment(title: localized.string(for: "off"), isPrimary: false, helpProvider: offHelpProvider, accessibilityLabel: localized.string(for: "off.help.title"))
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.nightShift(_:))
            return view
        default:
            return nil
        }
    }
    
    @objc
    func zoom(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        guard let display = Display.main else {
            return
        }
        var percentage: Double
        if segment == 0 {
            percentage = display.percentage(zoomingIn: 1)
        } else {
            percentage = display.percentage(zoomingOut: 1)
        }
        _ = display.zoom(to: percentage)
    }
    
    @objc
    func volume(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        guard let output = AudioOutput.main else {
            return
        }
        if segment == 0 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume + 0.1)
            }
        } else if segment == 1 {
            if output.isMuted {
                _ = output.setMuted(false)
            } else {
                _ = output.setVolume(output.volume - 0.1)
            }
        } else if segment == 2 {
            _ = output.setMuted(true)
        }
    }
    
    @objc
    func contrast(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            Session.shared.apply(true, for: .macosDisplayContrastEnabled) {
                _ in
            }
        } else {
            Session.shared.apply(false, for: .macosDisplayContrastEnabled) {
                _ in
            }
        }
    }

    @objc
    func nightShift(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            MorphicNightShift.setEnabled(true)
        } else {
            MorphicNightShift.setEnabled(false)
        }
    }

    @objc
    func reader(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            Session.shared.apply(true, for: .macosVoiceOverEnabled) {
                _ in
            }
        } else {
            Session.shared.apply(false, for: .macosVoiceOverEnabled) {
                _ in
            }
        }
    }

    @objc
    func readselected(_ sender: Any?) {
        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }
        
        // NOTE: we retrieve system settings here which are _not_ otherwise captured by Morphic; if we decide to capture those settings in the future for broader capture/apply purposes, then we should modify this code to access those settings via Session.shared (if doing so will ensure that we are not getting cached data...rather than 'captured or set data'...since we need to check these settings every time this function is called).
        let defaultsDomain = "com.apple.speech.synthesis.general.prefs"
        guard let defaults = UserDefaults(suiteName: defaultsDomain) else {
            NSLog("Could not access defaults domain: \(defaultsDomain)")
            return
        }
        
        // NOTE: sendSpeakSelectedTextHotKey will be called synchronously or asynchronously (depending on whether we need to enable the OS feature asynchronously first)
        let sendSpeakSelectedTextHotKey = {
            // obtain any custom-specified key sequence used for activating the "speak selected text" feature in macOS (or else assume default)
            let speakSelectedTextHotKeyCombo = defaults.integer(forKey: "SpokenUIUseSpeakingHotKeyCombo")
            //
            let keyCode: CGKeyCode
            let keyOptions: MorphicInput.KeyOptions
            if speakSelectedTextHotKeyCombo != 0 {
                guard let (customKeyCode, customKeyOptions) = MorphicInput.parseDefaultsKeyCombo(speakSelectedTextHotKeyCombo) else {
                    // NOTE: while we should be able to decode any custom hotkey, this code is here to capture edge cases we have not anticipated
                    // NOTE: in the future, we should consider an informational prompt alerting the user that we could not decode their custom hotkey (so they know why the feature did not work...or at least that it intentionally did not work)
                    NSLog("Could not decode custom hotkey")
                    return
                }
                keyCode = customKeyCode
                keyOptions = customKeyOptions
            } else {
                // default hotkey is Option+Esc
                keyCode = CGKeyCode(kVK_Escape)
                keyOptions = .withAlternateKey
            }
            
            //
            
            // get the window ID of the topmost window
            guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
                NSLog("Could not get ID of topmost window")
                return
            }

            // capture a reference to the topmost application
            guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
                NSLog("Could not get reference to application owning the topmost window")
                return
            }
            
            // activate the topmost application
            guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
                NSLog("Could not activate the topmost window")
                return
            }
            
            // send the "speak selected text key" to the system
            guard MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) == true else {
                NSLog("Could not send 'Speak selected text' hotkey to the keyboard input stream")
                return
            }
        }
        
        // make sure the user has "speak selected text..." enabled in System Preferences
        let speakSelectedTextKeyEnabled = defaults.bool(forKey: "SpokenUIUseSpeakingHotKeyFlag")
        if speakSelectedTextKeyEnabled == false {
            // if SpokenUIUseSpeakingHotKeyFlag is false, then enable it via UI automation
            Session.shared.apply(true, for: .macosSpeakSelectedTextEnabled) {
                _ in
                // send the hotkey (asynchronously) once we have enabled macOS's "speak selected text" feature
                sendSpeakSelectedTextHotKey()
            }
        } else {
            // send the hotkey (synchronously) now
            sendSpeakSelectedTextHotKey()
        }
    }

    @objc
    func magnifier(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        let session = Session.shared
        if segment == 0 {
            let keyValuesToSet: [(Preferences.Key, Interoperable?)] = [
                (.macosZoomStyle, 1)
            ]
            let preferences = Preferences(identifier: "__magnifier__")
            let capture = CaptureSession(settingsManager: session.settings, preferences: preferences)
            capture.keys = keyValuesToSet.map{ $0.0 }
            capture.captureDefaultValues = true
            capture.run {
                session.storage.save(record: capture.preferences) {
                    _ in
                    let apply = ApplySession(settingsManager: session.settings, keyValueTuples: keyValuesToSet)
                    apply.add(key: .macosZoomEnabled, value: true)
                    apply.run {
                    }
                }
            }
        } else {
            session.storage.load(identifier: "__magnifier__") {
                (_, preferences: Preferences?) in
                if let preferences = preferences {
                    let apply = ApplySession(settingsManager: session.settings, preferences: preferences)
                    apply.addFirst(key: .macosZoomEnabled, value: false)
                    apply.run {
                    }
                } else {
                    session.apply(false, for: .macosZoomEnabled){
                        _ in
                    }
                }
            }
        }
    }
    
}

fileprivate struct LocalizedStrings {
    
    var prefix: String
    var table = "MorphicBarViewController"
    var bundle = Bundle.main
    
    init(prefix: String) {
        self.prefix = prefix
    }
    
    func string(for suffix: String) -> String {
        return bundle.localizedString(forKey: prefix + "." + suffix, value: nil, table: table)
    }
}

fileprivate class QuickHelpDynamicTextProvider: QuickHelpContentProvider{
    
    var textProvider: () -> (String, String)?
    
    init(textProvider: @escaping () -> (String, String)?) {
        self.textProvider = textProvider
    }
    
    func quickHelpViewController() -> NSViewController? {
        guard let strings = textProvider() else{
            return nil
        }
        let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
        viewController.titleText = strings.0
        viewController.messageText = strings.1
        return viewController
    }
}

fileprivate class QuickHelpTextSizeBiggerProvider: QuickHelpContentProvider {
    
    init(display: Display?, localized: LocalizedStrings) {
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0{
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == total - 1 {
            viewController.titleText = localized.string(for: "bigger.limit.help.title")
            viewController.messageText = localized.string(for: "bigger.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "bigger.help.title")
            viewController.messageText = localized.string(for: "bigger.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpTextSizeSmallerProvider: QuickHelpContentProvider {
    
    init(display: Display?, localized: LocalizedStrings) {
        self.display = display
        self.localized = localized
    }
    
    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0 {
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == 0 {
            viewController.titleText = localized.string(for: "smaller.limit.help.title")
            viewController.messageText = localized.string(for: "smaller.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "smaller.help.title")
            viewController.messageText = localized.string(for: "smaller.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpVolumeUpProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "up.muted.help.title")
            viewController.messageText = localized.string(for: "up.muted.help.message")
        } else {
            if level >= 0.99 {
                viewController.titleText = localized.string(for: "up.limit.help.title")
                viewController.messageText = localized.string(for: "up.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "up.help.title")
                viewController.messageText = localized.string(for: "up.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeDownProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "down.muted.help.title")
            viewController.messageText = localized.string(for: "down.muted.help.message")
        } else {
            if level <= 0.01{
                viewController.titleText = localized.string(for: "down.limit.help.title")
                viewController.messageText = localized.string(for: "down.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "down.help.title")
                viewController.messageText = localized.string(for: "down.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeMuteProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "muted.help.title")
            viewController.messageText = localized.string(for: "muted.help.message")
        } else {
            viewController.titleText = localized.string(for: "mute.help.title")
            viewController.messageText = localized.string(for: "mute.help.message")
        }
        return viewController
    }
    
}

private extension NSImage {
    
    static func plus() -> NSImage {
        return NSImage(named: "SegmentIconPlus")!
    }
    
    static func minus() -> NSImage {
        return NSImage(named: "SegmentIconMinus")!
    }
    
}

private extension NSColor {
    
    // string must be formatted as #rrggbb
    static func createFromRgbHexString(_ rgbHexString: String) -> NSColor? {
        if rgbHexString.count != 7 {
            return nil
        }
        
        let hashStartIndex = rgbHexString.startIndex
        let redStartIndex = rgbHexString.index(hashStartIndex, offsetBy: 1)
        let greenStartIndex = rgbHexString.index(redStartIndex, offsetBy: 2)
        let blueStartIndex = rgbHexString.index(greenStartIndex, offsetBy: 2)
        
        let hashAsString = rgbHexString[hashStartIndex..<redStartIndex]
        guard hashAsString == "#" else {
            return nil
        }
        
        let redAsHexString = rgbHexString[redStartIndex..<greenStartIndex]
        guard let redAsInt = Int(redAsHexString, radix: 16),
            redAsInt >= 0,
            redAsInt <= 255 else {
            //
            return nil
        }
        let greenAsHexString = rgbHexString[greenStartIndex..<blueStartIndex]
        guard let greenAsInt = Int(greenAsHexString, radix: 16),
            greenAsInt >= 0,
            greenAsInt <= 255 else {
            return nil
        }
        let blueAsHexString = rgbHexString[blueStartIndex...]
        guard let blueAsInt = Int(blueAsHexString, radix: 16),
            blueAsInt >= 0,
            blueAsInt <= 255 else {
            //
            return nil
        }
        
        return NSColor(red: CGFloat(redAsInt) / 255.0, green: CGFloat(greenAsInt) / 255.0, blue: CGFloat(blueAsInt) / 255.0, alpha: 1.0)
    }
}
