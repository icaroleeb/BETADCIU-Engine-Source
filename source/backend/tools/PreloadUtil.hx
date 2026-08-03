package backend.tools;

import states.PlayState;
import objects.Character;
import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;

class PreloadUtil
{
    public static var isPreloading:Bool = false;
    public static var stagesToLoad:Array<String> = [];
    public static var charactersToLoad:Array<String> = [];
    public static var imagesToLoad:Array<String> = [];
    public static var soundsToLoad:Array<String> = [];

    public static function preload(?chars:Array<String>, ?images:Array<String>, ?stages:Array<String>, ?sounds:Array<String>) {
        if (chars != null) charactersToLoad = charactersToLoad.concat(chars);
        if (images != null) imagesToLoad = imagesToLoad.concat(images);
        if (stages != null) stagesToLoad = stagesToLoad.concat(stages);
        if (sounds != null) soundsToLoad = soundsToLoad.concat(sounds);

        charactersToLoad = CoolUtil.removeDupe(charactersToLoad, "Preload Characters");
        imagesToLoad = CoolUtil.removeDupe(imagesToLoad, "Preload Images");
        stagesToLoad = CoolUtil.removeDupe(stagesToLoad, "Preload Stages");
        soundsToLoad = CoolUtil.removeDupe(soundsToLoad, "Preload Sounds");

        var loadedArray:Array<String> = []; // just to debloat the terminal a bit

        if (charactersToLoad.length > 0) {
            for (char in charactersToLoad) {
                var dummyChar:Character = new Character(0, 0, char);
                
                if (FlxG.state is PlayState) {
                    PlayState.instance.startCharacterScripts(char);
                    PlayState.instance.stopCharacterScripts(char);
                }

                if (dummyChar.missingCharacter) trace('Failed to load character: $char');
                else loadedArray.push(char);

                if (dummyChar != null) dummyChar.destroy();
                dummyChar = null;
            }
            charactersToLoad = [];

            trace("Characters Loaded: " + loadedArray);
            loadedArray = [];
        }

        if ((FlxG.state is PlayState) && stagesToLoad.length > 0) {
            var ogStage = PlayState.instance.curStage;
            for (stage in stagesToLoad) {
                PlayState.instance.changeStage(stage, true);
                loadedArray.push(stage);
            }
            stagesToLoad = [];
            PlayState.instance.changeStage(ogStage, true); 

            trace("Stages Loaded: " + loadedArray);
            loadedArray = [];
        }

        if (imagesToLoad.length > 0) {
            for (image in imagesToLoad) {
                if (Paths.image(image, null, ClientPrefs.data.cacheOnGPU) != null)
                    loadedArray.push(image);
                else
                    trace("Failed to load image: " + image);
            }
            imagesToLoad = [];

            trace("Images Loaded: " + loadedArray);
            loadedArray = [];
        }

        if (soundsToLoad.length > 0) { // not adding the null check here because paths.sound already has its own null trace
            for (sound in soundsToLoad) {
                Paths.sound(sound);
            }
            soundsToLoad = [];
        }
    }

    public static function grabStuffToPreload() {
        var songPath:String = PlayState.instance.songName;
        
        var checkAndPush = function(path:String, list:Array<String>) {
            if (FileSystem.exists(path)) {
                var items = CoolUtil.coolTextFile(path);
                for (item in items) list.push(item.split(' ')[0]);
                isPreloading = true;
            }
        };

        checkAndPush(Paths.txt('$songPath/preload'), charactersToLoad);
        checkAndPush(Paths.txt('$songPath/preload-stage'), stagesToLoad);

        // JSON Parsing
        var jsonPath:String = Paths.json('$songPath/preload');
        if (FileSystem.exists(jsonPath)) {
            try {
                var content:String = Paths.getContent(jsonPath);
                var data:Dynamic = Json.parse(content);

                if (data.characters != null) charactersToLoad = charactersToLoad.concat(cast data.characters);
                if (data.stages != null) stagesToLoad = stagesToLoad.concat(cast data.stages);
                if (data.images != null) imagesToLoad = imagesToLoad.concat(cast data.images);
                if (data.sounds != null) soundsToLoad = soundsToLoad.concat(cast data.sounds);
                isPreloading = true;
            } catch (e:Dynamic) {
                trace("Error parsing JSON: " + e);
            }
        }
    }
}