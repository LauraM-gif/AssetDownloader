//
//  RestoredTask.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public struct RestoredTask<URLType: Hashable, Task: URLSessionTask>: Hashable {
    public let name: String
    public let url: URLType
    public let sessionTask: Task

    public func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        hasher.combine(url)
    }
}