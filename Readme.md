# GrammarFixAI

<p align="center">
  <img src="assets/icon.png" alt="GrammarFixAI Icon" width="120"/>
</p>

A lightweight, menu bar–based macOS grammar checker that lets you instantly correct grammar, spelling, and punctuation from anywhere in your workflow — no sign-up required, totally free.

---

## 📥 Installation

Download from the **[Mac App Store](https://apps.apple.com/us/app/grammarfixai/id6751153698?mt=12)**.

---

## 📖 Important Note

I’m sharing this source so others can **explore, learn from it, and hopefully gain useful insights**.

Please note, however, this is **not** intended for rebranding or redistribution under a different name with minimal changes.

---
 
## Screenshots
 
| | |
|---|---|
| ![Fix with Apple Intelligence](screenshots/screenshot_1.png) | ![Fix with OpenAI](screenshots/screenshot_2.png) |
| Fix with Apple Intelligence | Fix with OpenAI |
| ![Dark mode](screenshots/screenshot_3.png) | ![Provider switching](screenshots/screenshot_4.png) |
| Dark mode support | Switch AI providers |
 
![Right-click integration](screenshots/screenshot_5.png)
*Fix Grammar from the Services menu in any app*
 
---

### 🔧 Configuration Steps

1. Create a `GoogleService-Info.plist` file using the steps in the link [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
2. Place it inside the `GrammarFixAI` folder
3. Update the app identifier for the project
4. Also update the `keychain-access-groups` in the `GrammarFixAI.entitlements`
5. Now run the project

---

## 🚀 Usage

1. Launch GrammarFixAI — it lives in your menu bar.
2. Paste or type text, then click **Fix** for instant corrections.
3. Use ⌥⌘0 or Services menu to correct selected text in any app.
4. Enable _Launch at Login_ in preferences if you want it always running.

---

## 🖥 Requirements

- macOS **15.5 or later**
- App size: ~2 MB
- Language support: English
- Price: Free

---

## 📜 License

This project is licensed under a custom BSD-style license. See the [LICENSE](LICENSE) file for details.
