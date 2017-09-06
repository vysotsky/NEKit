import Foundation
import CocoaLumberjackSwift

open class DNSSession {
    open let requestMessage: DNSMessage
    var requestIPPacket: IPPacket?
    open var realIP: IPAddress?
    open var fakeIP: IPAddress?
    open var realResponseMessage: DNSMessage?
    var realResponseIPPacket: IPPacket?
    open var matchedRule: Rule?
    open var matchResult: DNSSessionMatchResult?
    var indexToMatch = 0
    var expireAt: Date?

    init?(message: DNSMessage) {
        guard message.messageType == .query else {
            DDLogError("DNSSession can only be initailized by a DNS query.")
            return nil
        }

        guard message.queries.count == 1 else {
            DDLogError("Expecting the DNS query has exact one query entry.")
            return nil
        }

        requestMessage = message
    }

    convenience init?(packet: IPPacket) {
        guard let payload = packet.protocolParser.payload, let message = DNSMessage(payload: payload) else {
            return nil
        }
        self.init(message: message)
        requestIPPacket = packet
    }
}

extension DNSSession: CustomStringConvertible {
    public var description: String {
        return "<\(type(of: self)) domain: \(String(describing: self.requestMessage.queries.first?.name)) realIP: \(String(describing: realIP)) fakeIP: \(String(describing: fakeIP))>"
    }
}
