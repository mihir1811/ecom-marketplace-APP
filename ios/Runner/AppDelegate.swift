import Flutter
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DevicePerf") {
      DevicePerf.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiveDevice") {
      LiveDevice.register(messenger: registrar.messenger())
    }
  }
}

/// The battery for a live show's visit record (battery_plus clashes with
/// wakelock_plus). iOS gives no SIM operator since iOS 16.
enum LiveDevice {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "gemworld/live_device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "battery" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        var out: [String: Any] = [
          "charging": device.batteryState == .charging,
        ]
        // -1 when unknown (simulator).
        if device.batteryLevel >= 0 {
          out["level"] = Int((device.batteryLevel * 100).rounded())
        }
        result(out)
      }
    }
  }
}

/// What the 3D simulators adapt their rendering to: the memory this app
/// may still use, the device's total, and how hot it runs. Nothing here is
/// a fixed device class; the OS reports its own limits.
enum DevicePerf {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "gemworld/device_perf", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "snapshot" else {
        result(FlutterMethodNotImplemented)
        return
      }
      var out: [String: Any] = [
        "totalBytes": Int64(ProcessInfo.processInfo.physicalMemory),
        // nominal 0, fair 1, serious 2, critical 3.
        "thermalState": ProcessInfo.processInfo.thermalState.rawValue,
        "powerSaving": ProcessInfo.processInfo.isLowPowerModeEnabled,
      ]
      if #available(iOS 13.0, *) {
        out["appMemoryBytes"] = Int64(os_proc_available_memory())
      }
      result(out)
    }
  }
}
