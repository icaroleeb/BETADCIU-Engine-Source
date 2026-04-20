package;
import sys.io.File;
import sys.FileSystem;

class HxvlcFixer {
    static function main() {
        var libPath = "D:/Backup/coisas aleatorias/BETADCIU-Engine-Source/.haxelib/hxvlc/2,0,1/source/hxvlc/openfl/Video.hx";
        
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
}