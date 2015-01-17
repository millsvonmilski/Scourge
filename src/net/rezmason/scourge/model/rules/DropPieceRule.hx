package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.GridDirection.*;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

typedef DropPieceConfig = {
    public var overlapSelf:Bool;
    public var pieceTableIDs:Array<Int>;
    public var allowFlipping:Bool;
    public var allowRotating:Bool;
    public var growGraph:Bool;
    public var allowNowhere:Bool;
    public var allowPiecePick:Bool; // if true, nothing in the game itself is left to chance
    public var orthoOnly:Bool;
    public var diagOnly:Bool;
    public var pieces:Pieces;
}

typedef DropPieceMove = {>Move,
    var targetNode:Int;
    var numAddedNodes:Int;
    var addedNodes:Array<Int>;
    var pieceID:Int;
    var rotation:Int;
    var reflection:Int;
    var coord:IntCoord;
    var duplicate:Bool;
}

class DropPieceRule extends RopesRule<DropPieceConfig> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(PlyAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var nowhereMove:DropPieceMove = makeMove();
    private var movePool:Array<DropPieceMove> = [];
    private var allMoves:Array<DropPieceMove> = [];

    override private function _update():Void {

        var dropMoves:Array<DropPieceMove> = [];

        // This allows the place-piece function to behave like a skip function
        // Setting this to false also forces players to forfeit if they can't place a piece
        if (config.allowNowhere) dropMoves.push(cast nowhereMove);

        var pieceIDs:Array<Int> = [];
        if (config.allowPiecePick) for (pieceID in config.pieceTableIDs) pieceIDs.push(pieceID);
        else if (state.globals[pieceTableID_] != Aspect.NULL) pieceIDs.push(state.globals[pieceTableID_]);

        // get current player head
        var currentPlayer:Int = state.globals[currentPlayer_];
        var bodyNode:AspectSet = getNode(getPlayer(currentPlayer)[bodyFirst_]);

        // Find edge nodes of current player
        var edgeNodes:Array<AspectSet> = bodyNode.listToArray(state.nodes, bodyNext_).filter(hasFreeEdge);

        var pieceReflection:Int = state.globals[pieceReflection_];
        var pieceRotation:Int = state.globals[pieceRotation_];

        for (pieceID in pieceIDs) {

            var freePiece:FreePiece = config.pieces.getPieceById(pieceID);

            // For each allowed reflection,
            var allowedReflectionIndex:Int = pieceReflection % freePiece.numReflections;
            for (reflectionIndex in 0...freePiece.numReflections) {

                if (!config.allowFlipping && reflectionIndex != allowedReflectionIndex) continue;
                
                // For each allowed rotation,
                var allowedRotationIndex:Int = pieceRotation % freePiece.numRotations;

                for (rotationIndex in 0...freePiece.numRotations) {

                    if (!config.allowRotating && rotationIndex != allowedRotationIndex) continue;
                    var piece:Piece = freePiece.getPiece(reflectionIndex, rotationIndex);

                    // For each edge node,
                    for (node in edgeNodes) {

                        // Generate the piece's footprint

                        var footprint = piece.footprint(config.overlapSelf, !config.diagOnly, !config.orthoOnly);

                        // Using each footprint coord as a home coord (aka the point of connection),
                        for (homeCoord in footprint) {

                            // Is the piece's body clear?

                            var valid:Bool = true;

                            var numAddedNodes:Int = 0;
                            var addedNodes:Array<Int> = [];

                            for (coord in piece.cells) {
                                var nodeAtCoord:AspectSet = walkLocus(getNodeLocus(node), coord, homeCoord).value;
                                addedNodes.push(getID(nodeAtCoord));
                                numAddedNodes++;
                                var occupier:Int = nodeAtCoord[occupier_];
                                var isFilled:Int = nodeAtCoord[isFilled_];

                                if (isFilled == Aspect.TRUE && !(config.overlapSelf && occupier == currentPlayer)) {
                                    valid = false;
                                    break;
                                }
                            }

                            if (valid) {
                                var dropMove:DropPieceMove = getMove();
                                dropMove.targetNode = getID(node);
                                dropMove.coord = homeCoord;
                                dropMove.pieceID = pieceID;
                                dropMove.rotation = rotationIndex;
                                dropMove.reflection = reflectionIndex;
                                dropMove.id = dropMoves.length;
                                dropMove.numAddedNodes = numAddedNodes;
                                dropMove.addedNodes = addedNodes;
                                dropMove.duplicate = false;
                                dropMoves.push(dropMove);
                            }
                        }
                    }
                }
            }
        }

        // We find and mark duplicate moves, to help AI players
        for (ike in 0...dropMoves.length) {
            var dropMove:DropPieceMove = dropMoves[ike];
            if (dropMove.duplicate) continue;
            for (jen in ike + 1...dropMoves.length) {
                if (dropMoves[jen].duplicate) continue;
                dropMoves[jen].duplicate = movesAreEqual(dropMove, dropMoves[jen]);
            }
        }

        moves = cast dropMoves;
    }

    inline function getMove():DropPieceMove {
        var move:DropPieceMove = movePool.pop();
        if (move == null) {
            move = makeMove();
            allMoves.push(move);
        }
        return move;
    }

    inline static function makeMove():DropPieceMove {
        return {
            id:-1,
            targetNode:Aspect.NULL,
            pieceID:-1,
            reflection:-1,
            rotation:-1,
            numAddedNodes:0,
            addedNodes:null,
            coord:null,
            duplicate:false,
        };
    }

    override private function _chooseMove(choice:Int):Void {

        var move:DropPieceMove = cast moves[choice];

        var currentPlayer:Int = state.globals[currentPlayer_];
        var player:AspectSet = getPlayer(currentPlayer);

        if (move.targetNode != Aspect.NULL) {
            var freePiece:FreePiece = config.pieces.getPieceById(move.pieceID);
            var targetLocus:BoardLocus = getLocus(move.targetNode);
            var coords:Array<IntCoord> = freePiece.getPiece(move.reflection, move.rotation).cells;
            var homeCoord:IntCoord = move.coord;
            var maxFreshness:Int = state.globals[maxFreshness_] + 1;

            var bodyNode:AspectSet = getNode(getPlayer(currentPlayer)[bodyFirst_]);

            for (coord in coords) bodyNode = fillAndOccupyCell(walkLocus(targetLocus, coord, homeCoord).value, currentPlayer, maxFreshness, bodyNode);
            player[bodyFirst_] = getID(bodyNode);

            state.globals[maxFreshness_] = maxFreshness;

            player[numConsecutiveSkips_] = 0;
        } else {
            player[numConsecutiveSkips_] = player[numConsecutiveSkips_] + 1;
        }

        state.globals[pieceTableID_] = Aspect.NULL;
        onSignal();
    }

    override private function _collectMoves():Void movePool = allMoves.copy();

    inline function hasFreeEdge(node:AspectSet):Bool {
        var exists:Bool = false;

        for (neighbor in neighborsFor(getNodeLocus(node), config.orthoOnly)) {
            if (neighbor.value[isFilled_] == Aspect.FALSE) {
                exists = true;
                break;
            }
        }

        return exists;
    }

    inline function movesAreEqual(move1:DropPieceMove, move2:DropPieceMove):Bool {
        var val:Bool = true;
        //if (move1.targetNode != move2.targetNode) val = false;
        if (move1.numAddedNodes != move2.numAddedNodes) {
            val = false;
        } else {
            for (addedNodeID1 in move1.addedNodes) {
                for (addedNodeID2 in move2.addedNodes) {
                    if (addedNodeID1 == addedNodeID2) {
                        val = false;
                        break;
                    }
                    if (!val) break;
                }
            }
        }
        return val;
    }

    inline function fillAndOccupyCell(me:AspectSet, currentPlayer:Int, maxFreshness, bodyNode:AspectSet):AspectSet {
        if (me[occupier_] != currentPlayer || me[isFilled_] == Aspect.FALSE) me[freshness_] = maxFreshness;
        me[occupier_] = currentPlayer;
        me[isFilled_] = Aspect.TRUE;
        return bodyNode.addSet(me, state.nodes, ident_, bodyNext_, bodyPrev_);
    }

    // A works-for-now function for translating piece coords into nodes accessible from a given starting point
    inline function walkLocus(locus:BoardLocus, fromCoord:IntCoord, toCoord:IntCoord):BoardLocus {
        var dn:Int = 0;
        var dw:Int = 0;
        var de:Int = toCoord.x - fromCoord.x;
        var ds:Int = toCoord.y - fromCoord.y;

        if (de < 0) {
            dw = -de;
            de = 0;
        }

        if (ds < 0) {
            dn = -ds;
            ds = 0;
        }

        return locus.run(N, dn).run(S, ds).run(E, de).run(W, dw);
    }

    inline function neighborsFor(locus:BoardLocus, ortho:Bool):Array<BoardLocus> {
        return ortho ? locus.orthoNeighbors() : locus.neighbors;
    }
}
