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
    public func removeProcessors(_ filter: (String) -> Bool) -> BluetoothAssistant {
        processors.filter({ filter($0.name) }).forEach({ processor in
            processor.workQueue.cancelAllOperations()
            processor.resultQueue.cancelAllOperations()
        })
        processors.removeAll(where: { filter($0.name) })
        return self
    }
    func processor(_ name: String) -> Processor {
        if let result = processors.first(where: { $0.name == name }) {
            return result
        }
        let workQueue = OperationQueue()
        let resultQueue = OperationQueue()
        workQueue.maxConcurrentOperationCount = 1
        resultQueue.maxConcurrentOperationCount = 1
        let processor = Processor(
            name: name,
            workQueue: workQueue,
            resultQueue: resultQueue
        )
        processors.append(processor)
        return processor
    }
    @discardableResult
    private func addProcess(
        keyName: String,
        operation: Operation
    ) -> BluetoothAssistant {
        processor(keyName).workQueue.addOperation(operation)
        return self
    }
    @discardableResult
    private func addProcess(
        keyName: String,
        block: @escaping () -> Void
    ) -> BluetoothAssistant {
        processor(keyName).workQueue.addOperation(block)
        return self
    }
    class Processor {
        let name: String
        let workQueue: OperationQueue
        let resultQueue: OperationQueue
        init(
            name: String,
            workQueue: OperationQueue,
            resultQueue: OperationQueue
        ) {
            self.name = name
            self.workQueue = workQueue
            self.resultQueue = resultQueue
        }
    }
}
