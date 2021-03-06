package;

import haxe.io.Bytes;
import lime.app.Application;
import lime.graphics.Image;
import net.rezmason.hypertype.Strings;
import net.rezmason.utils.display.SDFFontGenerator;
import net.rezmason.utils.display.MetaballTextureGenerator;
import net.rezmason.utils.display.GlobTextureGenerator;
import sys.io.File;

class ScourgeAssetGen extends Application {

    override public function onPreloadComplete():Void {
        
        var profontChars:String = [
            ' ',
            Strings.ALPHANUMERICS,
            Strings.PUNCTUATION,
            Strings.SYMBOLS,
            Strings.WEIRD_SYMBOLS,
        ].join('');

        var matrixChars:String = Strings.MATRIX_CHARS + Strings.MATRIX_UNUSED_CHARS;

        var characterSets:Array<FontCharacterSet> = [
            {chars:profontChars, size:300, size2:300, fontID:'ProFont'},
            {chars:Strings.SMALL_CYRILLICS, size:400, size2:300, fontID:'ProFont_Cy'},
            {chars:Strings.SHARP_BOX_SYMBOLS, size:300, size2:300, fontID:'SourceProFont'},
            {chars:Strings.ROUNDED_BOX_SYMBOLS, size:300, size2:300, fontID:'SourceProFont'},
        ];
        var glyphs = SDFFontGenerator.extractGlyphsFromFonts(characterSets);
        SDFFontGenerator.generate(glyphs, 72, 72, 1, 20, deployFont.bind('full'));

        characterSets = [{chars:matrixChars, size:218, size2:218, fontID:'MatrixCode'}];
        var glyphs = SDFFontGenerator.extractGlyphsFromFonts(characterSets);
        SDFFontGenerator.generate(glyphs, 72, 72, 1, 20, deployFont.bind('matrix'));

        deployImage('metaballs', 'metaball', MetaballTextureGenerator.makeTexture(30, 0.62, 20));
        deployImage('metaballs', 'glob', GlobTextureGenerator.makeTexture(512));

        Sys.exit(0);
    }

    static function deployFont(id:String, htf:Bytes, image:Image):Void {
        var path = '../../../../../../../../assets/sdffonts/';
        File.saveBytes('$path${id}.htf', htf);
        File.saveContent('$path${id}.png', image.encode().toString());
    }

    static function deployImage(dirPath:String, id:String, image:Image):Void {
        var path = '../../../../../../../../assets/';
        File.saveContent('$path$dirPath/${id}.png', image.encode().toString());
    }
}
