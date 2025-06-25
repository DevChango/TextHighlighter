import SwiftUI
import TextHighlighter

// MARK: – Vista raíz que carga los datos / Root view that loads data
struct HighlightRootView: View {
    @StateObject private var highlightManager = HighlightManager()
    @StateObject private var controller = UnderlineTextViewController()
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                ContentView(controller: controller, highlightManager: highlightManager)
            } else {
                ProgressView("Cargando resaltados... / Loading highlights...")
            }
        }
        .task {
            await highlightManager.loadHighlights()
            isReady = true
        }
    }
}

// MARK: – Vista principal con versos y subrayado / Main view with verses and highlighting
struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    // MARK: – Controladores / Controllers
    @ObservedObject var controller: UnderlineTextViewController
    @ObservedObject var highlightManager: HighlightManager

    // MARK: – Estado de UI / UI State
    @State private var showingError  = false
    @State private var errorMessage  = ""

    // MARK: – Versos demo / Demo verses
    private let verses: [[String: Any]] = [
        ["id": 1, "uuid": "caperu-1", "texto": "Érase una vez una niña pequeña,"],
        ["id": 2, "uuid": "caperu-2", "texto": "que llevaba una capa de un rojo brillante."],
        ["id": 3, "uuid": "caperu-3", "texto": "Cruzó el bosque alegre y contenta,"],
        ["id": 4, "uuid": "caperu-4", "texto": "con una canasta para su abuelita enferma."],
        ["id": 5, "uuid": "caperu-5", "texto": "Un lobo la vio, astuto y hambriento,"],
        ["id": 6, "uuid": "caperu-6", "texto": "y le habló con voz dulce y amable."],
        ["id": 7, "uuid": "caperu-7", "texto": "“¿A dónde vas con tanto apuro?”, preguntó el lobo."],
        ["id": 8, "uuid": "caperu-8", "texto": "“A casa de mi abuela, señor lobo seguro.”"]
    ]

    var body: some View {
        VStack {
            colorPickerSection

            UnderlineTextViewWrapper(
                verses             : verses,
                lineSpacing        : 20,
                horizontalSpacing  : 15,
                underlineColor     : .black,
                underlineColorDark : .white,
                underlineYOffset   : 2,
                fontName           : "Helvetica Neue",
                fontSize           : 18,
                verseTextColor     : .black,
                verseTextColorDark : .white,
                idTextColor        : .gray,
                idTextColorDark    : .white,
                onVerseClick       : { print("Clicked verse: \($0)") },
                controller         : controller,
                highlightManager   : highlightManager
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            controlButtons
        }
        .background(colorScheme == .dark ? .black : .white)
        .onAppear {
            controller.syncWithManager(highlightManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { clearError() }
        } message: {
            Text(errorMessage)
        }
        .onReceive(highlightManager.$lastError) {
            if let e = $0 { showError(e.localizedDescription) }
        }
        .onReceive(controller.$lastError) {
            if let e = $0 { showError(e.localizedDescription) }
        }
        .onChange(of: controller.textView) { _, newView in
            if newView != nil {
                controller.applyHighlights(from: highlightManager)
            }
        }
        .onChange(of: colorScheme) {
            controller.applyHighlights(from: highlightManager)
        }
    }

    // MARK: – Selector de color / Highlight color picker
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Highlight Color / Color de subrayado")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .center)

            Picker("Color", selection: $controller.highlightColorScheme) {
                ForEach(HighlightColorScheme.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    // MARK: – Botones de control / Control buttons
    private var controlButtons: some View {
        HStack(spacing: 12) {
            
            Button("Mark Selected / Marcar") {
                controller.convertUnderlinesToHighlights(manager: highlightManager)
                checkForErrors()
            }
            .buttonStyle(.borderedProminent)
            .disabled(controller.textView?.selectedVerses.isEmpty ?? true)

            Button("Unmark Selected / Desmarcar") {
                controller.removeHighlightsFromSelected(manager: highlightManager)
                checkForErrors()
            }
            .buttonStyle(.bordered)

            Button("Clear All / Limpiar todo") {
                clearAll()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(highlightManager.statistics.totalHighlights == 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: – Utilidades / Helpers
    
    private func checkForErrors() {
        if let e = controller.lastError ?? highlightManager.lastError {
            showError(e.localizedDescription)
        }
    }

    private func showError(_ msg: String) {
        errorMessage = msg
        showingError = true
    }

    private func clearError() {
        controller.lastError = nil
        errorMessage = ""
    }

    private func clearAll() {
        highlightManager.clearAll()
        controller.applyHighlights(from: highlightManager)
    }
}
