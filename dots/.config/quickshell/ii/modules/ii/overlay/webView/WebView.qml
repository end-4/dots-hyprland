pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtWebView
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 400
    minimumHeight: 300

    property bool urlBarCollapsed: false
    property bool bookmarksVisible: false

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.urlBarCollapsed ? 0 : 48
                color: Appearance.colors.colLayer3
                radius: Appearance.rounding.small
                visible: Layout.preferredHeight > 0
                clip: true

                Behavior on Layout.preferredHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        onClicked: root.urlBarCollapsed = !root.urlBarCollapsed

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: "keyboard_arrow_up"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            rotation: root.urlBarCollapsed ? 180 : 0

                            Behavior on rotation {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Appearance.colors.colOutlineVariant
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        enabled: webView.canGoBack
                        onClicked: webView.goBack()

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: "arrow_back"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: parent.enabled ? Appearance.colors.colOnSurface : Appearance.colors.colOnLayer2Disabled
                        }
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        enabled: webView.canGoForward
                        onClicked: webView.goForward()

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: "arrow_forward"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: parent.enabled ? Appearance.colors.colOnSurface : Appearance.colors.colOnLayer2Disabled
                        }
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        onClicked: webView.loading ? webView.stop() : webView.reload()

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: webView.loading ? "close" : "refresh"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    TextField {
                        id: urlField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        text: webView.url
                        selectByMouse: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurface
                        leftPadding: 12
                        rightPadding: 12
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle {
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.verysmall

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }

                        onAccepted: {
                            let input = text.trim()
                            if (input.includes('.') && !input.includes(' ')) {
                                if (!input.startsWith('http://') && !input.startsWith('https://')) {
                                    input = 'https://' + input
                                }
                                webView.url = input
                            } else {
                                webView.url = 'https://www.google.com/search?q=' + encodeURIComponent(input)
                            }
                        }
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        onClicked: webView.url = Config?.options?.search?.engineBaseUrl.replace("search?q=", "") || "https://www.duckduckgo.com"

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: "home"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        StyledToolTip {
                            text: Translation.tr("Home")
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Appearance.colors.colOutlineVariant
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        toggled: root.bookmarksVisible
                        colBackground: Qt.rgba(0, 0, 0, 0)
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colBackgroundToggled: Appearance.colors.colPrimaryContainer
                        colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colLayer3Active
                        colRippleToggled: Appearance.colors.colPrimaryContainerActive
                        onClicked: root.bookmarksVisible = !root.bookmarksVisible

                        contentItem: MaterialSymbol {
                            anchors.fill: parent
                            text: "bookmark"
                            iconSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        StyledToolTip {
                            text: Translation.tr("Bookmarks")
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.verysmall
                clip: true

                WebView {
                    id: webView
                    anchors.fill: parent
                    url: Config?.options?.search?.engineBaseUrl.replace("search?q=", "") || "https://www.duckduckgo.com"

                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebView.LoadSucceededStatus) {
                            urlField.text = webView.url
                        }
                    }
                }

                RippleButton {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: 8
                    }
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer3
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    colRipple: Appearance.colors.colLayer3Active
                    visible: root.urlBarCollapsed
                    opacity: root.urlBarCollapsed ? 1 : 0
                    onClicked: root.urlBarCollapsed = false

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    contentItem: MaterialSymbol {
                        anchors.fill: parent
                        text: "keyboard_arrow_down"
                        iconSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    height: 3
                    width: parent.width * (webView.loadProgress / 100)
                    color: Appearance.colors.colPrimary
                    visible: webView.loading

                    Behavior on width {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
            }

            Rectangle {
                Layout.preferredWidth: root.bookmarksVisible ? 200 : 0
                Layout.fillHeight: true
                color: Appearance.colors.colLayer3
                radius: Appearance.rounding.small
                visible: Layout.preferredWidth > 0
                clip: true

                Behavior on Layout.preferredWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Bookmarks")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                        }

                        RippleButton {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            buttonRadius: Appearance.rounding.small
                            colBackground: Qt.rgba(0, 0, 0, 0)
                            colBackgroundHover: Appearance.colors.colLayer3Hover
                            colRipple: Appearance.colors.colLayer3Active
                            onClicked: {
                                let name = Translation.tr("New Bookmark")
                                let url = webView.url
                                let newBookmarks = (Config.options?.overlay?.webView?.bookmarks ?? []).slice()
                                newBookmarks.push({name: name, url: url})
                                Config.options.overlay.webView.bookmarks = newBookmarks
                            }

                            contentItem: MaterialSymbol {
                                anchors.fill: parent
                                text: "add"
                                iconSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            StyledToolTip {
                                text: Translation.tr("Add currrent page")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: bookmarksList
                            model: Config.options?.overlay?.webView?.bookmarks ?? []
                            spacing: 4

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: bookmarksList.width
                                height: 36
                                color: Qt.rgba(0, 0, 0, 0)
                                radius: Appearance.rounding.verysmall

                                property bool editing: false

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    RippleButton {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Qt.rgba(0, 0, 0, 0)
                                        colBackgroundHover: Appearance.colors.colLayer3Hover
                                        colRipple: Appearance.colors.colLayer3Active
                                        visible: !editing
                                        onClicked: webView.url = modelData.url
                                        altAction: () => { editing = true; editField.forceActiveFocus(); editField.selectAll(); }

                                        contentItem: StyledText {
                                            text: modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colOnSurface
                                            elide: Text.ElideRight
                                            leftPadding: 8
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        StyledToolTip {
                                            text: modelData.url
                                        }
                                    }

                                    TextField {
                                        id: editField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        visible: editing
                                        text: modelData.name
                                        selectByMouse: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSurface
                                        leftPadding: 8
                                        rightPadding: 8
                                        verticalAlignment: TextInput.AlignVCenter
                                        background: Rectangle {
                                            color: Appearance.colors.colLayer2
                                            radius: Appearance.rounding.verysmall
                                        }

                                        onAccepted: {
                                            let newBookmarks = (Config.options?.overlay?.webView?.bookmarks ?? []).slice()
                                            newBookmarks[index] = {name: text, url: modelData.url}
                                            Config.options.overlay.webView.bookmarks = newBookmarks
                                            editing = false
                                        }

                                        Keys.onEscapePressed: editing = false
                                    }

                                    RippleButton {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Qt.rgba(0, 0, 0, 0)
                                        colBackgroundHover: Appearance.colors.colErrorContainerHover
                                        colRipple: Appearance.colors.colErrorContainerActive
                                        onClicked: {
                                            let newBookmarks = (Config.options?.overlay?.webView?.bookmarks ?? []).slice()
                                            newBookmarks.splice(index, 1)
                                            Config.options.overlay.webView.bookmarks = newBookmarks
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.fill: parent
                                            text: "close"
                                            iconSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            color: Appearance.colors.colError
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
