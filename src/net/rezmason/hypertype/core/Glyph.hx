package net.rezmason.hypertype.core;

import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec3;
import net.rezmason.utils.display.SDFFont;

@:allow(net.rezmason.hypertype.core.BodySegment)
@:allow(net.rezmason.hypertype.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;

    var shapeBuf:VertexBuffer;
    var colorBuf:VertexBuffer;
    var paintBuf:VertexBuffer;
    var color:Vec3;
    var paintHex:Int;
    var charCode:Int;
    var font:SDFFont;

    function new(id:Int = 0):Void this.id = id;
}
