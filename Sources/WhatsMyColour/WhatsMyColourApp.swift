import AppKit
import SwiftUI

@MainActor
final class ColorModel: ObservableObject {
    @Published var color = NSColor(srgbRed: 0.43, green: 0.35, blue: 0.96, alpha: 1)
    @Published var sampling = false
    @Published var copied = false
    private let sampler = LiveSampler()
    @Published var error: String?
    private var escapeMonitor: Any?
    private var resetTask: Task<Void, Never>?

    init() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            let cancelled = MainActor.assumeIsolated {
                if self?.sampling == true {
                    self?.stopSampling()
                    return true
                }
                return false
            }
            return cancelled ? nil : event
        }
    }

    var hex: String { HexColor(color: color)?.string ?? "#000000" }

    func pick() {
        if sampling {
            stopSampling()
            return
        }
        error = nil
        copied = false
        sampling = true
        sampler.start { [weak self] color in
            self?.color = color
        } failure: { [weak self] message in
            self?.sampling = false
            self?.error = message
        }
    }

    func stopSampling() {
        sampler.stop()
        sampling = false
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
                Text(model.copied ? "Copied to clipboard" : (model.sampling ? "Move your pointer anywhere to inspect its color." : "Start live sampling to inspect your screen."))
                    .font(.callout).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button(action: model.pick) {
                    Label(model.sampling ? "Freeze color" : "Start live", systemImage: model.sampling ? "pause.fill" : "eyedropper").frame(maxWidth: .infinity)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                Button(action: model.copy) {
                    Label(model.copied ? "Copied" : "Copy hex", systemImage: model.copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("c", modifiers: .command)
                .tint(.accentColor)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
            }
            Text("⌘⇧P to start / freeze · Esc to cancel · ⌘C to copy")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(28).frame(width: 380)
        .onAppear {
            NSApp.windows.first(where: { $0.canBecomeMain })?.level = .floating
        }
        .onDisappear(perform: model.stopSampling)
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
            CommandMenu("Color") {
                Button("Cancel Sampling", action: model.stopSampling)
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(!model.sampling)
            }
            CommandGroup(replacing: .pasteboard) {
                Button("Copy Hex", action: model.copy).keyboardShortcut("c")
            }
        }
    }
}
