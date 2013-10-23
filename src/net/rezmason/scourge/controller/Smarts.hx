package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;

class Smarts {

    private var actionIndicesByAction:Map<String, Int>;

    public function new():Void {}

    public function init(game:Game):Void {
        actionIndicesByAction = new Map();
        for (ike in 0...game.actionIDs.length) actionIndicesByAction[game.actionIDs[ike]] = ike;
    }

    public function choose(game:Game):GameEventType {
        throw "Override this.";
        return null;
    }
}