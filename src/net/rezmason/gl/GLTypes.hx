package net.rezmason.gl;

typedef AttribsLocation = #if flash Int #else Int #end ;
typedef UniformLocation = #if flash Int #else openfl.gl.GLUniformLocation #end ;

typedef NativeVertexBuffer = #if flash flash.display3D.VertexBuffer3D #else openfl.gl.GLBuffer #end ;
typedef NativeIndexBuffer = #if flash flash.display3D.IndexBuffer3D #else openfl.gl.GLBuffer #end ;
typedef NativeProgram = #if flash net.rezmason.gl.glsl2agal.Program #else openfl.gl.GLProgram #end ;
typedef NativeTexture = #if flash flash.display3D.textures.TextureBase #else openfl.gl.GLTexture #end;

typedef Context = #if flash flash.display3D.Context3D #else Class<openfl.gl.GL> #end ;