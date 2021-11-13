package game;

using StringTools;

class Boyfriend extends Character
{
	public var stunned:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf', ?isDeathCharacter:Bool = false)
	{
		super(x, y, char, true, isDeathCharacter);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if(curCharacter != "hellbob")
			{
				if(animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;
	
				if(animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
					playAnim('idle', true, false, 10);
	
				if(animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
					playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}
}
