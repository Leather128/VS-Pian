package utilities;

class MusicUtilities
{

    /**
    * This function returns the string path of the current music that should be played (as a replacement for the title screen music)
    */
    public static function GetTitleMusicPath():String
    {
        return Paths.music('freakyMenu');
    }

    /**
    * This function returns the string path of the current options menu music.
    */
    public static function GetOptionsMenuMusic():String
    {
        return Paths.music('freakyMenu');
    }
}