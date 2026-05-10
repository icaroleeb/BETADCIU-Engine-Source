package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

// Split these to reduce the number of lines
import objects.notes.NoteTypeHelper;
import objects.notes.NoteSkinLoader;
import objects.notes.NoteSkinConfig;
import objects.notes.NoteSkinConfig.NoteSkinConfigData;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	value3:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FunkinSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent(default, set):Note =  null;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;
	public var dType:Int = 0;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	//Weekend notes implementation... kinda
	public var separateSheets:Bool = false;
	public var separateXMLExists:Bool = false;
	public var noteAnimSuffixes:Array<String> = ["0", " hold piece", " hold end"]; // To accommodate for other namings

	// I don't like using isPixelStage;
	public var isPixelNote:Bool = false; // Needs to be global for use in other functions

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	public static var _cachedCustomNoteSkins:Array<String> = null;

	public var skinConfig:NoteSkinConfigData;
	public var sustainHeightScale:Float = 1; // I still don't get why Weekend notes only scaled up the hold pieces
	public var createdFrom:Dynamic;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if(texture != value)
		{
			value = NoteSkinLoader.reload(this, value);
		}

		texture = value;
		return value;
	}

	public function defaultRGB(?pixelShit:Bool=false)
	{
		var arr:Array<FlxColor> = pixelShit ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		if (Type.getClassName(Type.getClass(FlxG.state)) == "states.PlayState") 
			noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			NoteTypeHelper.apply(this, value);
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	private function set_parent(value:Note):Note
	{
		parent = value;

		if (parent != null)
			applyInitialSetup();

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		if (_cachedCustomNoteSkins == null) _cachedCustomNoteSkins = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		this.createdFrom = createdFrom;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				playAnim('scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		applyInitialSetup();
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	public var _lastNoteOffX:Float = 0;
	public static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this

	public var isLegacyNoteSkin:Bool = false;

	var jsonConfig:Bool = false;

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor && alpha > 0.3)
			alpha = 0.3;
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var daOffsets:Array<Float> = [];
		if (animation != null && jsonConfig) daOffsets = getAnimOffset(animation.curAnim.name);
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + daOffsets[0] + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + daOffsets[1] + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(isPixelNote)
					y -= PlayState.daPixelZoom * 9.5;
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		if (animation == null){
			return; // I don't know how this happened but okay
		}

		animation.play(anim, force);

		var daOffsets = getAnimOffset(anim);

		var scaleMult:Float = isPixelNote ? PlayState.daPixelZoom : 0.7;
		offset.x += daOffsets[0] * (scaleMult / scale.x);
		offset.y += daOffsets[1] * (scaleMult / scale.y);

		updateHitbox();
		
		// if(useRGBShader && !isLegacyNoteSkin) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
		// else if (isLegacyNoteSkin) rgbShader.enabled = false;
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public function getLaneName():String
	{
		return switch(noteData)
		{
			case 0: "left";
			case 1: "down";
			case 2: "up";
			case 3: "right";
			default: "left";
		};
	}

	public function applySustainScale()
	{
		if (!isSustainNote) return;

		var sustainScale:Float =
			Conductor.stepCrochet / 100 * 1.05 * (1 / PlayState.holdSubdivisions);

		if (createdFrom != null && createdFrom.songSpeed != null)
			sustainScale *= createdFrom.songSpeed;

		if (isPixelNote)
			sustainScale *= 1.19;

		sustainScale *= sustainHeightScale;

		scale.y = sustainScale;
		updateHitbox();
	}

	public function applyInitialSetup(){
		// I saw that pixel notes adjusts something with offsetX so this might break it
		offsetX = 0;

		if (isSustainNote && prevNote != null)
		{
			// alpha = 0.6;
			// multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			var swagWidth = parent != null ? parent.width : width;

			offsetX += swagWidth / 2;
			copyAngle = false;

			playAnim('holdend');
			updateHitbox();

			offsetX -= width / 2;

			if (isPixelNote || separateSheets)
				offsetX += 28;
			

			if (prevNote.isSustainNote)
			{
				prevNote.playAnim('hold');
				prevNote.applySustainScale();
			}

			if(isPixelNote)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		// x += offsetX;
	}
}
