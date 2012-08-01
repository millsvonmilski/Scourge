package net.rezmason.scourge.model;

class BoardStateConfig {

    public var playerGenes(default, null):Array<String>;
    public var circular:Bool;
    public var rules(default, null):Array<Rule>;

    public function new():Void {
        rules = [];
        playerGenes = [];
    }
}
