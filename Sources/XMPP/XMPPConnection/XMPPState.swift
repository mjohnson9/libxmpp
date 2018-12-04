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

	init(stateController: XMPPStateController)

	func run()
	func receivedElement(element: Element)
	func receivedStreamStart(element: Element)
	func receivedStreamEnd()
}

protocol XMPPStateController: class {
	var session: XMPPSession! { get }

	func switchState(state: XMPPState, data: Any?)
	func resetState()

	func write(_ element: Element)
	func writeStreamBegin(xmppVersion: String, to: String, from: String?)
}
