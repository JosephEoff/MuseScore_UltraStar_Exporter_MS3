import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
// FileDialog
import Qt.labs.folderlistmodel 2.1
import QtQml 2.2
import MuseScore 3.0
import FileIO 3.0


// This MuseScore Plugin is licensed under the GPL Version 2
//Copyright Joseph Eoff, April 2015
MuseScore {
    menuPath: "View." +qsTr("UltraStar Annotator")
    description: qsTr("Annotate Score for UltraStar Export")
    pluginType: "dock"
    dockArea: "left"
    onRun: {

    }

    Rectangle {
        color: "lightgrey"
        anchors.fill: parent
        width: grid.width + 20
        height: grid.height + 20
        ColumnLayout {
            id: grid
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10

            Button {
                id: lineBreak
                text: qsTr("Make Line Break")
                onClicked: {
                    annotateItem("/")
                }
            }
            Button {
                id: goldenNote
                text: qsTr("Make Golden Note")
                onClicked: {
                    annotateItem("*")
                }
            }
            Button {
                id: freestyleNote
                text: qsTr("Make Freestyle Note")
                onClicked: {
                    annotateItem("F")
                }
            }
        }
    }
    function annotateItem(annotation) {
        var cursor = curScore.newCursor(true)
        cursor.rewind(0)
        cursor.rewind(1)
        cursor.next()
        var segment = getSelectedItem(cursor)
        console.log(segment)
        if (segment) {
            for (var i = 0; i < segment.annotations.length; i++) {
                var ann = segment.annotations[i].text
                if (ann === "/" || ann === "*" || ann === "F") {
                    //already marked
                    return
                }
            }
            var marker = newElement(Element.STAFF_TEXT)
            marker.text = annotation
            marker.visible = false
            curScore.startCmd()
            cursor.add(marker)
            curScore.endCmd(false)
        }
    }

    function getSelectedItem(cursor) {
        cursor.filter = -1
        for (var i = 0; i < curScore.ntracks; i++) {
            cursor.track = i
            cursor.rewind(0)
            cursor.rewind(1)
            while (cursor.element) {
                for (var i = 0; i < cursor.element.notes.length; i++) {
                    if (cursor.element.notes[i].selected) {
                        console.log("element.notes")
                        return cursor.segment
                    }
                }
                cursor.next()
            }
        }
        return null
    }
}
