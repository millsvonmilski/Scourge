package net.rezmason.scourge.model;

import net.rezmason.ropes.Rule;
import net.rezmason.ropes.RuleFactory;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.Types;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using Lambda;
using Reflect;
using net.rezmason.ropes.StatePlan;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.Pointers;

class Game {

    public var actionIDs(getActionList, null):Array<String>;
    public var revision(getRevision, never):Int;
    public var currentPlayer(getCurrentPlayer, never):Int;
    public var winner(getWinner, never):Int;
    public var state(getState, null):State;
    public var plan(default, null):StatePlan;
    public var hasBegun(getHasBegun, null):Bool;
    public var checksum(getChecksum, null):Int;

    var historian:StateHistorian;
    var actions:Array<Rule>;
    var defaultActions:Array<Rule>;
    var winner_:AspectPtr;
    var currentPlayer_:AspectPtr;

    public function new():Void { historian = new StateHistorian(); }

    public function begin(config:ScourgeConfig, randomFunction:Void->Float, annotateFunc:String->Dynamic = null, savedState:SavedState = null):Int {

        if (hasBegun)
            throw "The game has already begun; it cannot begin again until you end it.";

        // Build the game from the config

        var ruleConfig:Dynamic = ScourgeConfigFactory.makeRuleConfig(config, randomFunction, historian.history, historian.historyState);
        var basicRules:Hash<Rule> = RuleFactory.makeBasicRules(ScourgeConfigFactory.ruleDefs, ruleConfig);
        var combinedConfig:Dynamic<Array<String>> = ScourgeConfigFactory.makeCombinedRuleCfg(config);

        if (annotateFunc != null) addAnnotations(annotateFunc, basicRules, combinedConfig);

        var combinedRules:Hash<Rule> = RuleFactory.combineRules(combinedConfig, basicRules);

        // Find the demiurgic rules

        var basicRulesArray:Array<Rule> = [];
        var demiurgicRules:Hash<Rule> = new Hash<Rule>();
        var rules:Array<Rule> = [];
        for (key in basicRules.keys().a2z()) {
            var rule:Rule = basicRules.get(key);
            rules.push(rule);

            if (rule.demiurgic) demiurgicRules.set(key, rule);
            else basicRulesArray.push(rule);
        }

        // Plan the state

        var state:State = historian.state;
        plan = new StatePlanner().planState(state, rules);

        // Prime the rules with the state and plan

        // demiurgic ones go first
        for (key in ScourgeConfigFactory.makeDemiurgicRuleList()) demiurgicRules.get(key).prime(state, plan);
        for (rule in basicRulesArray) rule.prime(state, plan);

        // Grab some aspect pointers so we can quickly evaluate the state

        winner_ = plan.onState(WinAspect.WINNER);
        currentPlayer_ = plan.onState(PlyAspect.CURRENT_PLAYER);

        // Find the player actions

        actionIDs = ScourgeConfigFactory.makeActionList(config);
        actions = [];
        for (actionID in actionIDs) actions.push(combinedRules.get(actionID));

        // Find the default actions

        var defaultActionIDs:Array<String> = ScourgeConfigFactory.makeDefaultActionList();
        defaultActions = [];
        for (defaultActionID in defaultActionIDs) defaultActions.push(combinedRules.get(defaultActionID));

        // Find the start action and make it happen

        if (savedState != null) {
            historian.load(savedState);
        } else {
            historian.key.lock();
            var startAction = combinedRules.get(ScourgeConfigFactory.makeStartAction());
            startAction.update();
            historian.key.unlock();
            startAction.chooseOption();
        }
        /*
        var startAction = combinedRules.get(ScourgeConfigFactory.makeStartAction());
        startAction.update();
        startAction.chooseOption();
        */

        updateAll();

        return historian.history.revision;
    }

    public function save():SavedState { return historian.save(); }

    public function end():Void {

        if (!hasBegun)
            throw "The game cannot end, because it hasn't begun.";

        historian.reset();
        actions = null;
        actionIDs = null;
    }

    public function forget():Void { historian.history.forget(); }

    public function getOptions():Array<Array<Option>> {
        var allOptions:Array<Array<Option>> = [];
        for (action in actions) allOptions.push(action.options);
        return allOptions;
    }

    public function getQuantumOptions():Array<Array<Option>> {
        var allQuantumOptions:Array<Array<Option>> = [];
        for (action in actions) allQuantumOptions.push(action.quantumOptions);
        return allQuantumOptions;
    }

    public function chooseOption(actionIndex:Int, optionIndex:Int = 0, isQuantum:Bool = false):Int {
        if (actionIndex < 0 || actionIndex > actionIDs.length - 1)
            throw "Invalid action";

        var action:Rule = actions[actionIndex];

        if (optionIndex < 0 || optionIndex > action.options.length - 1)
            throw "Invalid option for action " + actionIDs[actionIndex];

        if (isQuantum) action.chooseQuantumOption(optionIndex);
        else action.chooseOption(optionIndex);

        updateAll();
        return pushHist();
    }

    public function chooseDefaultOption():Int {
        for (action in defaultActions) {
            if (action.options.length > 0) {
                action.chooseOption();
                break;
            }
        }
        updateAll();
        return pushHist();
    }

    public function rewind(revision:Int):Void {
        historian.history.revert(revision);
        historian.read();
        updateAll();
    }

    public function spitBoard():String {
        return state.spitBoard(plan);
    }

    private function pushHist():Int {
        historian.write();
        return historian.history.commit();
    }

    private function updateAll():Void {
        historian.key.lock();
        for (action in actions) action.update();
        historian.key.unlock();
    }

    private function addAnnotations(annotateFunc:String->Void, basicRules:Hash<Rule>, cfg:Dynamic<Array<String>>):Void {
        var cfgFields:Array<String> = cfg.fields();
        for (field in cfgFields) {
            var ruleFields:Array<String> = cfg.field(field);
            var lacedRuleFields:Array<String> = [];

            for (ruleField in ruleFields) {
                lacedRuleFields.push(ruleField);
                var lacedField:String = "annotate_" + ruleField;
                lacedRuleFields.push(lacedField);
                basicRules.set(lacedField, new AnnotateRule(function() annotateFunc(ruleField)));
            }

            cfg.setField(field, lacedRuleFields);
        }
    }

    private function getActionList():Array<String> { return actionIDs.copy(); }

    private function getRevision():Int { return historian.history.revision; }

    private function getCurrentPlayer():Int { return historian.state.aspects.at(currentPlayer_); }

    private function getWinner():Int { return historian.state.aspects.at(winner_); }

    private function getState():State { return historian.state; }

    private function getHasBegun():Bool { return actions != null; }

    private function getChecksum():Int { return historian.history.getChecksum(); }
}
