package net.rezmason.scourge.textview.core.rendermethods;

import flash.geom.Matrix3D;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;

class MouseMethod extends RenderMethod {

    //inline static var FAT_FINGERS:Float = 2; // TODO: Fat finger support needs to wait till we can z-order buttons

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aPaint:AttribsLocation;

    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    public function new():Void super();

    override public function activate():Void {
        util.setProgram(program);
    }

    override public function deactivate():Void {
    }

    override function init():Void {
        super.init();
        backgroundColor = 0xFFFFFF;
        //glyphMag = FAT_FINGERS;
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/mousepicking.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/mousepicking.frag');
    }

    override function connectToShaders():Void {
        aPos    = program.getAttribsLocation('aPos'   );
        aCorner = program.getAttribsLocation('aCorner');
        aPaint  = program.getAttribsLocation('aPaint' );

        uGlyphMat  = program.getUniformLocation('uGlyphMat' );
        uCameraMat = program.getUniformLocation('uCameraMat');
        uBodyMat   = program.getUniformLocation('uBodyMat'  );
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        program.setProgramConstantsFromMatrix(uGlyphMat, glyphMat);
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        program.setProgramConstantsFromMatrix(uCameraMat, cameraMat);
        program.setProgramConstantsFromMatrix(uBodyMat, bodyMat);
    }

    override public function setSegment(segment:BodySegment):Void {

        var shapeBuffer:VertexBuffer = null;
        var paintBuffer:VertexBuffer = null;

        if (segment != null) {
            shapeBuffer = segment.shapeBuffer;
            paintBuffer = segment.paintBuffer;
        }

        program.setVertexBufferAt(aPos,    shapeBuffer, 0, 3);
        program.setVertexBufferAt(aCorner, shapeBuffer, 3, 2);
        program.setVertexBufferAt(aPaint,  paintBuffer, 0, 3);
    }
}

