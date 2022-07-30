//
//  ContentView.swift
//  MyBitbank
//
//  Created on 2022/07/17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

struct MainView: View {
    @StateObject var viewModel = BitbankViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            Text(Int(viewModel.getTotalLastAmount()).withComma)
                .font(.largeTitle)

            HStack {
                Text(Int(viewModel.getTotalLastAmount() - viewModel.getTotalOpenAmount()).withComma)
                    .font(.title)
                
                Text(String(round(viewModel.getTotalRate() * 10 * 100) / 10) + "%")
                    .font(.title)
            }
            
            if (viewModel.updateCounter > 0) {
                AssetList(myAssets: viewModel.myAssets)
            } else {
                Text("Loading...")
            }
            
            Button(action: {
                viewModel.getUserAssets()
            }, label: { Text("更新") })
        }
        .onAppear {
            viewModel.getUserAssets()
            //viewModel.getTicker(pair: "btc_jpy")
        }
    }
}

struct AssetList: View {
    var myAssets: [MyAsset]
    
    var body: some View {
        List {
            if (myAssets.count > 0) {
                ForEach(myAssets) { myAsset in
                    AssetItem(myAsset: myAsset)
                }
            }
        }
    }
}

struct AssetItem: View {
    @ObservedObject var myAsset: MyAsset
    
    var body: some View {
        HStack(spacing: 0) {
            Text(myAsset.asset.asset)
            Spacer()
            Text(Int(round(myAsset.getLastAmount())).withComma)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
            Text(Int(round(myAsset.getLastAmount() - myAsset.getOpenAmount())).withComma)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
            Text(String(round(myAsset.getLastRate() * 10 * 100) / 10) + "%")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        //.frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private let formatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    f.groupingSize = 3
    return f
}()

extension Int {
    var withComma: String {
        return formatter.string(from: NSNumber(integerLiteral: self)) ?? "\(self)"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
