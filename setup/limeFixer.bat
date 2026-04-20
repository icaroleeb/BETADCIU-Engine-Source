@echo off
cd ../
cd .haxelib/lime/git/
git submodule update
cd ../../../
haxelib run lime rebuild cpp -clean

echo:
echo Finished rebuilding lime -- Thank NMVTeam for making this script!
pause
