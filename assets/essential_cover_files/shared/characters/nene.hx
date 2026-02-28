import flixel.group.FlxTypedSpriteGroup;
import funkin.vis.dsp.SpectralAnalyzer;
import animate.FlxAnimate;

var analyzer:SpectralAnalyzer;

var pupilState:Int = 0;

var PUPIL_STATE_NORMAL = 0;
var PUPIL_STATE_LEFT = 1;

function onCreatePost(){
    stereoBG = new FlxSprite(0, 0).loadGraphic(Paths.image('characters/abot/stereoBG'));

    setupAbotViz();

    eyeWhites = new FlxSprite(0, 0).makeGraphic(160, 60, 0xFFFFFFFF);

    pupil = new FlxAnimate(0, 0);
    pupil.frames = Paths.getAnimateAtlas('characters/abot/systemEyes');
    pupil.anim.addBySymbolIndices('lookleft', 'a bot eyes lookin', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], 24, false);
	pupil.anim.addBySymbolIndices('lookright', 'a bot eyes lookin', [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35], 24, false);

    abot = new FlxAnimate(0, 0);
    abot.frames = Paths.getAnimateAtlas('characters/abot/abotSystem');
    abot.anim.addBySymbol('anim', 'Abot System', 24, false);

    abot.antialiasing = ClientPrefs.data.antialiasing;
    eyeWhites.antialiasing = ClientPrefs.data.antialiasing;
    pupil.antialiasing = ClientPrefs.data.antialiasing;
    stereoBG.antialiasing = ClientPrefs.data.antialiasing;
    abotViz.antialiasing = ClientPrefs.data.antialiasing;

    abot.x = gf.x - 100;
    abot.y = gf.y + 316; // 764 - 740

    abotViz.x = abot.x + 207;
    abotViz.y = abot.y + 84;

    eyeWhites.x = abot.x + 40;
    eyeWhites.y = abot.y + 250;

    pupil.x = abot.x + 50;
    pupil.y = abot.y + 238;

    stereoBG.x = abot.x + 150;
    stereoBG.y = abot.y + 30;

    abot.shader = gf.shader;
    eyeWhites.shader = gf.shader;
    pupil.shader = gf.shader;
    stereoBG.shader = gf.shader;
    abotViz.shader = gf.shader;

    vis1.shader = gf.shader;
    vis2.shader = gf.shader;
    vis3.shader = gf.shader;
    vis4.shader = gf.shader;
    vis5.shader = gf.shader;
    vis6.shader = gf.shader;
    vis7.shader = gf.shader;

    abot.color = gf.color;
    eyeWhites.color = gf.color;
    pupil.color = gf.color;
    stereoBG.color = gf.color;
    abotViz.color = gf.color;

    vis1.color = gf.color;
    vis2.color = gf.color;
    vis3.color = gf.color;
    vis4.color = gf.color;
    vis5.color = gf.color;
    vis6.color = gf.color;
    vis7.color = gf.color;

    insert(members.indexOf(gf) - 1, stereoBG);
    insert(members.indexOf(gf) - 1, abotViz);
    insert(members.indexOf(gf) - 1, eyeWhites);
    insert(members.indexOf(gf) - 1, pupil);
    insert(members.indexOf(gf) - 1, abot);

	pupil.anim.play('lookleft');
}

var start = false;

function onSongStart(){
    initAnalyzer(); // LET'S GO!!! IT WORKS!
    start = true;
}

function onUpdatePost(elapsed){
    if(analyzer == null) {
        return;
    }

    var levels = analyzer.getLevels();

    for (i in 0...abotViz.members.length)
    {
        var animFrame:Int = Math.round(levels[i].value * 6);

        // don't display if we're at 0 volume from the level
        abotViz.members[i].visible = animFrame > 0;
  
        // decrement our animFrame, so we can get a value from 0-5 for animation frames
        animFrame -= 1;

        animFrame = Math.floor(Math.min(5, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));

        animFrame = Std.int(Math.abs(animFrame - 5));

        abotViz.members[i].animation.curAnim.curFrame = animFrame;
    }
}

