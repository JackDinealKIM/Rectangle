//
//  CustomLayoutDefaults.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import Foundation

extension Defaults {
    /// 커스텀 레이아웃 기능 활성화 여부
    static let customLayoutsEnabled = BoolDefault(key: "customLayoutsEnabled", defaultValue: false)

    /// 커스텀 레이아웃 트리거 모디파이어 (기본: Shift)
    /// 0 = no modifier required, 1 = Shift, 2 = Control, 4 = Option, 8 = Command
    static let customLayoutModifier = IntDefault(key: "customLayoutModifier", defaultValue: 1) // Shift

    /// 커스텀 존 오버레이 표시 여부 (Shift 키 누를 때 모든 존 표시)
    static let showCustomLayoutOverlay = BoolDefault(key: "showCustomLayoutOverlay", defaultValue: true)

    /// 커스텀 존 미리보기 색상
    static let customZonePreviewColor = StringDefault(key: "customZonePreviewColor")
}

// MARK: - Notification Names

extension Notification.Name {
    static let customLayoutsToggled = Notification.Name("customLayoutsToggled")
    static let customLayoutModifierChanged = Notification.Name("customLayoutModifierChanged")
}
