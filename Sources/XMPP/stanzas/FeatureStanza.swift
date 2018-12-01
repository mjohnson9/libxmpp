//
//  FeatureStanza.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/1/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class FeatureStanza: Stanza {
    /// Whether or not this feature is required
    public let required: Bool

    override init?(_ element: Element) {
        var wasRequired = false
        for child in element.children where child.tag == "required" {
            wasRequired = true
            break
        }
        self.required = wasRequired

        super.init(element)
    }
}
