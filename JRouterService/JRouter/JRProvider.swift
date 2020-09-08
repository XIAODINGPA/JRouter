//
//  JRProvider.swift
//  23
//
//  Created by 焦瑞洁 on 2020/7/6.
//  Copyright © 2020 ddcx. All rights reserved.
//

import Foundation

typealias JRCompletion = (_ result: Any) -> Void

///
protocol JRProviderType: AnyObject {
    
    associatedtype Target: JRouterTargetType
    
    func link(_ target: Target, completion: @escaping JRCompletion)
}

class JRProvider<Target: JRouterTargetType>: JRProviderType {
    
    typealias LinkpointClosure = (Target) -> LinkPoint
    
    let linkpointClosure: LinkpointClosure
    
    var interceptClosure: ((Bool)->Void)?
    
    init(linkpointClosure: @escaping LinkpointClosure = JRProvider.defaultLinkpointMapping) {
        self.linkpointClosure = linkpointClosure
    }
    
    func link(_ target: Target, completion: @escaping JRCompletion) {
        linkNorml(target, completion:  completion)
    }
    
    func linkPoint(_ token : Target) -> LinkPoint {
        return linkpointClosure(token)
    }
}

extension JRProvider {
    
    func linkNorml(_ target: Target, completion: @escaping JRCompletion) {
        let linkPoint = self.linkPoint(target)
        if target.isIntercept == true {
            var copyTarget = target
            copyTarget.intercept = { [weak self](it) in
                self?.interceptClosure?(it)
            }
            performLink(copyTarget, completion: completion, linkPoint: linkPoint)
        }else{
            performLink(target, completion: completion, linkPoint: linkPoint)
        }
    }
    
    private func performLink(_ target: Target, completion: @escaping JRCompletion, linkPoint: LinkPoint){
        switch linkPoint.type {
        case .controller:
            intercept(perform: linkController, target: target, completion: completion, linkPoint: linkPoint)
        case .flutter:
            linkFlutter(target, targetClass: target.targetClass, completion: completion, linkPoint: linkPoint)
        case .bridge:
            break
        case .undefine:
            break
        }
    }
    
    private func intercept(perform: @escaping((Target, Any, @escaping JRCompletion, LinkPoint)->()), target: Target, completion: @escaping JRCompletion, linkPoint: LinkPoint){
        if target.isIntercept == true {
            var targetClass: Any? = nil
            interceptClosure = { (it) in
                if it == true{
                    if let lastClass = targetClass  {
                        perform(target, lastClass, completion, linkPoint)
                    }
                }
            }
            // 先进行目标初始化，才能进到拦截的异步回调之中
            targetClass = target.targetClass
        }else{
            perform(target, target.targetClass, completion, linkPoint)
        }
    }
}

extension JRProvider {
    final class func defaultLinkpointMapping(for target: Target) -> LinkPoint {
        return LinkPoint(
            type: target.type
        )
    }
}

class LinkPoint {
    let type: JRType
    init(type: JRType){
        self.type = type
    }
}