//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINChatSessionManagerClosureHandler {
    func bind(action id: Int?, closure: @escaping ((Error?) -> Void))
    func bindFile(action id: Int?, closure: @escaping ((Error?, [String:Any]?) -> Void))
    func bindChannel(action id: Int?, closure: @escaping ((Error?) -> Void))
    func bindICEServer(action id: Int?, closure: @escaping ((Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void))
    func unbind(action id: Int?)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerClosureHandler {
    internal func bind(action id: Int?, closure: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async {
            guard let id = id, self.actionBoundClosures.keys.filter({ $0 == id }).count == 0 else { return }
            self.actionBoundClosures[id] = closure
            
            if self.onActionID == nil {
                self.onActionID = { [weak self] result, error in
                    let targetClosure = self?.actionBoundClosures.filter({
                        guard case let .success(id) = result else { return false }
                        return $0.key == id
                    }).first?.value
                    targetClosure?(error)
                    
                    self?.actionBoundClosures.removeValue(forKey: id)
                }
            }
        }
    }
    
    internal func bindFile(action id: Int?, closure: @escaping ((Error?, [String:Any]?) -> Void)) {
        DispatchQueue.main.async {
            guard let id = id, self.actionFileBoundClosures.keys.filter({ $0 == id }).count == 0 else { return }
            self.actionFileBoundClosures[id] = closure
            
            if self.onActionFileInfo == nil {
                self.onActionFileInfo = { [weak self] result, fileInfo, error in
                    let targetClosure = self?.actionFileBoundClosures.filter({
                        guard case let .success(id) = result else { return false }
                        return $0.key == id
                    }).first?.value
                    targetClosure?(error, fileInfo)
                    
                    self?.actionFileBoundClosures.removeValue(forKey: id)
                }
            }
        }
    }
    
    internal func bindChannel(action id: Int?, closure: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async {
            guard let id = id, self.actionChannelBoundClosures.keys.filter({ $0 == id }).count == 0 else { return }
            self.actionChannelBoundClosures[id] = closure
            
            if self.onActionChannel == nil {
                self.onActionChannel = { [weak self] result, channelID in
                    let targetClosure = self?.actionChannelBoundClosures.filter({
                        guard case let .success(id) = result else { return false }
                        return $0.key == id
                    }).first?.value
                    targetClosure?(nil)
                    
                    self?.actionChannelBoundClosures.removeValue(forKey: id)
                }
            }
        }
    }
    
    internal func bindICEServer(action id: Int?, closure: @escaping ((Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void)) {
        DispatchQueue.main.async {
            guard let id = id, self.actionICEServersBoundClosures.keys.filter({ $0 == id }).count == 0 else { return }
            self.actionICEServersBoundClosures[id] = closure
            
            if self.onActionSevers == nil {
                self.onActionSevers = { [weak self] result, stunServers, turnServers in
                    let targetClosure = self?.actionICEServersBoundClosures.filter({
                        guard case let .success(id) = result else { return false }
                        return $0.key == id
                    }).first?.value
                    targetClosure?(nil, stunServers, turnServers)
                    
                    self?.actionICEServersBoundClosures.removeValue(forKey: id)
                }
            }
        }
    }
    
    internal func unbind(action id: Int?) {
        guard let id = id else { return }
        if actionBoundClosures.keys.filter({ $0 == id }).count > 0 {
            actionBoundClosures.removeValue(forKey: id)
        } else if actionFileBoundClosures.keys.filter({ $0 == id }).count > 0 {
            actionFileBoundClosures.removeValue(forKey: id)
        } else if actionChannelBoundClosures.keys.filter({ $0 == id }).count > 0 {
            actionChannelBoundClosures.removeValue(forKey: id)
        } else if actionICEServersBoundClosures.keys.filter({ $0 == id }).count > 0 {
            actionICEServersBoundClosures.removeValue(forKey: id)
        }
    }
}
