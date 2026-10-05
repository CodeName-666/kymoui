<p align="center">
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/%F0%9F%8C%90-English-15123A"></a>
  <a href="README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/%F0%9F%8C%90-Deutsch-A78BFA"></a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/kymotrace-logo-dark.svg">
    <img src="docs/images/kymotrace-logo-light.svg" alt="Kymotrace – Embedded Telemetry" width="480">
  </picture>
</p>

<h3 align="center">KymoUi · The Qt Quick interface of KymoStudio</h3>

<p align="center">
  Qt Design Studio project of the <b>Kymotrace</b> user interface.
</p>

---

> [!NOTE]
> The interface is now developed directly in
> **[KymoStudio](https://github.com/CodeName-666/kymostudio)** under `qml/`.
> This repository remains as a standalone Qt Design Studio project and as the
> history of the interface.

<p align="center">
  <img src="docs/images/kymostudio-workbench.png" alt="The KymoStudio interface with a time series and an XY chart" width="900">
</p>

## What is in here

- **`content/`**: the workspace views, i.e. chart windows, connection dialogs, sidebars and toolbar
- **`imports/KymoUi`**, **`imports/Common`**: the QML module `KymoUi` with shared components and constants
- **`KymoUi.qmlproject`**: the project to open in Qt Design Studio
- **`CMakeLists.txt`**, **`src/`**: build as a standalone Qt 6 application (`KymoUiApp`)

## Part of Kymotrace

| Project | Role |
|---|---|
| [KymoStudio](https://github.com/CodeName-666/kymostudio) | desktop app: receive, display, analyse, export |
| [KymoCore](https://github.com/CodeName-666/kymocore) | portable C++11 library for transmitting measurements |
| [KymoProbe](https://github.com/CodeName-666/kymoprobe) | firmware and examples for ESP32, Arduino and STM32 |
