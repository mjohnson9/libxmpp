//
//  StateGracefulClose.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/5/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

class StateGracefulClose: XMPPState {
	var description: String = "Closing"

	var parentState: XMPPState?

	private var stateControllerr: XMPPStateController

	private var timer: DispatchSourceTimer!

	required init(stateController: XMPPStateController, data: Any?) {
		self.stateControllerr = stateController
	}

	func run() {
		self.stateControllerr.write(string: "</stream:stream>")
		os_log(.info, log: XMPPConnection.osLog, "%s: Sent stream closing", self.stateControllerr.domain)

		let gracefulCloseTimer = DispatchSource.makeTimerSource()
		self.timer = gracefulCloseTimer
		gracefulCloseTimer.setEventHandler {
			self.gracefulCloseTimeout()
		}
		gracefulCloseTimer.schedule(deadline: .now() + 1)
		gracefulCloseTimer.resume()
	}

	func receivedStanza(stanza: Stanza) -> Bool { return false }

	func receivedStreamStart(element: Element) -> Bool { return false }

	func receivedStreamEnd() -> Bool {
		self.timer.cancel()

		os_log(.info, log: XMPPConnection.osLog, "%s: Received stream closing", self.stateControllerr.domain)
		self.stateControllerr.disconnectWithoutRetry()

		return true
	}

	func changingState(nextState: XMPPState) { }

	func gracefulCloseTimeout() {
		os_log(.info, log: XMPPConnection.osLog, "%s: Graceful close timed out; closing forcefully", self.stateControllerr.domain)
		self.stateControllerr.disconnectWithoutRetry()
	}
}
