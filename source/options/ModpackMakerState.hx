package options;

import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxCamera;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

import psychlua.FunkinLua;
import psychlua.DebugLuaText;

import objects.Character;
import objects.Character.CharacterFile;
import backend.Song.SwagSong;
import backend.StageData.StageFile;

#if cpp
import sys.thread.Thread;
#end

using StringTools;

class ModpackMakerState extends MusicBeatState {
    private var camEditor:FlxCamera;
    private var camHUD:FlxCamera;
    private var camMenu:FlxCamera;

    public var camFollow:FlxObject;
    var UI_box:PsychUIBox;

    var directoryDropDown:PsychUIDropDownMenu;
    var songDirectoryDropDown:PsychUIDropDownMenu;

    var swagDirectory:String;
    var swagSongDirectory:String;
    var swagSuf:String = "";

    public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

    public static var selectedSongName:String = ""; // I screwed myself over by using dofile

    public function new() {
        super();
    }

    override function create() {
        camEditor = initPsychCamera();

        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        camMenu = new FlxCamera();
        camMenu.bgColor.alpha = 0;

        FlxG.cameras.add(camHUD, false);
        FlxG.cameras.add(camMenu, false);

        luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
        add(luaDebugGroup);
        luaDebugGroup.cameras = [camMenu];

        setupBackgroundAndTitle();

        camFollow = new FlxObject(0, 0, 2, 2);
        camFollow.screenCenter();
        add(camFollow);

        FlxG.camera.follow(camFollow);

        UI_box = new PsychUIBox(FlxG.width - 360, 25, 350, 350, ['Setup']);
        UI_box.scrollFactor.set(1, 1);
        UI_box.cameras = [camMenu];
        add(UI_box);

        addSetupUI();
        UI_box.selectedName = 'Setup';

        FlxG.mouse.visible = true;
        reloadSetupOptions();

        new ModpackAssetRegistry();
        PlayState.instance = new DummyPlayState();

        super.create();
    }

    private function setupBackgroundAndTitle():Void {
        var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFFea71fd;
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

        var titleText = createText("MODPACK MAKER!!!", 50, 50, 48, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, 3, camMenu);
        add(titleText);

        var descText = createText(
            "A helpful tool that allows you to make Modpacks from Master Folders.",
            50, 600, 32, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, 2.4, null
        );
        descText.width = 1180;
        descText.scrollFactor.set();
        descText.screenCenter();
        descText.y += 270;
        add(descText);
    }

    private function createText(text:String, x:Float, y:Float, size:Int, color:FlxColor, borderStyle:FlxTextBorderStyle, borderSize:Float, cam:FlxCamera):FlxText {
        var txt = new FlxText(x, y, 0, text, size);
        txt.setFormat(Paths.font("vcr.ttf"), size, color, CENTER, borderStyle, FlxColor.BLACK);
        txt.borderSize = borderSize;
        if (cam != null) txt.cameras = [cam];
        return txt;
    }

    var weekFileNameInput:PsychUIInputText;
    var modpackNameInput:PsychUIInputText; // Add this at class level if you want to access it later

    function addSetupUI():Void {
        var tabGroup = UI_box.getTab("Setup").menu;

        directoryDropDown = new PsychUIDropDownMenu(15, 45, [''], onDirectorySelected);
        songDirectoryDropDown = new PsychUIDropDownMenu(directoryDropDown.x + 170, 45, [''], onSongDirectorySelected);

        // Modpack Name input field
        modpackNameInput = new PsychUIInputText(15, 105, 200, "Modpack", 8);

        // Week File Name input field
        weekFileNameInput = new PsychUIInputText(15, 165, 200, "", 8);

        var createButton = new FlxButton(directoryDropDown.x, 275, "Create Modpack", copyAndWriteFiles);
        createButton.setGraphicSize(80, 30);
        createButton.updateHitbox();

        // Labels
        tabGroup.add(new FlxText(directoryDropDown.x, directoryDropDown.y - 18, 0, 'Mod Directory:'));
        tabGroup.add(new FlxText(songDirectoryDropDown.x, songDirectoryDropDown.y - 18, 0, 'Song Directory:'));
        tabGroup.add(new FlxText(modpackNameInput.x, modpackNameInput.y - 18, 0, 'Modpack Name:'));
        tabGroup.add(new FlxText(weekFileNameInput.x, weekFileNameInput.y - 18, 0, 'Week File Name:'));

        // Add all UI elements
        for (item in [
            modpackNameInput,
            weekFileNameInput,
            directoryDropDown,
            songDirectoryDropDown,
            createButton
        ])
            tabGroup.add(item);
    }

