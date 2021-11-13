package states;

import flixel.FlxObject;
import flixel.FlxG;
import utilities.CoolUtil;
import flixel.group.FlxGroup;
import flixel.FlxSprite;

using StringTools;

class FreeplayChooser extends MusicBeatState
{
    private var bg:FlxSprite;
    private var sectionGroup:FlxTypedGroup<FreeplaySection>;
    private var camFollow:FlxObject;

    private static var selected:Int = 0;
    private var sections:Array<String> = [];

    private var grid_Width:Int = 2; // constant gamer D)

    override function create()
    {
        var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

        FlxG.camera.scroll.set();
		FlxG.camera.target = null;
        
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFF379ED9;
        bg.scrollFactor.set();
		add(bg);

        sectionGroup = new FlxTypedGroup<FreeplaySection>();

        for(i in 0...initSonglist.length)
        {
            // Creates an array of their strings
			var listArray = initSonglist[i].split(":");

            var coolSection = listArray[5];

            if(coolSection == null)
                coolSection = "main";

            if(!sections.contains(coolSection))
                sections.push(coolSection);
        }

        for(i in 0...sections.length)
        {
            var section:String = sections[i];

            var column:Int = i % grid_Width;
            var row:Int = Std.int(i / grid_Width);

            var section_Sprite = new FreeplaySection(250 + (column * 450), 50 + (row * 450), section.toLowerCase());
            section_Sprite.ID = i;

            section_Sprite.loadGraphic(Paths.image("freeplay menu/sections/" + section.toLowerCase(), "preload"));
            section_Sprite.setGraphicSize(400, 400);

            section_Sprite.updateHitbox();

            section_Sprite.setPosition(250 + (column * 450), 50 + (row * 450));

            sectionGroup.add(section_Sprite);
        }

        camFollow = new FlxObject(sectionGroup.members[selected].getGraphicMidpoint().x - 150, sectionGroup.members[selected].getGraphicMidpoint().y - 200, 1, 1);
        add(camFollow);

        for(sprite in sectionGroup.members)
        {
            if(sprite.ID == selected)
                sprite.alpha = 1;
            else
                sprite.alpha = 0.5;
        }

        add(sectionGroup);

        FlxG.camera.follow(camFollow, LOCKON, 0.1 * (60 / Main.display.currentFPS));

        super.create();
    }

    override function update(elapsed:Float)
    {
        if(controls.BACK)
            FlxG.switchState(new MainMenuState());

        var down = controls.DOWN_P;
        var up = controls.UP_P;
        var left = controls.LEFT_P;
        var right = controls.RIGHT_P;

        if(left || down || up || right)
        {
            if(left)
                selected -= 1;
            if(right)
                selected += 1;

            if(down)
                selected += grid_Width;
            if(up)
                selected -= grid_Width;

            if(selected < 0)
                selected = sections.length - 1;
            if(selected > sections.length - 1)
                selected = 0;

            for(sprite in sectionGroup.members)
            {
                if(sprite.ID == selected)
                    sprite.alpha = 1;
                else
                    sprite.alpha = 0.5;
            }

            camFollow.setPosition(sectionGroup.members[selected].getGraphicMidpoint().x - 150, sectionGroup.members[selected].getGraphicMidpoint().y - 200);

            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        }

        if(controls.ACCEPT)
            FlxG.switchState(new FreeplayState(sections[selected].toLowerCase()));

        FlxG.camera.followLerp = 0.1 * (60 / Main.display.currentFPS);

        super.update(elapsed);
    }
}

class FreeplaySection extends FlxSprite
{
    var section:String = "main";

    public function new(x:Float, y:Float, ?section:String = "main")
    {
        super(x,y);
    }
}