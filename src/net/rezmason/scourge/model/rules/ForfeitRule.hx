package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class ForfeitRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;
    var bodyPrev_:AspectPtr;

    public function new():Void {
        super();

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            BodyAspect.BODY_NEXT,
            BodyAspect.BODY_PREV,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        bodyFirst_ = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        bodyPrev_ = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var player:AspectSet = state.players[currentPlayer];
        var bodyNode:BoardNode = state.nodes[history.get(player.at(bodyFirst_))];

        for (node in bodyNode.boardListToArray(state, bodyNext_)) killCell(node);
        history.set(player.at(bodyFirst_), Aspect.NULL);
        history.set(player.at(head_), Aspect.NULL);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == Aspect.FALSE) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    function killCell(node:BoardNode):Void {
        history.set(node.value.at(isFilled_), Aspect.FALSE);
        history.set(node.value.at(occupier_), Aspect.NULL);
        node.removeNode(state, bodyNext_, bodyPrev_);
    }
}

