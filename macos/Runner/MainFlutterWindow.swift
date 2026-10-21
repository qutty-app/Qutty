import Cocoa
import FlutterMacOS
import ScreenCaptureKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    ScreenPickerChannel.register(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// Bridges the Dart `qutty/screen_picker` channel to the system
/// `SCContentSharingPicker`.
enum ScreenPickerChannel {
  static let name = "qutty/screen_picker"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "pick" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(macOS 14.0, *) {
        NativeScreenPicker.shared.present { payload in
          result(payload)
        }
      } else {
        result(["status": "unavailable"])
      }
    }
  }
}

/// Presents the macOS content-sharing picker (macOS 14+) and reports the chosen
/// screen or window in a form the Flutter side can map to a capture source.
///
/// When the choice cannot be resolved (a window on macOS 14.x, or the picker
/// failing to start) `status` is `unavailable` and the Dart caller falls back to
/// the in-app source list.
@available(macOS 14.0, *)
final class NativeScreenPicker: NSObject, SCContentSharingPickerObserver {
  static let shared = NativeScreenPicker()

  private var completion: (([String: Any]) -> Void)?

  /// Shows the system picker. The completion runs once, on the main queue.
  func present(completion: @escaping ([String: Any]) -> Void) {
    guard self.completion == nil else {
      completion(["status": "unavailable"])
      return
    }
    self.completion = completion
    let picker = SCContentSharingPicker.shared
    picker.add(self)
    picker.isActive = true
    picker.present()
  }

  private func finish(_ payload: [String: Any]) {
    guard let completion = completion else { return }
    self.completion = nil
    let picker = SCContentSharingPicker.shared
    picker.remove(self)
    picker.isActive = false
    DispatchQueue.main.async { completion(payload) }
  }

  func contentSharingPicker(
    _ picker: SCContentSharingPicker,
    didUpdateWith filter: SCContentFilter,
    for stream: SCStream?
  ) {
    switch filter.style {
    case .window:
      if #available(macOS 15.2, *), let window = filter.includedWindows.first {
        finish(["status": "picked", "type": "window", "label": window.title ?? ""])
      } else {
        // The window id cannot be mapped on this macOS version.
        finish(["status": "unavailable"])
      }
    default:
      if let displayID = displayID(for: filter) {
        finish(["status": "picked", "type": "screen", "sourceId": "\(displayID)"])
      } else {
        finish(["status": "unavailable"])
      }
    }
  }

  func contentSharingPicker(
    _ picker: SCContentSharingPicker,
    didCancelFor stream: SCStream?
  ) {
    finish(["status": "cancelled"])
  }

  func contentSharingPickerStartDidFailWithError(_ error: Error) {
    finish(["status": "unavailable"])
  }

  /// Resolves the display the filter points at. On macOS 15.2+ the filter lists
  /// its displays directly; older systems fall back to matching the filter's
  /// content size against each active display.
  private func displayID(for filter: SCContentFilter) -> CGDirectDisplayID? {
    if #available(macOS 15.2, *), let display = filter.includedDisplays.first {
      return display.displayID
    }
    let size = filter.contentRect.size
    guard size.width > 0, size.height > 0 else { return nil }
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
      return nil
    }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetActiveDisplayList(count, &displays, &count) == .success else {
      return nil
    }
    for id in displays {
      let bounds = CGDisplayBounds(id)
      if abs(bounds.width - size.width) < 1, abs(bounds.height - size.height) < 1 {
        return id
      }
    }
    return nil
  }
}