    private function onDirectorySelected(selected:Int, pressed:String):Void {
        swagDirectory = directoryDropDown.selectedLabel;
        Mods.currentModDirectory = swagDirectory;
        reloadDirectoryDropDown("data");
    }

    private function onSongDirectorySelected(index:Int, label:String):Void {
        swagSongDirectory = songDirectoryDropDown.selectedLabel;

        var defaultName = swagSongDirectory + "-betadciu";
        var weeksFolder = Paths.modFolders(modpackNameInput.text + "/weeks/");

        var foundBetadciu:Bool = false;
        var songName:String = "";

        if (FileSystem.exists(weeksFolder)) {
            for (file in FileSystem.readDirectory(weeksFolder)) {
                if (file.endsWith("-betadciu.json")) {
                    try {
                        var filePath = weeksFolder + file;
                        var raw = File.getContent(filePath).trim();
                        var json:Dynamic = Json.parse(raw);

                        if (Reflect.hasField(json, "songs") && json.songs.length > 0 && json.songs[0].length > 0) {
                            songName = json.songs[0][0].toLowerCase(); // First song
                            foundBetadciu = true;
                            break;
                        }
                    } catch (e:Dynamic) {
                        trace("Error reading week file: " + e);
                    }
                }
            }
        }

        selectedSongName = swagSongDirectory;

        if (foundBetadciu && songName != "") {
            defaultName = songName + "-bonus";
        }

        if (weekFileNameInput != null) {
            weekFileNameInput.text = defaultName;
        }
    }

    function copyAndWriteFiles():Void {
        for (dataType in ["data", "songs"]) {
            var folder = Paths.modFolders(swagDirectory + "/" + dataType + "/" + swagSongDirectory + "/");
            var modpackFolder = Paths.modFolders(modpackNameInput.text + "/" + dataType + "/" + swagSongDirectory + "/");
            processFolder(folder, modpackFolder, dataType);
        }

        ModpackAssetRegistry.instance.processAll(swagDirectory, modpackNameInput.text);
        createWeekFile();

        FlxG.sound.play(Paths.sound('confirmMenu'));
        showToast("Modpack created successfully!");
    }

