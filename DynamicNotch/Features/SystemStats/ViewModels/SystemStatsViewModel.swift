//
//  SystemStatsViewModel.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/29/26.
//

import Foundation
import Combine

@MainActor
final class SystemStatsViewModel: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsagePercent: Double = 0.0
    @Published var memoryUsedGB: Double = 0.0
    @Published var memoryTotalGB: Double = 0.0
    
    @Published var cpuHistory: [Double] = Array(repeating: 0.0, count: 15)
    @Published var memoryHistory: [Double] = Array(repeating: 0.0, count: 15)
    
    private var timer: Timer?
    private var previousCpuInfo: host_cpu_load_info?
    
    func startMonitoring() {
        stopMonitoring()
        previousCpuInfo = getCPULoadInfo()
        updateStats()
        
        cpuHistory = Array(repeating: cpuUsage, count: 15)
        memoryHistory = Array(repeating: memoryUsagePercent, count: 15)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateStats()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        updateCPU()
        updateMemory()
    }
    
    private func updateCPU() {
        guard let currentCpuInfo = getCPULoadInfo() else { return }
        
        if let previous = previousCpuInfo {
            // Using safe wrapping subtraction (&-) to avoid overflow crashes on long uptimes
            let userDiff = Double(currentCpuInfo.cpu_ticks.0 &- previous.cpu_ticks.0)
            let systemDiff = Double(currentCpuInfo.cpu_ticks.1 &- previous.cpu_ticks.1)
            let idleDiff = Double(currentCpuInfo.cpu_ticks.2 &- previous.cpu_ticks.2)
            let niceDiff = Double(currentCpuInfo.cpu_ticks.3 &- previous.cpu_ticks.3)
            
            let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
            if totalDiff > 0 {
                let activeDiff = userDiff + systemDiff + niceDiff
                self.cpuUsage = (activeDiff / totalDiff) * 100.0
                
                self.cpuHistory.append(self.cpuUsage)
                if self.cpuHistory.count > 15 {
                    self.cpuHistory.removeFirst()
                }
            }
        }
        
        previousCpuInfo = currentCpuInfo
    }
    
    private func updateMemory() {
        var pageSize: vm_size_t = 0
        let hostPort = mach_host_self()
        host_page_size(hostPort, &pageSize)
        
        var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        var vmStat = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &hostSize)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let physicalMemory = Double(ProcessInfo.processInfo.physicalMemory) // bytes
        
        let activePages = Double(vmStat.active_count)
        let wirePages = Double(vmStat.wire_count)
        let compressedPages = Double(vmStat.compressor_page_count)
        
        let usedBytes = (activePages + wirePages + compressedPages) * Double(pageSize)
        
        self.memoryUsedGB = usedBytes / (1024.0 * 1024.0 * 1024.0)
        self.memoryTotalGB = physicalMemory / (1024.0 * 1024.0 * 1024.0)
        self.memoryUsagePercent = (usedBytes / physicalMemory) * 100.0
        
        self.memoryHistory.append(self.memoryUsagePercent)
        if self.memoryHistory.count > 15 {
            self.memoryHistory.removeFirst()
        }
    }
    
    private func getCPULoadInfo() -> host_cpu_load_info? {
        let count = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(count)
        var cpuLoadInfo = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: count) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        return result == KERN_SUCCESS ? cpuLoadInfo : nil
    }
}
