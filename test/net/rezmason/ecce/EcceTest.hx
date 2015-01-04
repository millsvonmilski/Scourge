package net.rezmason.ecce;

import massive.munit.Assert;

class EcceTest {
    
    @Test
    public function ecceTest():Void {
        var ecce = new Ecce();
        
        var q0 = ecce.query([]);
        var q1 = ecce.query([Thing1]);
        var q2 = ecce.query([Thing1]);
        var q3 = ecce.query([Thing2]);
        var q4 = ecce.query([Thing3]);

        var e1 = ecce.create([Thing1]);
        var e2 = ecce.create([Thing2]);
        var e3 = ecce.create([Thing3]);

        var e4 = ecce.create();
        e4.add(Thing1);
        e4.remove(Thing1);
        e4.add(Thing1);

        e4.get(Thing1);

        ecce.query([Thing3]);
        try {
            ecce.query([Thing2, Thing3]);
            Assert.fail('Ecce should not allow new queries after entities are created');
        } catch (e:String) {}
        
        var e5 = ecce.create([Thing1, Thing2]);
        var e6 = ecce.create([Thing2, Thing3]);
        var e7 = ecce.create([Thing3, Thing1]);

        for (e in ecce.get([Thing2])) trace(e.get(Thing2));

        for (e in q2) trace(e.get(Thing1));

        var classes:Array<Class<Component>> = [Thing1, Thing2, Thing3];

        for (ike in 0...1000) {
            var t = classes[Std.random(3)];
            e7.add(t);
            t = classes[Std.random(3)];
            e7.remove(t);
        }
    }
}

class Thing1 extends Component { public function new() {} }
class Thing2 extends Component { public function new() {} }
class Thing3 extends Component { public function new() {} }
