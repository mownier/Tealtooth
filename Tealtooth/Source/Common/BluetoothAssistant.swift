import CoreBluetooth

public class BluetoothAssistant {
    private var centralManager: CBCentralManager
    private var centralManagerDelegate: CentralManagerDelegate
    public init(
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        let centralManagerDelegate = CentralManagerDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
        self.centralManagerDelegate = centralManagerDelegate
    }
}
