#include "ChatCommandManager.as"
#include "DefaultChatCommands.as"
#include "RayCasts.as"

ChatCommandManager@ manager;

void onRestart(CRules@ this)
{
	if (isServer() && isClient())
	{
		onInit(this);
	}
}

void onInit(CRules@ this)
{
	this.addCommandID("SendChatMessage");
	@manager = ChatCommands::getManager();
	RegisterDefaultChatCommands(manager);
	manager.ProcessConfigCommands();
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	textOut = removeExcessSpaces(textIn);
	if (textOut == "") return false;

	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textOut, command, args))
	{
		if (!command.canPlayerExecute(player))
		{
			server_AddToChat(getTranslatedString("You are unable to use this command"), ConsoleColour::ERROR, player);
			return false;
		}

		command.Execute(args, player);
	}
	else if (command !is null)
	{
		server_AddToChat(getTranslatedString("'{COMMAND}' is not a valid command").replace("{COMMAND}", textOut), ConsoleColour::ERROR, player);
		return false;
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in textIn, string& out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textIn, command, args))
	{
		//don't run command a second time on localhost
		if (!isServer())
		{
			//assume command can be executed if server forwards it to clients
			command.Execute(args, player);
		}

		return false;
	}
	
	if (getMap() is null) return false;

	CBlob@ local = getLocalPlayerBlob();
	CBlob@ pb = player.getBlob();
	bool in_range = local !is null && pb !is null; //&& inProximity(local, pb);

	if ((pb !is null && in_range) || local is null)
	{
		bool add_to_chat = true;
		//for (u8 i = 0; i < getPlayersCount(); i++)
		//{
		//	CPlayer@ p = getPlayer(i);
		//	if (p is null || p.getBlob() is null) continue;
		//	CBlob@ b = p.getBlob();
//
		//	if (local !is null && inProximity(local, b))
		//	{
		//		add_to_chat = true;
		//		break;
		//	}
		//}

		if (add_to_chat)
		{
			if (pb !is null)
			{
				client_AddToChat("[Citizen #"+pb.getNetworkID()+"] "+textIn, SColor(255,0,0,0));
				if (inProximity(local, pb)) pb.Chat(textIn);
			}
			else
				return true;
		}
		else
		{
			client_AddToChat("No one saw your message", SColor(255,255,0,0));
		}
	}
	
	return false;
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("SendChatMessage") && isClient())
	{
		string message;
		if (!params.saferead_string(message)) return;

		u8 r, g, b, a;
		if (!params.saferead_u8(b)) return;
		if (!params.saferead_u8(g)) return;
		if (!params.saferead_u8(r)) return;
		if (!params.saferead_u8(a)) return;
		SColor color(a, r, g, b);

		client_AddToChat(message, color);
	}
}
