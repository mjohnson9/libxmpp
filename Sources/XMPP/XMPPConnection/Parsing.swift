//
//  Parsing.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

private struct AssociatedKeys {
	static var parserNeedsReset: UInt8 = 0
	static var parserState: UInt8 = 0
}

extension XMPPConnection: EventedXMLParserDelegate {

	// MARK: Variables
	internal private(set) var parserNeedsReset: Bool {
		get {
			guard let value = objc_getAssociatedObject(self, &AssociatedKeys.parserNeedsReset) as? Bool else {
				return false
			}
			return value
		}
		set(newValue) {
			objc_setAssociatedObject(self, &AssociatedKeys.parserNeedsReset, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	 private var parserState: XMPPParserState! {
		get {
			guard let value = objc_getAssociatedObject(self, &AssociatedKeys.parserState) as? XMPPParserState else {
				return nil
			}

			return value
		}
		set(newValue) {
			objc_setAssociatedObject(self, &AssociatedKeys.parserState, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	internal func resetParser() {
		self.parserNeedsReset = true
	}

	internal func parserHasReset() {
		self.parserNeedsReset = false
		self.parserState = XMPPParserState()
	}

	// MARK: Parser delegate functions

	/*public func parser(_: XMLParser, didStartMappingPrefix: String, toURI: String) {
		/*guard !self.parserNeedsReset else {
		os_log(.debug, log: XMPPConnection.osLog, "%s: Started mapping prefix \"%{public}s\" to \"%{public}s\" while the parser was awaiting reset", self.domain, didStartMappingPrefix, toURI)
		return
		}*/

		os_log(.debug, log: XMPPConnection.osLog, "%s: Started mapping prefix \"%s\" to \"%s\"", self.domain, didStartMappingPrefix, toURI)

		var namespaceURIs = self.session!.namespacePrefixes[didStartMappingPrefix]
		if namespaceURIs == nil {
			namespaceURIs = []
		}
		namespaceURIs!.append(toURI)
		self.session!.namespacePrefixes[didStartMappingPrefix] = namespaceURIs

		if didStartMappingPrefix.count > 0 {
			if self.session!.namespacesForElement == nil {
				self.session!.namespacesForElement = [:]
			}

			self.session!.namespacesForElement[didStartMappingPrefix] = toURI
		}
	}*/

	/*public func parser(_: XMLParser, didEndMappingPrefix: String) {
		/*guard !self.parserNeedsReset else {
		os_log(.debug, log: XMPPConnection.osLog, "%s: Stopped mapping prefix \"%{public}s\" while the parser was awaiting reset", self.domain, didEndMappingPrefix)
		return
		}*/

		os_log(.debug, log: XMPPConnection.osLog, "%s: Stopped mapping prefix \"%s\"", self.domain, didEndMappingPrefix)

		var namespaceURIs = self.session!.namespacePrefixes[didEndMappingPrefix]
		guard namespaceURIs != nil else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Ended namespace \"%{public}s\" without ever starting it", self.domain, didEndMappingPrefix)
			//self.sendStreamError("invalid-xml")
			return
		}
		namespaceURIs!.remove(at: namespaceURIs!.count - 1)
		if namespaceURIs!.count == 0 {
			self.session!.namespacePrefixes.removeValue(forKey: didEndMappingPrefix)
		} else {
			self.session!.namespacePrefixes[didEndMappingPrefix] = namespaceURIs
		}
	}*/

	public func elementStarted(tag: String, namespaceURI: String?, prefix: String, namespaces: [String: String], attributes: [String: String]) {
		let element: Element = Element()
		element.tag = tag

		guard let namespaceURIs = self.parserState.namespacePrefixes[prefix], namespaceURIs.count > 0 else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Element has namespace prefix of %{public}s, but the server never defined that prefix", self.domain, prefix)
			self.sendStreamError("bad-format")
			return
		}
		let resolvedNamespaceURI = namespaceURIs[namespaceURIs.count - 1]
		element.prefix = prefix
		element.resolvedNamespace = resolvedNamespaceURI

		if let defaultNamespaces = self.parserState.namespacePrefixes[""], defaultNamespaces.count > 0 {
			element.defaultNamespace = defaultNamespaces[defaultNamespaces.count - 1]
			var checkingElement = self.parserState.currentElement
			while let checkElement = checkingElement {
				if checkElement.defaultNamespace == "" {
					// This element uses the default namespace of its parent
					checkingElement = checkElement.parent
					continue
				}

				if checkElement.defaultNamespace != element.defaultNamespace {
					// The first non-empty namespace is different, continue using the one assigned
					break
				}

				// The first non-empty namespace is the same, make ours blank
				element.defaultNamespace = nil
				break
			}
		}

		if namespaces.count > 0 {
			element.prefixedNamespaces = namespaces
		}

		element.attributes.reserveCapacity(attributes.count)
		for (name, value) in attributes {
			element.attributes[name] = value
		}

		element.parent = self.parserState.currentElement
		if element.parent != nil {
			element.parent.children.append(element)
		}

		if element.resolvedNamespace == "http://etherx.jabber.org/streams" && element.tag == "stream" && element.parent == nil {
			if self.parserState.openingStreamQualifiedName != nil {
				// The stream opening was sent, but we've already received a stream open
				os_log(.info, log: XMPPConnection.osLog, "%s: Received a second stream opening", self.domain)
				self.sendStreamError("invalid-xml")
				return
			}

			self.parserState.openingStreamQualifiedName = (element.prefix != "" ? element.prefix + ":" : "") + element.tag
			let handled = self.state.receivedStreamStart(element: element)
			guard handled else {
				self.sendStreamError("invalid-xml")
				return
			}
			return
		}

		self.parserState.currentElement = element
	}

	public func elementEnded(tag: String, namespaceURI: String?, prefix: String?) {
		let qualifiedName = (self.parserState.currentElement.prefix != "" ? self.parserState.currentElement.prefix + ":" : "") + self.parserState.currentElement.tag
		guard tag == self.parserState.currentElement.tag && prefix == self.parserState.currentElement.prefix else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Tag of ending element doesn't match element currently being processed: %{public}s%{public}s != %{public}s", self.domain, (prefix != nil ? prefix! + ":" : ""), tag, qualifiedName)
			self.sendStreamError("bad-format")
			return
		}

		if self.parserState.openingStreamQualifiedName != nil && qualifiedName == self.parserState.openingStreamQualifiedName {
			guard self.parserState.currentElement == nil else {
				os_log(.info, log: XMPPConnection.osLog, "%s: Received stream closing inside of another element", self.domain)
				self.sendStreamError("bad-format")
				return
			}

			self.parserState.openingStreamQualifiedName = nil
			let handled = self.state.receivedStreamEnd()
			guard handled else {
				self.disconnectAndRetry()
				return
			}
			return
		}

		if self.parserState.currentElement.parent == nil {
			let stanza = Stanza(self.parserState.currentElement)
			let handled = self.state.receivedStanza(stanza: stanza!)
			self.parserState?.currentElement = nil
			guard handled else {
				self.sendStreamError("unsupported-stanza-type")
				return
			}
			return
		}

		self.parserState.currentElement = self.parserState.currentElement.parent
	}

