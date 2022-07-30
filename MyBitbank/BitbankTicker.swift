//
//  BitbankTicker.swift
//  MyBitbank
//  
//  Created on 2022/07/18
//  
//

import Foundation

// MARK: - BitbankTicker
struct BitbankTicker: Codable {
    let success: Int
    let data: Ticker
}

// MARK: - DataClass
struct Ticker: Codable {
    let sell, buy, high, low: String
    let dataOpen, last, vol: String
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case sell, buy, high, low
        case dataOpen = "open"
        case last, vol, timestamp
    }
}
