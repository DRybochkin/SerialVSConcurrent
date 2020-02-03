//
//  ViewController.swift
//  SerialVSConcurrent
//
//  Created by Dmitriy Rybochkin on 03.02.2020.
//  Copyright © 2020 Dmitriy Rybochkin. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let serialQueueCount = 100
        static let operationCount = 50
    }

    // MARK: - Outlets

    @IBOutlet var serialLabel: UILabel!
    @IBOutlet var concurrentLabel: UILabel!
    @IBOutlet var testLabel: UILabel!

    // MARK: - Private properties

    private let serial = DispatchQueue(label: "concurent", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

    // MARK: - Actions

    @IBAction func serialTap() {
        self.serialLabel.text = ""
        DispatchQueue.main.async {
            self.startSerial()
        }
    }

    @IBAction func concurrentTap() {
        self.concurrentLabel.text = ""
        DispatchQueue.main.async {
            self.startConcurent()
        }
    }

    // MARK: - Private functions

    private func startConcurent() {
        let startDate = Date()
        var maxInterval: TimeInterval = 0
        let startMemory = getMemory()
        var count = 0
        for index in 0..<Constants.serialQueueCount {
            serial.async(flags: .barrier) { [weak self] in
                guard let self = self else {
                    return
                }
                self.test(prefix: index)
                let interval = startDate.distance(to: Date())
                if interval > maxInterval {
                    maxInterval = interval
                    count += 1
                    let memoryUsage = self.getMemory() - startMemory
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.concurrentLabel.text = "\(interval) - \(count) - \(memoryUsage)"
                    }
                }
            }
        }
    }

    private func startSerial() {
        let startDate = Date()
        var maxInterval: TimeInterval = 0
        let startMemory = getMemory()
        var count = 0
        for index in 0..<Constants.serialQueueCount {
            let serial = DispatchQueue(label: "serial-\(UUID().uuidString)", qos: .default)
            serial.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.test(prefix: index)
                let interval = startDate.distance(to: Date())
                if interval > maxInterval {
                    maxInterval = interval
                    count += 1
                    let memoryUsage = self.getMemory() - startMemory
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.serialLabel.text = "\(interval) - \(count) - \(memoryUsage)"
                    }
                }
            }
        }
    }

    @discardableResult
    private func test(prefix: Int) -> Int {
        var result = 0
        for index in 0..<Constants.operationCount {
            result += index
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.testLabel.text = "\(prefix)-\(index)"
            }
        }
        return result
    }

    // TODO: - Функция не потокобезопасная => иногда в ней воможны падения
    // Если они учащаются то можно закоментировать и вернуть 0
    private func getMemory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? taskInfo.resident_size/(1024*1024) : 0
    }
}

