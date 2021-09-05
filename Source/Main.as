void Main()
{
}

void OntingsChanged()
{

}

void Update(float dt)
{

}

void RenderMenu()
{

}

CGameEditorPluginMapMapType@ _mapEditor;
void Render()
{
	auto app = GetApp();
	auto editor = cast<CGameCtnEditorCommon>(app.Editor);
	if (editor is null)	return;

	@_mapEditor = editor.PluginMapType;
	auto map = app.RootMap;

	if (editor !is null && _mapEditor !is null)
	{
		UI::Begin("Royal Map Tool");

		// UI::Text("picked: " + ((picked is null) ? "" : picked.DescId.GetName()));
		UI::Text("Delete All Except:");
		UI::SameLine();
		if (UI::Button("White")) AntiPurge(1);	
		UI::SameLine();
		if (UI::Button("Green")) AntiPurge(2);	
		UI::SameLine();
		if (UI::Button("Blue")) AntiPurge(3);	
		UI::SameLine();
		if (UI::Button("Red")) AntiPurge(4);	
		UI::SameLine();
		if (UI::Button("Black")) AntiPurge(5);	

		if(UI::Button("Switch To Race Type")) _mapEditor.SetMapType("TrackMania\\TM_Race");
		UI::SameLine();	
		if(UI::Button("Switch To Royal Type")) _mapEditor.SetMapType("TrackMania\\TM_Royal");
		

		UI::Text("Save As:");
		DoSaveAsButton(map.MapInfo.Path, map.MapInfo.NameForUi, "-White", "$fff");
		DoSaveAsButton(map.MapInfo.Path, map.MapInfo.NameForUi, "-Green", "$0f0");
		DoSaveAsButton(map.MapInfo.Path, map.MapInfo.NameForUi, "-Blue", "$00f");
		DoSaveAsButton(map.MapInfo.Path, map.MapInfo.NameForUi, "-Red", "$f00");
		DoSaveAsButton(map.MapInfo.Path, map.MapInfo.NameForUi, "-Black", "$000");
		
		for (int i = 0; i < map.Blocks.Length; i++)
		{
			auto thisBlock = map.Blocks[i];

			string name = thisBlock.DescId.GetName();

			if (name.Contains("Start") || name.Contains("Finish"))
			{
				if (thisBlock.WaypointSpecialProperty is null) continue;
				string color = GetOrderColor(thisBlock.WaypointSpecialProperty.Order);
				int3 coord = int3(thisBlock.CoordX, thisBlock.CoordY, thisBlock.CoordZ);

				// if (UI::Button("delete " + i)){
				// 	print("delete" + " (" + coord.x + ", " +coord.y + ", " +coord.z + ")");
				// 	deletedBlockCoord = coord;
				// 	deletedBlock = true;
				// }

				UI::Text(color + " : " + thisBlock.DescId.GetName() + " (" + coord.x + ", " +coord.y + ", " +coord.z + ")" );
				
			}
		}

		UI::End();
	}


}

void DoSaveAsButton( const string&in path,const string&in name, const string&in color, const string&in colorCode){
	UI::SameLine();
	if(UI::Button(color)){
		_mapEditor.SaveMap(path + name + colorCode + color);
	}
}

void AntiPurge(int colorId)
{
	auto app = GetApp();
	auto common = cast<CGameCtnEditorCommon>(app.Editor);
	auto editor = common.PluginMapType;
	auto map = app.RootMap;

	int c = 0;
	array<int3> coords();

	for (int i = 0; i < map.Blocks.Length; i++)
	{

		auto thisBlock = map.Blocks[i];
		string name = thisBlock.DescId.GetName();

		if (thisBlock.WaypointSpecialProperty !is null && (name.Contains("Start") || name.Contains("Finish")))
		{
			if(thisBlock.WaypointSpecialProperty.Order != colorId){
				int3 coord = int3(thisBlock.CoordX, thisBlock.CoordY, thisBlock.CoordZ);
				coords.InsertLast(coord);
				c++;
			}
		}
	}

	for (int i = 0; i < c; i++)
	{
		bool res = editor.RemoveBlock(coords[i]);
		print(res + " removed: " + "(" + coords[i].x + ", " + coords[i].y + ", " +coords[i].z + ")");
		if(!res){
			// common.OrbitalCameraControl.m_TargetedPosition = vec3(float(coords[i].x)*32, float(coords[i].y)*8,float(coords[i].z)*32);
		}
	}
}

string GetOrderColor(int order)
{
	switch (order)
	{
		case 1: return "White";
		case 2: return "Green";
		case 3: return "Blue";
		case 4: return "Red";
		case 5: return "Black";
		default: break;
	}
	return "";
}