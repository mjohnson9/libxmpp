//
//  StanzaHandling.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

extension XMPPConnection {
    private static let stanzaHandlers: [String: (XMPPConnection) -> (Stanza) -> Void] = [
        // Stream features
        "{http://etherx.jabber.org/streams}features": XMPPConnection.processFeatures,
        // Stream errors
        "{http://etherx.jabber.org/streams}error": XMPPConnection.receivedStreamError,

        // TLS
        "{urn:ietf:params:xml:ns:xmpp-tls}proceed": XMPPConnection.processTLSProceed,
        "{urn:ietf:params:xml:ns:xmpp-tls}failure": XMPPConnection.processTLSFailure
    ]
    internal func receivedStanza(element: Element) {
        os_log(.debug, log: XMPPConnection.osLog, "%s -> %{private}s", self.domain, element.serialize())

        guard let stanza = Stanza(element) else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Unable to parse incoming stanza: %{private}s", element.serialize())
            self.sendStreamErrorAndClose(tag: "unsupported-stanza-type")
            return
        }

        let keys = [stanza.mapKey(), stanza.mapKeyNamespaceOnly(), stanza.mapKeyTagOnly()]
        for key in keys {
            if let handler = XMPPConnection.stanzaHandlers[key] {
                handler(self)(stanza)
                return
            }
        }

        os_log(.info, log: XMPPConnection.osLog, "%s: Unable to handle stanza from namespace %{public}s", self.domain, stanza.namespace)
        self.sendStreamErrorAndClose(tag: "unsupported-stanza-type")
    }
}
