//
//  TaskQueue.swift
//  AVAssetDownloader
//
//  Created by Ilias Pavlidakis on 26/09/2020.
//

import Foundation
import AVFoundation

public final class TaskQueue: NSObject {

    private let sessionName: String
    private let delegateQueue: OperationQueue

    private lazy var proxySessionDelegate: ProxySessionDelegate = ProxySessionDelegate(self)
    private lazy var session: AVAssetDownloadURLSession = makeSession()

    public init(
        _ sessionName: String,
        delegateQueue: OperationQueue = .main
    ) {
        self.sessionName = sessionName
        self.delegateQueue = delegateQueue

        super.init()
    }
}

extension TaskQueue {

    // The taskProvider will have to resume the tasks he receives
    public func restoreAssetDownloadTasks(
        _ taskProvider: @escaping (RestoredTask<AVURLAsset, AVAggregateAssetDownloadTask>) -> AVAssetDownloadDelegate?,
        cancelNonRestorableTasks: Bool = true
    ) {
        var setOfTasks = Dictionary<String ,RestoredTask<AVURLAsset, AVAggregateAssetDownloadTask>>()
        session.getAllTasks { [proxySessionDelegate] tasks in
            tasks
                .compactMap { ($0 as? AVAggregateAssetDownloadTask)?.taskDescription != nil ? $0 as? AVAggregateAssetDownloadTask : nil  }
                .map { RestoredTask<AVURLAsset, AVAggregateAssetDownloadTask>(name: $0.taskDescription!, url: $0.urlAsset, sessionTask: $0) }
                .forEach { if setOfTasks[$0.name] == nil { setOfTasks[$0.name] = $0 } }

            for task in setOfTasks.values {
                guard let delegate = taskProvider(task) else {
                    if cancelNonRestorableTasks {
                        task.sessionTask.cancel()
                    }
                    continue
                }

                proxySessionDelegate.subscribe(delegate, identifier: task)
            }
        }
    }
}

extension TaskQueue {

    private func makeSession(
    ) -> AVAssetDownloadURLSession {
        let configuration = URLSessionConfiguration.background(
            withIdentifier: sessionName
        )
        configuration.sessionSendsLaunchEvents = true

        proxySessionDelegate.subscribe(self)

        return AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: proxySessionDelegate,
            delegateQueue: delegateQueue
        )
    }
}

extension TaskQueue {

    public func makeAssetDownloadTask(
        _ downloadTask: DownloadTask<AVURLAsset>,
        delegate: AVAssetDownloadDelegate? = nil
    ) -> (URLSessionTask, (() -> Void)?)? {

        let task = session.aggregateAssetDownloadTask(
            with: downloadTask.url,
            mediaSelections: [downloadTask.url.preferredMediaSelection],
            assetTitle: downloadTask.name,
            assetArtworkData: downloadTask.artworkData,
            options: downloadTask.options
        )
        task?.taskDescription = downloadTask.name

        guard let _task = task else {
            assertionFailure("Failed to make task for DownloadTask with identifier: \(downloadTask.identifier)")
            return nil
        }

        var unsubscribeBlock: (() -> Void)?
        if let delegate = delegate {
            unsubscribeBlock = proxySessionDelegate.subscribe(delegate, identifier: _task)
        }

        return (_task, unsubscribeBlock)
    }
}

extension TaskQueue: ProxySessionDelegating {

    public func orphaned(
        task: URLSessionTask
    ) {
        debugPrint("ORPHANED TASK FOUND: \(task.taskIdentifier) => \(task.taskDescription ?? "<no task description>")")
    }
}
