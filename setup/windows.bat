@REM @echo off
@REM color 0a
@REM cd ..
@REM @echo on
@REM echo Installing dependencies...
@REM echo This might take a few moments depending on your internet speed.
@REM haxelib install lime 8.3.1
@REM haxelib install openfl 9.3.3
@REM haxelib install flixel 6.1.0
@REM haxelib install flixel-addons 3.3.2
@REM haxelib install flixel-tools 1.5.1
@REM haxelib install hscript-iris 1.1.3
@REM haxelib install tjson 1.4.0
@REM haxelib install hxdiscord_rpc 1.2.4
@REM haxelib install hxvlc 2.0.1 --skip-dependencies
@REM haxelib install format 3.8.0
@REM haxelib set lime 8.1.2
@REM haxelib set openfl 9.3.3
@REM haxelib install flixel-animate 1.4.0
@REM haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
@REM haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
@REM haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
@REM haxelib git extension-haptics https://github.com/LimeExtensions/extension-haptics 5e596270017b4c159b5c2feda087941ab159636d
@REM echo Finished!
@REM pause

@echo off
color 0a
cd ..
@echo on

echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git hxpkg https://github.com/ADA-Funni/hxpkg add-hmm-compatibility
haxelib run hxpkg setup
haxelib run hxpkg install --force
haxelib run lime rebuild cpp -release

echo Installation finished! If you get errors related to lime, run limeFixer script and try again.
pause