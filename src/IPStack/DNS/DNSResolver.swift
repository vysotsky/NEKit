import Foundation
import CocoaLumberjackSwift

public protocol DNSResolverProtocol: class {
    weak var delegate: DNSResolverDelegate? { get set }
    func resolve(session: DNSSession)
    func stop()
}

public protocol DNSResolverDelegate: class {
    func didReceive(rawResponse: Data)
}

open class UDPDNSResolver: DNSResolverProtocol, NWUDPSocketDelegate {
    var socket: NWUDPSocket
    public weak var delegate: DNSResolverDelegate?
    public var didFail: (() -> (IPAddress, NEKit.Port)?)?
    
    let replacements: [String: String]?

    public init(address: IPAddress, port: Port, replacements: [String: String]? = nil) {
        self.replacements = replacements
        socket = NWUDPSocket(host: address.presentation, port: Int(port.value))!
        socket.delegate = self
    }

    public func resolve(session: DNSSession) {
        if let replacements = replacements {
            var needsBuild = false
            
            for (idx, query) in session.requestMessage.queries.enumerated() {
                for (origonal, replacement) in replacements {
                    if query.name == origonal {
                        let newQuery = DNSQuery(name: replacement, type: query.type, klass: query.klass, originalName: origonal)
                        session.requestMessage.queries[idx] = newQuery
                        
                        needsBuild = true
                    }
                }
            }
            
            if needsBuild {
                if session.requestMessage.buildMessage() {
                    DDLogInfo("Rewrote payload for request")
                } else {
                    DDLogInfo("Problem writing payload for request")
                }
            }
        }
        
        socket.write(data: session.requestMessage.payload)
    }

    public func stop() {
        socket.disconnect()
    }

    public func didReceive(data: Data, from: NWUDPSocket) {
        delegate?.didReceive(rawResponse: data)
    }
    
    public func didCancel(socket: NWUDPSocket) {
        if let (address, port) = didFail?() {
            self.socket.disconnect()
            self.socket = NWUDPSocket(host: address.presentation, port: Int(port.value))!
            self.socket.delegate = self
        }
    }
}
