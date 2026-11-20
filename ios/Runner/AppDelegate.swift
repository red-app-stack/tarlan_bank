import Flutter
import UIKit
import CoreImage

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Whether screen protection is armed. When true, the blurred overlay is
  /// shown whenever the app resigns active (app switcher / lock screen).
  private var blurEnabled = false
  private var blurImageView: UIImageView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // No OS-level screenshot-blocking API exists on iOS. Instead of blocking,
    // we cover the app-switcher / lock-screen snapshot with a blurred image
    // of the app itself (same approach screen_protector takes).
    let channel = FlutterMethodChannel(name: "screen_protect_native", binaryMessenger: engine().binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        self?.blurEnabled = true
        if UIApplication.shared.applicationState != .active {
          self?.showBlur()
        } else {
          self?.hideBlur()
        }
        result(true)
      case "disable":
        self?.blurEnabled = false
        self?.hideBlur()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
      return true
    }
    return ok
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    if blurEnabled { showBlur() }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hideBlur()
  }

  private func keyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: \.isKeyWindow)
    }
    return nil
  }

  private func showBlur() {
    guard blurImageView == nil,
          let window = keyWindow(),
          let rootView = window.rootViewController?.view else { return }

    // Snapshot the current UI, then blur it hard enough for a banking app.
    let renderer = UIGraphicsImageRenderer(bounds: rootView.bounds)
    let snapshot = renderer.image { size in
      rootView.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: false)
    }

    guard let ciImage = CIImage(image: snapshot) else { return }
    let filter = CIFilter(name: "CIGaussianBlur")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(60.0, forKey: kCIInputRadiusKey)

    guard let blurred = filter.outputImage?.cropped(to: ciImage.extent),
          let image = UIImage(ciImage: blurred) else { return }

    let imageView = UIImageView(image: image)
    imageView.frame = rootView.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.isUserInteractionEnabled = false
    rootView.addSubview(imageView)
    blurImageView = imageView
  }

  private func hideBlur() {
    blurImageView?.removeFromSuperview()
    blurImageView = nil
  }
}
