//
//  StateError.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/5/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

class StateError: XMPPState {
	var description: String = "Error"

	var parentState: XMPPState?
	private var stateController: XMPPStateController

	private var errorTag: String

	required init(stateController: XMPPStateController, data: Any?) {
		self.stateController = stateController
		// swiftlint:disable:next force_cast
		self.errorTag = data as! String
	}

	func run() {
		let error = self.constructStreamError(tag: self.errorTag)
		self.stateController.write(error)
		os_log(.info, log: XMPPConnection.osLog, "%s: Sent stream error: %s", self.stateController.domain, self.errorTag)
		self.stateController.disconnectAndRetry()
	}

	func receivedStanza(stanza: Stanza) -> Bool { return true }

	func receivedStreamStart(element: Element) -> Bool { return true }

	func receivedStreamEnd() -> Bool { return true }

	func changingState(nextState: XMPPState) { }

	private func constructStreamError(tag: String) -> Element {
		let root = Element()
		root.prefix = "stream"
		root.tag = "error"
		root.attributes["to"] = self.stateController.domain

		let child = Element()
		child.tag = tag
		child.defaultNamespace = "urn:ietf:params:xml:ns:xmpp-streams"

		root.children = [child]

		return root
	}
}
