import CoreBluetooth

public class Characteristic {
    public internal(set) var proxy: CBCharacteristic
    init(proxy: CBCharacteristic) {
        self.proxy = proxy
    }
}
