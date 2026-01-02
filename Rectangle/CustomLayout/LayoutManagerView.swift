//
//  LayoutManagerView.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import SwiftUI
import AppKit

/// 환경설정에 통합될 레이아웃 관리 뷰
struct LayoutManagerView: View {
    @ObservedObject private var layoutManager = CustomLayoutManager.shared
    @State private var selectedScreen: NSScreen?
    @State private var showingEditor = false
    @State private var editingLayout: CustomLayout?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Custom Layouts")
                    .font(.title2)
                    .bold()

                Spacer()

                Button("Create New Layout") {
                    createNewLayout()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Screen Selector
            HStack {
                Text("Select Screen:")
                    .font(.headline)

                Picker("Screen", selection: $selectedScreen) {
                    Text("All Screens").tag(nil as NSScreen?)
                    ForEach(NSScreen.screens, id: \.self) { screen in
                        let screenId = CustomLayoutManager.screenIdentifier(for: screen)
                        Text(screenName(for: screen)).tag(screen as NSScreen?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)

                Spacer()
            }
            .padding(.horizontal)

            Divider()

            // Layout List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredLayouts) { layout in
                        LayoutCard(
                            layout: layout,
                            isActive: isActive(layout),
                            onActivate: { activateLayout(layout) },
                            onEdit: { editLayout(layout) },
                            onDuplicate: { duplicateLayout(layout) },
                            onDelete: { deleteLayout(layout) }
                        )
                    }

                    if filteredLayouts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.3.group")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No layouts for this screen")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Create a new layout or select a preset")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding()
            }

            Divider()

            // Preset Templates
            presetsSection
        }
        .sheet(isPresented: $showingEditor) {
            if let layout = editingLayout, let screen = selectedScreen ?? NSScreen.main {
                LayoutEditorView(layout: layout, screen: screen)
            }
        }
    }

    private var filteredLayouts: [CustomLayout] {
        if let screen = selectedScreen {
            let screenId = CustomLayoutManager.screenIdentifier(for: screen)
            return layoutManager.layouts.filter { $0.screenIdentifier == screenId }
        }
        return layoutManager.layouts
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preset Templates")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presetTemplates, id: \.name) { preset in
                        PresetCard(
                            name: preset.name,
                            iconName: preset.iconName,
                            onSelect: { createFromPreset(preset) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Helper Methods

    private func screenName(for screen: NSScreen) -> String {
        let screenId = CustomLayoutManager.screenIdentifier(for: screen)
        let resolution = "\(Int(screen.frame.width))x\(Int(screen.frame.height))"
        if screen == NSScreen.main {
            return "Main Screen (\(resolution))"
        }
        return "Screen \(screenId) (\(resolution))"
    }

    private func isActive(_ layout: CustomLayout) -> Bool {
        let screenId = layout.screenIdentifier
        return layoutManager.activeLayoutPerScreen[screenId] == layout.id
    }

    private func activateLayout(_ layout: CustomLayout) {
        layoutManager.setActiveLayout(layoutId: layout.id, forScreen: layout.screenIdentifier)
    }

    private func createNewLayout() {
        guard let screen = selectedScreen ?? NSScreen.main else { return }
        let screenId = CustomLayoutManager.screenIdentifier(for: screen)
        editingLayout = CustomLayout(
            name: "New Layout",
            zones: [],
            screenIdentifier: screenId
        )
        showingEditor = true
    }

    private func editLayout(_ layout: CustomLayout) {
        editingLayout = layout
        selectedScreen = NSScreen.screens.first { screen in
            CustomLayoutManager.screenIdentifier(for: screen) == layout.screenIdentifier
        }
        showingEditor = true
    }

    private func duplicateLayout(_ layout: CustomLayout) {
        var duplicate = layout
        duplicate.name = "\(layout.name) Copy"
        layoutManager.addLayout(duplicate)
    }

    private func deleteLayout(_ layout: CustomLayout) {
        layoutManager.deleteLayout(id: layout.id)
    }

    private func createFromPreset(_ preset: PresetTemplate) {
        guard let screen = selectedScreen ?? NSScreen.main else { return }
        let layouts = CustomLayoutManager.createPresetLayouts(for: screen)
        if let presetLayout = layouts.first(where: { $0.name == preset.name }) {
            layoutManager.addLayout(presetLayout)
        }
    }

    // MARK: - Preset Templates

    struct PresetTemplate {
        let name: String
        let iconName: String
    }

    private var presetTemplates: [PresetTemplate] {
        [
            PresetTemplate(name: "Two Columns", iconName: "rectangle.split.2x1"),
            PresetTemplate(name: "Three Columns", iconName: "rectangle.split.3x1"),
            PresetTemplate(name: "Grid 2x2", iconName: "square.grid.2x2"),
            PresetTemplate(name: "Coding Setup", iconName: "chevron.left.forwardslash.chevron.right")
        ]
    }
}

// MARK: - Layout Card

struct LayoutCard: View {
    let layout: CustomLayout
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Preview (simplified)
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 80, height: 60)
                    .border(Color.gray, width: 1)

                ForEach(layout.zones.prefix(4)) { zone in
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(
                            width: zone.rect.width * 70,
                            height: zone.rect.height * 50
                        )
                        .border(Color.blue, width: 1)
                        .position(
                            x: 40 + zone.rect.x * 70 + zone.rect.width * 35,
                            y: 30 + zone.rect.y * 50 + zone.rect.height * 25
                        )
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(layout.name)
                        .font(.headline)

                    if isActive {
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text("\(layout.zones.count) zones")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Modified: \(layout.modifiedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(isActive ? "Active" : "Activate") {
                    onActivate()
                }
                .disabled(isActive)

                Button("Edit") {
                    onEdit()
                }

                Menu {
                    Button("Duplicate", action: onDuplicate)
                    Divider()
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let name: String
    let iconName: String
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)

            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Preview

struct LayoutManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LayoutManagerView()
            .frame(width: 800, height: 600)
    }
}
