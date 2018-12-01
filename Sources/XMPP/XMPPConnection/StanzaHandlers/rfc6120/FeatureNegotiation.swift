//
//  FeatureNegotiation.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

private class PreferredFeature {
    public let namespace: String
    public let tag: String
    public let handler: (XMPPConnection) -> (FeatureStanza) -> Void

    public init(namespace: String, tag: String, handler: @escaping (XMPPConnection) -> (FeatureStanza) -> Void) {
        self.namespace = namespace
        self.tag = tag
        self.handler = handler
    }

    public func doesMatch(_ feature: PreferredFeature) -> Bool {
        if self.namespace != "*" && self.namespace != feature.namespace {
            return false
        }

        if self.tag != "*" && self.tag != feature.tag {
            return false
        }

        return true
    }

    public func doesMatch(_ feature: FeatureStanza) -> Bool {
        if self.namespace != "*" && self.namespace != feature.namespace {
            return false
        }

        if self.tag != "*" && self.tag != feature.tag {
            return false
        }

        return true
    }
}

extension XMPPConnection {
    private static let preferredFeatures: [PreferredFeature] = [
        PreferredFeature(namespace: "urn:ietf:params:xml:ns:xmpp-tls", tag: "starttls", handler: XMPPConnection.negotiateTLS)
    ]
    internal func processFeatures(_ stanza: Stanza) {
        for child in stanza.element.children {
            guard let feature = FeatureStanza(child) else {
                os_log(.info, log: XMPPConnection.osLog, "%s: Received feature stanza that couldn't be parsed: %{public}s", child.serialize())
                self.sendStreamErrorAndClose(tag: "invalid-xml")
                return
            }

            self.session.availableFeatures.append(feature)

            if feature.required {
                self.session.requiredFeaturesRemaining[feature.featureKey()] = feature
            } else {
                self.session.optionalFeaturesRemaining[feature.featureKey()] = feature
            }
        }

        self.negotiateNextFeature()
    }

    private func negotiateNextFeature() {
        for (_, requiredFeature) in self.session.requiredFeaturesRemaining {
            for negotiableFeature in XMPPConnection.preferredFeatures where negotiableFeature.doesMatch(requiredFeature) {
                if negotiableFeature.doesMatch(requiredFeature) {
                    return negotiableFeature.handler(self)(requiredFeature)
                }
            }
        }

        if self.session.requiredFeaturesRemaining.count > 0 {
            os_log(.info, log: XMPPConnection.osLog, "%s: We don't support any of the required features. Disconnecting.", self.domain)
            self.sendStreamErrorAndClose(tag: "unsupported-feature")
            return self.fatalConnectionError(XMPPIncompatibleError())
        }

        for (_, optionalFeature) in self.session.optionalFeaturesRemaining {
            for negotiableFeature in XMPPConnection.preferredFeatures where negotiableFeature.doesMatch(optionalFeature) {
                return negotiableFeature.handler(self)(optionalFeature)
            }
        }

        os_log(.info, log: XMPPConnection.osLog, "%s: Negotiation finished.", self.domain)
        self.resetConnectionAttempts() // Finishing negotiation represents a successful connection

        #warning("Currently disconnecting after feature negotiation -- remove this later")
        self.dispatchConnected(status: XMPPConnectionStatus(serviceAvailable: true, secure: self.session!.secure, canLogin: false, canRegister: false))
        self.disconnectGracefully()
    }

    internal func featureNegotiationComplete(_ feature: FeatureStanza) {
        let key = feature.featureKey()
        self.session.requiredFeaturesRemaining.removeValue(forKey: key)
        self.session.optionalFeaturesRemaining.removeValue(forKey: key)

        self.negotiateNextFeature()
    }
}
