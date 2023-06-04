import Foundation

public enum TealtoothError: Swift.Error {
    case unimplemented
    case bluetoothNotPoweredOn
    case alreadyScanning
}

public struct TealtoothErrors: Swift.Error {
    public let list: [Any]
    public init(list: [Any]) {
        self.list = list
    }
}
