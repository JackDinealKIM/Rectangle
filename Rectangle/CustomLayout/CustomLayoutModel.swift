//
//  CustomLayoutModel.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import Foundation
import AppKit

// MARK: - Custom Zone (정규화된 좌표 0.0~1.0 사용)
struct CustomZone: Codable, Identifiable, Equatable {
    let id: UUID
    var rect: NormalizedRect  // 정규화된 좌표 (0.0 ~ 1.0)
    var name: String?

    init(id: UUID = UUID(), rect: NormalizedRect, name: String? = nil) {
        self.id = id
        self.rect = rect
        self.name = name
    }

    /// 실제 화면 좌표로 변환
    func absoluteRect(for screenFrame: CGRect) -> CGRect {
        return CGRect(
            x: screenFrame.minX + rect.x * screenFrame.width,
            y: screenFrame.minY + rect.y * screenFrame.height,
            width: rect.width * screenFrame.width,
            height: rect.height * screenFrame.height
        )
    }

    /// 커서가 이 존 안에 있는지 확인 (정규화된 좌표 기준)
    func contains(normalizedPoint: CGPoint) -> Bool {
        let zoneRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        return zoneRect.contains(normalizedPoint)
    }
}

// MARK: - Normalized Rect (0.0 ~ 1.0)
struct NormalizedRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// CGRect를 정규화된 좌표로 변환
    static func fromAbsolute(_ rect: CGRect, screenFrame: CGRect) -> NormalizedRect {
        return NormalizedRect(
            x: (rect.minX - screenFrame.minX) / screenFrame.width,
            y: (rect.minY - screenFrame.minY) / screenFrame.height,
            width: rect.width / screenFrame.width,
            height: rect.height / screenFrame.height
        )
    }

    var minX: CGFloat { x }
    var minY: CGFloat { y }
    var maxX: CGFloat { x + width }
    var maxY: CGFloat { y + height }
    var midX: CGFloat { x + width / 2 }
    var midY: CGFloat { y + height / 2 }
}

// MARK: - Custom Layout (모니터별 레이아웃)
struct CustomLayout: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var zones: [CustomZone]
    var screenIdentifier: String  // 모니터 고유 ID (시리얼 번호 또는 UUID)
    var gapSize: Int  // 존 간 간격 (픽셀)
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(),
         name: String,
         zones: [CustomZone] = [],
         screenIdentifier: String,
         gapSize: Int = 0) {
        self.id = id
        self.name = name
        self.zones = zones
        self.screenIdentifier = screenIdentifier
        self.gapSize = gapSize
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    mutating func addZone(_ zone: CustomZone) {
        zones.append(zone)
        modifiedAt = Date()
    }

    mutating func removeZone(id: UUID) {
        zones.removeAll { $0.id == id }
        modifiedAt = Date()
    }

    mutating func updateZone(id: UUID, rect: NormalizedRect) {
        if let index = zones.firstIndex(where: { $0.id == id }) {
            zones[index].rect = rect
            modifiedAt = Date()
        }
    }

    /// 특정 위치에 있는 존 찾기 (정규화된 좌표)
    func zone(at normalizedPoint: CGPoint) -> CustomZone? {
        return zones.first { $0.contains(normalizedPoint: normalizedPoint) }
    }
}

// MARK: - Layout Manager (싱글톤)
class CustomLayoutManager: ObservableObject {
    static let shared = CustomLayoutManager()

    @Published var layouts: [CustomLayout] = []
    @Published var activeLayoutPerScreen: [String: UUID] = [:]  // screenID -> layoutID

    private let layoutsKey = "customLayouts"
    private let activeLayoutsKey = "activeLayoutPerScreen"

    private init() {
        loadLayouts()
    }

    // MARK: - Persistence

    func saveLayouts() {
        if let encoded = try? JSONEncoder().encode(layouts) {
            UserDefaults.standard.set(encoded, forKey: layoutsKey)
        }
        if let encoded = try? JSONEncoder().encode(activeLayoutPerScreen) {
            UserDefaults.standard.set(encoded, forKey: activeLayoutsKey)
        }
    }

