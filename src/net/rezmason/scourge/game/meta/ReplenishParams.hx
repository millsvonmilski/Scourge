package net.rezmason.scourge.game.meta;

typedef ReplenishParams = {
    var globalProperties:Map<String, ReplenishableProperty>;
    var playerProperties:Map<String, ReplenishableProperty>;
    var nodeProperties:Map<String, ReplenishableProperty>;
}