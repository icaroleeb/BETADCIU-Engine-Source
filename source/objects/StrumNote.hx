package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import haxe.Json;
import haxe.format.JsonParser;

import objects.notes.NoteSkinConfig;
import objects.notes.NoteSkinConfig.NoteSkinConfigData;
import objects.notes.NoteAnimationLoader;

using StringTools;

class StrumNote extends FunkinSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var daStyle = "style";
	public var sustainReduce:Bool = true;
	private var player:Int;

	// Weekend Note Implementation
	public var separateSheets:Bool = false;

	public var skinConfig:NoteSkinConfigData;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();

			/*
			if (texture.toLowerCase().contains('pixel')){
				pixelPerfectPosition = true;
				pixelPerfectRender = true;
			}else{
				pixelPerfectPosition = false;
				pixelPerfectRender = false;
			}
			*/
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	var daRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) {
			useRGBShader = false;
			daRGBShader = false;
		}
		
		noteData = leData;
		defaultRGB();
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.noteStyle != null && PlayState.SONG.noteStyle.length > 1) { // old charts
			isLegacyNoteSkin = true;
			skin = PlayState.SONG.noteStyle;
		} else if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1 && !isLegacyNoteSkin) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		var isCustomNoteSkin:Bool = false;
		var CustomNoteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		for (i in 0...CustomNoteSkins.length) {
			if (CustomNoteSkins[i] == skin) isCustomNoteSkin = true;
		}

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public var isLegacyNoteSkin:Bool = false;
	public var isPixelNote:Bool = false; // Needs to be global since it's used in playAnim

	public function reloadNote()
	{
		skinConfig = null;
		var skin:String = texture;

		separateSheets = false;
		isLegacyNoteSkin = false;
		useRGBShader = true;
		animOffsets.clear();
		
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		switch (texture)
		{
			case "pixel":
				texture = "NOTE_assets-pixel";
			case "normal":
				texture = "NOTE_assets";
		}

		var configPath = NoteSkinConfig.getConfigPath(texture);

		if (configPath != null){
			final json = NoteSkinConfig.get('images/$configPath');
			skinConfig = json;

			rgbShader.enabled = json.inGameColoring;
			isPixelNote = json.isPixel;

			skin = json.strumTexture;
		}else{
			var pathSplit:Array<String> = texture.split('/');
			var notePath:String = texture;

			var curNotePath = notePath;
			isPixelNote = false;

			for (noteDirectory in ["noteSkins/", "notes/", "pixelUI/noteSkins/", "pixelUI/notes/"]) {
				final fullPath = '$noteDirectory$notePath';
				final weekendPath = '$fullPath/notes_strumline';
				var jsonPath = fullPath;
			
				if (Paths.fileExists('images/$weekendPath.png', IMAGE)) {
					separateSheets = true;
					final jsonName = pathSplit[pathSplit.length - 1];

					jsonPath = '$noteDirectory$notePath/$jsonName';
					notePath = weekendPath;
				} else if (Paths.fileExists('images/$fullPath.png', IMAGE)) {
					notePath = fullPath;
				}
			
				if (curNotePath != notePath) {
					isLegacyNoteSkin = (noteDirectory == "notes/");
					isPixelNote = (noteDirectory.startsWith("pixelUI/") || StringTools.contains(notePath, "-pixel"));
					break;
				}
			}

			skin = notePath;
		}

		var isCustomNoteSkin:Bool = false;
		var CustomNoteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		for (i in 0...CustomNoteSkins.length) {
			if (CustomNoteSkins[i] == texture) isCustomNoteSkin = true;
		}

		defaultRGB(isPixelNote);

		if(isPixelNote) {
			loadGraphic(Paths.image(skin));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image(skin), true, Math.floor(width), Math.floor(height));
		}
		else{
			frames = Paths.getSparrowAtlas(skin);
		}

		loadNoteAnims(isPixelNote);
		updateHitbox();

		if (frames == null){ // Set to default if no frames found so it doesn't crash
			rgbShader.enabled = true;
			texture = Note.defaultNoteSkin;
		} 
			
		if(lastAnim != null){
			playAnim(lastAnim, true);
		}
	}

	function defaultRGB(?pixelShit:Bool=false) {
		var index:Int = Std.int(Math.abs(noteData) % 4);

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[index];
		if(pixelShit) arr = ClientPrefs.data.arrowRGBPixel[index];
		
		if(noteData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
	}

	public function playerPosition()
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		if (separateSheets && !isPixelNote){
			offset.x += 32 * (0.7 / scale.x);
			offset.y += 32 * (0.7 / scale.y);
		}

		var daOffsets = getAnimOffset(anim);
		
		offset.x += daOffsets[0] * ((isPixelNote ? PlayState.daPixelZoom : 0.7) / scale.x);
		offset.y += daOffsets[1] * ((isPixelNote ? PlayState.daPixelZoom : 0.7) / scale.y);
		
		if(useRGBShader && !isLegacyNoteSkin) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
		else if (isLegacyNoteSkin) rgbShader.enabled = false;
	}

	public function loadNoteAnims(isPixelNote:Bool = false)
	{
		if (skinConfig != null && skinConfig.receptorAnimations != null)
		{
			NoteAnimationLoader.loadNoteAnimsFromConfig(this, true);
			scale.set(0.7, 0.7);
			return;
		}

		loadLegacy(isPixelNote);
	}

	public function loadLegacy(isPixelNote:Bool = false){
		if (isPixelNote){
			antialiasing = false;
			// setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			scale.set(6, 6);

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			var index:Int = Std.int(Math.abs(noteData) % 4);
			var staticFrame:Int = index;
			var pressedFrames:Array<Int> = [index + 4, index + 8];
			var confirmFrames:Array<Int> = [index + 12, index + 16];

			// Add animations
			animation.add('static', [staticFrame]);
			animation.add('pressed', pressedFrames, 12, false);
			animation.add('confirm', confirmFrames, 24, false);
		}else{
			if (separateSheets){
				var dirArr:Array<String> = ["Left", "Down", "Up", "Right"];
				var index:Int = Std.int(Math.abs(noteData) % 4);

				animation.addByPrefix("static", "static" + dirArr[index]);
				animation.addByPrefix("pressed", "press" + dirArr[index], 24, false);
				animation.addByPrefix("confirm", "confirm" + dirArr[index], 24, false);
			} else{
				var colors:Array<String> = ['green', 'blue', 'purple', 'red'];
				var arrows:Array<String> = ['arrowUP', 'arrowDOWN', 'arrowLEFT', 'arrowRIGHT'];

				for (i in 0...colors.length) {
					animation.addByPrefix(colors[i], arrows[i]);
				}

				var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
				var index:Int = Std.int(Math.abs(noteData) % 4);

				animation.addByPrefix('static', 'arrow' + directions[index]);
				animation.addByPrefix('pressed', directions[index].toLowerCase() + ' press', 24, false);
				animation.addByPrefix('confirm', directions[index].toLowerCase() + ' confirm', 24, false);
			}	

			antialiasing = ClientPrefs.data.antialiasing;
			// setGraphicSize(Std.int(width * 0.7));
			scale.set(0.7, 0.7);
		}
	}
}
