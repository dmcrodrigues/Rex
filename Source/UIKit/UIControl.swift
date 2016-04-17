//
//  UIView.swift
//  Rex
//
//  Created by Neil Pankey on 6/19/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import ReactiveCocoa
import UIKit
import enum Result.NoError

extension UIControl {
#if os(iOS)
    /// Creates a producer for the sender whenever a specified control event is triggered.
    public func rex_controlEvents(events: UIControlEvents) -> SignalProducer<UIControl?, NoError> {
        return rac_signalForControlEvents(events)
            .toSignalProducer()
            .map { $0 as? UIControl }
            .flatMapError { _ in SignalProducer(value: nil) }
    }
#endif

    /// Wraps a control's `enabled` state in a bindable property.
    public var rex_enabled: MutableProperty<Bool> {
        return associatedProperty(self, key: &enabledKey, initial: { $0.enabled }, setter: { $0.enabled = $1 })
    }
    
    /// Wraps a control's `selected` state in a bindable property.
    public var rex_selected: MutableProperty<Bool> {
        return associatedProperty(self, key: &selectedKey, initial: { $0.selected }, setter: { $0.selected = $1 })
    }
    
    /// Wraps a control's `highlighted` state in a bindable property.
    public var rex_highlighted: MutableProperty<Bool> {
        return associatedProperty(self, key: &highlightedKey, initial: { $0.highlighted }, setter: { $0.highlighted = $1 })
    }

    /// Exposes a property that binds an action into a control's value changed event. The
    /// action is set as a target of the control for `ValueChanged` events. When property
    /// changes occur the previous action is removed as a target. This also binds the
    /// enabled state of the action to the `rex_enabled` property on the control.
    public var rex_valueChanged: MutableProperty<CocoaAction> {
        return associatedObject(self, key: &valueChangedKey, initial: { [weak self] _ in
            let initial = CocoaAction.rex_disabled
            let property = MutableProperty(initial)

            property.producer
                .combinePrevious(initial)
                .start(Observer(next: { previous, next in
                    self?.removeTarget(previous, action: CocoaAction.selector, forControlEvents: .ValueChanged)
                    self?.addTarget(next, action: CocoaAction.selector, forControlEvents: .ValueChanged)
                }))

            if let strongSelf = self {
                strongSelf.rex_enabled <~ property.producer.flatMap(.Latest) { $0.rex_enabledProducer }
            }

            return property
        })
    }
}

private var enabledKey: UInt8 = 0
private var selectedKey: UInt8 = 0
private var highlightedKey: UInt8 = 0
private var valueChangedKey: UInt8 = 0
