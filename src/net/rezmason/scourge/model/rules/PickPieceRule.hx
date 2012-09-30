package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.scourge.model.AspectUtils;
using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {>BuildConfig,
    public var pieceTableIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
    public var randomFunction:Void->Float; // Source of random numbers
}

typedef PickPieceOption = {>Option,
    var hatIndex:Int;
    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}

class PickPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    private var allOptions:Array<PickPieceOption>;
    private var pickOption:Option;

    // This rule is surprisingly complex

    @extra(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_:AspectPtr;
    @extra(PieceAspect.PIECE_HAT_PREV) var pieceHatPrev_:AspectPtr;

    @extra(PieceAspect.PIECE_ID) var pieceID_:AspectPtr;
    @extra(PieceAspect.PIECE_NEXT) var pieceNext_:AspectPtr;
    @extra(PieceAspect.PIECE_PREV) var piecePrev_:AspectPtr;

    @extra(PieceAspect.PIECE_OPTION_ID) var pieceOptionID_:AspectPtr;

    @state(PieceAspect.PIECES_PICKED) var piecesPicked_:AspectPtr;
    @state(PieceAspect.PIECE_FIRST) var pieceFirst_:AspectPtr;
    @state(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_:AspectPtr;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;

    @state(PieceAspect.PIECE_HAT_PLAYER) var pieceHatPlayer_:AspectPtr;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_:AspectPtr;

    var remakeHat:Bool;

    public function new(cfg:PickPieceConfig):Void {
        super();
        this.cfg = cfg;
        if (cfg.hatSize > cfg.pieceTableIDs.length) cfg.hatSize = cfg.pieceTableIDs.length;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        buildPieceOptions();
    }

    override public function update():Void {
        remakeHat = false;

        if (cfg.allowAll) {
            options = cast allOptions.copy();
            quantumOptions = [];
        } else if (
                state.aspects.at(pieceHatPlayer_) != state.aspects.at(currentPlayer_) ||
                state.aspects.at(piecesPicked_) == cfg.hatSize) {
            remakeHat = true;
            options = [pickOption];
            quantumOptions = cast allOptions.copy();
        } else if (state.aspects.at(pieceTableID_) == Aspect.NULL) {
            options = [pickOption];
            var quantumPieceOptions:Array<PickPieceOption> = [];
            var firstHatPiece:AspectSet = state.extras[state.aspects.at(pieceHatFirst_)];
            var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);
            for (piece in hatPieces) quantumPieceOptions.push(allOptions[piece.at(pieceOptionID_)]);
            quantumOptions = cast quantumPieceOptions;
        }
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var option:PickPieceOption = cast options[choice];
        if (cfg.allowAll) {
            setPiece(option.pieceTableID, option.reflection, option.rotation);
        } else {
            if (remakeHat) buildHat();
            option = pickOptionFromHat();
            setPiece(option.pieceTableID, option.reflection, option.rotation);
        }
    }

    override public function chooseQuantumOption(choice:Int):Void {
        super.chooseQuantumOption(choice);

        var option:PickPieceOption = cast options[choice];
        if (remakeHat) buildHat();
        pickOptionFromHat(option);
        setPiece(option.pieceTableID, option.reflection, option.rotation);
    }

    private function buildPieceOptions():Void {
        allOptions = [];
        pickOption = {optionID:0};

        var pieceFrequencies:Array<Int> = [];
        for (pieceTableID in cfg.pieceTableIDs) {
            if (pieceFrequencies[pieceTableID] == null) pieceFrequencies[pieceTableID] = 0;
            pieceFrequencies[pieceTableID]++;
        }

        // Create an option for every element being picked randomly

        for (pieceTableID in 0...pieceFrequencies.length) {
            var pieceFrequency:Null<Int> = pieceFrequencies[pieceTableID];
            if (pieceFrequency == 0 || pieceFrequency == null) continue;

            var piece:PieceGroup = Pieces.getPieceById(pieceTableID);

            if (!cfg.allowFlipping) {
                var flipWeight:Float = piece.length % 2;
                for (reflection in 0...piece.length) {
                    if (!cfg.allowRotating) {
                        var spinWeight:Float = piece[reflection].length % 4;
                        for (rotation in 0...piece[reflection].length) {
                            makeOption(pieceTableID, reflection, rotation, pieceFrequency * flipWeight * spinWeight);
                        }
                    } else {
                        makeOption(pieceTableID, reflection, 0, pieceFrequency * flipWeight);
                    }
                }
            } else if (!cfg.allowRotating) {
                var reflection:Int = 0;
                var spinWeight:Float = piece[reflection].length % 4;
                for (rotation in 0...piece[reflection].length) {
                    makeOption(pieceTableID, 0, rotation, pieceFrequency * spinWeight);
                }
            } else {
                makeOption(pieceTableID, 0, 0, pieceFrequency);
            }
        }

        // Create a hat extra for every option
        var allPieces:Array<AspectSet> = [];
        for (option in allOptions) {
            extraAspectTemplate.mod(pieceID_, state.extras.length);
            option.hatIndex = state.extras.length;
            extraAspectTemplate.mod(pieceOptionID_, option.optionID);
            var piece:AspectSet = buildExtra();
            allPieces.push(piece);
            state.extras.push(piece);
            cfg.historyState.extras.push(buildHistExtra(cfg.history));
        }

        allPieces.chainByAspect(pieceID_, pieceNext_, piecePrev_);
        state.aspects.mod(pieceFirst_, allPieces[0].at(pieceID_));
    }

    private function makeOption(pieceTableID:Int, reflection:Int, rotation:Int, weight:Float):Void {
        allOptions.push({
            pieceTableID:pieceTableID,
            rotation:rotation,
            reflection:reflection,
            weight:weight,
            relatedOptionID:0,
            optionID:allOptions.length,
            hatIndex:0,
        });
    }

    private function setPiece(pieceTableID:Int, reflection:Int, rotation:Int):Void {
        state.aspects.mod(pieceTableID_, pieceTableID);
        state.aspects.mod(pieceReflection_, reflection);
        state.aspects.mod(pieceRotation_, rotation);
    }

    private function pickOptionFromHat(option:PickPieceOption = null):PickPieceOption {

        var firstHatPiece:AspectSet = state.extras[state.aspects.at(pieceHatFirst_)];
        var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);

        var maxWeight:Float = 0;
        var weights:Array<Float> = [];
        for (piece in hatPieces) {
            weights.push(maxWeight);
            maxWeight += allOptions[piece.at(pieceOptionID_)].weight;
        }

        var pickedPiece:AspectSet = null;
        if (option == null) {
            var pick:Float = cfg.randomFunction() * maxWeight;
            pickedPiece = hatPieces[binarySearch(pick, weights)];
            option = allOptions[pickedPiece.at(pieceOptionID_)];
        } else {
            pickedPiece = state.extras[option.hatIndex];
        }

        state.aspects.mod(piecesPicked_, state.aspects.at(piecesPicked_) + 1);


        pickedPiece.removeSet(state.extras, pieceHatNext_, pieceHatPrev_);

        return option;
    }

    private function buildHat():Void {
        var firstPiece:AspectSet = state.extras[state.aspects.at(pieceFirst_)];
        var allPieces:Array<AspectSet> = firstPiece.listToArray(state.extras, pieceNext_);
        allPieces.chainByAspect(pieceID_, pieceHatNext_, pieceHatPrev_);
        state.aspects.mod(pieceHatFirst_, firstPiece.at(pieceID_));
        state.aspects.mod(piecesPicked_, 0);
    }

    private function binarySearch(val:Float, list:Array<Float>):Int {
        function search(min:Int, max:Int):Int {
            var halfway:Int = Std.int((min + max) * 0.5);
            if (max < min) return -1;
            else if (list[halfway] > val) return search(min, halfway - 1);
            else if (list[halfway] < val) return search(halfway + 1, max);
            else return halfway;
        }

        return search(0, list.length);
    }
}
