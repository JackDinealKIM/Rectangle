//
//  LayoutEditorViewModel.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit

class LayoutEditorViewModel: ObservableObject {
    @Published var layout: CustomLayout
    @Published var selectedZoneId: UUID?
    @Published var showGrid: Bool = true
    @Published var gridColumns: Int = 4
    @Published var gridRows: Int = 4
    @Published var showGridTemplatePopover: Bool = false
    @Published var templateColumns: Int = 2
    @Published var templateRows: Int = 2

    let screen: NSScreen
    var screenFrame: CGRect

    var selectedZone: CustomZone? {
        guard let id = selectedZoneId else { return nil }
        return layout.zones.first { $0.id == id }
    }

    init(layout: CustomLayout, screen: NSScreen) {
        self.layout = layout
        self.screen = screen
        self.screenFrame = screen.frame
    }

    // MARK: - Zone Management

    func addDefaultZone() {
        let newZone = CustomZone(
            rect: NormalizedRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
            name: "Zone \(layout.zones.count + 1)"
        )
        layout.addZone(newZone)
        selectedZoneId = newZone.id
    }

    func deleteZone(_ id: UUID) {
        layout.removeZone(id: id)
        if selectedZoneId == id {
            selectedZoneId = nil
        }
    }

    func selectZone(_ id: UUID) {
        selectedZoneId = id
    }

    // MARK: - Zone Editing

    func moveZone(_ id: UUID, by translation: CGSize, canvasSize: CGSize) {
        guard let zone = layout.zones.first(where: { $0.id == id }) else { return }

        let dx = translation.width / canvasSize.width
        let dy = translation.height / canvasSize.height

        var newRect = zone.rect
        newRect.x = max(0, min(1 - newRect.width, newRect.x + dx))
        newRect.y = max(0, min(1 - newRect.height, newRect.y + dy))

        layout.updateZone(id: id, rect: newRect)
    }

    func resizeZone(_ id: UUID, edge: ResizeEdge, by translation: CGSize, canvasSize: CGSize) {
        guard let zone = layout.zones.first(where: { $0.id == id }) else { return }

        let dx = translation.width / canvasSize.width
        let dy = translation.height / canvasSize.height

        var newRect = zone.rect

        switch edge {
        case .top:
            let newY = max(0, newRect.y + dy)
            let deltaY = newY - newRect.y
            newRect.y = newY
            newRect.height = max(0.05, newRect.height - deltaY)

        case .bottom:
            newRect.height = max(0.05, min(1 - newRect.y, newRect.height + dy))

        case .left:
            let newX = max(0, newRect.x + dx)
            let deltaX = newX - newRect.x
            newRect.x = newX
            newRect.width = max(0.05, newRect.width - deltaX)

        case .right:
            newRect.width = max(0.05, min(1 - newRect.x, newRect.width + dx))

        case .topLeft:
            let newX = max(0, newRect.x + dx)
            let newY = max(0, newRect.y + dy)
            let deltaX = newX - newRect.x
            let deltaY = newY - newRect.y
            newRect.x = newX
            newRect.y = newY
            newRect.width = max(0.05, newRect.width - deltaX)
            newRect.height = max(0.05, newRect.height - deltaY)

        case .topRight:
            let newY = max(0, newRect.y + dy)
            let deltaY = newY - newRect.y
            newRect.y = newY
            newRect.width = max(0.05, min(1 - newRect.x, newRect.width + dx))
            newRect.height = max(0.05, newRect.height - deltaY)

        case .bottomLeft:
            let newX = max(0, newRect.x + dx)
            let deltaX = newX - newRect.x
            newRect.x = newX
            newRect.width = max(0.05, newRect.width - deltaX)
            newRect.height = max(0.05, min(1 - newRect.y, newRect.height + dy))

        case .bottomRight:
            newRect.width = max(0.05, min(1 - newRect.x, newRect.width + dx))
            newRect.height = max(0.05, min(1 - newRect.y, newRect.height + dy))
        }

        layout.updateZone(id: id, rect: newRect)
    }

