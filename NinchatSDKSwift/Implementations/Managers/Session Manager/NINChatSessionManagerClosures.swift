//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

protocol NINChatSessionManagerClosureHandler {
    func bind(action id: Int, closure: @escaping ((Error?) -> Void))
    func unbine(action id: Int)
    
    func bind(queue id: String,  closure: @escaping ((Error?, Int) -> Void))
    func unbind(queue id: String)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerClosureHandler {
    internal func bind(action id: Int, closure: @escaping ((Error?) -> Void)) {
        if actionBindedClosures.keys.filter({ $0 == id }).count > 0 { return }
        actionBindedClosures[id] = closure
        
        if self.onActionID == nil {
            self.onActionID = { [weak self] id, error in
                let targetClosure = self?.actionBindedClosures.filter({ $0.key == id }).first?.value
                targetClosure?(error)
            }
        }
    }
    internal func unbine(action id: Int) {
        if actionBindedClosures.keys.filter({ $0 == id }).count == 0 { return }
        actionBindedClosures.removeValue(forKey: id)
    }
        
    internal func bind(queue id: String, closure: @escaping ((Error?, Int) -> Void)) {
        if progressBindedClosures.keys.filter({ $0 == id }).count > 0 { return }
        progressBindedClosures[id] = closure
        
        if self.onProgress == nil {
            self.onProgress = { [weak self] id, event, error in
                let targetClosure = self?.actionBindedClosures.filter({ $0.key == id }).first?.value
                targetClosure?(error)
            }
        }
    }
    internal func unbind(queue id: String) {
        if progressBindedClosures.keys.filter({ $0 == id }).count == 0 { return }
        progressBindedClosures.removeValue(forKey: id)
    }
}

/*
struct here {
    internal func captureActionFile(id: Int, closure: @escaping (([String:Any]?) -> Void)) {
        self.onActionFileInfo = { actionID, fileInfo in
            guard id == actionID else { return }
            closure(fileInfo)
        }
    }
    
    internal func captureActionProgress(id: Int, closure: @escaping ((Error?, Int) -> Void)) {
        self.onActionQueueUdpdated = { [weak self] actionID, position, queueID in
            guard id == actionID else { return }
            guard self?.currentQueueID == queueID else { return }
            
            closure(nil, position)
        }
        
        self.onQueuedError = { event, actionID, error in
            guard id == actionID else { return }
            
            closure(error, 0)
        }
    }
    
    internal func captureActionServers(id: Int, closure: @escaping ((Error?, [NINWebRTCServerInfo]?, [NINWebRTCServerInfo]?) -> Void)) {
        self.onActionSevers = { actionID, stunServers, turnServers in
            guard id == actionID else { return }
            
            closure(nil, stunServers, turnServers)
        }
        
        self.onActionSeversError = { actionID, error in
            guard id == actionID else { return }
            
            closure(error, nil, nil)
        }
    }
    
    internal func captureActionSession(event: Events, closure: @escaping ((Error?) -> Void)) {
        
    }
}
*/
