package net.rezmason.hypertype.core;

import net.rezmason.gl.GLTypes;

import net.rezmason.ds.SceneNode;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class Body extends SceneNode<Body> {

    static var _ids:Int = 0;

    public var numGlyphs(default, null):Int = 0;
    public var id(default, null):Int = ++_ids;
    public var transform(default, null):Matrix4 = new Matrix4();
    public var concatenatedTransform(get, null):Matrix4;
    public var glyphScale(default, set):Float;
    public var glyphTexture(default, set):GlyphTexture;
    public var scene(default, null):Scene;
    public var mouseEnabled:Bool = true;
    public var visible:Bool = true;
    
    public var fontChangedSignal(default, null):Zig<Void->Void> = new Zig();
    public var interactionSignal(default, null):Zig<Int->Interaction->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var sceneSetSignal(default, null):Zig<Void->Void> = new Zig();
    public var drawSignal(default, null):Zig<Void->Void> = new Zig();

    @:allow(net.rezmason.hypertype.core) var segments(default, null):Array<BodySegment> = [];
    @:allow(net.rezmason.hypertype.core) var params(default, null):Array<Float>;
    
    var trueNumGlyphs:Int = 0;
    var concatMat:Matrix4 = new Matrix4();
    var glyphs:Array<Glyph> = [];

    public function new():Void {
        super();
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateGlyphTexture);
        glyphTexture = fontManager.defaultFont;
        params = [0, 0, 0, 0];
        params[2] = id / 0xFF;
        glyphScale = 1;
    }

    override public function addChild(node:Body):Bool {
        var success = super.addChild(node);
        if (success) {
            node.setScene(scene);
            node.update(0);
            if (scene != null) scene.invalidate();
        }
        return success;
    }

    override public function removeChild(node:Body):Bool {
        var success = super.removeChild(node);
        if (success) {
            node.setScene(null);
            if (scene != null) scene.invalidate();
        }
        return success;
    }

    public inline function getGlyphByID(id:Int):Glyph return glyphs[id];

    public inline function eachGlyph():Iterator<Glyph> return glyphs.iterator();

    public function growTo(numGlyphs:Int):Void {
        if (trueNumGlyphs < numGlyphs) {

            var oldSegments:Array<BodySegment> = segments;
            var oldGlyphs:Array<Glyph> = glyphs;

            glyphs = [];
            segments = [];

            var remainingGlyphs:Int = numGlyphs;
            var startGlyph:Int = 0;
            var segmentID:Int = 0;

            while (startGlyph < numGlyphs) {
                var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                var segment:BodySegment = null;
                var donor:BodySegment = oldSegments[segmentID];

                if (donor != null && donor.numGlyphs == len) {
                    segment = donor;
                    segment.numGlyphs = len;
                } else {
                    segment = new BodySegment(segmentID, len, donor);
                    if (donor != null) donor.destroy();
                }

                segments.push(segment);
                glyphs = glyphs.concat(segment.glyphs);
                startGlyph += Almanac.BUFFER_CHUNK;
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
                segmentID++;
            }

            trueNumGlyphs = numGlyphs;

        } else {
            var remainingGlyphs:Int = numGlyphs;
            for (segment in segments) {
                segment.numGlyphs = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
            }
        }
        this.numGlyphs = numGlyphs;
        for (glyph in glyphs) glyph.set_font(glyphTexture.font);
    }

    @:allow(net.rezmason.hypertype.core)
    function update(delta:Float):Void updateSignal.dispatch(delta);

    @:allow(net.rezmason.hypertype.core)
    function upload():Void for (segment in segments) segment.upload();

    @:allow(net.rezmason.hypertype.core)
    function setScene(scene:Scene):Void {
        var lastScene:Scene = this.scene;
        if (this.scene != null) this.scene.resizeSignal.remove(updateGlyphTransform);
        this.scene = scene;
        updateGlyphTransform();
        if (this.scene != null) this.scene.resizeSignal.add(updateGlyphTransform);
        for (child in children()) child.setScene(scene);
        sceneSetSignal.dispatch();
    }

    function updateGlyphTexture(glyphTexture:GlyphTexture):Void {
        if (this.glyphTexture != glyphTexture) {
            this.glyphTexture = glyphTexture;
            updateGlyphTransform();
            for (glyph in glyphs) glyph.set_font(glyphTexture.font);
        }
    }

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        updateGlyphTransform();
        return glyphScale;
    }

    inline function set_glyphTexture(tex:GlyphTexture):GlyphTexture {
        if (tex != null) {
            this.glyphTexture = tex;
            fontChangedSignal.dispatch();
        }
        return glyphTexture;
    }

    inline function updateGlyphTransform():Void {
        if (glyphTexture != null && scene != null) {
            params[0] = glyphScale * scene.camera.glyphScale;
            params[1] = glyphScale * scene.camera.glyphScale * scene.stageWidth / scene.stageHeight;
        }
    }

    function get_concatenatedTransform():Matrix4 {
        concatMat.copyFrom(transform);
        if (parent != null) concatMat.append(parent.concatenatedTransform);
        return concatMat;
    }
}