package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;

import flixel.system.FlxAssets.FlxShader;
import flixel.graphics.frames.FlxFrame;

typedef NoteHoldCoverConfig = {
	anim:String,
	minFps:Int,
	maxFps:Int,
	offsets:Array<Array<Float>>
}

class NoteHoldCover extends FlxSprite
{
  public var rgbShader:PixelCoverShaderRef;
  private var idleAnim:String;
	private var _textureLoaded:String = null;
	private var _configLoaded:String = null;

  public static var defaultNoteHoldCover(default, never):String = 'noteCovers/noteCovers';
	public static var configs:Map<String, NoteHoldCoverConfig> = new Map<String, NoteHoldCoverConfig>();

  public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		animation = new PsychAnimationController(this);

		var skin:String = null;
		if(PlayState.SONG.coverSkin != null && PlayState.SONG.coverSkin.length > 0) skin = PlayState.SONG.coverSkin;
		else skin = defaultNoteHoldCover + getCoverSkinPostfix();
		
		rgbShader = new PixelCoverShaderRef();
		shader = rgbShader.shader;
		precacheConfig(skin);
		_configLoaded = skin;
		scrollFactor.set();
    //setupNoteCover(x, y, 0)
	}

  override function destroy()
  {
      configs.clear();
      super.destroy();
  }

  var maxAnims:Int = 2;
	public function setupNoteHoldCover(x:Float, y:Float, direction:Int = 0, ?note:Note = null) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		aliveTime = 0;

		var texture:String = null;
		if(note != null && note.noteHoldCoverData.texture != null) texture = note.noteHoldCoverData.texture;
		else if(PlayState.SONG.coverSkin != null && PlayState.SONG.coverSkin.length > 0) texture = PlayState.SONG.coverSkin;
		else texture = defaultNoteHoldCover + getCoverSkinPostfix();
		
		var config:NoteHoldCoverConfig = null;
		if(_textureLoaded != texture)
			config = loadAnims(texture);
		else
			config = precacheConfig(_configLoaded);

		var tempShader:RGBPalette = null;
		if((note == null || note.noteHoldCoverData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
		{
			// If Note RGB is enabled:
			if(note != null && !note.noteHoldCoverData.useGlobalShader)
			{
				
				if(note.noteHoldCoverData.r != -1) note.rgbShader.r = note.noteHoldCoverData.r;
				if(note.noteHoldCoverData.g != -1) note.rgbShader.g = note.noteHoldCoverData.g;
				if(note.noteHoldCoverData.b != -1) note.rgbShader.b = note.noteHoldCoverData.b;
				tempShader = note.rgbShader.parent;
			}
			else tempShader = Note.globalRgbShaders[direction];
		}

		alpha = ClientPrefs.data.coverAlpha;
		if(note != null) alpha = note.noteHoldCoverData.a;
		rgbShader.copyValues(tempShader);

		if(note != null) antialiasing = note.noteHoldCoverData.antialiasing;
		if(PlayState.isPixelStage || !ClientPrefs.data.antialiasing) antialiasing = false;

		_textureLoaded = texture;
		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, maxAnims);
		animation.play('note' + direction + '-' + animNum, true);
		
		var minFps:Int = 22;
		var maxFps:Int = 26;
		if(config != null)
		{
			var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
			//trace('anim: ${animation.curAnim.name}, $animID');
			var offs:Array<Float> = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length-1)];
			offset.x += offs[0];
			offset.y += offs[1];
			minFps = config.minFps;
			maxFps = config.maxFps;
		}
		else
		{
			offset.x += -58;
			offset.y += -55;
		}

		if(animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
	}

  public static function getCoverSkinPostfix()
  {
    var skin:String = '';
    if(ClientPrefs.data.coverSkin != ClientPrefs.defaultData.coverSkin)
        skin = '-' + ClientPrefs.data.coverSkin.trim().toLowerCase().replace(' ', '_');
    return skin;
  }

  function loadAnims(skin:String, ?animName:String = null):NoteHoldCoverConfig {
		maxAnims = 0;
		frames = Paths.getSparrowAtlas(skin);
		var config:NoteHoldCoverConfig = null;
		if(frames == null)
		{
			skin = defaultNoteHoldCover + getCoverSkinPostfix();
			frames = Paths.getSparrowAtlas(skin);
			if(frames == null) //if you really need this, you really fucked something up
			{
				skin = defaultNoteHoldCover;
				frames = Paths.getSparrowAtlas(skin);
			}
		}
		config = precacheConfig(skin);
		_configLoaded = skin;

		if(animName == null)
			animName = config != null ? config.anim : 'note cover';

		while(true) {
			var animID:Int = maxAnims + 1;
			for (i in 0...Note.colArray.length) {
				if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false)) {
					//trace('maxAnims: $maxAnims');
					return config;
				}
			}
			maxAnims++;
			//trace('currently: $maxAnims');
		}
	}

  public static function precacheConfig(skin:String)
  {
    if(configs.exists(skin)) return configs.get(skin);
  
    var path:String = Paths.getPath('images/$skin.txt', TEXT, true);
    var configFile:Array<String> = CoolUtil.coolTextFile(path);
    if(configFile.length < 1) return null;

    var framerates:Array<String> = configFile[1].split(' ');
    var offs:Array<Array<Float>> = [];
    for (i in 2...configFile.length)
    {
      var animOffs:Array<String> = configFile[i].split(' ');
      offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
    }
  
    var config:NoteSplashConfig = {
      anim: configFile[0],
      minFps: Std.parseInt(framerates[0]),
      maxFps: Std.parseInt(framerates[1]),
      offsets: offs
    };
    configs.set(skin, config);
    return config;
  }

  function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
  {
    var animFrames = [];
    @:privateAccess
    animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

    if(animFrames.length < 1) return false;
   
    animation.addByPrefix(name, anim, framerate, loop);
    return true;
  }

  static var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float) {
		aliveTime += elapsed;
		if((animation.curAnim != null && animation.curAnim.finished) ||
			(animation.curAnim == null && aliveTime >= buggedKillTime && holdFinished)) kill();

		super.update(elapsed);
	}
}

class PixelCoverShaderRef {
	public var shader:PixelCoverShader = new PixelCoverShader();

	public function copyValues(tempShader:RGBPalette)
	{
		var enabled:Bool = false;
		if(tempShader != null)
			enabled = true;

		if(enabled)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else shader.mult.value[0] = 0.0;
	}

  public function new()
  {
    shader.r.value = [0, 0, 0];
    shader.g.value = [0, 0, 0];
    shader.b.value = [0, 0, 0];
    shader.mult.value = [1];
  
    var pixel:Float = 1;
    if(PlayState.isPixelStage) pixel = PlayState.daPixelZoom;
    shader.uBlocksize.value = [pixel, pixel];
    //trace('Created shader ' + Conductor.songPosition);
  }
}

class PixelCoverShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if(color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}