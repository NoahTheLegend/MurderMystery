
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

array<u16> sortPlayersByWeight(array<u16> players)
{
    array<u16> sortedPlayers = players;

    for (uint i = 0; i < sortedPlayers.length(); i++)
    {
        CPlayer@ p1 = getPlayerByNetworkId(sortedPlayers[i]);
        if (p1 is null) continue;

        for (uint j = i + 1; j < sortedPlayers.length(); j++)
        {
            CPlayer@ p2 = getPlayerByNetworkId(sortedPlayers[j]);
            if (p2 is null) continue;

            u32 weight1 = p1.get_u32("weight");
            u32 weight2 = p2.get_u32("weight");

            if (weight1 < weight2 || (weight1 == weight2 && XORRandom(100) > 50))
            {
                u16 temp = sortedPlayers[i];
                sortedPlayers[i] = sortedPlayers[j];
                sortedPlayers[j] = temp;
                @p1 = p2;
            }
        }
    }

    return sortedPlayers;
}

void BalanceAll(CRules@ this, RulesCore@ core, BalanceInfo[]@ infos, int type = SCRAMBLE)
{
    u32 count = 0;
    array<u16> players;

    for (uint i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p is null || p.getTeamNum() == this.getSpectatorTeamNum()) continue;

        players.insertLast(p.getNetworkID());
        count++;
    }

    array<u32> roles = {2, 1};
    if (count > 10)
    {
        roles.insertAt(0, 2);
        roles.insertLast(1);
    }

    for (uint i = roles.size(); i < count; i++)
    {
        roles.insertLast(0);
    }

    players = sortPlayersByWeight(players);
    u32 sum = 0;
	u8 sheriff_cost = 1; 

    for (uint i = 0; i < players.size(); i++)
    {
        CPlayer@ p = getPlayerByNetworkId(players[i]);
        if (p is null) continue;

        core.ChangePlayerTeam(p, 1);
		f32 ratio = 1;

        u32 w = Maths::Max(1, p.get_u32("weight"));
        u32 role = roles[i];
		u8 rnd = XORRandom(100);

		p.set_u8("role", role);
		p.set_u32("weight", role == 0 ? w + ratio : role == 1 ? w / sheriff_cost : 0);

        printf(p.getUsername() + " r:" + p.get_u8("role") + " w:" + p.get_u32("weight"));
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

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u32 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;

	core.ChangePlayerTeam(player, 1);
}