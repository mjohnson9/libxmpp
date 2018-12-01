//
//  XMPPSession.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/21/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

class XMPPSession {
    struct RequestsMade {
        var endStream: Bool = false
        var startTls: Bool = false
    }

    var secure: Bool = false

    var availableFeatures: [FeatureStanza] = []
    var requiredFeaturesRemaining: [String: FeatureStanza] = [:]
    var optionalFeaturesRemaining: [String: FeatureStanza] = [:]

    var requestsMade: RequestsMade = RequestsMade()
    var receivedStreamStart: Bool = false
    var openingStreamQualifiedName: String!

    var currentElement: Element!
    var namespacesForElement: [String: String]!
    var namespacePrefixes: [String: [String]] = [:]
}
