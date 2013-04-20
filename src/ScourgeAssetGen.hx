package;

import haxe.Utf8;

import nme.Assets;
import nme.Lib;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.Event;

import flash.net.FileReference;

import net.rezmason.utils.FlatFont;

import net.rezmason.scourge.textview.TestStrings;

class ScourgeAssetGen {

    public static function main():Void {

        var requiredString:String = [
            TestStrings.ALPHANUMERICS,
            TestStrings.PUNCTUATION,
            TestStrings.SYMBOLS,
            TestStrings.WEIRD_SYMBOLS,
            TestStrings.BOX_SYMBOLS,
        ].join("");

        var font1:FlatFont = FlatFont.flatten(Assets.getFont("assets/ProFontX.ttf"), 140, requiredString, 48, 48, 1);
        var font2:FlatFont = FlatFont.flatten(Assets.getFont("assets/SourceCodePro-Semibold.ttf"), 140, requiredString, 48, 48, 1);
        var font3:FlatFont = FlatFont.combine(font1, [font2]);

        deploy(font1, "profont");
        deploy(font2, "source");
        deploy(font3, "full");
    }

    static function deploy(font:FlatFont, id:String):Void {
        var fontBD:BitmapData = font.getBitmapDataClone();

        var sprite:Sprite = new Sprite();
        sprite.addChild(new Bitmap(fontBD));

        var fileRef = null;
        sprite.addEventListener("click", function(_) {
            var json = font.exportJSON();
            var pngBytes = com.moodycamel.PNGEncoder2.encode(fontBD);
            fileRef = new FileReference();

            function savePNG(_) {
                fileRef.removeEventListener("complete", savePNG);
                fileRef.save(pngBytes, id + "_flat.png");
                Lib.current.removeChild(sprite);
            }

            fileRef.addEventListener("complete", savePNG);
            fileRef.save(json, id + "_flat.json");

        });

        Lib.current.addChild(sprite);
    }
}
