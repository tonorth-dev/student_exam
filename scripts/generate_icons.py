from PIL import Image
import os

def create_icon_if_not_exists(input_path, output_path, size):
    if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
        img = Image.open(input_path)
        # 直接调整大小，保持原始比例
        img = img.resize((size, size), Image.Resampling.LANCZOS)
        # 保存为PNG，使用最高质量
        img.save(output_path, 'PNG', optimize=True, quality=100)
        print(f"Generated {output_path}")

def main():
    # 源图片路径
    input_path = "assets/images/logo.png"
    
    # macOS 图标路径
    macos_icon_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(macos_icon_dir, exist_ok=True)
    
    # 生成不同尺寸的图标
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    for size in sizes:
        output_path = os.path.join(macos_icon_dir, f"app_icon_{size}.png")
        create_icon_if_not_exists(input_path, output_path, size)
    
    print("Icon generation completed!")

if __name__ == "__main__":
    main() 