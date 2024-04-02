
/*
 * Auto balance teams inside a RulesCore
 * 		does a conservative job to avoid pissing off players
 * 		and to avoid forcing many implementation limitations
 * 		onto rulescore extensions so it can be used out of
 * 		the box for most gamemodes.
 */

#include "PlayerInfo.as";
#include "BaseTeamInfo.as";
#include "RulesCore.as";

#define SERVER_ONLY

const int TEAM_DIFFERENCE_THRESHOLD = 1; //max allowed diff

//TODO: store this in rules
enum BalanceType
{
	NOTHING = 0,
	SWAP_BALANCE,
	SCRAMBLE,
	SCORE_SORT,
	KILLS_SORT
};

/**
 * BalanceInfo class
 * simply holds the last time we balanced someone, so we
 * don't make some poor guy angry if he's always balanced
 *
 * we reset this time when you swap team, so that if you
 * imbalance the game, you can be swapped back swiftly
 */

class BalanceInfo
{
	string username;
	s32 lastBalancedTime;

	BalanceInfo() { /*dont use this manually*/ }

	BalanceInfo(string _username)
	{
		username = _username;
		lastBalancedTime = getGameTime();
	}
};

/*
 * Methods on a global array of balance infos to make the
 * actual hooks much cleaner.
 */

// add a balance info from username
void addBalanceInfo(string username, BalanceInfo[]@ infos)
{
	//check if it's already added
	BalanceInfo@ b = getBalanceInfo(username, infos);
	if (b is null)
		infos.push_back(BalanceInfo(username));
	else
		b.lastBalancedTime = getGameTime();
}

// get a balanceinfo from a username
BalanceInfo@ getBalanceInfo(string username, BalanceInfo[]@ infos)
{
	for (uint i = 0; i < infos.length; i++)
	{
		BalanceInfo@ b = infos[i];
		if (b.username == username)
			return b;
	}
	return null;
}

// remove a balanceinfo by username
void removeBalanceInfo(string username, BalanceInfo[]@ infos)
{
	for (uint i = 0; i < infos.length; i++)
	{
		if (infos[i].username == username)
		{
			infos.erase(i);
			return;
		}
	}
}

// get the earliest balance time
s32 getEarliestBalance(BalanceInfo[]@ infos)
{
	return 1;
}

s32 getAverageBalance(BalanceInfo[]@ infos)
{
	return 1;
}

u8[] shuffleArray(u8[] arr) {
    uint length = arr.length();
    for (uint i = length - 1; i > 0; i--) {
        uint j = XORRandom(i + 1);
        uint temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }

	return arr;
}

// force balance all teams

void BalanceAll(CRules@ this, RulesCore@ core, BalanceInfo[]@ infos, int type = SCRAMBLE)
{
	int numTeams = this.getTeamsCount();
	int team = 1;

	u8[] roles = {2,1};
	for (u8 i = roles.size(); i < getPlayersCount(); i++)
	{
		roles.push_back(0);
	}
	u8[] roles_to_pick = shuffleArray(roles);

	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null) continue;

		if (p.getTeamNum() != this.getSpectatorTeamNum())
		{
			core.ChangePlayerTeam(p, 1);
			p.set_u8("role", roles_to_pick[i]);
		}
	}
}

///////////////////////////////////////////////////
//pass stuff to the core from each of the hooks

bool haveRestarted = false;

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	this.set_bool("managed teams", true); //core shouldn't try to manage the teams

	//set this here, we need to wait
	//for the other rules script to set up the core

	BalanceInfo[]@ infos;
	if (!this.get("autobalance infos", @infos) || infos is null)
	{
		BuildBalanceArray(this);
	}

	haveRestarted = true;
}

/*
 * build the balance array and store it inside the rules so it can persist
 */

void BuildBalanceArray(CRules@ this)
{
	BalanceInfo[] temp;

	for (int player_step = 0; player_step < getPlayersCount(); ++player_step)
	{
		addBalanceInfo(getPlayer(player_step).getUsername(), temp);
	}

	this.set("autobalance infos", temp);
}

/*
 * Add a player to the balance list and set its team number
 */

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
	this.get("core", @core);

	core.ChangePlayerTeam(player, 1);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	BalanceInfo[]@ infos;
	this.get("autobalance infos", @infos);

	if (infos is null) return;

	removeBalanceInfo(player.getUsername(), infos);
}

void onTick(CRules@ this)
{
	if (haveRestarted || (getGameTime() % 1800 == 0))
	{
		//get the core and balance infos
		RulesCore@ core;
		this.get("core", @core);

		BalanceInfo[]@ infos;
		this.get("autobalance infos", @infos);

		if (core is null || infos is null) return;

		if (haveRestarted) //balance all on start
		{
			haveRestarted = false;
			//force all teams balanced
			int type = SCRAMBLE;

			BalanceAll(this, core, infos, type);
		}

		if (getTeamDifference(core.teams) > TEAM_DIFFERENCE_THRESHOLD)
		{
			getNet().server_SendMsg("Teams are way imbalanced due to players leaving...");
		}
	}

}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;

	core.ChangePlayerTeam(player, 1);
}