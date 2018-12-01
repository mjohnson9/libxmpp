//
//  XMPPClientDelegate.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/1/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation

public protocol XMPPClientDelegate: class {
    func xmppCannotConnect(error: Error)
    func xmppConnected(connectionStatus: XMPPConnectionStatus)
}
