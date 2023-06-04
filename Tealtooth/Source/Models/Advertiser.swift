import CoreBluetooth

public class Advertiser {
    public let peripehral: Peripheral
    public let info: [String : Any]
    public let rssi: Int
    public init(peripheral: Peripheral, info: [String : Any], rssi: Int) {
        self.peripehral = peripheral
        self.info = info
        self.rssi = rssi
    }
}
