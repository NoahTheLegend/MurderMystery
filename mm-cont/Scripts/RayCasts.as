
bool inProximity(CBlob@ blob, CBlob@ blob1)
{
    return
        (getMap().rayCastSolidNoBlobs(blob.getPosition(), blob1.getPosition())
        || getMap().rayCastSolidNoBlobs(blob.getPosition() - Vec2f(0,8), blob1.getPosition() - Vec2f(0,8)));
}