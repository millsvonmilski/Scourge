package net.rezmason.scourge.textview;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.text.Sigil;
import net.rezmason.scourge.textview.text.Span;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.Document;
import net.rezmason.utils.FlatFont;
import net.rezmason.utils.Utf8Utils.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIMediator {

    inline static var LINE_TOKEN:String = '¬¬¬';

    public var isDirty(default, null):Bool;

    var numRows:Int;
    var numCols:Int;

    var document:Document;

    var pageLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var mainText:String;
    var styleEnd:String;

    public function new():Void {
        document = new Document();
        numRows = 0;
        numCols = 0;
        mainText = '';
        styleEnd = '§{}';
        isDirty = false;
    }

    public function adjustLayout(numRows:Int, numCols:Int):Void {
        this.numRows = numRows;
        this.numCols = numCols;
        this.isDirty = true;
    }

    public function stylePage(startIndex:Int, glyphs:Array<Glyph>, caretGlyph:Glyph, font:FlatFont):Int {
        var id:Int = 0;
        var pageSegment:Array<String> = getPageSegment(startIndex);
        var spanIndex:Int = getLineStyleIndex(startIndex);

        resetSpans();
        styleCaret(caretGlyph, font);

        var currentSpan:Span = document.getSpanByIndex(spanIndex);

        var caretGlyphID:Int = -1;

        for (line in pageSegment) {
            var index:Int = 0;

            for (index in 0...length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                switch (charCode) {
                    case Sigil.STYLE_CODE:
                        spanIndex++;
                        currentSpan = document.getSpanByIndex(spanIndex);
                    case Sigil.CARET_CODE:
                        caretGlyphID = id;
                    case _:
                        var glyph:Glyph = glyphs[id];
                        glyph.set_char(charCode, font);
                        currentSpan.addGlyph(glyph);
                        glyph.set_z(0);
                        id++;
                }
            }
        }

        updateSpans(0);

        return caretGlyphID;
    }

    public function updateDirtyText(force:Bool = false, bodyPaint:Int):Void {
        isDirty = isDirty || force;

        if (isDirty) {

            isDirty = false;

            if (numRows * numCols > 0) {

                // Simplify the combined text and wrap it to new lines as we construct the page

                document.setText(swapTabsWithSpaces(combineText()), bodyPaint);
                page = document.getStyledText().split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

                // Add blank lines to the end, to reach the minimum page length (numRows)

                var blankParagraph:String = rpad('', ' ', numCols);
                pageLength = page.length;
                while (page.length < numRows) page.push(blankParagraph);

                // Count the sigils in each line, for style lookup

                var lineStyleIndex:Int = 0;
                lineStyleIndices = [lineStyleIndex];
                for (line in page) {
                    lineStyleIndex += line.split(Sigil.STYLE).length - 1;
                    lineStyleIndices.push(lineStyleIndex);
                }
            }
        }
    }

    public function resetSpans():Void document.removeAllGlyphs();

    public function updateSpans(delta:Float):Void document.updateSpans(delta);

    public function setText(text:String):Void {
        mainText = text;
        isDirty = true;
    }

    public function styleCaret(caretGlyph:Glyph, font:FlatFont):Void {}

    function combineText():String return mainText;

    inline function padLine(line:String):String {
        var count:Int = 0;

        function check(char:Int):Void {
           if (char == Sigil.STYLE_CODE || char == Sigil.CARET_CODE) count++;
        }

        Utf8.iter(line, check);

        // Pads a string until its length, ignoring sigils, is numCols
        return rpad(line, ' ', numCols + count);
    }

    inline function wrapLines(s:String):String {

        // Splits a line into an array of lines whose length, ignoring sigils, is numCols

        var wrappedLines:Array<String> = [];
        var index:Int = 0;
        var lastIndex:Int = 0;
        var count:Int = 0;

        function checkChar(char:Int):Void {
            if (char != Sigil.STYLE_CODE && char != Sigil.CARET_CODE) {
                count++;
                if (count == numCols + 1) {
                    wrappedLines.push(sub(s, lastIndex, index - lastIndex));
                    lastIndex = index;
                    count = 1;
                }
            }
            index++;
        }

        Utf8.iter(s, checkChar);
        if (wrappedLines.length == 0 || count > 0) {
            wrappedLines.push(sub(s, lastIndex, index - lastIndex));
        }
        wrappedLines = wrappedLines.map(padLine);

        return wrappedLines.join(LINE_TOKEN);
    }

    public function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y) if (id != 0):
                var targetSpan:Span = document.getSpanByMouseID(id);
                if (targetSpan != null) handleSpanMouseInteraction(targetSpan, type);
            case _:
        }
    }

    function handleSpanMouseInteraction(span:Span, type:MouseInteractionType):Void {
        span.receiveInteraction(type);
    }

    public function getPageSegment(index:Int):Array<String> return page.slice(index, index + numRows);

    public function getLineStyleIndex(index:Int):Int return lineStyleIndices[index];

    inline function swapTabsWithSpaces(input:String):String {
        var left:String = '';
        var right:String = input;

        while (length(right) > 0) {
            var tabIndex:Int = right.indexOf('\t');
            if (tabIndex == -1) {
                left = left + right;
                right = '';
            } else {
                left = left + right.substr(0, tabIndex) + '     ';
                right = right.substr(tabIndex, right.length);
                right = sub(right, 1);
            }
        }

        return left;
    }

    inline function numScrollPositions():Int {
        return pageLength < (numRows - 1) ? 1 : pageLength - (numRows - 1) + 1;
    }

    public inline function bottomPos():Float return numScrollPositions() - 1;
}