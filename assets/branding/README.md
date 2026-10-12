# 应用图标

`app_icon.png` 按用户要求直接复制自 `D:/Projects/AnimeTrack/app/icon.png`：512 × 512 的月夜海面像素画。原图 SHA-256 为 `027708a18b6614196d4e4d7f0762da06f91019d61d3d00de6cf146e144bf557d`，没有修改 AnimeTrack 的文件。

运行 `./scripts/generate_app_icons.ps1` 可从本目录原图重新生成五种 Android 密度的传统图标和自适应前景，以及包含 16、24、32、48、64、128、256 像素图层的 Windows ICO。脚本只缩放、添加透明安全边距与转换文件格式，不重新绘制原图；Android 自适应背景沿用原图边缘的深蓝色 `#00031C`。

这些文件用于系统启动图标，无须作为 Flutter 页面运行时资源加入 pubspec。Android 的前景／背景定义在 `mipmap-anydpi-v26/ic_launcher.xml` 和 `values/ic_launcher_background.xml`；Windows 使用既有 `runner/resources/app_icon.ico` 资源位置。
