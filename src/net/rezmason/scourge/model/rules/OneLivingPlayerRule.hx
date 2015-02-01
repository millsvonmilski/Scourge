package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using net.rezmason.utils.Pointers;

class OneLivingPlayerRule extends RopesRule<Void> {

    @player(BodyAspect.HEAD) var head_;
    @global(WinAspect.WINNER) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override private function _chooseMove(choice:Int):Void {

        var playersWithHeads:Array<Int> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != NULL) playersWithHeads.push(getID(player));
        }

        if (playersWithHeads.length == 1) state.global[winner_] = playersWithHeads.pop();
    }
}

