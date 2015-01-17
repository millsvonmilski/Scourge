package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessBodyRule extends RopesRule<Void> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    override private function _chooseMove(choice:Int):Void {

        // trace(state.spitBoard(plan));

        var maxFreshness:Int = state.globals[maxFreshness_] + 1;

        // Check each player to see if they still have head nodes

        for (player in eachPlayer()) {
            var playerID:Int = getID(player);

            var head:Int = player[head_];

            if (head != Aspect.NULL) {
                var bodyFirst:Int = player[bodyFirst_];
                var playerHead:AspectSet = getNode(head);
                if (playerHead[occupier_] != playerID || playerHead[isFilled_] == Aspect.FALSE) {

                    // Destroy the head and body

                    player[head_] = Aspect.NULL;
                    var bodyNode:AspectSet = getNode(bodyFirst);
                    for (node in bodyNode.listToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
                    player[bodyFirst_] = Aspect.NULL;
                }
            }

        }

        state.globals[maxFreshness_] = maxFreshness;

        // trace(state.spitBoard(plan));
        // trace('---');
    }

    function killCell(node:AspectSet, maxFreshness:Int):Void {
        node[isFilled_] = Aspect.FALSE;
        node[occupier_] = Aspect.NULL;
        node[freshness_] = maxFreshness;

        node.removeSet(state.nodes, bodyNext_, bodyPrev_);
    }
}

