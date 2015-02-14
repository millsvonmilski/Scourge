package net.rezmason.praxis.bot;

import haxe.Timer;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.utils.Zig;

class BotSystem extends PlayerSystem {

    private var botsByIndex:Map<Int, BotPlayer>;
    private var numBots:Int;
    private var random:Void->Float;

    public function new(usesSignals:Bool, random:Void->Float):Void {
        super(usesSignals, true);

        botsByIndex = new Map();
        numBots = 0;
        this.random = random;
    }

    public function createPlayer(index:Int, smarts:Smarts, period:Int):IPlayer {
        var bot:BotPlayer = new BotPlayer(index, smarts, period);
        bot.playSignal.add(onBotSignal.bind(index));
        botsByIndex[index] = bot;
        numBots++;
        return bot;
    }

    private function onBotSignal(senderIndex:Int, event:GameEvent):Void {
        if (!game.hasBegun || senderIndex == game.currentPlayer) processGameEvent(event);
    }

    override private function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        for (bot in botsByIndex) if (bot.smarts != null) bot.smarts.init(game, config, bot.index, random);
    }

    override private function play():Void beat(choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;

    private function choose():Void {
        var player:BotPlayer = currentPlayer();
        var playerSmarts:Smarts = player.smarts;
        var event:GameEvent = playerSmarts.choose();
        // trace('${game.currentPlayer} $event');
        player.playSignal.dispatch(event);
    }

    private function beat(cbk:Void->Void):Void {
        #if neko
            cbk();
        #else
            var period:Int = 10;
            if (game.hasBegun) period = currentPlayer().period;
            var timer:Timer = new Timer(period);
            timer.run = onBeat.bind(timer, cbk);
        #end
    }

    private function onBeat(timer:Timer, cbk:Void->Void):Void {
        #if !neko
            timer.stop();
            if (game.hasBegun) cbk();
        #end
    }

    private inline function currentPlayer():BotPlayer return botsByIndex[game.currentPlayer];
}