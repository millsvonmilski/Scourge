package net.rezmason.hypertype.demo;

import net.rezmason.gl.GLTypes;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Interaction;

using net.rezmason.hypertype.core.GlyphUtils;

class EyeCandyDemo {

    static var CHARS = Strings.ALPHANUMERICS;
    static var NUM_CHARS = CHARS.length;

    public var body(default, null):Body;

    var time:Float;

    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix4;
    var rawTransform:Matrix4;
    var setBackTransform:Matrix4;

    public function new(num:Int = 2400):Void {

        body = new Body();
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        body.glyphScale = 0.007;

        time = 0;

        dragging = false;
        dragStartTransform = new Matrix4();
        rawTransform = new Matrix4();
        rawTransform.appendRotation( 45, Vector4.X_AXIS);
        rawTransform.appendRotation(315, Vector4.Z_AXIS);
        setBackTransform = rawTransform.clone();
        setBackTransform.appendTranslation(0, 0, 0.5);
        body.transform.copyFrom(setBackTransform);

        setSize(num); // 40000, 240
    }

    inline function setSize(num:Int):Void {
        body.growTo(num);

        var dTheta:Float = Math.PI * (3 - Math.sqrt(5));
        var dZ:Float = 2 / (num + 1);
        var theta:Float = 0;
        var _z:Float = 1 - dZ / 2;

        for (ike in 0...num) {
            var charCode:Int = CHARS.charCodeAt(ike % NUM_CHARS);

            var rad:Float = Math.sqrt(1 - _z * _z);
            var x:Float = Math.cos(theta) * rad;
            var y:Float = Math.sin(theta) * rad;
            var z:Float = _z;

            x *= 0.6;
            y *= 0.6;
            z *= 0.6;

            var r:Float = ramp(x + 0.5);
            var g:Float = ramp(y + 0.5);
            var b:Float = ramp(z + 0.5);

            body.getGlyphByID(ike).SET({x:x, y:y, z:z, r:r, g:g, b:b, char:charCode, paint:ike});
            
            _z -= dZ;
            theta += dTheta;
        }
    }

    inline function ramp(num:Float):Float return (2 - num) * num;

    public function update(delta:Float):Void {
        time += delta;

        body.transform.identity();
        body.transform.appendRotation(time * 30, Vector4.Z_AXIS);
        body.transform.append(setBackTransform);

        for (glyph in body.eachGlyph()) {
            glyph.set_p(Math.cos(time * 4 + glyph.get_x() * 20) * 0.200 + 0.4);
            glyph.set_s(Math.cos(time * 4 + glyph.get_y() * 30) * 0.200 + 3.0);
            glyph.set_f(Math.cos(time * 8 + glyph.get_z() * 40) * 0.280 + 0.1);
        }
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOUSE_DOWN: startDrag(x, y);
                    case MOUSE_UP, DROP: stopDrag();
                    case MOVE, ENTER, EXIT: if (dragging) updateDrag(x, y);
                    case _:
                }
            case KEYBOARD(type, keyCode, modifier):
                if (type == KEY_DOWN) {
                    switch (keyCode) {
                        case LEFT:  setSize(Std.int(body.numGlyphs * (modifier.shiftKey ? 0.666 : 0.9)));
                        case RIGHT: setSize(Std.int(body.numGlyphs * (modifier.shiftKey ? 1.500 : 1.1)));
                        case _: setGlobalChar(cast keyCode);
                    }
                }
        }
    }

    inline function startDrag(x:Float, y:Float):Void {
        dragging = true;
        dragStartTransform.copyFrom(rawTransform);
        dragX = x;
        dragY = y;
    }

    inline function updateDrag(x:Float, y:Float):Void {
        rawTransform.copyFrom(dragStartTransform);
        rawTransform.appendRotation((dragX - x) * 180, Vector4.Y_AXIS);
        rawTransform.appendRotation((dragY - y) * 180, Vector4.X_AXIS);
        setBackTransform.copyFrom(rawTransform);
        setBackTransform.appendTranslation(0, 0, 0.5);
    }

    inline function stopDrag():Void {
        dragging = false;
    }

    inline function setGlobalChar(charCode:Int):Void {
        for (glyph in body.eachGlyph()) glyph.set_char(charCode);
    }

}