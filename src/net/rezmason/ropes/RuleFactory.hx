package net.rezmason.ropes;

import haxe.ds.ArraySort;
import net.rezmason.ropes.Types;
import net.rezmason.utils.StringSort;

using Lambda;
using Type;

class RuleFactory {

    public static function makeBasicRules(ruleDefs:Map<String, Class<Rule>>, cfg:Dynamic):Map<String, Rule> {

        var rules:Map<String, Rule> = new Map();

        if (cfg != null) {
            var cfgFields:Array<String> = Reflect.fields(cfg);
            ArraySort.sort(cfgFields, StringSort.sort);
            for (field in cfgFields) {
                //var ruleDef:Class<Rule> = cast ruleDefs[field].resolveClass();
                var ruleDef:Class<Rule> = ruleDefs[field];
                if (ruleDef == null) {
                    trace('Rule not found: $field');
                } else {
                    var args:Array<Dynamic> = [Reflect.field(cfg, field)];
                    args.remove(null);
                    rules[field] = ruleDef.createInstance(args);
                }
            }
        }
        return rules;
    }

    public static function combineRules(cfg:Map<String, Array<String>>, basicRules:Map<String, Rule>):Map<String, Rule> {
        var combinedRules:Map<String, Rule> = new Map();

        if (cfg != null) {

            var ruleStack:Array<String> = [];

            function makeJointRule(key:String):Rule {
                ruleStack.push(key);
                var rules:Array<Rule> = [];
                var ruleNames:Array<String> = cfg[key];
                for (ruleName in ruleNames) {
                    if (ruleName == key) trace('Joint rule $key cannot contain itself.');
                    else if (ruleStack.has(ruleName)) trace('Cyclical joint rule definition: $key and $ruleName');
                    else if (basicRules.exists(ruleName)) rules.push(basicRules[ruleName]);
                    else if (combinedRules.exists(ruleName)) rules.push(combinedRules[ruleName]);
                    else if (cfg.exists(ruleName)) rules.push(makeJointRule(ruleName));
                    else trace('Rule not found: $ruleName');
                }
                var jointRule:Rule = new JointRule(rules);
                combinedRules[key] = jointRule;
                ruleStack.pop();
                return jointRule;
            }

            var cfgKeys:Array<String> = [];
            for (key in cfg.keys()) cfgKeys.push(key);

            ArraySort.sort(cfgKeys, StringSort.sort);
            for (key in cfgKeys) {
                if (basicRules.exists(key)) trace('Basic rule already exists with name: $key');
                else if (!combinedRules.exists(key)) makeJointRule(key);
            }
        }

        return combinedRules;
    }
}

/*
    Give each field a status: unbuilt, building, built
    Populate a Map<String, RuleConfigStatus> and check it
*/
