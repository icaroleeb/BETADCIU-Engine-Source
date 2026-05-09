package objects.notes;

import objects.Note;
import backend.Paths;

class NoteAnimationLoader
{
	public static function load(note:Note, skin:String, separateSheets:Bool):Void
	{
		loadFrames(note, skin, separateSheets);
		loadAnims(note);

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
					note.animation.addByPrefix(Note.colArray[note.noteData] + 'holdend', Note.colArray[note.noteData] + note.noteAnimSuffixes[2], 24, true);
					note.animation.addByPrefix(Note.colArray[note.noteData] + 'hold', Note.colArray[note.noteData] + note.noteAnimSuffixes[1], 24, true);
				}
				else
				{
					note.animation.add(Note.colArray[note.noteData] + 'holdend', [note.noteData * 2 + 1]);
					note.animation.add(Note.colArray[note.noteData] + 'hold', [note.noteData * 2]);
				}
			}
			else
			{
				var dirScroll:Array<String> = ["Left", "Down", "Up", "Right"];

				note.animation.addByPrefix(Note.colArray[note.noteData] + "Scroll", "note" + dirScroll[note.noteData]);
			}
		}
		else
		{
			if (note.isSustainNote)
			{
				attemptToAddAnimationByPrefix(note, 'purpleholdend', 'pruple end hold', 24, true);

				note.animation.addByPrefix(Note.colArray[note.noteData] + 'holdend', Note.colArray[note.noteData] + ' hold end', 24, true);

				note.animation.addByPrefix(Note.colArray[note.noteData] + 'hold', Note.colArray[note.noteData] + ' hold piece', 24, true);
			}
			else
			{
				note.animation.addByPrefix(Note.colArray[note.noteData] + 'Scroll', Note.colArray[note.noteData] + '0');
			}
		}

		note.scale.set(0.7, 0.7);
		note.updateHitbox();
	}

	public static function loadPixelNoteAnims(note:Note):Void
	{
		if (Note.colArray[note.noteData] == null)
			return;

		if (note.isSustainNote)
		{
			note.animation.add(Note.colArray[note.noteData] + 'holdend', [note.noteData + 4], 24, true);
			note.animation.add(Note.colArray[note.noteData] + 'hold', [note.noteData], 24, true);
		}
		else
		{
			note.animation.add(Note.colArray[note.noteData] + 'Scroll', [note.noteData + 4], 24, true);
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
}
