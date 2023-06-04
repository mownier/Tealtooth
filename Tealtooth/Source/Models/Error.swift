import Foundation

public enum TealtoothError: Swift.Error {
    case unimplemented
    case bluetoothNotPoweredOn
    case alreadyScanning
    case scanningNotActive
    case timedOutWhileTryingToConnect
    case errorNotDetermined
    case connectResultIsNil
    case stillConnecting
    case stillDisconnecting
    case timedOutWhileTryingToDisconnect
    case disconnectResultIsNil
    case failedToConvertFromStringToUUID
    case peripheralNotFound
}

public struct TealtoothErrors: Swift.Error {
    public let list: [Any]
    public init(list: [Any]) {
        self.list = list
    }
}
