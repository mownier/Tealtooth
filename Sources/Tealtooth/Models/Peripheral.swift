import CoreBluetooth

public class Peripheral {
    public internal(set) var proxy: CBPeripheral
    var keyName: String { proxy.keyName }
    init(proxy: CBPeripheral) {
        self.proxy = proxy
    }
}

extension CBPeripheral {
    var keyName: String { identifier.uuidString }
}
