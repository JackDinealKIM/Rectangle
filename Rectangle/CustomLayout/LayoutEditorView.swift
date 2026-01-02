//
//  LayoutEditorView.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import SwiftUI

struct LayoutEditorView: View {
    @StateObject private var viewModel: LayoutEditorViewModel
    @Environment(\.presentationMode) var presentationMode

    init(layout: CustomLayout, screen: NSScreen) {
        _viewModel = StateObject(wrappedValue: LayoutEditorViewModel(layout: layout, screen: screen))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView

            Divider()

            HStack(spacing: 0) {
                // Canvas Area
                canvasView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Sidebar
                sidebarView
                    .frame(width: 250)
            }

            Divider()

            // Bottom Bar
            bottomBarView
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack {
            Text(viewModel.layout.name)
                .font(.headline)
                .padding(.leading)

            Spacer()

            Button("Add Zone") {
                viewModel.addDefaultZone()
            }

            Button("Grid Template") {
                viewModel.showGridTemplatePopover.toggle()
            }
            .popover(isPresented: $viewModel.showGridTemplatePopover) {
                gridTemplatePopover
            }

            Spacer()

            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }

            Button("Save") {
                viewModel.saveLayout()
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Canvas

    private var canvasView: some View {
        ZStack {
            // Background
            Color.black.opacity(0.1)

            // Screen Frame
            GeometryReader { geometry in
                let canvasSize = geometry.size
                let scale = min(canvasSize.width * 0.9, canvasSize.height * 0.9)
                let screenAspect = viewModel.screenFrame.width / viewModel.screenFrame.height
                let canvasWidth = screenAspect > 1 ? scale : scale * screenAspect
                let canvasHeight = screenAspect > 1 ? scale / screenAspect : scale

                ZStack {
                    // Screen background
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: canvasWidth, height: canvasHeight)
                        .border(Color.gray, width: 2)

                    // Zones
                    ForEach(viewModel.layout.zones) { zone in
                        ZoneView(
                            zone: zone,
                            canvasWidth: canvasWidth,
                            canvasHeight: canvasHeight,
                            isSelected: viewModel.selectedZoneId == zone.id,
                            onTap: { viewModel.selectZone(zone.id) },
                            onDrag: { translation in
                                viewModel.moveZone(zone.id, by: translation, canvasSize: CGSize(width: canvasWidth, height: canvasHeight))
                            },
                            onResize: { edge, translation in
                                viewModel.resizeZone(zone.id, edge: edge, by: translation, canvasSize: CGSize(width: canvasWidth, height: canvasHeight))
                            }
                        )
                    }

                    // Grid lines (optional)
                    if viewModel.showGrid {
                        gridLines(width: canvasWidth, height: canvasHeight)
                    }
                }
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)
            }
        }
    }

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Vertical lines
            ForEach(0..<Int(viewModel.gridColumns), id: \.self) { i in
                let x = width * CGFloat(i) / CGFloat(viewModel.gridColumns)
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }

