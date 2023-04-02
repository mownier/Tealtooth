import CoreBluetooth

public class Peripheral {
    public internal(set) var proxy: CBPeripheral
    init(proxy: CBPeripheral) {
        self.proxy = proxy
    }
}
