package game;

import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxColor;
import modding.CharacterCreationState.SpritesheetType;
import lime.utils.Assets;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.Json;
#if sys
import sys.io.File;
import polymod.backends.PolymodAssets;
#end
import utilities.CoolUtil;
import states.PlayState;
import flixel.FlxSprite;
import modding.CharacterConfig;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;
	var animationNotes:Array<Dynamic> = [];

	var dancesLeftAndRight:Bool = false;

	public var barColor:FlxColor = FlxColor.WHITE;
	public var positioningOffset:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];

	public var otherCharacters:Array<Character>;

	var offsetsFlipWhenPlayer:Bool = true;
	var offsetsFlipWhenEnemy:Bool = false;

	public var coolTrail:FlxTrail;

	public var deathCharacter:String = "bf-dead";

	public var swapLeftAndRightSingPlayer:Bool = true;

	public var icon:String;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDeathCharacter:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		antialiasing = true;

		dancesLeftAndRight = false;

		var ilikeyacutg:Bool = false;

		switch (curCharacter)
		{
			case 'dad':
				// DAD ANIMATION LOADING CODE
				frames = Paths.getSparrowAtlas('characters/DADDY_DEAREST', 'shared');
				animation.addByPrefix('idle', 'Dad idle dance', 24, false);
				animation.addByPrefix('singUP', 'Dad Sing Note UP', 24, false);
				animation.addByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24, false);
				animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24, false);
				animation.addByPrefix('singLEFT', 'Dad Sing Note LEFT', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(71, 23, 0);
			case 'pico':
				frames = Paths.getSparrowAtlas('characters/Pico_FNF_assetss', 'shared');
				animation.addByPrefix('idle', "Pico Idle Dance", 24);
				animation.addByPrefix('singUP', 'pico Up note0', 24, false);
				animation.addByPrefix('singDOWN', 'Pico Down Note0', 24, false);

				if (isPlayer)
				{
					animation.addByPrefix('singLEFT', 'Pico NOTE LEFT0', 24, false);
					animation.addByPrefix('singRIGHT', 'Pico Note Right0', 24, false);
					animation.addByPrefix('singRIGHTmiss', 'Pico Note Right Miss', 24, false);
					animation.addByPrefix('singLEFTmiss', 'Pico NOTE LEFT miss', 24, false);
				}
				else
				{
					// Need to be flipped! REDO THIS LATER!
					animation.addByPrefix('singLEFT', 'Pico Note Right0', 24, false);
					animation.addByPrefix('singRIGHT', 'Pico NOTE LEFT0', 24, false);
					animation.addByPrefix('singRIGHTmiss', 'Pico NOTE LEFT miss', 24, false);
					animation.addByPrefix('singLEFTmiss', 'Pico Note Right Miss', 24, false);
				}

				animation.addByPrefix('singUPmiss', 'pico Up note miss', 24);
				animation.addByPrefix('singDOWNmiss', 'Pico Down Note MISS', 24);

				playAnim('idle');

				flipX = true;
				barColor = FlxColor.fromRGB(55, 158, 217);
				cameraOffset = [50,0];
			case '':
				trace("NO VALUE THINGY LOL DONT LOAD SHIT");
				deathCharacter = "";
				icon = "bf-old";

			default:
				if (isPlayer)
					flipX = !flipX;

				ilikeyacutg = true;
				
				loadNamedConfiguration(curCharacter);
		}

		if (isPlayer && !ilikeyacutg)
			flipX = !flipX;

		if (icon == null)
			icon = curCharacter;

		// YOOOOOOOOOO POG MODDING STUFF
		if(character != "")
			loadOffsetFile(curCharacter);

		if(curCharacter != '' && otherCharacters == null)
		{
			updateHitbox();

			if(!debugMode)
			{
				dance();
	
				if(isPlayer)
				{
					// Doesn't flip for BF, since his are already in the right place???
					if(swapLeftAndRightSingPlayer && !isDeathCharacter)
					{
						var oldOffRight = animOffsets.get("singRIGHT");
						var oldOffLeft = animOffsets.get("singLEFT");

						// var animArray
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;

						animOffsets.set("singRIGHT", oldOffLeft);
						animOffsets.set("singLEFT", oldOffRight);
		
						// IF THEY HAVE MISS ANIMATIONS??
						if (animation.getByName('singRIGHTmiss') != null)
						{
							var oldOffRightMiss = animOffsets.get("singRIGHTmiss");
							var oldOffLeftMiss = animOffsets.get("singLEFTmiss");

							var oldMiss = animation.getByName('singRIGHTmiss').frames;
							animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
							animation.getByName('singLEFTmiss').frames = oldMiss;

							animOffsets.set("singRIGHTmiss", oldOffLeftMiss);
							animOffsets.set("singLEFTmiss", oldOffRightMiss);
						}
					}
				}
			}
		}
		else
			visible = false;
	}

	function loadNamedConfiguration(characterName:String)
	{
		var rawJson:String;

		rawJson = Assets.getText(Paths.json("character data/" + characterName + "/config")).trim();

		var config:CharacterConfig = cast Json.parse(rawJson);

		loadCharacterConfiguration(config);
	}

	public function loadCharacterConfiguration(config:CharacterConfig)
	{
		if(config.characters == null || config.characters.length <= 1)
		{
			if(!isPlayer)
				flipX = config.defaultFlipX;
			else
				flipX = !config.defaultFlipX;

			if(config.offsetsFlipWhenPlayer == null)
			{
				if(curCharacter.startsWith("bf"))
					offsetsFlipWhenPlayer = false;
				else
					offsetsFlipWhenPlayer = true;
			}
			else
				offsetsFlipWhenPlayer = config.offsetsFlipWhenPlayer;

			if(config.offsetsFlipWhenEnemy == null)
			{
				if(curCharacter.startsWith("bf"))
					offsetsFlipWhenEnemy = true;
				else
					offsetsFlipWhenEnemy = false;
			}
			else
				offsetsFlipWhenEnemy = config.offsetsFlipWhenEnemy;

			dancesLeftAndRight = config.dancesLeftAndRight;

			frames = Paths.getSparrowAtlas('characters/' + config.imagePath, 'shared');

			if(config.graphicsSize != null)
				setGraphicSize(Std.int(width * config.graphicsSize));

			for(selected_animation in config.animations)
			{
				if(selected_animation.indices != null)
				{
					animation.addByIndices(
						selected_animation.name,
						selected_animation.animation_name,
						selected_animation.indices, "",
						selected_animation.fps,
						selected_animation.looped
					);
				}
				else
				{
					animation.addByPrefix(
						selected_animation.name,
						selected_animation.animation_name,
						selected_animation.fps,
						selected_animation.looped
					);
				}
			}

			if(dancesLeftAndRight)
				playAnim("danceRight");
			else
				playAnim("idle");

			if(debugMode)
				flipX = config.defaultFlipX;
		
			if(config.antialiased != null)
				antialiasing = config.antialiased;

			updateHitbox();

			if(config.positionOffset != null)
				positioningOffset = config.positionOffset;

			if(config.trail == true)
				coolTrail = new FlxTrail(this, null, config.trailLength, config.trailDelay, config.trailStalpha, config.trailDiff);

			if(config.swapDirectionSingWhenPlayer != null)
				swapLeftAndRightSingPlayer = config.swapDirectionSingWhenPlayer;
			else if(curCharacter.startsWith("bf"))
				swapLeftAndRightSingPlayer = false;
		}
		else
		{
			otherCharacters = [];

			for(characterData in config.characters)
			{
				var character:Character;

				if(!isPlayer)
					character = new Character(x, y, characterData.name, isPlayer);
				else
					character = new Boyfriend(x, y, characterData.name, isPlayer);

				if(flipX)
					characterData.positionOffset[0] = 0 - characterData.positionOffset[0];

				character.positioningOffset[0] += characterData.positionOffset[0];
				character.positioningOffset[1] += characterData.positionOffset[1];
				
				otherCharacters.push(character);
			}
		}

		if(config.barColor == null)
			config.barColor = [255,0,0];

		barColor = FlxColor.fromRGB(config.barColor[0], config.barColor[1], config.barColor[2]);

		if(config.cameraOffset != null)
		{
			if(flipX)
				config.cameraOffset[0] = 0 - config.cameraOffset[0];

			cameraOffset = config.cameraOffset;
		}

		if(config.deathCharacterName != null)
			deathCharacter = config.deathCharacterName;
		else
			deathCharacter = "bf-dead";

		if(config.healthIcon != null)
			icon = config.healthIcon;
	}

	public function loadOffsetFile(characterName:String)
	{
		animOffsets = new Map<String, Array<Dynamic>>();
		
		var offsets:Array<String>;

		#if sys
		offsets = CoolUtil.coolTextFilePolymod(Paths.txt("character data/" + characterName + "/" + "offsets"));
		#else
		offsets = CoolUtil.coolTextFile(Paths.txt("character data/" + characterName + "/" + "offsets"));
		#end

		for(x in 0...offsets.length)
		{
			var selectedOffset = offsets[x];
			var arrayOffset:Array<String>;
			arrayOffset = selectedOffset.split(" ");

			addOffset(arrayOffset[0], Std.parseInt(arrayOffset[1]), Std.parseInt(arrayOffset[2]));
		}
	}

	public function quickAnimAdd(animName:String, animPrefix:String)
	{
		animation.addByPrefix(animName, animPrefix, 24, false);
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && curCharacter != '')
		{
			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				var dadVar:Float = 4;

				if (curCharacter == 'dad')
					dadVar = 6.1;
				
				if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
				{
					dance();
					holdTimer = 0;
				}
			}

			// fix for multi character stuff lmao
			if(animation.curAnim != null)
			{
				if(animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?altAnim:String = "")
	{
		if (!debugMode && curCharacter != '')
		{
			switch (curCharacter)
			{
				default:
					// fix for multi character stuff lmao
					if(animation.curAnim != null)
					{
						if (!animation.curAnim.name.startsWith('hair'))
						{
							if(!dancesLeftAndRight)
								playAnim('idle' + altAnim);
							else
							{
								danced = !danced;
		
								if (danced)
									playAnim('danceRight' + altAnim);
								else
									playAnim('danceLeft' + altAnim);
							}
						}
					}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

		/*
		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}*/
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		if((isPlayer && offsetsFlipWhenPlayer) || (!isPlayer && offsetsFlipWhenEnemy))
			x = 0 - x;

		animOffsets.set(name, [x, y]);
	}
}