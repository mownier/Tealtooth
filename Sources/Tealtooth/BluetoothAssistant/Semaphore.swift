import Foundation

extension BluetoothAssistant {
    func semaphore(_ name: String) -> Semaphore {
        if let result = semaphores.first(where: { $0.name == name }) {
            return result
        }
        let semaphore = Semaphore(
            name: name,
            mutex: DispatchSemaphore(value: 1)
        )
        semaphores.append(semaphore)
        return semaphore
    }
    func scanSemaphore() -> Semaphore {
        return semaphore(scanSemaphoreName)
    }
    class Semaphore {
        let activatedOn: Date
        let name: String
        let mutex: DispatchSemaphore
        init(
            name: String,
            mutex: DispatchSemaphore
        ) {
            self.activatedOn = Date()
            self.name = name
            self.mutex = mutex
        }
    }
    var scanSemaphoreName: String { "BluetoothAssistant.scanSemaphore" }
}
