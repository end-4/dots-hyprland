import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Scope {
	id: root
	property bool failed;
	property string errorString;

	// Connect to the Quickshell global to listen for the reload signals.
	Connections {
		target: Quickshell

		function onReloadCompleted() {
			root.failed = false;
			popupLoader.loading = true;
		}

		function onReloadFailed(error: string) {
			// Close any existing popup before making a new one.
			popupLoader.active = false;

			root.failed = true;
			root.errorString = error;
			popupLoader.loading = true;
		}
	}

	// Keep the popup in a loader because it isn't needed most of the timeand will take up
	// memory that could be used for something else.
	LazyLoader {
		id: popupLoader

		PanelWindow {
			id: popup

			anchors.top: true
			margins.top: 0

			width: rect.width + shadow.radius * 2
			height: rect.height + shadow.radius * 2

			// color blending is a bit odd as detailed in the type reference.
			color: "transparent"

			Rectangle {
				id: rect
				anchors.centerIn: parent
				color: failed ?  "#ffe99195" : "#ffD1E8D5"

				implicitHeight: layout.implicitHeight + 30
				implicitWidth: layout.implicitWidth + 30
				radius: 12

				// Fills the whole area of the rectangle, making any clicks go to it,
				// which dismiss the popup.
				MouseArea {
					id: mouseArea
					anchors.fill: parent
					onClicked: popupLoader.active = false

					// makes the mouse area track mouse hovering, so the hide animation
					// can be paused when hovering.
					hoverEnabled: true
				}

				ColumnLayout {
					id: layout
					anchors {
						top: parent.top
						topMargin: 10
						horizontalCenter: parent.horizontalCenter
					}

					Text {
						renderType: Text.NativeRendering
						font.family: "Rubik"
						font.pointSize: 14
						// color: Appearance.colors.colOnBackground
						text: root.failed ? "Reload failed" : "Reload completed"
						color: failed ? "#ff93000A" : "#ff0C1F13"
					}

					Text {
						renderType: Text.NativeRendering
						font.family: "JetBrains Mono NF"
						font.pointSize: 11
						text: root.errorString
						color: failed ? "#ff93000A" : "#ff0C1F13"
						// When visible is false, it also takes up no space.
						visible: root.errorString != ""
					}
				}

				// A progress bar on the bottom of the screen, showing how long until the
				// popup is removed.
				Rectangle {
					id: bar
					color: failed ? "#ff93000A" : "#ff0C1F13"
					anchors.bottom: parent.bottom
					anchors.left: parent.left
					anchors.margins: 10
					height: 5
					radius: 9999

					PropertyAnimation {
						id: anim
						target: bar
						property: "width"
						from: rect.width
						to: 0
						duration: failed ? 10000 : 800
						onFinished: popupLoader.active = false

						// Pause the animation when the mouse is hovering over the popup,
						// so it stays onscreen while reading. This updates reactively
						// when the mouse moves on and off the popup.
						paused: mouseArea.containsMouse
					}
				}

				// We could set `running: true` inside the animation, but the width of the
				// rectangle might not be calculated yet, due to the layout.
				// In the `Component.onCompleted` event handler, all of the component's
				// properties and children have been initialized.
				Component.onCompleted: anim.start()
			}

			DropShadow {
				id: shadow
                anchors.fill: rect
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6
                samples: radius * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: "#44000000"
                source: rect
            }
		}
	}
}
