//
//  Haptics.swift
//  test
//
//  Created by jose pablo sanchez guillen on 21/11/25.
//

import UIKit

final class Haptics {
    static let shared = Haptics()
    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(type)
    }
}
