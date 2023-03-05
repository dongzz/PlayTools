//
//  MacPlugin.swift
//  AKInterface
//
//  Created by Isaac Marovitz on 13/09/2022.
//

import AppKit
import CoreGraphics
import Foundation

class AKPlugin: NSObject, Plugin {
    required override init() {
    }

    var screenCount: Int {
        NSScreen.screens.count
    }

    var mousePoint: CGPoint {
        NSApplication.shared.windows.first!.mouseLocationOutsideOfEventStream as CGPoint
    }

    var windowFrame: CGRect {
        NSApplication.shared.windows.first!.frame as CGRect
    }

    var isMainScreenEqualToFirst: Bool {
        return NSScreen.main == NSScreen.screens.first
    }

    var mainScreenFrame: CGRect {
        return NSScreen.main!.frame as CGRect
    }

    var isFullscreen: Bool {
        NSApplication.shared.windows.first!.styleMask.contains(.fullScreen)
    }

    func setCursor() {
        if let customImg = NSImage(named: "cur") {
            customImg.size.width = 30
            customImg.size.height = 30
            NSCursor.init(image: customImg, hotSpot: NSPoint(x: 0, y: 0)).set()
        } else {
            NSCursor.pointingHand.set()
        }
    }

    func hideCursor() {
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }

    func unhideCursor() {
        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    func terminateApplication() {
        NSApplication.shared.terminate(self)
    }

    func eliminateRedundantKeyPressEvents(_ dontIgnore: @escaping() -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            if dontIgnore() {
                return event
            }
            return nil
        })
    }

    func setupMouseButton(_ _up: Int, _ _down: Int, _ dontIgnore: @escaping(Int, Bool, Bool) -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask(rawValue: UInt64(_up)), handler: { event in
            let isEventWindow = event.window == NSApplication.shared.windows.first!
            if dontIgnore(_up, true, isEventWindow) {
                return event
            }
            return nil
        })
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask(rawValue: UInt64(_down)), handler: { event in
            if dontIgnore(_up, false, true) {
                return event
            }
            return nil
        })
    }

    func setupScrollWheel(_ onMoved: @escaping(CGFloat, CGFloat, UInt) -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.scrollWheel, handler: { event in
            let consumed = onMoved(event.scrollingDeltaX, event.scrollingDeltaY, event.phase.rawValue)
            if consumed {
                return nil
            }
            return event
        })
    }

    func setupMouseDwon(_ onDown: @escaping() -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.rightMouseDown, handler: { event in
            let consumed = onDown()
            if consumed {
                return nil
            }
            return event
        })
    }

    func setupMouseUp(_ onUp: @escaping() -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.rightMouseUp, handler: { event in
            let consumed = onUp()
            if consumed {
                return nil
            }
            return event
        })
    }

    func setupMouseEntered(_ onEntered: @escaping() -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseEntered, handler: { event in
            let consumed = onEntered()
            if consumed {
                self.setCursor()
                return nil
            }
            return event
        })
    }

    func setupMouseExited(_ onExited: @escaping() -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseExited, handler: { event in
            let consumed = onExited()
            if consumed {
                NSCursor.arrow.set()
                return nil
            }
            return event
        })
    }

    func urlForApplicationWithBundleIdentifier(_ value: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: value)
    }

    func setMenuBarVisible(_ visible: Bool) {
        NSMenu.setMenuBarVisible(visible)
    }
}
