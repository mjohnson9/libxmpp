//
//  Stream.swift
//  xmppclient
//
//  Created by Michael Johnson on 11/23/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import Foundation
import os.log

private struct AssociatedKeys {
    static var attemptReconnect: UInt8 = 0
    static var currentConnectionAddress: UInt8 = 0
    static var inStream: UInt8 = 0
    static var outStream: UInt8 = 0
    static var readThread: UInt8 = 0
    static var connectionErrors: UInt8 = 0
}

internal class ParserNeedsReset: Error { }

extension XMPPConnection: StreamDelegate, XMPPStateController {
    // MARK: Variables
    private var attemptReconnect: Bool {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.attemptReconnect) as? Bool else {
                return true
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.attemptReconnect, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    internal private(set) var currentConnectionAddress: Int {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.currentConnectionAddress) as? Int else {
                return 0
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.currentConnectionAddress, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var inStream: InputStream! {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.inStream) as? InputStream else {
                return nil
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.inStream, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var outStream: OutputStream! {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.outStream) as? OutputStream else {
                return nil
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.outStream, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var readThread: Thread! {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.readThread) as? Thread else {
                return nil
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.readThread, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var connectionErrors: [Error]! {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.connectionErrors) as? [Error] else {
                return nil
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.connectionErrors, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    internal var streamIsOpen: Bool {
        if self.inStream == nil || self.outStream == nil {
            return false
        }

        let streamStatus = self.inStream.streamStatus
        return (streamStatus == .opening || streamStatus == .open || streamStatus == .reading || streamStatus == .writing)
    }

	// MARK: State functions

	internal func switchState(state: XMPPState) {
		self.state.changingState(nextState: state)
		self.state = state
		self.state.run()
	}

    // MARK: Connection functions

    internal func startConnectionAttempts() {
        if self.connectionAddresses == nil {
            self.dispatchCannotConnect(error: XMPPUnableToConnectError())
            return
        }

        self.connectionErrors = []
        self.connectionErrors.reserveCapacity(self.connectionAddresses.count)

        while self.attemptReconnect {
            if self.currentConnectionAddress > (self.connectionAddresses.count - 1) {
                print("\(self.domain): Ran out of hosts to connect to")
                self.dispatchCannotConnect(error: XMPPUnableToConnectError())
                return
            }

            let connectionAddress = self.connectionAddresses[self.currentConnectionAddress]
            self.currentConnectionAddress += 1

            let error = self.attemptConnection(toHostname: connectionAddress.host, toPort: connectionAddress.port)

            // Send some debug information
            if let error = error {
                print("\(self.domain): Disconnected from \(connectionAddress.host):\(connectionAddress.port) with error: (\(String(describing: error))")
            } else {
                print("\(self.domain): Disconnected from \(connectionAddress.host):\(connectionAddress.port)")
            }
        }
    }

    private func attemptConnection(toHostname hostname: String, toPort port: UInt16) -> Error! {
        print("\(self.domain): Attempting connection to \(hostname):\(port)")

        self.resetState()

        var inStream: InputStream!
        var outStream: OutputStream!

        Stream.getStreamsToHost(withName: hostname, port: Int(port), inputStream: &inStream, outputStream: &outStream)

        self.inStream = inStream
        self.outStream = outStream

        /*self.inStream.delegate = self
         self.outStream.delegate = self*/

        /*self.inStream.setProperty(kCFBooleanTrue, forKey: kCFStreamPropertySocketExtendedBackgroundIdleMode as Stream.PropertyKey)
         self.outStream.setProperty(kCFBooleanTrue, forKey: kCFStreamPropertySocketExtendedBackgroundIdleMode as Stream.PropertyKey)*/

        self.inStream.open()
        self.outStream.open()
        defer {
            if let outStream = self.outStream {
                outStream.close()
            }
            if let inStream = self.inStream {
                inStream.close()
            }
        }

		self.state.run()

        var parser: EventedXMLParser!
		var parserError: Error?

		let bufferSize = Int(4096 * 32)
        let streamBuffer = malloc(bufferSize)!.bindMemory(to: UInt8.self, capacity: bufferSize)
		defer { free(streamBuffer) }

        while self.inStream != nil {
            if self.parserNeedsReset || parser == nil {
                parser = self.createParser()
                self.parserHasReset()

                os_log(.debug, log: XMPPConnection.osLog, "%s: Reset XML parser", self.domain)
            }

            let readLen = inStream.read(streamBuffer, maxLength: bufferSize)
			if readLen == -1 {
				// An error has occured
				break
			}

			let data = Data(bytesNoCopy: streamBuffer, count: readLen, deallocator: .none)

			if let dataString = String(data: data, encoding: .utf8) {
				os_log(.debug, log: XMPPConnection.osLog, "%s -> %s", self.domain, dataString)
			} else {
				os_log(.debug, log: XMPPConnection.osLog, "%s -> (couldn't be decoded as UTF-8) %s", data.map { String(format: "%02hhx", $0)}.joined())
			}

			parserError = parser.feed(data)
			if parserError != nil {
				break
			}
        }

        var errors: [Error] = []
        if let castedError = parserError as NSError? {
            os_log(.debug, log: XMPPConnection.osLog, "%s: Parser error: %@", self.domain, castedError)
            errors.append(castedError)
        }
        if let inStream = self.inStream {
            if let inStreamError = inStream.streamError as NSError? {
                os_log(.debug, log: XMPPConnection.osLog, "%s: Input stream error: %@", self.domain, inStreamError)
                errors.append(inStreamError)
            }
        }
        if let outStream = self.outStream {
            if let outStreamError = outStream.streamError as NSError? {
                os_log(.debug, log: XMPPConnection.osLog, "%s: Output stream error: %@", self.domain, outStreamError)
                errors.append(outStreamError)
            }
        }

        var error: Error! = nil
        if errors.count == 1 {
            error = errors[0]
        } else if errors.count > 1 {
            error = XMPPMultiError(underlyingErrors: errors)
        }

        return error
    }

    // MARK: Functions exposed to other modules
    internal func resetConnectionAttempts() {
        self.currentConnectionAddress = 0
    }

    // MARK: Stream delegate functions
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("\(self.domain): \(aStream) is open")
        case Stream.Event.hasSpaceAvailable:
            #if DEBUG
            print("\(self.domain): \(aStream) has space available")
            #endif
        case Stream.Event.hasBytesAvailable:
            #if DEBUG
            print("\(self.domain): \(aStream) has bytes available")
            #endif
        case Stream.Event.endEncountered:
            print("\(self.domain): \(aStream) encountered EOF")
        case Stream.Event.errorOccurred:
            print("\(self.domain): \(aStream) had an error: \(String(describing: aStream.streamError))")
        default:
            print("\(self.domain): Received unhandled event: \(eventCode)")
        }
    }

    // MARK: Functions for other extensions
    internal func streamEnableTLS() {
        let sslSettings: [NSString: Any] = [
            NSString(format: kCFStreamSSLLevel): kCFStreamSocketSecurityLevelNegotiatedSSL,
            NSString(format: kCFStreamSSLPeerName): NSString(string: self.domain)
        ]

        self.outStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
        self.inStream.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
    }

    // MARK: Write functions

    internal func write(_ element: Element) {
        self.write(string: element.serialize())
    }

    internal func writeStreamEnd() {
        self.write(string: "</stream:stream>")
    }

	internal func write(string: String) {
        guard self.streamIsOpen else {
            os_log(.error, log: XMPPConnection.osLog, "%s: Attempted to write while stream was closed", self.domain)
            return
        }
        let encodedString: Data = string.data(using: .utf8)!
        _ = encodedString.withUnsafeBytes {
            self.outStream.write($0, maxLength: encodedString.count)
        }
        os_log(.debug, log: XMPPConnection.osLog, "%s <- %{private}s", self.domain, string)
    }

    // MARK: Disconnect functions

    public func disconnect() {
		guard self.streamIsOpen else {
			return
		}
        self.switchState(state: StateGracefulClose(stateController: self, data: nil))
    }

    internal func disconnectWithoutRetry() {
        self.attemptReconnect = false
        self.disconnectAndRetry()
    }

    internal func disconnectAndRetry() {
        self.session = nil

        if self.inStream != nil {
            self.inStream.close()
            self.inStream = nil
        }

        if self.outStream != nil {
            self.outStream.close()
            self.outStream = nil
        }
    }

    // MARK: Graceful close timeout

    private func gracefulCloseTimeout() {
        self.disconnectWithoutRetry()
        print("\(self.domain): Graceful close timed out")
    }

    // MARK: Helper functions

	func resetState() {
        self.session = XMPPSession()
		self.resetParser()
    }

    private func createParser() -> EventedXMLParser {
        let parserOptional = EventedXMLParser()
		guard let parser = parserOptional else {
			os_log(.error, log: XMPPConnection.osLog, "%s: Failed to create XML parser", self.domain)
			fatalError()
		}

        parser.delegate = self

        return parser
    }
}
