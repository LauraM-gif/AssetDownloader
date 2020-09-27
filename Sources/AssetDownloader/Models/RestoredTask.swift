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

    public init(
        name: String,
        url: URLType,
        sessionTask: Task
    ) {
        self.name = name
        self.url = url
        self.sessionTask = sessionTask
    }

    public init?(
        name: String,
        sessionTask: Task
    ) {
        assertionFailure("Invalid URLType and Task combination")
        return nil
    }

    public func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        if let assetURL = (url as? AVURLAsset)?.url {
            hasher.combine(assetURL)
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

#if !os(tvOS) && !os(macOS)
extension RestoredTask where URLType == AVURLAsset, Task == AVAggregateAssetDownloadTask {

    public init(
        name: String,
        sessionTask: Task
    ) {
        self.name = name
        self.url = sessionTask.urlAsset
        self.sessionTask = sessionTask
    }
}
#endif


extension RestoredTask where URLType == URLRequest, Task == URLSessionDownloadTask {

    public init?(
        name: String,
        sessionTask: Task
    ) {
        guard let request = sessionTask.currentRequest else {
            return nil
        }
        self.name = name
        self.url = request
        self.sessionTask = sessionTask
    }
}