    function createWeekFile():Void {
        var weeksPath = Paths.modFolders(modpackNameInput.text + "/weeks");
        if (!FileSystem.exists(weeksPath)) FileSystem.createDirectory(weeksPath);

        var folder = Paths.modFolders(swagDirectory + "/data/" + swagSongDirectory + "/");
        var p2Icon = "bf";
        var p2HC:Array<Int> = [0, 0, 0];
        var daSongName = "tutorial";

        // Grab character and song info
        for (file in FileSystem.readDirectory(folder)) {
            if (file.endsWith("-hard.json") && file.startsWith(swagSongDirectory)) {
                var path = folder + file;
                var rawJson = FileSystem.exists(path) ? File.getContent(path).trim() : Assets.getText(path).trim();
                var json:SwagSong = cast getSongJson(rawJson);

                if (json.player2 != null) {
                    var charData = loadCharacterFile(json.player2);
                    if (charData != null) {
                        p2Icon = charData.healthicon;
                        p2HC = charData.healthbar_colors;
                    }
                }

                daSongName = json.song;
            }
        }

        var weekFilePath = weeksPath + "/" + weekFileNameInput.text + ".json";
        var weekData:Dynamic = null;

        // Check for existing file and load if found
        if (FileSystem.exists(weekFilePath)) {
            var rawWeek = File.getContent(weekFilePath);
            weekData = Json.parse(rawWeek);

            if (weekData == null || !Reflect.hasField(weekData, "songs")) {
                weekData = null; // fallback to creating a new structure
            }
        }

        // If no valid week data was loaded, create new
        if (weekData == null) {
            var isBonus:Bool = weekFileNameInput.text.toLowerCase().endsWith("-bonus");

            // Format weekName accordingly
            var weekName = isBonus
                ? CoolUtil.toTitleCase(StringTools.replace(weekFileNameInput.text, "-", " "))
                : CoolUtil.toTitleCase(StringTools.replace(swagDirectory, "-", " ")) + " BETADCIU";

            weekData = {
                storyName: weekName,
                hideFreeplay: false,
                weekBackground: "bruh",
                difficulties: "Hard",
                weekBefore: "tutorial",
                startUnlocked: true,
                weekCharacters: ["", "bf", ""],
                songs: [],
                hideStoryMode: false,
                weekName: weekName
            };
        }

        // Append song to list if not already present
        var songList:Array<Dynamic> = Reflect.field(weekData, "songs");
        songList.push([daSongName, p2Icon, p2HC]);

        // Save result
        File.saveContent(weekFilePath, Json.stringify(weekData, null, "    "));
    }



