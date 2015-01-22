package net.rezmason.scourge.model;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.State;
import net.rezmason.scourge.controller.Presenter;
import net.rezmason.scourge.model.Pieces;
import net.rezmason.scourge.model.ScourgeAction.*;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;
import net.rezmason.scourge.model.rules.*;
import net.rezmason.scourge.tools.Resource;
import net.rezmason.utils.Siphon;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigFactory {

    inline static var CLEAN_UP:String = 'cleanUp';
    inline static var WRAP_UP:String = 'wrapUp';

    static var BUILD_BOARD:String        = Type.getClassName(BuildBoardRule);
    static var BUILD_PLAYERS:String      = Type.getClassName(BuildPlayersRule);
    static var BUILD_GLOBALS:String      = Type.getClassName(BuildGlobalsRule);
    static var CAVITY:String             = Type.getClassName(CavityRule);
    static var DECAY:String              = Type.getClassName(DecayRule);
    static var DROP_PIECE:String         = Type.getClassName(DropPieceRule);
    static var EAT_CELLS:String          = Type.getClassName(EatCellsRule);
    static var END_TURN:String           = Type.getClassName(EndTurnRule);
    static var RESET_FRESHNESS:String    = Type.getClassName(ResetFreshnessRule);
    static var FORFEIT:String            = Type.getClassName(ForfeitRule);
    static var KILL_HEADLESS_BODY:String = Type.getClassName(KillHeadlessBodyRule);
    static var PICK_PIECE:String         = Type.getClassName(PickPieceRule);
    static var REPLENISH:String          = Type.getClassName(ReplenishRule);
    static var STALEMATE:String          = Type.getClassName(StalemateRule);
    static var ONE_LIVING_PLAYER:String  = Type.getClassName(OneLivingPlayerRule);
    static var BITE:String               = Type.getClassName(BiteRule);
    static var SWAP_PIECE:String         = Type.getClassName(SwapPieceRule);

    public static var ruleDefs(default, null):Map<String, Class<Rule>> = cast Siphon.getDefs(
        'net.rezmason.scourge.model.rules', 'src', false, 'Rule'
    );

    public static var presenterDefs(default, null):Map<String, Class<Presenter>> = cast Siphon.getDefs(
        'net.rezmason.scourge.controller.presenters', 'src', false, 'Presenter'
    );

    public inline static function makeDefaultActionList():Array<String> return [DROP_ACTION, QUIT_ACTION];
    public inline static function makeStartAction():String return START_ACTION;
    public static function makeBuilderRuleList():Array<String> return [BUILD_GLOBALS, BUILD_PLAYERS, BUILD_BOARD];
    public static function makeActionList(config:ScourgeConfig):Array<String> {

        var actionList:Array<String> = [QUIT_ACTION, DROP_ACTION/*, PICK_ACTION*/];

        if (config.maxSwaps > 0) actionList.push(SWAP_ACTION);
        if (config.maxBites > 0) actionList.push(BITE_ACTION);

        return actionList;
    }

    public static function makeDefaultConfig():ScourgeConfig {

        var pieces:Pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));

        return {
            allowAllPieces:false,
            allowFlipping:false,
            allowNowhereDrop:true,
            allowRotating:true,
            baseBiteReachOnThickness:false,
            biteHeads:true,
            biteThroughCavities:false,
            circular:false,
            diagDropOnly:false,
            eatHeads:true,
            eatRecursive:true,
            growGraphWithDrop:false,
            includeCavities:true,
            omnidirectionalBite:false,
            orthoBiteOnly:true,
            orthoDecayOnly:true,
            orthoDropOnly:true,
            orthoEatOnly:false,
            overlapSelf:false,
            takeBodiesFromHeads:true,
            firstPlayer:0,
            maxBiteReach:3,
            maxSizeReference:Std.int(400 * 0.7),
            minBiteReach:1,
            numPlayers:4,
            pieceHatSize:5,
            startingSwaps:5,
            startingBites:5,
            swapBoost:1,
            swapPeriod:4,
            maxSwaps:10,
            biteBoost:1,
            bitePeriod:3,
            maxBites:10,
            maxSkips:3,
            initGrid:null,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
        };
    }

    public static function makeRuleConfig(config:ScourgeConfig, rand:Void->Float):Map<String, Dynamic> {
        var ruleConfig:Map<String, Dynamic> = [
            BUILD_GLOBALS => makeBuildStateConfig(config),
            BUILD_PLAYERS => makeBuildPlayersConfig(config),
            BUILD_BOARD => makeBuildBoardConfig(config),
            EAT_CELLS => makeEatCellsConfig(config),
            DECAY => makeDecayConfig(config),
            DROP_PIECE => makeDropPieceConfig(config),
            REPLENISH => makeReplenishConfig(config),

            END_TURN => null,
            RESET_FRESHNESS => null,
            FORFEIT => null,
            KILL_HEADLESS_BODY => null,
            ONE_LIVING_PLAYER => null,
        ];

        if (!config.allowAllPieces) ruleConfig.set(PICK_PIECE, makePickPieceConfig(config, rand));
        if (config.includeCavities) ruleConfig.set(CAVITY, null);
        if (!config.allowAllPieces && config.maxSwaps > 0) ruleConfig.set(SWAP_PIECE, makeSwapConfig(config));
        if (config.maxBites > 0) ruleConfig.set(BITE, makeBiteConfig(config));
        if (config.maxSkips > 0) ruleConfig.set(STALEMATE, makeSkipsExhaustedConfig(config));

        return ruleConfig;
    }

    public static function makeCombinedRuleCfg(config:ScourgeConfig):Map<String, Array<String>> {

        var combinedRuleConfig:Map<String, Array<String>> = [
            CLEAN_UP => [DECAY, KILL_HEADLESS_BODY, ONE_LIVING_PLAYER, RESET_FRESHNESS],
            WRAP_UP  => [END_TURN, REPLENISH],

            START_ACTION => [CLEAN_UP],
            QUIT_ACTION  => [FORFEIT, CLEAN_UP, WRAP_UP],
            DROP_ACTION  => [DROP_PIECE, EAT_CELLS, CLEAN_UP, WRAP_UP],
        ];

        if (config.includeCavities) combinedRuleConfig[CLEAN_UP].insert(1, CAVITY);
        if (!config.allowAllPieces && config.maxSwaps > 0) combinedRuleConfig[SWAP_ACTION] = [SWAP_PIECE, PICK_PIECE];
        if (config.maxBites > 0) combinedRuleConfig[BITE_ACTION] = [BITE, CLEAN_UP];
        if (config.maxSkips > 0) combinedRuleConfig[DROP_ACTION].push(STALEMATE);

        if (!config.allowAllPieces) {
            combinedRuleConfig[START_ACTION].push(PICK_PIECE);
            combinedRuleConfig[WRAP_UP].push(PICK_PIECE);
        }

        return combinedRuleConfig;
    }

    inline static function makeBuildStateConfig(config:ScourgeConfig) {
        return {
            firstPlayer:config.firstPlayer,
        };
    }

    inline static function makeBuildPlayersConfig(config:ScourgeConfig) {
        return {
            numPlayers:config.numPlayers,
        };
    }

    inline static function makeBuildBoardConfig(config:ScourgeConfig) {
        return {
            circular:config.circular,
            initGrid:config.initGrid,
        };
    }

    inline static function makeEatCellsConfig(config:ScourgeConfig) {
        return {
            recursive:config.eatRecursive,
            eatHeads:config.eatHeads,
            takeBodiesFromHeads:config.takeBodiesFromHeads,
            orthoOnly:config.orthoEatOnly,
        };
    }

    inline static function makeDecayConfig(config:ScourgeConfig) {
        return {
            orthoOnly:config.orthoDecayOnly,
        };
    }

    inline static function makePickPieceConfig(config:ScourgeConfig, randomFunction:Void->Float) {
        return {
            pieceTableIDs:config.pieceTableIDs,
            allowFlipping:config.allowFlipping,
            allowRotating:config.allowRotating,
            hatSize:config.pieceHatSize,
            randomFunction:randomFunction,
            pieces:config.pieces,
        };
    }

    inline static function makeDropPieceConfig(config:ScourgeConfig) {
        return {
            overlapSelf:config.overlapSelf,
            pieceTableIDs:config.pieceTableIDs,
            allowFlipping:config.allowFlipping,
            allowRotating:config.allowRotating,
            growGraph:config.growGraphWithDrop,
            allowNowhere:config.allowNowhereDrop,
            allowPiecePick:config.allowAllPieces,
            orthoOnly:config.orthoDropOnly,
            diagOnly:config.diagDropOnly,
            pieces:config.pieces,
        };
    }

    inline static function makeBiteConfig(config:ScourgeConfig) {
        return {
            minReach:config.minBiteReach,
            maxReach:config.maxBiteReach,
            maxSizeReference:config.maxSizeReference,
            baseReachOnThickness:config.baseBiteReachOnThickness,
            omnidirectional:config.omnidirectionalBite,
            biteThroughCavities:config.biteThroughCavities,
            biteHeads:config.biteHeads,
            orthoOnly:config.orthoBiteOnly,
            startingBites:config.startingBites,
        };
    }

    inline static function makeSwapConfig(config:ScourgeConfig) {
        return {
            startingSwaps:config.startingSwaps,
        };
    }

    inline static function makeSkipsExhaustedConfig(config:ScourgeConfig) {
        return {
            maxSkips:config.maxSkips,
        };
    }

    inline static function makeReplenishConfig(config:ScourgeConfig) {
        var stateReplenishProperties:Array<ReplenishableConfig> = [];

        if (config.maxSwaps > 0) stateReplenishProperties.push({
            prop:SwapAspect.NUM_SWAPS,
            amount:config.swapBoost,
            period:config.swapPeriod,
            maxAmount:config.maxSwaps,
        });

        if (config.maxBites > 0) stateReplenishProperties.push({
            prop:BiteAspect.NUM_BITES,
            amount:config.biteBoost,
            period:config.bitePeriod,
            maxAmount:config.maxBites,
        });

        return {
            globalProperties:stateReplenishProperties,
            playerProperties:[],
            nodeProperties:[],
        };
    }

    inline static function makeAlertConfig(alertFunction:Void->Void) {
        return {
            alertFunction:alertFunction,
        };
    }
}
