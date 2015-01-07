package net.rezmason.scourge;

import flash.Lib;
import flash.display.Stage;
import flash.events.Event;

import net.rezmason.scourge.textview.GameSystem;
import net.rezmason.scourge.textview.NavSystem;
import net.rezmason.scourge.textview.ScourgeNavPageAddresses;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.FontManager;
import net.rezmason.scourge.textview.pages.*;
import net.rezmason.gl.*;
import net.rezmason.utils.santa.Santa;

class Context {

    var stage:Stage;
    var engine:Engine;
    var glSys:GLSystem;
    var glFlow:GLFlowControl;

    public function new():Void {
        stage = Lib.current.stage;
        glSys = new GLSystem();
        glFlow = glSys.getFlowControl();
        glFlow.onConnect = onGLConnect;
        glFlow.connect();
    }

    function onGLConnect():Void {
        glFlow.onConnect = null;
        Santa.mapToClass(GLSystem, Singleton(glSys));
        Santa.mapToClass(Stage, Singleton(stage));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full'])));

        makeEngine();
        makeGameSystem();
        makeNavSystem();
    }

    function makeEngine():Void {
        engine = new Engine(glFlow);
        engine.readySignal.add(addListeners);
        engine.init();
    }

    function addListeners():Void {
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.RESIZE, onResize);

        // these kind of already happened, so we just trigger them
        onResize();
        onActivate();
    }

    function makeGameSystem():Void Santa.mapToClass(GameSystem, Singleton(new GameSystem()));

    function makeNavSystem():Void {
        var navSystem:NavSystem = new NavSystem(engine);
        navSystem.addPage(ScourgeNavPageAddresses.SPLASH, new SplashPage());
        navSystem.addPage(ScourgeNavPageAddresses.ABOUT, new AboutPage());
        navSystem.addPage(ScourgeNavPageAddresses.GAME, new GamePage());

        navSystem.goto(Page(ScourgeNavPageAddresses.SPLASH));
    }

    function onResize(?event:Event):Void engine.setSize(stage.stageWidth, stage.stageHeight);
    function onActivate(?event:Event):Void engine.activate();
    function onDeactivate(?event:Event):Void engine.deactivate();
}
