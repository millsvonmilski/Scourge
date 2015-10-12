package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.components.BoardSpaceState;
import net.rezmason.scourge.components.BoardSpaceView;
import net.rezmason.scourge.textview.View;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.ui.BorderBox;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.grid.GridUtils;
using net.rezmason.scourge.textview.core.GlyphUtils;

class MoveMediator {

    public var moveChosenSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    var num:Float = 0;
    var loupe:BorderBox;
    var ecce:Ecce;
    var qBoard:Query;
    var boardSpacesByID:Map<Int, Entity>;
    var selectedSpace:Entity;

    public function new() {
        var view:View = new Present(View);
        view.board.interactionSignal.add(handleBoardInteraction);

        ecce = new Present(Ecce);
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
        selectedSpace = null;

        loupe = view.loupe;
        loupe.body.mouseEnabled = false;
        loupe.body.updateSignal.add(onUpdate);    
    }

    function onUpdate(delta) {
        num += delta;
        loupe.width  = (Math.sin(num * 2) * 0.5 + 0.5) * 0.5;
        loupe.height = (Math.sin(num * 3) * 0.5 + 0.5) * 0.5;
        loupe.redraw();
    }

    public function enableHumanMoves() {
        trace('ENABLE HUMAN MOVES');
    }

    public function acceptBoardSpaces() {
        boardSpacesByID = new Map();
        for (entity in qBoard) {
            var spaceState = entity.get(BoardSpaceState);
            boardSpacesByID[spaceState.cell.id] = entity;
        }
    }

    public function ejectBoardSpaces() {
        boardSpacesByID = null;
    }

    function handleBoardInteraction(glyphID, interaction) {
        switch (interaction) {
            case KEYBOARD(type, keyCode, modifier) if (type == KEY_DOWN && selectedSpace != null): 
                var cell = selectedSpace.get(BoardSpaceState).cell;
                var nextCell = null;
                switch (keyCode) {
                    case UP: nextCell = cell.n();
                    case DOWN: nextCell = cell.s();
                    case LEFT: nextCell = cell.w();
                    case RIGHT: nextCell = cell.e();
                    case SPACE: trace('SPACE');
                    case _:
                }
                if (nextCell != null) {
                    var nextSpace = boardSpacesByID[nextCell.id];
                    if (nextSpace.get(BoardSpaceState).petriData.isWall) return;
                    selectedSpace.get(BoardSpaceView).over.set_s(0);
                    selectedSpace = nextSpace;
                    selectedSpace.get(BoardSpaceView).over.set_s(2);
                }
            case MOUSE(type, x, y): 
                switch (type) {
                    case CLICK:
                        if (selectedSpace != null) selectedSpace.get(BoardSpaceView).over.set_s(0);
                        selectedSpace = boardSpacesByID[glyphID];
                        selectedSpace.get(BoardSpaceView).over.set_s(2);
                    case MOUSE_DOWN:
                    case MOUSE_UP:
                    case MOVE:
                    case _:
                }
            case _:
        }
    }
}