import Foundation

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

    public init(address: IPAddress, port: Port) {
        socket = NWUDPSocket(host: address.presentation, port: Int(port.value))!
        socket.delegate = self
    }

    public func resolve(session: DNSSession) {
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
