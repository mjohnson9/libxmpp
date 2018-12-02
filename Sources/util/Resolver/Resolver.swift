//
//  Resolver.swift
//  libxmpp
//
//  Created by Michael Johnson on 12/1/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log
import dnssd
import dnsutil

internal class Resolver {
    static internal let osLog = OSLog(subsystem: "computer.johnson.libxmpp.Resolver", category: "network")

    private let name: String
    private let queryType: UInt16

    private var continueProcessing: Bool = true

    private var error: Error! = nil
    public var results: [DNSRecord] = []

    init(srvName: String) {
        self.name = srvName
        self.queryType = UInt16(kDNSServiceType_SRV)
    }

    init(hostname: String) {
        self.name = hostname
        self.queryType = UInt16(kDNSServiceType_A)
    }

    public func resolve() -> Error {
        self.error = nil

        let dnsServiceRef: UnsafeMutablePointer<DNSServiceRef?> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<DNSServiceRef>.size)
        var dnsServiceRefWasInitialized = false
        defer {
            if dnsServiceRefWasInitialized {
                DNSServiceRefDeallocate(dnsServiceRef.pointee)
            }
            dnsServiceRef.deallocate()
        }

        let dnsCallback: DNSServiceQueryRecordReply = { (dnsServiceRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, error: DNSServiceErrorType, fullNameCString: UnsafePointer<Int8>?, rrType: UInt16, rrClass: UInt16, rrDataLen: UInt16, rrDataPointer: UnsafeRawPointer?, ttl: UInt32, userData: UnsafeMutableRawPointer?) in
            guard let userData = userData else {
                os_log(.error, log: Resolver.osLog, "User data was nil in callback from SRV record processor")
                fatalError()
            }
            let resolverClass = Unmanaged<Resolver>.fromOpaque(userData).takeUnretainedValue()
            resolverClass.queryRecordCallback(dnsServiceRef: dnsServiceRef, flags: flags, interfaceIndex: interfaceIndex, error: error, fullNameCString: fullNameCString, rrType: rrType, rrClass: rrClass, rDataLen: rrDataLen, rDataPointer: rrDataPointer, ttl: ttl)
        }

        let errorNum = self.name.withCString { (srvNameCString: UnsafePointer<Int8>) -> DNSServiceErrorType in
            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            let error = DNSServiceQueryRecord(
                dnsServiceRef,
                kDNSServiceFlagsReturnIntermediates | kDNSServiceFlagsTimeout,
                0,
                srvNameCString,
                self.queryType,
                UInt16(kDNSServiceClass_IN),
                dnsCallback,
                selfPointer
            )
            dnsServiceRefWasInitialized = true

            return error
        }
        let error: Error! = (errorNum == kDNSServiceErr_NoError ? nil : DNSServiceError(errorNum))
        guard error == nil else {
            os_log(.error, log: Resolver.osLog, "Failed to create DNS resolver: %s", String(describing: error))
            fatalError()
        }

        while self.continueProcessing {
            let error = DNSServiceProcessResult(dnsServiceRef.pointee)
            guard error == kDNSServiceErr_NoError else {
                return DNSServiceError(error)
            }
        }

        return self.error
    }

    // swiftlint:disable:next function_parameter_count
    internal func queryRecordCallback(dnsServiceRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, error: DNSServiceErrorType, fullNameCString: UnsafePointer<Int8>?, rrType: UInt16, rrClass: UInt16, rDataLen: UInt16, rDataPointer: UnsafeRawPointer?, ttl: UInt32) {
        if (flags & kDNSServiceFlagsMoreComing) != kDNSServiceFlagsMoreComing {
            self.continueProcessing = false
        }
        guard error == kDNSServiceErr_NoError else {
            let serviceError = DNSServiceError(error)
            self.error = serviceError
            return
        }
        guard rrType == self.queryType else {
            // Probably an intermediate
            return
        }
        guard let rDataPointer = rDataPointer else {
            fatalError("Not all needed variables are present")
        }

        var rrData = Data()
        rrData.reserveCapacity(1 + (MemoryLayout<UInt16>.size * 2) + MemoryLayout<UInt32>.size + MemoryLayout<UInt16>.size + Int(rDataLen))

        // Write full name of RR
        var fullNameLength = UInt8(0)
        rrData.append(UnsafeBufferPointer(start: &fullNameLength, count: 1))
        //rrData.append(fullNameData)

        var rrTypeBigEndian = rrType.bigEndian
        rrData.append(UnsafeBufferPointer(start: &rrTypeBigEndian, count: 1))

        var rrClassBigEndian = rrClass.bigEndian
        rrData.append(UnsafeBufferPointer(start: &rrClassBigEndian, count: 1))

        var ttlBigEndian = ttl.bigEndian
        rrData.append(UnsafeBufferPointer(start: &ttlBigEndian, count: 1))

        var rDataLenBigEndian = rDataLen.bigEndian
        rrData.append(UnsafeBufferPointer(start: &rDataLenBigEndian, count: 1))

        let rDataBytes = rDataPointer.assumingMemoryBound(to: UInt8.self)
        rrData.append(rDataBytes, count: Int(rDataLen))

        print(rrData.map { String(format: "%02hhx", $0) }.joined())

        let resourceRecordPointerOptional = rrData.withUnsafeBytes { (rrBytes: UnsafePointer<Int8>) in
            return dns_parse_resource_record(rrBytes, UInt32(rrData.count))
        }

        guard let resourceRecordPointer = resourceRecordPointerOptional else {
            fatalError("Failed to parse resource record")
        }

        let resourceRecord = resourceRecordPointer.pointee
        self.insertRecord(record: resourceRecord)
    }

    private func insertRecord(record: dns_resource_record_t) {
        switch Int(record.dnstype) {
        case kDNSServiceType_SRV:
            self.results.append(SRVRecord(record: record))
        default:
            os_log(.error, log: Resolver.osLog, "Unable to handle resource record of type %d", record.dnstype)
            fatalError()
        }
    }
}
