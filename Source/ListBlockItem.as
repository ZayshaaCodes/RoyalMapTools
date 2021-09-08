class ListBlockItem
{
	CGameCtnBlock@ Block;
	int Order = 1000;
	ListBlockItem(CGameCtnBlock@ blk){
		@Block = blk;
		if (blk.WaypointSpecialProperty !is null){
			Order = blk.WaypointSpecialProperty.Order;
		}
	}
}