    func loadLayouts() {
        if let data = UserDefaults.standard.data(forKey: layoutsKey),
           let decoded = try? JSONDecoder().decode([CustomLayout].self, from: data) {
            layouts = decoded
        }

        if let data = UserDefaults.standard.data(forKey: activeLayoutsKey),
           let decoded = try? JSONDecoder().decode([String: UUID].self, from: data) {
            activeLayoutPerScreen = decoded
        }
    }

    // MARK: - CRUD Operations

    func addLayout(_ layout: CustomLayout) {
        layouts.append(layout)
        saveLayouts()
    }

    func updateLayout(_ layout: CustomLayout) {
        if let index = layouts.firstIndex(where: { $0.id == layout.id }) {
            layouts[index] = layout
            saveLayouts()
        }
    }

    func deleteLayout(id: UUID) {
        layouts.removeAll { $0.id == id }
        // 활성 레이아웃에서도 제거
        activeLayoutPerScreen = activeLayoutPerScreen.filter { $0.value != id }
        saveLayouts()
    }

    func setActiveLayout(layoutId: UUID, forScreen screenId: String) {
        activeLayoutPerScreen[screenId] = layoutId
        saveLayouts()
    }

    func getActiveLayout(forScreen screenId: String) -> CustomLayout? {
        guard let layoutId = activeLayoutPerScreen[screenId] else { return nil }
        return layouts.first { $0.id == layoutId }
    }

    // MARK: - Screen Identification

    static func screenIdentifier(for screen: NSScreen) -> String {
        // 모니터 고유 식별자 생성 (UUID 기반)
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "Screen_\(screenNumber.intValue)"
        }
        // Fallback: 화면 프레임 기반 해시
        let frameString = "\(screen.frame.width)x\(screen.frame.height)"
        return "Screen_\(frameString.hashValue)"
    }

    // MARK: - Preset Layouts

    static func createPresetLayouts(for screen: NSScreen) -> [CustomLayout] {
        let screenId = screenIdentifier(for: screen)

        return [
            // 2분할 (좌/우)
            CustomLayout(
                name: "Two Columns",
                zones: [
                    CustomZone(rect: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0)),
                    CustomZone(rect: NormalizedRect(x: 0.5, y: 0.0, width: 0.5, height: 1.0))
                ],
                screenIdentifier: screenId
            ),

            // 3분할 (좌/중앙/우)
            CustomLayout(
                name: "Three Columns",
                zones: [
                    CustomZone(rect: NormalizedRect(x: 0.0, y: 0.0, width: 0.33, height: 1.0)),
                    CustomZone(rect: NormalizedRect(x: 0.33, y: 0.0, width: 0.34, height: 1.0)),
                    CustomZone(rect: NormalizedRect(x: 0.67, y: 0.0, width: 0.33, height: 1.0))
                ],
                screenIdentifier: screenId
            ),

            // Grid 2x2
            CustomLayout(
                name: "Grid 2x2",
                zones: [
                    CustomZone(rect: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5)),
                    CustomZone(rect: NormalizedRect(x: 0.5, y: 0.0, width: 0.5, height: 0.5)),
                    CustomZone(rect: NormalizedRect(x: 0.0, y: 0.5, width: 0.5, height: 0.5)),
                    CustomZone(rect: NormalizedRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
                ],
                screenIdentifier: screenId
            ),

            // Coding Setup (왼쪽 넓게 + 오른쪽 2분할)
            CustomLayout(
                name: "Coding Setup",
                zones: [
                    CustomZone(rect: NormalizedRect(x: 0.0, y: 0.0, width: 0.6, height: 1.0), name: "Editor"),
                    CustomZone(rect: NormalizedRect(x: 0.6, y: 0.0, width: 0.4, height: 0.5), name: "Terminal"),
                    CustomZone(rect: NormalizedRect(x: 0.6, y: 0.5, width: 0.4, height: 0.5), name: "Browser")
                ],
                screenIdentifier: screenId
            )
        ]
    }
}
