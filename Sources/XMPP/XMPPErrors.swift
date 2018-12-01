//
//  XMPPErrors.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/22/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

public class XMPPErrorStanza: Error {
    var stanza: Element

    init(stanza: Element) {
        self.stanza = stanza
    }
}

public class XMPPNoSuchDomainError: Error {
}

public class XMPPServiceNotSupportedError: Error {
}

public class XMPPUnableToConnectError: Error {
}

public class XMPPCriticalSSLError: Error {
}

public class XMPPIncompatibleError: Error {
}

public class XMPPXMLError: Error {
}
