
# ✨ TextHighlighter ✍️  
**Developer: DevChango 🐵**

---

## 📝 Description / Descripción

EN: **TextHighlighter** is a Swift framework for macOS that enables interactive underlining and persistent highlighting of verses or text blocks using customized colors.

ES: **TextHighlighter** es un framework en Swift para macOS que permite subrayar interactivamente y resaltar de forma persistente versos o bloques de texto usando colores personalizados.

---

## 💡 Key Features / Características Principales

- ✅ EN: Interactive dotted underlines with custom colors.  
     ES: Subrayado punteado interactivo con colores personalizados.

- 💾 EN: Persistent highlights stored locally using `UserDefaults`.  
     ES: Destacados persistentes almacenados localmente usando `UserDefaults`.

- 🌗 EN: Dark/Light mode support.  
     ES: Soporte para modo oscuro y claro.

- 🎨 EN: Highlight color picker and real-time visual updates.  
     ES: Selector de color de destacado y actualizaciones visuales en tiempo real.

- 🧠 EN: Sync between view and highlight manager.  
     ES: Sincronización entre la vista y el gestor de destacados.

- 📐 EN: SwiftUI + AppKit hybrid architecture.  
     ES: Arquitectura híbrida SwiftUI + AppKit.

---

## 📦 Project Structure / Estructura del Proyecto

```
TextHighlighter/
├── Examples/
│   └── DemoApp/
│       ├── Assets.xcassets/
│       │   ├── AccentColor.colorset/
│       │   ├── AppIcon.appiconset/
│       │   └── Contents.json
│       ├── ContentView.swift
│       └── DemoAppApp.swift
│
├── Sources/
│   └── TextHighlighter/
│       ├── Core/
│       │   ├── HighlightData.swift
│       │   ├── HighlightManager.swift
│       │   └── HighlightPersistenceManager.swift
│       └── UI/
│           ├── DotUnderlineLayoutManager.swift
│           ├── UnderlineTextController.swift
│           ├── UnderlineTextView.swift
│           └── UnderlineTextViewWrapper.swift
│
├── Tests/
│   └── TextHighlighterTests/
│       └── TextHighlighterTests.swift
│
├── Package.swift
├── README.md
└── LICENSE
```

---

## 📂 Persistence / Persistencia

EN: Highlights are stored using `UserDefaults` with the key:

```swift
"TextHighlighter.SavedHighlights"
```

ES: Los destacados se guardan usando `UserDefaults` con la clave indicada arriba, lo que permite recuperar automáticamente los datos entre sesiones.

---

## 📥 Integration Guide / Guía de Integración

### ✅ EN: Using as Swift Package

1. Open your Xcode project.
2. Go to `File > Add Packages...`
3. Paste the repository URL:

```text
https://github.com/DevChango/TextHighlighter.git
```

4. Select the version (main branch or latest release).
5. Import the framework where needed:

```swift
import TextHighlighter
```

### ✅ ES: Usar como paquete Swift

1. Abre tu proyecto en Xcode.
2. Ve a `Archivo > Agregar Paquetes...`
3. Pega la URL del repositorio:

```text
https://github.com/DevChango/TextHighlighter.git
```

4. Selecciona la versión (rama `main` o último release).
5. Importa el framework donde lo necesites:

```swift
import TextHighlighter
```

---

## 🚀 Demo

EN: You can find a working demo inside the `Examples/DemoApp` folder.  
ES: Puedes encontrar una demo funcional dentro de la carpeta `Examples/DemoApp`.

---

## 🔧 Requirements / Requisitos

- macOS 13+
- Xcode 15+
- Swift 5.9+

---

## ⚠️ Notes & Limitations / Notas y Limitaciones

EN:
- This is an experimental project by a Swift beginner.
- Logic and implementation details may change over time.
- Some parts may not follow best practices yet.

ES:
- Este es un proyecto experimental creado por un principiante en Swift.
- La lógica puede cambiar en futuras versiones.
- Algunas partes podrían no seguir aún buenas prácticas.

---

## 📌 Future Improvements / Mejoras Futuras

EN:
- [ ] Sync highlights to disk as `.json`.
- [ ] Add custom tags and note editors.
- [ ] Performance optimization for long texts.
- [ ] Preview or export selected highlights.

ES:
- [ ] Sincronizar los destacados con disco como archivo .json.
- [ ] Agregar etiquetas personalizadas y editor de notas.
- [ ] Optimización de rendimiento para textos largos.
- [ ] Vista previa o exportación de destacados seleccionados.

---

## 📸 Screenshots / Capturas

**EN: Here's how `TextHighlighter` looks and works.**  
**ES: Así se ve y funciona `TextHighlighter`.**

---

#### ✍️ 1. Highlighting Verses / Marcado de Versos

> EN: Click on any verse to underline and mark it with a custom color.  
> ES: Haz clic en un verso para subrayarlo y marcarlo con un color personalizado.

![Highlighting Verses](https://github.com/user-attachments/assets/24879cde-47da-4775-9768-5e165a0f5947)

---

#### 🌗 2. Dark/Light Mode Support / Modo Claro y Oscuro

> EN: The UI adapts automatically to system appearance.  
> ES: La interfaz se adapta automáticamente al modo del sistema.

![Dark Mode](https://github.com/user-attachments/assets/5d4d160a-2477-4298-930e-f5a538dfaa1c)

---

#### 📐 3. Resizing Support / Soporte de Redimensionamiento

> EN: Layout scales gracefully when resizing the window.  
> ES: El diseño se adapta correctamente al redimensionar la ventana.

![Resizing Demo](https://github.com/user-attachments/assets/906acc42-2418-46ca-9384-d3d46e56d58c)

---

## 📫 Contact / Contacto

**DevChango** – [GitHub](https://github.com/DevChango)  
EN: Feel free to open issues or pull requests.  
ES: ¡Siéntete libre de abrir issues o pull requests!

---

## 📄 License / Licencia

MIT License

---

Created with 💖 and 💻 by **DevChango**
