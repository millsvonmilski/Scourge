package net.rezmason.scourge.textview.core.rendermethods;

import flash.geom.Matrix3D;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.Almanac.*;
import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;

class PrettyMethod extends RenderMethod {

    inline static var DERIV_MULT:Float =
    #if flash
        0.3
    #elseif js
        80
    #else
        80
    #end
    ;

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aDistort:AttribsLocation;
    var aColor:AttribsLocation;
    var aUV:AttribsLocation;
    var aFX:AttribsLocation;
    var uSampler:UniformLocation;
    var uDerivMult:UniformLocation;
    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    public function new():Void super();

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        programUtil.setDepthTest(false);

        programUtil.setFourProgramConstants(program, uDerivMult, [DERIV_MULT, 0, 0, 0]);
    }

    override public function deactivate():Void {
        programUtil.setTextureAt(program, uSampler, null);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        programUtil.setDepthTest(true);
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/scourge_glyphs.vert');

        var frag:String = getText('shaders/scourge_glyphs.frag');

        #if flash
            fragShader = getText('shaders/scourge_glyphs_flash.frag');
        #elseif js
            programUtil.enableExtension("OES_standard_derivatives");
            fragShader = '#extension GL_OES_standard_derivatives : enable \n precision mediump float;' + frag;
        #else
            fragShader = frag;
        #end
    }

    override function connectToShaders():Void {

        aPos     = programUtil.getAttribsLocation(program, 'aPos'    );
        aCorner  = programUtil.getAttribsLocation(program, 'aCorner' );
        aDistort = programUtil.getAttribsLocation(program, 'aDistort');
        aColor   = programUtil.getAttribsLocation(program, 'aColor'  );
        aUV      = programUtil.getAttribsLocation(program, 'aUV'     );
        aFX      = programUtil.getAttribsLocation(program, 'aFX'     );
        
        uSampler   = programUtil.getUniformLocation(program, 'uSampler'  );
        uDerivMult = programUtil.getUniformLocation(program, 'uDerivMult');
        uGlyphMat  = programUtil.getUniformLocation(program, 'uGlyphMat' );
        uCameraMat = programUtil.getUniformLocation(program, 'uCameraMat');
        uBodyMat   = programUtil.getUniformLocation(program, 'uBodyMat'  );
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(program, uGlyphMat, glyphMat); // uGlyphMat contains the character matrix
        programUtil.setTextureAt(program, uSampler, glyphTexture.texture); // uSampler contains our texture
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(program, uCameraMat, cameraMat); // uCameraMat contains the camera matrix
        programUtil.setProgramConstantsFromMatrix(program, uBodyMat, bodyMat); // uBodyMat contains the body's matrix
    }

    override public function setSegment(segment:BodySegment):Void {

        var shapeBuffer:VertexBuffer = null;
        var colorBuffer:VertexBuffer = null;

        if (segment != null) {
            shapeBuffer = segment.shapeBuffer;
            colorBuffer = segment.colorBuffer;
        }

        programUtil.setVertexBufferAt(program, aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        programUtil.setVertexBufferAt(program, aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        programUtil.setVertexBufferAt(program, aDistort, shapeBuffer, 5, 3); // aScale contains h,s,p
        programUtil.setVertexBufferAt(program, aColor,   colorBuffer, 0, 3); // aColor contains r,g,b
        programUtil.setVertexBufferAt(program, aUV,      colorBuffer, 3, 2); // aUV contains u,v
        programUtil.setVertexBufferAt(program, aFX,      colorBuffer, 5, 3); // aFX contains i,f,a
    }
}

