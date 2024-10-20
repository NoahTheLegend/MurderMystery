#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"

void onInit(CRules@ this)
{
	string t = CFileMatcher("WesternBangBang-Regular.ttf").getFirst();
	GUI::LoadFont("title", t, 74, true);
	
	string ts = CFileMatcher("WesternBangBang-RegularSmall.ttf").getFirst();
	GUI::LoadFont("title-small", ts, 32, true);

	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	if (isServer())
	{
		getSecurity().reloadSecurity();
	}

	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;
	s_effects = false;

	sv_max_localplayers = 1;
	PrecacheTextures();

	//smooth shader

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24,2.0f,32);

	//also restart stuff
	onRestart(this);
}

bool enabled_shaders = false;
void onRender(CRules@ this)
{
	if (!isClient()) return;

	if (!enabled_shaders && getLocalPlayer() !is null)
	{
		Driver@ driver = getDriver();
		
		string path = (isServer() && isClient() ? "" : "The")+"MurderMystery";
		if (getLocalPlayer().getUsername() == "GoldenGuy")
		{
			driver.AddShader("../Mods/"+path+"/Shaders/hq2x-contrast", 1.0f);
			driver.SetShader("../Mods/"+path+"/Shaders/hq2x-contrast", true);

			enabled_shaders = true;
		}
		else
		{
			driver.AddShader("../Mods/"+path+"/Shaders/hq2x", 1.0f);
			driver.SetShader("../Mods/"+path+"/Shaders/hq2x", true);

			enabled_shaders = true;
		}

		return;
	}
	
	if (enabled_shaders)
	{
		Driver@ driver = getDriver();
		if (!driver.ShaderState())
		{
			driver.ForceStartShaders();
		}
	}
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(24.0f);
		map.SetBorderColourTop(SColor(0xff000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;
	}
}

void onTick(CRules@ this)
{	
	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;
		CMap@ map = getMap();
		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x80000000));
	}
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "dots", 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "", 0);
}
