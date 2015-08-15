package net.rezmason.scourge.game;

import massive.munit.Assert;
import VisualAssert;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;

using net.rezmason.grid.GridUtils;

class GridUtilsTest {

    var nodeItr:Int;
    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end

    @Test
    public function rowTest():Void {
        nodeItr = 0;

        var node:Cell<Int> = makeNode();
        var first:Cell<Int> = node;
        Assert.areEqual(0, node.value);
        for (i in 1...10) node = node.attach(makeNode(), E);
        var last:Cell<Int> = node;
        Assert.areEqual(10 - 1, node.run(E).value);
        Assert.areEqual(last, first.run(E));
        Assert.areEqual(first, last.run(W));

        nodeItr = 10;
        for (n in node.walk(W)) Assert.areEqual(n.value, --nodeItr);

        var ike:Int = 0;

        for (n in last.walk(W)) ike++;
        Assert.areEqual(10, ike);

        ike = 0;
        for (n in first.walk(E)) ike++;
        Assert.areEqual(10, ike);

        Assert.areEqual(10, first.getGraphSequence().length);

        Assert.areEqual(5, first.getGraphSequence(underFiveOnly).length);
    }

    function underFiveOnly(val:Int, connection:Int):Bool { return val < 5; }

    function makeNode():Cell<Int> {
        var node:Cell<Int> = new Cell<Int>(nodeItr, nodeItr);
        nodeItr++;
        return node;
    }
}
