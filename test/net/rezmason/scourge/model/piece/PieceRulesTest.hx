package net.rezmason.scourge.model.piece;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Aspect;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.meta.FreshnessAspect;
import net.rezmason.scourge.model.piece.PieceAspect;
import net.rezmason.scourge.model.piece.DropPieceRule;
import net.rezmason.scourge.model.piece.PickPieceRule;
import net.rezmason.scourge.model.piece.SwapPieceRule;
import net.rezmason.scourge.model.test.TestPieceRule;
import net.rezmason.scourge.tools.Resource;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Pointers;

class PieceRulesTest extends ScourgeRuleTest
{
    private static var PIECE_SIZE:Int = 4;

    #if TIME_TESTS
    var time:Float;
    #end
    var pieces:Pieces;

    @Before
    public function setup():Void {
        #if TIME_TESTS
        time = massive.munit.util.Timer.stamp();
        #end
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    @After
    public function tearDown():Void {
        #if TIME_TESTS
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
        #end
    }

    // An L/J block has nine neighbor cells.
    // Reflection allowed   rotation allowed    move count
    // N                    N                   9
    // Y                    N                   18
    // N                    Y                   36
    // Y                    Y                   72

    @Test
    public function placePieceOrtho():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(72, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        dropRule.chooseMove();

        VisualAssert.assert('empty petri, L piece on top left extending up', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function placePieceOrthoNoSpace():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 4), // 'I block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.frozenPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(0, moves.length); // The board has no room for the piece! There should be no moves.

        var numWalls:Int = ~/([^X])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(160, numWalls); // 160 walls cells

        VisualAssert.assert('full petri', state.spitBoard(plan));
    }

    @Test
    public function placePieceOrthoNoFlipping():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(36, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceOrthoNoSpinning():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(18, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceOrthoNoSpinningOrFlipping():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(9, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceOrthoSelf():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:true,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(9 + 4, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceOrthoAllowNowhere():Void {

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:true,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(1, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        dropRule.chooseMove();

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell still for player 0
    }

    @Test
    public function pickPieceTest():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:true,
            hatSize:hatSize,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onGlobal(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        for (ike in 0...hatSize * 2) {
            Assert.areEqual(1, pickPieceRule.moves.length);
            Assert.areEqual(pieceTableIDs.length - (ike % hatSize), pickPieceRule.quantumMoves.length);
            pickPieceRule.chooseMove();
            Assert.areEqual(pieceTableIDs[ike % hatSize], state.global[pieceTableID_]);
            state.global[pieceTableID_] =  Aspect.NULL;
            pickPieceRule.update();
        }
    }

    @Test
    public function pickPieceTestNoFlipping():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:false,
            allowRotating:true,
            hatSize:hatSize,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onGlobal(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.moves.length);
        Assert.areEqual(12, pickPieceRule.quantumMoves.length);
    }

    @Test
    public function pickPieceTestNoSpinning():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:false,
            hatSize:hatSize,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onGlobal(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.moves.length);
        Assert.areEqual(23, pickPieceRule.quantumMoves.length);
    }

    @Test
    public function placePieceDiag():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:false,
            diagOnly:true,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(40, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceOrthoDiag():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:false,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.flowerPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(33, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(5, numCells); // 5 cells for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(5 + 4, numCells); // 9 cells for player 0
    }

    @Test
    public function swapPieceTest():Void {
        var swapPieceCfg:SwapPieceConfig = {
            startingSwaps:5,
        };
        var swapPieceRule:SwapPieceRule = new SwapPieceRule();
        swapPieceRule.init(swapPieceCfg);
        makeState([swapPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onGlobal(PieceAspect.PIECE_TABLE_ID);

        state.global[pieceTableID_] =  0;

        swapPieceRule.update();

        for (ike in 0...swapPieceCfg.startingSwaps) {
            Assert.areEqual(1, swapPieceRule.moves.length);
            swapPieceRule.chooseMove();
            swapPieceRule.update();
            Assert.areEqual(0, swapPieceRule.moves.length);
            state.global[pieceTableID_] =  0;
            swapPieceRule.update();
        }

        Assert.areEqual(0, swapPieceRule.moves.length);
    }
}