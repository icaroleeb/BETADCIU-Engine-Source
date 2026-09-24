package states.editors.content;

import backend.StageData;
import objects.Character;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import psychlua.ModchartSprite;

class StageEditorAnimationSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var originalZoom:Float;
	var originalCamPoint:FlxPoint;
	var originalPosition:FlxPoint;
	var originalCamTarget:FlxObject;
	var originalAlpha:Float = 1;
	public var target:StageEditorMetaSprite;
	
	var curAnim:Int = 0;
	var animsTxtGroup:FlxTypedGroup<FlxText>;

	var UI_animationbox:PsychUIBox;
	var camHUD:FlxCamera = cast(FlxG.state, LuaStageEditorState).camHUD;
	
	public function new()
	{
		super();

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(50, 50, 100, 100, true, 0xFFAAAAAA, 0xFF666666));
		add(grid);
		
		animsTxtGroup = new FlxTypedGroup<FlxText>();
		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);
		
		UI_animationbox = new PsychUIBox(FlxG.width - 320, 20, 300, 250, ['Animações Lua']);
		UI_animationbox.cameras = [camHUD];
		UI_animationbox.scrollFactor.set();
		add(UI_animationbox);
		addAnimationsUI();

		openCallback = function()
		{
			curAnim = 0;
			originalZoom = FlxG.camera.zoom;
			originalCamPoint = FlxPoint.weak(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			originalPosition = FlxPoint.weak(target.x, target.y);
			originalCamTarget = FlxG.camera.target;
			originalAlpha = target.alpha;
			FlxG.camera.zoom = 0.5;
			FlxG.camera.scroll.set(0, 0);

			target.alpha = 1;
			target.sprite.screenCenter();
			add(target.sprite);
			reloadAnimList();
		};

		closeCallback = function()
		{
			FlxG.camera.zoom = originalZoom;
			FlxG.camera.scroll.set(originalCamPoint.x, originalCamPoint.y);
			FlxG.camera.target = originalCamTarget;

			target.x = originalPosition.x;
			target.y = originalPosition.y;
			target.alpha = originalAlpha;
			remove(target.sprite);

			if(target.animations != null && target.animations.length > 0)
			{
				if(target.firstAnimation == null) target.firstAnimation = target.animations[0].anim;
				playAnim(target.firstAnimation);
			}
		};
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	var mainAnimTxt:FlxText;

	function addAnimationsUI()
	{
		var tab_group = UI_animationbox.getTab('Animações Lua').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, 'Loop?', 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			if(target.animations == null) return;
			var anim:AnimArray = target.animations[selectedAnimation];
			if(anim == null) return;

			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices != null ? anim.indices.toString() : "";
			animationIndicesInputText.text = indicesStr.length > 2 ? indicesStr.substr(1, indicesStr.length - 2) : "";
		});

		mainAnimTxt = new FlxText(160, animationDropDown.y - 18, 0, 'Anim. Principal: ');
		var initAnimButton:PsychUIButton = new PsychUIButton(160, animationDropDown.y, 'Definir Principal', function() {
			if(target.animations == null || target.animations.length == 0) return;
			var anim:AnimArray = target.animations[curAnim];
			if(anim == null) return;

			mainAnimTxt.text = 'Anim. Principal: ${anim.anim}';
			target.firstAnimation = anim.anim;
		});
		tab_group.add(mainAnimTxt);
		tab_group.add(initAnimButton);

		var addUpdateButton:PsychUIButton = new PsychUIButton(40, animationIndicesInputText.y + 35, 'Adicionar/Atualizar', function() {
			if(animationInputText.text == '') return;

			if(target.animations == null) target.animations = [];

			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastOffsets:Array<Float> = null;
			for (anim in target.animations)
				if(animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					cast (target.sprite, ModchartSprite).animOffsets.remove(animationInputText.text);
					target.sprite.animation.remove(animationInputText.text);
					target.animations.remove(anim);
				}

			var addedAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets,
				playerOffsets: lastOffsets
			};

			if(addedAnim.indices != null && addedAnim.indices.length > 0)
				target.sprite.animation.addByIndices(addedAnim.anim, addedAnim.name, addedAnim.indices, '', addedAnim.fps, addedAnim.loop);
			else
				target.sprite.animation.addByPrefix(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop);

			target.animations.push(addedAnim);
			reloadAnimList();
			playAnim(addedAnim.anim, true);

			curAnim = target.animations.length - 1;
			updateTextColors();
		});

		var removeButton:PsychUIButton = new PsychUIButton(160, animationIndicesInputText.y + 35, 'Remover', function()
		{
			if(target.animations == null) return;
			for (anim in target.animations)
			{
				if(animationInputText.text == anim.anim)
				{
					var targetSprite:ModchartSprite = cast (target.sprite, ModchartSprite);
					var resetAnim:Bool = false;
					if(targetSprite.animation.curAnim != null && anim.anim == targetSprite.animation.curAnim.name) resetAnim = true;

					if(targetSprite.animOffsets.exists(anim.anim))
						targetSprite.animOffsets.remove(anim.anim);

					target.animations.remove(anim);
					targetSprite.animation.remove(anim.anim);

					if(resetAnim && target.animations.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, target.animations.length-1);
						playAnim(target.animations[curAnim].anim, true);
						updateTextColors();
					}
					else if(target.animations.length < 1)
						target.sprite.animation.curAnim = null;

					reloadAnimList();
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animações:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Nome da Animação:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Tag/Prefixe do XML:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'Índices (Opcional):'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	function reloadAnimList()
	{
		if(target.animations == null) target.animations = [];
		else if(target.animations.length > 0) playAnim(target.animations[0].anim, true);
		curAnim = 0;

		for (text in animsTxtGroup)
			text.kill();

		var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
		if(target.animations.length > 0)
		{
			if(target.firstAnimation == null || !target.sprite.animation.exists(target.firstAnimation))
				target.firstAnimation = target.animations[0].anim;

			mainAnimTxt.text = 'Anim. Principal: ${target.firstAnimation}';
		}
		else
		{
			target.firstAnimation = null;
			mainAnimTxt.text = '(Sem Animação Principal)';
		}

		for (num => anim in target.animations)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * num);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			if(anim.offsets != null)
				text.text = '${anim.anim}: ${spr.animOffsets.get(anim.anim)}';
			else
				text.text = '${anim.anim}: Sem offsets';

			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);
		}
		updateTextColors();
		reloadAnimationDropDown();
	}
	
	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		if(target.animations != null) {
			for (anim in target.animations) animList.push(anim.anim);
		}
		if(animList.length < 1) animList.push('SEM ANIMAÇÕES');
		animationDropDown.list = animList;
	}

	inline function updateTextColors()
	{
		for (num => text in animsTxtGroup)
		{
			text.color = FlxColor.WHITE;
			if(num == curAnim) text.color = FlxColor.LIME;
		}
	}

	function playAnim(name:String, force:Bool = false)
	{
		var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
		spr.playAnim(name, force);
		if(!spr.animOffsets.exists(name)) spr.updateHitbox();
	}
	
	final minZoom = 0.25;
	final maxZoom = 2;
	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(PsychUIInputText.focusOn != null) return;

		if(target.animations != null && target.animations.length > 1)
		{
			var changedAnim:Bool = false;
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;
			else if(FlxG.keys.justPressed.SPACE) changedAnim = true;

			if(changedAnim)
			{
				curAnim = FlxMath.wrap(curAnim, 0, target.animations.length-1);
				playAnim(target.animations[curAnim].anim, true);
				updateTextColors();
			}
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT) { shiftMult = 4; shiftMultBig = 10; }
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		if(target.sprite.animation.curAnim != null)
		{
			var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
			var anim:String = spr.animation.curAnim.name;
			var changedOffset = false;
			var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
			var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
			if(moveKeysP.contains(true))
			{
				if(spr.animOffsets.get(anim) != null)
				{
					spr.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
					spr.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
				}
				else spr.offset.x = spr.offset.y = 0;
				changedOffset = true;
			}
	
			if(moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if(holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while(holdingArrowsElapsed > (1/60))
					{
						if(spr.animOffsets.get(anim) != null)
						{
							spr.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
							spr.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
						}
						else spr.offset.x = spr.offset.y = 0;
						holdingArrowsElapsed -= (1/60);
						changedOffset = true;
					}
				}
			}
			else holdingArrowsTime = 0;
	
			if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
			{
				spr.offset.x -= FlxG.mouse.deltaScreenX;
				spr.offset.y -= FlxG.mouse.deltaScreenY;
				changedOffset = true;
			}

			if (FlxG.keys.justPressed.R && FlxG.keys.pressed.CONTROL)
			{
				if(target.animations != null && target.animations[curAnim] != null) {
					target.animations[curAnim].offsets = null;
					target.animations[curAnim].playerOffsets = null;
				}
				spr.animOffsets.remove(anim);
				spr.updateHitbox();
				animsTxtGroup.members[curAnim].text = '${anim}: Sem offsets';
			}
			
			if(changedOffset && target.animations != null && target.animations[curAnim] != null)
			{
				var offX = Math.round(spr.offset.x);
				var offY = Math.round(spr.offset.y);

				spr.addOffset(anim, offX, offY);
				target.animations[curAnim].offsets = [offX, offY];
				target.animations[curAnim].playerOffsets = [offX, offY];
				animsTxtGroup.members[curAnim].text = '${anim}: ${spr.animOffsets.get(anim)}';
			}
		}

		var camX:Float = 0;
		var camY:Float = 0;
		var camMove:Float = elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.J) camX -= camMove;
		if (FlxG.keys.pressed.K) camY += camMove;
		if (FlxG.keys.pressed.L) camX += camMove;
		if (FlxG.keys.pressed.I) camY -= camMove;

		if(camX != 0 || camY != 0)
		{
			FlxG.camera.scroll.x += camX;
			FlxG.camera.scroll.y += camY;
		}

		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = 0.5;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);

		if(FlxG.keys.justPressed.ESCAPE)
		{
			persistentDraw = true;
			close();
		}
	}
}