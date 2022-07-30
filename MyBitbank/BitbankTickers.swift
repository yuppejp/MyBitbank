//
//  BitbankTickers.swift
//  MyBitbank
//  
//  Created on 2022/07/23
//  
//

import Foundation

struct BitbankTickersResponse: Codable {
    let success: Int
    let data: [Ticker]
}

struct Ticker: Codable {
    let pair, sell, buy, high: String
    let low, datumOpen, last, vol: String
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case pair, sell, buy, high, low
        case datumOpen = "open"
        case last, vol, timestamp
    }
}

