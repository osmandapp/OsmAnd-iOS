//
//  TooManyRequestsRetryStrategy.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Kingfisher

struct TooManyRequestsRetryStrategy: RetryStrategy {
    
    enum Interval: Sendable {
        /// The current retry count is given as a parameter.
        case custom(block: @Sendable (_ retriedCount: Int) -> TimeInterval)
        
        func timeInterval(for retriedCount: Int) -> TimeInterval {
            let retryAfter: TimeInterval
            switch self {
            case .custom(let block):
                retryAfter = block(retriedCount)
            }
            return retryAfter
        }
    }
    
    let maxRetryCount: Int
    let retryInterval: Interval
    
    func retry(context: RetryContext, retryHandler: @escaping @Sendable (RetryDecision) -> Void) {
        guard context.retriedCount < maxRetryCount else {
            retryHandler(.stop)
            return
        }
        
        guard !context.error.isTaskCancelled else {
            retryHandler(.stop)
            return
        }
        
        guard case let .responseError(reason) = context.error else {
            retryHandler(.stop)
            return
        }
        
        switch reason {
        case .invalidHTTPStatusCode(let response):
            guard response.statusCode == 429 else {
                retryHandler(.stop)
                return
            }
            
            let interval = retryInterval.timeInterval(for: context.retriedCount)
            if interval <= 0 {
                retryHandler(.retry(userInfo: nil))
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    retryHandler(.retry(userInfo: nil))
                }
            }
            
        default:
            retryHandler(.stop)
        }
    }
}
