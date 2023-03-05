import Foundation
import GameController
import UIKit

class PlayInput {
    static let shared = PlayInput()
    var actions = [Action]()
    var timeoutForBind = true

    var isEdit = false

    static private var lCmdPressed = false
    static private var rCmdPressed = false

    func invalidate() {
        PlayMice.shared.stop()
        for action in self.actions {
            action.invalidate()
        }
    }

    func parseKeymap() {
        actions = []
        for button in keymap.keymapData.buttonModels {
            actions.append(ButtonAction(data: button))
        }

        for draggableButton in keymap.keymapData.draggableButtonModels {
            actions.append(DraggableButtonAction(data: draggableButton))
        }

        for joystick in keymap.keymapData.joystickModel {
            // Left Thumbstick, Right Thumbstick, Mouse
            if joystick.keyName.contains(Character("u")) {
                actions.append(ContinuousJoystickAction(data: joystick))
            } else { // Keyboard
                actions.append(JoystickAction(data: joystick))
            }
        }
    }

    public func toggleEditor(show: Bool) {
        mode.show(show)
        if show {
            if let keyboard = GCKeyboard.coalesced!.keyboardInput {
                keyboard.keyChangedHandler = { _, _, keyCode, _ in
                    if !PlayInput.cmdPressed()
                        && !PlayInput.FORBIDDEN.contains(keyCode)
                        && self.isSafeToBind(keyboard) {
                        EditorController.shared.setKey(keyCode.rawValue)
                    }
                }
            }
            if let controller = GCController.current?.extendedGamepad {
                controller.valueChangedHandler = { _, element in
                    // This is the index of controller buttons, which is String, not Int
                    let alias: String! = element.aliases.first
                    EditorController.shared.setKey(alias)
                }
            }
        } else {
            GCKeyboard.coalesced!.keyboardInput!.keyChangedHandler = nil
            GCController.current?.extendedGamepad?.valueChangedHandler = nil
        }
    }

    func setup() {
        parseKeymap()

        for mouse in GCMouse.mice() {
            if settings.mouseMapping {
                mouse.mouseInput?.mouseMovedHandler = PlayMice.shared.handleMouseMoved
            } else {
                mouse.mouseInput?.mouseMovedHandler = PlayMice.shared.handleFakeMouseMoved
            }
        }

    }

    static public func cmdPressed() -> Bool {
        return lCmdPressed || rCmdPressed
    }

    private func isSafeToBind(_ input: GCKeyboardInput) -> Bool {
           var result = true
           for forbidden in PlayInput.FORBIDDEN where input.button(forKeyCode: forbidden)?.isPressed ?? false {
               result = false
               break
           }
           return result
       }

    private static let FORBIDDEN: [GCKeyCode] = [
        .leftGUI,
        .rightGUI,
        .leftAlt,
        .rightAlt,
        .printScreen
    ]

    private func swapMode(_ pressed: Bool) {
        if !settings.mouseMapping {
            return
        }
        if pressed {
            if !self.isEdit {
                self.invalidate()
                self.isEdit = true
                Toast.showOver(msg: "edit open")
            } else {
                self.setup()
                self.isEdit = false
                Toast.showOver(msg: "edit close")
            }
        }
    }

    var root: UIViewController? {
        return screen.window?.rootViewController
    }

    func setupShortcuts() {
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.button(forKeyCode: .leftGUI)?.pressedChangedHandler = { _, _, pressed in
                PlayInput.lCmdPressed = pressed
            }
            keyboard.button(forKeyCode: .rightGUI)?.pressedChangedHandler = { _, _, pressed in
                PlayInput.rCmdPressed = pressed
            }
            keyboard.button(forKeyCode: .leftAlt)?.pressedChangedHandler = { _, _, pressed in
                self.swapMode(pressed)
            }
            keyboard.button(forKeyCode: .rightAlt)?.pressedChangedHandler = { _, _, pressed in
                self.swapMode(pressed)
            }
        }

        for mouse in keymap.keymapData.mouseAreaModel {
            if mouse.keyName.hasSuffix("tick") || settings.mouseMapping {
                actions.append(CameraAction(data: mouse))
            }
        }

        PlayMice.shared.setupScrollWheelHandler()
        PlayMice.shared.setupMouseMoveHandler()
    }

    func initialize() {
        if !PlaySettings.shared.keymapping {
            return
        }

        let centre = NotificationCenter.default
        let main = OperationQueue.main

        centre.addObserver(forName: NSNotification.Name.GCKeyboardDidConnect, object: nil, queue: main) { _ in
            self.setupShortcuts()
//            if !mode.visible {
                self.setup()
//            }
        }

//        centre.addObserver(forName: NSNotification.Name.GCMouseDidConnect, object: nil, queue: main) { _ in
//            if !mode.visible {
//                self.setup()
//            }
//        }

        centre.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: main) { _ in
//            if !mode.visible {
                self.setup()
//            }
        }

        setupShortcuts()

        AKInterface.shared!.setCursor()
        // Fix beep sound
        AKInterface.shared!
            .eliminateRedundantKeyPressEvents(self.dontIgnore)
    }

    func dontIgnore() -> Bool {
//        (mode.visible && !EditorController.shared.editorMode) || PlayInput.cmdPressed()
        (isEdit && !EditorController.shared.editorMode) || PlayInput.cmdPressed()
    }
}
