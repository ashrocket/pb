import CryptoKit
import Foundation
import Security

enum EncryptionError: Error {
    case invalidCiphertext
    case randomFailure(OSStatus)
    case unsupportedKeychainStatus(OSStatus)
}

protocol KeychainValueStore {
    func readData(account: String) throws -> Data?
    func writeData(_ data: Data, account: String) throws
}

final class SecurityKeychainStore: KeychainValueStore {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func readData(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw EncryptionError.unsupportedKeychainStatus(status)
        }
    }

    func writeData(_ data: Data, account: String) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw EncryptionError.unsupportedKeychainStatus(addStatus)
            }
        default:
            throw EncryptionError.unsupportedKeychainStatus(status)
        }
    }
}

final class InMemoryKeychainStore: KeychainValueStore {
    private var items: [String: Data] = [:]

    func readData(account: String) throws -> Data? {
        items[account]
    }

    func writeData(_ data: Data, account: String) throws {
        items[account] = data
    }
}

struct KeyMaterial {
    let payloadKey: SymmetricKey
    let searchKey: SymmetricKey
}

final class EncryptionManager {
    private let keychain: KeychainValueStore
    private let payloadInfo = Data("clip-05 payload encryption".utf8)
    private let searchInfo = Data("clip-05 search index".utf8)
    private let passphraseAccount = "payload-passphrase"
    private let saltAccount = "payload-salt"

    init(keychain: KeychainValueStore = SecurityKeychainStore(service: "local.clip05.history")) {
        self.keychain = keychain
    }

    func encrypt(_ plaintext: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(plaintext, using: try keyMaterial().payloadKey)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.invalidCiphertext
        }
        return Data([1]) + combined
    }

    func decrypt(_ ciphertext: Data) throws -> Data {
        guard let version = ciphertext.first, version == 1 else {
            throw EncryptionError.invalidCiphertext
        }

        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext.dropFirst())
        return try AES.GCM.open(sealedBox, using: try keyMaterial().payloadKey)
    }

    func searchDigest(for text: String) throws -> Data {
        let normalized = SearchIndex.normalizedSearchTerm(text)
        let digest = HMAC<SHA256>.authenticationCode(
            for: Data(normalized.utf8),
            using: try keyMaterial().searchKey
        )
        return Data(digest)
    }

    private func keyMaterial() throws -> KeyMaterial {
        let passphrase = try loadOrCreate(account: passphraseAccount, byteCount: 32)
        let salt = try loadOrCreate(account: saltAccount, byteCount: 16)

        return KeyMaterial(
            payloadKey: HKDF<SHA256>.deriveKey(
                inputKeyMaterial: SymmetricKey(data: passphrase),
                salt: salt,
                info: payloadInfo,
                outputByteCount: 32
            ),
            searchKey: HKDF<SHA256>.deriveKey(
                inputKeyMaterial: SymmetricKey(data: passphrase),
                salt: salt,
                info: searchInfo,
                outputByteCount: 32
            )
        )
    }

    private func loadOrCreate(account: String, byteCount: Int) throws -> Data {
        if let existing = try keychain.readData(account: account), !existing.isEmpty {
            return existing
        }

        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw EncryptionError.randomFailure(status)
        }

        let created = Data(bytes)
        try keychain.writeData(created, account: account)
        return created
    }
}
