package objects.notes;

import objects.Note;
import backend.Paths;

import objects.notes.NoteSkinConfig;
import objects.notes.NoteSkinConfig.NoteSkinConfigData;

class NoteAnimationLoader
{
	public static function load(note:Note, skin:String, separateSheets:Bool):Void
	{
		loadFrames(note, skin, separateSheets);

		var skinConfig:NoteSkinConfigData = note.skinConfig;

		if (skinConfig != null){
			loadNoteAnimsFromConfig(note);
		}else{
			loadAnims(note);
		}
		
		if (!note.isSustainNote)
		{
			note.centerOffsets();
			note.centerOrigin();
		}
	}

	public static function loadAnims(note:Note):Void
	{
		if (note.isPixelNote)
			loadPixelNoteAnims(note);
		else
			loadNoteAnims(note);
	}

	public static function loadFrames(note:Note, skin:String, ?separateSheets:Bool = false):Void
	{
		if (separateSheets && note.isSustainNote)
		{
			if (Paths.fileExists("images/" + skin + "_hold.xml", IMAGE))
			{
				note.frames = Paths.getSparrowAtlas(skin + "_hold");
				note.separateXMLExists = true;
			}
			else
			{
				var rawPic:Dynamic = Paths.image(skin + "_hold");
				note.loadGraphic(rawPic, true, 52, 87);
			}
		}
		else
		{
			try
			{
				note.frames = Paths.getSparrowAtlas(skin);
			}
			catch (e)
			{
				note.texture = Note.defaultNoteSkin;
			}
		}
	}

	public static function loadNoteAnims(note:Note):Void
	{
		if (Note.colArray[note.noteData] == null)
			return;

		if (note.separateSheets)
		{
			if (note.isSustainNote)
			{
				if (note.separateXMLExists)
				{
					note.animation.addByPrefix('holdend', Note.colArray[note.noteData] + note.noteAnimSuffixes[2], 24, true);
					note.animation.addByPrefix('hold', Note.colArray[note.noteData] + note.noteAnimSuffixes[1], 24, true);
				}
				else
				{
					note.animation.add('holdend', [note.noteData * 2 + 1]);
					note.animation.add('hold', [note.noteData * 2]);
				}
			}
			else
			{
				var dirScroll:Array<String> = ["Left", "Down", "Up", "Right"];

				note.animation.addByPrefix("scroll", "note" + dirScroll[note.noteData]);
			}
		}
		else
		{
			if (note.isSustainNote)
			{
				attemptToAddAnimationByPrefix(note, 'purpleholdend', 'pruple end hold', 24, true);

				note.animation.addByPrefix('holdend', Note.colArray[note.noteData] + ' hold end', 24, true);
				note.animation.addByPrefix('hold', Note.colArray[note.noteData] + ' hold piece', 24, true);
			}
			else
			{
				note.animation.addByPrefix('scroll', Note.colArray[note.noteData] + '0');
			}
		}
	}

	public static function loadPixelNoteAnims(note:Note):Void
	{
		if (Note.colArray[note.noteData] == null)
			return;

		if (note.isSustainNote)
		{
			note.animation.add('holdend', [note.noteData + 4], 24, true);
			note.animation.add('hold', [note.noteData], 24, true);
		}
		else
		{
			note.animation.add('scroll', [note.noteData + 4], 24, true);
		}
	}

	public static function attemptToAddAnimationByPrefix(note:Note, name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Void
	{
		if (note.frames == null)
			return;

		var animFrames = [];

		@:privateAccess
		note.animation.findByPrefix(animFrames, prefix);

		if (animFrames.length < 1)
			return;

		note.animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	public static function loadNoteAnimsFromConfig(note:Dynamic, isStrum:Bool = false):Void
	{
		var config = note.skinConfig;
		if (config == null)
			return;

		var lanes = isStrum ? config.receptorAnimations : config.noteAnimations;
		if (lanes == null)
			return;

		var laneAnims:Array<NoteSkinConfig.AnimationData> = lanes[note.noteData];

		if (laneAnims == null || laneAnims.length == 0)
			return;

		for (anim in laneAnims)
		{
			if (anim.indices != null)
			{
				note.animation.add(
					anim.anim,
					anim.indices,
					anim.fps != null ? anim.fps : 24,
					anim.looping == true
				);
			}
			else
			{
				note.animation.addByPrefix(
					anim.anim,
					anim.xmlName,
					anim.fps != null ? anim.fps : 24,
					anim.looping == true
				);
			}

			if (anim.offsets != null){
				note.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
	}
}
