# MiMo TTS Tool

基于 Flutter 的 MiMo V2.5 TTS 桌面客户端，支持小米 MiMo 语音合成 API 的全部三种模型。

## 功能

- **内置音色** — 8 款预置音色（冰糖/茉莉/苏打/白桦/Mia/Chloe/Milo/Dean），开箱即用
- **音色设计** — 通过文本描述自定义生成全新音色
- **音色克隆** — 提供音频样本即可复刻任意声音
- **风格控制** — 支持自然语言指令、音频标签、导演模式
- **本地 TTS 服务** — 内置 HTTP 服务，其他应用可通过 API 调用
- **暗色/亮色主题** — 跟随系统自动切换

## 快速开始

1. 安装 [Flutter](https://flutter.dev/docs/get-started/install)
2. 获取 API Key：[MiMo 开放平台](https://platform.xiaomimimo.com/#/console/api-keys)
3. 运行：

```bash
flutter pub get
flutter run -d windows
```

首次启动时输入 API Key 即可使用。

## 本地 TTS 服务

在设置页面开启本地服务后，可通过 HTTP API 调用：

```bash
curl -X POST http://localhost:8899/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input":"你好世界","voice":"冰糖"}' \
  --output output.wav
```

## 模型说明

| 模型 | 用途 |
|------|------|
| `mimo-v2.5-tts` | 预置音色语音合成，支持唱歌 |
| `mimo-v2.5-tts-voicedesign` | 文本描述定制音色 |
| `mimo-v2.5-tts-voiceclone` | 音频样本复刻音色 |

## 依赖

- Flutter 3.x
- [audioplayers](https://pub.dev/packages/audioplayers) — 音频播放
- [http](https://pub.dev/packages/http) — API 请求
- [shared_preferences](https://pub.dev/packages/shared_preferences) — 本地存储
- [file_picker](https://pub.dev/packages/file_picker) — 文件选择（音色克隆）

## License

MIT
