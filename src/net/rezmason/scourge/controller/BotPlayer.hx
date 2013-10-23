package net.rezmason.scourge.controller;

import msignal.Signal;
import net.rezmason.scourge.controller.Types;

@:allow(net.rezmason.scourge.controller.BotSystem)
class BotPlayer implements Player {

    public var index(default, null):Int;
    public var ready(default, null):Bool;

    private var smarts:Smarts;
    private var period:Int;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Signal1<GameEvent>;

    private function new(signal:Signal2<Int, GameEvent>, index:Int, smarts:Smarts, period:Int):Void {
        this.index = index;
        this.smarts = smarts;
        this.period = period;

        updateSignal = new Signal1();
        updateSignal.add(signal.dispatch.bind(index));
    }

}