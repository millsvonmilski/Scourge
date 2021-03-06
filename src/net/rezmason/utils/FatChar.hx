package net.rezmason.utils;

import haxe.Utf8;

class FatChar {
    public var string(default, null):String;
    public var code(default, set):Null<Int>;

    public function new(code:Null<Int> = null):Void {
        set_code(code);
    }

    public function set_code(code:Null<Int>):Null<Int> {
        this.code = code;
        if (code != null && code < 0x80) string = String.fromCharCode(code);
        else string = null;
        return code;
    }

    public function toString():String {
        return '{code:$code string:$string}';
    }

    public static function fromString(str:String):Array<FatChar> {
        var arr:Array<FatChar> = [];
        function pushChar(code:Int):Void { arr.push(new FatChar(code)); }
        Utf8.iter(str, pushChar);
        return arr;
    }
}
