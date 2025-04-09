package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

class StrumNote extends OffsettableSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;

	// Weekend Note Implementation
	public var separateSheets:Bool = false;

	// I don't like using isPixelStage;
	public var isPixel:Bool = false;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
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
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData];
		
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		var useLegacyArrowSkin:Bool = false;
		if(PlayState.SONG != null && PlayState.SONG.noteStyle != null && PlayState.SONG.noteStyle.length > 1) { // old charts
			useLegacyArrowSkin = true;
			skin = PlayState.SONG.noteStyle;
		} else if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1 && !useLegacyArrowSkin) skin = PlayState.SONG.arrowSkin;
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

	public function reloadNote()
	{
		separateSheets = false;
		isLegacyNoteSkin = false;
		animOffsets.clear();
		
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		var notePath:String = texture;
		if (notePath == 'normal') notePath = "noteSkins/NOTE_assets";

		var curNotePath = notePath;

		for (noteDirectory in ["noteSkins/", "notes/"]) {
			final fullPath = '$noteDirectory$notePath';
			final strumlinePath = '$fullPath/notes_strumline';
			var jsonPath = fullPath;
		
			if (Paths.fileExists('images/$strumlinePath.png', IMAGE)) {
				separateSheets = true;
				jsonPath = '$noteDirectory$notePath/$notePath';
				notePath = strumlinePath;
			} else if (Paths.fileExists('images/$fullPath.png', IMAGE)) {
				notePath = fullPath;
			}

			if (Paths.fileExists('images/$jsonPath.json', TEXT)) {
				final json = Note.getNoteFile('images/$jsonPath');
				if (json.strumAnimations != null) {
					for (anim in json.strumAnimations) {
						addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
					}
				}
			}
		
			if (curNotePath != notePath) {
				isLegacyNoteSkin = (noteDirectory == "notes/");
				break;
			}
		}

		var isCustomNoteSkin:Bool = false;
		var CustomNoteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		for (i in 0...CustomNoteSkins.length) {
			if (CustomNoteSkins[i] == texture) isCustomNoteSkin = true;
		}

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(notePath);
			loadNoteAnims();
		}
		updateHitbox();

		if (frames == null){ // Set to default if no frames found so it doesn't crash
			texture = Note.defaultNoteSkin;
		} 

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
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

		if (separateSheets && !isPixel){
			offset.x += 32;
			offset.y += 20;
		}

		var daOffsets = getAnimOffset(anim);
		
		offset.x += daOffsets[0];
		offset.y += daOffsets[1];
		
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	public function loadNoteAnims(isPixel:Bool = false){
		if (isPixel){

		}else{
			if (separateSheets){
				var dirArr:Array<String> = ["Left", "Down", "Up", "Right"];

				animation.addByPrefix("static", "static" + dirArr[noteData]);
				animation.addByPrefix("pressed", "press" + dirArr[noteData], 24, false);
				animation.addByPrefix("confirm", "confirm" + dirArr[noteData], 24, false);
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
			setGraphicSize(Std.int(width * 0.7));

		}
	}
}
