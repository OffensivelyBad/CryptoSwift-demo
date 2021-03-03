//
//  Crypto.swift
//  UniversalSledDemo
//
//  Created by Shawn Roller on 3/3/21.
//

import Foundation
import CryptoSwift

struct CryptoKey {
    let key: [UInt8]
    var hmac_key: [UInt8] {
        return Array(key.prefix(32))
    }
    var cipher_key: [UInt8] {
        return Array(key[32..<64])
    }
    var iv: [UInt8] {
        return Array(key.suffix(from: 64))
    }
}

struct Crypto {
    
    // Determine if we should use encryption - testing does not require encryption and may make troubleshooting easier
    static let USE_ENCRYPTION = true
    
    static let NEXO_HMAC_KEY_LENGTH = 32
    static let NEXO_CIPHER_KEY_LENGTH = 32
    static let NEXO_IV_LENGTH = 16
    
    
    // MARK: - if we need to generate new key data bytes, getKeyBytes will do the trick - just pass in the new passphrase and make sure to update the keyIdentifier and keyVersion
    static let keyIdentifier = "ios"
    static let keyVersion = 1
    static let derivedKeys = CryptoKey(key: [7, 138, 67, 38, 42, 42, 72, 205, 83, 133, 251, 245, 79, 63, 82, 106, 141, 121, 32, 161, 44, 80, 249, 206, 240, 203, 127, 64, 130, 162, 7, 33,
                                      184, 62, 9, 97, 167, 42, 58, 146, 139, 148, 85, 202, 226, 16, 131, 31, 244, 133, 233, 230, 174, 71, 75, 53, 67, 203, 214, 51, 132, 223, 251, 72,
                                      230, 94, 158, 178, 34, 15, 228, 110, 99, 230, 255, 150, 196, 39, 188, 224])
    private func getKeyBytes(forPassphrase passphrase: String) -> [UInt8] {
        do {
            let keyLength = 80
            let salt: [UInt8] = Array("AdyenNexoV1Salt".utf8)
            let rounds = 4000
            let phraseArray: [UInt8] = Array(passphrase.utf8)

            let key = try PKCS5.PBKDF2(password: phraseArray, salt: salt, iterations: rounds, keyLength: keyLength, variant: .sha1).calculate()
            return key
        } catch {
            fatalError("Could not generate crypto key material")
        }
    }
    
    static func crypt(bytes: [UInt8], keys: CryptoKey, ivMod: [UInt8], encrypt: Bool) -> [UInt8] {
        do {
            var actualIV = keys.iv
            for (index, _) in keys.iv.enumerated() {
                actualIV[index] = keys.iv[index] ^ ivMod[index]
            }
            
            let aes = try AES(key: keys.cipher_key, blockMode: CBC(iv: actualIV))
            if encrypt {
                let encryptedBytes = try aes.encrypt(bytes)
                return encryptedBytes
            } else {
                let decryptedBytes = try aes.decrypt(bytes)
                return decryptedBytes
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func hmac(bytes: [UInt8], keys: CryptoKey) -> [UInt8] {
        do {
            let mac = HMAC(key: keys.hmac_key, variant: .sha256)
            let hmac = try mac.authenticate(bytes)
            return hmac
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func encryptAndHmac(bytes: [UInt8]) -> SaleRequest {
        do {
            let data = Data(bytes)
            let requestObject = try JSONDecoder().decode(SaleRequest.self, from: data)
            
            if !Crypto.USE_ENCRYPTION {
                return requestObject
            }
            
            let originalSaleToPOIRequest = requestObject.SaleToPOIRequest
            let messageHeader = originalSaleToPOIRequest.MessageHeader
            
            let ivMod = AES.randomIV(16)
            let nexoBlob = Data(Crypto.crypt(bytes: bytes, keys: Crypto.derivedKeys, ivMod: ivMod, encrypt: true)).base64EncodedString()
            let hmac = Data(Crypto.hmac(bytes: bytes, keys: Crypto.derivedKeys)).base64EncodedString()
            let nonce = Data(ivMod).base64EncodedString()
            
            let securityTrailer = SecurityTrailer(KeyVersion: Crypto.keyVersion, KeyIdentifier: Crypto.keyIdentifier, Hmac: hmac, Nonce: nonce, AdyenCryptoVersion: 1)
            let saleToPOIRequest = SaleToPOIRequest(MessageHeader: messageHeader, NexoBlob: nexoBlob, SecurityTrailer: securityTrailer)
            let saleRequest = SaleRequest(SaleToPOIRequest: saleToPOIRequest)
            
            return saleRequest
        } catch {
            fatalError("Can't encrypt data")
        }
    }
    
    static func decryptAndValidateHmac(bytes: [UInt8]) throws -> SaleResponse {
        let data = Data(bytes)
        let responseObject = try JSONDecoder().decode(SaleResponse.self, from: data)
        
        if !Crypto.USE_ENCRYPTION {
            return responseObject
        }
        
        let originalSaleToPOIResponse = responseObject.SaleToPOIResponse
        guard let payload = originalSaleToPOIResponse.NexoBlob, let cipherText = Data(base64Encoded: payload) else {
            fatalError("No payload to decrypt")
        }
        
        let trailer = originalSaleToPOIResponse.SecurityTrailer
        guard let hmacB64 = trailer?.Hmac, let nonceB64 = trailer?.Nonce, let ivMod = Data(base64Encoded: nonceB64) else {
            fatalError("No Hmac to validate")
        }
        
        let decryptedBytes = Crypto.crypt(bytes: cipherText.bytes, keys: Crypto.derivedKeys, ivMod: ivMod.bytes, encrypt: false)
        let decryptedData = Data(decryptedBytes)
        let saleResponse = try JSONDecoder().decode(SaleResponse.self, from: decryptedData)
        
        guard let receivedMac = Data(base64Encoded: hmacB64) else {
            fatalError("No received mac")
        }
        let hmac = Crypto.hmac(bytes: decryptedBytes, keys: self.derivedKeys)
        
        guard receivedMac.count == hmac.count else {
            fatalError("HMAC validation failed - length mismatch")
        }
        
        var equal = true
        for (index, _) in hmac.enumerated() {
            if receivedMac[index] != hmac[index] {
                equal = false
                break;
            }
        }
        
        if !equal {
            fatalError("HMAC validation failed!")
        }
        
        return saleResponse
    }
    
}
