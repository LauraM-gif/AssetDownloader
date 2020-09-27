//
//  RestoredTask.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public struct RestoredTask<URLType: Hashable, Task: URLSessionTask>: Hashable, Equatable {
    public let name: String
    public let url: URLType
    public let sessionTask: Task

    public func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        if let assetURL = url as? AVURLAsset {
            hasher.combine(assetURL.url)
        }
    }

    public static func ==(
        lhs: Self,
        rhs: Self
    ) -> Bool {
        return lhs.name == rhs.name
            && (lhs.url as? AVURLAsset)?.url == (rhs.url as? AVURLAsset)?.url
    }
}
