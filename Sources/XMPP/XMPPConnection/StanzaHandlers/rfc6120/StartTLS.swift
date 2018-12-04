//
//  TLS.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

extension XMPPConnection {
    internal func negotiateTLS(_ stanza: Stanza) {
        let element = Element()
        element.tag = "starttls"
        element.defaultNamespace = "urn:ietf:params:xml:ns:xmpp-tls"

        self.session!.requestsMade.startTls = true
        self.write(element)
    }

    internal func processTLSProceed(_ stanza: Stanza) {
        guard self.session!.requestsMade.startTls else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Server sent StartTLS proceed without being asked", self.domain)
            self.sendStreamErrorAndClose(tag: "invalid-xml")
            return
        }

        os_log(.info, log: XMPPConnection.osLog, "%s: Received StartTLS proceed", self.domain)

        self.resetParser()
        self.streamEnableTLS()

        os_log(.info, log: XMPPConnection.osLog, "%s: Enabled TLS", self.domain)

        self.resetSession()
        self.session!.secure = true
        self.sendStreamOpener()
    }

    internal func processTLSFailure(_ stanza: Stanza) {
        guard self.session!.requestsMade.startTls else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Server sent StartTLS failure without being asked", self.domain)
            self.disconnectAndRetry()
            return
        }

        os_log(.info, log: XMPPConnection.osLog, "%s: Received StartTLS failure", self.domain)
        self.disconnectAndRetry()
    }
}
