package net.rezmason.scourge.game.piece;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.scourge.game.piece.DropPieceActor;
import net.rezmason.scourge.game.piece.PickPieceActor;
import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.scourge.game.piece.SwapPieceActor;
import net.rezmason.scourge.game.test.TestPieceActor;
import net.rezmason.utils.openfl.Resource;

using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.pointers.Pointers;

class PieceRulesTest extends ScourgeRuleTest
{
    private static var PIECE_SIZE:Int = 4;

    #if TIME_TESTS
    var time:Float;
    #end
    var pieceLib:PieceLibrary;
    var pieceIDs:Array<String>;

    @Before
    public function setup():Void {
        #if TIME_TESTS
        time = massive.munit.util.Timer.stamp();
        #end
        pieceLib = new PieceLibrary(Resource.getString('tables/pieces.json.txt'));
        pieceIDs = [for (piece in pieceLib.getPiecesOfSize(4)) piece.id];
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:true,
            allowRotating:true,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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

        var bodyFirst_ = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_ = plan.onSpace(BodyAspect.BODY_NEXT);
        var bodyPrev_ = plan.onSpace(BodyAspect.BODY_PREV);
        var bodySpace = state.spaces[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodySpace, bodyNext_, bodyPrev_));
    }

    @Test
    public function placePieceOrthoNoSpace():Void {
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('1112211122'), // 'I block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:true,
            allowRotating:true,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:false,
            allowRotating:true,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:true,
            allowRotating:false,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:false,
            allowRotating:false,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:true,
            allowFlipping:false,
            allowRotating:false,
            allowSkipping:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:false,
            allowRotating:false,
            allowSkipping:true,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var pickPieceParams:PickPieceParams = {
            pieceIDs:pieceIDs,
            allowFlipping:true,
            allowRotating:true,
            hatSize:hatSize,
            pieceLib:pieceLib,
        };
        var pickPieceRule = TestUtils.makeRule(PickPieceBuilder, PickPieceSurveyor, PickPieceActor, pickPieceParams);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableIndex_ = plan.onGlobal(PieceAspect.PIECE_TABLE_INDEX);

        pickPieceRule.update();

        for (ike in 0...hatSize * 2) {
            Assert.areEqual(pieceIDs.length - (ike % hatSize), pickPieceRule.moves.length);
            pickPieceRule.chooseMove();
            Assert.areEqual(ike % hatSize, state.global[pieceTableIndex_]);
            state.global[pieceTableIndex_] =  Aspect.NULL;
            pickPieceRule.update();
        }
    }

    @Test
    public function pickPieceTestNoFlipping():Void {
        var pickPieceParams:PickPieceParams = {
            pieceIDs:pieceIDs,
            allowFlipping:false,
            allowRotating:true,
            hatSize:3,
            pieceLib:pieceLib,
        };
        var pickPieceRule = TestUtils.makeRule(PickPieceBuilder, PickPieceSurveyor, PickPieceActor, pickPieceParams);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);
        pickPieceRule.update();
        Assert.areEqual(7, pickPieceRule.moves.length);
    }

    @Test
    public function pickPieceTestNoSpinning():Void {
        var pickPieceParams:PickPieceParams = {
            pieceIDs:pieceIDs,
            allowFlipping:true,
            allowRotating:false,
            hatSize:3,
            pieceLib:pieceLib,
        };
        var pickPieceRule = TestUtils.makeRule(PickPieceBuilder, PickPieceSurveyor, PickPieceActor, pickPieceParams);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);
        pickPieceRule.update();
        Assert.areEqual(13, pickPieceRule.moves.length);
    }

    @Test
    public function placePieceDiag():Void {
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:true,
            allowRotating:true,
            allowSkipping:false,
            dropOrthoOnly:false,
            dropDiagOnly:true,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var testPieceParams:TestPieceParams = {
            pieceTableIndex:pieceIDs.indexOf('0122112122'), // 'L/J block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule = TestUtils.makeRule(TestPieceActor, testPieceParams);

        var dropParams:DropPieceParams = {
            dropOverlapsSelf:false,
            allowFlipping:false,
            allowRotating:false,
            allowSkipping:false,
            dropOrthoOnly:false,
            dropDiagOnly:false,
            pieceLib:pieceLib,
            pieceIDs:pieceIDs,
            allowPiecePick:false,
        };
        var dropRule = TestUtils.makeRule(DropPieceSurveyor, DropPieceActor, dropParams);
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
        var swapPieceParams:SwapPieceParams = {
            startingSwaps:5,
        };
        var swapPieceRule = TestUtils.makeRule(SwapPieceSurveyor, SwapPieceActor, swapPieceParams);
        makeState([swapPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableIndex_ = plan.onGlobal(PieceAspect.PIECE_TABLE_INDEX);

        state.global[pieceTableIndex_] =  0;

        swapPieceRule.update();

        for (ike in 0...swapPieceParams.startingSwaps) {
            Assert.areEqual(1, swapPieceRule.moves.length);
            swapPieceRule.chooseMove();
            swapPieceRule.update();
            Assert.areEqual(0, swapPieceRule.moves.length);
            state.global[pieceTableIndex_] =  0;
            swapPieceRule.update();
        }

        Assert.areEqual(0, swapPieceRule.moves.length);
    }
}
