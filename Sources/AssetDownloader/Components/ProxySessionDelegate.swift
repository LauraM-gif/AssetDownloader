//
//  ProxySessionDelegate.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public protocol ProxySessionDelegating: class, AVAssetDownloadDelegate  {

    func orphaned(
        task: URLSessionTask
    )
}

final class ProxySessionDelegate: NSObject {

    private var subscribers: [AnyHashable: AVAssetDownloadDelegate] = [:]
    private weak var delegate: ProxySessionDelegating?

    init(
        _ delegate: ProxySessionDelegating? = nil
    ) {
        self.delegate = delegate

        super.init()
    }
}

extension ProxySessionDelegate {

    private func delegate(
        for task: URLSessionTask
    ) -> AVAssetDownloadDelegate? {
        subscribers[task] ?? delegate
    }

    @discardableResult
    func subscribe(
        _ delegate: AVAssetDownloadDelegate,
        identifier: AnyHashable = UUID()
    ) -> SubscriptionReceipt {
        subscribers[identifier] = delegate
        return SubscriptionReceipt(
            unsubscribeBlock: { [weak self] in self?.subscribers[identifier] = nil }
        )
    }
}

extension ProxySessionDelegate {

    /// important: After this call the delegate will be removed from the subscribers list
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        delegate(for: task)?.urlSession?(
            session,
            task: task,
            didCompleteWithError: error
        )
    }

    func urlSessionDidFinishEvents(
        forBackgroundURLSession session: URLSession
    ) {
        delegate?.urlSessionDidFinishEvents?(
            forBackgroundURLSession: session
        )
    }
}

extension ProxySessionDelegate: AVAssetDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        didLoad timeRange: CMTimeRange,
        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange,
        for mediaSelection: AVMediaSelection
    ) {
        delegate(for: aggregateAssetDownloadTask)?.urlSession?(
            session,
            aggregateAssetDownloadTask: aggregateAssetDownloadTask,
            didLoad: timeRange,
            totalTimeRangesLoaded: loadedTimeRanges,
            timeRangeExpectedToLoad: timeRange,
            for: mediaSelection
        )
    }

    func urlSession(
        _ session: URLSession,
        aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        willDownloadTo location: URL
    ) {
        delegate(for: aggregateAssetDownloadTask)?.urlSession?(
            session,
            aggregateAssetDownloadTask: aggregateAssetDownloadTask,
            willDownloadTo: location
        )
    }
}
