//
//  CustomLayoutSnapping.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import Foundation
import AppKit

// MARK: - SnappingManager Extension for Custom Layouts

extension SnappingManager {

    /// Shift 키를 누른 상태에서 커스텀 레이아웃 존을 확인
    func customLayoutZoneContainingCursor() -> (zone: CustomZone, screen: NSScreen)? {
        let loc = NSEvent.mouseLocation

        for screen in NSScreen.screens {
            let screenId = CustomLayoutManager.screenIdentifier(for: screen)

            // 해당 스크린의 활성 레이아웃 가져오기
            guard let activeLayout = CustomLayoutManager.shared.getActiveLayout(forScreen: screenId) else {
                continue
            }

            // 커서가 스크린 안에 있는지 확인
            guard screen.frame.contains(loc) else { continue }

            // 정규화된 좌표로 변환
            let normalizedPoint = CGPoint(
                x: (loc.x - screen.frame.minX) / screen.frame.width,
                y: (loc.y - screen.frame.minY) / screen.frame.height
            )

            // 커서가 포함된 존 찾기
            if let zone = activeLayout.zone(at: normalizedPoint) {
                return (zone, screen)
            }
        }

        return nil
    }

    /// 커스텀 존에 윈도우 스냅
    func snapToCustomZone(zone: CustomZone, screen: NSScreen, windowElement: AccessibilityElement?, windowId: CGWindowID?) {
        guard let windowElement = windowElement else { return }

        let zoneRect = zone.absoluteRect(for: screen.adjustedVisibleFrame())

        // Gap 적용
        let gapSize = CustomLayoutManager.shared.getActiveLayout(forScreen: CustomLayoutManager.screenIdentifier(for: screen))?.gapSize ?? 0
        let finalRect = applyGapsToRect(zoneRect, gapSize: gapSize)

        // 윈도우 이동/리사이징
        windowElement.setFrame(finalRect, adjustSizeFirst: false)

        // 히스토리 저장
        if let windowId = windowId {
            AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
                action: .specified,
                rect: finalRect,
                visibleFrameOfScreen: screen.adjustedVisibleFrame()
            )
        }
    }

    private func applyGapsToRect(_ rect: CGRect, gapSize: Int) -> CGRect {
        guard gapSize > 0 else { return rect }

        let gap = CGFloat(gapSize)
        return CGRect(
            x: rect.minX + gap,
            y: rect.minY + gap,
            width: rect.width - gap * 2,
            height: rect.height - gap * 2
        )
    }

    /// 커스텀 레이아웃 오버레이 윈도우 표시 (Shift 키 누른 상태)
    func showCustomLayoutOverlay(for screen: NSScreen) {
        let screenId = CustomLayoutManager.screenIdentifier(for: screen)

        guard let activeLayout = CustomLayoutManager.shared.getActiveLayout(forScreen: screenId) else {
            return
        }

        // 모든 존을 FootprintWindow로 표시
        for zone in activeLayout.zones {
            let zoneRect = zone.absoluteRect(for: screen.adjustedVisibleFrame())

            let overlay = FootprintWindow()
            overlay.setFrame(zoneRect, display: true)
            overlay.orderFront(nil)

            // Zone 이름 레이블 추가 (옵션)
            if let zoneName = zone.name {
                let textField = NSTextField(labelWithString: zoneName)
                textField.frame = CGRect(x: 10, y: 10, width: zoneRect.width - 20, height: 20)
                textField.alignment = .center
                textField.textColor = .white
                textField.font = .systemFont(ofSize: 14, weight: .bold)
                overlay.contentView?.addSubview(textField)
            }

            // 임시 저장 (나중에 숨기기 위해)
            customLayoutOverlays.append(overlay)
        }
    }

    /// 커스텀 레이아웃 오버레이 숨기기
    func hideCustomLayoutOverlays() {
        for overlay in customLayoutOverlays {
            overlay.orderOut(nil)
        }
        customLayoutOverlays.removeAll()
    }

    // 오버레이 윈도우 임시 저장용
    private static var customLayoutOverlays: [FootprintWindow] = []
    private var customLayoutOverlays: [FootprintWindow] {
        get { SnappingManager.customLayoutOverlays }
        set { SnappingManager.customLayoutOverlays = newValue }
    }
}

// MARK: - Modified SnappingManager handle() for Custom Zones

/*
기존 SnappingManager의 handle() 메서드를 수정하여 Shift 키 감지 추가:

1. leftMouseDragged 이벤트에서 Shift 키 확인
2. Shift 키가 눌려있으면 customLayoutZoneContainingCursor() 호출
3. 커스텀 존이 감지되면 해당 존으로 FootprintWindow 표시
4. leftMouseUp 시 커스텀 존에 스냅

예시 코드 (SnappingManager.swift에 추가):

func handle(event: NSEvent) {
    switch event.type {
    case .leftMouseDragged:
        // 기존 로직...

        // Shift 키 감지
        let shiftPressed = event.modifierFlags.contains(.shift)

        if shiftPressed {
            // 커스텀 레이아웃 존 확인
            if let (zone, screen) = customLayoutZoneContainingCursor() {
                // 오버레이 표시
                if currentCustomZone?.id != zone.id {
                    box?.orderOut(nil)
                    let zoneRect = zone.absoluteRect(for: screen.adjustedVisibleFrame())
                    box?.setFrame(zoneRect, display: true)
                    box?.orderFront(nil)
                    currentCustomZone = zone
                    currentCustomScreen = screen
                }
            } else {
                currentCustomZone = nil
                currentCustomScreen = nil
            }
        } else {
            // 기존 스냅 로직
            if let snapArea = snapAreaContainingCursor(priorSnapArea: currentSnapArea) {
                // ...
            }
        }

    case .leftMouseUp:
        if let customZone = currentCustomZone, let customScreen = currentCustomScreen {
            box?.orderOut(nil)
            snapToCustomZone(zone: customZone, screen: customScreen, windowElement: windowElement, windowId: windowId)
            currentCustomZone = nil
            currentCustomScreen = nil
        } else if let currentSnapArea = self.currentSnapArea {
            // 기존 스냅 로직
        }
        // ...

    default:
        break
    }
}

// 프로퍼티 추가
var currentCustomZone: CustomZone?
var currentCustomScreen: NSScreen?
*/
