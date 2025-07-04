function onCreate(){
	var stageVars = game.variables.get("stageVariables");

	var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
	bg.scrollFactor.set(0.9, 0.9);
	game.addBehindGF(bg);
	stageVars.set("bg", bg);

	var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
	stageFront.scrollFactor.set(0.9, 0.9);
	stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
	stageFront.updateHitbox();
	game.addBehindGF(stageFront);
	stageVars.set("stageFront", stageFront);

	var stageLight:FlxSprite = new FlxSprite(-125, -100).loadGraphic(Paths.image('stage_light'));
	stageLight.scrollFactor.set(0.9, 0.9);
	stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
	stageLight.updateHitbox();
	game.add(stageLight);
	stageVars.set("stageLight", stageLight);

	var stageLight2:FlxSprite = new FlxSprite(1225, -100).loadGraphic(Paths.image('stage_light'));
	stageLight2.scrollFactor.set(0.9, 0.9);
	stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
	stageLight2.updateHitbox();
	stageLight2.flipX = true;
	game.add(stageLight2);
	stageVars.set("stageLight2", stageLight2);

	var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
	stageCurtains.scrollFactor.set(1.3, 1.3);
	stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
	stageCurtains.updateHitbox();
	game.add(stageCurtains);
	stageVars.set("stageCurtains", stageCurtains);
}