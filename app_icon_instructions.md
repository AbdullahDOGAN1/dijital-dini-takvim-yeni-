# App Icon Generator Script
# Bu dosya flutter_launcher_icons paketini kullanarak app icon oluşturmaya yardımcı olur

# pubspec.yaml'a eklenecek dependency:
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_icon.svg"
  min_sdk_android: 21 # android min sdk version
  web:
    generate: true
    image_path: "assets/images/app_icon.svg"
    background_color: "#2d4a3e"
    theme_color: "#f4d03f"
  windows:
    generate: true
    image_path: "assets/images/app_icon.svg"
    icon_size: 48 # min:48, max:256, default: 48

# Komutlar:
# 1. pubspec.yaml'a yukarıdaki konfigürasyonu ekleyin
# 2. Terminal'de çalıştırın: flutter pub get
# 3. Icon'ları oluşturmak için: flutter pub run flutter_launcher_icons
