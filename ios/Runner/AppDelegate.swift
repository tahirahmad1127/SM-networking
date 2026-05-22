import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.smnetworking.app/install_session",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "getInstallId" {
          guard let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
          ).first,
          let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
          let created = attrs[.creationDate] as? Date else {
            result("")
            return
          }
          result(String(Int(created.timeIntervalSince1970 * 1000)))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
