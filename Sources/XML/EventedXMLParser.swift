//
//  EventedXMLParser.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/24/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

/*import Foundation
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

    public func feed(_ data: Data) {
        data.withUnsafeBytes { (_: UnsafePointer<Int8>) -> Void in
            //xmlParseChunk(self.xmlParserContext, dataPointer, data.count, 0)
        }
    }

    // MARK: Helpers

    private static func createSaxHandler() -> xmlSAXHandler {
        var saxHandler = xmlSAXHandler()
        saxHandler.initialized = XML_SAX2_MAGIC

        return saxHandler
    }
}

class XMLParsingError: Error {
    public let message: String

    init(message: String) {
        self.message = message
    }
}

@objc protocol EventedXMLParserDelegate: class {
    @objc optional func parserDidStartDocument()
    @objc optional func parserDidEndDocument()

    @objc optional func elementStarted(tag: String, namespaceURI: String?, prefix: String?, namespaces: [String: String], attributes: [String: String])
    @objc optional func elementEnded(tag: String, namespaceURI: String?, prefix: String?)

    @objc optional func resolveExternalEntityName(name: String, systemID: String?) -> Data?

    @objc optional func parseErrorOccured(error: Error)

    @objc optional func foundCharacters(characters: String)
    @objc optional func foundIgnorableWhitespace(whitespace: String)

    @objc optional func foundProcessingInstruction(target: String, data: String?)
    @objc optional func foundComment(comment: String)
    @objc optional func foundCDATA(data: Data)
}*/
