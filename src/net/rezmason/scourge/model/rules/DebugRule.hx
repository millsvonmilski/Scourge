package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Rule;
// import net.rezmason.scourge.model.aspects.BodyAspect;
// using net.rezmason.scourge.model.BoardUtils;

class DebugRule extends Rule {

    // @player(BodyAspect.BODY_FIRST) var bodyFirst_;

    override public function _init(cfg:Dynamic):Void { moves.push({id:0}); }

    override private function _chooseMove(choice:Int):Void {
        // trace(state.spitBoard(plan));
    }
}

