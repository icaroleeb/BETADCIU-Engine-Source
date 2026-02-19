package states.stages;

import states.stages.objects.PerspectiveSprite;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;

class Sserafim extends BaseStage
{
    var perspectiveFloor:PerspectiveSprite = null;

	override function create()
    {
        if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

        var solid:FlxSprite = new FlxSprite(-5000, -3000).makeGraphic(4000, 3000, 0xFFFFFFFF);
        solid.updateHitbox();
        solid.scrollFactor.set();
        stageVars.set('solid', solid);
        add(solid);

        var solidCover:FlxSprite = new FlxSprite(-5000, -3000).makeGraphic(4000, 3000, 0xFF000000);
        solidCover.updateHitbox();
        solidCover.scrollFactor.set();
        solidCover.alpha = 0;
        stageVars.set('solidCover', solidCover);
        add(solidCover);

        var bg:BGSprite = new BGSprite('bg', -1853, -815, 0.75, 0.75);
        stageVars.set('bg', bg);
        add(bg);

        var fucker:BGSprite = new BGSprite('floor', 790, 625, 0.85, 0.85);
        fucker.alpha = 0.0;
        stageVars.set('fucker', fucker);
        add(fucker);

        perspectiveFloor = new PerspectiveSprite();
        perspectiveFloor.sprite.loadGraphic(Paths.image('floor'));
        perspectiveFloor.setPositions(760, 1375, 790, 625);
        perspectiveFloor.setScrollFactors(1.05, 1.05, 0.93, 0.93);
        stageVars.set("perspectiveFloor", perspectiveFloor);
        add(perspectiveFloor);

        var backTables:BGSprite = new BGSprite('back-tables', -1857, 267, 0.93, 0.93);
        stageVars.set('backTables', backTables);
        add(backTables);

        var backTablesCutscene:BGSprite = new BGSprite('cutscene/counter-stretch', -1858, 377, 0.93, 0.93);
        backTablesCutscene.scale.set(400, 1);
        backTablesCutscene.updateHitbox();
        stageVars.set('backTablesCutscene', backTablesCutscene);
        add(backTablesCutscene);

        var burgerCutscene:BGSprite = new BGSprite('cutscene/burger-cutscene', -97, 237, 0.93, 0.93);
        stageVars.set('burgerCutscene', burgerCutscene);
        add(burgerCutscene);

        var backStools:BGSprite = new BGSprite('cutscene/back-stools', -1357, 426, 0.94, 0.94);
        stageVars.set('backStools', backStools);
        add(backStools);

        var backLightColor:BGSprite = new BGSprite('lights/back-light-color', -1241, -949, 0.93, 0.93);
        backLightColor.alpha = 0.0;
        stageVars.set('backStools', backStools);
        add(backLightColor);

        var backLightWhite:BGSprite = new BGSprite('lights/back-light-white', -771, -599, 0.93, 0.93);
        backLightWhite.alpha = 0.0;
        stageVars.set('backLightWhite', backLightWhite);
        add(backLightWhite);

        var truck:BGSprite = new BGSprite('truck-stuff', -983, -707, 0.95, 0.95);
        stageVars.set('truck', truck);
        add(truck);

        var truckDoor:BGSprite = new BGSprite('truck-door', -980, -173, 0.95, 0.95);
        stageVars.set('truckDoor', truckDoor);
        add(truckDoor);

        var truckLight2:BGSprite = new BGSprite('lights/truck-light2', -781, -464, 0.95, 0.95);
        truckLight2.alpha = 0.0;
        stageVars.set('truckLight2', truckLight2);
        add(truckLight2);

        var truckLight1:BGSprite = new BGSprite('lights/truck-light1', -962, -607, 0.95, 0.95);
        truckLight1.alpha = 0.0;
        stageVars.set('truckLight1', truckLight1);
        add(truckLight1);

        var frontStool:BGSprite = new BGSprite('front-stool', -280, 818, 1.0, 1.0);
        stageVars.set('frontStool', frontStool);
        add(frontStool);
    }

    var dust1:FlxBackdrop;
    var dust2:FlxBackdrop;
    var dust3:FlxBackdrop;
    var dust4:FlxBackdrop;

    override function createPost(){
        dust1 = new FlxBackdrop(Paths.image('dust/dustMid'), FlxAxes.X);
        dust1.setPosition(-650, -200);
        dust1.scrollFactor.set(1.1, 1.1);
        dust1.scale.set(1.5, 1.5);
        dust1.alpha = 0.8;
        dust1.velocity.x = 350;
        PlayState.instance.variables.get("stageVariables").set("dust1", dust1);

        dust2 = new FlxBackdrop(Paths.image('dust/dustBack'), FlxAxes.X);
        dust2.setPosition(-650, -250);
        dust2.scrollFactor.set(1.15, 1.15);
        dust2.scale.set(1.5, 1.5);
        dust2.alpha = 0.9;
        dust2.velocity.x = -300;
        PlayState.instance.variables.get("stageVariables").set("dust2", dust2);

        dust3 = new FlxBackdrop(Paths.image('dust/dustMid'), FlxAxes.X);
        dust3.setPosition(-650, -400);
        dust3.scrollFactor.set(1.2, 1.2);
        dust3.scale.set(2, 2);
        dust3.alpha = 0.8;
        dust3.velocity.x = -200;
        PlayState.instance.variables.get("stageVariables").set("dust3", dust3);

        dust4 = new FlxBackdrop(Paths.image('dust/dustBack'), FlxAxes.X);
        dust4.setPosition(-650, -1300);
        dust4.scrollFactor.set(1.25, 1.25);
        dust4.scale.set(3.5, 3.5);
        dust4.alpha = 0.9;
        dust4.velocity.x = -150;
        PlayState.instance.variables.get("stageVariables").set("dust4", dust4);

        add(dust1);
        add(dust2);
        add(dust3);
        add(dust4);

        dust1.color = 0xff98847d;
        dust2.color = 0xff8b6c63;
        dust3.color = 0xff6e645c;
        dust4.color = 0xff886a60;
    }

