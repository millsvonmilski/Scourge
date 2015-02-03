package net.rezmason.scourge.model.test;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.test.TestAspect;

class TestRule extends Rule {

    @extra(TestAspect.VALUE_1) var extraVal_:AspectPtr;
    @node(TestAspect.VALUE_1) var nodeVal_:AspectPtr;
    @player(TestAspect.VALUE_1) var playerVal_:AspectPtr;
    @global(TestAspect.VALUE_1) var stateVal_:AspectPtr;
}
