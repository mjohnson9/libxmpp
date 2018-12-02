//
//  SRVRecord.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/22/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log
import dnssd
import dnsutil

class SRVRecord: DNSRecord, CustomStringConvertible {
    var target: String
    var port: UInt16
    var priority: UInt16
    var weight: UInt16
    internal var weightForShuffle: Float

    public var description: String {
        return "IN SRV " + String(self.priority) + " " + String(self.weight) + " " + String(self.port) + " " + String(self.target)
    }

    init(record: dns_resource_record_t) {
        guard record.dnstype == kDNSServiceType_SRV else {
            fatalError("SRVRecord constructor given a non-SRV record")
        }
        guard let dataPointer = record.data.SRV else {
            fatalError("Failed to get SRV data from resource record")
        }
        let data = dataPointer.pointee

        self.target = String(cString: data.target)
        self.port = data.port
        self.priority = data.priority
        self.weight = data.weight

        let weightNormalized: Float = (self.weight == 0 ? 0.1 : Float(self.weight))
        self.weightForShuffle = Float.random(in: 0..<1) * (1.0 / weightNormalized)
    }

    static func shuffle(records: inout [SRVRecord]) {
        records.sort(by: SRVRecord.compare)
    }

    internal static func compare(recordOne: SRVRecord, recordTwo: SRVRecord) -> Bool {
        if recordOne.priority != recordTwo.priority {
            return recordOne.priority < recordTwo.priority
        }

        return recordOne.weightForShuffle < recordTwo.weightForShuffle
    }
}
