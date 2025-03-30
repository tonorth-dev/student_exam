import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 设置平台通道处理器
    let channel = FlutterMethodChannel(
      name: "com.example.student_exam/screen_info",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getScreenSize" {
        // 获取主屏幕信息
        if let screen = NSScreen.main {
          let screenFrame = screen.frame
          let width = screenFrame.size.width
          let height = screenFrame.size.height
          
          // 返回屏幕尺寸
          result([
            "width": width,
            "height": height
          ])
        } else {
          result(FlutterError(code: "NO_SCREEN",
                            message: "无法获取屏幕信息",
                            details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
