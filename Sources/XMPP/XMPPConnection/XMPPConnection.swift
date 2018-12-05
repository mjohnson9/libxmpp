//
//  xmppconnection.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/21/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import Network
import os.log

public class XMPPConnection: NSObject {
    static internal let osLog = OSLog(subsystem: "computer.johnson.libxmpp.XMPPConnection", category: "network")

    public let domain: String

    // MARK: Shared variables
    internal var connectionAddresses: [(host: String, port: UInt16)]!
    internal private(set) var allowInsecure: Bool = false
    public private(set) var isProbe: Bool

    public weak var connectionDelegate: XMPPConnectionDelegate!

	internal var session: XMPPSession!
	internal var state: XMPPState

    // MARK: Initialization and deinitialization

    public init(forDomain domain: String, allowInsecure: Bool, isProbe: Bool) {
        self.domain = domain
        self.allowInsecure = allowInsecure
        self.isProbe = isProbe
    }

    deinit {
        objc_removeAssociatedObjects(self)
    }

    // MARK: Public interface

    public func connect() {
        os_log(.info, log: XMPPConnection.osLog, "%s: Connecting", self.domain)

        // Start by attempting to resolve SRV records
        self.resolveSRV()
    }

    internal func dispatchConnected(status: XMPPConnectionStatus) {
        self.connectionDelegate?.xmppConnected(connectionStatus: status)
    }

    internal func dispatchCannotConnect(error: Error) {
        self.connectionDelegate?.xmppCannotConnect(error: error)
    }

    internal func fatalConnectionError(_ error: Error) {
        self.disconnectWithoutRetry()
        self.dispatchCannotConnect(error: error)
    }
}

protocol XMPPStanzaObserver {
    func stanzaReceived(element: Element)
}

public struct XMPPConnectionStatus {
    var serviceAvailable: Bool
    var secure: Bool
    var canLogin: Bool
    var canRegister: Bool
}

public protocol XMPPConnectionDelegate: class {
    func xmppCannotConnect(error: Error)
    func xmppConnected(connectionStatus: XMPPConnectionStatus)
}
