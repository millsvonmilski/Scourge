package net.rezmason.scourge.waves;

class WaveFunctions {

    public inline static function heartbeat(x:Float):Float {
        x *= Math.PI;
        return -Math.sin(x) * Math.cos(x * 0.5);
    }

    public inline static function bolus(x:Float):Float {
        return (Math.cos(x * Math.PI) + 1) * 0.5;
    }

    public inline static function sineTooth(x:Float):Float {
        return (Math.sin(x * Math.PI / 2) + 1) * 0.5;
    }

    public inline static function sawTooth(x:Float):Float {
        return (x + 1) * 0.5;
    }

    public inline static function photocopy(func:Float->Float, rez:Int):Float->Float {
        var data:Array<Float> = [];
        for (ike in 0...rez + 1) data[ike] = func(ike / rez * 2 - 1);

        return function (x:Float):Float {
            x = (x + 1) * rez / 2;
            var frac:Float = x % 1;

            /*
            var y1:Float = data[Std.int(x - frac)];
            var y2:Float = data[Std.int(x - frac + 1)];
            return y2 * frac + y1 * (1 - frac);
            */

            return (data[Std.int(x - frac + 1)]) * frac + (data[Std.int(x - frac)]) * (1 - frac);
        };
    }
}
