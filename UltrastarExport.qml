import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0
// FileDialog
import Qt.labs.folderlistmodel 2.1
import QtQml 2.2
import MuseScore 1.0
import FileIO 1.0


// This MuseScore Plugin is licensed under the GPL Version 2
//Copyright Joseph Eoff, April 2015
MuseScore {
    menuPath: "Plugins." + "Ultrastar Export"
    version: "1.0"
    description: "Export to Ultrastar format"

    onRun: {
        // check MuseScore version
        if (!(mscoreMajorVersion == 2 && (mscoreMinorVersion > 0 || mscoreUpdateVersion>0))) {
            exportDialog.visible = false
            errorDialog.openErrorDialog(
                        qsTr("Minimum MuseScore Version 2.0.1 required for export"))
        }
        if (!(curScore)) {
            errorDialog.openErrorDialog(qsTr(
                                            "Select a score before exporting."))
            Qt.quit()
        } else {
            exportDialog.visible = true
            fillDefaultValues()
        }
    }

    Component.onDestruction: {
        settings.exportDirectory = exportDirectory.text
    }

    function fillDefaultValues() {
        instrumentPlayer2.enabled = false
        voicePlayer2.enabled = false
        loadInstrumentList(staffList)
        instrumentPlayer1.model = staffList
        instrumentPlayer2.model = staffList
        loadVoiceList(instrumentPlayer1.currentText, player1Voices)
        loadVoiceList(instrumentPlayer2.currentText, player2Voices)
        directorySelectDialog.folder = ((Qt.platform.os=="windows")? "file:///" : "file://") + exportDirectory.text;
    }

    function loadInstrumentList(instrumentList) {
        for (var i = 0; i < curScore.parts.length; i++) {
            var partname = curScore.parts[i].partName
            instrumentList.append({
                                      partname: partname
                                  })
        }
    }

    function loadVoiceList(instrumentName, voiceList) {
        for (var i = 0; i < curScore.parts.length; i++) {
            if (curScore.parts[i].partName === instrumentName) {
                voiceList.clear()
                for (var j = 0; j < curScore.parts[i].endTrack
                     - curScore.parts[i].startTrack; j++) {
                    voiceList.append({
                                         j: j
                                     })
                }
            }
        }
    }

    Settings {
        id: settings
        property alias exportDirectory: exportDirectory.text
    }

    ListModel {
        id: staffList
    }

    ListModel {
        id: player1Voices
    }

    ListModel {
        id: player2Voices
    }

    MessageDialog {
        id: errorDialog
        visible: false
        title: qsTr("Error")
        text: "Error"
        onAccepted: {
            exportDialog.visible = false
            Qt.quit()
        }
        function openErrorDialog(message) {
            text = message
            open()
        }
    }

    MessageDialog {
        id: warningDialog
        visible: false
        title: qsTr("Warning")
        text: "Warning"
        onAccepted: {
            Qt.quit()
        }
        function openWarningDialog(message) {
            text = message
            open()
        }
    }

    FileIO {
        id: songTextWriter
        onError: console.log(msg + "  Filename = " + songTextWriter.source)
    }

    FileDialog {
        id: directorySelectDialog
        title: qsTr("Please choose a directory")
        selectFolder: true
        visible: false
        onAccepted: {
            exportDirectory.text = directorySelectDialog.fileUrl.toString().replace("file://", "").replace(/^\/(.:\/)(.*)$/, "$1$2");
        }
        Component.onCompleted: visible = false
    }

    Dialog {
        id: exportDialog
        visible: true
        title: qsTr("Ultrastar Export")
        width: formbackground.width
        height: formbackground.height
        contentItem: Rectangle {
            id: formbackground
            width: exporterColumn.width + 20
            height: exporterColumn.height + 20
            color: "lightgrey"
            ColumnLayout {
                id: exporterColumn
                GridLayout {
                    id: grid
                    columns: 2
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 10
                    Label {
                        text: qsTr("Player 1")
                    }
                    Label {
                        text: " "
                    }
                    Label {
                        text: qsTr("Instrument")
                    }
                    ComboBox {
                        id: instrumentPlayer1
                        onCurrentIndexChanged: {
                            loadVoiceList(currentText, player1Voices)
                            voicePlayer1.model = player1Voices
                        }
                    }
                    Label {
                        text: qsTr("Voice")
                    }
                    ComboBox {
                        id: voicePlayer1
                    }
                    Label {
                        text: qsTr("Duet")
                    }
                    CheckBox {
                        id: duet
                        onClicked: {
                            instrumentPlayer2.enabled = checked
                            voicePlayer2.enabled = checked
                        }
                    }
                    Label {
                        text: qsTr("Player 2")
                    }
                    Label {
                        text: " "
                    }
                    Label {
                        text: qsTr("Instrument")
                    }
                    ComboBox {
                        id: instrumentPlayer2
                        onCurrentIndexChanged: {
                            loadVoiceList(currentText, player2Voices)
                            voicePlayer2.model = player2Voices
                        }
                    }
                    Label {
                        text: qsTr("Voice")
                    }
                    ComboBox {
                        id: voicePlayer2
                    }
                    Button {
                        id: selectDirectory
                        text: qsTr("Select export directory")
                        onClicked: {
                            directorySelectDialog.open()
                        }
                    }
                    Label {
                        id: exportDirectory
                        text: ""
                    }
                    Button {
                        id: exportButton
                        text: qsTr("Export")
                        onClicked: {
                            exportUltrastar()
                            //Qt.quit()
                        } // onClicked
                    }
                    Button {
                        id: cancelButton
                        text: qsTr("Cancel")
                        onClicked: {
                            exportDialog.visible = false
                            Qt.quit()
                        } // onClicked
                    }
                    Label {
                        id: exportStatus
                        text: ""
                    }
                }
            }
        }
    }

    function exportUltrastar() {
        exportStatus.text = qsTr("Exporting .txt File.")
        if (!exportTxtFile()) {
            return false
        }
        exportStatus.text = qsTr("Exporting .mp3 File.")
        exportAudioFile()
        exportStatus.text = ""
    }

    function exportTxtFile() {
        var crlf = "\r\n"
        if (!(curScore.title)) {
            warningDialog.openWarningDialog(qsTr("Score must have a title."))
            return false
        }
        var filename = exportDirectory.text + "//" + filenameFromScore(
                    ) + ".txt"
        console.log(filename)

        var txtContent = ""
        var title = curScore.title
        if (duet.checked) {
            title += " Duet"
        }
        title += " " + instrumentPlayer1.currentText
        if (duet.checked) {
            title += " + " + instrumentPlayer2.currentText
        }
        txtContent += "#TITLE:" + title + crlf

        if (!(curScore.composer)) {
            warningDialog.openWarningDialog(qsTr("Score must have a composer."))
            return false
        }
        txtContent += "#ARTIST:" + curScore.composer + crlf

        txtContent += "#MP3:" + filenameFromScore() + ".mp3" + crlf
        txtContent += "#VIDEO:" + crlf
        txtContent += "#VIDEOGAP:" + crlf
        txtContent += "#START:0" + crlf

        var bpm = getTempo_BPM()
        txtContent += "#BPM:" + bpm + crlf

        txtContent += "#GAP:0" + crlf

        if (duet.checked) {
            txtContent += "P1" + crlf
        }

        var cursor = getCursor(instrumentPlayer1.currentText,
                               voicePlayer1.currentText)

        cursor.rewind(0)
        txtContent += getSongText(cursor, bpm)

        if (duet.checked) {
            txtContent += "P2" + crlf
            cursor = getCursor(instrumentPlayer2.currentText,
                               voicePlayer2.currentText)
            txtContent += getSongText(cursor, bpm)
        }
        txtContent += "E" + crlf
        console.log(txtContent)
        songTextWriter.source = filename
        songTextWriter.write(txtContent)
        return true
    }

    function getSongText(cursor, bpm) {
        var crlf = "\r\n"
        var syllable = ""
        var songContent = ""
        var pitch_midi
        var timestamp_midi_ticks
        var duration_midi_ticks
        var gotfirstsyllable = false
        var needABreak = false
        var makeGolden = false
        var makeFreestyle = false
        var lineHeader = ":"

        while (cursor.segment) {

            if (needABreak && gotfirstsyllable) {
                timestamp_midi_ticks = calculateMidiTicksfromTicks(cursor.tick,
                                                                   bpm)
                songContent += "-" + timestamp_midi_ticks + crlf
                needABreak = false
            }

            needABreak = checkForMarkerInStaffText(cursor.segment, "/", true)
            makeGolden = checkForMarkerInStaffText(cursor.segment, "*", true)
            makeFreestyle = checkForMarkerInStaffText(cursor.segment, "F", true)

            if (cursor.element && cursor.element.type === Element.CHORD) {
                syllable = "-"
                if (cursor.element.lyrics.length > 0) {
                    syllable = cursor.element.lyrics[0].text
                    if (cursor.element.lyrics[0].syllabic === Lyrics.SINGLE
                            || cursor.element.lyrics[0].syllabic === Lyrics.END) {

                        syllable += " "
                    } else {
                        syllable += "-"
                    }
                }

                pitch_midi = cursor.element.notes[0].ppitch
                duration_midi_ticks = calculateMidiTicksfromTicks(
                            cursor.element.duration.ticks, bpm)
                timestamp_midi_ticks = calculateMidiTicksfromTicks(cursor.tick,
                                                                   bpm)

                if (!gotfirstsyllable) {
                    gotfirstsyllable = true
                }

                lineHeader = ":"
                if (makeGolden) {
                    lineHeader = "*"
                }
                if (makeFreestyle) {
                    lineHeader = "F"
                }

                songContent += lineHeader + " " + timestamp_midi_ticks + " "
                        + duration_midi_ticks + " " + pitch_midi + " " + syllable + crlf
            }
            cursor.next()
        }
        return songContent
    }

    function checkForMarkerInStaffText(segment, marker, hide) {
        for (var i = 0; i < segment.annotations.length; i++) {
            if (segment.annotations[i].type === Element.STAFF_TEXT) {
                if (segment.annotations[i].text === marker) {
                    if (hide && segment.annotations[i].visible){
                        curScore.startCmd()
                        segment.annotations[i].visible=false
                        curScore.endCmd(false)
                    }
                    return true
                }
            }
        }
        return false
    }

    function calculateMidiTicksfromTicks(ticks, bpm) {
        return Math.round((ticks / 490.96154) * 60 / bpm * 15)
    }

    function getCursor(instrument, voice) {
        for (var i = 0; i < curScore.parts.length; i++) {
            if (curScore.parts[i].partName === instrument) {
                var track = curScore.parts[i].startTrack + parseInt(voice, 10)
                var cursor = curScore.newCursor(true)
                cursor.rewind(1)
                cursor.track = track
                cursor.rewind(0)
                return cursor
            }
        }
    }

    function getTempo_BPM() {
        var cursor = curScore.newCursor()
        cursor.rewind(0)
        while (cursor.segment) {
            var an = cursor.segment.annotations
            for (var i = 0; i < cursor.segment.annotations.length; i++) {
                if (cursor.segment.annotations[i].type === Element.TEMPO_TEXT) {
                    console.log("Tempo: " + cursor.segment.annotations[i].tempo)
                    return cursor.segment.annotations[i].tempo * 60
                }
            }
            cursor.next()
        }
    }

    function exportAudioFile() {
        var filename = exportDirectory.text + "//" + filenameFromScore()
        writeScore(curScore, filename, "mp3")
    }

    function filenameFromScore() {
        var name = curScore.title
        if (duet.checked) {
            name += " duet"
        }
        name += " " + instrumentPlayer1.currentText
        if (duet.checked) {
            name += " " + instrumentPlayer2.currentText
        }
        name = name.replace(/ /g, "_")
        return name
    }
}
