//
//  EventedXMLParser.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/24/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import libxml2

class EventedXMLParser {
    private static var xmlHandler: xmlSAXHandler = createSaxHandler()

    public weak var delegate: EventedXMLParserDelegate?

    private var xmlParserContext: xmlParserCtxtPtr! = nil

    init?() {
        let selfPointer = Unmanaged<EventedXMLParser>.passUnretained(self).toOpaque()
        guard let parserContext = xmlCreatePushParserCtxt(&EventedXMLParser.xmlHandler, selfPointer, nil, 0, nil) else {
            return nil
        }
        self.xmlParserContext = parserContext
    }

    deinit {
        xmlFreeParserCtxt(self.xmlParserContext)
    }

    public func feed(_ data: Data) -> Error? {
        let parserError = data.withUnsafeBytes { (dataPointer: UnsafePointer<Int8>) in
            return xmlParseChunk(self.xmlParserContext, dataPointer, Int32(data.count), 0)
        }

		return nil
    }

    // MARK: Helpers

    private static func createSaxHandler() -> xmlSAXHandler {
        var saxHandler = xmlSAXHandler()
        saxHandler.initialized = XML_SAX2_MAGIC

		saxHandler.startDocument = { (context) in
			guard let context = context else {
				return
			}

			let parser = EventedXMLParser.fromContext(context)
			parser.delegate?.parserDidStartDocument()
		}

		saxHandler.endDocument = { (context) in
			guard let context = context else {
				return
			}

			let parser = EventedXMLParser.fromContext(context)
			parser.delegate?.parserDidEndDocument()
		}

		saxHandler.startElementNs = { (context, localName, prefix, URI, numNamespaces, namespacesPointer, numAttributes, numDefaulted, attributesPointer) in
			guard let context = context else {
				return
			}

			let parser = EventedXMLParser.fromContext(context)
		}

        return saxHandler
    }

	private static func fromContext(_ context: UnsafeMutableRawPointer) -> EventedXMLParser {
		return Unmanaged<EventedXMLParser>.fromOpaque(context).takeUnretainedValue()
	}
}

class XMLParsingError: Error {
    public let message: String

    init(message: String) {
        self.message = message
    }
}

protocol EventedXMLParserDelegate: class {
    func parserDidStartDocument()
    func parserDidEndDocument()

    func elementStarted(tag: String, namespaceURI: String?, prefix: String, namespaces: [String: String], attributes: [String: String])
    func elementEnded(tag: String, namespaceURI: String?, prefix: String?)

    func resolveExternalEntityName(name: String, systemID: String?) -> Data?

    func parseErrorOccured(error: Error)

    func foundCharacters(characters: String)
    func foundIgnorableWhitespace(whitespace: String)

    func foundProcessingInstruction(target: String, data: String?)
    func foundComment(comment: String)
    func foundCDATA(data: Data)
}