function onBeatHit(){
    if (curBeat % gfSpeed == 0){
	    abot.anim.play("anim", true);
    	//abot.anim.curFrame = 1;
    }
}

function initAnalyzer(){
    analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1, 40);

    analyzer.minDb = -65;
    analyzer.maxDb = -25;
    analyzer.maxFreq = 22000;

    analyzer.minFreq = 10;

    analyzer.fftN = 256;
}

function setupAbotViz():Void{
    var positionX = [0, 59, 56, 66, 54, 52, 51];
    var positionY = [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

    abotViz = new FlxTypedSpriteGroup(gf.x + 100, gf.y + 400);

    vis1 = new FlxSprite(0, 0);
    vis1.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis1.animation.addByPrefix('vis', 'viz1', 0, false);
    vis1.animation.play('vis', false, false, 6);
    vis1.antialiasing = false;
    abotViz.add(vis1);

    vis2 = new FlxSprite(59, -8);
    vis2.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis2.animation.addByPrefix('vis', 'viz2', 0, false);
    vis2.animation.play('vis', false, false, 6);
    vis2.antialiasing = false;
    abotViz.add(vis2);

    vis3 = new FlxSprite(115, -11.5);
    vis3.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis3.animation.addByPrefix('vis', 'viz3', 0, false);
    vis3.animation.play('vis', false, false, 6);
    vis3.antialiasing = false;
    abotViz.add(vis3);

    vis4 = new FlxSprite(181, -11.9);
    vis4.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis4.animation.addByPrefix('vis', 'viz4', 0, false);
    vis4.animation.play('vis', false, false, 6);
    vis4.antialiasing = false;
    abotViz.add(vis4);

    vis5 = new FlxSprite(235, -11.4);
    vis5.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis5.animation.addByPrefix('vis', 'viz5', 0, false);
    vis5.animation.play('vis', false, false, 6);
    vis5.antialiasing = false;
    abotViz.add(vis5);

    vis6 = new FlxSprite(287, -6.7);
    vis6.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis6.animation.addByPrefix('vis', 'viz6', 0, false);
    vis6.animation.play('vis', false, false, 6);
    vis6.antialiasing = false;
    abotViz.add(vis6);

    vis7 = new FlxSprite(338, 0.3);
    vis7.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis7.animation.addByPrefix('vis', 'viz7', 0, false);
    vis7.animation.play('vis', false, false, 6);
    vis7.antialiasing = false;
    abotViz.add(vis7);

    vis1.antialiasing = ClientPrefs.data.antialiasing;
    vis2.antialiasing = ClientPrefs.data.antialiasing;
    vis3.antialiasing = ClientPrefs.data.antialiasing;
    vis4.antialiasing = ClientPrefs.data.antialiasing;
    vis5.antialiasing = ClientPrefs.data.antialiasing;
    vis6.antialiasing = ClientPrefs.data.antialiasing;
    vis7.antialiasing = ClientPrefs.data.antialiasing;

    vis1.visible = false;
    vis2.visible = false;
    vis3.visible = false;
    vis4.visible = false;
    vis5.visible = false;
    vis6.visible = false;
    vis7.visible = false;
}

function onMoveCamera(char)
{
    if (start){
        if (char == "dad")
            pupil.anim.play('lookleft');
        else
            pupil.anim.play('lookright');
    }
}

function onDestroy()
{
    remove(abotViz);
    remove(abot);
    remove(eyeWhites);
    remove(pupil);
    remove(stereoBG);

    remove(vis1);
    remove(vis2);
    remove(vis3);
    remove(vis4);
    remove(vis5);
    remove(vis6);
    remove(vis7);

    //

    abotViz.destroy();
    abot.destroy();
    eyeWhites.destroy();
    pupil.destroy();
    stereoBG.destroy();

    vis1.destroy();
    vis2.destroy();
    vis3.destroy();
    vis4.destroy();
    vis5.destroy();
    vis6.destroy();
    vis7.destroy();
}