    private function loadCharacterFile(characterId:String):CharacterFile {
        var path = Paths.getPath('images/characters/jsons/' + characterId + '.json', TEXT);
        #if MODS_ALLOWED
        if (FileSystem.exists(Paths.modFolders('characters/' + characterId + '.json')) || Assets.exists(Paths.modFolders('characters/' + characterId + '.json')))
            path = Paths.modFolders('characters/' + characterId + '.json');
        #end
        if (!FileSystem.exists(path) && !Assets.exists(path)) {
            path = Paths.getPath('images/characters/jsons/' + Character.DEFAULT_CHARACTER + ".json", TEXT);
        }
        var rawJson = FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path);
        return cast Json.parse(rawJson);
    }


    // This one processes all files in the directory
    public function processFolder(folder:String, modpackFolder:String, dataType:String):Void {
        if (!FileSystem.exists(modpackFolder)) FileSystem.createDirectory(modpackFolder);

        for (file in FileSystem.readDirectory(folder)) {
            var initPath = folder + file;
            var modifiedPath = modpackFolder + file;

            if (FileSystem.isDirectory(initPath)) {
                processFolder(initPath + "/", modifiedPath + "/", dataType);
                continue;
            }

            if (file.endsWith('.lua')) {
                var openLua = new FunkinLua(initPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }

            if (dataType == "data") {
                processDataFile(file, initPath);
            }

            sys.io.File.copy(initPath, modifiedPath);
        }
    }

    private function processDataFile(file:String, initPath:String):Void {
        if (file.endsWith("-hard.json") && file.startsWith(swagSongDirectory)) {
            var rawJson = FileSystem.exists(initPath) ? File.getContent(initPath).trim() : Assets.getText(initPath).trim();
            var json:SwagSong = cast getSongJson(rawJson);

            copyNoteAssets([json.noteStyle, json.arrowSkin]);
            copyEventAssets(json.events);
            copyNoteTypeAssets(json.notes);

            // Extra Stuff I should've added from the start
            copyCharacterFromName(json.player1);
            copyCharacterFromName(json.player2);
            copyCharacterFromName(json.gfVersion);
            copyStageFromName(json.stage);
        }

        if (file == 'arrowSwitches.txt') {
            copyNoteAssets(initPath);
        }

        if (file == "preload" + swagSuf + ".txt") {
            copyCharacterAssets(initPath);
        }

        if (file == "preload-stage" + swagSuf + ".txt") {
            copyStageAssets(initPath);
        }

		 if (file == "preload" + swagSuf + ".json") {
            processPreloadAssets(initPath);
        }
    }

	private function processPreloadAssets(initPath:String):Void {
		if (!FileSystem.exists(initPath)) return;

		try {
			var rawJson = File.getContent(initPath).trim();
			var preloadData:Dynamic = Json.parse(rawJson);

			// Handle characters (expects array of strings: character names)
			if (Reflect.hasField(preloadData, "characters")) {
				var chars:Array<String> = cast preloadData.characters;
				for (charName in chars) {
					copyCharacterFromName(charName);
				}
			}

			// Handle images (expects array of paths)
			if (Reflect.hasField(preloadData, "images")) {
				var images:Array<String> = cast preloadData.images;
				for (image in images) {
					ModpackAssetRegistry.instance.addAsset("images", image);
				}
			}

			// Handle sounds (expects array of paths)
			if (Reflect.hasField(preloadData, "sounds")) {
				var sounds:Array<String> = cast preloadData.sounds;
				for (sound in sounds) {
					ModpackAssetRegistry.instance.addAsset("sounds", sound);
				}
			}

			// Handle fonts
			if (Reflect.hasField(preloadData, "fonts")) {
				var fonts:Array<String> = cast preloadData.fonts;
				for (font in fonts) {
					ModpackAssetRegistry.instance.addAsset("fonts", font);
				}
			}

			// Handle videos
			if (Reflect.hasField(preloadData, "videos")) {
				var videos:Array<String> = cast preloadData.videos;
				for (vid in videos) {
					ModpackAssetRegistry.instance.addAsset("videos", vid);
				}
			}

			// Handle shaders
			if (Reflect.hasField(preloadData, "shaders")) {
				var shaders:Array<String> = cast preloadData.shaders;
				for (shader in shaders) {
					ModpackAssetRegistry.instance.addAsset("shaders", shader);
				}
			}

			// Handle stages
			if (Reflect.hasField(preloadData, "stages")) {
				var stages:Array<String> = cast preloadData.stages;
				for (stageName in stages) {
					copyStageFromName(stageName);
				}
			}

		} catch (e:Dynamic) {
			trace("Error processing preload file: " + e);
		}
	}


    private function copyNoteAssets(input:Dynamic):Void {
        var noteStyles:Array<String> = [];

        if (Std.isOfType(input, String)) {
            var path:String = cast input;
            var stuff = CoolUtil.coolTextFile(path);
            if (stuff == null || stuff.length == 0) return;

            for (line in stuff) {
                var data = line.split(" ");
                if (data.length > 1) noteStyles.push(data[1]);
            }
        }
        else if (Std.isOfType(input, Array)) {
            noteStyles = cast input;
        }
        else return;

        var imagesBase = Paths.modFolders(swagDirectory + "/images/");
        var modpackImagesBase = Paths.modFolders(modpackNameInput.text + "/images/");

        for (noteStyle in noteStyles) {
            if (noteStyle == null || noteStyle.length == 0) continue;

            // 1. Old-style notes folder
            var noteFolder = imagesBase + "notes/";
            var noteModpackFolder = modpackImagesBase + "notes/";
            doCopyShit(noteFolder, noteModpackFolder, [
                noteStyle + ".png",
                noteStyle + ".xml",
                noteStyle + "ENDS.png",
                "noteSplashes-" + noteStyle + ".png",
                "noteSplashes-" + noteStyle + ".xml"
            ]);

            // 2. noteSkins/ (flat)
            var noteSkinFlatFolder = imagesBase + "noteSkins/";
            var noteSkinFlatModpack = modpackImagesBase + "noteSkins/";
            doCopyShit(noteSkinFlatFolder, noteSkinFlatModpack, [
                noteStyle + ".png",
                noteStyle + ".xml",
                noteStyle + "ENDS.png",
                "noteSplashes-" + noteStyle + ".png",
                "noteSplashes-" + noteStyle + ".xml"
            ]);

            // 3. noteSplashes/<noteStyle>/
            var splashFolder = imagesBase + "noteSplashes/" + noteStyle + "/";
            var splashModpackFolder = modpackImagesBase + "noteSplashes/" + noteStyle + "/";
            doCopyShit(splashFolder, splashModpackFolder);

            // 4. noteSkins/<noteStyle>/ (new style folder)
            var noteSkinFolder = imagesBase + "noteSkins/" + noteStyle + "/";
            var noteSkinModpackFolder = modpackImagesBase + "noteSkins/" + noteStyle + "/";
            doCopyShit(noteSkinFolder, noteSkinModpackFolder);
        }
    }

    private function copyEventAssets(events:Array<Dynamic>):Void {
        if (events == null || events.length == 0) return;

        var pushedEvents:Array<String> = [];
        for (event in events) {
            for (i in 0...event[1].length) {
                var evName = Std.string(event[1][i][0]);
                var val1:String = Std.string(event[1][i][1]);
                var val2:String = Std.string(event[1][i][2]);

                // Add event name if not already tracked
                if (pushedEvents.indexOf(evName) < 0) pushedEvents.push(evName);

                // Handle special logic for specific event names
                switch (evName) {
                    case "Change Character":
                        if (val2 != null && val2.length > 0)
                            copyCharacterFromName(val2);

                    case "Change Stage":
                        if (val1 != null && val1.length > 0)
                            copyStageFromName(val1);
                }
            }
        }

        var eventFolder = Paths.modFolders(swagDirectory + "/custom_events/");
        var eventModpackFolder = Paths.modFolders(modpackNameInput.text + "/custom_events/");
        var evCopyArray:Array<String> = [];

        for (ev in pushedEvents) {
            var luaPath = Paths.modFolders("custom_events/" + ev + ".lua");
            if (FileSystem.exists(luaPath)) {
                var openLua = new FunkinLua(luaPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }

            evCopyArray.push(ev + ".txt");
            evCopyArray.push(ev + ".lua");
        }

        doCopyShit(eventFolder, eventModpackFolder, evCopyArray);
    }


    private function copyNoteTypeAssets(notes:Array<Dynamic>):Void {
		if (notes == null || notes.length == 0) return;

        var pushedNoteTypes:Array<String> = [];
        for (section in notes) {
			var sectionNotes:Array<Dynamic> = section.sectionNotes;

            for (songNotes in sectionNotes) {
                var noteType = songNotes[3];
                if (noteType != "" && pushedNoteTypes.indexOf(noteType) < 0) {
                    pushedNoteTypes.push(noteType);
                }
            }
        }

        if (pushedNoteTypes.length == 0) return;

        var ntCopyArray:Array<String> = [];
        var noteTypeFolder = Paths.modFolders(swagDirectory + "/custom_notetypes/");
        var noteTypeModpackFolder = Paths.modFolders(modpackNameInput.text + "/custom_notetypes/");

        for (nt in pushedNoteTypes) {
            var luaPath = Paths.modFolders("custom_notetypes/" + nt + ".lua");
            if (FileSystem.exists(luaPath)) {
                var openLua = new FunkinLua(luaPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }
            ntCopyArray.push(nt + ".txt");
            ntCopyArray.push(nt + ".lua");
        }
        doCopyShit(noteTypeFolder, noteTypeModpackFolder, ntCopyArray);
    }

    private function copyCharacterAssets(initPath:String):Void {
        var characters = CoolUtil.coolTextFile(initPath);
        var charFolder = Paths.modFolders(swagDirectory + "/characters/");
        var charModpackFolder = Paths.modFolders(modpackNameInput.text + "/characters/");

        if (!FileSystem.exists(charModpackFolder)) FileSystem.createDirectory(charModpackFolder);

       for (character in characters) {
			copyCharacterFromName(character);
		}
    }

    private function copyCharacterImages(json:CharacterFile):Void {
        for (folderName in ["characters", "icons"]) {
            var basePath = Paths.modFolders(swagDirectory + "/images/");
            var modpackPath = Paths.modFolders(modpackNameInput.text + "/images/");
            var imagePath = (folderName == "icons") ? "icons/icon-" + json.healthicon : json.image;
            var parts = imagePath.split('/');

            for (i in 0...parts.length - 1) {
                basePath += parts[i] + "/";
                modpackPath += parts[i] + "/";
            }
            doCopyShit(basePath, modpackPath, [parts[parts.length - 1] + ".png", parts[parts.length - 1] + ".xml"]);
        }
    }

	private function copyCharacterFromName(name:String):Void {
		if (name.contains("-embed")) return;

		var charFolder = Paths.modFolders(swagDirectory + "/characters/");
		var charModpackFolder = Paths.modFolders(modpackNameInput.text + "/characters/");
		if (!FileSystem.exists(charModpackFolder)) FileSystem.createDirectory(charModpackFolder);

		for (file in FileSystem.readDirectory(charFolder)) {
			if (file == name + ".json" || file == name + ".lua") {
				if (file.endsWith(".json")) {
					var rawJson = FileSystem.exists(charFolder + file) ? File.getContent(charFolder + file) : Assets.getText(charFolder + file);
					var json:CharacterFile = cast Json.parse(rawJson);
					copyCharacterImages(json);
				}
				if (file.endsWith(".lua")) {
					var openLua = new FunkinLua(charFolder + file, "modpack");
					openLua.call("onCreate", []);
					openLua.call("onCreatePost", []);
				}
				sys.io.File.copy(charFolder + file, charModpackFolder + file);
			}
		}
	}

    private function copyStageAssets(initPath:String):Void {
        var stages = CoolUtil.coolTextFile(initPath);
        var stageFolder = Paths.modFolders(swagDirectory + "/stages/");
        var stageModpackFolder = Paths.modFolders(modpackNameInput.text + "/stages/");

        if (!FileSystem.exists(stageModpackFolder)) FileSystem.createDirectory(stageModpackFolder);

        for (stage in stages) {
			copyStageFromName(stage);
		}
    }

    private function copyStageRelatedAssets(stageData:StageFile):Void {
        if (stageData.ratingSkin != null) {
            copyRatingSkinAssets(stageData.ratingSkin);
        }
        if (stageData.countdownAssets != null) {
            for (asset in stageData.countdownAssets) {
                copyCountdownAsset(asset);
            }
        }
    }

	private function copyStageFromName(name:String):Void {
		if (name.contains("-embed")) return;

		var stageFolder = Paths.modFolders(swagDirectory + "/stages/");
		var stageModpackFolder = Paths.modFolders(modpackNameInput.text + "/stages/");
		if (!FileSystem.exists(stageModpackFolder)) FileSystem.createDirectory(stageModpackFolder);

		for (file in FileSystem.readDirectory(stageFolder)) {
			if (file == name + ".json" || file == name + ".lua") {
				if (file.endsWith(".json")) {
					var rawJson = FileSystem.exists(stageFolder + file) ? File.getContent(stageFolder + file) : Assets.getText(stageFolder + file);
					var stageData:StageFile = cast Json.parse(rawJson);
					copyStageRelatedAssets(stageData);
				}
				if (file.endsWith(".lua")) {
					var openLua = new FunkinLua(stageFolder + file, "modpack");
					openLua.call("onCreate", []);
					openLua.call("onCreatePost", []);
				}
				sys.io.File.copy(stageFolder + file, stageModpackFolder + file);
			}
		}
	}


    private function copyRatingSkinAssets(ratingSkin:Array<String>):Void {
        var parts = ratingSkin[0].split('/');
        var ratingFolder = Paths.modFolders(swagDirectory + "/images/");
        var ratingModpackFolder = Paths.modFolders(modpackNameInput.text + "/images/");

        for (i in 0...parts.length - 1) {
            ratingFolder += parts[i] + "/";
            ratingModpackFolder += parts[i] + "/";
        }

        if (!FileSystem.exists(ratingModpackFolder)) FileSystem.createDirectory(ratingModpackFolder);

        for (file in FileSystem.readDirectory(ratingFolder)) {
            if (!FileSystem.isDirectory(ratingFolder + file) &&
                (file.endsWith(ratingSkin[1] + ".png") || file.endsWith(ratingSkin[1] + ".xml"))) {
                sys.io.File.copy(ratingFolder + file, ratingModpackFolder + file);
            }
        }
    }

    private function copyCountdownAsset(assetPath:String):Void {
        var parts = assetPath.split('/');
        var baseFolder = Paths.modFolders(swagDirectory + "/images/");
        var modpackFolder = Paths.modFolders(modpackNameInput.text + "/images/");

        for (i in 0...parts.length - 1) {
            baseFolder += parts[i] + "/";
            modpackFolder += parts[i] + "/";
        }

        doCopyShit(baseFolder, modpackFolder, [parts[parts.length - 1] + ".png", parts[parts.length - 1] + ".xml"]);
    }

   override function update(elapsed:Float) {
        var canPress:Bool = PsychUIInputText.focusOn == null;

       	ClientPrefs.toggleVolumeKeys(canPress);

        if (canPress && FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new options.OptionsState());
            FlxG.mouse.visible = false;
            return;
        }

        super.update(elapsed);
    }


    function reloadDirectoryDropDown(type:String):Void {
        var lowerType = type.toLowerCase();
        if (lowerType == "data") {
            var directories = getDirectories(swagDirectory + "/data/");
            songDirectoryDropDown.list = directories;
        } else {
            var directories = Paths.getModDirectories();
            directoryDropDown.list = directories;
        }
    }

    private function getDirectories(basePath:String):Array<String> {
        var dirs = new Array<String>();
		var modDirectoryPath = Paths.modFolders(basePath);

        if (FileSystem.exists(modDirectoryPath)) {
            for (folder in FileSystem.readDirectory(modDirectoryPath)) {
                var path = haxe.io.Path.join([modDirectoryPath, folder]);
                if (FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder) && !dirs.contains(folder))
                    dirs.push(folder);
            }
        }
        if (dirs.length == 0) dirs.push("NO DIRECTORIES");
        return dirs;
    }

    function reloadSetupOptions():Void {
        if (UI_box != null) reloadDirectoryDropDown("");
    }

    public function addTextToDebug(text:String, ?color:FlxColor = FlxColor.RED):Void {
        var newText = luaDebugGroup.recycle(DebugLuaText);
        newText.text = text;
        newText.color = color;
        newText.disableTime = 6;
        newText.alpha = 1;
        newText.setPosition(10, 8 - newText.height);

        luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
            spr.y += newText.height + 2;
        });
        luaDebugGroup.add(newText);

        Sys.println(text);
    }

    public function getSongJson(rawJson:String){
        var songJson:Dynamic = Json.parse(rawJson);
         
        if(Reflect.hasField(songJson, 'song'))
        {
            var subSong:SwagSong = Reflect.field(songJson, 'song');
            if(subSong != null && Type.typeof(subSong) == TObject)
                songJson = subSong;
        }

        return songJson;
    }

    function showToast(message:String, duration:Float = 2):Void {
        var toast = new FlxText(0, 0, 0, message, 20);
        toast.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        toast.borderSize = 2;
        toast.screenCenter(X);
        toast.y = FlxG.height - 60;
        toast.scrollFactor.set();
        toast.cameras = [camHUD]; // Put on HUD layer

        add(toast);

        FlxTween.tween(toast, {alpha: 0}, 0.5, {
            startDelay: duration,
            onComplete: function(_) {
                toast.destroy(); // Clean up
            }
        });
    }
}

