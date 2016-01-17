# MuseScore_UltraStar_Exporter
This plugin exports the lyrics and the music of a score into the UltraStar format.
[UltraStar](http://ultrastardx.sourceforge.net/) is free program similar to [SingStar](https://www.singstar.com/en_US/about.html). Other programs use the UltraStar format as well, such as the open source [Performous](http://performous.org/).

These programs generally attempt to match lyrics and tone notations to an existing mp3 recording of a song. The basic idea of these kinds of games looks like it would work well for practicing, but the existing mp3 files are usually the original song from the original artist. While this works well when singing just for fun, it makes it difficult for the singer to really learn from his performance.

This plugin requires MuseScore 2.0.1 or above.

Features:
* Export of the musical score to an mp3 file.
* Export of the required .txt file for UltraStar.
* Export for Duet is implemented but mostly untested.
* Selection of the Instrument and Voice to be used for the lyrics for player 1 and player 2.
* Annotator to mark line breaks and golden or freestyle notes.
* Supports tempo changes (tested with Performous)

Usage:

1. Enter the score of the song - do NOT use repeats, as MuseScore doesn't unroll them when making the mp3.
2. Mark line breaks by selecting a note and pressing `CTRL+T` for a Staff Text. Enter a `/` to indicate a line break.
3. Mark a golden note by selecting a note and pressing `CTRL+T` for a Staff Text. Enter a `*` to indicate a golden note.
4. Mark a freestyle note by selecting a note and pressing `CTRL+T` for a Staff Text. Enter a `F` to indicate a freestyle note.
5. The export function sets the UltraStar notations to invisible - to see them again, select "Show Invisible" from the "View" menu. The notations are hidden so as not to clutter up the printout. When "Show invisible" is active, you can edit the notations as needed.

Alternatively, use the Annotator (Menu View/UltraStar Annotator.) Select a note with Shift and Left mouse button - draw a box around the note. Click the appropriate button to add the annotation.

Make sure to select the correct instrument when exporting.

The plugin has been tested under Windows7 against release 2.0.2 and Linux.
