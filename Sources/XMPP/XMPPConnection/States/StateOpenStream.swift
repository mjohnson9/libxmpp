//
//  StateOpen.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/4/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class StateOpenStream: XMPPState {
	private var stateController: XMPPStateController

	var description: String = "Opening stream"

	var parentState: XMPPState?

	required init(stateController: XMPPStateController) {
		self.stateController = stateController
	}

	func run() {
		<#code#>
	}

	func receivedElement(element: Element) {
		<#code#>
	}

	func receivedStreamStart(element: Element) {
		<#code#>
	}

	func receivedStreamEnd() {
		<#code#>
	}
}
