#define CLIENT_ONLY

void onStateChange(CRules@ this, const u8 oldState)
{
	if (this.isGameOver() && this.getTeamWon() >= 0)
	{
		// only play for winners
		CPlayer@ localplayer = getLocalPlayer();
		if (localplayer !is null)
		{
			CBlob@ playerBlob = getLocalPlayerBlob();
			int teamNum = playerBlob !is null ? playerBlob.getTeamNum() : localplayer.getTeamNum() ; // bug fix (cause in singelplayer player team is 255)
			
			bool murderers_left = false;
			bool innocents_left = false;

			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p is null || p.getBlob() is null) continue;

				CBlob@ b = p.getBlob();
				if (b.get_u8("role") == 2) murderers_left = true;
				else innocents_left = true;
			}
			
			u8 mr = this.get_u8("my_role");
			if ((mr < 2 && innocents_left)
				|| (mr == 2 && !innocents_left))
			{
				Sound::Play("MatchWin.ogg");
			}
            else if ((mr < 2 && !innocents_left)
				|| (mr == 2 && innocents_left))
                Sound::Play("MatchLose.ogg");
		}
	}
}