// Helper function for copying files with optional filtering
function doCopyShit(srcFolder:String, destFolder:String, checkFiles:Array<String> = null):Void {
    if (!FileSystem.exists(srcFolder)) return;
    if (!FileSystem.exists(destFolder)) FileSystem.createDirectory(destFolder);

    for (file in FileSystem.readDirectory(srcFolder)) {
        if (checkFiles != null && checkFiles.length > 0) {
            if (checkFiles.indexOf(file) >= 0) {
                sys.io.File.copy(srcFolder + file, destFolder + file);
            }
        } else {
            var fullSrc = srcFolder + file;
            var fullDest = destFolder + file;

            if (FileSystem.exists(fullSrc)) {
                sys.io.File.copy(fullSrc, fullDest);
            }
        }
    }
}

class ModpackAssetGroup {
    public var subDir:String;
    public var extensions:Array<String>;
    private var assets:Map<String, Bool>; // acts like a Set

    public function new(subDir:String, extensions:Array<String>) {
        this.subDir = subDir;
        this.extensions = extensions;
        this.assets = new Map();
    }

    public function add(path:String):Void {
        assets.set(path, true); // no duplicates
    }

    public function clear():Void {
        assets.clear();
    }

    public function getList():Array<String> {
        return [for (k in assets.keys()) k];
    }
}

