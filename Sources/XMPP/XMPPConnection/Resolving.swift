//
//  Resolving.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

private struct AssociatedKeys {
    // static var resolver: UInt8 = 0
}

extension XMPPConnection {
    // MARK: Variables

    private var srvName: String {
        return "_xmpp-client._tcp." + self.domain
    }

    // MARK: Functions exposed to other modules

    internal func resolveSRV() {
        os_log(.debug, log: XMPPConnection.osLog, "%s: Resolving SRV records", self.domain)

        let resolver = Resolver(srvName: self.srvName)
        let error = resolver.resolve()
        guard error == nil else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Got an error resolving SRV record: %s", String(describing: error))
            self.switchToFallbackDNS()
            return
        }

        var resultsCasted: [SRVRecord] = []
        for result in resolver.results {
            guard let resultCasted = result as? SRVRecord else {
                os_log(.error, log: XMPPConnection.osLog, "%s: Received record of type %{public}s, but expecting SRVRecord", self.domain, String(describing: type(of: result)))
                fatalError()
            }

            resultsCasted.append(resultCasted)
        }

        SRVRecord.shuffle(records: &resultsCasted)
        self.handleSRVResults(results: resultsCasted)
    }

    // MARK: Handle DNS results

    private func switchToFallbackDNS() {
        os_log(.debug, log: XMPPConnection.osLog, "%s: Switching to fallback DNS", self.domain)
        self.connectionAddresses = [(host: self.domain, port: UInt16(5222))]
        self.startConnectionAttempts()
    }

    private func handleSRVResults(results: [SRVRecord]!) {
        guard let results = results, results.count > 0 else {
            os_log(.info, log: XMPPConnection.osLog, "%s: Received no SRV records", self.domain)
            self.switchToFallbackDNS()
            return
        }

        // Check for service not supported record
        if results.count == 1 {
            let result = results[0]
            if result.target == "." {
                os_log(.info, log: XMPPConnection.osLog, "%s: The only SRV record for this domain has a target of \"%{public}s\". Service is unavailable for this domain.", self.domain, result.target)
                self.dispatchCannotConnect(error: XMPPServiceNotSupportedError())
                return
            }
        }

        self.connectionAddresses = []
        self.connectionAddresses.reserveCapacity(results.count)
        for result in results {
            self.connectionAddresses.append((host: result.target, port: result.port))
        }

        self.startConnectionAttempts()
    }

    // MARK: SRVResolverDelegate functions

    /*public func srvResolver(_ resolver: SRVResolver!, didStopWithError error: Error!) {
        self.resolverTimer.invalidate()
        self.resolverTimer = nil

        if error != nil {
            os_log(.info, log: XMPPConnection.osLog, "%s: Failed to resolve SRV records: %s", self.domain, String(describing: error))
            self.switchToFallbackDNS()
            return
        }

        os_log(.debug, log: XMPPConnection.osLog, "%s: Received SRV records: %@", self.domain, self.resolver.results)
        self.handleSRVResults(results: self.convertSRVRecords(results: self.resolver.results))
    }*/

    // MARK: Timeout functions

    /*@objc private func resolverTimeout(timer: Timer) {
        if self.resolver.isFinished {
            return
        }

        os_log(.info, log: XMPPConnection.osLog, "%s: Resolver timed out", self.domain)

        self.resolver.stop()
        self.handleSRVResults(results: self.convertSRVRecords(results: self.resolver.results))
    }*/

    // MARK: Helper functions

    /*private func convertSRVRecords(results: [Any]!) -> [SRVRecord]? {
        if results == nil || results.count == 0 {
            return nil
        }

        var converted: [SRVRecord] = []
        converted.reserveCapacity(results.count)

        for resultAny in results {
            guard let result = resultAny as? NSDictionary else {
                os_log(.error, "%s: SRV result record was not an NSDictionary", self.domain)
                fatalError()
            }
            let record = SRVRecord(dict: result)
            converted.append(record)
        }

        SRVRecord.shuffle(records: &converted)

        return converted
    }*/
}
