//archer HUD

#include "ArcherCommon.as";
#include "ActorHUDStartPos.as";

const string iconsFilename = "Entities/Characters/Archer/ArcherIcons.png";
const int slotsSize = 6;

void onInit(CSprite@ this)
{
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
	GUI::SetFont("menu");
	CBlob@ blob = this.getBlob();

	u8 role_num = blob.get_u8("role");
	string prefix = "YOU ARE";
	string role = roles[role_num];
	SColor col = roles_color[role_num];
	
	CBlob@ local = getLocalPlayerBlob();
	if (blob.getPlayer() is null && local is null)
	{
		Vec2f charname_pos = getDriver().getScreenPosFromWorldPos(blob.getPosition())+Vec2f(0, Maths::Sin(blob.getTickSinceCreated() * 0.075f) * 5.0f);
		GUI::DrawTextCentered(blob.getInventoryName(), charname_pos - Vec2f(0, 24), SColor(155,255,255,255));
	}

	if (blob.hasTag("dead")) return;
	if (local !is null && getGameTime() > intro_time+30)
	{
		u8 local_role_num = local.get_u8("role");
		f32 dist = getDriver().getScreenHeight()/2 * 0.9f;

		if (local_role_num == 2)
		{
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p is null) continue;
				
				CBlob@ pb = p.getBlob();
				if (pb is null || pb is local) continue;
				
				Vec2f pb_pos = pb.getPosition();
				Vec2f pb_pos2d = getDriver().getScreenPosFromWorldPos(pb_pos);

				Vec2f vec = pb_pos - local.getPosition();
				vec.Normalize();
				vec *= getCamera().targetDistance;
				
				Vec2f dim = Vec2f(8,8) * getCamera().targetDistance;;
				Vec2f sq_pos = getDriver().getScreenPosFromWorldPos(local.getPosition()) + vec * Maths::Min((pb_pos-local.getPosition()).Length(), dist);

				Vec2f sq_tl = sq_pos - dim/2;
				Vec2f sq_br = sq_tl + dim;

				f32 factor = pb.getDistanceTo(local) / 256.0f;
				u8 alpha = Maths::Min(100, (100 * factor * 0.1f));
				if (alpha <= 10) alpha = 0;

				GUI::DrawRectangle(sq_tl, sq_br, pb.get_u8("role") != 2 ? SColor(alpha,255,25,55) : SColor(alpha,25,255,25));
			}

			if (role_num == 2 && local !is blob)
			{
				Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(blob.getOldPosition(), blob.getPosition(), getInterpolationFactor())) - Vec2f(0,48);
				f32 len = (local.getAimPos() - blob.getPosition()).Length();
				if (len < max_len)
				{
					f32 team_alpha = 255 * (1.0f - len/max_len);
					GUI::DrawTextCentered("MURDERER", pos2d, SColor(team_alpha,225,25,25));
				}
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

	if (getGameTime() < intro_time && blob.isMyPlayer() && !blob.hasTag("intro_launched"))
	{
		SetScreenFlash(255,0,0,0,intro_time/30.0f + 1);
		blob.Tag("intro_launched");
	}

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
