package net.rezmason.utils;

import haxe.io.Bytes;

class HalfFloatUtil {

    /**
     * Practically carbon copied from Jeroen van der Zijp's paper:
     * ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
     **/

    static var tables = generateTables();
    static var baseTable = tables[0];
    static var shiftTable = tables[1];
    static var floatBytes = Bytes.alloc(4);

    public inline static function floatToHalfFloat(float:Float):Int {
        floatBytes.setFloat(0, float);
        var floatRep:Int = floatBytes.getInt32(0);
        var halfFloatRep:Int = baseTable[(floatRep >> 23) & 0x1FF] + ((floatRep & 0x007FFFFF) >> shiftTable[(floatRep >> 23) & 0x1FF]);
        return halfFloatRep;
    }

    public inline static function halfFloatToFloat(halfFloatRep:Int):Float {
        var floatRep:Int = ((halfFloatRep & 0x8000) << 16) | (((halfFloatRep & 0x7c00) + 0x1C000) << 13) | ((halfFloatRep & 0x03FF) << 13);
        floatBytes.setInt32(0, floatRep);
        var float:Float = floatBytes.getFloat(0);
        return float;
    }

    static function generateTables() {
        baseTable = [];
        shiftTable = [];
        for (i in 0...256) {
            var e:Int = i - 127;
            if (e < -24) {
                baseTable[i | 0x100] = 0x8000;
                shiftTable[i | 0x000] = 24;
                shiftTable[i | 0x100] = 24;
            } else if (e < -14) {
                // Small numbers map to denorms
                baseTable[i | 0x000] = (0x0400 >> (-e - 14));
                baseTable[i | 0x100] = (0x0400 >> (-e - 14)) | 0x8000;
                shiftTable[i | 0x000] = -e - 1;
                shiftTable[i | 0x100] = -e - 1;
            } else if (e <= 15) {
                // Normal numbers just lose precision
                baseTable[i | 0x000] = ((e + 15) << 10);
                baseTable[i | 0x100] = ((e + 15) << 10) | 0x8000;
                shiftTable[i | 0x000] = 13;
                shiftTable[i | 0x100] = 13;
            } else if (e < 128) {
                // Large numbers map to Infinity
                baseTable[i | 0x000] = 0x7C00;
                baseTable[i | 0x100] = 0xFC00;
                shiftTable[i | 0x000] = 24;
                shiftTable[i | 0x100] = 24;
            } else {
                // Infinity and NaN's stay Infinity and NaNs
                baseTable[i | 0x000] = 0x7C00;
                baseTable[i | 0x100] = 0xFC00;
                shiftTable[i | 0x000] = 13;
                shiftTable[i | 0x100] = 13;
            }
        }
        return [baseTable, shiftTable];
    }
}
