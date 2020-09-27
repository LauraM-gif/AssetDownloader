//
//  SubscriptionReceipt.swift
//  AssetDownloader
//
//  Created by Ilias Pavlidakis on 27/09/2020.
//

import Foundation

public struct SubscriptionReceipt {

    weak var delegate: URLSessionDelegate?
    let unsubscribeBlock: () -> Void
}
