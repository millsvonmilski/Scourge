package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class KillDisconnectedCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var option:Option = new Option();

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;

    public function new():Void {
        super();

        if (nodeReqs == null)  nodeReqs = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];

        if (playerReqs == null) playerReqs = [
            BodyAspect.HEAD,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
    }

    //override public function listStateAspectRequirements():AspectRequirements { return reqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return playerReqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return nodeReqs; }
    override public function getOptions():Array<Option> { return [option]; }

    override public function chooseOption(choice:Option):Void {
        if (choice == option) {

            // perform kill operation on state

            var nodesInPlay:Array<BoardNode> = [];

            var heads:Array<BoardNode> = [];
            for (ike in 0...state.players.length) {
                var head:Int = history.get(head_.dref(state.players[ike]));
                heads.push(state.nodes[head]);
            }

            var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
            var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

            for (candidate in candidates) if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
        }
    }

    function isCandidate(me:AspectSet, you:AspectSet):Bool {
        var occupier:Int = history.get(occupier_.dref(me));
        var isFilled:Int = history.get(isFilled_.dref(me));
        var freshness:Int = history.get(freshness_.dref(me));
        if (isFilled > 0 && occupier > -1) return true;
        else if (freshness > 0) return true;
        return false;
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(isFilled_.dref(me)) == 0) return false;
        return history.get(occupier_.dref(me)) == history.get(occupier_.dref(you));
    }

    function killCell(me:AspectSet):Void {
        history.set(occupier_.dref(me), -1);
        history.set(isFilled_.dref(me), 0);
        history.set(freshness_.dref(me), 0);
    }
}

