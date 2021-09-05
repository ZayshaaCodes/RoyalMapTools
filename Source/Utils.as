namespace Util
{   
#if TMNEXT
    CSmPlayer@ GetViewingPlayer()
    {
        auto playground = GetApp().CurrentPlayground;
        if (playground is null || playground.GameTerminals.Length != 1) {
            return null;
        }
        return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
    }
#elif TURBO
    CGameMobil@ GetViewingPlayer()
    {
        auto playground = cast<CTrackManiaRace>(GetApp().CurrentPlayground);
        if (playground is null) {
            return null;
        }
        return playground.LocalPlayerMobil;
    }
#elif MP4
    CGamePlayer@ GetViewingPlayer()
    {
        auto playground = GetApp().CurrentPlayground;
        if (playground is null || playground.GameTerminals.Length != 1) {
            return null;
        }
        return playground.GameTerminals[0].GUIPlayer;
    }
#endif

}
