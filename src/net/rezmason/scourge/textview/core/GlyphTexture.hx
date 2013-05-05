package net.rezmason.scourge.textview.core;

import nme.display.BitmapData;
import nme.geom.Matrix3D;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.utils.Types;
import net.rezmason.scourge.textview.utils.TextureUtil;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):FlatFont;
    public var matrix(default, null):Matrix3D;
    public var aspectRatio(default, null):Float;

    public function new(textureUtil:TextureUtil, font:FlatFont):Void {
        this.font = font;
        texture = textureUtil.createTexture(customize(font.getBitmapDataClone()));

        matrix = new Matrix3D();
        matrix.appendTranslation(-0.5, -0.5, 0);
    }

    function customize(src:BitmapData):BitmapData { return src; }
}