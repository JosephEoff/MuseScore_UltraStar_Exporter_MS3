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
    version: "1.1"
    description: "Export to Ultrastar format"

    onRun: {
        exportDialog.visible = false
        // check MuseScore version
        if (!(mscoreMajorVersion == 2 && (mscoreMinorVersion > 0 || mscoreUpdateVersion > 0))) {
            errorDialog.openErrorDialog(
                        qsTr("Minimum MuseScore Version %1 required for export").arg("2.0.1"))
        }
        if (!(curScore)) {
            errorDialog.openErrorDialog(qsTranslate("QMessageBox",
					"No score open.\nThis plugin requires an open score to run.\n"))
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
        loadVoiceList(instrumentPlayer1.currentText, player1Voices, voicePlayer1);
        loadVoiceList(instrumentPlayer2.currentText, player2Voices, voicePlayer2);
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

    function loadVoiceList(instrumentName, voiceList, voiceCombo) {
        for (var i = 0; i < curScore.parts.length; i++) {
            if (curScore.parts[i].partName === instrumentName) {
                voiceList.clear();
                for (var j = 0; j < (curScore.parts[i].endTrack - curScore.parts[i].startTrack); j++) {
                    voiceList.append({ j: (j + 1) });
                }
            }
        }
        voiceCombo.model = voiceList; //applying the new list sets currentIndex to 0, but doesn't update the shown comboboxText
        voiceCombo.currentIndex = 1;  //force an indexChange to force the combo to update its label
        voiceCombo.currentIndex = 0;  //force indexChange back to default, now the label will be updated
    }

    Settings {
        id: settings
        property alias exportDirectory: exportDirectory.text
        property alias highAccuracyMode: highAccuracyMode.checked
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
            exportDirectory.text = this.folder.toString().replace("file://", "").replace(/^\/(.:\/)(.*)$/, "$1$2");
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
                    anchors.fill: parent
                    anchors.margins: 10
                    Label {
                        text: qsTr("Player 1")
                        Layout.columnSpan: 2
                    }
                    Label {
                        text: qsTranslate("Ms::MuseScore", "Instrument")
                    }
                    ComboBox {
                        id: instrumentPlayer1
                        onCurrentIndexChanged: {
                            loadVoiceList(currentText, player1Voices, voicePlayer1);
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
                        Layout.columnSpan: 2
                    }
                    Label {
                        text: qsTranslate("Ms::MuseScore", "Instrument")
                    }
                    ComboBox {
                        id: instrumentPlayer2
                        onCurrentIndexChanged: {
                            loadVoiceList(currentText, player2Voices, voicePlayer2);
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
                    Label {
                        text: qsTr("High Accuracy Mode")
                    }
                    CheckBox {
                        id: highAccuracyMode
                    }
                    Button {
                        id: exportButton
                        text: qsTranslate("PrefsDialogBase", "Export")
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

        txtContent += "#BPM:" + getTempo_BPM() + crlf;

        txtContent += "#GAP:0" + crlf

        if (duet.checked) {
            txtContent += "P1" + crlf
        }

        var cursor = getCursor(instrumentPlayer1.currentText,
                               voicePlayer1.currentIndex)

        cursor.rewind(0)
        txtContent += getSongText(cursor);

        if (duet.checked) {
            txtContent += "P2" + crlf
            cursor = getCursor(instrumentPlayer2.currentText,
                               voicePlayer2.currentIndex)
            txtContent += getSongText(cursor);
        }
        txtContent += "E" + crlf
        console.log(txtContent)
        songTextWriter.source = filename
        songTextWriter.write(txtContent)
        return true
    }

    function getSongText(cursor) {
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
        var changedTempo = undefined;

        while (cursor.segment) {

            if (needABreak && gotfirstsyllable) {
                timestamp_midi_ticks = calculateMidiTicksfromTicks(cursor.tick);
                songContent += "-" + timestamp_midi_ticks + crlf
                needABreak = false
            }

            needABreak = checkForMarkerInStaffText(cursor.segment, "/", true)
            makeGolden = checkForMarkerInStaffText(cursor.segment, "*", true)
            makeFreestyle = checkForMarkerInStaffText(cursor.segment, "F", true)
            changedTempo = getNewBPMFromSegment(cursor.segment);

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
                duration_midi_ticks = calculateMidiTicksfromTicks(cursor.element.duration.ticks);
                timestamp_midi_ticks = calculateMidiTicksfromTicks(cursor.tick);

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

                if (changedTempo) {
                    songContent += "B " + timestamp_midi_ticks + " " + changedTempo + crlf;
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

    function getNewBPMFromSegment(segment) {
        for (var i = 0; i < segment.annotations.length; i++) {
            if (segment.annotations[i].type === Element.TEMPO_TEXT) {
                return calculateBPMfromTempo(segment.annotations[i].tempo);
            }
        }
        return undefined; //invalid - no tempo text found
    }

    function calculateMidiTicksfromTicks(ticks) {
		if (highAccuracyMode.checked)
		{
			// /5 because values at https://musescore.org/plugin-development/tick-length-values are all multiples of 5
			// and we want to have maximal precision whilst keeping numeric values as small as possible
			return (ticks / 5);
		}
		else
		{//normal accuracy mode
			//division is a global variable holding the tickLength of a crochet(1/4th note)
			return Math.round(ticks / division * 4); // *4 scales from crotchet-reference to whole measure
		}
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

    function calculateBPMfromTempo(tempo) {
        //tempo is a % compared to 60bpm (tempo == 1 -> bpm == 60)
        if (highAccuracyMode.checked)
		{
			//division is a global variable holding the tickLength of a crochet(1/4th note)
			//scaling tempo with tickLength allows very precise approximation of real note lengths in export
			// *15 (*60 for real BPM, then /4 to scale to crotchet because 4* crotchet == 60 and division is in crotchet)
			// /5 because values at https://musescore.org/plugin-development/tick-length-values are all multiples of 5
			// and we want to have maximal precision whilst keeping numeric values as small as possible
			// so in total we do (*15/5) == * 3
			return (tempo * division * 3);
		}
		else
		{//normal accuracy mode
			return (tempo * 60);
		}
    }

    function getTempo_BPM() {
        var bpm = 2; //default BPM = 120bpm = 200% = 2 according to https://musescore.org/en/node/16635
        //song BPM is expected at the first chord/rest of the score, so let's find it
        var segment = curScore.firstSegment(Segment.ChordRest);
        //filter on firstSegment doesn't seem to work, so stepping here manually
        while ((segment != null) && (segment.segmentType !== Segment.ChordRest)) {
            segment = segment.nextInMeasure;
        }
        if (segment != null) { //found first chord/rest of the score
            //let's see if there's a TEMPO_TEXT assigned to it
            for (var i = segment.annotations.length; i-- > 0; ) {
                if (segment.annotations[i].type === Element.TEMPO_TEXT) {
                    bpm = segment.annotations[i].tempo;
                    break;
                }
            }
        }
        console.log('Tempo: ' + bpm + ' | Real BPM: ' + (bpm * 60));
        bpm = calculateBPMfromTempo(bpm);
        console.log('\tTickBPM: ' + bpm);
        return bpm;
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
