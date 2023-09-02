import CoreBluetooth

public class BluetoothAssistant {
    public private(set) var name: String
    let centralManager: CBCentralManager
    let centralManagerDelegate: CentralManagerDelegate
    var semaphores: [Semaphore]
    var didInitiateDisconnect: Bool = false
    var didInitiateConnect: Bool = false
    var didInitiateStopScanWithTimeout: Bool = false
    var connectResult: Result<Peripheral, Swift.Error>?
    var disconnectResult: Result<Peripheral, Swift.Error>?
    public init(
        name: String,
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        self.semaphores = []
        self.name = name
        let centralManagerDelegate = CentralManagerDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
        self.centralManagerDelegate = centralManagerDelegate
        self.centralManagerDelegate.assistant = self
    }
}