	public func foundCharacters(characters: String) {
		guard let currentElement = self.parserState.currentElement else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Received text node as a child of the root node", self.domain)
			self.sendStreamError("bad-format")
			return
		}

		if currentElement.contents == nil {
			currentElement.contents = characters
		} else {
			currentElement.contents += characters
		}
	}

	public func foundCDATA(data: Data) {
		guard let currentElement = self.parserState.currentElement else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Received CDATA as a child of the root node", self.domain)
			self.sendStreamError("bad-format")
			return
		}

		guard let decodedCDATA = String(data: data, encoding: .utf8) else {
			os_log(.info, log: XMPPConnection.osLog, "%s: Received CDATA that could not be decoded as UTF-8")
			self.sendStreamError("unsupported-encoding")
			return
		}

		if currentElement.contents == nil {
			currentElement.contents = decodedCDATA
		} else {
			currentElement.contents += decodedCDATA
		}
	}

	// MARK: Fatal stream errors because of parsing

	public func resolveExternalEntityName(name: String, systemID: String?) -> Data? {
		os_log(.info, log: XMPPConnection.osLog, "%s: Received XML external entity", self.domain)
		self.sendStreamError("restricted-xml")
		return nil
	}

	public func foundProcessingInstruction(target: String, data: String?) {
		os_log(.info, log: XMPPConnection.osLog, "%s: Received XML processing instruction", self.domain)
		self.sendStreamError("restricted-xml")
	}

	public func foundComment(comment: String) {
		os_log(.info, log: XMPPConnection.osLog, "%s: Received XML comment", self.domain)
		self.sendStreamError("restricted-xml")
	}

	public func parseErrorOccured(error: Error) {
		os_log(.info, log: XMPPConnection.osLog, "%s: Error parsing XML stream: %s", self.domain, String(describing: error))
		self.sendStreamError("bad-format")
	}

	func parserDidStartDocument() { }

	func parserDidEndDocument() { }

	func foundIgnorableWhitespace(whitespace: String) { }
}
