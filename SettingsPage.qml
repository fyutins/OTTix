import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Label {
            text: qsTr("Settings")
            color: "#e0e0e0"
            font.pixelSize: 22
            font.bold: true
        }

        GroupBox {
            title: qsTr("Playback")
            Layout.fillWidth: true
            label: Label {
                text: parent.title
                color: "#e0e0e0"
                font.bold: true
            }

            ColumnLayout {
                width: parent.width
                spacing: 12

                RowLayout {
                    Label {
                        text: qsTr("Volume")
                        color: "#e0e0e0"
                    }

                    Slider {
                        id: defaultVolumeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: 100
                    }

                    Label {
                        text: defaultVolumeSlider.value.toFixed(0)
                        color: "#e0e0e0"
                        Layout.preferredWidth: 30
                    }
                }

                RowLayout {
                    Label {
                        text: qsTr("Hardware Decoding")
                        color: "#e0e0e0"
                    }

                    ComboBox {
                        id: hwdecCombo
                        model: ["auto", "no", "yes", "nvdec", "cuda", "vaapi", "d3d11va"]
                        currentIndex: 0
                    }
                }

                RowLayout {
                    Label {
                        text: qsTr("Cache (MB)")
                        color: "#e0e0e0"
                    }

                    SpinBox {
                        id: cacheSpinBox
                        from: 0
                        to: 1024
                        value: 150
                    }
                }
            }
        }

        GroupBox {
            title: qsTr("Database")
            Layout.fillWidth: true
            label: Label {
                text: parent.title
                color: "#e0e0e0"
                font.bold: true
            }

            ColumnLayout {
                width: parent.width
                spacing: 12

                Button {
                    text: qsTr("Clear Cache")
                    onClicked: {
                        DatabaseManager.clearCache(0)
                    }
                }

                Label {
                    text: qsTr("Database location: ") + Qt.application.applicationDirPath + "/iptv_player.db"
                    color: "#808080"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: qsTr("About")
            Layout.fillWidth: true
            label: Label {
                text: parent.title
                color: "#e0e0e0"
                font.bold: true
            }

            ColumnLayout {
                width: parent.width
                spacing: 8

                Label {
                    text: qsTr("IPTV Player v0.1")
                    color: "#e0e0e0"
                }

                Label {
                    text: qsTr("Supports M3U playlists and XTREAM API")
                    color: "#a0a0a0"
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
