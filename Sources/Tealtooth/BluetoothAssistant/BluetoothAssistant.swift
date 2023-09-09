import CoreBluetooth

public class BluetoothAssistant {
    public private(set) var name: String
    let centralManager: CBCentralManager
    let centralManagerDelegate: CentralManagerDelegate
    let peripheralDelegate: PeripheralDelegate
    var semaphores: [Semaphore]
    var processors: [Processor]
    var didInitiateDisconnect: Bool = false
    var didInitiateConnect: Bool = false
    var didInitiateStopScanWithTimeout: Bool = false
    var didInitiateReadRSSI: Bool = false
    var didInitiateDiscoverServices: Bool = false
    var didInitiateDiscoverIncludedServices: Bool = false
    var didInitiateDiscoverCharacteristics: Bool = false
    var didInitiateReadCharacteristic: Bool = false
    var didInitiateWriteCharacteristic: Bool = false
    var didInitiateUpdateNotifyStatus: Bool = false
    var didInitiateDiscoverDescriptors: Bool = false
    var didInitiateReadDescriptor: Bool = false
    var didInitiateWriteDescriptor: Bool = false
    var connectResult: Result<Peripheral, Swift.Error>?
    var disconnectResult: Result<Peripheral, Swift.Error>?
    var readRSSIResult: Result<Int, Swift.Error>?
    var discoverServicesResult: Result<[Service], Swift.Error>?
    var discoverIncludedServicesResult: Result<[Service], Swift.Error>?
    var discoverCharacteristicsResult: Result<[Characteristic], Swift.Error>?
    var readCharacteristicResult: Result<Characteristic, Swift.Error>?
    var writeCharacteristicResult: Result<Characteristic, Swift.Error>?
    var updateNotifyStatusResult: Result<Characteristic, Swift.Error>?
    var discoverDescriptorsResult: Result<[Descriptor], Swift.Error>?
    var readDescriptorResult: Result<Descriptor, Swift.Error>?
    var writeDescriptorResult: Result<Descriptor, Swift.Error>?
    var conservedPeripherals: [Peripheral]
    public init(
        name: String,
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        self.semaphores = []
        self.processors = []
        self.conservedPeripherals = []
        self.name = name
        self.centralManagerDelegate = CentralManagerDelegate()
        self.peripheralDelegate = PeripheralDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
    }
    @discardableResult
    public func ready() -> BluetoothAssistant {
        centralManagerDelegate.assistant = self
        peripheralDelegate.assistant = self
        return self
    }
    @discardableResult
    public func conservePeripheral(_ peripheral: Peripheral) -> BluetoothAssistant {
        conservedPeripherals.removeAll(where: { $0.keyName == peripheral.keyName })
        conservedPeripherals.append(peripheral)
        return self
    }
    @discardableResult
    public func removeConservedPeripherals(_ filter: (String) -> Bool) -> BluetoothAssistant {
        conservedPeripherals.removeAll(where: { filter($0.keyName) })
        return self
    }
}
