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
    internal func receivedStanza(element: Element) {
        os_log(.debug, log: XMPPConnection.osLog, "%s <- %{private}s", self.domain, element.serialize())

        guard let stanza = Stanza(element) else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Unable to parse incoming stanza: %{private}s", element.serialize())
            self.sendStreamErrorAndClose(tag: "unsupported-stanza-type")
            return
        }

        switch stanza.namespace {
        case "http://etherx.jabber.org/streams":
            return self.processStreamsNamespace(stanza)
        case "urn:ietf:params:xml:ns:xmpp-tls":
            return self.processTlsNamespace(stanza)
        default:
            os_log(.info, log: XMPPConnection.osLog, "%s: Unable to handle stanza from namespace %{public}s", self.domain, stanza.namespace)
            self.sendStreamErrorAndClose(tag: "unsupported-stanza-type")
            return
        }
    }
}