class ModpackAssetRegistry {
    public static var instance:ModpackAssetRegistry;

    private var groups:Map<String, ModpackAssetGroup>;

    public function new() {
        groups = new Map();

        addGroup("images", [".png", ".xml"]);
        addGroup("fonts", [""]);
        addGroup("sounds", [".ogg", ".mp3"]);
        addGroup("videos", [".mp4", ".webm"]);
        addGroup("shaders", [".frag", ".vert", ".glsl"]);

        ModpackAssetRegistry.instance = this;
    }

    private function addGroup(type:String, extensions:Array<String>):Void {
        groups.set(type, new ModpackAssetGroup(type, extensions));
    }

    public function addAsset(type:String, path:String):Void {
        if (groups.exists(type) && path != null && path.length > 0){
			trace('[addAsset] Adding $path to $type');
			groups.get(type).add(path);
		}
    }

    public function processAll(swagDirectory:String, newDirectory:String):Void {
        for (group in groups.iterator()) {
            processLuaList(group.getList(), group.subDir, group.extensions, swagDirectory, newDirectory);
            group.clear();
        }
    }

    public function processLuaList(luaList:Array<String>, subDir:String, extensions:Array<String>, swagDirectory:String, newDirectory:String):Void {
        if (luaList == null || luaList.length == 0) return;

        // Wrap the actual logic
        function copyLogic():Void {
            for (item in luaList) {
                var parts = item.split('/');
                var baseFolder = Paths.modFolders('$swagDirectory/$subDir/');
                var modpackFolder = Paths.modFolders('$newDirectory/$subDir/');

                for (i in 0...parts.length - 1) {
                    baseFolder += parts[i] + '/';
                    modpackFolder += parts[i] + '/';
                }

                var fileBase = parts[parts.length - 1];
                var filesToCopy = extensions.map(ext -> fileBase + ext);
                doCopyShit(baseFolder, modpackFolder, filesToCopy);
            }

            luaList.splice(0, luaList.length); // optional cleanup
        }

        #if cpp
        // Run in a background thread (only on native targets)
        Thread.create(copyLogic);
        #else
        // Fallback to synchronous version
        copyLogic();
        #end
    }
}

// So that I don't have to add game != null to everything in FunkinLua
class DummyPlayState extends PlayState {
	public function new() {
		super();
		PlayState.instance = this; // Register this dummy as the active PlayState
	}

	override function create() {
        // DO NOTHING
	}

    override function update(elapsed:Float) {
        // DO NOTHING
	}

    override function beatHit() {
        // DO NOTHING
	}

    override function stepHit() {
        // DO NOTHING
	}

	override function getLuaObject(tag:String):Dynamic {
		// Optionally store dummy objects here if needed
		return null;
	}
}
