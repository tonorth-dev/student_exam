#include "flutter_window.h"

#include <optional>
#include <Windows.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // 注册平台通道处理器
  flutter::MethodChannel<flutter::EncodableValue> channel(
      flutter_controller_->engine()->messenger(), "com.example.student_exam/screen_info",
      &flutter::StandardMethodCodec::GetInstance());

  // 设置平台通道的处理函数
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue> &call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getScreenSize") {
          // 获取主屏幕的尺寸（像素）
          int screenWidth = GetSystemMetrics(SM_CXSCREEN);
          int screenHeight = GetSystemMetrics(SM_CYSCREEN);

          // 获取系统 DPI
          HDC hdc = GetDC(NULL);
          int dpiX = GetDeviceCaps(hdc, LOGPIXELSX);
          ReleaseDC(NULL, hdc);

          // 计算逻辑尺寸 (96 是标准 DPI)
          double logicalWidth = screenWidth * (96.0 / dpiX);
          double logicalHeight = screenHeight * (96.0 / dpiX);

          // 创建返回值
          flutter::EncodableMap screen_size;
          screen_size[flutter::EncodableValue("width")] = flutter::EncodableValue(logicalWidth);
          screen_size[flutter::EncodableValue("height")] = flutter::EncodableValue(logicalHeight);
          
          result->Success(flutter::EncodableValue(screen_size));
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
