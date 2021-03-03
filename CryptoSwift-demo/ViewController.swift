//
//  ViewController.swift
//  CryptoSwift-demo
//
//  Created by Shawn Roller on 3/2/21.
//

import UIKit
import CryptoSwift

//struct KeyMaterial {
//    hmacKey
//}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        self.getKeyMaterial(fromPassphrase: "testing123")
        let key = self.getKeyBytes(forPassphrase: "testing123")
        print(key)
    }

    func getKeyMaterial(fromPassphrase passphrase: String) {
        do {
            let keyLength = 80
            let salt: [UInt8] = Array("AdyenNexoV1Salt".utf8)
            let rounds = 4000
            let phraseArray: [UInt8] = Array(passphrase.utf8)

//            let key = try PKCS5.PBKDF2(password: phraseArray, salt: salt, iterations: rounds, keyLength: keyLength, variant: .sha1).calculate()
//            print(key)
            let key: [UInt8] = [7, 138, 67, 38, 42, 42, 72, 205, 83, 133, 251, 245, 79, 63, 82, 106, 141, 121, 32, 161, 44, 80, 249, 206, 240, 203, 127, 64, 130, 162, 7, 33]

            let iv = AES.randomIV(16)

            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)

            let testMessage = "I have poop in my shoot"
            let inputData = Data(testMessage.utf8)
            let encryptedBytes = try aes.encrypt(inputData.bytes)
            let encryptedData = Data(encryptedBytes)

            print(encryptedData)

            let decryptedBytes = try aes.decrypt(encryptedData.bytes)
            let decryptedData = Data(decryptedBytes)
            let decryptedString = String(data: decryptedData, encoding: .utf8)

            print(decryptedData)
            print(decryptedString)
            
            let signature = try HMAC(key: key, variant: .sha256).authenticate(encryptedBytes)
            let signatureData = Data(signature)
            let signatureString = signatureData.base64EncodedString()
            
            print(signature)
            print(signatureData)
            print(signatureString)
            
//            let password: [UInt8] = Array("s33krit".utf8)
//            let salt: [UInt8] = Array("nacllcan".utf8)
//
//            /* Generate a key from a `password`. Optional if you already have a key */
//            let key = try PKCS5.PBKDF2(
//                password: password,
//                salt: salt,
//                iterations: 4096,
//                keyLength: 32, /* AES-256 */
//                variant: .sha256
//            ).calculate()
//
//            /* Generate random IV value. IV is public value. Either need to generate, or get it from elsewhere */
//            let iv = AES.randomIV(AES.blockSize)
//
//            print(key)
//
//            /* AES cryptor instance */
//            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
//
//            /* Encrypt Data */
//            let inputData = Data()
//            let encryptedBytes = try aes.encrypt(inputData.bytes)
//            let encryptedData = Data(encryptedBytes)
//
//            print(encryptedData)
//
//            /* Decrypt Data */
//            let decryptedBytes = try aes.decrypt(encryptedData.bytes)
//            let decryptedData = Data(decryptedBytes)
//
//            print(decryptedData)
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
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

}

