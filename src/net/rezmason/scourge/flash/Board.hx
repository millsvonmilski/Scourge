package net.rezmason.scourge.flash;

import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.ui.Keyboard;
import flash.utils.Timer;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;
import net.kawa.tween.easing.Quad;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Game;
import net.rezmason.scourge.Player;
import net.rezmason.scourge.PlayerAction;
import net.rezmason.scourge.Pieces;

import flash.Lib;

class Board {
	
	inline static var __snap:Bool = true; // not sure if I want this
	
	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;
	inline static var SNAP_RATE:Float = 0.3;
	
	private static var PIECE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var PIECE_POP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 20, 1, true);
	private static var PIECE_SWAP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 8, 1);
	
	private static var PLAIN_CT:ColorTransform = GUIFactory.makeCT(0xFFFFFF);
	private static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF];
	private static var ORIGIN:Point = new Point();
	
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;
	private var playerCTs:Array<ColorTransform>;
	private var currentPlayer:Player;
	private var currentPlayerIndex:Int;
	private var lastGUIColorCycle:Int;
	private var shiftBite:Bool;
	private var background:Shape;
	private var grid:GameGrid;
	private var bar:Sprite;
	private var barBackground:Shape;
	private var well:Well;
	private var statPanel:StatPanel;
	private var timerPanel:TimerPanel;
	private var piece:Sprite;
	private var pieceBlocks:Array<Shape>;
	private var piecePlug:Shape;
	private var pieceBite:Sprite;
	private var pieceHandle:Sprite;
	private var draggingPiece:Bool;
	private var biting:Bool;
	private var swapHinting:Bool;
	private var gridHitBox:Rectangle;
	private var pieceBoardScale:Float;
	private var pieceWaitingOnGrid:Bool;
	private var pieceScaledDown:Bool;
	private var pieceLocX:Int;
	private var pieceLocY:Int;
	private var handleGoalX:Float;
	private var handleGoalY:Float;
	private var handlePushTimer:Timer;
	private var keyList:Array<Bool>;
	private var biteIndicator:MovieClip;
	
	private var pieceRecipe:Array<Int>;
	private var pieceCenter:Array<Float>;
	
	private var pieceHandleJob:KTJob;
	private var pieceHandleSpinJob:KTJob;
	private var pieceJob:KTJob;
	private var guiColorJob:KTJob;
	private var guiColorTransform:ColorTransform;
	private var pieceBlockJobs:Array<KTJob>;
	private var pieceBiteJob:KTJob;
	private var swapCounterJob:KTJob;
	private var biteCounterJob:KTJob;
	
	private var overBiteButton:Bool;
	private var overSwapButton:Bool;
	private var currentBlockForSwapHint:Int;
	
	private var pieceHomeX:Float;
	private var pieceHomeY:Float;
	
	private var debugNumPlayers:Int;
	
	public function new(__game:Game, __scene:Sprite, __debugNumPlayers) {
		scene = __scene;
		game = __game;
		
		debugNumPlayers = __debugNumPlayers;
		
		scene.mouseEnabled = scene.mouseChildren = false;
		
		if (scene.stage != null) {
			connectToStage();
		} else {
			scene.addEventListener(Event.ADDED_TO_STAGE, connectToStage);
		}
	}
	
	private function connectToStage(?event:Event):Void {
		scene.removeEventListener(Event.ADDED_TO_STAGE, connectToStage);
		stage = scene.stage;
		stage.focus = stage;
		
		initialize();
	}
	
	private function initialize():Void {
		
		// initialize the primitive variables
		draggingPiece = false;
		pieceScaledDown = false;
		swapHinting = false;
		biting = false;
		pieceBlockJobs = [];
		keyList = [];
		guiColorTransform = new ColorTransform();
		overSwapButton = false;
		overBiteButton = false;
		pieceWaitingOnGrid = false;
		
		// create the player color transforms
		playerCTs = [];
		for (ike in 0...TEAM_COLORS.length) playerCTs[ike] = GUIFactory.makeCT(TEAM_COLORS[ike]);
		
		// build the scene
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		background.cacheAsBitmap = true;
		
		grid = new GameGrid();
		for (ike in 0...Common.MAX_PLAYERS) grid.makePlayerHeadAndBody(playerCTs[ike]);
		well = new Well();
		timerPanel = new TimerPanel();
		statPanel = new StatPanel(Layout.STAT_PANEL_HEIGHT);
		barBackground = GUIFactory.drawSolidRect(new Shape(), 0x888888, 1, 0, 0, Layout.BAR_WIDTH * 0.6, Layout.BAR_HEIGHT);
		barBackground.cacheAsBitmap = true;
		bar = GUIFactory.makeContainer([barBackground, timerPanel, statPanel, well]);
		
		
		// wire up the scene
		GUIFactory.wireUp(well.rotateRightButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(well.rotateLeftButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(well.biteButton, biteHint, biteHint, toggleBite);
		GUIFactory.wireUp(well.swapButton, swapHint, swapHint, swapPiece);
		GUIFactory.wireUp(timerPanel.skipButton, null, null, skipTurn);
		
		gridHitBox = grid.getHitBox();
		gridHitBox.inflate(Layout.UNIT_SIZE * 1.5, Layout.UNIT_SIZE * 1.5);
		
		// position things
		well.x = well.y = Layout.BAR_MARGIN;
		timerPanel.x = Layout.BAR_MARGIN;
		timerPanel.y = well.y + well.height + Layout.BAR_MARGIN;
		statPanel.x = Layout.BAR_MARGIN;
		statPanel.y = timerPanel.y + timerPanel.height + Layout.BAR_MARGIN;
		
		GUIFactory.fillSprite(scene, [background, grid, bar]);
		
		// Set up the piece, piece handle, piece blocks and piece bite
		pieceBlocks = [];
		var bW:Int = Layout.UNIT_SIZE + 2;
		for (ike in 0...Common.MOST_BLOCKS_IN_PIECE + 1) {
			pieceBlocks.push(GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, -1, -1, bW, bW, bW * 0.5));
		}
		piece = GUIFactory.makeContainer(pieceBlocks);
		piecePlug = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, bW, bW, bW);
		piecePlug.visible = false;
		piecePlug.x = piecePlug.y = Layout.UNIT_SIZE / 2;
		piece.addChild(piecePlug);
		piece.filters = [PIECE_GLOW];
		pieceBite = new ScourgeLib_BiteMask();
		pieceBite.rotation = 180;
		pieceBite.visible = false;
		pieceBite.width = pieceBite.height = Layout.UNIT_SIZE * 0.7;
		pieceBite.blendMode = BlendMode.ERASE;
		piece.blendMode = BlendMode.LAYER;
		piece.addChild(pieceBite);
		pieceHandle = GUIFactory.makeContainer([piece]);
		pieceHandle.tabEnabled = !(pieceHandle.buttonMode = pieceHandle.useHandCursor = true);
		pieceHandle.x = Layout.WELL_WIDTH  / 2;
		pieceHandle.y = Layout.WELL_WIDTH / 2;
		piece.scaleX = piece.scaleY = Layout.WELL_WIDTH / (Layout.UNIT_SIZE * 5);
		
		// wire up the piece handle
		GUIFactory.wireUp(pieceHandle, popPieceOnRollover, popPieceOnRollover);
		
		well.addChildAt(pieceHandle, 1);
		
		// add events
		pieceHandle.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		grid.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		stage.addEventListener(MouseEvent.MOUSE_UP, dropPiece);
		
		grid.firstBiteCheck = firstBiteCheck;
		grid.endBiteCheck = endBiteCheck;
		
		stage.addEventListener(Event.ADDED, resize, true);
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		
		handlePushTimer = new Timer(10);
		handlePushTimer.addEventListener(TimerEvent.TIMER, updateHandlePush);
		
		// kick things off
		game.begin(debugNumPlayers);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		lastGUIColorCycle = -1;
		update(true, true);
		grid.initHeads(game.getNumPlayers());
		grid.updateFadeSourceBitmap();
		//fillBoardRandomly();
		scene.mouseEnabled = scene.mouseChildren = true;
		
		//traceHierarchy();
	}
	
	private function traceHierarchy(?target:DisplayObject = null, ?spit:Bool = true):String {
		
		if (target == null) target = untyped __as__(scene, DisplayObject);
		
		var str:String = "\n<element id='" + target.name + "' value='" + target.toString() + "'";
		var container:DisplayObjectContainer = untyped __as__(target, DisplayObjectContainer);
		if (container != null && container.numChildren > 0) {
			str += ">";
			for (ike in 0...container.numChildren) str += traceHierarchy(container.getChildAt(ike), false);
			str += "\n</element>";
		} else {
			str += "/>";
		}
		
		if (spit) {
			var box:TextField = new TextField();
			box.text = str;
			box.background = true;
			scene.addChild(box);
		}
		
		return str;
	}
	
	private function resize(?event:Event):Void {
		
		if (event.type == Event.ADDED && event.target != flash.Lib.current) return;
		
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;
		
		sw = Math.max(sw, MIN_WIDTH);
		sh = Math.max(sh, MIN_HEIGHT);
		
		// size the background. This is more //////important later when I texture it
		background.scaleX = background.scaleY = 1;
		if (background.width / background.height < sw / sh) {
			background.width = sw;
			background.scaleY = background.scaleX;
		} else {
			background.height = sh;
			background.scaleX = background.scaleY;
		}
		
		bar.height = sh;
		bar.scaleX = bar.scaleY;
		bar.x = 0;
		bar.y = 0;
		
		var barWidth:Float = Layout.BAR_WIDTH * bar.scaleX;
		
		// scale and reposition grid
		
		if (sw - barWidth < sh) {
			grid.width = sw - barWidth - 40;
			grid.scaleY = grid.scaleX;
		} else {
			grid.height = sh - 40;
			grid.scaleX = grid.scaleY;
		}
		
		grid.x = barWidth + (sw - barWidth - grid.width) * 0.5;
		grid.y = (sh - grid.height) * 0.5;
	}
	
	private function update(?thePiece:Bool, ?thePlay:Bool, ?fade:Bool):Void {
		
		if (thePlay) {
			if (fade) {
				grid.fadeByFreshness(game.getFreshGrid(), game.getMaxFreshness());
				waitForGridUpdate(thePiece);
			} else {
				cycleGUIColors();
			}
			
			grid.updateBodies(game.getColorGrid());
			grid.updateHeads(game.getPlayers());
			
			if (fade) return;
		}
		
		if (thePiece) {
			if (!biting) {
				updatePiece();
				showPiece();
			}
			updateWell();
			updateStats();
		}
	}
	
	private function waitForGridUpdate(updatePiece:Bool):Void {
		grid.addEventListener(Event.COMPLETE, gridUpdateResponder, false, 0, true);
		pieceWaitingOnGrid = updatePiece;
		pieceHandle.visible = false;
		lockScene();
	}
	
	private function gridUpdateResponder(event:Event):Void {
		grid.removeEventListener(Event.COMPLETE, gridUpdateResponder);
		cycleGUIColors();
		if (pieceWaitingOnGrid) {
			pieceWaitingOnGrid = false;
			update(true);
			unlockScene();
		}
	}
	
	private function lockScene():Void { scene.mouseChildren = false; }
	private function unlockScene():Void { scene.mouseChildren = true; }
	
	private function cycleGUIColors():Void {
		if (lastGUIColorCycle == currentPlayerIndex) return;
		lastGUIColorCycle = currentPlayerIndex;
		var tween:Dynamic = {};
		var ct:ColorTransform = playerCTs[currentPlayerIndex];
		tween.redMultiplier = ct.redMultiplier;
		tween.greenMultiplier = ct.greenMultiplier;
		tween.blueMultiplier = ct.blueMultiplier;
		if (guiColorJob != null) guiColorJob.complete();
		guiColorJob = KTween.to(guiColorTransform, Layout.QUICK * 3, tween, Layout.SLIDE);
		guiColorJob.onChange = tweenGUIColors;
	}
	
	private function tweenGUIColors():Void {
		well.tint(guiColorTransform);
		statPanel.tint(guiColorTransform);
		timerPanel.tint(guiColorTransform);
		barBackground.transform.colorTransform = guiColorTransform;
	}
	
	private function updatePiece(?previousAngle:Int = 0):Void {
		
		// get the current mouse offsets;
		
		var c1X:Float = 0;
		var c1Y:Float = 0;
		var offX:Float = 0;
		var offY:Float = 0;
		
		var pt:Point;
		
		if (pieceCenter != null) {
			
			c1X = Layout.UNIT_SIZE * pieceCenter[0];
			c1Y = Layout.UNIT_SIZE * pieceCenter[1];
			
			pt = piece.globalToLocal(pieceHandle.localToGlobal(ORIGIN));
			
			offX = pt.x - c1X;
			offY = pt.y - c1Y;
			
			if (previousAngle > 0) {
				offX *= -1;
			} else if (previousAngle < 0) {
				offY *= -1;
			}
		}
		
		pieceRecipe = game.getPiece();
		pieceCenter = game.getPieceCenter();
		pieceHandle.rotation = 0;
		var lastAlpha:Float = pieceHandle.alpha;
		pieceHandle.transform.colorTransform = playerCTs[currentPlayerIndex];
		pieceHandle.alpha = lastAlpha;
		
		var c2X:Float = Layout.UNIT_SIZE * pieceCenter[0];
		var c2Y:Float = Layout.UNIT_SIZE * pieceCenter[1];
		
		// redraw the piece
		var ike:Int = 0, jen:Int = 0;
		while (jen < pieceBlocks.length) {
			var pieceBlock:Shape = pieceBlocks[jen];
			pieceBlock.x = Layout.UNIT_SIZE * pieceRecipe[ike];
			pieceBlock.y = Layout.UNIT_SIZE * pieceRecipe[ike + 1];
			if (ike + 2 < pieceRecipe.length) ike += 2;
			jen++;
		}
		
		pieceBite.x = pieceRecipe[ike    ] * Layout.UNIT_SIZE + pieceBlocks[jen - 1].width;
		pieceBite.y = pieceRecipe[ike + 1] * Layout.UNIT_SIZE + pieceBlocks[jen - 1].height;
		
		piecePlug.visible = (pieceRecipe == Pieces.O_PIECE);
		
		// update the position
		pieceHomeX = -c2X * piece.scaleX;
		pieceHomeY = -c2Y * piece.scaleY;
		
		if (draggingPiece) {
			piece.x = 0;
			piece.y = 0;
			pt = piece.globalToLocal(pieceHandle.localToGlobal(ORIGIN));
			piece.x = (pt.x - c2X + offY) * piece.scaleX;
			piece.y = (pt.y - c2Y + offX) * piece.scaleY;
			dragPiece(__snap);
		} else {
			piece.x = pieceHomeX;
			piece.y = pieceHomeY;
		}
		enableDrag();
	}
	
	private function liftPiece(event:Event):Void {
		if (draggingPiece || biting) return;
		draggingPiece = true;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		
		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceJob != null) pieceJob.complete();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		
		pieceBoardScale = grid.pattern.transform.concatenatedMatrix.a / piece.transform.concatenatedMatrix.a;
		
		popPiece(true);
		
		var mX:Float, mY:Float;
		if (event.currentTarget == grid) {
			mX = pieceCenter[0];
			mY = pieceCenter[1];
		} else {
			mX = piece.mouseX / Layout.UNIT_SIZE;
			mY = piece.mouseY / Layout.UNIT_SIZE;
		}
		
		var goodX:Float = mX, testX:Float;
		var goodY:Float = mY, testY:Float;
		var goodDist:Float = Math.POSITIVE_INFINITY, testDist:Float;
		
		var ike:Int = 0;
		while (ike < pieceRecipe.length) {
			testX = (pieceRecipe[ike] + 0.5) - mX;
			testY = (pieceRecipe[ike + 1] + 0.5) - mY;
			testDist = Math.sqrt(testX * testX + testY * testY);
			if (testDist < goodDist) {
				goodDist = testDist;
				goodX = testX + mX;
				goodY = testY + mY;
			}
			ike += 2;
		}
		
		var goodPt:Point = well.globalToLocal(piece.localToGlobal(new Point(goodX * Layout.UNIT_SIZE, goodY * Layout.UNIT_SIZE)));
		
		piece.x += pieceHandle.x;
		piece.y += pieceHandle.y;
		
		if (event.currentTarget == grid) {
			piece.x -= goodPt.x;
			piece.y -= goodPt.y;
			pieceHandle.scaleX = pieceHandle.scaleY = pieceBoardScale;
		} else {
			var toX:Float = piece.x  - goodPt.x;
			var toY:Float = piece.y  - goodPt.y;
			piece.x -= well.mouseX;
			piece.y -= well.mouseY;
			pieceJob = KTween.to(piece, 3 * Layout.QUICK, {x:toX, y:toY}, Layout.POUNCE);
			pieceHandleJob = KTween.to(pieceHandle, Layout.QUICK, {scaleX:1.2, scaleY:1.2}, Linear.easeOut);
		}
		
		dragPiece();
	}
	
	private function dragPiece(?snap:Bool):Void {
		if (!draggingPiece) return;
		var oldX:Float = pieceHandle.x;
		var oldY:Float = pieceHandle.y;
		
		var overGrid:Bool = gridHitBox.contains(grid.pattern.mouseX, grid.pattern.mouseY);
		var scale:Float;
		
		if (overGrid != pieceScaledDown) {
			pieceScaledDown = overGrid;
			if (pieceHandleJob != null) pieceHandleJob.complete();
			scale = overGrid ? pieceBoardScale : 1.2;
			pieceHandleJob = KTween.to(pieceHandle, 2 * Layout.QUICK, {scaleX:scale, scaleY:scale}, Linear.easeOut);
		}
		
		pieceHandle.x = well.mouseX;
		pieceHandle.y = well.mouseY;
		well.addChild(pieceHandle);
		
		if (overGrid && gridHitBox.containsRect(pieceHandle.getBounds(grid.pattern))) {
			
			// grid snapping.
			
			var gp:Point = grid.pattern.globalToLocal(piece.localToGlobal(ORIGIN));
			
			pieceLocX = Std.int(Math.round(gp.x / Layout.UNIT_SIZE));
			pieceLocY = Std.int(Math.round(gp.y / Layout.UNIT_SIZE));
			
			pieceHandle.transform.colorTransform = game.evaluatePosition(pieceLocX, pieceLocY) ? PLAIN_CT : playerCTs[currentPlayerIndex];
			
			var gp2:Point = new Point(pieceLocX * Layout.UNIT_SIZE, pieceLocY * Layout.UNIT_SIZE);
			
			gp  = pieceHandle.globalToLocal(grid.pattern.localToGlobal(gp));
			gp2 = pieceHandle.globalToLocal(grid.pattern.localToGlobal(gp2));
			
			gp2.x = pieceHandle.x + (gp2.x - gp.x) * pieceHandle.scaleX;
			gp2.y = pieceHandle.y + (gp2.y - gp.y) * pieceHandle.scaleY;
			
			if (!snap || Math.abs(pieceHandle.x + pieceHandle.y - handleGoalX - handleGoalY) < 2) {
				if (handlePushTimer.running) {
					pieceHandle.x = oldX;
					pieceHandle.y = oldY;
				} else {
					pieceHandle.x = gp2.x;
					pieceHandle.y = gp2.y;
				}
			} else if (snap) {
				handleGoalX = gp2.x;
				handleGoalY = gp2.y;
				pieceHandle.x = oldX;
				pieceHandle.y = oldY;
				handlePushTimer.start();
			}
		} else {
			pieceLocX = pieceLocY = -1;
			handlePushTimer.reset();
		}
	}
	
	private function updateHandlePush(event:Event):Void {
		if (!draggingPiece) return;
		pieceHandle.x = pieceHandle.x * (1 - SNAP_RATE) + handleGoalX * SNAP_RATE;
		pieceHandle.y = pieceHandle.y * (1 - SNAP_RATE) + handleGoalY * SNAP_RATE;
		if (Math.abs(pieceHandle.x + pieceHandle.y - handleGoalX - handleGoalY) < 2) finishHandlePush();
	}
	
	private function finishHandlePush():Void {
		if (!(draggingPiece && handlePushTimer.running)) return;
		handlePushTimer.stop();
		pieceHandle.x = handleGoalX;
		pieceHandle.y = handleGoalY;
	}
	
	private function dropPiece(?event:Event):Void {
		if (!draggingPiece) return;
		pieceHandle.x = handleGoalX;
		pieceHandle.y = handleGoalY;
		handlePushTimer.stop();
		
		dragPiece();
		
		pieceHandle.transform.colorTransform = playerCTs[currentPlayerIndex];
		piece.filters = [PIECE_GLOW];
		pieceScaledDown = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();
		
		draggingPiece = false;
		
		if (pieceLocX != -1 && game.processPlayerAction(PlayerAction.PLACE_PIECE(pieceLocX, pieceLocY))) {
			currentPlayer = game.getCurrentPlayer();
			currentPlayerIndex = game.getCurrentPlayerIndex();
			update(true, true, true);
		} else {
			var pieceHandleHome:Float = Layout.WELL_WIDTH / 2;
			pieceHandleJob = KTween.to(pieceHandle, 2 * Layout.QUICK, {x:pieceHandleHome, y:pieceHandleHome, scaleX:1, scaleY:1}, Layout.POUNCE, enableDrag);
			pieceJob = KTween.to(piece, 2 * Layout.QUICK, {x:pieceHomeX, y:pieceHomeY}, Layout.POUNCE);
			well.addChild(pieceHandle);
		}
	}
	
	private function showPiece():Void {
		if (biteIndicator != null) {
			biteIndicator.gotoAndStop(0);
			biteIndicator.visible = false;
		}
		pieceHandle.visible = true;
		well.addChildAt(pieceHandle, 1);
		piece.x = pieceHomeX;
		piece.y = pieceHomeY;
		pieceHandle.x = Layout.WELL_WIDTH  / 2;
		pieceHandle.y = Layout.WELL_WIDTH / 2;
		pieceHandle.scaleX = pieceHandle.scaleY = 0.7;
		pieceHandle.alpha = 0;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		pieceHandleJob = KTween.to(pieceHandle, 3 * Layout.QUICK, {alpha:1, scaleX:1, scaleY:1}, Layout.SLIDE, enableDrag);
	}
	
	private function updateWell():Void {
		if (swapCounterJob != null) swapCounterJob.complete();
		if (biteCounterJob != null) biteCounterJob.complete();
		well.updateCounters(currentPlayer.swaps, currentPlayer.bites);
	}
	
	private function updateStats():Void {
		statPanel.update(game.getRollCall(), playerCTs);
	}
	
	private function rotatePiece(?event:Event):Void {
		if (biting) return;
		finishHandlePush();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		if (pieceJob != null) pieceJob.complete();
		var cc:Bool = event != null && event.currentTarget == well.rotateLeftButton;
		game.processPlayerAction(PlayerAction.SPIN_PIECE(cc));
		var angle:Int = cc ? -90 : 90;
		updatePiece(angle);
		pieceHandleSpinJob = KTween.from(pieceHandle, 2 * Layout.QUICK, {rotation:-angle}, Layout.POUNCE, enableDrag);
		if (!draggingPiece) pieceJob = KTween.to(piece, 2 * Layout.QUICK, {x:pieceHomeX, y:pieceHomeY}, Layout.POUNCE);
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
	}
	
	private function rotateHint(event:Event):Void {
		if (draggingPiece || biting) return;
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		var angle:Float = (event.type == MouseEvent.ROLL_OUT) ? 0 : ((event.currentTarget == well.rotateLeftButton) ? -10 : 10);
		pieceHandleSpinJob = KTween.to(pieceHandle, Layout.QUICK, {rotation:angle}, Layout.POUNCE);
	}
	
	private function popPieceOnRollover(event:Event):Void {
		if (draggingPiece) return;
		popPiece(event.type == MouseEvent.ROLL_OVER);
	}
	
	private function popPiece(?bigger:Bool):Void {
		piece.filters = [bigger ? PIECE_POP_GLOW : PIECE_GLOW];
	}
	
	private function enableDrag():Void {
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = true;
		if (!draggingPiece) well.addChildAt(pieceHandle, 1);
	}
	
	private function keyHandler(event:KeyboardEvent):Void {
		var down:Bool = event.type == KeyboardEvent.KEY_DOWN;
		var wasDown:Bool = keyList[event.keyCode];
		if (down != wasDown) {
			switch (event.keyCode) {
				case Keyboard.SPACE: if (down) rotatePiece();
				case Keyboard.SHIFT: 
					if (!biting || shiftBite) {
						shiftBite = down;
						toggleBite(null, down);
					}
				case Keyboard.TAB: if (down) swapPiece();
				case Keyboard.ESCAPE: if (down) skipTurn();
				case Keyboard.F1: untyped __global__["flash.profiler.showRedrawRegions"](down);
				case Keyboard.F2:
					if (down) {
						var gridString:String = game.getColorGrid().toString() + ",";
						for (ike in 0...Common.BOARD_SIZE) {
							Lib.trace(gridString.substr(ike * Common.BOARD_SIZE * 2, Common.BOARD_SIZE * 2));
						}
					}
			}
		}
		keyList[event.keyCode] = (event.type == KeyboardEvent.KEY_DOWN);
	}
	
	private function mouseHandler(event:MouseEvent):Void {
		if (draggingPiece) {
			dragPiece(__snap);
		}
	}
	
	private function biteHint(event:Event):Void {
		if (draggingPiece || biting) return;
		
		if (biteCounterJob != null) biteCounterJob.complete();
		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceBiteJob != null) pieceBiteJob.complete();
		overBiteButton = event.type == MouseEvent.ROLL_OVER;
		if (overBiteButton) {
			pieceBite.visible = true;
			pieceBite.alpha = 1;
			var wham:Float = Layout.WELL_WIDTH * 0.05;
			//pieceHandle.rotation = 30;
			pieceHandleJob = KTween.from(pieceHandle, 3 * Layout.QUICK, {x:pieceHandle.x + wham, y:pieceHandle.y + wham, rotation:0}, Layout.ZIGZAG);
			well.biteCounter.visible = true;
			well.biteCounter.alpha = 0;
			biteCounterJob = KTween.to(well.biteCounter, 3 * Layout.QUICK, {alpha:1}, Layout.POUNCE);
		} else {
			pieceBite.alpha = 0.05;
			pieceBiteJob = KTween.to(pieceBite, 3 * Layout.QUICK, {alpha:0, visible:false}, Layout.POUNCE);
			//pieceHandleJob = KTween.to(pieceHandle, 3 * Layout.QUICK, {rotation:0}, Layout.POUNCE);
			well.biteCounter.alpha = 1;
			biteCounterJob = KTween.to(well.biteCounter, 3 * Layout.QUICK, {alpha:0, visible:false}, Layout.POUNCE);
		}
	}
	
	private function toggleBite(?event:Event, ?isBiting:Null<Bool>):Void {
		if (draggingPiece || currentPlayer.bites < 1 && isBiting != false) return;
		grid.cancelDragBite();
		var switched:Bool = false;
		if (isBiting == null) {
			biting = !biting;
			switched = true;
		} else {
			switched = biting != isBiting;
			biting = isBiting;
		}
		if (biting) {
			switch (game.getCurrentPlayer().biteSize) {
				case 1:biteIndicator = well.smallBiteIndicator;
				case 2:biteIndicator = well.bigBiteIndicator;
				case 3:biteIndicator = well.superBiteIndicator;
			}
			biteIndicator.visible = true;
			biteIndicator.transform.colorTransform = playerCTs[currentPlayerIndex];
			pieceHandle.visible = false;
			biteIndicator.gotoAndPlay("in");
			
			var headPositions:Array<Int> = Common.HEAD_POSITIONS[game.getNumPlayers() - 1];
			var headX:Int = headPositions[currentPlayerIndex * 2    ];
			var headY:Int = headPositions[currentPlayerIndex * 2 + 1];
			
			grid.showTeeth();
			grid.updateTeeth(game.getBiteGrid(), currentPlayerIndex, headX, headY, playerCTs[currentPlayerIndex]);
			grid.tintTeeth(TEAM_COLORS[currentPlayerIndex]);
			
			if (!overBiteButton) {
				if (biteCounterJob != null) biteCounterJob.complete();
				well.biteCounter.visible = true;
				well.biteCounter.alpha = 0;
				biteCounterJob = KTween.to(well.biteCounter, 3 * Layout.QUICK, {alpha:1}, Layout.POUNCE);
			}
			
		} else {
			if (biteIndicator != null && biteIndicator.visible) showPiece();
			grid.hideTeeth(currentPlayerIndex);
			pieceBite.visible = false;
			
			if (!overBiteButton && switched) {
				if (biteCounterJob != null) biteCounterJob.complete();
				well.biteCounter.visible = true;
				well.biteCounter.alpha = 1;
				biteCounterJob = KTween.to(well.biteCounter, 3 * Layout.QUICK, {alpha:0, visible:false}, Layout.POUNCE);
			}
		}
	}
	
	private function firstBiteCheck(bX:Int, bY:Int):Array<Int> {
		if (!game.processPlayerAction(PlayerAction.START_BITE(bX, bY))) return null;
		return game.getBiteLimits();
	}
	
	private function endBiteCheck(bX:Int, bY:Int):Void {
		if (game.processPlayerAction(PlayerAction.END_BITE(bX, bY))) {
			if (shiftBite && currentPlayer.bites > 0) {
				update(true, true, true);
				var headPositions:Array<Int> = Common.HEAD_POSITIONS[game.getNumPlayers() - 1];
				var headX:Int = headPositions[currentPlayerIndex * 2    ];
				var headY:Int = headPositions[currentPlayerIndex * 2 + 1];
				grid.updateTeeth(game.getBiteGrid(), currentPlayerIndex, headX, headY, playerCTs[currentPlayerIndex]);
			} else {
				toggleBite(null, false);
				update(true, true, true);
			}
		}
	}
	
	private function swapHint(event:Event):Void {
		if (draggingPiece || biting) return;
		if (swapCounterJob != null) swapCounterJob.complete();
		overSwapButton = event.type == MouseEvent.ROLL_OVER;
		if (overSwapButton) {
			swapHinting = true;
			piecePlug.visible = false;
			currentBlockForSwapHint = 0;
			pushCurrentSwapBlock();
			pieceHandle.filters = [PIECE_SWAP_GLOW];
			well.swapCounter.visible = true;
			well.swapCounter.alpha = 0;
			swapCounterJob = KTween.to(well.swapCounter, 3 * Layout.QUICK, {alpha:1}, Layout.POUNCE);
		} else {
			swapHinting = false;
			var oldPieceX:Float = piece.x;
			var oldPieceY:Float = piece.y;
			var oldXs:Array<Float> = [];
			var oldYs:Array<Float> = [];
			for (ike in 0...pieceBlocks.length) {
				oldXs[ike] = pieceBlocks[ike].x;
				oldYs[ike] = pieceBlocks[ike].y;
				if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
			}
			updatePiece();
			KTween.from(piece, Layout.QUICK, {x:oldPieceX, y:oldPieceY}, Layout.POUNCE);
			for (ike in 0...pieceBlocks.length) {
				pieceBlockJobs[ike] = KTween.from(pieceBlocks[ike], Layout.QUICK, {x:oldXs[ike], y:oldYs[ike]}, Layout.SLIDE);
			}
			pieceHandle.filters = [];
			piece.filters = [PIECE_GLOW];
			well.swapCounter.alpha = 1;
			swapCounterJob = KTween.to(well.swapCounter, 3 * Layout.QUICK, {alpha:0, visible:false}, Layout.POUNCE);
		}
	}
	
	private function pushCurrentSwapBlock():Void {
		if (!swapHinting) return;
		var block:Shape = pieceBlocks[currentBlockForSwapHint];
		var spotTaken:Bool;
		var spotX:Float = 0, spotY:Float = 0;
		while (true) {
			spotTaken = false;
			spotX = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[0]) * Layout.UNIT_SIZE;
			spotY = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[1]) * Layout.UNIT_SIZE;
			
			for (ike in 0...pieceBlocks.length) {
				if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
				spotTaken = spotTaken || (pieceBlocks[ike].x == spotX && pieceBlocks[ike].y == spotY);
			}
			
			if (!spotTaken) break;
		}
		
		if (pieceBlockJobs[currentBlockForSwapHint] != null) pieceBlockJobs[currentBlockForSwapHint].close();
		pieceBlockJobs[currentBlockForSwapHint] = KTween.to(block, Layout.QUICK * 0.7, {x:spotX, y:spotY}, Linear.easeOut, pushCurrentSwapBlock);
		
		currentBlockForSwapHint = (currentBlockForSwapHint + 1) % pieceBlocks.length;
	}
	
	private function swapPiece(?event:Event):Void {
		if (draggingPiece || !well.swapButton.mouseEnabled) return;
		toggleBite(null, false);
		swapHinting = false;
		game.processPlayerAction(PlayerAction.SWAP_PIECE);
		for (ike in 0...pieceBlocks.length) {
			if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
		}
		update(true);
		if (pieceRecipe == Pieces.O_PIECE) KTween.from(piecePlug, Layout.QUICK, {alpha:0}, Layout.POUNCE);
		if (!overSwapButton) {
			if (swapCounterJob != null) swapCounterJob.complete();
			well.swapCounter.visible = true;
			well.swapCounter.alpha = 1;
			swapCounterJob = KTween.to(well.swapCounter, 20 * Layout.QUICK, {alpha:0, visible:false}, Quad.easeIn);
		}
	}
	
	private function skipTurn(?event:Event):Void {
		if (draggingPiece || grid.isDraggingBite()) return;
		toggleBite(null, false);
		if (swapCounterJob != null) swapCounterJob.complete();
		game.processPlayerAction(PlayerAction.SKIP);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
	}
}