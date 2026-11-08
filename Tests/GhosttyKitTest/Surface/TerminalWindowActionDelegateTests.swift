import GhosttyKit
@testable import GhosttyTerminal
import Testing

@MainActor
struct TerminalWindowActionDelegateTests {
    @Test
    func `window actions reach the delegate with their payloads`() {
        let bridge = TerminalCallbackBridge()
        let probe = WindowActionProbe()
        bridge.delegate = probe

        var action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_NEW_WINDOW
        bridge.handleAction(action)

        action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_NEW_SPLIT
        action.action.new_split = GHOSTTY_SPLIT_DIRECTION_DOWN
        bridge.handleAction(action)

        action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_CLOSE_TAB
        action.action.close_tab_mode = GHOSTTY_ACTION_CLOSE_TAB_MODE_OTHER
        bridge.handleAction(action)

        action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_QUIT
        bridge.handleAction(action)

        #expect(probe.actions == [.newWindow, .newSplit(.down), .closeTab(.other), .quit])
    }

    @Test
    func `a window action is reported handled only when a delegate adopts the protocol`() {
        var action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_NEW_WINDOW

        let adopting = TerminalCallbackBridge()
        adopting.delegate = WindowActionProbe()
        #expect(adopting.handlesWindowAction(action))

        let other = TerminalCallbackBridge()
        other.delegate = TitleOnlyProbe()
        #expect(!other.handlesWindowAction(action))

        var title = ghostty_action_s()
        title.tag = GHOSTTY_ACTION_SET_TITLE
        #expect(!adopting.handlesWindowAction(title))
    }

    @Test
    func `the controller forwards app-targeted window actions to its delegate`() {
        let controller = TerminalController()
        let probe = WindowActionProbe()
        controller.windowActionDelegate = probe
        var action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_QUIT
        var target = ghostty_target_s()
        target.tag = GHOSTTY_TARGET_APP
        #expect(controller.deliverActionForTesting(target: target, action: action))
        #expect(probe.actions == [.quit])

        controller.windowActionDelegate = nil
        #expect(!controller.deliverActionForTesting(target: target, action: action))
    }

    @Test
    func `TerminalViewState forwards window actions to onWindowAction`() {
        let state = TerminalViewState()
        var received: [TerminalWindowAction] = []
        state.onWindowAction = { received.append($0) }
        state.terminalDidRequestWindowAction(.toggleFullscreen)
        #expect(received == [.toggleFullscreen])
    }
}

@MainActor
private final class WindowActionProbe: TerminalSurfaceWindowActionDelegate {
    var actions: [TerminalWindowAction] = []
    func terminalDidRequestWindowAction(_ action: TerminalWindowAction) {
        actions.append(action)
    }
}

@MainActor
private final class TitleOnlyProbe: TerminalSurfaceTitleDelegate {
    func terminalDidChangeTitle(_: String) {}
}
