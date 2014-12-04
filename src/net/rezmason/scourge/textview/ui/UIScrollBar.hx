package net.rezmason.scourge.textview.ui;

import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIScrollBar {

    public var trackGlyph:Glyph;
    public var thumbGlyph:Glyph;
    public var visible:Bool;
    public var fade:Float;
    var bodyPaint:Int;

    public function new(bodyPaint:Int):Void {
        visible = false;
        fade = 0;
        this.bodyPaint = bodyPaint;
    }

    public inline function setGlyphs(track:Glyph, thumb:Glyph):Void {
        trackGlyph = track;
        thumbGlyph = thumb;

        trackGlyph.set_rgb(1, 1, 1);
        trackGlyph.set_i(0.2);
        trackGlyph.set_paint(bodyPaint);

        thumbGlyph.set_rgb(1, 1, 1);
        thumbGlyph.set_i(1);
        thumbGlyph.set_paint(bodyPaint);
    }

    public inline function updateFade(delta:Float):Void {
        var changed:Bool = false;
        var fadeGoal:Float = 0;
        if (visible && fade < 1) {
            fadeGoal = 1;
            changed = true;
        } else if (!visible && fade > 0) {
            fadeGoal = 0;
            changed = true;
        }

        if (changed) {
            delta *= 10;
            fade = fade * (1 - delta) + fadeGoal * delta;
            trackGlyph.set_rgb(fade, fade, fade);
            thumbGlyph.set_rgb(fade, fade, fade);
        }
    }

    public inline function updatePosition(x:Float, y:Float, thumbY:Float, thumbHeight:Float, trackHeight:Float):Void {
        
        if (thumbHeight >= 1) {
            trackGlyph.set_rgb(0, 0, 0);
            thumbGlyph.set_rgb(0, 0, 0);
        } else {
            trackGlyph.set_rgb(1, 1, 1);
            thumbGlyph.set_rgb(1, 1, 1);
        }

        if (Math.isNaN(thumbY)) thumbY = 0;
        thumbGlyph.set_s(thumbHeight);
        thumbGlyph.set_h(0.65 / thumbHeight);

        trackGlyph.set_s(trackHeight);
        trackGlyph.set_h(0.95 / trackHeight);

        trackGlyph.set_xyz(x, y, 0);
        thumbGlyph.set_xyz(x, y + thumbY, 0);
    }
}
