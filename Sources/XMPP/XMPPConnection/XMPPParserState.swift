//
//  XMPPParserState.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/4/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class XMPPParserState {
	var openingStreamQualifiedName: String!

	var currentElement: Element!
	var namespacesForElement: [String: String]!
	var namespacePrefixes: [String: [String]] = [:]
}
