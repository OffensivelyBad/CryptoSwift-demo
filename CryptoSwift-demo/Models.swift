//
//  AdyenModels.swift
//  UniversalSledDemo
//
//  Created by Shawn Roller on 2/10/21.
//

import Foundation

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}

extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

// MARK: - Encryption
struct SecurityTrailer: Codable {
    let KeyVersion: Int
    let KeyIdentifier: String
    let Hmac: String
    let Nonce: String
    var AdyenCryptoVersion: Int = 1
}

// MARK: - Generic models
struct MessageHeader: Codable {
    let ProtocolVersion: String
    let MessageClass: String
    let MessageCategory: String
    let MessageType: String
    let SaleID: String
    let ServiceID: String
    let POIID: String
}

struct SaleToAcquirerData: Codable {
    let email: String?
    let customerID: Int?
    var contract: String = "ONECLICK,RECURRING"
    var stringData: String {
        return "shopperEmail=\(email ?? "")&shopperReference=\(customerID ?? 0)&recurringContract=\(contract)"
    }
}

// MARK: - Abort request
struct AbortRequest: Codable {
    var AbortReason: String? = "MerchantAbort"
    let MessageReference: MessageReference
}

struct MessageReference: Codable {
    var MessageCategory: String? = "Payment"
    let SaleID: String
    let ServiceID: String
}

// MARK: - Device request
struct DiagnosisRequest: Codable {
    var HostDiagnosisFlag: Bool = false
}

// MARK: - Payment request
struct SaleRequest: Codable {
    let SaleToPOIRequest: SaleToPOIRequest
}

struct SaleToPOIRequest: Codable {
    let MessageHeader: MessageHeader
    var PaymentRequest: PaymentRequest? = nil
    var DiagnosisRequest: DiagnosisRequest? = nil
    var AbortRequest: AbortRequest? = nil
    var NexoBlob: String? = nil
    var SecurityTrailer: SecurityTrailer? = nil
}

struct PaymentRequest: Codable {
    let SaleData: SaleData
    var PaymentTransaction: PaymentTransaction? = nil
}

struct SaleData: Codable {
    let SaleTransactionID: SaleTransactionID
    let SaleToAcquirerData: String? // to request a token - use SaleToAcquirerData.stringData
    let TokenRequestedType: String? // to request a token this would be "Customer"
}

struct SaleTransactionID: Codable {
    let TransactionID: String
    let TimeStamp: String
    
    init(TransactionID: String) {
        self.TransactionID = TransactionID
        
        let formatter = DateFormatter()
        let format = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.dateFormat = format
        let stringDate = formatter.string(from: Date())
        
        self.TimeStamp = stringDate
    }
}

struct PaymentTransaction: Codable {
    let AmountsReq: AmountsReq
    var TransactionConditions: TransactionConditions? = nil
}

struct TransactionConditions: Codable {
    let ForceEntryMode: [String]
}

struct AmountsReq: Codable {
    let Currency: String
    let RequestedAmount: Double
}

// MARK: - Payment response
struct SaleResponse: Codable {
    let SaleToPOIResponse: SaleToPOIResponse
}

struct SaleToPOIResponse: Codable {
    let MessageHeader: MessageHeader
    var PaymentResponse: PaymentResponse? = nil
    var PaymentReceipt: PaymentReceipt? = nil
    var DiagnosisResponse: DiagnosisResponse? = nil
    var NexoBlob: String? = nil
    var SecurityTrailer: SecurityTrailer? = nil
}

struct DiagnosisResponse: Codable {
    var POIStatus: POIStatus? = nil
    let Response: Response?
}

struct POIStatus: Codable {
    let CommunicationOKFlag: Bool
    let PrinterStatus: String?
    let GlobalStatus: String?
}

struct PaymentResponse: Codable {
    let POIData: POIData
    let Response: Response
    var AmountsResp: AmountsResp? = nil
    var PaymentResult: PaymentResult? = nil
    let SaleData: ResponseSaleData
}

struct ResponseSaleData: Codable {
    let SaleTransactionID: ResponseSaleTransactionID
}

struct ResponseSaleTransactionID: Codable {
    let TransactionID: String
    let TimeStamp: String
}

struct PaymentResult: Codable {
    let PaymentAcquirerData: PaymentAcquirerData
    var PaymentInstrumentData: PaymentInstrumentData? = nil
}

struct PaymentAcquirerData: Codable {
    let AcquirerPOIID: String
    let MerchantID: String
}

struct POIData: Codable {
    let POIReconciliationID: String?
    let POITransactionID: POITransactionID
}

struct POITransactionID: Codable {
    let TransactionID: String
    let TimeStamp: String
}

struct Response: Codable {
    let Result: String
    let AdditionalResponse: String?
    let ErrorCondition: String?
    var alias: String? {
        return getValue(withKey: "alias")
    }
    var detailReference: String? {
        return getValue(withKey: "recurring.recurringDetailReference")
    }
    var shopperReference: String? {
        return getValue(withKey: "recurring.shopperReference")
    }
    var shopperEmail: String? {
        return getValue(withKey: "shopperEmail")
    }
    var refusalReason: String? {
        return getValue(withKey: "refusalReason")
    }
    var batteryLevel: String? {
        return getValue(withKey: "batteryLevel")
    }
    var unconfirmedBatchCount: String? {
        return getValue(withKey: "unconfirmedBatchCount")
    }
    var firmwareVersion: String? {
        return getValue(withKey: "firmwareVersion")
    }
    var networkProfile: String? {
        return getValue(withKey: "networkProfile")
    }
    var merchantAccount: String? {
        return getValue(withKey: "merchantAccount")
    }
    var terminalId: String? {
        return getValue(withKey: "terminalId")
    }
    var storeId: String? {
        return getValue(withKey: "storeId")
    }
    
