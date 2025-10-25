// BiometricBridge.swift
// iOS Native Biometric Authentication Bridge for Flutter
// Place this file in: ios/Runner/BiometricBridge.swift

import Foundation
import LocalAuthentication
import Security

@objc class BiometricBridge: NSObject {

    // MARK: - Biometric Capability Check

    @objc static func checkBiometrics() -> [String: Any] {
        let context = LAContext()
        var error: NSError?

        let canUseBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        let canUsePasscode = context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: nil
        )

        var biometryType: String = "none"
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                biometryType = "faceID"
            case .touchID:
                biometryType = "touchID"
            case .none:
                biometryType = "none"
            @unknown default:
                biometryType = "unknown"
            }
        }

        // Check for Optic ID (Vision Pro)
        #if targetEnvironment(simulator)
        let hasOpticID = false
        #else
        let hasOpticID = biometryType == "opticID" // Will be available in future iOS
        #endif

        return [
            "faceID": biometryType == "faceID",
            "touchID": biometryType == "touchID",
            "opticID": hasOpticID,
            "enrolled": canUseBiometrics,
            "passcodeSet": canUsePasscode,
            "biometryType": biometryType,
            "error": error?.localizedDescription ?? ""
        ]
    }

    // MARK: - Advanced Authentication with Policy

    @objc static func authenticateWithPolicy(
        reason: String,
        policy: [String: Any],
        fallbackTitle: String?,
        cancelTitle: String?
    ) async throws -> [String: Any] {

        let context = LAContext()

        // Configure context from policy
        if let allowPasscode = policy["allowPasscode"] as? Bool {
            context.localizedFallbackTitle = allowPasscode ? (fallbackTitle ?? "Use Passcode") : ""
        }

        if let cancelBtn = cancelTitle {
            context.localizedCancelTitle = cancelBtn
        }

        // Set reauth interval
        if let reauthInterval = policy["reauthInterval"] as? Int {
            if #available(iOS 9.0, *) {
                context.touchIDAuthenticationAllowableReuseDuration = TimeInterval(reauthInterval)
            }
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            return [
                "success": success,
                "evaluatedPolicyDomainState": context.evaluatedPolicyDomainState?.base64EncodedString() ?? ""
            ]

        } catch let error as LAError {
            return [
                "success": false,
                "error": error.localizedDescription,
                "errorCode": error.code.rawValue
            ]
        }
    }

    // MARK: - Keychain Integration

    @objc static func setupKeychain(
        accessGroup: String?,
        synchronizable: Bool,
        accessibility: String
    ) -> [String: Any] {

        var keychainAccessibility: CFString

        switch accessibility {
        case "kSecAttrAccessibleWhenUnlockedThisDeviceOnly":
            keychainAccessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly":
            keychainAccessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case "kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly":
            if #available(iOS 8.0, *) {
                keychainAccessibility = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            } else {
                keychainAccessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        default:
            keychainAccessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        // Store configuration in UserDefaults for reference
        let config = [
            "accessGroup": accessGroup ?? "",
            "synchronizable": synchronizable,
            "accessibility": accessibility
        ] as [String : Any]

        UserDefaults.standard.set(config, forKey: "KeychainConfig")

        return [
            "success": true,
            "accessibility": String(describing: keychainAccessibility)
        ]
    }

    // MARK: - Secure Storage with Biometric Protection

    @objc static func saveSecureData(
        key: String,
        data: String,
        requireBiometric: Bool
    ) -> [String: Any] {

        guard let dataValue = data.data(using: .utf8) else {
            return ["success": false, "error": "Invalid data format"]
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataValue,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Add biometric protection
        if requireBiometric {
            if #available(iOS 8.0, *) {
                var accessControl: SecAccessControl?
                var error: Unmanaged<CFError>?

                accessControl = SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    .biometryCurrentSet,
                    &error
                )

                if let accessControl = accessControl {
                    query[kSecAttrAccessControl as String] = accessControl
                    // Remove kSecAttrAccessible when using access control
                    query.removeValue(forKey: kSecAttrAccessible as String)
                }
            }
        }

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        return [
            "success": status == errSecSuccess,
            "status": status
        ]
    }

    @objc static func loadSecureData(
        key: String,
        reason: String?
    ) async -> [String: Any] {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: reason ?? "Authenticate to access data"
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            if let value = String(data: data, encoding: .utf8) {
                return [
                    "success": true,
                    "data": value
                ]
            }
        }

        return [
            "success": false,
            "status": status,
            "error": SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
        ]
    }

    // MARK: - Device Security Check

    @objc static func checkDeviceSecurity() -> [String: Any] {
        let context = LAContext()
        var error: NSError?

        let hasBiometric = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        let hasPasscode = context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: nil
        )

        // Check if device is jailbroken
        let isJailbroken = checkJailbreak()

        return [
            "hasBiometric": hasBiometric,
            "hasPasscode": hasPasscode,
            "isJailbroken": isJailbroken,
            "deviceSecureEnough": hasBiometric && hasPasscode && !isJailbroken
        ]
    }

    private static func checkJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else

        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if app can write outside sandbox
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Cannot write outside sandbox - good
        }

        return false
        #endif
    }

    // MARK: - Biometric State Change Detection

    @objc static func getBiometricState() -> String? {
        let context = LAContext()
        var error: NSError?

        _ = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        if let domainState = context.evaluatedPolicyDomainState {
            return domainState.base64EncodedString()
        }

        return nil
    }

    @objc static func hasBiometricStateChanged(previousState: String?) -> Bool {
        guard let previous = previousState else { return false }

        let current = getBiometricState()
        return previous != current
    }
}

// MARK: - Flutter Method Channel Handler

extension BiometricBridge {

    @objc static func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
        case "checkBiometrics":
            result(checkBiometrics())

        case "authenticateWithPolicy":
            guard let args = call.arguments as? [String: Any],
                  let reason = args["reason"] as? String,
                  let policy = args["policy"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            let fallbackTitle = args["fallbackTitle"] as? String
            let cancelTitle = args["cancelTitle"] as? String

            Task {
                do {
                    let authResult = try await authenticateWithPolicy(
                        reason: reason,
                        policy: policy,
                        fallbackTitle: fallbackTitle,
                        cancelTitle: cancelTitle
                    )
                    result(authResult)
                } catch {
                    result(FlutterError(code: "AUTH_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "setupKeychain":
            guard let args = call.arguments as? [String: Any],
                  let synchronizable = args["synchronizable"] as? Bool,
                  let accessibility = args["accessibility"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            let accessGroup = args["accessGroup"] as? String
            let keychainResult = setupKeychain(
                accessGroup: accessGroup,
                synchronizable: synchronizable,
                accessibility: accessibility
            )
            result(keychainResult)

        case "saveSecureData":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String,
                  let data = args["data"] as? String,
                  let requireBiometric = args["requireBiometric"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            result(saveSecureData(key: key, data: data, requireBiometric: requireBiometric))

        case "loadSecureData":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            let reason = args["reason"] as? String

            Task {
                let loadResult = await loadSecureData(key: key, reason: reason)
                result(loadResult)
            }

        case "checkDeviceSecurity":
            result(checkDeviceSecurity())

        case "getBiometricState":
            result(getBiometricState())

        case "hasBiometricStateChanged":
            guard let args = call.arguments as? [String: Any],
                  let previousState = args["previousState"] as? String? else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            result(hasBiometricStateChanged(previousState: previousState))

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
