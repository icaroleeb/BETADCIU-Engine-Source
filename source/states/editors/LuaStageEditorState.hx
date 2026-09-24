package states.editors;

import backend.StageData;
import backend.PsychCamera;
import objects.Character;
import psychlua.LuaUtils;

import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;
import openfl.display.Sprite;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import psychlua.ModchartSprite;
import flash.net.FileFilter;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import states.editors.content.Prompt;
import states.editors.content.PreloadListSubState;

import states.editors.content.StageEditorAnimationSubstate;
import states.editors.content.StageEditorMetaSprite;

class LuaStageEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	final minZoom = 0.1;
	final maxZoom = 2;

	var outputTime:Float = 0;

	var gf:Character;
	var dad:Character;
	var boyfriend:Character;
	var stageJson:StageFile;

	var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	var UI_stagebox:PsychUIBox;
	var UI_box:PsychUIBox;
	var spriteList_box:PsychUIBox;
	var stageSprites:Array<StageEditorMetaSprite> = [];
	
	public function new(stageToLoad:String = 'stage', cachedJson:StageFile = null)
	{
		lastLoadedStage = stageToLoad;
		stageJson = cachedJson;
		super();
	}

	var lastLoadedStage:String;
	var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var posTxt:FlxText;
	var outputTxt:FlxText;

	var animationEditor:StageEditorAnimationSubstate;
	var unsavedProgress:Bool = false;
	
	var selectionSprites:FlxSpriteGroup = new FlxSpriteGroup();

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Lua Stage Editor', 'Stage: ' + lastLoadedStage);
		#end

		if(stageJson == null) stageJson = StageData.getStageFile(lastLoadedStage);
		FlxG.camera.follow(null, LOCKON, 0);

		loadJsonAssetDirectory();
		gf = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.gf : 'gf');
		gf.visible = !(stageJson.hide_girlfriend);
		dad = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.dad : 'dad');
		boyfriend = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.boyfriend : 'bf', true);

		for (i in 0...4)
		{
			var spr:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.LIME);
			spr.alpha = 0.8;
			selectionSprites.add(spr);
		}

		FlxG.camera.zoom = stageJson.defaultZoom;
		repositionGirlfriend();
		repositionDad();
		repositionBoyfriend();

		screenUI();
		spriteCreatePopup();
		editorUI();

		var point = focusOnTarget('boyfriend');
		FlxG.camera.scroll.set(point.x - FlxG.width/2, point.y - FlxG.height/2);
		
		add(camFollow);
		updateSpriteList();

		addHelpScreen();
		FlxG.mouse.visible = true;
		animationEditor = new StageEditorAnimationSubstate();

		super.create();
	}

	function loadJsonAssetDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = stageJson.directory;
		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		Paths.setCurrentLevel(directory);
	}

	var showSelectionQuad:Bool = true;
	function addHelpScreen()
	{
		#if FLX_DEBUG
		var btn = 'F3';
		#else
		var btn = 'F2';
		#end

		var str:Array<String> = [
			"E/Q - Zoom In/Out",
			"J/K/L/I - Move Camera",
			"R - Reset Zoom",
			"Arrow Keys / R. Mouse - Move Object",
			'$btn - Toggle HUD',
			"F12 - Toggle Selection Box",
			"Shift - Move 4x faster",
			"Control - Move pixel by pixel"
		];

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
			var helpText:FlxText = new FlxText(0, 0, 680, txt, 16);
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

	function loadObjectsFromLuaScript(stageName:String)
	{
		var luaPath:String = Paths.getPath('stages/$stageName.lua', TEXT, null, true);
		var content:String = null;

		#if sys
		if (FileSystem.exists(luaPath))
			content = File.getContent(luaPath);
		#else
		if (Assets.exists(luaPath))
			content = Assets.getText(luaPath);
		#end

		if (content == null || content.length == 0) return;

		var currentImagePath:String = "";
		var lines:Array<String> = content.split('\n');
		
		var spriteDataMap:Map<String, {x: Float, y: Float, scaleX: Float, scaleY: Float, scrollX: Float, scrollY: Float, img: String, isAnim: Bool}> = [];
		var spriteOrder:Array<String> = [];

		for (line in lines)
		{
			line = line.trim();

			if ((line.indexOf("imagePath") != -1 || line.indexOf("path") != -1) && line.indexOf("=") != -1 && (line.indexOf("\"") != -1 || line.indexOf("'") != -1))
			{
				var pSplit = line.split('"');
				if (pSplit.length >= 2) currentImagePath = pSplit[1];
				else {
					var pSplit2 = line.split("'");
					if (pSplit2.length >= 2) currentImagePath = pSplit2[1];
				}
			}

			if (line.startsWith('makeAnimatedLuaSprite') || line.startsWith('makeLuaSprite') || line.startsWith('makeVideoSprite'))
			{
				var quoteSplit = line.split('"');
				if (quoteSplit.length < 4) quoteSplit = line.split("'");

				if (quoteSplit.length >= 4)
				{
					var sprName:String = quoteSplit[1];
					var rawImg:String = quoteSplit[3];

					var sprImage:String = rawImg;
					if (line.contains("..") || rawImg.indexOf("imagePath") != -1 || !rawImg.contains("/")) {
						if (!rawImg.startsWith("backgrounds/") && !rawImg.startsWith("stages/") && currentImagePath != "") {
							sprImage = currentImagePath + rawImg;
						}
					}

					sprImage = StringTools.replace(sprImage, "imagePath .. '", "");
					sprImage = StringTools.replace(sprImage, 'imagePath .. "', "");
					sprImage = StringTools.replace(sprImage, "imagePath..'", "");
					sprImage = StringTools.replace(sprImage, 'imagePath.."', "");
					sprImage = StringTools.replace(sprImage, "'", "");
					sprImage = StringTools.replace(sprImage, '"', "");

					var posX:Float = 0;
					var posY:Float = 0;
					var commaSplit = line.split(',');
					if (commaSplit.length >= 3)
					{
						var xStr = commaSplit[commaSplit.length - 2].trim();
						var yStr = commaSplit[commaSplit.length - 1].split(')')[0].trim();
						posX = Std.parseFloat(xStr);
						posY = Std.parseFloat(yStr);
						if (Math.isNaN(posX)) posX = 0;
						if (Math.isNaN(posY)) posY = 0;
					}

					if (!spriteDataMap.exists(sprName))
						spriteOrder.push(sprName);

					spriteDataMap.set(sprName, {
						x: posX,
						y: posY,
						scaleX: 1,
						scaleY: 1,
						scrollX: 1,
						scrollY: 1,
						img: sprImage,
						isAnim: line.startsWith('makeAnimatedLuaSprite')
					});
				}
			}
			else if (line.startsWith('scaleObject'))
			{
				var quoteSplit = line.split('"');
				if (quoteSplit.length < 2) quoteSplit = line.split("'");

				if (quoteSplit.length >= 2)
				{
					var sprName = quoteSplit[1];
					var commaSplit = line.split(',');
					if (commaSplit.length >= 3 && spriteDataMap.exists(sprName))
					{
						var sX = Std.parseFloat(commaSplit[1].trim());
						var sYStr = commaSplit[2].split(')')[0].trim();
						var sY = Std.parseFloat(sYStr);
						
						var data = spriteDataMap.get(sprName);
						if (!Math.isNaN(sX)) data.scaleX = sX;
						if (!Math.isNaN(sY)) data.scaleY = sY;
					}
				}
			}
			else if (line.startsWith('setScrollFactor'))
			{
				var quoteSplit = line.split('"');
				if (quoteSplit.length < 2) quoteSplit = line.split("'");

				if (quoteSplit.length >= 2)
				{
					var sprName = quoteSplit[1];
					var commaSplit = line.split(',');
					if (commaSplit.length >= 3 && spriteDataMap.exists(sprName))
					{
						var scX = Std.parseFloat(commaSplit[1].trim());
						var scY = Std.parseFloat(commaSplit[2].split(')')[0].trim());
						var data = spriteDataMap.get(sprName);
						if (!Math.isNaN(scX)) data.scrollX = scX;
						if (!Math.isNaN(scY)) data.scrollY = scY;
					}
				}
			}
		}

		for (sprName in spriteOrder)
		{
			var info = spriteDataMap.get(sprName);
			var exists:Bool = false;
			for (spr in stageSprites) {
				if (spr != null && spr.name == sprName) {
					exists = true;
					break;
				}
			}

			if (!exists)
			{
				var modSprite = new ModchartSprite();
				var meta = new StageEditorMetaSprite({
					type: info.isAnim ? 'animatedSprite' : 'sprite',
					name: sprName,
					image: info.img,
					scale: [info.scaleX, info.scaleY],
					scroll: [info.scrollX, info.scrollY]
				}, modSprite);

				meta.image = info.img;
				meta.x = info.x;
				meta.y = info.y;
				meta.setScale(info.scaleX, info.scaleY);
				meta.setScrollFactor(info.scrollX, info.scrollY);
				stageSprites.push(meta);
			}
		}
	}

	function updateSpriteList()
	{
		for (spr in stageSprites)
			if(spr != null && !StageData.reservedNames.contains(spr.type))
				spr.sprite = FlxDestroyUtil.destroy(spr.sprite);

		stageSprites = [];
		var list:Map<String, FlxSprite> = [];
		
		if(stageJson.objects != null && stageJson.objects.length > 0)
		{
			list = StageData.addObjectsToState(stageJson.objects, gf, dad, boyfriend, null, true);
			for (key => spr in list)
				stageSprites[spr.ID] = new StageEditorMetaSprite(stageJson.objects[spr.ID], spr);
		}

		loadObjectsFromLuaScript(lastLoadedStage);

		for (character in ['gf', 'dad', 'boyfriend'])
			if(!list.exists(character))
				stageSprites.push(new StageEditorMetaSprite({type: character}, Reflect.field(this, character)));

		updateSpriteListRadio();
	}

	var spriteListRadioGroup:PsychUIRadioGroup;
	var focusRadioGroup:PsychUIRadioGroup;

	function screenUI()
	{
		var lowQualityCheckbox:PsychUICheckBox = null;
		var highQualityCheckbox:PsychUICheckBox = null;
		function visibilityFilterUpdate()
		{
			curFilters = 0;
			if(lowQualityCheckbox != null && lowQualityCheckbox.checked) curFilters |= LOW_QUALITY;
			if(highQualityCheckbox != null && highQualityCheckbox.checked) curFilters |= HIGH_QUALITY;
		}

		spriteList_box = new PsychUIBox(25, 40, 250, 200, ['Lua Sprites']);
		spriteList_box.scrollFactor.set();
		spriteList_box.cameras = [camHUD];
		add(spriteList_box);
		addSpriteListBox();

		var bg:FlxSprite = new FlxSprite(0, FlxG.height - 60).makeGraphic(1, 1, FlxColor.BLACK);
		bg.cameras = [camHUD];
		bg.alpha = 0.4;
		bg.scale.set(FlxG.width, FlxG.height - bg.y);
		bg.updateHitbox();
		add(bg);
		
		var tipText:FlxText = new FlxText(0, FlxG.height - 44, 300, 'Press F1 for Help', 20);
		tipText.alignment = CENTER;
		tipText.cameras = [camHUD];
		tipText.scrollFactor.set();
		tipText.screenCenter(X);
		tipText.active = false;
		add(tipText);

		var targetTxt:FlxText = new FlxText(30, FlxG.height - 52, 300, 'Camera Target', 16);
		targetTxt.alignment = CENTER;
		targetTxt.cameras = [camHUD];
		targetTxt.scrollFactor.set();
		targetTxt.active = false;
		add(targetTxt);

		focusRadioGroup = new PsychUIRadioGroup(targetTxt.x, FlxG.height - 24, ['dad', 'boyfriend', 'gf'], 10, 0, true);
		focusRadioGroup.onClick = function() {
			if (focusRadioGroup != null && focusRadioGroup.checked > -1) {
				var point = focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
				camFollow.setPosition(point.x, point.y);
				FlxG.camera.target = camFollow;
			}
		}
		focusRadioGroup.radios[0].label = 'Opponent';
		focusRadioGroup.radios[1].label = 'Boyfriend';
		focusRadioGroup.radios[2].label = 'Girlfriend';

		for (radio in focusRadioGroup.radios)
			radio.text.size = 11;
		
		focusRadioGroup.cameras = [camHUD];
		add(focusRadioGroup);

		lowQualityCheckbox = new PsychUICheckBox(FlxG.width - 240, FlxG.height - 36, 'Low Quality?', 90);
		lowQualityCheckbox.cameras = [camHUD];
		lowQualityCheckbox.onClick = visibilityFilterUpdate;
		lowQualityCheckbox.checked = false;
		add(lowQualityCheckbox);

		highQualityCheckbox = new PsychUICheckBox(FlxG.width - 120, FlxG.height - 36, 'High Quality?', 90);
		highQualityCheckbox.cameras = [camHUD];
		highQualityCheckbox.onClick = visibilityFilterUpdate;
		highQualityCheckbox.checked = true;
		add(highQualityCheckbox);
		visibilityFilterUpdate();

		posTxt = new FlxText(0, 50, 500, 'X: 0\nY: 0', 24);
		posTxt.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		posTxt.borderSize = 2;
		posTxt.cameras = [camHUD];
		posTxt.screenCenter(X);
		posTxt.visible = false;
		add(posTxt);

		outputTxt = new FlxText(0, 0, 800, '', 24);
		outputTxt.alignment = CENTER;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.borderSize = 1;
		outputTxt.cameras = [camHUD];
		outputTxt.screenCenter();
		outputTxt.alpha = 0;
		add(outputTxt);
	}

	function addSpriteListBox()
	{
		var tab_group = spriteList_box.getTab('Lua Sprites').menu;
		spriteListRadioGroup = new PsychUIRadioGroup(10, 10, [], 25, 18, false, 200);
		spriteListRadioGroup.cameras = [camHUD];
		spriteListRadioGroup.onClick = function() {
			updateSelectedUI();
		}
		tab_group.add(spriteListRadioGroup);
		
		var buttonX = spriteList_box.x + spriteList_box.width - 10;
		var buttonY = spriteListRadioGroup.y - 30;
		var buttonMoveUp:PsychUIButton = new PsychUIButton(buttonX, buttonY, 'Move Up', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if(spr == null) return;

			var newSel:Int = Std.int(Math.min(stageSprites.length-1, selected + 1));
			stageSprites.remove(spr);
			stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveUp.cameras = [camHUD];
		tab_group.add(buttonMoveUp);

		var buttonMoveDown:PsychUIButton = new PsychUIButton(buttonX, buttonY + 30, 'Move Down', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if(spr == null) return;

			var newSel:Int = Std.int(Math.max(0, selected - 1));
			stageSprites.remove(spr);
			stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveDown.cameras = [camHUD];
		tab_group.add(buttonMoveDown);
		
		var buttonCreate:PsychUIButton = new PsychUIButton(buttonX, buttonY + 60, 'New', function() createPopup.visible = createPopup.active = true);
		buttonCreate.cameras = [camHUD];
		buttonCreate.normalStyle.bgColor = FlxColor.GREEN;
		buttonCreate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonCreate);

		var buttonDuplicate:PsychUIButton = new PsychUIButton(buttonX, buttonY + 90, 'Duplicate', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if(spr == null || StageData.reservedNames.contains(spr.type)) return;

			var copiedSpr = new ModchartSprite();
			var copiedMeta:StageEditorMetaSprite = new StageEditorMetaSprite(null, copiedSpr);
			for (field in Reflect.fields(spr))
			{
				if(field == 'sprite') continue;
				try {
					var fld:Dynamic = Reflect.getProperty(spr, field);
					Reflect.setProperty(copiedMeta, field, fld);
				} catch(e:Dynamic) {}
			}
			copiedMeta.name = findUnoccupiedName('${copiedMeta.name}_copy');
			insertMeta(copiedMeta, 1);
		});
		buttonDuplicate.cameras = [camHUD];
		buttonDuplicate.normalStyle.bgColor = FlxColor.BLUE;
		buttonDuplicate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDuplicate);
	
		var buttonDelete:PsychUIButton = new PsychUIButton(buttonX, buttonY + 120, 'Delete', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = stageSprites[selected];
			if(spr == null || StageData.reservedNames.contains(spr.type)) return;

			stageSprites.remove(spr);
			spr.sprite = FlxDestroyUtil.destroy(spr.sprite);
			updateSpriteListRadio();
		});
		buttonDelete.cameras = [camHUD];
		buttonDelete.normalStyle.bgColor = FlxColor.RED;
		buttonDelete.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDelete);
	}

	function showOutput(txt:String, isError:Bool = false)
	{
		outputTxt.color = isError ? FlxColor.RED : FlxColor.WHITE;
		outputTxt.text = txt;
		outputTime = 3;
		if(isError) FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
		else FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	var createPopup:FlxSpriteGroup;
	function findUnoccupiedName(prefix = 'luaSprite')
	{
		var num:Int = 1;
		var name:String = 'unnamed';
		while(true)
		{
			var cantUseName:Bool = false;
			name = prefix + num;
			for (basic in stageSprites)
			{
				if(basic.name == name) { cantUseName = true; break; }
			}
			if(cantUseName) { num++; continue; }
			break;
		}
		return name;
	}

	function insertMeta(meta, insertOffset:Int = 0)
	{
		var num:Int = Std.int(Math.max(0, Math.min(spriteListRadioGroup.labels.length, spriteListRadioGroup.labels.length - spriteListRadioGroup.checked - 1 + insertOffset)));
		stageSprites.insert(num, meta);
		updateSpriteListRadio();
		createPopup.visible = createPopup.active = false;
		spriteListRadioGroup.checked = spriteListRadioGroup.labels.length - num - 1;
		updateSelectedUI();
		unsavedProgress = true;
	}

	function spriteCreatePopup()
	{
		createPopup = new FlxSpriteGroup();
		createPopup.cameras = [camHUD];
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scale.set(300, 240);
		bg.updateHitbox();
		bg.screenCenter();
		createPopup.add(bg);

		var txt:FlxText = new FlxText(0, bg.y + 10, 180, 'New Sprite', 24);
		txt.screenCenter(X);
		txt.alignment = CENTER;
		createPopup.add(txt);

		var btnY = 320;
		var btn:PsychUIButton = new PsychUIButton(0, btnY, 'No Animation', function() loadImage('sprite'));
		btn.screenCenter(X);
		createPopup.add(btn);

		btnY += 50;
		var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Animated', function() loadImage('animatedSprite'));
		btn.screenCenter(X);
		createPopup.add(btn);

		btnY += 50;
		var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Solid Color', function() {
			var meta:StageEditorMetaSprite = new StageEditorMetaSprite({type: 'square', scale: [200, 200], name: findUnoccupiedName()}, new ModchartSprite());
			meta.sprite.makeGraphic(1, 1, FlxColor.WHITE);
			meta.sprite.scale.set(200, 200);
			meta.sprite.updateHitbox();
			meta.sprite.screenCenter();
			insertMeta(meta);
		});
		btn.screenCenter(X);
		createPopup.add(btn);
		add(createPopup);
		createPopup.visible = createPopup.active = false;
	}
	
	function updateSpriteListRadio()
	{
		var _sel:String = (spriteListRadioGroup.checkedRadio != null ? spriteListRadioGroup.checkedRadio.label : null);
		var nameList:Array<String> = [];
		for (spr in stageSprites)
		{
			if(spr == null) continue;
			switch(spr.type)
			{
				case 'gf': nameList.push('- Girlfriend -');
				case 'boyfriend': nameList.push('- Boyfriend -');
				case 'dad': nameList.push('- Opponent -');
				default: nameList.push(spr.name);
			}
		}
		nameList.reverse();
		
		spriteListRadioGroup.labels = nameList;
		for (radio in spriteListRadioGroup.radios)
		{
			if(radio.label == _sel) { spriteListRadioGroup.checkedRadio = radio; break; }
		}

		final maxNum:Int = 19;
		spriteList_box.resize(250, Std.int(Math.min(maxNum, spriteListRadioGroup.labels.length) * 25 + 35));
	}

	function editorUI()
	{
		UI_box = new PsychUIBox(FlxG.width - 225, 10, 200, 400, ['Meta', 'Data', 'Object']);
		UI_box.cameras = [camHUD];
		UI_box.scrollFactor.set();
		add(UI_box);
		UI_box.selectedName = 'Data';

		UI_stagebox = new PsychUIBox(FlxG.width - 275, 25, 250, 100, ['Stage']);
		UI_stagebox.cameras = [camHUD];
		UI_stagebox.scrollFactor.set();
		add(UI_stagebox);
		UI_box.y += UI_stagebox.y + UI_stagebox.height;

		addDataTab();
		addObjectTab();
		addMetaTab();
		addStageTab();
	}

	var directoryDropDown:PsychUIDropDownMenu;
	var uiInputText:PsychUIInputText;
	var hideGirlfriendCheckbox:PsychUICheckBox;
	var zoomStepper:PsychUINumericStepper;
	var cameraSpeedStepper:PsychUINumericStepper;
	var camDadStepperX:PsychUINumericStepper;
	var camDadStepperY:PsychUINumericStepper;
	var camGfStepperX:PsychUINumericStepper;
	var camGfStepperY:PsychUINumericStepper;
	var camBfStepperX:PsychUINumericStepper;
	var camBfStepperY:PsychUINumericStepper;

	function addDataTab()
	{
		var tab_group = UI_box.getTab('Data').menu;
		var objX = 10;
		var objY = 20;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Compiled Assets:'));

		var folderList:Array<String> = [''];
		#if sys
		for (folder in FileSystem.readDirectory('assets/'))
			if(FileSystem.isDirectory('assets/$folder') && folder != 'shared' && !Mods.ignoreModFolders.contains(folder))
				folderList.push(folder);
		#end

		var saveButton:PsychUIButton = new PsychUIButton(UI_box.width - 90, UI_box.height - 50, 'Save', function() { saveData(); });
		tab_group.add(saveButton);

		directoryDropDown = new PsychUIDropDownMenu(objX, objY, folderList, function(sel:Int, selected:String) {
			stageJson.directory = selected;
			saveObjectsToJson();
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new LuaStageEditorState(lastLoadedStage, stageJson));
		});
		directoryDropDown.selectedLabel = stageJson.directory;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'UI Style:'));
		uiInputText = new PsychUIInputText(objX, objY, 100, stageJson.stageUI != null ? stageJson.stageUI : '', 8);
		uiInputText.onChange = function(old:String, cur:String) stageJson.stageUI = uiInputText.text;

		objY += 30;
		hideGirlfriendCheckbox = new PsychUICheckBox(objX, objY, 'Hide Girlfriend?', 100);
		hideGirlfriendCheckbox.onClick = function()
		{
			stageJson.hide_girlfriend = hideGirlfriendCheckbox.checked;
			gf.visible = !hideGirlfriendCheckbox.checked;
		};
		hideGirlfriendCheckbox.checked = !gf.visible;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Offsets:'));

		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Opponent:'));
		camDadStepperX = new PsychUINumericStepper(objX, objY, 50, 0, -10000, 10000, 0);
		camDadStepperY = new PsychUINumericStepper(objX + 80, objY, 50, 0, -10000, 10000, 0);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Girlfriend:'));
		camGfStepperX = new PsychUINumericStepper(objX, objY, 50, 0, -10000, 10000, 0);
		camGfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, 0, -10000, 10000, 0);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Boyfriend:'));
		camBfStepperX = new PsychUINumericStepper(objX, objY, 50, 0, -10000, 10000, 0);
		camBfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, 0, -10000, 10000, 0);

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Data:'));
		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Zoom:'));
		zoomStepper = new PsychUINumericStepper(objX, objY, 0.05, stageJson.defaultZoom, minZoom, maxZoom, 2);
		zoomStepper.onValueChange = function() {
			stageJson.defaultZoom = zoomStepper.value;
			FlxG.camera.zoom = stageJson.defaultZoom;
		};

		tab_group.add(new FlxText(objX + 80, objY - 18, 100, 'Speed:'));
		cameraSpeedStepper = new PsychUINumericStepper(objX + 80, objY, 0.1, stageJson.camera_speed != null ? stageJson.camera_speed : 1, 0, 10, 2);

		tab_group.add(hideGirlfriendCheckbox);
		tab_group.add(camDadStepperX);
		tab_group.add(camDadStepperY);
		tab_group.add(camGfStepperX);
		tab_group.add(camGfStepperY);
		tab_group.add(camBfStepperX);
		tab_group.add(camBfStepperY);
		tab_group.add(zoomStepper);
		tab_group.add(cameraSpeedStepper);
		tab_group.add(uiInputText);
		tab_group.add(directoryDropDown);
	}
	
	function _updateCamera()
	{
		if(focusRadioGroup != null && focusRadioGroup.checked > -1)
		{
			var point = focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			camFollow.setPosition(point.x, point.y);
		}
	}

	var colorInputText:PsychUIInputText;
	var nameInputText:PsychUIInputText;
	var imgTxt:FlxText;

	var scaleStepperX:PsychUINumericStepper;
	var scaleStepperY:PsychUINumericStepper;
	var scrollStepperX:PsychUINumericStepper;
	var scrollStepperY:PsychUINumericStepper;
	var angleStepper:PsychUINumericStepper;
	var alphaStepper:PsychUINumericStepper;

	var antialiasingCheckbox:PsychUICheckBox;
	var flipXCheckBox:PsychUICheckBox;
	var flipYCheckBox:PsychUICheckBox;
	var lowQualityCheckbox:PsychUICheckBox;
	var highQualityCheckbox:PsychUICheckBox;

	function getSelected(blockReserved:Bool = true)
	{
		var selected:Int = spriteListRadioGroup.checked;
		if(selected >= 0)
		{
			var spr = stageSprites[spriteListRadioGroup.labels.length - selected - 1];
			if(spr != null && (!blockReserved || !StageData.reservedNames.contains(spr.type)))
				return spr;
		}
		return null;
	}

	function addObjectTab()
	{
		var tab_group = UI_box.getTab('Object').menu;
		var objX = 10;
		var objY = 30;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Name (for Lua/HScript):'));
		nameInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		nameInputText.onChange = function(old:String, cur:String) {
			var selected = getSelected();
			if(selected != null) {
				selected.name = nameInputText.text;
				spriteListRadioGroup.checkedRadio.label = selected.name;
			}
		};
		tab_group.add(nameInputText);

		objY += 35;
		imgTxt = new FlxText(objX, objY - 15, 200, 'Image: ', 8);
		var imgButton:PsychUIButton = new PsychUIButton(objX, objY, 'Change Image', function() { loadImage(); });
		tab_group.add(imgButton);
		tab_group.add(imgTxt);
		
		var animationsButton:PsychUIButton = new PsychUIButton(objX + 90, objY, 'Animations', function() {
			var selected = getSelected();
			if(selected == null || selected.type != 'animatedSprite') return;
			destroySubStates = false;
			persistentDraw = false;
			animationEditor.target = selected;
			unsavedProgress = true;
			openSubState(animationEditor);
		});
		tab_group.add(animationsButton);
		
		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Color:'));
		colorInputText = new PsychUIInputText(objX, objY, 80, 'FFFFFF', 8);
		colorInputText.onChange = function(old:String, cur:String) {
			var selected = getSelected();
			if(selected != null) selected.color = colorInputText.text;
		};
		tab_group.add(colorInputText);

		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Scale (X/Y):'));
		scaleStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperX.onValueChange = scaleStepperY.onValueChange = function() {
			var selected = getSelected();
			if(selected != null) selected.setScale(scaleStepperX.value, scaleStepperY.value);
		};
		tab_group.add(scaleStepperX);
		tab_group.add(scaleStepperY);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Scroll Factor (X/Y):'));
		scrollStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0, 10, 2);
		scrollStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0, 10, 2);
		scrollStepperX.onValueChange = scrollStepperY.onValueChange = function() {
			var selected = getSelected();
			if(selected != null) selected.setScrollFactor(scrollStepperX.value, scrollStepperY.value);
		};
		tab_group.add(scrollStepperX);
		tab_group.add(scrollStepperY);
		
		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Opacity:'));
		alphaStepper = new PsychUINumericStepper(objX, objY, 0.1, 1, 0, 1, 2, true);
		alphaStepper.onValueChange = function() {
			var selected = getSelected();
			if(selected != null) selected.alpha = alphaStepper.value;
		};
		tab_group.add(alphaStepper);

		antialiasingCheckbox = new PsychUICheckBox(objX + 90, objY, 'Anti-Aliasing', 80);
		antialiasingCheckbox.onClick = function() {
			var selected = getSelected();
			if(selected != null) selected.antialiasing = antialiasingCheckbox.checked;
		};
		tab_group.add(antialiasingCheckbox);
	}

	var oppDropdown:PsychUIDropDownMenu;
	var gfDropdown:PsychUIDropDownMenu;
	var plDropdown:PsychUIDropDownMenu;
	function addMetaTab()
	{
		var tab_group = UI_box.getTab('Meta').menu;
		var characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		if(characterList.length < 1) characterList.push('');
		
		var objX = 10;
		var objY = 20;

		oppDropdown = new PsychUIDropDownMenu(objX, objY + 60, characterList, function(sel:Int, selected:String) {
			if(selected != null && selected.length > 0) { dad.changeCharacter(selected); repositionDad(); }
		});
		gfDropdown = new PsychUIDropDownMenu(objX, objY + 120, characterList, function(sel:Int, selected:String) {
			if(selected != null && selected.length > 0) { gf.changeCharacter(selected); repositionGirlfriend(); }
		});
		plDropdown = new PsychUIDropDownMenu(objX, objY + 180, characterList, function(sel:Int, selected:String) {
			if(selected != null && selected.length > 0) { boyfriend.changeCharacter(selected); repositionBoyfriend(); }
		});

		tab_group.add(new FlxText(plDropdown.x, plDropdown.y - 18, 100, 'Player:'));
		tab_group.add(plDropdown);
		tab_group.add(new FlxText(gfDropdown.x, gfDropdown.y - 18, 100, 'Girlfriend:'));
		tab_group.add(gfDropdown);
		tab_group.add(new FlxText(oppDropdown.x, oppDropdown.y - 18, 100, 'Opponent:'));
		tab_group.add(oppDropdown);
	}

	var stageDropDown:PsychUIDropDownMenu;
	function addStageTab()
	{
		var tab_group = UI_stagebox.getTab('Stage').menu;
		stageDropDown = new PsychUIDropDownMenu(10, 30, [''], function(sel:Int, selected:String) {
			if(selected != null && selected.length > 0) {
				stageJson = StageData.getStageFile(selected);
				lastLoadedStage = selected;
				updateSpriteList();
				reloadCharacters();
			}
		});

		reloadStageDropDown();

		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 60, 'Stage:'));
		tab_group.add(stageDropDown);
	}

	function reloadStageDropDown()
	{
		var stageList:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'stages/');
		
		for (folder in foldersToCheck)
		{
			#if sys
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.toLowerCase().endsWith('.json') || file.toLowerCase().endsWith('.lua'))
					{
						var extLength = file.toLowerCase().endsWith('.json') ? '.json'.length : '.lua'.length;
						var stageToCheck:String = file.substr(0, file.length - extLength);
						if (!stageList.contains(stageToCheck))
							stageList.push(stageToCheck);
					}
				}
			}
			#end
		}

		if (!stageList.contains(lastLoadedStage))
			stageList.push(lastLoadedStage);
		if (stageList.length < 1) 
			stageList.push('stage');

		if (stageDropDown != null)
		{
			stageDropDown.list = stageList;
			stageDropDown.selectedLabel = lastLoadedStage;
		}
	}
	
	function updateSelectedUI()
	{
		var selected = getSelected(false);
		if(selected == null) return;
		posTxt.text = 'X: ${Math.round(selected.x)}\nY: ${Math.round(selected.y)}';
		posTxt.visible = true;
	}

	function reloadCharacters()
	{
		repositionGirlfriend();
		repositionDad();
		repositionBoyfriend();
	}

	public function UIEvent(id:String, sender:Dynamic) {}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(PsychUIInputText.focusOn != null) return;

		if(FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new states.editors.MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			return;
		}

		var moveX:Float = 0;
		var moveY:Float = 0;
		if (FlxG.keys.justPressed.LEFT) moveX -= 5;
		if (FlxG.keys.justPressed.RIGHT) moveX += 5;
		if (FlxG.keys.justPressed.UP) moveY -= 5;
		if (FlxG.keys.justPressed.DOWN) moveY += 5;

		if(moveX != 0 || moveY != 0)
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected >= 0)
			{
				var spr = stageSprites[spriteListRadioGroup.labels.length - selected - 1];
				if(spr != null)
				{
					spr.x += moveX;
					spr.y += moveY;
					posTxt.text = 'X: ${Math.round(spr.x)}\nY: ${Math.round(spr.y)}';
				}
			}
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 4;
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.2;

		// CAMERA CONTROLS
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
			if(FlxG.camera.target != null) FlxG.camera.target = null;
			if(focusRadioGroup != null && focusRadioGroup.checked > -1) focusRadioGroup.checked = -1;
		}

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = stageJson.defaultZoom;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
	}

	override function draw()
	{
		for (basic in stageSprites)
			if(basic.visible) basic.draw(curFilters);
		super.draw();
	}

	function focusOnTarget(target:String) return FlxPoint.weak(0, 0);
	function repositionGirlfriend() { if(gf != null) gf.setPosition(stageJson.girlfriend[0], stageJson.girlfriend[1]); }
	function repositionDad() { if(dad != null) dad.setPosition(stageJson.opponent[0], stageJson.opponent[1]); }
	function repositionBoyfriend() { if(boyfriend != null) boyfriend.setPosition(stageJson.boyfriend[0], stageJson.boyfriend[1]); }

	function saveObjectsToJson()
	{
		stageJson.objects = [];
		for (basic in stageSprites)
			stageJson.objects.push(basic.formatToJson());
	}

	function saveData()
	{
		saveObjectsToJson();
		var data = haxe.Json.stringify(stageJson, '\t');
		var fileRef = new FileReference();
		fileRef.save(data, '$lastLoadedStage.json');
	}

	function loadImage(onNewSprite:String = null) {}

	var curFilters:LoadFilters = (LOW_QUALITY)|(HIGH_QUALITY);
}