package;

import haxe.Utf8;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import format.png.Tools;
import format.png.Writer;
import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.Font;

import flash.net.FileReference;

import net.rezmason.utils.FlatFont;
import net.rezmason.utils.SDF;

import net.rezmason.scourge.textview.TestStrings;

@:font("assets/ProFontX.ttf") class ProFont extends Font {}
@:font("assets/SourceCodePro_FontsOnly-1.013/TTF/SourceCodePro-Semibold.ttf") class SourceProFont extends Font {}

class ScourgeAssetGen {

    public static function main():Void {

        var requiredString:String = [
            TestStrings.ALPHANUMERICS,
            TestStrings.PUNCTUATION,
            TestStrings.SYMBOLS,
            TestStrings.WEIRD_SYMBOLS,
            TestStrings.BOX_SYMBOLS,
        ].join("");

        var font1:FlatFont = FlatFont.flatten(new ProFont(), 140, requiredString, 48, 48, 1);
        var font2:FlatFont = FlatFont.flatten(new SourceProFont(), 140, requiredString, 48, 48, 1);
        var font3:FlatFont = FlatFont.combine(font1, [font2]);

        deploy(font1, "profont");
        deploy(font2, "source");
        deploy(font3, "full");

        var sdf = new SDF();
    }

    static function deploy(font:FlatFont, id:String):Void {
        var fontBD:BitmapData = font.getBitmapDataClone();

        var sprite:Sprite = new Sprite();
        sprite.addChild(new Bitmap(fontBD));

        var fileRef = null;
        sprite.addEventListener("click", function(_) {
            var json = font.exportJSON();

            var bytesOutput:BytesOutput = new BytesOutput();
            var writer:Writer = new Writer(bytesOutput);
            var data = Tools.build32ARGB(fontBD.width, fontBD.height, Bytes.ofData(fontBD.getPixels(fontBD.rect)));
            writer.write(data);

            fileRef = new FileReference();

            function savePNG(_) {
                fileRef.removeEventListener("complete", savePNG);
                fileRef.save(bytesOutput.getBytes().getData(), id + "_flat.png");
                Lib.current.removeChild(sprite);
            }

            fileRef.addEventListener("complete", savePNG);
            fileRef.save(json, id + "_flat.json");

        });

        Lib.current.addChild(sprite);
    }
}