    override function update(elapsed:Float)
    {
        if(perspectiveFloor != null) perspectiveFloor.updateSkew(game.camGame);
    }

    /*
    override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
    {
        switch (scriptEvent.eventData.eventKind)
        {
            case 'sserafimGuitarVibration':
                HapticUtil.increasingVibrate(Constants.MIN_VIBRATION_AMPLITUDE, Constants.MAX_VIBRATION_AMPLITUDE / 2, scriptEvent.eventData.getFloat('duration'));
            case 'sserafimShow':
                setGirlsVisible(scriptEvent.eventData.getBoolArray('visible'));
            case 'sserafimSing':
                setGirlsSinging(scriptEvent.eventData.getBoolArray('singing'));
            case 'sserafimDark':
                setDarkenAmt(scriptEvent.eventData.getFloat('amount'), scriptEvent.eventData.getFloat('duration'));
            case 'sserafimLights':
                flashTruckLights(scriptEvent.eventData.getFloat('amount'), scriptEvent.eventData.getFloat('duration'));
            case 'sserafimCover':
                setCoverVisible(scriptEvent.eventData.getBool('visible'));
            case 'sserafimFlash':
                flashScreen(scriptEvent.eventData.getFloat('duration'));
            case 'sserafimPulseLights':
                setLightState(scriptEvent.eventData.getBool('enabled'), scriptEvent.eventData.getArray('colors'), scriptEvent.eventData.getArray('durations'),
                scriptEvent.eventData.getArray('intensities'));
            case 'sserafimKick':
                if (scriptEvent.eventData.getBool('final'))
                {
                    // play second kick anim + reset her idle back to normal
                    yunjin.playAnimation('kick2', true, false);
                    FunkinSound.playOnce(Paths.sound('doorKick2'), 1.0);
                    yunjin.danceEvery = 1;

                    HapticUtil.vibrate(0, 0.2, 0.8, 0);

                    // Show the opponent health icon at this point
                    PlayState.instance.iconP2.visible = true;

                    // hide the cutscene characters if theyre present!
                    if (sserafimGf != null)
                    {
                        // and show the REAL gf
                        PlayState.instance.currentStage.getGirlfriend()?.visible = true;

                        sserafimGf.visible = false;
                        sserafimBf.visible = false;
                    }

                    yunjin.animation.onFrameChange.removeAll();

                    yunjin.animation.onFrameChange.add(function(animName:String, frameNumber:Int, index:Int) {
                        // at this point in the animation, the door is no longer part of her animation...
                        // show a static one!
                        if (frameNumber == 23) getNamedProp('truckDoor').visible = true;
                    });

                    yunjin.animation.onFinish.addOnce(function(animName:String) {
                        yunjin.animation.onFrameChange.removeAll();
                    });

                    // start the dust clearing
                    startClear();
                }
                else
                {
                    // play first kick anim
                    yunjin.playAnimation('kick1', true, false);
                    //FunkinSound.playOnce(Paths.sound('doorKick1'), 1.0);

                    HapticUtil.vibrate(0, 0.2, 0.4, 0);
                }
            case 'sserafimEnd':
                endStuff();
            }
            
    }
    */

    function startClear():Void{
        /*
        FlxTween.tween(stageShader,
        {
            baseBrightness: 0,
            baseHue: 0,
            baseContrast: 0,
            baseSaturation: 0
        }, 6.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(characterShader,
        {
            baseBrightness: 0,
            baseHue: 0,
            baseContrast: 0,
            baseSaturation: 0
        }, 6.0 * 4, {ease: FlxEase.sineOut});
        */

        FlxTween.tween(dust1, {alpha: 0, y: dust1.y + 100}, 5.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust2, {alpha: 0, y: dust2.y + 200}, 4.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust3, {alpha: 0, y: dust3.y + 150}, 6.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust4, {alpha: 0, y: dust4.y + 100}, 4.0 * 4, {ease: FlxEase.sineOut});

        FlxTween.tween(dust1.velocity, {x: 0}, 5.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust2.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust3.velocity, {x: 0}, 6.0 * 4, {ease: FlxEase.sineOut});
        FlxTween.tween(dust4.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
    }

    override public function destroy():Void {
		if (perspectiveFloor != null) { // fuck u <3.
			remove(perspectiveFloor);
			perspectiveFloor.destroy();
			perspectiveFloor = null;
		}
		super.destroy();
	}
}