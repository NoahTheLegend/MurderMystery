#define CLIENT_ONLY

#include "RunnerCommon.as"
#include "RayCasts.as"

void onInit(CSprite@ this)
{
	// this.getCurrentScript().runFlags |= Script::tick_onground;
	this.getCurrentScript().runFlags |= Script::tick_not_inwater;
	this.getCurrentScript().runFlags |= Script::tick_moving;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);

	if (
		(blob.isOnGround() && (left || right)) ||
		(blob.isOnLadder() && (left || right || up || down))
	) {
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		if ((blob.getNetworkID() + getGameTime()) % (moveVars.walkFactor < 1.0f ? 14 : 8) == 0)
		{
			CBlob@ local = getLocalPlayerBlob();
			if (local is null || local is blob || !inProximity(local, blob))
			{
				f32 volume = 0.1f;
				TileType tile = blob.getMap().getTile(blob.getPosition() + Vec2f(0.0f, blob.getRadius() + 4.0f)).type;

				if (blob.getMap().isTileGroundStuff(tile))
				{
					this.PlayRandomSound("/EarthStep", volume);
				}
				else if (blob.isOnLadder())
				{
					f32 pitch = 0.75f + XORRandom(10) / 20.0f; //0.75f - 1.25f
					this.PlaySound("/WoodHeavyBump1", volume, pitch);
				}
				else
				{
					this.PlayRandomSound("/StoneStep", volume);
				}
			}
		}
	}
}