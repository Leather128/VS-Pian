package states;

#if discord_rpc
import utilities.Discord.DiscordClient;
#end

import lime.app.Application;
import flixel.util.FlxTimer;
import game.Song;
import game.Highscore;
import utilities.CoolUtil;
import ui.HealthIcon;
import ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	static var curSelected:Int = 0;
	static var curDifficulty:Int = 1;
	static var curSpeed:Float = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var speedText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var songsReady:Bool = false;

	public static var coolColors:Array<Int> = [0xFF7F1833, 0xFF7C689E, -14535868, 0xFFA8E060, 0xFFFF87FF, 0xFF8EE8FF, 0xFFFF8CCD, 0xFFFF9900];
	private var bg:FlxSprite;
	private var selectedColor:Int = 0xFF7F1833;
	private var interpolation:Float = 0.0;
	private var scoreBG:FlxSprite;

	private var curRank:String = "N/A";

	private var curDiffString:String = "normal";
	private var curDiffArray:Array<String> = ["easy", "normal", "hard"];

	public function new(?_section:String = "main") { this.section = _section; super(); }

	private var section:String = "main";

	override function create()
	{
		Application.current.window.title = Application.current.meta.get('name');
		
		var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		#if NO_PRELOAD_ALL
		if(!songsReady)
		{
			Assets.loadLibrary("songs").onComplete(function (_) {
				FlxTween.tween(black, {alpha: 0}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						remove(black);
						black.kill();
						black.destroy();
					}
				});
	
				songsReady = true;
			});
		}
		#else
		songsReady = true;
		#end

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		// Loops through all songs in freeplaySonglist.txt
		for (i in 0...initSonglist.length)
		{
			// Creates an array of their strings
			var listArray = initSonglist[i].split(":");

			// Variables I like yes mmmm tasty
			var week = Std.parseInt(listArray[2]);
			var icon = listArray[1];
			var song = listArray[0];
			
			var diffsStr = listArray[3];
			var diffs = ["easy", "normal", "hard"];

			var color = listArray[4];
			var actualColor:Null<FlxColor> = null;

			var songSection = listArray[5];

			if(color != null)
				actualColor = FlxColor.fromString(color);

			if(diffsStr != null)
				diffs = diffsStr.split(",");

			// Creates new song data accordingly
			if(section.toLowerCase() == songSection.toLowerCase())
				songs.push(new SongMetadata(song, week, icon, diffs, actualColor));
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		scoreText = new FlxText(FlxG.width, 5, 0, "", 32);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		diffText = new FlxText(scoreText.x + 100, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.alignment = CENTER;
		add(diffText);

		speedText = new FlxText(scoreText.x + 50, diffText.y + 36, 0, "", 24);
		speedText.font = scoreText.font;
		speedText.alignment = CENTER;
		add(speedText);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
		}

		changeSelection();
		changeDiff();

		selector = new FlxText();

		selector.size = 40;
		selector.text = "<";

		if(!songsReady)
		{
			add(black);
		} else {
			remove(black);
			black.kill();
			black.destroy();
		}

		selectedColor = songs[curSelected].color;
		bg.color = selectedColor;

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;

		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		bg.color = FlxColor.interpolate(bg.color, selectedColor, interpolation);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreBG.x = scoreText.x - 6;

		if(Std.int(scoreBG.width) != Std.int(scoreText.width + 6))
			scoreBG.makeGraphic(Std.int(scoreText.width + 6), 102, FlxColor.BLACK);

		scoreText.x = FlxG.width - scoreText.width;
		scoreText.text = "PERSONAL BEST:" + lerpScore;

		diffText.x = scoreText.x + (scoreText.width / 2) - (diffText.width / 2);

		curSpeed = FlxMath.roundDecimal(curSpeed, 2);

		if(curSpeed < 0.5)
			curSpeed = 0.5;

		speedText.text = "Speed: " + curSpeed + " (R)";
		speedText.x = scoreText.x + (scoreText.width / 2) - (speedText.width / 2);

		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var shift = FlxG.keys.pressed.SHIFT;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if(songsReady)
		{
			if (upP)
			{
				changeSelection(-1);
			}
			if (downP)
			{
				changeSelection(1);
			}
	
			if (leftP && !shift)
				changeDiff(-1);
			else if (leftP && shift)
				curSpeed -= 0.05;

			if (rightP && !shift)
				changeDiff(1);
			else if (rightP && shift)
				curSpeed += 0.05;

			if(FlxG.keys.justPressed.R)
				curSpeed = 1;
	
			if (controls.BACK)
				FlxG.switchState(new FreeplayChooser());

			if (accepted)
			{
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDiffString);
	
				trace(poop);
	
				if(Assets.exists(Paths.json("song data/" + songs[curSelected].songName.toLowerCase() + "/" + poop, "preload")))
				{
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;
					PlayState.songMultiplier = curSpeed;
					PlayState.storyDifficultyStr = curDiffString.toUpperCase();
		
					PlayState.storyWeek = songs[curSelected].week;
					trace('CUR WEEK' + PlayState.storyWeek);
					LoadingState.loadAndSwitchState(new PlayState(section.toLowerCase()));
				}
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = curDiffArray.length - 1;

		if (curDifficulty > curDiffArray.length - 1)
			curDifficulty = 0;

		curDiffString = curDiffArray[curDifficulty].toUpperCase();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDiffString);
		#end

		diffText.text = "< " + curDiffString + " - " + curRank + " >";
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// Sounds

		// Scroll Sound
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		// Song Inst
		if(FlxG.save.data.freeplayMusic)
		{
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName));
			FlxG.sound.music.fadeIn(1, 0, 0.7);
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDiffString);
		#end

		curDiffArray = songs[curSelected].difficulties;

		changeDiff();

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		interpolation = 0.0;
		selectedColor = songs[curSelected].color;

		for(i in 0...100)
		{
			new FlxTimer().start(i / 100, function(t:FlxTimer){
				interpolation += 0.01;
			});
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var difficulties:Array<String> = ["easy", "normal", "hard"];
	public var color:FlxColor = FlxColor.GREEN;

	public function new(song:String, week:Int, songCharacter:String, ?difficulties:Array<String>, ?color:FlxColor)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;

		if(difficulties != null)
			this.difficulties = difficulties;

		if(color != null)
			this.color = color;
		else
		{
			if(FreeplayState.coolColors.length - 1 >= this.week)
				this.color = FreeplayState.coolColors[this.week];
			else
				this.color = FreeplayState.coolColors[0];
		}
	}
}
