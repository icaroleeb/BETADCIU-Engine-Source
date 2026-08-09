package objects;

import backend.animation.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

import backend.Song;
import states.stages.objects.TankmenBG;
import objects.Bopper;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	@:optional var player_position:Array<Float>; // New preferred field
	@:optional var playerposition:Array<Float>;  // Legacy fallback
	var camera_position:Array<Float>;
	var player_camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var noteSkin:String;
	@:optional var is_player_char:Bool; // New preferred field
	@:optional var isPlayerChar:Bool;  // Legacy fallback
	@:optional var isCharSpeaker:Bool;
	
	@:optional var _editor_isPlayer:Null<Bool>;

	// stuff from nmv
	@:optional var scalableOffsets:Null<Bool>;
	@:optional var autoOffset:Null<Bool>;
	@:optional var vSliceSustains:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
	var playerOffsets:Array<Float>;
}

class Character extends Bopper
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	/**
	 * is the player character
	 * 
	 * changes some things like flipping them
	**/
	public var isPlayer:Bool = false;
	public var isPsychPlayer:Null<Bool>;

	/**
	 * is the speaker character
	 * 
	 * makes the character act like a "gf" character
	**/
	public var isSpeakerChar:Bool = false;

	/**
	 * Character's json name
	**/
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var pastCharacter:String = DEFAULT_CHARACTER;

	public var charName:String = DEFAULT_CHARACTER; // believe me... this is useful asf
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;

	/**
	 * Multiplier of how long a character holds the sing pose
	**/
	public var singDuration:Float = 4;

	/**
	 * if true, character uses `danceLeft` and `danceRight` instead of `idle`
	**/
	public var danceIdle:Bool = false;

	public var skipDance:Bool = false; // prevents a character from "dancing"

	public var stopIdle:Bool = false; // prevents a character from "dancing" -- legacy variable, prefer to use skipDance

	/**
	 *  Makes the character sing (if the character is on PlayState's modchartCharacters map)
	**/
	public var playSingAnim:Bool = false; 

	/**
	 * The characters health icon
	**/
	public var healthIcon:String = 'face';

	public var animationsArray:Array<AnimArray> = [];
	public var animationNotes:Array<Dynamic> = [];

	/**
	 * Character offsets defined by the json
	**/
	public var positionArray:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];

	/**
	 * Camera offsets defined by the json
	**/
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];

	// Used on Character Editor
	public var flippedAnims:Bool = false;
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	/**
	 * The Characters health bar colours stored as `[r,g,b]`
	**/
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var iconColor:String;

	/**
	 *	If enabled, the character's singing animation will stop at the last frame while holding a sustain note
	**/
	public var vSliceSustains = false;

	/**
	 *	missing character
	**/
	public var missingCharacter:Bool = false;
	public var missingText:FlxText;

	/**
	 *	Misses for characters that doesn't have miss in their sprites 
	**/
	public var hasMissAnimations:Bool = false;
	public var curColor:FlxColor = 0xFFFFFFFF;

	/**
	 * 	Vocals file suffix to be loaded in PlayState
	**/
	public var vocalsFile:String = '';

	/**
	 *  ugh...
	**/
	public var noteSkin:String = '';

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Float>>();
		animPlayerOffsets = new Map<String, Array<Float>>();
		iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
		this.isPlayer = isPlayer;
		changeCharacter(character);
		
		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String) {
		animationsArray = [];
		animOffsets.clear();
		animPlayerOffsets.clear();
		curCharacter = character;
		pastCharacter = character;
		isPsychPlayer = false;

		curColor = 0xFFFFFFFF;

		var characterPath:String = 'characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			if (!character.startsWith('bf-')) { // if the name starts with "bf" and cannot load the json, assume its a bf re-skin and loads the regular bf.
				missingCharacter = true;
				missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
				missingText.alignment = CENTER;
			}
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		stopIdle = skipDance = specialAnim = stunned = false;

		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public static function getCharacterFile(character:String):CharacterFile{
		var characterPath:String = 'images/characters/jsons/' + character;
		var path:String = Paths.json(characterPath);

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders('characters/'+character+'.json')) || Assets.exists(Paths.modFolders('characters/'+character+'.json'))) {
			path = Paths.modFolders('characters/'+character+'.json');
		}
		#end
	
		if (!FileSystem.exists(path) && !Assets.exists(path))
		{
			trace('oh no missingno. Character '+character+" not found.");
			path = Paths.json('images/characters/jsons/' + DEFAULT_CHARACTER); //If a character couldn't be found, change to bf just to prevent a crash
			character = DEFAULT_CHARACTER;
		}

		var rawJson:Dynamic;

		rawJson = FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path);
		
		var json:CharacterFile = cast Json.parse(rawJson);

		return json;
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		isPsychPlayer = json.is_player_char ?? json.isPlayerChar ?? false;
		isSpeakerChar = json.isCharSpeaker ?? false;

		vSliceSustains = json.vSliceSustains ?? false;
		scalableOffsets = json.scalableOffsets ?? false;

		autoOffset = json.autoOffset ?? true;

		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
		isAnimateAtlas = (Paths.exists(animToFind));

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(json.image.split(','));
		}
		else
		{
			try
			{
				frames = Paths.getAnimateAtlas(json.image);
			}
			catch(e:haxe.Exception)
			{
				FlxG.log.warn('Could not load atlas ${json.image}: $e');
				trace(e.stack);
			}
		}

		imageFile = json.image;
		jsonScale = json.scale > 0 ? json.scale : 1; // context: https://prnt.sc/4ulDTwEzHh20
		if (jsonScale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		var playerPosition = json.player_position ?? json.playerposition ?? null;

		positionArray = ((!debugMode && isPlayer && playerPosition != null) ? playerPosition : json.position);
		playerPositionArray = playerPosition ?? json.position;
		cameraPosition = (isPlayer && json.player_camera_position != null ? json.player_camera_position : json.camera_position);
		playerCameraPosition = json.player_camera_position ?? json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		//flipX = (json.flip_x != isPlayer);
		flipX = !!json.flip_x;
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file ?? '';
		noteSkin = json.noteSkin ?? '';
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		iconColor = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]).toHexString().substring(2);

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if(animationsArray != null && animationsArray.length > 0) {
			for (a in animationsArray) {
				var animAnim:String = '' + a.anim;
				var animName:String = '' + a.name;
				var animFps:Int = a.fps;
				var animLoop:Bool = !!a.loop; //Bruh
				var animIndices:Array<Int> = a.indices;

				if(!isAnimateAtlas)
				{
					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				else
				{
					if(animIndices != null && animIndices.length > 0)
						this.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						this.anim.addBySymbol(animAnim, animName, animFps, animLoop);

				}

				var offsets = a.offsets ?? [0, 0];
				var playerOffsets = a.playerOffsets ?? offsets;
				var swagOffsets = (isPlayer && a.playerOffsets != null) ? playerOffsets : offsets;

				if (a.playerOffsets == null) 
				{
					// isPsychPlayer = true; // i tried to set this out of the loop but it didn't worked
					autoOffset = true;
				}else{
					autoOffset = false;
				}

				// var daFlipAuto = (autoOffset && this.flipX && !isPsychPlayer);

				if(swagOffsets != null && a.offsets.length > 1) addOffset(a.anim, swagOffsets[0], swagOffsets[1]);
				else addOffset(a.anim, 0, 0);

				if(playerOffsets != null && playerOffsets.length > 1) addPlayerOffset(a.anim, playerOffsets[0], playerOffsets[1]);
				else addPlayerOffset(a.anim, 0, 0);
			}

			if (isPlayer) {
				flipX = !flipX;

				if (!isPsychPlayer) 
					flipAnims(); //did i just fix all that flipping bug by just using a check that actually makes sense?? -- future me here: yeah, i did.
			}

			if (!isPlayer)
				if (isPsychPlayer) 
					flipAnims();

			/*
			if (autoOffset && !isPsychPlayer)
				flipAnims();
			*/
		}
		//trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		if(debugMode || (animation.curAnim == null))
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		if (curCharacter == 'pico-speaker') { // aw come on, a switch with only one case is an if disguised
			if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
			{
				var noteData:Int = 1;
				if(animationNotes[0][1] > 2) noteData = 3;

				noteData += FlxG.random.int(0, 1);
				playAnim('shoot' + noteData, true);
				animationNotes.shift();
			}
			if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return (animation.curAnim == null);
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return animation.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		animation.curAnim.finish();
	}

	public function hasAnimation(id:String):Bool
{
		if (animation.exists(id))
			return true;

		if (isAnimate)
			return addAnimationIfMissing(id);

		return false;
}

	public function listAnimations():Array<String>
	{
		var frameLabels:Array<String> = getFrameLabelList();
		var animationList:Array<String> = this.animation?.getNameList() ?? [];

		return frameLabels.concat(animationList);
	}

	public function getFrameLabelList():Array<String>
	{
		if (!this.isAnimate)
		{
			trace('WARNING: getFrameLabelList() only works texture atlases!');
			return [];
		}

		var foundLabels:Array<String> = [];
		var mainTimeline:Null<animate.internal.Timeline> = this.library.timeline;

		//trace('Checking for frame labels in the animate atlas...');

		for (layer in mainTimeline.layers)
		{
			@:nullSafety(Off)
			for (frame in layer.frames)
			{
					if (frame.name.rtrim() != '')
					{
						foundLabels.push(frame.name);
					}
			}
		}

		//trace(foundLabels.length > 0 ? 'Found frame labels: ' + foundLabels.join(', ') : 'No frame labels found.');

		return foundLabels;
	}

	function addAnimationIfMissing(id:String):Bool
	{
		@:privateAccess
		var symbols:Array<String> = [for (key in this.library.dictionary.keys()) key];
		var frameLabels:Array<String> = listAnimations();

		if (frameLabels.contains(id))
		{
			// Animation exists as a frame label but wasn't added, so we add it
			anim.addByFrameLabel(id, id, this.library.frameRate, false);
			return true;
		}
		else if (symbols.contains(id))
		{
			// Animation exists as a symbol but wasn't added, so we add it
			anim.addBySymbol(id, id, this.library.frameRate, false);
			return true;
		}

		return false;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return animation.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		animation.curAnim.paused = value;

		return value;
	}

	/**
	 * FOR GF DANCING SHIT
	 */
	override public function dance(forced:Bool=false)
	{
		if (!debugMode && !skipDance && !specialAnim && !stopIdle)
		{
			super.dance();
			// if(danceIdle)
			// {
			// 	danced = !danced;

			// 	if (danced)
			// 		playAnim('danceRight' + idleSuffix);
			// 	else
			// 		playAnim('danceLeft' + idleSuffix);
			// }
			// else if(hasAnimation('idle' + idleSuffix))
			// 	playAnim('idle' + idleSuffix);

			if (color != curColor && !hasMissAnimations)
				color = curColor;
		}
	}

	public var useFallbackMiss:Bool = false;

	override public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		if (!canPlayAnimations) return;

		specialAnim = false;
		var missShit:Bool = false;

		// Reimplemented the fall back for the alt sprites
		if (animName.endsWith('alt') && !hasAnimation(animName)) {
			animName = animName.split('-')[0];
		}

		if (animName.endsWith('miss') && !hasAnimation(animName)) {
			animName = animName.substr(0, animName.length - 4);
			missShit = true;
		}

		super.playAnim(animName, force, reversed, frame);

		var playedAnim = __prevPlayedAnimation;

		var regularOff = animOffsets.get(playedAnim);
		var playerOff = animPlayerOffsets.get(playedAnim);

		if (isPlayer) {
			if (playerOff != null) {
				if (!autoOffset) offset.set(playerOff[0], playerOff[1]);
				if (scalableOffsets) {
					offset.x *= scale.x;
					offset.y *= scale.y;
				}
			}
		}

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (playedAnim == 'singLEFT') danced = true;
			else if (playedAnim == 'singRIGHT') danced = false;

			if (playedAnim == 'singUP' || playedAnim == 'singDOWN') danced = !danced;
		}

		if (missShit && useFallbackMiss) {
			var realCurColor:FlxColor = curColor;
			color = CoolUtil.blendColors(curColor, 0xFFCFAFFF);
			curColor = realCurColor;
		}
		else if (color != curColor && !hasMissAnimations){
			color = curColor;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function setZoom(Zoom:Float)
	{
		this.scale.set(jsonScale * Zoom, jsonScale * Zoom);
		scalableOffsets = true;
	}

	public function flipAnims() {
		//rewrote it
		var foundAnim:Bool = false;
		if (isAnimateAtlas) {
			for (anim in animationsArray) {
				if (anim.anim.contains("singRIGHT")) {
					var animSplit:Array<String> = anim.anim.split('singRIGHT');
					var suffix = animSplit[1];
					
					var singRightName = 'singRIGHT' + suffix;
					var singLeftName = 'singLEFT' + suffix;

					@:privateAccess {
						var oldRightAnim = this.anim._animations.get(singRightName);
						var oldLeftAnim = this.anim._animations.get(singLeftName);

						if (oldRightAnim != null && oldLeftAnim != null) {
							this.anim._animations.set(singRightName, oldLeftAnim);
							this.anim._animations.set(singLeftName, oldRightAnim);
							foundAnim = true;
						}
					}
				}
			}
		} else {
			for (anim in animationsArray){
				if (anim.anim.contains("singRIGHT")) {
					var animSplit:Array<String> = anim.anim.split('singRIGHT');

					if (animation.getByName('singRIGHT' + animSplit[1]) != null && animation.getByName('singLEFT' + animSplit[1]) != null) {
						var oldRight = animation.getByName('singRIGHT' + animSplit[1]).frames;
						animation.getByName('singRIGHT' + animSplit[1]).frames = animation.getByName('singLEFT' + animSplit[1]).frames;
						animation.getByName('singLEFT' + animSplit[1]).frames = oldRight;
						foundAnim = true;
					}
				}
			}
		}

		if (foundAnim) flippedAnims = !flippedAnims;
	}

	inline function predictCharacterIsPlayer(name:String) { // if i remove this later, is because people didn't liked it. -Ryiuu
		if (name.startsWith('bf') || name.startsWith('bf-') || name.endsWith('-player') || name.endsWith('-playable'))
			return true;
		else 
			return false;
	}

	override function set_color(Color:FlxColor):Int
	{
		curColor = Color;
		return super.set_color(Color);
	}

	@:allow(states.editors.CharacterEditorState, states.editors.CharacterEditorStateWIP)
	public var isAnimateAtlas(default, null):Bool = false;
	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		super.draw();
		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
			if (alpha < 0.6) missingText.alpha = alpha;
		}
	}

	public override function destroy()
	{
		if (missingText != null) missingText.visible = false; // this should fix some weird bugs when a character is missing
		super.destroy();
	}

	// Character Perfect Pixel Effect

	/**
   * Returns the screen position of this object.
   *
   * @param   result  Optional arg for the returning point
   * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
   * @return  The screen position of this object.
   */
	public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
	{
		if (result == null) result = FlxPoint.get();
		if (camera == null) camera = FlxG.camera;

		result.set(x, y);

		if (pixelPerfectPosition)
		{
			result.x = Math.round(result.x / scale.x) * scale.x;
			result.y = Math.round(result.y / scale.y) * scale.y;
		}

		return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
	}

	override function drawSimple(camera:FlxCamera):Void
	{
		getScreenPosition(_point, camera).subtractPoint(offset);

		if (isPixelPerfectRender(camera))
		{
			_point.x = Math.round(_point.x / scale.x) * scale.x;
			_point.y = Math.round(_point.y / scale.y) * scale.y;
		}

		_point.copyToFlash(_flashPoint);
		camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.round(_matrix.tx / scale.x) * scale.x;
			_matrix.ty = Math.round(_matrix.ty / scale.y) * scale.y;
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}
}