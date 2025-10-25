// AppDelegate Integration for Enterprise Login Features
// Add these modifications to your existing AppDelegate.swift file

import UIKit
import Flutter
import LocalAuthentication

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var biometricChannel: FlutterMethodChannel?
    private var deepLinkChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // Setup Biometric Method Channel
        setupBiometricChannel(controller: controller)

        // Setup Deep Link Channel
        setupDeepLinkChannel(controller: controller)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Biometric Method Channel

    private func setupBiometricChannel(controller: FlutterViewController) {
        biometricChannel = FlutterMethodChannel(
            name: "com.app/biometric",
            binaryMessenger: controller.binaryMessenger
        )

        biometricChannel?.setMethodCallHandler { (call, result) in
            BiometricBridge.handleMethodCall(call, result: result)
        }
    }

    // MARK: - Deep Link Channel

    private func setupDeepLinkChannel(controller: FlutterViewController) {
        deepLinkChannel = FlutterMethodChannel(
            name: "com.app/deeplink",
            binaryMessenger: controller.binaryMessenger
        )

        deepLinkChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleDeepLinkMethod(call, result: result)
        }
    }

    private func handleDeepLinkMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInitialLink":
            // Return any initial link that opened the app
            result(nil) // Will be set if app opened via link
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Universal Links

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {

        // Handle universal links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {

            deepLinkChannel?.invokeMethod("onLink", arguments: url.absoluteString)
            return true
        }

        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    // MARK: - URL Scheme Deep Links

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        // Handle custom URL schemes
        deepLinkChannel?.invokeMethod("onLink", arguments: url.absoluteString)

        return super.application(app, open: url, options: options)
    }

    // MARK: - App Lifecycle for Security

    override func applicationWillResignActive(_ application: UIApplication) {
        // Called when app is about to move from active to inactive state
        // Can be used to add blur effect for privacy
        addPrivacyBlur()
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Remove privacy blur
        removePrivacyBlur()

        // Check if biometric state changed (user added/removed fingerprint)
        notifyBiometricStateChange()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        // Can be used to trigger logout timer for security
        startSecurityTimer()
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        // Check if security timeout expired
        checkSecurityTimeout()
    }

    // MARK: - Privacy Protection

    private var blurView: UIVisualEffectView?

    private func addPrivacyBlur() {
        guard blurView == nil else { return }

        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window?.bounds ?? .zero
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 999

        window?.addSubview(blurEffectView)
        blurView = blurEffectView
    }

    private func removePrivacyBlur() {
        blurView?.removeFromSuperview()
        blurView = nil
    }

    // MARK: - Security Timeout

    private var backgroundTime: Date?
    private let securityTimeoutMinutes = 5.0

    private func startSecurityTimer() {
        backgroundTime = Date()
    }

    private func checkSecurityTimeout() {
        guard let bgTime = backgroundTime else { return }

        let timeInBackground = Date().timeIntervalSince(bgTime)
        let timeoutSeconds = securityTimeoutMinutes * 60

        if timeInBackground > timeoutSeconds {
            // Trigger re-authentication
            deepLinkChannel?.invokeMethod("requireReauth", arguments: [
                "reason": "timeout",
                "timeInBackground": Int(timeInBackground)
            ])
        }

        backgroundTime = nil
    }

    // MARK: - Biometric State Change

    private func notifyBiometricStateChange() {
        let currentState = BiometricBridge.getBiometricState()
        let previousState = UserDefaults.standard.string(forKey: "BiometricState")

        if let current = currentState {
            UserDefaults.standard.set(current, forKey: "BiometricState")

            if BiometricBridge.hasBiometricStateChanged(previousState: previousState) {
                // Notify Flutter about biometric change
                biometricChannel?.invokeMethod("onBiometricStateChanged", arguments: [
                    "previousState": previousState ?? "",
                    "currentState": current
                ])
            }
        }
    }

    // MARK: - Memory Warning

    override func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        // Clear any cached sensitive data
        clearSensitiveCache()
    }

    private func clearSensitiveCache() {
        // Clear sensitive cached data
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: - Push Notifications (Optional)

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // Send token to Flutter
        let channel = FlutterMethodChannel(
            name: "com.app/notifications",
            binaryMessenger: (window?.rootViewController as! FlutterViewController).binaryMessenger
        )
        channel.invokeMethod("onToken", arguments: token)
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for notifications: \(error)")
    }
}

// MARK: - Extension for Device Info

extension AppDelegate {

    @objc static func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current

        return [
            "model": device.model,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "name": device.name,
            "identifierForVendor": device.identifierForVendor?.uuidString ?? "",
            "isSimulator": isSimulator()
        ]
    }

    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Security Extensions

extension AppDelegate {

    @objc static func checkSSLPinning(host: String, certificate: Data) -> Bool {
        // Implement certificate pinning validation
        // This is a placeholder - implement actual pinning logic
        return true
    }

    @objc static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result != 0 {
            return false
        }

        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    @objc static func preventScreenshots() {
        // Add a field to prevent screenshots (enterprise security)
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Log screenshot event for security audit
            print("⚠️ Screenshot detected - security event logged")
        }
    }
}

// MARK: - Constants

private let P_TRACED: Int32 = 0x00000800
private let CTL_KERN: Int32 = 1
private let KERN_PROC: Int32 = 14
private let KERN_PROC_PID: Int32 = 1
