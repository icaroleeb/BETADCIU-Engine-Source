package objects;

import openfl.Assets;
import flixel.FlxSprite;
import objects.Note;
// import objects.notes.NoteColoring; // imported on import.hx
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxTimer;
import states.PlayState;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.FunkinSprite;
import objects.notes.NoteSkinConfig;

class CoverSprite extends FunkinSprite
{
	public var spawned:Bool = false;

	public var spriteId:String = "";
	public var texture(default, set):String = null;

	public var rgbShader:RGBShaderReference;

	public var hColor:String = "";
	public var noteIndex:Int = 0;

	public var isCustomHoldCoverSkin:Bool = true;

	private function set_texture(value:String):String {
		if(texture != value) {
			value = reloadCover(value);
		}
		return value;
	}

	public function reloadCover(newTexture:String = '', postfix:String = '') {
		initFrames(noteIndex, hColor, newTexture);
		initAnimations(noteIndex, hColor);

		return newTexture;
	}

	public function initFrames(i:Int, hColor:String, skin:String = "")
	{
		this.hColor = hColor;
		this.noteIndex = i;
		
		if (hColor.length < 0) {
			if (Paths.fileExists('images/holdCovers/$skin/holdCover$hColor.png', IMAGE)){
				this.frames = Paths.getSparrowAtlas(skin.length > 0 ? 
					'holdCovers/$skin/holdCover$hColor' : 
					'holdCovers/holdCover$hColor');
			}
			else{
				this.frames = Paths.getSparrowAtlas('holdCovers/holdCover$hColor');
			}

			isCustomHoldCoverSkin = true;
		}else{
			if (Paths.fileExists('images/holdCovers/$skin/holdCover.png', IMAGE)){
				this.frames = Paths.getSparrowAtlas(skin.length > 0 ? 
					'holdCovers/$skin/holdCover' : 
					'holdCovers/holdCover');
			}
			else{
				this.frames = Paths.getSparrowAtlas('holdCovers/holdCover');
			}

			isCustomHoldCoverSkin = false;
		}
	}


	public function initAnimations(i:Int, hColor:String)
	{
		this.animation.addByPrefix("start" + Std.string(i), 'holdCoverStart'+hColor+'0', 24, false);
		this.animation.addByPrefix("loop" + Std.string(i), 'holdCover'+hColor+'0', 22, true);
		this.animation.addByPrefix("end" + Std.string(i), 'holdCoverEnd'+hColor+'0', 24, false);

		this.animation.onFinish.add((anim) -> {
			if (anim.contains("start" + Std.string(i))) this.animation.play("loop" + Std.string(i), false);
			if (anim.contains("end" + Std.string(i))) {
				this.visible = false;
				this.kill();
			}
		});	
	}
}

class HoldCover extends FlxTypedSpriteGroup<CoverSprite>
{
	public var enabled:Bool = true;
	public var isPlayer:Bool = false;

	public var config(default, set):SkinAnimConfig;
	public static var configs:Map<String, SkinAnimConfig> = new Map();
	var noteDataMap:Map<Int, String> = new Map();

	var activeCovers:Map<Int, CoverSprite> = new Map();

	public var autoRGB:Bool = true; // almost forgot to make this public lol

	public function new(enabled:Bool, isPlayer:Bool)
	{
		this.enabled = enabled;
		this.isPlayer = isPlayer;
		
		super(0, 0, 0);
	}

	function spawnNewCover(i:Int, hColor:String, noteTexture:String):CoverSprite
	{
		var hold:CoverSprite = this.recycle(CoverSprite, () -> new CoverSprite());
		hold.initFrames(i, hColor, noteTexture != null ? noteTexture : "");
		hold.initAnimations(i, hColor);
		hold.visible = true;
		hold.spriteId = '$hColor-$i';
		this.add(hold);
		return hold;
	}

