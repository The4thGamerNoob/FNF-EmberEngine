package backend;


import flixel.input.keyboard.FlxKey;


class ExtraKeysHandler {
    public static var instance:ExtraKeysHandler;


    public var data:ExtraKeysData;


    public function new() {
        reloadExtraKeys();
    }


    public function reloadExtraKeys() {
        var parser = new json2object.JsonParser<ExtraKeysData>();
        var dataPath:String = 'data/extrakeys.json';
        var dataText:String = Paths.getTextFromFile(dataPath);
		parser.fromJson(dataText);
		data = parser.value;
    }
}


class ExtraKeysData {
    public var keys:Array<EKManiaMode>;


    // these are only used to set the colors into your save data!
    public var colors:Array<EKNoteColor>;
    public var pixelNoteColors:Array<EKNoteColor>;


    public var animations:Array<EKAnimation>;
    public var maxKeys:Int;
    public var minKeys:Int;


    // these are used to set your keybinds into your save data!
    // also used when you click the Default Reset button
    public var keybinds:Array<Array<Array<Int>>>;


    // I said i wouldnt, but here it is! Anyway...
    public var scales:Array<Float>;
}


class EKManiaMode {
    public var notes:Array<Int>;
}


class EKNoteColor {
    public var inner:String;
    public var border:String;
    public var outline:String;


    public function new(){}
}


class EKAnimation {
    public var strum:String;
    public var anim:String;
    public var note:String;
    public var sing:String;
}