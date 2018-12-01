//
//  Stanza.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class Stanza {
    // MARK: Common attributes
    /// The XML element tag of this stanza
    public let tag: String
    /// The resolved XML namespace of this stanza
    public let namespace: String
    /// The message ID sent with this stanza
    public let id: String
    // swiftlint:disable:previous identifier_name
    /// The address that this stanza came from
    public let from: String
    /// The address that this stanza was sent to
    public let to: String
    // swiftlint:disable:previous identifier_name

    // MARK: For internal use
    /// The element given for creating the stanza
    public let element: Element

    // MARK: Initializers
    init?(_ element: Element) {
        self.element = element

        self.tag = element.tag
        self.namespace = element.resolvedNamespace

        if let idValue = element.attributes["id"] {
            self.id = idValue
        } else {
            self.id = ""
        }

        if let from = element.attributes["from"] {
            self.from = from
        } else {
            self.from = ""
        }

        // swiftlint:disable:next identifier_name
        if let to = element.attributes["to"] {
            self.to = to
        } else {
            self.to = ""
        }
    }

    public func mapKey() -> String {
        if self.namespace == "" {
            return self.tag
        }
        return "{" + self.namespace + "}" + self.tag
    }

    public func mapKeyTagOnly() -> String {
        if self.namespace == "" {
            return self.tag
        }
        return "{*}" + self.tag
    }

    public func mapKeyNamespaceOnly() -> String {
        if self.namespace == "" {
            return self.tag
        }
        return "{" + self.namespace + "}*"
    }
}
