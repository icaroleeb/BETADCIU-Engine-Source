package states.editors;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;

import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;

import flixel.group.FlxContainer;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

import states.editors.content.CharacterEditorKit.CharEditorUI;

import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.containers.menus.*;
import haxe.ui.core.Screen;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.backend.flixel.CursorHelper;
import haxe.ui.layouts.AbsoluteLayout;

using backend.ui.ToolKitUtils;

class CharacterEditorStateWIP extends UIState
{
	var character:Character;
	var ghostCharacter:Character;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:Null<FlxContainer> = null;
	var grid:FlxBackdrop;

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var bgLayer:Null<FlxContainer> = null;

	var anims = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	var camHUD:FlxCamera;

	final dadPos = new FlxPoint(100, 100);
	final bfPos = new FlxPoint(770, 100);

	var isTextFieldFocused:Bool = false;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	public var ui:CharEditorUI;

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();
		FlxG.sound.music.stop();
		#if !web // me and my lazyness to made this a mp3
		FlxG.sound.playMusic(Paths.music('kawaruslow'), 0.7);
		#end

		FlxG.cameras.reset();
		FlxG.cameras.add(camHUD = new FlxCamera(), false);
		camHUD.bgColor = 0x0;

		buildBG();

		silhouettes = new FlxContainer();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPos.x, dadPos.y - 10).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		dad.alpha = 0.2;
		silhouettes.add(dad);
		
		var boyfriend:FlxSprite = new FlxSprite(bfPos.x, bfPos.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		boyfriend.alpha = 0.2;
		silhouettes.add(boyfriend);

		healthIcon = new HealthIcon();
		add(healthIcon);
		healthIcon.visible = false;
		
		ghostCharacter = new Character(0, 0);
		ghostCharacter.visible = false;
		ghostCharacter.alpha = ghostAlpha;
		add(ghostCharacter);
		
		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(CharacterEditorState.GraphicCursorCross));
		cameraFollowPointer.antialiasing = false;
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		
		buildUI();
		addCharacter();
		reloadCharacterDropDown();

		ui.toolBar.characterDropdown.selectItemBy((item) -> return item.id == _char);

		add(cameraFollowPointer);
		// add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);


		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;


		updatePointerPos();
		character.finishAnimation();

		if(ClientPrefs.data.cacheOnGPU) Paths.clearUnusedMemory();
	}

	function addHelpScreen()
	{
		var str:Array<String> = ["CAMERA",
		"E/Q or Wheel Mouse - Camera Zoom In/Out",
		"J/K/L/I or Left Click - Move Camera",
		"R - Reset Camera Zoom",
		"",
		"CHARACTER",
		"Ctrl + R - Reset Current Offset",
		"Ctrl + C - Copy Current Offset",
		"Ctrl + V - Paste Copied Offset on Current Animation",
		"Ctrl + Z - Undo Last Paste or Reset",
		"W/S - Previous/Next Animation",
		"Space - Replay Animation",
		"Arrow Keys/Mouse & Right Click - Move Offset",
		"A/D - Frame Advance (Back/Forward)",
		"",
		"OTHER",
		"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
		"Hold Control - Move camera 4x slower"];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(respawn:Bool = false) {
		final isPlayer = (respawn ? character.isPlayer : !predictCharacterIsNotPlayer(_char));

		if (character != null) character = null;
		character = new Character(0, 0, _char, isPlayer);
		add(character);
		
		character.debugMode = true;
		character.missingCharacter = false;

		if (!respawn && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer) {
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
		}

		ui.toolBar.isPlayerCheckBox.value = character.isPlayer;

		updateCharacterPositions();
		updateAnimList();
		updateDialogBox();

		FlxTimer.wait(0, dance);
	}

	var ghostAlpha:Float = 0.6;

	function buildUI() {
		root.cameras = [camHUD];

		ui = new CharEditorUI();
		add(ui);

		ui.characterDialogBox.bindDialogToView(); // so it doesn't go offscreen

		ui.toolBar.exitMenuButton.onClick = (_) -> { exitState(); }

		// ui.toolBar.redoButton.onClick = (_) -> { triggerClipboardAction(false); }
		// ui.toolBar.undoButton.onClick = (_) -> { triggerClipboardAction(true); }

		// ui.toolBar.toggleCharBounds.onClick = (_) -> {
		// 	characterBounds.visible = !characterBounds.visible;
		// 	characterBounds.target = character;
		// }

		ui.toolBar.findComponent('stageBGCheckbox', CheckBox).onChange = (_) -> {
			bgLayer.visible = _.value.toBool();
			
			if (bgLayer.visible) {
				ui.toolBar.gridBGCheckbox.value = false;
				grid.visible = false;
			}
		}

		ui.toolBar.showSilhouettes.onChange = (_) -> {
			silhouettes.visible = _.value.toBool();
		}

		ui.toolBar.gridBGCheckbox.onChange = (_) -> {
			final val = _.value.toBool();
			if (val) {
				ui.toolBar.stageBGCheckbox.value = false;
				bgLayer.visible = false;
			}
			
			grid.visible = val;
		}

		ui.toolBar.bgView.findComponent('bgColour', ColorPickerPopup).onChange = (_) -> {
			final newColour = FlxColor.fromString(_.value.toString());
			if (FlxG.camera.bgColor != newColour)
			{
				ui.toolBar.findComponent('stageBGCheckbox', CheckBox).value = false;
				ui.toolBar.gridBGCheckbox.value = false;
			}
			
			FlxG.camera.bgColor = newColour;
		}

		ui.toolBar.refreshCharButton.onClick = (_) -> {
			reloadCharacterDropDown();
			addCharacter(true);
		}

		ui.toolBar.isPlayerCheckBox.onChange = (_) -> {
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			character.flipAnims();
			reloadAnimList();
			updateCharacterPositions();
			updatePointerPos(true);
		}

		ui.toolBar.isPlayerCheckBox.onClick = (_) -> {
			// addUndoAction(CHANGED_CHECKBOX, ui.toolBar.isPlayerCheckBox, !ui.toolBar.isPlayerCheckBox.value);
		}
		
		// opened the dropdown
		ui.toolBar.characterDropdown.onClick = (_) -> {
			// reloadCharacterDropDown();
		}
		
		// we selected a new char
		ui.toolBar.characterDropdown.onChange = (_) -> {
			if (_.data.isDropDownItem()) {
				_char = _.data.id;
				addCharacter();
				updateCharacterPositions();
				updateAnimList();
				updateDialogBox();
				// resetActions();
			}
		}
		
		ui.toolBar.saveCharacterButton.onClick = (_) -> { saveCharacter(); }
		
		ui.animationList.onClick = (_) -> {
			if (ui.animationList.animationList.selectedItem != null)
			{
				final anim = ui.animationList.animationList.selectedItem.id;
				if (character.hasAnimation(anim)) character.playAnim(anim);
				// else FlxG.sound.play(Paths.sound('ui/error'));
			}
		}
		
		ui.toolBar.loadTemplateButton.onClick = (_) -> {
			addCharacter();
			updateAnimList();
			updateDialogBox();
			// resetActions();
		}
		
		// GHOST SETTINGS
		var slider = ui.toolBar.ghostSettings.findComponent('ghostAlphaSlider', Slider);
		if (slider != null) {
			slider.onChange = (_) -> {
				if (ghostCharacter != null) {
					ghostCharacter.alpha = _.value.toFloat();
				}
			}
			
			slider.onDragStart = (_) -> {
				// addUndoAction(MOVED_SLIDER, slider, slider.value);
			}
		}
		
		var killGhostButton = ui.toolBar.ghostSettings.findComponent('killGhost', Button);
		if (killGhostButton != null) {
			killGhostButton.onClick = (_) -> {
				killGhostButton.disabled = true;
				ghostCharacter = FlxDestroyUtil.destroy(ghostCharacter);
			}
		}
		
		var ghostEnabledButton = ui.toolBar.ghostSettings.findComponent('enableGhost', Button);
		if (ghostEnabledButton != null) {
			ghostEnabledButton.onClick = (_) -> {
				if (killGhostButton != null) 
					killGhostButton.disabled = false;

				if (ghostCharacter == null) {
					ghostCharacter = new Character(0, 0, character.curCharacter);
					insert(members.indexOf(character) - 1, ghostCharacter);
				}

				var anim = anims[curAnim];
				if(!character.isAnimationNull())
				{
					var myAnim = anims[curAnim];

					if (ghostCharacter.curCharacter != character.curCharacter)
					{
						remove(ghostCharacter);
						ghostCharacter.destroy();

						ghostCharacter = new Character(0, 0, character.curCharacter);
						insert(members.indexOf(character) - 1, ghostCharacter);
					}

					ghostCharacter.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghostCharacter.animation.pause();
					
					var spr:Character = ghostCharacter;
					if(spr != null)
					{
						spr.setPosition(character.x, character.y);
						spr.antialiasing = character.antialiasing;
						spr.flipX = character.flipX;
						spr.alpha = ghostAlpha;

						spr.scale.set(character.scale.x, character.scale.y);
						spr.updateHitbox();

						spr.offset.set(character.offset.x, character.offset.y);
						spr.visible = true;

						// var otherSpr:Character = ghostCharacter;
						// if(otherSpr != null) otherSpr.visible = false;
					}
					/*hideGhostButton.active = true;
					hideGhostButton.alpha = 1;*/
					trace('created ghost image');
				}
			}
		}
		
		var ghostBlend = ui.toolBar.ghostSettings.findComponent('ghostBlend', CheckBox);
		if (ghostBlend != null) {
			ghostBlend.onChange = (_) -> {
				if (ghostCharacter != null)
				{
					final offset = _.value.toBool() ? 125 : 0;
					
					ghostCharacter.colorTransform.redOffset = offset;
					ghostCharacter.colorTransform.greenOffset = offset;
					ghostCharacter.colorTransform.blueOffset = offset;
				}
			}
			
			ghostBlend.onClick = (_) -> {
				// addUndoAction(CHANGED_CHECKBOX, ghostBlend, !ghostBlend.value);
			}
		}
		
		ui.toolBar.ghostInFront.onClick = (_) -> {
			// updateGhostLayering();
			// addUndoAction(CHANGED_CHECKBOX, ui.toolBar.ghostInFront, !ui.toolBar.ghostInFront.value);

			remove(ghostCharacter);

			var pos:Int = -1;
			if(character != null)
				pos = members.indexOf(character);

			if (ui.toolBar.ghostInFront.value) {
				insert(pos+1, ghostCharacter);
			} else {
				insert(pos-1, ghostCharacter);
			}
		}
		
		// dialogebox stuff
		
		ui.characterDialogBox.danceEveryStepper.onChange = (_) -> {
			character.danceEveryNumBeats = _.value.toInt();
		}
		
		ui.characterDialogBox.flipXCheckbox.onChange = (_) -> {
			if (character.originalFlipX == _.value.toBool()) return;
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		}
				
		ui.characterDialogBox.antialiasingCheckbox.onChange = (_) -> {
			character.noAntialiasing = !_.value.toBool();
			character.antialiasing = !character.noAntialiasing;
		}
		
		for (i in [ui.characterDialogBox.flipXCheckbox, ui.characterDialogBox.antialiasingCheckbox, ui.characterDialogBox.animationLoopCheckbox]) {
			i.onClick = (_) -> {
				// addUndoAction(CHANGED_CHECKBOX, i, !i.value);
			}
		}
		
		ui.characterDialogBox.scaleStepper.onChange = (_) -> {
			final newScale = _.value.toFloat();
			character.scale.set(newScale, newScale);
			character.updateHitbox();
			character.jsonScale = newScale;
		}
		
		ui.characterDialogBox.singLengthStepper.onChange = (_) -> {
			character.singDuration = _.value.toFloat();
		}
		
		ui.characterDialogBox.characterXStepper.onChange = (_) -> {
			character.positionArray[0] = _.value.toFloat();
			updateCharacterPositions();
		}
		
		ui.characterDialogBox.characterYStepper.onChange = (_) -> {
			character.positionArray[1] = _.value.toFloat();
			updateCharacterPositions();
		}
		
		ui.characterDialogBox.characterCamXStepper.onChange = (_) -> {
			character.cameraPosition[0] = _.value.toFloat();
		}
		
		ui.characterDialogBox.characterCamYStepper.onChange = (_) -> {
			character.cameraPosition[1] = _.value.toFloat();
		}
		
		ui.characterDialogBox.healthColourPicker.onChange = (_) -> {
			var selectedColor:FlxColor = FlxColor.fromString(Std.string(_.value));
			character.healthColorArray = [selectedColor.red, selectedColor.green, selectedColor.blue];
			
			var bgColour:FlxColor = FlxColor.interpolate(0xFF3D3F41, selectedColor, 0.1);
			ui.characterDialogBox.iconDisplay.backgroundColor = cast (bgColour : Int);

			unsavedProgress = true;		
		}
				
		ui.characterDialogBox.healthIconTextField.onChange = (_) -> {
			character.healthIcon = ui.characterDialogBox.healthIconTextField.value;
			updateHealthIcon();
		}
		
		ui.characterDialogBox.getIconColourButton.onClick = (_) -> {
			final dominantInt:Int = CoolUtil.dominantColor(healthIcon);
			final color:FlxColor = FlxColor.fromInt(dominantInt);

			ui.characterDialogBox.healthColourPicker.value = color.toWebString(); 

			character.healthColorArray = [color.red, color.green, color.blue];
			
			var bgColour:FlxColor = FlxColor.interpolate(0xFF3D3F41, color, 0.1);
			ui.characterDialogBox.iconDisplay.backgroundColor = cast (bgColour : Int);

			unsavedProgress = true;
		}
		
		ui.characterDialogBox.reloadCharacterImageButton.onClick = (_) -> {
			var lastAnim = character.getAnimationName();
			character.imageFile = ui.characterDialogBox.imageFileTextField.value;
			reloadCharacterImage();
			if(!character.isAnimationNull()) 
				character.playAnim(lastAnim, true);
		}
		
		ui.characterDialogBox.removeAnimationButton.onClick = (_) -> {
			if (ui.characterDialogBox.animationsDropdown.selectedItem == null
				|| !ui.characterDialogBox.animationsDropdown.selectedItem.isDropDownItem()) return;

			var animToFind:String = ui.characterDialogBox.animationNameTextField.text;
			var foundAnim:AnimArray = null;
			var previousIndex = -1;

			for (anim in character.animationsArray) 
			if (anim.anim == animToFind) {
				previousIndex = character.animationsArray.indexOf(anim);
				foundAnim = anim;
				break;
			}

			if (foundAnim != null) {
				if (character.animation.getByName(foundAnim.anim) != null) {
					@:privateAccess
					character.animation._animations.remove(foundAnim.anim);
				}
				
				character.animOffsets.remove(foundAnim.anim);
				if (character.animPlayerOffsets != null) character.animPlayerOffsets.remove(foundAnim.anim);
				character.animationsArray.remove(foundAnim);

				if (character.animationsArray.length > 0) {
					var nextAnim = character.animationsArray[0].anim;
					character.playAnim(nextAnim, true);
					ui.characterDialogBox.animationNameTextField.text = nextAnim; 
				} else {
					ui.characterDialogBox.animationNameTextField.text = '';
				}

				updateAnimList(); 
				trace('Removed animation: ' + animToFind);
			}

						
			if (previousIndex != -1 && character.animationsArray.length != 0) {
				final index = FlxMath.wrap(previousIndex, 0, character.animationsArray.length - 1);
				character.playAnim(character.animationsArray[index].anim);
				ui.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimationName());
				ui.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == character.getAnimationName());
			}
			
			
			updateAnimList();
		}
		
		ui.characterDialogBox.addAnimationButton.onClick = (_) -> {
			//
			final animName = ui.characterDialogBox.animationNameTextField.value;
			final prefix = ui.characterDialogBox.animationPrefixTextField.value;
			final indicesTxt = ui.characterDialogBox.animationIndicesTextField.getTextInput().text.trim().split(',');
			
			final indices:Array<Int> = [];
			
			if (indicesTxt.length > 1)
			{
				for (i in 0...indicesTxt.length)
				{
					var index:Int = Std.parseInt(indicesTxt[i]);
					if (indicesTxt[i] != null && indicesTxt[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}
			
			var hadAnim = false;
			var previousOffsets:Array<Float> = [0, 0];
			
			for (anim in character.animationsArray)
			{
				if (anim.anim == animName)
				{
					previousOffsets = anim.offsets;
					if (character.hasAnimation(animName))
					{
						@:privateAccess
						{
							character.animation.remove(animName);
							character.animation._curAnim = null; // ok
						}
						hadAnim = true;
					}
					character.animationsArray.remove(anim);
					break;
				}
			}
			
			var addedAnim:AnimArray = newAnim(animName, animName);
			addedAnim.fps = Math.round(ui.characterDialogBox.animationFramerateStepper.value);
			addedAnim.loop = ui.characterDialogBox.animationLoopCheckbox.selected;
			addedAnim.indices = indices;
				
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);
			character.addOffset(animName, previousOffsets[0], previousOffsets[1]);
			
			if (character.hasAnimation(animName))
			{
				// FlxG.sound.play(Paths.sound('ui/success'));
				
				character.playAnim(animName, true);
				
				ToolKitUtils.makeNotification('Animation Addition', 'Successfully ' + (hadAnim ? 'updated' : 'added') + ' "$animName" to character.', Success);
			}
			else
			{
				// FlxG.sound.play(Paths.sound('ui/warn'));
				ToolKitUtils.makeNotification('Animation Addition', 'Could not add "$animName" to character.', Warning);
			}
			
			updateAnimList();
			
			ui.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == animName);
			ui.animationList.animationList.selectItemBy((item) -> return item.id == animName);
		}
		
		ui.characterDialogBox.animationsDropdown.onChange = (_) -> {
			if (_.data.isDropDownItem()) fillAnimationFields(_.data.id);
		}
	}

	function updateHealthIcon() {
		if (character == null) return;
		
		healthIcon.changeIcon(character.healthIcon, false);
		ui.setHealthIcon(healthIcon.frame);
	}

	function updateAnimList() {
		if (character == null) return;
		
		final animListData:Array<ToolKitUtils.DropDownItem> = [];
		final animDropdownData:Array<ToolKitUtils.DropDownItem> = [];
		
		for (animObj in character.animationsArray) {
			if (animObj != null) {
				if (animObj.playerOffsets == null && animObj.offsets != null)
					animObj.playerOffsets = animObj.offsets;
			}
		}

		for (name => offset in character.animOffsets) {
			animListData.push({id: name, text: name + ': $offset'});
			animDropdownData.push(ToolKitUtils.makeSimpleDropDownItem(name));
		}

		ui.animationList.animationList.populateList(animListData);
		ui.characterDialogBox.animationsDropdown.populateList(animDropdownData);
				
		ui.animationList.animationList.dataSource.sort(null, ASCENDING);
		ui.characterDialogBox.animationsDropdown.dataSource.sort(null, ASCENDING);
	}

	function updateDialogBox() {
		if (character == null) return;
		
		ui.characterDialogBox.flipXCheckbox.selected = character.originalFlipX;
		ui.characterDialogBox.antialiasingCheckbox.value = !character.noAntialiasing;
		
		ui.characterDialogBox.healthColourPicker.value = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		
		ui.characterDialogBox.scaleStepper.value = character.jsonScale;
		ui.characterDialogBox.singLengthStepper.value = character.singDuration;
		ui.characterDialogBox.characterXStepper.value = character.positionArray[0];
		ui.characterDialogBox.characterYStepper.value = character.positionArray[1];
		
		ui.characterDialogBox.characterCamXStepper.value = character.cameraPosition[0];
		ui.characterDialogBox.characterCamYStepper.value = character.cameraPosition[1];
		
		ui.characterDialogBox.imageFileTextField.value = character.imageFile;
		ui.characterDialogBox.healthIconTextField.value = character.healthIcon;
		
		ui.characterDialogBox.danceEveryStepper.value = character.danceEveryNumBeats;
		
		updateHealthIcon();
				
		// animations tab
		ui.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == character.getAnimationName());
		
		fillAnimationFields(character.getAnimationName());
		
		// this isnt dialogbox!
		
		ui.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimationName());
		
		ui.toolBar.isPlayerCheckBox.selected = character.isPlayer;
	}

	function fillAnimationFields(?animationName:String)
	{
		var animName:String = '';
		var prefix:String = '';
		var indices:Array<Int> = [];
		var loops:Bool = false;
		var framerate:Int = 24;
		var flipX:Bool = false;
		var flipY:Bool = false;

		if (animationName != null) {
			for (i in character.animationsArray) {
				if (i.anim == animationName) {
					animName = i.anim;
					prefix = i.name;
					indices = i.indices ?? [];
					loops = i.loop ?? false;
					framerate = i.fps ?? 24;
					break;
				}
			}
		}
		
		ui.characterDialogBox.animationNameTextField.value = animName;
		ui.characterDialogBox.animationPrefixTextField.value = prefix;
		ui.characterDialogBox.animationIndicesTextField.value = (indices.length > 0 ? indices.join(',') : '');
		ui.characterDialogBox.animationLoopCheckbox.value = loops;
		ui.characterDialogBox.animationFramerateStepper.value = framerate;
	}

	function exitState() {
		if (_goToPlayState) {
			FlxG.switchState(PlayState.new);
			FlxG.mouse.visible = false;
		} else {
			if(!unsavedProgress) {
				FlxG.switchState(states.editors.MasterEditorMenu.new);
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				
			}
			else openSubState(new ExitConfirmationPrompt());
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if(Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			try
			{
				character.frames = Paths.getAnimateAtlas(character.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		{
			character.frames = Paths.getMultiAtlas(character.imageFile.split(','));
		}

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;

	var pressMouseCamera:Bool = true;
	var cameraZoomEditor:Float = 1.05;

	final assetFolder = 'week1';  // load from assets/week1/
	function buildBG() {
		if (bgLayer != null) return;

		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		var canLoadBG:Bool = false;
		#if ESSENTIAL_COVER_FILES canLoadBG = true; #end
		
		grid = new FlxBackdrop(FlxGridOverlay.create(100, 100, 200, 200).graphic);
		add(grid);
		grid.visible = false;
		
		bgLayer = new FlxContainer();
		add(bgLayer);

		if (canLoadBG) {
			var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
			bgLayer.add(bg);
			
			var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
		} else {
			var tempSprite:FlxSprite = new FlxSprite(0, 0).makeGraphic(64, 64, 0xFF666666);

			var bg:FlxBackdrop = new FlxBackdrop(tempSprite.graphic, XY); // so the variables doen't break
			bg.setPosition(-600, -200);
			bgLayer.add(bg);

			var stageFront:FlxBackdrop = new FlxBackdrop(tempSprite.graphic, XY); // so the variables doen't break
			stageFront.setPosition(-650, 600);
			bgLayer.add(stageFront);
		}

		Paths.currentLevel = lastLoaded;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		ToolKitUtils.update();

		isTextFieldFocused = (ToolKitUtils.currentFocus != null);
		
		if(isTextFieldFocused) {
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		cameraControls(elapsed);
		controlCharacter(elapsed);

		if(!character.isAnimationNull() && FlxG.keys.justPressed.SPACE)
			dance();

		ui.miscInfo.zoomText.text = 'Zoom: ' + FlxMath.roundDecimal(cameraZoomEditor, 2) + 'x';

		var frameInfo = '?';
		if (character != null) {
			var maxFrames = -1;
			var currentFrame:Int = 0;

			if (character.animation.curAnim != null) maxFrames = character.animation.curAnim.frames.length - 1;
			if (maxFrames < 0) maxFrames = 0;
			
			if (character != null && character.animation.curAnim != null) currentFrame = Std.int(character.animation.curAnim.curFrame);
			else currentFrame = 0;

			frameInfo = '(' + currentFrame + '/' + maxFrames + ')';
		}
		var animationText = 'Animation Frames: $frameInfo';
		ui.miscInfo.animationFramesText.color = FlxColor.WHITE;

		if (ui.animationList.animationList.selectedItem != null && !character.hasAnimation(ui.animationList.animationList.selectedItem.id)) {
			animationText = 'Error playing animation';
			ui.miscInfo.animationFramesText.color = 0xffb82433;
		}

		ui.miscInfo.animationFramesText.text = animationText;

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE)) {
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		} else if(FlxG.keys.justPressed.ESCAPE) {
			exitState();
			return;
		}
	}

	function cameraControls(elapsed:Float) {
		var cameraSpeed:Float = 8;

		if(FlxG.keys.pressed.SHIFT)
			cameraSpeed = 12;

		FlxG.camera.zoom = FlxMath.lerp(cameraZoomEditor, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * cameraSpeed));

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;

		if(FlxG.keys.pressed.SHIFT) shiftMult = 4;
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;
		if (FlxG.mouse.wheel != 0) shiftMult = 8;

		if(FlxG.keys.pressed.ALT && pressMouseCamera && FlxG.mouse.pressed && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)) {
			FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX;
			FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY;
		}

		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;

		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) cameraZoomEditor = 1;

		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			cameraZoomEditor += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) cameraZoomEditor = 3;
		} else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			cameraZoomEditor -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) cameraZoomEditor = 0.1;
		}

		if (FlxG.mouse.wheel != 0) cameraZoomEditor -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult * FlxG.mouse.wheel;
	}

	function controlCharacter(elapsed:Float) {
		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;

		if(FlxG.keys.pressed.SHIFT) {
			shiftMult = 4;
			shiftMultBig = 10;
		}
		
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;
		
		if (FlxG.mouse.wheel != 0) {
			shiftMult = 8;
			shiftMultBig = 14;
		}

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1) {
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim) {
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].anim, true);
				updateAnimList();
				ui.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimationName());
			}
		}

		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true)) {
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true)) {
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6) {
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60)) {
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)) {
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.keys.pressed.CONTROL) {
			if(FlxG.keys.justPressed.C) {
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			} else if(FlxG.keys.justPressed.V) {
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			} else if(FlxG.keys.justPressed.R) {
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			} else if(FlxG.keys.justPressed.Z && undoOffsets != null) {
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		var offsets:Array<Float> = [0, 0];
		if(changedOffset && anim != null && anim.offsets != null && !character.isPlayer) {
			anim.offsets[0] = character.offset.x;
			anim.offsets[1] = character.offset.y;

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateAnimList();

			offsets = anim.offsets;
		}

		if(changedOffset && anim != null && anim.playerOffsets != null && character.isPlayer) {
			anim.playerOffsets[0] = character.offset.x;
			anim.playerOffsets[1] = character.offset.y;

			character.addPlayerOffset(anim.anim, character.offset.x, character.offset.y);
			updateAnimList();
			offsets = anim.playerOffsets;
		}

		if (changedOffset && character != null && ui.animationList.animationList.selectedItem != null) {
			ui.animationList.animationList.selectedItem.text = character.getAnimationName() + ': $offsets';
			ui.animationList.animationList.dataSource = ui.animationList.animationList.dataSource;
		}
	}

	inline function updatePointerPos(?snap:Bool = true) {
		if(character == null || cameraFollowPointer == null) return;

		var offX:Float = 0;
		var offY:Float = 0;
		if(!character.isPlayer) {
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		} else {
			offX = character.getMidpoint().x - 100 - character.playerCameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.playerCameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if(snap) {
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width/2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height/2;
		}
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList() {
		anims = character.animationsArray;
		if(anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		if(ui.characterDialogBox.animationsDropdown != null) updateAnimList();
	}

	inline function updateCharacterPositions() {
		if((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPos.x, dadPos.y);
		else character.setPosition(bfPos.x, bfPos.y);

		if (character.isPlayer) {
			character.x += character.playerPositionArray[0];
			character.y += character.playerPositionArray[1];
		} else {
			character.x += character.positionArray[0];
			character.y += character.positionArray[1];
		}
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) ||
				name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if(!character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if(indices != null && indices.length > 0)
				character.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.anim.addBySymbol(anim, name, fps, loop);
		}

		if(!character.hasAnimation(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			playerOffsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	function reloadCharacterDropDown() {
		var characterList:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		#if MODS_ALLOWED
			var uniqueChars:Map<String, Bool> = new Map();
			var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');

			for (char in characterList) 
				uniqueChars.set(char, true);

			for (folder in foldersToCheck) {
				for (file in FileSystem.readDirectory(folder)) {
					if (file.toLowerCase().endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						uniqueChars.set(charToCheck, true);
					}
				}
			}

			characterList = [for (key in uniqueChars.keys()) key];
			if (characterList.length < 1) characterList.push('');
		#end

		ui.toolBar.characterDropdown.populateList([for (i in characterList) ToolKitUtils.makeSimpleDropDownItem(i)]);
		ui.toolBar.characterDropdown.dataSource.sort(null, ASCENDING);
	}

	inline function dance() {
		if (character == null) return;
		
		character.debugMode = false;
		character.playAnim(character.getAnimationName(), true);
		character.debugMode = true;
		
		ui.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimationName());
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if(_file != null) return;

		var wasAutoPause = FlxG.autoPause;
    	FlxG.autoPause = true;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position":	character.positionArray,
			"player_position": character.playerPositionArray,
			"camera_position": character.cameraPosition,
			"player_camera_position": character.playerCameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"is_player_char": character.isPsychPlayer,
			"_editor_isPlayer": character.isPlayer
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices', 'player_position', 'player_camera_position', 'playerOffsets']);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}

		FlxG.autoPause = wasAutoPause;
	}
}