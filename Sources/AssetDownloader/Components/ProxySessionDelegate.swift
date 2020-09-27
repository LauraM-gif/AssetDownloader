//
//  ProxySessionDelegate.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

#if os(tvOS) || os(macOS)
public protocol ProxySessionDelegating: class, URLSessionTaskDelegate  {

    func orphaned(
        task: URLSessionTask
    )
}

#else
public protocol ProxySessionDelegating: class, AVAssetDownloadDelegate  {

    func orphaned(
        task: URLSessionTask
    )
}
#endif

final class ProxySessionDelegate: NSObject {

    private var subscribers: [AnyHashable: URLSessionTaskDelegate] = [:]
    private weak var delegate: ProxySessionDelegating?

    init(
        _ delegate: ProxySessionDelegating? = nil
    ) {
        self.delegate = delegate

        super.init()
    }
}

extension ProxySessionDelegate {

    private func _delegate<Delegate: URLSessionTaskDelegate>(
        for task: URLSessionTask
    ) -> Delegate? {
        (subscribers[task] ?? delegate) as? Delegate
    }

    private func taskDelegate(
        for task: URLSessionTask
    ) -> URLSessionTaskDelegate? {
        _delegate(for: task)
    }

    private func downloadTaskDelegate(
        for task: URLSessionDownloadTask
    ) -> URLSessionDownloadDelegate? {
        _delegate(for: task)
    }

#if !os(tvOS) && !os(macOS)
    private func assetDelegate(
        for task: AVAggregateAssetDownloadTask
    ) -> AVAssetDownloadDelegate? {
        _delegate(for: task)
    }
#endif
    
    @discardableResult
    func subscribe(
        _ delegate: URLSessionTaskDelegate,
        identifier: AnyHashable = UUID()
    ) -> SubscriptionReceipt {
        subscribers[identifier] = delegate
        return SubscriptionReceipt(
            unsubscribeBlock: { [weak self] in self?.subscribers[identifier] = nil }
        )
    }
}

extension ProxySessionDelegate: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        downloadTaskDelegate(for: downloadTask)?.urlSession?(
            session,
            downloadTask: downloadTask,
            didWriteData: bytesWritten,
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite
        )
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        downloadTaskDelegate(for: downloadTask)?.urlSession(
            session,
            downloadTask: downloadTask,
            didFinishDownloadingTo: location
        )
    }
}

#if !os(tvOS) && !os(macOS)
extension ProxySessionDelegate: AVAssetDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        didLoad timeRange: CMTimeRange,
        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange,
        for mediaSelection: AVMediaSelection
    ) {
        assetDelegate(for: aggregateAssetDownloadTask)?.urlSession?(
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
        assetDelegate(for: aggregateAssetDownloadTask)?.urlSession?(
            session,
            aggregateAssetDownloadTask: aggregateAssetDownloadTask,
            willDownloadTo: location
        )
    }
}
#endif

extension ProxySessionDelegate /* : URLSessionTaskDelegate */ {

    /// important: After this call the delegate will be removed from the subscribers list
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        taskDelegate(for: task)?.urlSession?(
            session,
            task: task,
            didCompleteWithError: error
        )
    }

    #if !os(macOS)
    func urlSessionDidFinishEvents(
        forBackgroundURLSession session: URLSession
    ) {
        delegate?.urlSessionDidFinishEvents?(
            forBackgroundURLSession: session
        )
    }
    #endif
}