	public function spawnOnNoteHit(note:Note, isReady:Bool):Void
	{
		if (note == null || !enabled || !isReady) return;

		config = null;
		var noteData:Int = note.noteData;
		var isHoldEnd:Bool = false;
		if (note.animation.curAnim != null) isHoldEnd = note.animation.curAnim.name.endsWith('end');

		var tempConfig:SkinAnimConfig = NoteSkinConfig.createConfig();

		// data is always 0-3 (Std.int(x) % 4), so the note-hit color is just Note.colArrayCapitalized[data]
		var data:Int = Std.int(noteData) % 4;
		final colors:Array<String> = ["Purple", "Blue", "Green", "Red"];
		var hColor:String = colors[data];

		if (!note.isSustainNote) 
			return;

		var existingCover:CoverSprite = activeCovers.get(data);
		if (note.texture != null && note.texture.length > 0 && existingCover != null && existingCover.texture != note.texture && !existingCover.spawned) 
			existingCover.texture = note.texture;

		if (isHoldEnd) {
			if (existingCover != null && existingCover.spawned && isPlayer) {
				existingCover.animation.play("end" + Std.string(data), false);
				existingCover.spawned = false;
				activeCovers.remove(data);
			} else if (existingCover != null && existingCover.spawned) {
				new FlxTimer().start(0.075, function(tmr:FlxTimer) {
					existingCover.visible = false;
					existingCover.spawned = false;
					existingCover.kill();
					activeCovers.remove(data);
				});
			}
			return;
		}

		if (existingCover == null || !existingCover.spawned) {
			var newCover:CoverSprite = spawnNewCover(data, hColor, note.texture);
			newCover.spawned = true;

			newCover.antialiasing = (ClientPrefs.data.antialiasing && !newCover.texture.contains('pixel'));

			newCover.rgbShader = new RGBShaderReference(newCover, NoteRGBShader.initializeGlobalRGBShader(data));
			newCover.rgbShader.saturation = 1.6; // i like this -- probably making this a config on json later if people don't like it as a default thing

			updateRGB(newCover, note, data);

			newCover.animation.play("start" + Std.string(data), false);

			activeCovers.set(data, newCover);

			return;
		} else {
			updateRGB(existingCover, note, data);
		}
	}

	function updateRGB(cover:CoverSprite, note:Note, data:Int):Void
	{
		if (note.shader != null && note.rgbShader.enabled || !cover.isCustomHoldCoverSkin)
		{
			cover.rgbShader.enabled = true;

			if (!cover.isCustomHoldCoverSkin && note.isLegacyNoteSkin && autoRGB)
			{
				final tones = NoteColorExtractor.generateTones(NoteColorExtractor.getDominantColor(note));

				cover.rgbShader.r = tones.highlight;
				cover.rgbShader.g = FlxColor.WHITE;
				cover.rgbShader.b = tones.shadow;
				cover.rgbShader.saturation = 1; // most of the custom colors are pretty saturated already, so i'll leave the saturation boost for the default coloring
			}
			else
			{
				final defaultArr:Array<FlxColor> = (!note.isPixelNote) ? ClientPrefs.data.arrowRGB[data] : ClientPrefs.data.arrowRGBPixel[data];
				if (defaultArr != null)
				{
					cover.rgbShader.r = defaultArr[0];
					cover.rgbShader.g = defaultArr[1];
					cover.rgbShader.b = defaultArr[2];
					cover.rgbShader.saturation = 1.6;  // i like this -- probably making this a config on json later if people don't like it as a default thing
				}
			}
		}
		else cover.rgbShader.enabled = false;
	}

	public function despawnOnMiss(isReady:Bool, direction:Int, ?note:Note = null):Void
	{
		var data:Int = (note != null ? Std.int(note.noteData) % 4 : direction);
		if (enabled && isReady)
		{
			var cover:CoverSprite = activeCovers.get(data);
			if (cover != null)
			{
				cover.antialiasing = (ClientPrefs.data.antialiasing && !cover.texture.contains('pixel'));
				cover.visible = false;
				cover.animation.stop();
				cover.spawned = false;
				cover.kill();
				activeCovers.remove(data);
			}
		}
	}

	public function updateHold(elapsed:Float, isReady:Bool):Void
	{
		if (!enabled || !isReady) return;
		if (PlayState.instance == null || PlayState.instance.inCutscene) return;
		
		var game:PlayState = PlayState.instance;
		if (game.strumLineNotes == null) return;

		for (member in members) 
			if (member != null && !member.alive) this.remove(member, true);

		for (data => cover in activeCovers) {
			if (cover == null || !cover.alive) {
				activeCovers.remove(data);
				continue;
			}

			var strum:StrumNote = game.strumLineNotes.members[isPlayer ? data + 4 : data];
			if (strum == null) continue;

			final targetX:Float = strum.x + (strum.width - cover.width) * 0.5 - 11;
			final targetY:Float = strum.y + (strum.height - cover.height) * 0.5 + 50;

			if (cover.x != targetX) cover.x = targetX;
			if (cover.y != targetY) cover.y = targetY;
			if (cover.alpha != strum.alpha) cover.alpha = strum.alpha;
		}
  	}

	function set_config(value:SkinAnimConfig):SkinAnimConfig
	{
		return config = NoteSkinConfig.applyConfig(this, animation, value, noteDataMap, false);
	}
}