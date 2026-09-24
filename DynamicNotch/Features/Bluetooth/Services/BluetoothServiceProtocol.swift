//
//  BluetoothServiceProtocol.swift
//  DynamicNotch
//

import Foundation
import Combine

protocol BluetoothServiceProtocol: AnyObject, Sendable {
    var lastConnectedDevice: BluetoothAudioDevice? { get }
    var connectedDevices: [BluetoothAudioDevice] { get }
    var lastConnectedDevicePublisher: AnyPublisher<BluetoothAudioDevice?, Never> { get }
    var connectedDevicesPublisher: AnyPublisher<[BluetoothAudioDevice], Never> { get }
    var deviceConnectedEventPublisher: AnyPublisher<BluetoothAudioDevice, Never> { get }
    func refreshConnectedDeviceBatteries()
}

extension BluetoothServiceProtocol {
    var deviceConnectedEventPublisher: AnyPublisher<BluetoothAudioDevice, Never> {
        Empty().eraseToAnyPublisher()
    }
}

