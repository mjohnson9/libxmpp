//
//  StateOpen.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/4/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class StateOpenStream: XMPPState {
	var description: String = "Opening stream"

	var parentState: XMPPState?

	private var stateController: XMPPStateController

	required init(stateController: XMPPStateController, data: Any?) {
		self.stateController = stateController
	}

	func run() {
		let streamOpen = self.constructStreamBegin(xmppVersion: "1.0", to: self.stateController.domain, from: nil)
		self.stateController.write(string: streamOpen)
	}

	func changingState(nextState: XMPPState) { }

	func receivedStanza(stanza: Stanza) -> Bool {
		return false
	}

	func receivedStreamStart(element: Element) -> Bool {
		return true
	}

	func receivedStreamEnd() -> Bool {
		return false
	}

	// swiftlint:disable:next identifier_name
	private func constructStreamBegin(xmppVersion: String, to: String, from: String?) -> String {
		let openStream: NSMutableString = "<?xml version='1.0' encoding='UTF-8'?><stream:stream"
		if from != nil {
			openStream.append(" from='\(Element.escapeAttribute(from!))'")
		}
		openStream.append(" to='\(Element.escapeAttribute(to))'")
		openStream.append(" version='\(Element.escapeAttribute(xmppVersion))'")
		openStream.append(" xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>")

		return openStream as String
	}
}
