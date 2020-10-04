//
//  TaskQueue.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public final class TaskQueue: NSObject {

    public typealias DownloadTaskFactoryResult = (task: URLSessionTask, subscriptionReceipt: SubscriptionReceipt?)

    private let sessionName: String
    private let delegateQueue: OperationQueue

    private lazy var proxySessionDelegate: ProxySessionDelegate = ProxySessionDelegate(self)
    #if !os(tvOS) && !os(macOS)
    private lazy var assetsSession: AVAssetDownloadURLSession = makeAssetsSession()
    #endif
    private lazy var urlSession: URLSession = makeURLSession()

    public init(
        _ sessionName: String,
        delegateQueue: OperationQueue = .main
    ) {
        self.sessionName = sessionName
        self.delegateQueue = delegateQueue

        super.init()

        proxySessionDelegate.subscribe(self)
    }
}

extension TaskQueue {

    #if !os(tvOS) && !os(macOS)
    public func restoreAssetDownloadTasks(
        cancelNonRestorableTasks: Bool = true,
        _ taskProvider: @escaping (RestoredTask<AVURLAsset, AVAggregateAssetDownloadTask>) -> AVAssetDownloadDelegate?,
        _ taskSubscriptionCompletion: @escaping (URLSessionDelegate, SubscriptionReceipt) -> Void
    ) {
        _restoreTasks(
            session: assetsSession,
            cancelNonRestorableTasks: cancelNonRestorableTasks,
            taskProvider,
            taskSubscriptionCompletion
        )
    }
    #endif

    public func restoreDownloadTasks(
        cancelNonRestorableTasks: Bool = true,
        _ taskProvider: @escaping (RestoredTask<URLRequest, URLSessionDownloadTask>) -> URLSessionTaskDelegate?,
        _ taskSubscriptionCompletion: @escaping (URLSessionDelegate, SubscriptionReceipt) -> Void
    ) {
        _restoreTasks(
            session: urlSession,
            cancelNonRestorableTasks: cancelNonRestorableTasks,
            taskProvider,
            taskSubscriptionCompletion
        )
    }
}

extension TaskQueue {

    private func _restoreTasks<URLType: Hashable, Task, Delegate: URLSessionTaskDelegate>(
        session: URLSession,
        cancelNonRestorableTasks: Bool,
        _ taskProvider: @escaping (RestoredTask<URLType, Task>) -> Delegate?,
        _ taskSubscriptionCompletion: @escaping (URLSessionDelegate, SubscriptionReceipt) -> Void
    ) {
        session.getAllTasks { [proxySessionDelegate] tasks in
            let restoredTasks = tasks
                .compactMap { ($0 as? Task)?.taskDescription != nil ? $0 as? Task : nil }
                .compactMap { (taskDescription: $0.taskDescription!, sessionTask: $0 as! Task) }
                .compactMap { RestoredTask<URLType, Task>(name: $0.taskDescription, sessionTask: $0.sessionTask) }

            let setOfTasks = Set<RestoredTask<URLType, Task>>(restoredTasks)
            var counter = 0

            debugPrint("\(String(describing: self)): Will try to restore \(setOfTasks.count) \(String(describing: Task.self)) tasks.")

            for task in setOfTasks {
                guard let delegate = taskProvider(task) else {
                    if cancelNonRestorableTasks {
                        task.sessionTask.cancel()
                    }
                    continue
                }

                let receipt = proxySessionDelegate.subscribe(delegate, identifier: task)
                taskSubscriptionCompletion(delegate, receipt)
                counter += 1
            }

            debugPrint("\(String(describing: self)): \(counter) \(String(describing: Task.self)) tasks restored.")
        }
    }
    #if !os(tvOS) && !os(macOS)
    private func makeAssetsSession(
    ) -> AVAssetDownloadURLSession {
        let configuration = URLSessionConfiguration.background(
            withIdentifier: sessionName
        )
        configuration.sessionSendsLaunchEvents = true

        return AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: proxySessionDelegate,
            delegateQueue: delegateQueue
        )
    }
    #endif

    private func makeURLSession(
    ) -> URLSession {
        return URLSession(
            configuration: .default,
            delegate: proxySessionDelegate,
            delegateQueue: delegateQueue
        )
    }
}

extension TaskQueue {

    public func makeTask(
        _ downloadTask: AnyDownloadTask,
        delegate: URLSessionTaskDelegate? = nil
    ) -> DownloadTaskFactoryResult? {
        #if !os(tvOS) && !os(macOS)
        if let url = downloadTask.url as? AVURLAsset {
            let _assetDownloadTask = DownloadTask<AVURLAsset>(
                identifier: downloadTask.identifier,
                url: url,
                name: downloadTask.name,
                artworkData: downloadTask.artworkData,
                options: downloadTask.options
            )
            return makeAssetDownloadTask(
                _assetDownloadTask, delegate:
                    delegate as? AVAssetDownloadDelegate
            )
        } else if let url = downloadTask.url as? URLRequest {
            let _assetDownloadTask = DownloadTask<URLRequest>(
                identifier: downloadTask.identifier,
                url: url,
                name: downloadTask.name,
                artworkData: downloadTask.artworkData,
                options: downloadTask.options
            )
            return makeDownloadTask(
                _assetDownloadTask, delegate:
                    delegate as? URLSessionDownloadDelegate
            )
        } else {
            assertionFailure("Invalid download task request.")
            return nil
        }
        #else
        if let url = downloadTask.url as? URLRequest {
            let _assetDownloadTask = DownloadTask<URLRequest>(
                identifier: downloadTask.identifier,
                url: url,
                name: downloadTask.name,
                artworkData: downloadTask.artworkData,
                options: downloadTask.options
            )
            return makeDownloadTask(
                _assetDownloadTask, delegate:
                    delegate as? URLSessionDownloadDelegate
            )
        } else {
            assertionFailure("Invalid download task request.")
            return nil
        }
        #endif
    }

    #if !os(tvOS) && !os(macOS)
    public func makeAssetDownloadTask(
        _ downloadTask: DownloadTask<AVURLAsset>,
        delegate: AVAssetDownloadDelegate? = nil
    ) -> DownloadTaskFactoryResult? {
        let task = assetsSession.aggregateAssetDownloadTask(
            with: downloadTask.url,
            mediaSelections: [downloadTask.url.preferredMediaSelection],
            assetTitle: downloadTask.name,
            assetArtworkData: downloadTask.artworkData,
            options: downloadTask.options
        )
        task?.taskDescription = downloadTask.name

        guard let _task = task else {
            assertionFailure("Failed to make assetTask for DownloadTask with identifier: \(downloadTask.identifier)")
            return nil
        }

        var receipt: SubscriptionReceipt?
        if let delegate = delegate {
            receipt = proxySessionDelegate.subscribe(delegate, identifier: _task)
        }

        return (_task, receipt)
    }
    #endif

    public func makeDownloadTask(
        _ downloadTask: DownloadTask<URLRequest>,
        delegate: URLSessionTaskDelegate? = nil
    ) -> DownloadTaskFactoryResult? {
        let task = urlSession.downloadTask(with: downloadTask.url)
        task.taskDescription = downloadTask.name

        var receipt: SubscriptionReceipt?
        if let delegate = delegate {
            receipt = proxySessionDelegate.subscribe(delegate, identifier: task)
        }

        return (task, receipt)
    }
}

extension TaskQueue: ProxySessionDelegating {

    public func orphaned(
        task: URLSessionTask
    ) {
        debugPrint("ORPHANED TASK FOUND: \(task.taskIdentifier) => \(task.taskDescription ?? "<no task description>")")
    }
}
