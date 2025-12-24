import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Ajuste o caminho relativo para apontar para o seu Appearance.qml
// Exemplo: se este arquivo está na raiz "ii", use "modules/common"
import "modules/common" as Common

Scope {
    id: root

    property string popupType: "neutral"
    property string title: ""
    property string message: ""

    // --- CORES DO RELOADPOPUP (Fixas para Bad/Good) ---
    readonly property color bgBad: "#ffe99195"      // Vermelho Pastel
    readonly property color bgGood: "#ffD1E8D5"     // Verde Pastel
    readonly property color textBad: "#ff93000A"    // Texto Vermelho Escuro
    readonly property color textGood: "#ff0C1F13"   // Texto Verde Escuro

    // Acesso ao Singleton ou Componente Appearance
    // Se "Appearance" for um singleton global, pode usar direto.
    // Se não, instanciamos ou usamos o alias "Common.Appearance"
    // Aqui assumo que ele expõe "m3colors"
    property var themeColors: Common.Appearance.m3colors

    // --- FUNÇÕES AUXILIARES ---

    function transparentize(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    // --- LÓGICA DE CORES ---
    function getBgColor() {
        // Bad/Good: Cores Fixas (Pastel)
        if (root.popupType === "bad")  return root.bgBad
            if (root.popupType === "good") return root.bgGood

                // Submap: Cinza destacado do tema (Appearance)
                if (root.popupType === "submap")
                    return transparentize(root.themeColors.m3surfaceContainerHighest, 0.7)

                    // Neutral: Fundo padrão do tema (Appearance)
                    return transparentize(root.themeColors.m3surfaceContainer, 0.85)
    }

    function getTextColor() {
        // Bad/Good: Texto escuro fixo para contraste com pastel
        if (root.popupType === "bad")  return root.textBad
            if (root.popupType === "good") return root.textGood

                // Submap/Neutral: Texto dinâmico do tema (OnSurface)
                return root.themeColors.m3onSurface
    }

    function getBorderColor() {
        // Sem borda para Neutral/Submap ou se quiser manter limpo
        if (root.popupType === "neutral" || root.popupType === "submap") return "transparent"
            return "transparent"
    }

    // --- O VIGIA (Escuta o log) ---
    Process {
        id: watcher
        command: ["sh", "-c", "touch /tmp/qs_popup.log && stdbuf -oL tail -n 0 -f /tmp/qs_popup.log"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split("|");
                if (parts.length >= 3) {
                    root.popupType = parts[0].toLowerCase();
                    root.title = parts[1];
                    root.message = parts[2];

                    // Reset do Loader para reiniciar animações/timers
                    popupLoader.active = false;
                    popupLoader.active = true;
                }
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: false

        PanelWindow {
            id: popup
            exclusiveZone: 0

            // --- POSICIONAMENTO ---
            // Submap em baixo, Alertas em cima
            anchors.top: root.popupType !== "submap"
            anchors.bottom: root.popupType === "submap"

            margins.top: 10
            margins.bottom: root.popupType === "submap" ? 80 : 20

            implicitWidth: rect.width + shadow.radius * 2
            implicitHeight: rect.height + shadow.radius * 2

            WlrLayershell.namespace: "quickshell:popup"
            color: "transparent"

            Rectangle {
                id: rect
                anchors.centerIn: parent

                color: root.getBgColor()

                border.width: 0
                border.color: root.getBorderColor()

                // Tamanho adaptativo + Padding extra para o Submap
                implicitHeight: layout.implicitHeight + (root.popupType === "submap" ? 80 : 30)
                implicitWidth: layout.implicitWidth + (root.popupType === "submap" ? 80 : 30)

                radius: 12

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: popupLoader.active = false
                }

                ColumnLayout {
                    id: layout
                    spacing: root.popupType === "submap" ? 2 : 5
                    anchors.centerIn: parent

                    Text {
                        // TÍTULO
                        renderType: Text.NativeRendering
                        font.family: root.popupType === "submap" ? "Iosevka Light" : "Iosevka Heavy"
                        font.pointSize: root.popupType === "submap" ? 19 : 14
                        font.bold: root.popupType !== "submap"

                        text: root.title
                        color: root.getTextColor()

                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 400
                        elide: Text.ElideRight
                    }

                    Text {
                        // MENSAGEM
                        renderType: Text.NativeRendering
                        font.family: root.popupType === "submap" ? "Iosevka Heavy" : "Iosevka"
                        font.pointSize: root.popupType === "submap" ? 21 : 12
                        font.bold: root.popupType === "submap"

                        text: root.message
                        color: root.getTextColor()

                        textFormat: Text.RichText
                        horizontalAlignment: Text.AlignHCenter

                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 400
                        wrapMode: Text.WordWrap

                        visible: text !== ""
                    }
                }

                // --- TIMER ---
                Timer {
                    // Submap: 1 segundo
                    // Bad: 5 segundos
                    // Outros: 3 segundos
                    interval: root.popupType === "submap" ? 1200 : (root.popupType === "bad" ? 5000 : 3000)
                    running: popupLoader.active
                    onTriggered: popupLoader.active = false
                }
            }

            DropShadow {
                id: shadow
                anchors.fill: rect
                horizontalOffset: 0
                verticalOffset: 4
                radius: 8
                samples: 16
                color: Qt.rgba(0, 0, 0, 0.4)
                source: rect
                visible: root.popupType !== "neutral"
            }
        }
    }
}
