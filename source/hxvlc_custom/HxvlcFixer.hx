package;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class HxvlcFixer {
    static function main() {
        var root = getHaxelibPath();
        var libPath = root + "/hxvlc/2,0,1/source/hxvlc/openfl/Video.hx";
        
        if (FileSystem.exists(libPath)) {
            var content = File.getContent(libPath);
            if (content.indexOf("__enterFrame(deltaTime:Int)") != -1) {
                trace("first time boot detected! fixing hxvlc...");
                content = StringTools.replace(content, "__enterFrame(deltaTime:Int)", "__enterFrame(deltaTime:Float)");
                File.saveContent(libPath, content);
                trace("done!");
            }
        }
    }

    static function getHaxelibPath():String {
        try {
            var proc = new Process("haxelib", ["config"]);
            var output = StringTools.trim(proc.stdout.readAll().toString());
            proc.close();
            if (output.length > 0)
                return output;
        } catch (e:Dynamic) {
            trace("failed to get the haxelib path: " + e);
        }
        return null;
    }
}