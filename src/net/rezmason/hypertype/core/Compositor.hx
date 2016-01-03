package net.rezmason.hypertype.core;

import lime.Assets.getText;
import lime.graphics.Image;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLSystem;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.Program;
import net.rezmason.gl.Texture;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.gl.ViewportRenderTarget;
import net.rezmason.utils.santa.Present;
#if debug_graphics 
    import lime.graphics.cairo.CairoImageSurface;
    import net.rezmason.gl.ImageTexture;
#end

class Compositor {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;

    public var inputBuffer(default, null):RenderTarget;
    var inputTexture:Texture;
    #if debug_graphics 
        var debugTexture:ImageTexture;
        var debugSurface:CairoImageSurface;
        public var debugGraphics(default, null):DebugGraphics;
    #end
    var viewportBuffer:ViewportRenderTarget;
    var glSys:GLSystem;
    var program:Program;
    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    public function new() {
        glSys = new Present(GLSystem);

        glSys.enableExtension("OES_texture_float");
        glSys.enableExtension("OES_texture_float_linear");
        
        var textureRenderTarget = glSys.createTextureRenderTarget(FLOAT);
        inputTexture = textureRenderTarget.texture;
        inputBuffer = textureRenderTarget;
        viewportBuffer = glSys.viewportRenderTarget;

        #if debug_graphics 
            debugTexture = glSys.createImageTexture(new Image(null, 0, 0, 1, 1, 0x00000000));
            debugSurface = CairoImageSurface.fromImage(debugTexture.image);
            debugGraphics = new DebugGraphics(debugSurface);
        #end

        // inputBuffer = viewportBuffer;

        vertexBuffer = glSys.createVertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
        var verts = [
            -1, -1, 0, 0,
            -1,  1, 0, 1,
             1, -1, 1, 0,
             1,  1, 1, 1,
        ];
        for (ike in 0...verts.length) vertexBuffer.mod(ike, verts[ike]);
        vertexBuffer.upload();

        indexBuffer = glSys.createIndexBuffer(TOTAL_INDICES);
        var ind = [0, 1, 2, 1, 2, 3,];
        for (ike in 0...TOTAL_INDICES) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        var extensions = '';
        #if js 
            for (extension in ['GL_OES_texture_float',  'GL_OES_texture_float_linear',]) {
                glSys.enableExtension(extension);
                extensions = '$extensions\n#extension $extension : enable';
            }
            extensions = '$extensions\nprecision mediump float;';
        #end

        var vertShader = extensions + getText('shaders/post_process.vert');
        var fragShader = extensions + getText('shaders/post_process.frag');
        program = glSys.createProgram(vertShader, fragShader);
    }

    public function setSize(width, height) {
        inputBuffer.resize(width, height);
        #if debug_graphics 
            debugTexture.image.resize(width, height);
            debugSurface = CairoImageSurface.fromImage(debugTexture.image);
            @:privateAccess debugGraphics.recreate(debugSurface);
            debugGraphics.identityMatrix();
            if (width > height) {
                debugGraphics.translate((width - height) / 2, 0);
                debugGraphics.scale(height, height);
            } else {
                debugGraphics.translate(0, (height - width) / 2);
                debugGraphics.scale(width, width);
            }
            debugGraphics.translate(0.5, 0.5);
        #end
        viewportBuffer.resize(width, height);
    }

    public function draw() {
        glSys.setProgram(program);

        program.setTextureAt('uTexture', inputTexture);
        program.setVertexBufferAt('aPos', vertexBuffer, 0, 2);
        program.setVertexBufferAt('aUV',  vertexBuffer, 2, 2);

        glSys.start(viewportBuffer);
        glSys.clear(1, 0, 1);
        glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        #if debug_graphics
            glSys.setDepthTest(false);
            glSys.setBlendFactors(BlendFactor.SOURCE_ALPHA, BlendFactor.ONE_MINUS_SOURCE_ALPHA);  
            debugTexture.update();
            program.setTextureAt('uTexture', debugTexture);
            glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
            glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);  
            glSys.setDepthTest(true);
        #end
        glSys.finish();

        program.setTextureAt('uTexture', null);
        program.setVertexBufferAt('aPos', null, 0, 2);
        program.setVertexBufferAt('aUV',  null, 2, 2);
    }
}
