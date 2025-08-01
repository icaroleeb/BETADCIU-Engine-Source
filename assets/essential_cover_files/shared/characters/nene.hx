import flixel.group.FlxTypedSpriteGroup;
import funkin.vis.dsp.SpectralAnalyzer;

var analyzer:SpectralAnalyzer;

var pupilState:Int = 0;

var PUPIL_STATE_NORMAL = 0;
var PUPIL_STATE_LEFT = 1;

function onCreate(){
    var characterVars = game.variables.get("characterVariables");

    stereoBG = new FlxSprite(0, 0).loadGraphic(Paths.image('characters/abot/stereoBG'));
    characterVars.set("stereoBG", stereoBG);

    setupAbotViz();

    eyeWhites = new FlxSprite(0, 0).makeGraphic(160, 60, 0xFFFFFFFF);
    characterVars.set("eyeWhites", eyeWhites);

    pupil = new FlxAnimate(0, 0);
    Paths.loadAnimateAtlas(pupil, 'characters/abot/systemEyes');
    characterVars.set("pupil", pupil);

    abot = new FlxAnimate(0, 0);
    Paths.loadAnimateAtlas(abot, 'characters/abot/abotSystem');
    abot.anim.addBySymbol('anim', 'Abot System', 24, false);
    characterVars.set("abot", abot);

    abot.antialiasing = ClientPrefs.data.antialiasing;
    eyeWhites.antialiasing = ClientPrefs.data.antialiasing;
    pupil.antialiasing = ClientPrefs.data.antialiasing;
    stereoBG.antialiasing = ClientPrefs.data.antialiasing;
    abotViz.antialiasing = ClientPrefs.data.antialiasing;

    abot.x = gf.x - 100;
    abot.y = gf.y + 316;

    abotViz.x = gf.x + 100;
    abotViz.y = gf.y + 400;

    eyeWhites.x = abot.x + 40;
    eyeWhites.y = abot.y + 250;

    pupil.x = gf.x - 607;
    pupil.y = gf.y - 176;

    stereoBG.x = abot.x + 150;
    stereoBG.y = abot.y + 30;
}

function onCreatePost(){
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

    addBehindGF(stereoBG);
    addBehindGF(abotViz);
    addBehindGF(eyeWhites);
    addBehindGF(pupil);
    addBehindGF(abot);
}

function onEvent(n, v1, v2, v3){
    if(n == "Change Stage"){
        abot.shader = gf.shader;
        eyeWhites.shader = gf.shader;
        pupil.shader = gf.shader;
        stereoBG.shader = gf.shader;
        abotViz.shader = gf.shader;
    }

    if(n == "Change Character"){
        if(v1 == "gf" || v1 == 'girlfriend' || v1 == '2'){
            if(v2 == "nene"){
                abot.shader = gf.shader;
                eyeWhites.shader = gf.shader;
                pupil.shader = gf.shader;
                stereoBG.shader = gf.shader;
                abotViz.shader = gf.shader;
            }
        }
    }
}
function onSongStart(){
    initAnalyzer(); // LET'S GO!!! IT WORKS!
}

function onUpdatePost(elapsed){
    if (pupil.anim.isPlaying){
        switch (pupilState){
            case PUPIL_STATE_NORMAL:
            if (pupil.anim.curFrame >= 17){
                pupilState = PUPIL_STATE_LEFT;
                pupil.anim.pause();
            }

            case PUPIL_STATE_LEFT:
            if (pupil.anim.curFrame >= 30){
                pupilState = PUPIL_STATE_NORMAL;
                pupil.anim.pause();
            }
        }
    }

    stereoBG.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);
    eyeWhites.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);
    pupil.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);
    abot.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);
    abotViz.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);

    if(analyzer == null) return;

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
    characterVars.set("abotViz", abotViz);

    vis1 = new FlxSprite(0, 0);
    vis1.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis1.animation.addByPrefix('vis', 'viz1', 0, false);
    vis1.animation.play('vis', false, false, 6);
    vis1.antialiasing = false;
    abotViz.add(vis1);
    characterVars.set("vis1", vis1);

    vis2 = new FlxSprite(59, -8);
    vis2.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis2.animation.addByPrefix('vis', 'viz2', 0, false);
    vis2.animation.play('vis', false, false, 6);
    vis2.antialiasing = false;
    abotViz.add(vis2);
    characterVars.set("vis2", vis2);

    vis3 = new FlxSprite(115, -11.5);
    vis3.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis3.animation.addByPrefix('vis', 'viz3', 0, false);
    vis3.animation.play('vis', false, false, 6);
    vis3.antialiasing = false;
    abotViz.add(vis3);
    characterVars.set("vis3", vis3);

    vis4 = new FlxSprite(181, -11.9);
    vis4.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis4.animation.addByPrefix('vis', 'viz4', 0, false);
    vis4.animation.play('vis', false, false, 6);
    vis4.antialiasing = false;
    abotViz.add(vis4);
    characterVars.set("vis4", vis4);

    vis5 = new FlxSprite(235, -11.4);
    vis5.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis5.animation.addByPrefix('vis', 'viz5', 0, false);
    vis5.animation.play('vis', false, false, 6);
    vis5.antialiasing = false;
    abotViz.add(vis5);
    characterVars.set("vis5", vis5);

    vis6 = new FlxSprite(287, -6.7);
    vis6.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis6.animation.addByPrefix('vis', 'viz6', 0, false);
    vis6.animation.play('vis', false, false, 6);
    vis6.antialiasing = false;
    abotViz.add(vis6);
    characterVars.set("vis6", vis6);

    vis7 = new FlxSprite(338, 0.3);
    vis7.frames = Paths.getSparrowAtlas('characters/abot/aBotViz');
    vis7.animation.addByPrefix('vis', 'viz7', 0, false);
    vis7.animation.play('vis', false, false, 6);
    vis7.antialiasing = false;
    abotViz.add(vis7);
    characterVars.set("vis7", vis7);

    vis1.visible = false;
    vis2.visible = false;
    vis3.visible = false;
    vis4.visible = false;
    vis5.visible = false;
    vis6.visible = false;
    vis7.visible = false;

    vis1.antialiasing = ClientPrefs.data.antialiasing;
    vis2.antialiasing = ClientPrefs.data.antialiasing;
    vis3.antialiasing = ClientPrefs.data.antialiasing;
    vis4.antialiasing = ClientPrefs.data.antialiasing;
    vis5.antialiasing = ClientPrefs.data.antialiasing;
    vis6.antialiasing = ClientPrefs.data.antialiasing;
    vis7.antialiasing = ClientPrefs.data.antialiasing;
}


function onSectionHit()
{
	if (mustHitSection)
	    movePupilsRight();
	else
	    movePupilsLeft();
	
}

function movePupilsLeft() {
    if (pupilState == PUPIL_STATE_LEFT) return;
    pupil.anim.play('lookleft');
    pupil.anim.curFrame = 0;
}

function movePupilsRight() {
    if (pupilState == PUPIL_STATE_NORMAL) return;
    pupil.anim.play('lookright');
    pupil.anim.curFrame = 17;
}

function refreshAbotSpeaker():Void{
    abot.x = gf.x - 100;
    abot.y = gf.y + 316;

    abotViz.x = gf.x + 100;
    abotViz.y = gf.y + 400;

    eyeWhites.x = abot.x + 40;
    eyeWhites.y = abot.y + 250;

    pupil.x = gf.x - 607;
    pupil.y = gf.y - 176;

    stereoBG.x = abot.x + 150;
    stereoBG.y = abot.y + 30;
}