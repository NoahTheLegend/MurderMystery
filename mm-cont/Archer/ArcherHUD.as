//archer HUD

#include "ArcherCommon.as";
#include "ActorHUDStartPos.as";

const string iconsFilename = "Entities/Characters/Archer/ArcherIcons.png";
const int slotsSize = 6;

void onInit(CSprite@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors(CBlob@ this)
{
	if (!this.isMyPlayer()) return;
	// set cursor
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
	}
	else
	{
		// set cursor
		getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-16, -16) * cl_mouse_scale);
		// frame set in logic
	}
}

f32 alpha = 255;
const f32 max_len = 48.0f;

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	u8 role_num = blob.get_u8("role");
	string prefix = "YOU ARE";
	string role = roles[role_num];
	SColor col = roles_color[role_num];
	
	CBlob@ local = getLocalPlayerBlob();
	if (local !is null && local !is blob && getGameTime() > intro_time+30)
	{
		if (local.get_u8("role") == 2 && role_num == 2)
		{
			Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(blob.getOldPosition(), blob.getPosition(), getInterpolationFactor())) - Vec2f(0,48);
			f32 len = (local.getAimPos() - blob.getPosition()).Length();
			if (len < max_len)
			{
				GUI::SetFont("menu");
				f32 team_alpha = 255 * (1.0f - len/max_len);
				GUI::DrawTextCentered("TEAMMATE", pos2d, SColor(team_alpha,225,25,25));
			}
		}
	}

	if (!blob.isMyPlayer()) return;
	ManageCursors(blob);

	if (g_videorecording)
		return;

	CHUD@ hud = getHUD();
	if (hud is null) return;

	GUI::SetFont("title");
	alpha = Maths::Lerp(alpha, getScreenFlashAlpha(), 0.5f);
	if (getGameTime() < intro_time)
		SetScreenFlash(255,0,0,0, 1.0f);
	if (getGameTime() < intro_time+30)
	{
		Vec2f prefix_dim;
		Vec2f role_dim;

		GUI::GetTextDimensions(prefix, prefix_dim);
		GUI::GetTextDimensions(role, role_dim);

		col.setAlpha(alpha);

		Vec2f offset = getDriver().getScreenCenterPos()-Vec2f(prefix_dim.x/2 + role_dim.x/2, prefix_dim.y/2);
		GUI::DrawText(prefix, offset, SColor(alpha,255,255,255));
		GUI::DrawText(role, Vec2f(offset.x + prefix_dim.x + 20, offset.y), col);
		
		hud.HideCursor();
		getRules().chat = false;
		return;
	}
	else
	{
		alpha = 255;
		hud.ShowCursor();

		GUI::SetFont("title-small");
		GUI::DrawText(role, Vec2f(15,15), col);
		getRules().chat = true;
	}

	CPlayer@ player = blob.getPlayer();

	// draw inventory
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
	//DrawInventoryOnHUD(blob, tl);

	const u8 type = getArrowType(blob);
	u8 arrow_frame = 0;

	if (type != ArrowType::normal)
	{
		arrow_frame = type;
	}

	// draw coins
	const int coins = player !is null ? player.getCoins() : 0;
	//DrawCoinsOnHUD(blob, coins, tl, slotsSize - 2);

	// class weapon icon
	GUI::DrawIcon(iconsFilename, arrow_frame, Vec2f(16, 32), tl + Vec2f(8 + (slotsSize - 1) * 40, -16), 1.0f, blob.getTeamNum());
}
