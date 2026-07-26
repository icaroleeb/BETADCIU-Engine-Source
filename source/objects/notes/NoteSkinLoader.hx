package objects.notes;

import backend.Paths;
import objects.Note;
import states.PlayState;

import objects.notes.NoteAnimationLoader;
import objects.notes.NoteSkinConfig;
import objects.notes.NoteSkinConfig.NoteSkinConfigData;

using StringTools;

class NoteSkinLoader
{
	public static function reload(note:Note, texture:String = '', postfix:String = ''):String
	{
		note.rgbShader.enabled = true;
		note.skinConfig = null;

		if (texture == null){
			texture = "";
		}
			
		if (postfix == null){
			postfix = '';
		}

		if (texture.length < 1)
		{
			if (PlayState.SONG != null && PlayState.SONG.noteStyle != null){
				texture = PlayState.SONG.noteStyle;
			}
			else{
				texture = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			}
				
			if (texture == null || texture.length < 1){
				texture = Note.defaultNoteSkin + postfix;
			}
		}

		switch (texture)
		{
			case "pixel":
				texture = "NOTE_assets-pixel";
			case "normal":
				texture = "NOTE_assets";
		}

		var skin:String = texture + postfix;

		var animName:String = note.animation.curAnim != null
			? note.animation.curAnim.name
			: null;

		var wasPixelNote:Bool = note.isPixelNote;
		note.isPixelNote = false;

		var isCustomNoteSkin:Bool = Note._cachedCustomNoteSkins.contains(skin);

		var skinPostfix:String = Note.getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = note.isPixelNote ? 'pixelUI/' : '';

		if (customSkin == Note._lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			Note._lastValidChecked = customSkin;
		}
		else{
			skinPostfix = '';
		}

		var configPath:String = NoteSkinConfig.getConfigPath(skin);
		final flatConfig = 'noteSkins/$skin';

		if (configPath != null){
			final json = NoteSkinConfig.get('images/$configPath');
			@:privateAccess {note.jsonConfig = true;}

			note.skinConfig = json;

			note.rgbShader.enabled = json.inGameColoring;
			note.isPixelNote = json.isPixel;

			skin = note.isSustainNote ? json.holdTexture : json.noteTexture;
		}
		else{
			// I didn't wanna bother trying to rewrite this to fit the NMV JSON. Maybe later.

			var pathSplit:Array<String> = skin.split('/');
			var curSkin = skin;

			for (noteDirectory in ["noteSkins/", "notes/", "pixelUI/noteSkins/", "pixelUI/notes/"])
			{
				final fullPath = '$noteDirectory$skin';
				final weekendPath = '$fullPath/notes';
				var jsonPath = fullPath;

				if (Paths.fileExists('images/$weekendPath.png', IMAGE))
				{
					note.separateSheets = true;

					final jsonName = pathSplit[pathSplit.length - 1];
					jsonPath = '$noteDirectory$skin/$jsonName';

					skin = weekendPath;
				}
				else if (Paths.fileExists('images/$fullPath.png', IMAGE))
				{
					skin = fullPath;
				}

				if (curSkin != skin)
				{
					note.isLegacyNoteSkin = (noteDirectory == "notes/");

					if (noteDirectory.startsWith("pixelUI/") || skin.contains("-pixel"))
						note.isPixelNote = true;

					break;
				}
			}
		}

		if (note.noteType != 'Hurt Note')
			note.defaultRGB(note.isPixelNote);

		if (note.isLegacyNoteSkin && !isCustomNoteSkin)
			note.rgbShader.enabled = false;

		if (note.isPixelNote)
		{
			if (note.isSustainNote)
			{
				var graphic = Paths.image(skin + 'ENDS' + skinPostfix);

				try
				{
					note.loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				}
				catch (e)
				{
					var fallbackShit = Paths.image('pixelUI/' + Note.defaultNoteSkin + '-pixelENDS' + skinPostfix);
					graphic = fallbackShit;

					note.loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				}

				note.originalHeight = graphic.height / 2;
			}
			else
			{
				var graphic = Paths.image(skin + skinPostfix);

				try
				{
					note.loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
				}
				catch (e)
				{
					var fallbackShit = Paths.image('pixelUI/' + Note.defaultNoteSkin + '-pixel' + skinPostfix);
					graphic = fallbackShit;

					note.loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
				}
			}

			note.scale.set(6, 6);

			NoteAnimationLoader.loadPixelNoteAnims(note);

			note.antialiasing = false;

			if (note.isSustainNote)
			{
				note.offsetX += note._lastNoteOffX;
				note._lastNoteOffX = (note.width - 7) * (PlayState.daPixelZoom / 2);
				note.offsetX -= note._lastNoteOffX;
			}
		}
		else{
			NoteAnimationLoader.load(note, skin, note.separateSheets);
			note.scale.set(0.7, 0.7);
		}

		if (animName != null){
			note.playAnim(animName, true); // This one is to get the right anim
		}
			
		if (
			note.isSustainNote &&
			note.animation != null &&
			note.animation.curAnim != null &&
			note.animation.curAnim.name != null &&
			!note.animation.curAnim.name.contains("end")
		)
		{
			note.sustainHeightScale = Note.SUSTAIN_SIZE / note.frameHeight;

			/*
			if (note.isPixelNote && !wasPixelNote){
				note.offsetX -= 5;
			}
			*/

			note.applySustainScale();
		}

		note.updateHitbox();
		note.centerOffsets();
		note.centerOrigin();

		/*
		if (note.isPixelNote && note.isSustainNote)
		{
			note.scale.y *= PlayState.daPixelZoom;
			note.scale.y *= 1.222;

			note.updateHitbox();
		}
		*/

		if (animName != null){
			note.playAnim(animName); // This one is for the offsets.
		}
		
		return texture;
	}
	
}
