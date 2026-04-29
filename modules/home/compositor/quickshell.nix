{
  pkgs,
  inputs,
  theme,
  # system,
  ...
}: {
  # Install the Quickshell package directly from the flake input
  home.packages = [
    inputs.quickshell.packages.${pkgs.system}.default
  ];

  # Write the QML file that Quickshell reads on startup
  xdg.configFile."quickshell/shell.qml".text = ''
    import QtQuick
    import Quickshell

    ShellRoot {
        PanelWindow {
            id: topBar
            anchors {
                top: true
                left: true
                right: true
            }

            // The floating "Air" effect
            margins {
                top: 8
                left: 16
                right: 16
            }

            implicitHeight: 40
            color: "transparent"

            // The actual visual bar
            Rectangle {
                anchors.fill: parent
                color: "${theme.bg}"
                radius: 16
                border.color: "${theme.surface}"
                border.width: 2

                // Left side: Workspaces (Placeholder logic)
                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16
                    }
                    spacing: 8

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            // Highlight the first one as "active"
                            color: index === 0 ? "${theme.accent}" : "${theme.surface}"

                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                // Center: Clock
                Text {
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: "${theme.active}"

                    // A simple timer to update the clock
                    text: Qt.formatDateTime(new Date(), "hh:mm ap")
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm ap")
                    }
                }

                // Right side: System Tray / Status
                Row {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 16
                    }
                    spacing: 16

                    Text {
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "${theme.success}"
                        text: "󰕾 100%"
                    }
                    Text {
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "${theme.warning}"
                        text: "󰖩"
                    }
                }
            }
        }
    }
  '';
}
