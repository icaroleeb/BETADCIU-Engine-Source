package objects.freeplay;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
// import funkin.audio.FunkinSound; // commenting this because i still have to implement the funkin sound
import flixel.util.FlxTimer;
// import funkin.audio.FlxStreamSound;

// old ass code from fnf 0.3.2 (because im only using bf as a dj) but revamped to work with flixel-animate

class DJBoyfriend extends FunkinSprite
{
  public var currentState:DJBoyfriendState = Idle; // Represents the sprite's current status.
  public var onIntroDone:FlxSignal = new FlxSignal(); // A callback activated when the intro animation finishes.
  public var onSpook:FlxSignal = new FlxSignal();  // A callback activated when Boyfriend gets spooked.

  var gotSpooked:Bool = false;
  var timeSinceSpook:Float = 0; // Time since dad last SPOOKED you.

  static final SPOOK_PERIOD:Float = 120.0;
  static final TV_PERIOD:Float = 180.0;

  public function new(x:Float, y:Float) {
    super(x, y);
    this.frames = Paths.getAnimateAtlas("freeplay/freeplay-boyfriend", "shared", getDefaultAtlasSettings());

    setupAnimations();

    #if debug
    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);
    FlxG.console.registerFunction("tv", function() { currentState = TV; });
    #end
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        if (getAnimationName() != 'boyfriend dj intro') playAnim('boyfriend dj intro', true);
        timeSinceSpook = 0;
      case Idle:
        // We are in this state the majority of the time.
        if (getAnimationName() != 'Boyfriend DJ') playAnim('Boyfriend DJ', true);

        if (getAnimationName() == 'Boyfriend DJ' && this.animation?.curAnim?.looped) {
          if (timeSinceSpook >= SPOOK_PERIOD && !gotSpooked) {
            currentState = Spook;
          } else if (timeSinceSpook >= TV_PERIOD) {
            currentState = TV;
          }
        }
        timeSinceSpook += elapsed;
      case Confirm:
        if (getAnimationName() != 'Boyfriend DJ confirm') playAnim('Boyfriend DJ confirm', false);
        timeSinceSpook = 0;
      case Spook:
        if (getAnimationName() != 'bf dj afk')
        {
          onSpook.dispatch();
          playAnim('bf dj afk', false);
          gotSpooked = true;
        }
        timeSinceSpook = 0;
      case TV:
        if (getAnimationName() != 'Boyfriend DJ watchin tv OG') playAnim('Boyfriend DJ watchin tv OG', true);
        timeSinceSpook = 0;
      default:
        // I shit myself.
    }

  }

  function onFinishAnim(name:String):Void
  {
    switch (name)
    {
      case "boyfriend dj intro":
        // trace('Finished intro');
        currentState = Idle;
        onIntroDone.dispatch();
      case "Boyfriend DJ":
        // trace('Finished idle');
      case "bf dj afk":
        // trace('Finished spook');
        currentState = Idle;
      case "Boyfriend DJ confirm":

      case "Boyfriend DJ watchin tv OG":
        var frame:Int = FlxG.random.bool(33) ? 112 : 166;

        // BF switches channels when the video ends, or at a 10% chance each time his idle loops.
        if (FlxG.random.bool(5)) {
          frame = 60;
          // runTvLogic(); // boyfriend switches channel code?
        }
        // trace('Replay idle: ${frame}');
        anim.play("Boyfriend DJ watchin tv OG", true, false, frame);
        // trace('Finished confirm');
    }
  }

  public function resetAFKTimer():Void {
    timeSinceSpook = 0;
    gotSpooked = false;
  }

  function setupAnimations():Void {
    for (animation in ["boyfriend dj intro", "Boyfriend DJ confirm", "bf dj afk", "Boyfriend DJ watchin tv OG"])
      this.anim.addBySymbol(animation, animation, 24, false);
    this.anim.addBySymbol("Boyfriend DJ", "Boyfriend DJ", 24, true); // the only loopable anim

    this.anim.callback = function(name:String, number:Int, index:Int) {
      if (name == "Boyfriend DJ watching tv OG") {
        if (number == 80) // FunkinSound.playOnce(Paths.sound('remote_click));
        if (number == 85) runTvLogic();
      }
    };

    anim.onFinish.add((anim) -> { onFinishAnim(anim); });	

    // used the character editor to get these offsets lol
    addOffset('boyfriend dj intro', 6.8, 425.6); // Intro
    addOffset('Boyfriend DJ', 0, 0); // Idle
    addOffset('Boyfriend DJ confirm', 50.3, 0.4); // Confirm
    addOffset('bf dj afk', 0, 162.7); // AFK: Spook
    addOffset('Boyfriend DJ watchin tv OG', 19.9, 457.5); // AFK: TV

    this.playAnim("Boyfriend DJ", false);
  }

//   var cartoonSnd:Null<FunkinSound> = null;

  public var playingCartoon:Bool = false;

  public function runTvLogic() {
    /*if (cartoonSnd == null) {
      // tv is OFF, but getting turned on
      FunkinSound.playOnce(Paths.sound('tv_on'), 1.0, function() {
        loadCartoon();
      });
    } else {
      // plays it smidge after the click
      FunkinSound.playOnce(Paths.sound('channel_switch'), 1.0, function() {
        cartoonSnd.destroy();
        loadCartoon();
      });
    }*/

    // loadCartoon();
  }

  function loadCartoon() {
    // cartoonSnd = FunkinSound.load(Paths.sound(getRandomFlashToon()), 1.0, false, true, true, function() { anim.play("Boyfriend DJ watchin tv OG", true, false, 60); });

    // Fade out music to 40% volume over 1 second. -- This helps make the TV a bit more audible.
    FlxG.sound.music.fadeOut(1.0, 0.4);

    // Play the cartoon at a random time between the start and 5 seconds from the end.
    // cartoonSnd.time = FlxG.random.float(0, Math.max(cartoonSnd.length - (5 * Constants.MS_PER_SEC), 0.0));
  }

  final cartoonList:Array<String> = openfl.utils.Assets.list().filter(function(path) return path.startsWith("assets/sounds/cartoons/"));

  function getRandomFlashToon():String {
    var randomFile = FlxG.random.getObject(cartoonList);
    randomFile = randomFile.replace("assets/sounds/", ""); // Strip folder prefix
    randomFile = randomFile.substring(0, randomFile.length - 4); // Strip file extension

    return randomFile;
  }

  public function playAnim(id:String, ?Force:Bool = false, ?Reverse:Bool = false, ?Frame:Int = 0):Void {
    anim.play(id, Force, Reverse, Frame);
    
    var daOffset = animOffsets.get(id);

    if (animOffsets.exists(id)) offset.set(daOffset[0], daOffset[1]);
    else offset.set(0, 0);

    __prevPlayedAnimation = id;
  }

  public override function destroy():Void {
    super.destroy();

    // if (cartoonSnd != null) {
    //   cartoonSnd.destroy();
    //   cartoonSnd = null;
    // }
  }

  public function confirm():Void currentState = Confirm;

  var __prevPlayedAnimation:String = '';
  public inline function getAnimationName():String return __prevPlayedAnimation;
}

enum DJBoyfriendState
{
  Intro;
  Idle;
  Confirm;
  Spook;
  TV;
}