//
//  DNSServiceError.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/1/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import dnssd

class DNSServiceError: Error {
    public var description: String {
        return self.name + " (" + String(self.underlyingError) + ")"
    }

    public let name: String
    public let underlyingError: DNSServiceErrorType

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    init(_ error: DNSServiceErrorType) {
        self.underlyingError = error

        switch Int(self.underlyingError) {
        case kDNSServiceErr_AlreadyRegistered:
            self.name = "kDNSServiceErr_AlreadyRegistered"
        case kDNSServiceErr_BadFlags:
            self.name = "kDNSServiceErr_BadFlags"
        case kDNSServiceErr_BadInterfaceIndex:
            self.name = "kDNSServiceErr_BadInterfaceIndex"
        case kDNSServiceErr_BadKey:
            self.name = "kDNSServiceErr_BadKey"
        case kDNSServiceErr_BadParam:
            self.name = "kDNSServiceErr_BadParam"
        case kDNSServiceErr_BadReference:
            self.name = "kDNSServiceErr_BadReference"
        case kDNSServiceErr_BadSig:
            self.name = "kDNSServiceErr_BadSig"
        case kDNSServiceErr_BadState:
            self.name = "kDNSServiceErr_BadState"
        case kDNSServiceErr_BadTime:
            self.name = "kDNSServiceErr_BadTime"
        case kDNSServiceErr_DoubleNAT:
            self.name = "kDNSServiceErr_DoubleNAT"
        case kDNSServiceErr_Firewall:
            self.name = "kDNSServiceErr_Firewall"
        case kDNSServiceErr_Incompatible:
            self.name = "kDNSServiceErr_Incompatible"
        case kDNSServiceErr_Invalid:
            self.name = "kDNSServiceErr_Invalid"
        case kDNSServiceErr_NATPortMappingDisabled:
            self.name = "kDNSServiceErr_NATPortMappingDisabled"
        case kDNSServiceErr_NATPortMappingUnsupported:
            self.name = "kDNSServiceErr_NATPortMappingUnsupported"
        case kDNSServiceErr_NATTraversal:
            self.name = "kDNSServiceErr_NATTraversal"
        case kDNSServiceErr_NameConflict:
            self.name = "kDNSServiceErr_NameConflict"
        case kDNSServiceErr_NoAuth:
            self.name = "kDNSServiceErr_NoAuth"
        case kDNSServiceErr_NoError:
            self.name = "kDNSServiceErr_NoError"
        case kDNSServiceErr_NoMemory:
            self.name = "kDNSServiceErr_NoMemory"
        case kDNSServiceErr_NoRouter:
            self.name = "kDNSServiceErr_NoRouter"
        case kDNSServiceErr_NoSuchKey:
            self.name = "kDNSServiceErr_NoSuchKey"
        case kDNSServiceErr_NoSuchName:
            self.name = "kDNSServiceErr_NoSuchName"
        case kDNSServiceErr_NoSuchRecord:
            self.name = "kDNSServiceErr_NoSuchRecord"
        case kDNSServiceErr_NotInitialized:
            self.name = "kDNSServiceErr_NotInitialized"
        case kDNSServiceErr_PollingMode:
            self.name = "kDNSServiceErr_PollingMode"
        case kDNSServiceErr_Refused:
            self.name = "kDNSServiceErr_Refused"
        case kDNSServiceErr_ServiceNotRunning:
            self.name = "kDNSServiceErr_ServiceNotRunning"
        case kDNSServiceErr_Timeout:
            self.name = "kDNSServiceErr_Timeout"
        case kDNSServiceErr_Transient:
            self.name = "kDNSServiceErr_Transient"
        case kDNSServiceErr_Unknown:
            self.name = "kDNSServiceErr_Unknown"
        case kDNSServiceErr_Unsupported:
            self.name = "kDNSServiceErr_Unsupported"
        default:
            self.name = "unknown"
        }
    }
}
