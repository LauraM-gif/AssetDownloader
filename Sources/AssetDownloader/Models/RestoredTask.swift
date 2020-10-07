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

    init(
        name: String,
        url: URLType,
        sessionTask: Task
    ) {
        self.name = name
        self.url = url
        self.sessionTask = sessionTask
    }

    init?(
        name: String,
        sessionTask: URLSessionTask
    ) {
        switch (String(describing: URLType.self), String(describing: Task.self)) {
            #if !os(tvOS) && !os(macOS)
            case (String(describing: AVURLAsset.self), String(describing: AVAggregateAssetDownloadTask.self)):
                guard
                    let assetTask = sessionTask as? AVAggregateAssetDownloadTask,
                    let _url = assetTask.urlAsset as? URLType,
                    let _sessionTask = assetTask as? Task
                else {
                    assertionFailure("Invalid URLType(\(URLType.self)) and Task(\(Task.self)) combination")
                    return nil
                }
                self.name = name
                self.url = _url
                self.sessionTask = _sessionTask
            #endif
            case (String(describing: URLRequest.self), String(describing: URLSessionDownloadTask.self)):
                guard
                    let task = sessionTask as? URLSessionDownloadTask,
                    let request = task.currentRequest,
                    let _url = request as? URLType,
                    let _sessionTask = task as? Task
                else {
                    assertionFailure("Invalid URLType(\(URLType.self)) and Task(\(Task.self)) combination")
                    return nil
                }
                self.name = name
                self.url = _url
                self.sessionTask = _sessionTask
            default:
                assertionFailure("Invalid URLType(\(URLType.self)) and Task(\(Task.self)) combination")
                return nil
        }

    }
}

#if !os(tvOS) && !os(macOS)
extension RestoredTask where URLType == AVURLAsset, Task == AVAggregateAssetDownloadTask {

    init?(
        name: String,
        sessionTask: Task
    ) {
        self.name = name
        self.url = sessionTask.urlAsset
        self.sessionTask = sessionTask
    }

    static func ==(
        lhs: Self,
        rhs: Self
    ) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url
    }

    public func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        hasher.combine(url.url)
    }
}
#endif


extension RestoredTask where URLType == URLRequest, Task == URLSessionDownloadTask {

    init?(
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

    static func ==(
        lhs: Self,
        rhs: Self
    ) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url
    }

    public func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(name)
        hasher.combine(url.url)
    }
}
