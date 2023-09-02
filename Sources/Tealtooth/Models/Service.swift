import CoreBluetooth

public class Service {
    public internal(set) var proxy: CBService
    init(proxy: CBService) {
        self.proxy = proxy
    }
}
