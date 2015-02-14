package net.rezmason.scourge.game.body;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.DecayRule;
import net.rezmason.scourge.game.body.OwnershipAspect;

using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.Pointers;

class DecayRuleTest extends ScourgeRuleTest
{
    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end

    @Test
    public function decayScourgeRuleTest():Void {

        var params:DecayParams = {
            decayOrthogonallyOnly:true,
        };
        var decayRule:DecayRule = new DecayRule();
        decayRule.init(params);
        makeState([decayRule], 1, TestBoards.loosePetri);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(17, numCells); // 17 cells for player 0

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        decayRule.chooseMove();

        VisualAssert.assert('Empty petri, disconnected region gone', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // only one cell for player 0

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        Assert.areEqual(numCells, totalArea);
    }

    @Test
    public function decayDiagScourgeRuleTest():Void {

        var params:DecayParams = {
            decayOrthogonallyOnly:false,
        };
        var decayRule:DecayRule = new DecayRule();
        decayRule.init(params);
        makeState([decayRule], 1, TestBoards.loosePetri);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var head:BoardLocus = state.loci[state.players[0][head_]];
        var bump:BoardLocus = head.nw();

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);
        bump.value[occupier_] = 0;
        bump.value[isFilled_] = Aspect.TRUE;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(18, numCells); // 18 cells for player 0

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        decayRule.chooseMove();

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(18, numCells); // 18 cells for player 0
    }
}