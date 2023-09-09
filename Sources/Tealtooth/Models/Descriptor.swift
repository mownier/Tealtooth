import CoreBluetooth

public class Descriptor {
    public internal(set) var proxy: CBDescriptor
    init(proxy: CBDescriptor) {
        self.proxy = proxy
    }
}
