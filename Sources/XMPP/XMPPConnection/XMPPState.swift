//
//  XMPPState.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/4/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

protocol XMPPState: class {
	var description: String { get }
	var parentState: XMPPState? { get set }

	init(stateController: XMPPStateController, data: Any?)

	func run()
	func changingState(nextState: XMPPState)
	func receivedStanza(stanza: Stanza) -> Bool
	func receivedStreamStart(element: Element) -> Bool
	func receivedStreamEnd() -> Bool
}

protocol XMPPStateController: class {
	var session: XMPPSession! { get }
	var domain: String { get }

	func switchState(state: XMPPState)
	func resetState()

	func write(_ element: Element)
	func write(string: String)

	func disconnectWithoutRetry()
	func disconnectAndRetry()
}
