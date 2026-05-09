package objects.notes;

import objects.Note;

class NoteTypeHelper
{
    public static function apply(note:Note, value:String):Void
    {
        switch(value)
        {
            case 'Hurt Note':
                applyHurtNote(note);

            case 'Alt Animation':
                note.animSuffix = '-alt';

            case 'No Animation':
                note.noAnimation = true;
                note.noMissAnimation = true;

            case 'GF Sing':
                note.gfNote = true;
        }
    }

    static function applyHurtNote(note:Note):Void
    {
        note.ignoreNote = note.mustPress;

        note.rgbShader.r = 0xFF101010;
        note.rgbShader.g = 0xFFFF0000;
        note.rgbShader.b = 0xFF990022;

        note.noteSplashData.r = 0xFFFF0000;
        note.noteSplashData.g = 0xFF101010;
        note.noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

        note.lowPriority = true;
        note.missHealth = note.isSustainNote ? 0.25 : 0.1;
        note.hitCausesMiss = true;

        note.hitsound = 'cancelMenu';
        note.hitsoundChartEditor = false;
    }
}