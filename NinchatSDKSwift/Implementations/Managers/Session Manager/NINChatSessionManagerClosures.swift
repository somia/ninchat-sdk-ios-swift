//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINChatSessionManagerClosureHandler {
    func bind(action id: Int?, closure: @escaping (Error?) -> Void)
    func bindFile(action id: Int?, closure: @escaping (Error?, [String:Any]?) -> Void)
    func bindChannel(action id: Int?, closure: @escaping (Error?) -> Void)
    func bindICEServer(action id: Int?, closure: @escaping (Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerClosureHandler {
    internal func bind(action id: Int?, closure: @escaping (Error?) -> Void) {
        guard let id = id else { return }
        self.actionBoundClosures[id] = closure
        
        if self.onActionID == nil {
            self.onActionID = { [weak self, id, closure] result, error in
                if let targetClosure = self?.actionBoundClosures.filter({
                    guard case let .success(id) = result else { return false }
                    return $0.key == id
                }).first?.value {
                    targetClosure(error)
                }
            }
        }
    }
    
    internal func bindFile(action id: Int?, closure: @escaping (Error?, [String:Any]?) -> Void) {
        guard let id = id else { return }
        self.actionFileBoundClosures[id] = closure
        
        if self.onActionFileInfo == nil {
            self.onActionFileInfo = { [weak self, id, closure] result, fileInfo, error in
                if let targetClosure = self?.actionFileBoundClosures.filter({
                    guard case let .success(id) = result else { return false }
                    return $0.key == id
                }).first?.value {
                    targetClosure(error, fileInfo)
                }
            }
        }
    }
    
    internal func bindChannel(action id: Int?, closure: @escaping (Error?) -> Void) {
        guard let id = id else { return }
        self.actionChannelBoundClosures[id] = closure

        if self.onActionChannel == nil {
            self.onActionChannel = { [weak self, id, closure] result, channelID in
                if let targetClosure = self?.actionChannelBoundClosures.filter({
                    guard case let .success(id) = result else { return false }
                    return $0.key == id
                }).first?.value {
                    targetClosure(nil)
                }
            }
        }
    }
    
    internal func bindICEServer(action id: Int?, closure: @escaping (Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void) {
        guard let id = id else { return }
        self.actionICEServersBoundClosures[id] = closure

        if self.onActionSevers == nil {
            self.onActionSevers = { [weak self, id, closure] result, stunServers, turnServers in
                if let targetClosure = self?.actionICEServersBoundClosures.filter({
                    guard case let .success(id) = result else { return false }
                    return $0.key == id
                }).first?.value {

                    targetClosure(nil, stunServers, turnServers)
                }
            }
        }
    }
}
