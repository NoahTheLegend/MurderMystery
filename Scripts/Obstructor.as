// Obstructor.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";
#include "Hitters.as";
#include "RayCasts.as";

const u8 BURNOUT_COUNTER_MAX = 32;
const u8 BURNOUT_TIME_STEP = 8;

class Obstructor : Component
{
	u16 id;

	Obstructor(Vec2f position, u16 _id)
	{
		x = position.x;
		y = position.y;

		id = _id;
	}

	void Activate(CBlob@ this)
	{
		if (inProximity(getLocalPlayerBlob(), this))
		{
			this.getSprite().PlaySound("door_close.ogg");
		}

		if (getNet().isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
		}
	}

	void Deactivate(CBlob@ this)
	{
		this.Untag("obstructed");

		CMap@ map = getMap();
		if (map !is null)
		{
			this.getSprite().SetEmitSoundPaused(true);

			if (map.getTile(this.getPosition()).type == Dummy::OBSTRUCTOR)
			{
				if (inProximity(getLocalPlayerBlob(), this))
					this.getSprite().PlaySound("door_close.ogg");
			}

			if (getNet().isServer())
			{
				map.server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR_BACKGROUND);
			}
		}
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// used by BlobPlacement.as
	this.Tag("place norotate");

	// used by KnightLogic.as
	this.Tag("ignore sword");

	// used by DummyOnStatic.as
	this.set_TileType(Dummy::TILE, Dummy::OBSTRUCTOR_BACKGROUND);

	this.getCurrentScript().tickIfTag = "obstructed";
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f POSITION = this.getPosition() / 8;

	Obstructor component(POSITION, this.getNetworkID());
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_CARDINAL,                      // input topology
		TOPO_CARDINAL,                      // output topology
		INFO_LOAD,                          // information
		0,                                  // power
		component.id);                      // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetZ(-50);
		sprite.SetFacingLeft(false);
	}
}

void onTick(CBlob@ this)
{
	const u32 TIME = getGameTime();
	if (this.get_u32("burnout_time") + BURNOUT_TIME_STEP > TIME)
	{
		if (getNet().isServer())
		{
			getMap().server_SetTile(this.getPosition(), Dummy::OBSTRUCTOR);
		}

		CSprite@ sprite = this.getSprite();
		if (sprite !is null && inProximity(getLocalPlayerBlob(), this))
		{
			sprite.PlaySound("door_close.ogg");
		}
	}
}

bool isObstructed(CBlob@ this)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}