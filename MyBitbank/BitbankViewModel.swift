//
//  BitbankViewModel.swift
//  MyBitbank
//  
//  Created on 2022/07/18
//  
//

import Foundation
import CryptoSwift

class MyAsset: Identifiable, ObservableObject {
    let id = UUID()
    @Published var asset: Asset
    @Published var ticker: Ticker?
    
    init(_ asset: Asset) {
        self.asset = asset
        self.ticker = nil
    }
    
    // 現在の評価額
    func getLastAmount() -> Double {
        var amount = 0.0
        if let last = Double(ticker?.last ?? "0.0"), let onhandAmount = Double(asset.onhandAmount) {
            if (asset.asset == "jpy") {
                amount = onhandAmount
            } else {
                amount = last * onhandAmount
            }
            //print("[MyAsset#getLastAmount] last: \(last), onhandAmount: \(onhandAmount), amount: \(amount)")
        }
        return amount
    }

    // 24時間前の評価額
    func getOpenAmount() -> Double {
        var amount = 0.0
        if let open = Double(ticker?.datumOpen ?? "0.0"), let onhandAmount = Double(asset.onhandAmount) {
            if (asset.asset == "jpy") {
                amount = onhandAmount
            } else {
                amount = open * onhandAmount
            }
        }
        return amount
    }
    
    // ここ24時間の損益
    func getLastRate() -> Double {
        var rate = 0.0
        let last = getLastAmount()
        let open = getOpenAmount()
        if open != 0.0 {
            let delta = last - open
            rate = delta / open
        }
        return rate
    }
}

class BitbankViewModel: ObservableObject {
    let publicEndpoint = "https://public.bitbank.cc"
    let privateEndpoint = "https://api.bitbank.cc"
    let apiKey = "" // bitbankのポータルサイトで取得したAPIキー
    let apiSecret = "" // bitbankのポータルサイトで取得したシークレット
    
    @Published var myAssets: [MyAsset] = []
    @Published var updateCounter = 0

    func getTotalLastAmount() -> Double {
        var total = 0.0
        for myAsset in myAssets {
            total += myAsset.getLastAmount()
        }
        return total
    }
    
    func getTotalOpenAmount() -> Double {
        var total = 0.0
        for myAsset in myAssets {
            total += myAsset.getOpenAmount()
        }
        return total
    }
    
    func getTotalRate() -> Double {
        var rate = 0.0
        let last = getTotalLastAmount()
        let open = getTotalOpenAmount()
        let delta = last - open
        if open != 0.0 {
            rate = delta / open
       }
        return rate
    }
    
    func getTicker(pair: String) {
        let path = "/\(pair)/ticker"
        
        let urlString = publicEndpoint + path
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                print(object)
            } catch let error {
                print(error)
            }
        }
        task.resume()
    }

    func getTickers() {
        let path = "/tickers"
        
        let urlString = publicEndpoint + path
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                print(object)
            } catch let error {
                print(error)
            }

            let decoder = JSONDecoder()
            if let response = try? decoder.decode(BitbankTickersResponse.self, from: data) {
                DispatchQueue.main.async {
                    for ticker in response.data {
                        for i in 0..<self.myAssets.count {
                            let pair = self.myAssets[i].asset.asset + "_jpy"
                            if (ticker.pair == pair) {
                                self.myAssets[i].ticker = ticker
                                self.updateCounter += 1
                                break
                            }
                        }
                    }
                }
            } else {
                fatalError("Failed to decode from JSON.")
            }
        }
        task.resume()
    }

    func getUserAssets() {
        let path = "/v1/user/assets"
        let queryParam = ""
        
        let urlString = privateEndpoint + path + queryParam
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        let date: Date = Date()
        let nonce = String(Int(date.timeIntervalSince1970 * 10000))
        
        let signature = makeSignature(secret: apiSecret, nonce: nonce, path: path, queryParam: queryParam)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["ACCESS-KEY": apiKey]
        request.allHTTPHeaderFields = ["ACCESS-NONCE": nonce]
        request.allHTTPHeaderFields = ["ACCESS-SIGNATURE": signature]
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                print(jsonObject)
            } catch let error {
                print(error)
            }

            let decoder = JSONDecoder()
            if let response = try? decoder.decode(BitbankUserAssetsResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.myAssets.removeAll()
                    for asset in response.data.assets {
                        if let onhandAmount = Double(asset.onhandAmount) {
                            if (onhandAmount > 0.0) {
                                let myAsset = MyAsset(asset)
                                self.myAssets.append(myAsset)
                            }
                        }
                    }
                    
                    // 時価情報の取得
                    self.getTickers()
                }
            } else {
                fatalError("Failed to decode from JSON.")
            }
        }
        task.resume()
    }

    func getPrivateTradeHistory() {
        let path = "/v1/user/spot/trade_history"
        let queryParam = "?pair=btc_jpy"
        
        let urlString = privateEndpoint + path + queryParam
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        let date: Date = Date()
        let nonce = String(Int(date.timeIntervalSince1970 * 10000))
        
        let signature = makeSignature(secret: apiSecret, nonce: nonce, path: path, queryParam: queryParam)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["ACCESS-KEY": apiKey]
        request.allHTTPHeaderFields = ["ACCESS-NONCE": nonce]
        request.allHTTPHeaderFields = ["ACCESS-SIGNATURE": signature]
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                print(object)
            } catch let error {
                print(error)
            }
        }
        task.resume()
    }
    
    func makeSignature(secret: String, nonce: String, path: String, queryParam: String = "") -> String {
        let str = nonce + path + queryParam
        print(str)
        let bytes = str.bytes
        var signature = ""
        do {
            let hmac = try HMAC(key: secret, variant: .sha256).authenticate(bytes)
            signature = hmac.toHexString()
        } catch let error {
            print(error)
        }
        return signature
    }
}

//extension StringProtocol {
//    var bytes: [UInt8] { .init(utf8) }
//}


