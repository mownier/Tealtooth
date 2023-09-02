import Foundation

extension BluetoothAssistant {
    @discardableResult
    public func addScanProcess(_ operation: Operation) -> BluetoothAssistant {
        return addProcess(
            keyName: scanSemaphoreName,
            operation: operation
        )
    }
    @discardableResult
    public func addScanProcess(_ block: @escaping () -> Void) -> BluetoothAssistant {
        return addProcess(
            keyName: scanSemaphoreName,
            block: block
        )
    }
    @discardableResult
    public func addPeripheralProcess(
        identifier: String,
        operation: Operation
    ) -> BluetoothAssistant {
        return addProcess(
            keyName: identifier,
            operation: operation
        )
    }
    @discardableResult
    public func addPeripheralProcess(
        identifier: String,
        block: @escaping () -> Void
    ) -> BluetoothAssistant {
        return addProcess(
            keyName: identifier,
            block: block
        )
    }
    @discardableResult
    private func addProcess(
        keyName: String,
        operation: Operation
    ) -> BluetoothAssistant {
        processor(keyName).queue.addOperation(operation)
        return self
    }
    @discardableResult
    private func addProcess(
        keyName: String,
        block: @escaping () -> Void
    ) -> BluetoothAssistant {
        processor(keyName).queue.addOperation(block)
        return self
    }
    private func processor(_ name: String) -> Processor {
        if let result = processors.first(where: { $0.name == name }) {
            return result
        }
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let processor = Processor(
            name: name,
            queue: queue
        )
        processors.append(processor)
        return processor
    }
    class Processor {
        let name: String
        let queue: OperationQueue
        init(name: String, queue: OperationQueue) {
            self.name = name
            self.queue = queue
        }
    }
}
