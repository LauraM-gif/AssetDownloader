//
//  Task.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public struct DownloadTask<URLType: Hashable> {
    public let identifier: String
    public let url: URLType
    public let name: String
    public let artworkData: Data?
    public let options: [String : Any]?

    public init(
        identifier: String,
        url: URLType,
        name: String? = nil,
        artworkData: Data? = nil,
        options: [String : Any]? = nil
    ) {
        self.identifier = identifier
        self.url = url
        self.name = name ?? identifier
        self.artworkData = artworkData
        self.options = options
    }

    public func eraseToAnyDownloadTask(
    ) -> AnyDownloadTask {
        AnyDownloadTask(
            identifier: identifier,
            url: url,
            name: name,
            artworkData: artworkData,
            options: options
        )
    }
}

extension DownloadTask where URLType == AVURLAsset {

    public init(
        identifier: String,
        url: URL,
        name: String? = nil,
        artworkData: Data? = nil,
        options: [String : Any]? = nil
    ) {
        self.init(
            identifier: identifier,
            url: AVURLAsset(url: url),
            name: name,
            artworkData: artworkData,
            options: options
        )
    }
}


public struct AnyDownloadTask {

    public let identifier: String
    public let url: AnyHashable
    public let name: String
    public let artworkData: Data?
    public let options: [String : Any]?
}
