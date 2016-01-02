package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.core.BodySegment;
import net.rezmason.hypertype.core.GlyphTexture;
import net.rezmason.hypertype.core.RenderMethod;

class HitboxMethod extends RenderMethod {

    public function new():Void {
        super();
        backgroundColor = new Vec3(1, 1, 1);
    }

    override public function activate():Void glSys.setProgram(program);

    override function composeShaders():Void {
        vertShader = getText('shaders/hitbox.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/hitbox.frag');
    }

    override function setBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraTransform', body.scene.camera.transform);
        program.setProgramConstantsFromMatrix('uBodyTransform', body.concatenatedTransform);
        program.setFourProgramConstants('uFontSDFData', body.glyphTexture.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params);
    }

    override public function setSegment(segment:BodySegment):Void {
        var geometryBuffer:VertexBuffer = (segment == null) ? null : segment.geometryBuffer;
        var hitboxBuffer:VertexBuffer = (segment == null) ? null : segment.hitboxBuffer;
        program.setVertexBufferAt('aPosition',    geometryBuffer, 0, 3);
        program.setVertexBufferAt('aCorner', geometryBuffer, 3, 2);
        program.setVertexBufferAt('aGlyphID',  hitboxBuffer, 0, 2);
        program.setVertexBufferAt('aHorizontalStretch', hitboxBuffer, 2, 1);
        program.setVertexBufferAt('aScale', hitboxBuffer, 3, 1);
    }

    override public function drawBody(body:Body) if (body.mouseEnabled && body.visible) super.drawBody(body);
}

