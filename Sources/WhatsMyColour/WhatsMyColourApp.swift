import AppKit
import SwiftUI

@MainActor
final class ColorModel: ObservableObject {
    @Published var color = NSColor(srgbRed: 0.43, green: 0.35, blue: 0.96, alpha: 1)
    @Published var sampling = false
    @Published var copied = false
    private var sampler: NSColorSampler?
    private var resetTask: Task<Void, Never>?

    var hex: String { HexColor(color: color)?.string ?? "#000000" }

    func pick() {
        guard !sampling else { return }
        sampling = true
        copied = false
        let sampler = NSColorSampler()
        self.sampler = sampler
        sampler.show { [weak self] color in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let color { self.color = color }
                self.sampling = false
                self.sampler = nil
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
            }
        }
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
        copied = true
        resetTask?.cancel()
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.copied = false
        }
    }
}

struct PickerView: View {
    @ObservedObject var model: ColorModel

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Image(systemName: "eyedropper.halffull")
                Text("What's my colour?").fontWeight(.semibold)
                Spacer()
                Text("sRGB").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: model.color))
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.primary.opacity(0.08)))
                .accessibilityLabel("Selected color \(model.hex)")
            VStack(spacing: 8) {
                Text(model.hex).font(.system(size: 38, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                Text(model.copied ? "Copied to clipboard" : "Click a color anywhere, then copy its hex.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button(action: model.pick) {
                    Label("Pick color", systemImage: "eyedropper").frame(maxWidth: .infinity)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(model.sampling)
                Button(action: model.copy) {
                    Label(model.copied ? "Copied" : "Copy hex", systemImage: model.copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("c", modifiers: .command)
                .tint(.accentColor)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Text("⌘⇧P to pick · ⌘C to copy · Esc to cancel picking")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(28).frame(width: 380)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct WhatsMyColourApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = ColorModel()

    var body: some Scene {
        Window("What's my colour?", id: "picker") {
            PickerView(model: model)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .pasteboard) {
                Button("Copy Hex", action: model.copy).keyboardShortcut("c")
            }
        }
    }
}