    func updateZoneRect(_ id: UUID, x: CGFloat?, y: CGFloat?, width: CGFloat?, height: CGFloat?) {
        guard let zone = layout.zones.first(where: { $0.id == id }) else { return }

        var newRect = zone.rect
        if let x = x { newRect.x = max(0, min(1 - newRect.width, x)) }
        if let y = y { newRect.y = max(0, min(1 - newRect.height, y)) }
        if let width = width { newRect.width = max(0.05, min(1 - newRect.x, width)) }
        if let height = height { newRect.height = max(0.05, min(1 - newRect.y, height)) }

        layout.updateZone(id: id, rect: newRect)
    }

    // MARK: - Grid Template

    func createGridTemplate() {
        var newZones: [CustomZone] = []

        let cols = templateColumns
        let rows = templateRows

        for row in 0..<rows {
            for col in 0..<cols {
                let zone = CustomZone(
                    rect: NormalizedRect(
                        x: CGFloat(col) / CGFloat(cols),
                        y: CGFloat(row) / CGFloat(rows),
                        width: 1.0 / CGFloat(cols),
                        height: 1.0 / CGFloat(rows)
                    ),
                    name: "Zone \(row * cols + col + 1)"
                )
                newZones.append(zone)
            }
        }

        layout.zones = newZones
        selectedZoneId = nil
    }

    // MARK: - Snap to Grid

    func snapToGrid(_ id: UUID) {
        guard let zone = layout.zones.first(where: { $0.id == id }) else { return }

        let gridWidth = 1.0 / CGFloat(gridColumns)
        let gridHeight = 1.0 / CGFloat(gridRows)

        var newRect = zone.rect
        newRect.x = round(newRect.x / gridWidth) * gridWidth
        newRect.y = round(newRect.y / gridHeight) * gridHeight
        newRect.width = round(newRect.width / gridWidth) * gridWidth
        newRect.height = round(newRect.height / gridHeight) * gridHeight

        layout.updateZone(id: id, rect: newRect)
    }

    // MARK: - Save

    func saveLayout() {
        CustomLayoutManager.shared.updateLayout(layout)
    }

    // MARK: - Zone Merging (Advanced)

    func mergeZones(_ zoneIds: [UUID]) {
        guard zoneIds.count >= 2 else { return }

        let zones = layout.zones.filter { zoneIds.contains($0.id) }
        guard zones.count == zoneIds.count else { return }

        // Calculate bounding rect
        var minX: CGFloat = 1.0
        var minY: CGFloat = 1.0
        var maxX: CGFloat = 0.0
        var maxY: CGFloat = 0.0

        for zone in zones {
            minX = min(minX, zone.rect.x)
            minY = min(minY, zone.rect.y)
            maxX = max(maxX, zone.rect.x + zone.rect.width)
            maxY = max(maxY, zone.rect.y + zone.rect.height)
        }

        let mergedZone = CustomZone(
            rect: NormalizedRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            ),
            name: "Merged Zone"
        )

        // Remove old zones and add merged zone
        for id in zoneIds {
            layout.removeZone(id: id)
        }
        layout.addZone(mergedZone)
        selectedZoneId = mergedZone.id
    }

    // MARK: - Duplicate Zone

    func duplicateZone(_ id: UUID) {
        guard let zone = layout.zones.first(where: { $0.id == id }) else { return }

        let duplicateZone = CustomZone(
            rect: NormalizedRect(
                x: min(0.9, zone.rect.x + 0.05),
                y: min(0.9, zone.rect.y + 0.05),
                width: zone.rect.width,
                height: zone.rect.height
            ),
            name: zone.name.map { "\($0) Copy" }
        )
        layout.addZone(duplicateZone)
        selectedZoneId = duplicateZone.id
    }
}