            // Horizontal lines
            ForEach(0..<Int(viewModel.gridRows), id: \.self) { i in
                let y = height * CGFloat(i) / CGFloat(viewModel.gridRows)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zones")
                .font(.headline)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.layout.zones) { zone in
                        zoneListItem(zone)
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            if let selectedZone = viewModel.selectedZone {
                zoneProperties(selectedZone)
            }

            Spacer()
        }
        .padding(.vertical)
    }

    private func zoneListItem(_ zone: CustomZone) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name ?? "Zone \(zone.id.uuidString.prefix(8))")
                    .font(.subheadline)
                Text("x:\(Int(zone.rect.x * 100))% y:\(Int(zone.rect.y * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.deleteZone(zone.id)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(viewModel.selectedZoneId == zone.id ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            viewModel.selectZone(zone.id)
        }
    }

    private func zoneProperties(_ zone: CustomZone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zone Properties")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("X:")
                    TextField("X", value: Binding(
                        get: { zone.rect.x * 100 },
                        set: { viewModel.updateZoneRect(zone.id, x: $0 / 100, y: nil, width: nil, height: nil) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    Text("%")
                }

                HStack {
                    Text("Y:")
                    TextField("Y", value: Binding(
                        get: { zone.rect.y * 100 },
                        set: { viewModel.updateZoneRect(zone.id, x: nil, y: $0 / 100, width: nil, height: nil) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    Text("%")
                }

                HStack {
                    Text("W:")
                    TextField("Width", value: Binding(
                        get: { zone.rect.width * 100 },
                        set: { viewModel.updateZoneRect(zone.id, x: nil, y: nil, width: $0 / 100, height: nil) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    Text("%")
                }

                HStack {
                    Text("H:")
                    TextField("Height", value: Binding(
                        get: { zone.rect.height * 100 },
                        set: { viewModel.updateZoneRect(zone.id, x: nil, y: nil, width: nil, height: $0 / 100) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    Text("%")
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBarView: some View {
        HStack {
            Toggle("Show Grid", isOn: $viewModel.showGrid)

            Stepper("Columns: \(viewModel.gridColumns)", value: $viewModel.gridColumns, in: 2...12)
                .frame(width: 180)

            Stepper("Rows: \(viewModel.gridRows)", value: $viewModel.gridRows, in: 2...12)
                .frame(width: 180)

            Spacer()

            Text("\(viewModel.layout.zones.count) zones")
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Grid Template Popover

    private var gridTemplatePopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Grid Template")
                .font(.headline)

            HStack {
                Text("Columns:")
                Stepper("\(viewModel.templateColumns)", value: $viewModel.templateColumns, in: 1...6)
            }

            HStack {
                Text("Rows:")
                Stepper("\(viewModel.templateRows)", value: $viewModel.templateRows, in: 1...6)
            }

            Button("Create") {
                viewModel.createGridTemplate()
                viewModel.showGridTemplatePopover = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 250)
    }
}

// MARK: - Zone View

struct ZoneView: View {
    let zone: CustomZone
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGSize) -> Void
    let onResize: (ResizeEdge, CGSize) -> Void

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    private var absoluteRect: CGRect {
        CGRect(
            x: zone.rect.x * canvasWidth,
            y: zone.rect.y * canvasHeight,
            width: zone.rect.width * canvasWidth,
            height: zone.rect.height * canvasHeight
        )
    }

    var body: some View {
        ZStack {
            // Zone Rectangle
            Rectangle()
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                .border(isSelected ? Color.blue : Color.gray, width: 2)

            // Zone Label
            Text(zone.name ?? "Zone")
                .font(.caption)
                .foregroundColor(.primary)

            // Resize Handles (only when selected)
            if isSelected {
                resizeHandles
            }
        }
        .frame(width: absoluteRect.width, height: absoluteRect.height)
        .position(x: absoluteRect.midX, y: absoluteRect.midY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onDrag(value.translation)
                    isDragging = false
                    dragOffset = .zero
                }
        )
        .onTapGesture {
            onTap()
        }
        .offset(dragOffset)
    }

    private var resizeHandles: some View {
        Group {
            // Top-left
            resizeHandle(edge: .topLeft)
                .position(x: 0, y: 0)

            // Top-right
            resizeHandle(edge: .topRight)
                .position(x: absoluteRect.width, y: 0)

            // Bottom-left
            resizeHandle(edge: .bottomLeft)
                .position(x: 0, y: absoluteRect.height)

            // Bottom-right
            resizeHandle(edge: .bottomRight)
                .position(x: absoluteRect.width, y: absoluteRect.height)

            // Top
            resizeHandle(edge: .top)
                .position(x: absoluteRect.width / 2, y: 0)

            // Bottom
            resizeHandle(edge: .bottom)
                .position(x: absoluteRect.width / 2, y: absoluteRect.height)

            // Left
            resizeHandle(edge: .left)
                .position(x: 0, y: absoluteRect.height / 2)

            // Right
            resizeHandle(edge: .right)
                .position(x: absoluteRect.width, y: absoluteRect.height / 2)
        }
    }

    private func resizeHandle(edge: ResizeEdge) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        onResize(edge, value.translation)
                    }
            )
    }
}

enum ResizeEdge {
    case top, bottom, left, right
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - Preview

struct LayoutEditorView_Previews: PreviewProvider {
    static var previews: some View {
        if let screen = NSScreen.main {
            LayoutEditorView(
                layout: CustomLayout(
                    name: "Test Layout",
                    zones: [
                        CustomZone(rect: NormalizedRect(x: 0, y: 0, width: 0.5, height: 1.0))
                    ],
                    screenIdentifier: "test"
                ),
                screen: screen
            )
        }
    }
}
