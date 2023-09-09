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
    case timedOutWhileTryingToReadRSSI
    case peripheralNotConnected
    case readRSSIResultIsNil
    case timedOutWhileTryingToDiscoverServices
    case discoverServicesResultIsNil
    case serviceNotFound
    case timedOutWhileTryingToDiscoverIncludedServices
    case discoverIncludedServicesResultIsNil
    case includedServiceNotFound
    case timedOutWhileTryingToDiscoverCharacteristics
    case discoverCharacteristicsResultIsNil
    case characteristicNotFound
    case timedOutWhileTryingToReadCharacteristic
    case readCharacteristicResultIsNil
    case timedOutWhileTryingToWriteCharacteristic
    case writeCharacteristicResultIsNil
    case timedOutWhileTryingToUpdateNotifyStatus
    case updateNotifyStatusResultIsNil
    case timedOutWhileTryingToDiscoverDescriptors
    case discoverDescriptorsResultIsNil
    case descriptorNotFound
    case timedOutWhileTryingToReadDescriptor
    case readDescriptorResultIsNil
    case timedOutWhileTryingToWriteDescriptor
    case writeDescriptorResultIsNil
}

public struct TealtoothErrors: Swift.Error {
    public let list: [Any]
    public init(list: [Any]) {
        self.list = list
    }
}
