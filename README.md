<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/kymotrace-logo-dark.svg">
    <img src="docs/images/kymotrace-logo-light.svg" alt="Kymotrace – Embedded Telemetry" width="480">
  </picture>
</p>

<h3 align="center">KymoUi · Die Qt-Quick-Oberfläche von KymoStudio</h3>

<p align="center">
  Qt-Design-Studio-Projekt der Benutzeroberfläche von <b>Kymotrace</b>.
</p>

---

> [!NOTE]
> Die Oberfläche wird inzwischen direkt in
> **[KymoStudio](https://github.com/CodeName-666/kymostudio)** unter `qml/`
> weiterentwickelt. Dieses Repository bleibt als eigenständiges
> Qt-Design-Studio-Projekt und als Historie der Oberfläche erhalten.

<p align="center">
  <img src="docs/images/kymostudio-workbench.png" alt="Die KymoStudio-Oberfläche mit Zeitverlauf und XY-Diagramm" width="900">
</p>

## Was hier liegt

- **`content/`**: die Ansichten der Arbeitsfläche, also Diagrammfenster, Verbindungsdialoge, Seitenleisten und Werkzeugleiste
- **`imports/KymoUi`**, **`imports/Common`**: das QML-Modul `KymoUi` mit gemeinsamen Komponenten und Konstanten
- **`KymoUi.qmlproject`**: das Projekt zum Öffnen in Qt Design Studio
- **`CMakeLists.txt`**, **`src/`**: Build als eigenständige Qt-6-Anwendung (`KymoUiApp`)

## Teil von Kymotrace

| Projekt | Rolle |
|---|---|
| [KymoStudio](https://github.com/CodeName-666/kymostudio) | Desktop-App: empfangen, darstellen, analysieren, exportieren |
| [KymoCore](https://github.com/CodeName-666/kymocore) | portable C++11-Library für die Messwert-Übertragung |
| [KymoProbe](https://github.com/CodeName-666/kymoprobe) | Firmware und Beispiele für ESP32, Arduino und STM32 |