    // TODO: - may want to move this to a string function instead of in this struct
    func getValue(withKey key: String) -> String? {
        guard let response = AdditionalResponse, response.count > 0 else { return nil }
        let components = response.components(separatedBy: "&")
        for component in components {
            let kvp = component.components(separatedBy: "=")
            if kvp.count == 2 && kvp[0].uppercased() == key.uppercased() {
                return kvp[1]
            }
        }
        return nil
    }
}

struct PaymentInstrumentData: Codable {
    var CardData: CardData? = nil
    let PaymentInstrumentType: String?
}

struct CardData: Codable {
    let EntryMode: [String]?
    var PaymentToken: PaymentToken? = nil
    let PaymentBrand: String?
    let MaskedPan: String?
    let CardCountryCode: String?
    var SensitiveCardData: SensitiveCardData? = nil
}

struct PaymentToken: Codable {
    let TokenRequestedType: String
    let TokenValue: String
}

struct SensitiveCardData: Codable {
    let CardSeqNumb: String?
    let ExpiryDate: String?
}

struct AmountsResp: Codable {
    let AuthorizedAmount: Double
    let Currency: String
}

struct PaymentReceipt: Codable {
    
}



// MARK: - Examples
// serviceID could be the paymentTransactionID
let randomInt = Int.random(in: 11111..<999999999)
let exampleMessageHeader = MessageHeader(ProtocolVersion: "3.0", MessageClass: "Service", MessageCategory: "Payment", MessageType: "Request", SaleID: "iPod 12345", ServiceID: "\(randomInt)", POIID: "e285p-860078740")

// Payment Request
let exampleAmountsReq = AmountsReq(Currency: "EUR", RequestedAmount: 0.99)
let exampleTransactionConditions = TransactionConditions(ForceEntryMode: ["Keyed"]) // Forces keyed entry of the CC#
let examplePaymentTransaction = PaymentTransaction(AmountsReq: exampleAmountsReq, TransactionConditions: exampleTransactionConditions)
let exampleSaleTransactionID = SaleTransactionID(TransactionID: "27908")
let exampleSaleToAcquirerData = SaleToAcquirerData(email: "test123@test.uk", customerID: 8675309)
let exampleSaleData = SaleData(SaleTransactionID: exampleSaleTransactionID, SaleToAcquirerData: exampleSaleToAcquirerData.stringData, TokenRequestedType: "Customer")
let examplePaymentRequest = PaymentRequest(SaleData: exampleSaleData, PaymentTransaction: examplePaymentTransaction)
let exampleSaleToPOIRequest = SaleToPOIRequest(MessageHeader: exampleMessageHeader, PaymentRequest: examplePaymentRequest)
let exampleSaleRequest = SaleRequest(SaleToPOIRequest: exampleSaleToPOIRequest)

// Payment Response
let examplePaymentReceipt = PaymentReceipt()
let exampleAmountsResp = AmountsResp(AuthorizedAmount: 30.06, Currency: "EUR")
let exampleSensitiveCardData = SensitiveCardData(CardSeqNumb: "33", ExpiryDate: "0228")
let examplePaymentToken = PaymentToken(TokenRequestedType: "M469509594859802", TokenValue: "Customer")
let exampleCardData = CardData(EntryMode: ["Contactless"], PaymentToken: examplePaymentToken, PaymentBrand: "mc", MaskedPan: "541333 **** 9999", CardCountryCode: "826", SensitiveCardData: exampleSensitiveCardData)
let examplePaymentInstrumentData = PaymentInstrumentData(CardData: exampleCardData, PaymentInstrumentType: "Card")
let exampleResponse = Response(Result: "Success", AdditionalResponse: "...pspReference=982823828151799C...", ErrorCondition: nil)
let examplePOITransactionID = POITransactionID(TransactionID: "OJAE001613759925003", TimeStamp: "2021-02-19T18:38:44.000Z")
let examplePOIData = POIData(POIReconciliationID: "1000", POITransactionID: examplePOITransactionID)
let examplePaymentAcquirerData = PaymentAcquirerData(AcquirerPOIID: "e285p-860078740", MerchantID: "JustFabulous")
let examplePaymentResult = PaymentResult(PaymentAcquirerData: examplePaymentAcquirerData, PaymentInstrumentData: examplePaymentInstrumentData)
let exampleResponseSaleTransactionID = ResponseSaleTransactionID(TransactionID: "12345", TimeStamp: "2021-02-19T18:38:44.000Z")
let exampleResponseSaleData = ResponseSaleData(SaleTransactionID: exampleResponseSaleTransactionID)
let examplePaymentResponse = PaymentResponse(POIData: examplePOIData, Response: exampleResponse, AmountsResp: exampleAmountsResp, PaymentResult: examplePaymentResult, SaleData: exampleResponseSaleData)
let exampleSaleToPOIResponse = SaleToPOIResponse(MessageHeader: exampleMessageHeader, PaymentResponse: examplePaymentResponse, PaymentReceipt: examplePaymentReceipt)
let exampleSaleResponse = SaleResponse(SaleToPOIResponse: exampleSaleToPOIResponse)
