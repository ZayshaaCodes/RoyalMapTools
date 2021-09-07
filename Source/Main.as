bool _isMapEditorActive = false;

CGameCtnEditorCommon@ _editor;
CGameEditorPluginMapMapType@ _mapEditor;
CGameCtnChallenge@ _map;

bool windowsVisible = true;

const float pi = 3.141592656f;

void Main()
{

}

void OnSettingsChanged()
{
}

float t= 0;
void Update(float dt)
{	
}

void RenderMenu()
{
if (UI::MenuItem("\\$2f9" + Icons::PuzzlePiece + "\\$fff Royal Editor Helpers", selected: windowsVisible, enabled: GetApp().Editor !is null))
    {
        windowsVisible = !windowsVisible;
    }
}

void Render()
{
	auto app = GetApp();
	@_editor = cast<CGameCtnEditorCommon>(app.Editor);
	if (_editor is null) return;
	@_mapEditor = _editor.PluginMapType;
	@_map = app.RootMap;

	auto pg = app.CurrentPlayground;

	_isMapEditorActive = !(_editor is null || _mapEditor is null || pg !is null);	
	if(!_isMapEditorActive) return;

	if(!windowsVisible) return;

	Render2();
	//RenderMem();
}


void RenderMem()
{
	auto app = GetApp();

	UI::Begin("mem",windowsVisible);
	
	UI::Text( Text::FormatPointer( Dev::BaseAddress()));

	auto editorType = Reflection::TypeOf(_editor);

	auto pickedBlockMemberInfo = editorType.GetMember("PickedBlock");	
	auto offset = pickedBlockMemberInfo.Offset;
	auto block = _editor.PickedBlock;	

	if (block !is null)
	{
		nat3 coord = block.Coord;
		auto blockPtr = Dev::GetOffsetUint64(_editor,offset);
		auto pos = Dev::ReadVec3(blockPtr+0x6c);
		auto rot = Dev::ReadVec3(blockPtr+0x78) / pi * 180;
		auto isFree = Dev::ReadInt32(blockPtr+0x64) == 0;
		UI::InputText("PickedBlock Ptr", Text::FormatPointer(Dev::GetOffsetInt64(_editor,offset)));
		if (!isFree)
		{
			UI::Text("Coord: (" + coord.x + ", " + coord.y + ", " + coord.z + ")");
		} else {
			UI::Text("Position: (" + pos.x + ", " + pos.y + ", " + pos.z + ")");
			UI::Text("Rotation: (" + rot.x + ", " + rot.y + ", " + rot.z + ")");	
		}
		
	}
	
	UI::End();
}

void Render2()
{
	UI::Begin("Royal Map Tool", windowsVisible);

	UI::Text("Set Map Type:");
	UI::SameLine();	
	if(UI::Button("Race")) _mapEditor.SetMapType("TrackMania\\TM_Race");
	UI::SameLine();	
	if(UI::Button("Royal")) _mapEditor.SetMapType("TrackMania\\TM_Royal");
	
	// UI::Text("picked: " + ((picked is null) ? "" : picked.DescId.GetName()));
	UI::Text("Delete All Except:");
	UI::SameLine();

	UI::PushID("WhitePurge");
	if (UI::Button("White")) AntiPurge(1);	
	UI::SameLine();
	UI::PopID();

	UI::PushID("GreenPurge");
	if (UI::Button("Green")) AntiPurge(2);	
	UI::SameLine();
	UI::PopID();

	UI::PushID("BluePurge");
	if (UI::Button("Blue")) AntiPurge(3);	
	UI::SameLine();
	UI::PopID();

	UI::PushID("RedPurge");
	if (UI::Button("Red")) AntiPurge(4);	
	UI::SameLine();
	UI::PopID();

	UI::PushID("BlackPurge");
	if (UI::Button("Black")) AntiPurge(5);	
	UI::PopID();


	UI::Text("Save As:");
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "White", "$fff");
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Green", "$0f0");
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Blue", "$00f");
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Red", "$f00");
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Black", "$000");

	UI::Text("Block List: (* = free block)");

	DrawBlockList();

	UI::End();
}

string _searchText = "";
bool showGoals = true;
bool showSpawns = true;

void DrawBlockList()
{
	auto app = GetApp();
	
	auto appType = Reflection::TypeOf(app);
	auto editorType = Reflection::TypeOf(_editor);
	auto mapType = Reflection::TypeOf(_map);

	auto mapMemberInfo = appType.GetMember("RootMap");
	auto blocksArrayMemberInfo = mapType.GetMember("Blocks");
	
	auto blocksPtr = Dev::GetOffsetUint64(_map,blocksArrayMemberInfo.Offset);
	auto mapPtr = Dev::GetOffsetUint64(app,mapMemberInfo.Offset);

	// UI::InputText("Map Ptr", Text::FormatPointer(mapPtr));
	// UI::InputText("Blocks Ptr", Text::FormatPointer( blocksPtr));
	// UI::InputText("Blocks Arr Offset", Text::FormatPointer(blocksArrayMemberInfo.Offset));
	
	uint blockcount =  Dev::GetOffsetUint32(_map, blocksArrayMemberInfo.Offset + 8);
	// UI::Text( "Block Count = " + blockcount);

	showGoals = UI::Checkbox("Show Goals", showGoals);
	UI::SameLine();
	showSpawns = UI::Checkbox("Show Spawns", showSpawns);

	if (UI::Button("x"))
	{
		_searchText = "";
	} 
	UI::SameLine();
	_searchText = UI::InputText("Search", _searchText);

	auto blocks = Dev::GetOffsetNod(_map,blocksArrayMemberInfo.Offset);
	// for (size_t i = 0; i < blockcount; i++)
	for (int i = 0 ; i < blockcount; i++)
	{
		auto blockNod = _map.Blocks[i]; 

		bool needsTag = showGoals || showSpawns;
		string tag = "";
		if (needsTag && blockNod.WaypointSpecialProperty !is null) 
		{
			tag = blockNod.WaypointSpecialProperty.Tag;
		}
		auto descName = blockNod.DescId.GetName();

		bool isGoal = tag == "Goal";
		bool isSpawn = tag == "Spawn";
		auto slow = _searchText.ToLower().Trim();
		bool matchSearch = slow != "" && descName.ToLower().Contains(slow);
		if(!((isGoal && showGoals) || (isSpawn && showSpawns) || matchSearch)) continue;

		uint64 b1Addr = Dev::GetOffsetUint64(blocks,i * 0x8);	
		auto pos = Dev::ReadVec3(b1Addr+0x6c);
		auto rot = Dev::ReadVec3(b1Addr+0x78) / pi * 180;	
		auto isFree = Dev::ReadInt8(b1Addr+0x50) == 0;
		if (isFree)
		{		
			UI::PushID("Focus" + i);
			if (UI::Button("Focus"))
			{
				auto diff = pos - _editor.OrbitalCameraControl.m_TargetedPosition;
				_editor.OrbitalCameraControl.m_TargetedPosition += diff;
				_editor.OrbitalCameraControl.Pos += diff;
			}	
			UI::PopID();
			UI::SameLine();
			if (blockNod.WaypointSpecialProperty !is null)
			{
				int order = blockNod.WaypointSpecialProperty.Order;
				UI::PushStyleColor(UI::Col::Text, GetOrderColor(order));
				UI::Text("[" + GetOrderColorString(order) + "]");
				UI::PopStyleColor();
				UI::SameLine();
			}
			UI::Text( "*" + blockNod.DescId.GetName()
				+ " pos:(" + pos.x + ", " + pos.y + ", " + pos.z + ")"
				+ " rot:(" + rot.x + ", " + rot.y + ", " + rot.z + ")");
		} else 
		{
			UI::PushID("Focus" + i);
			if (UI::Button("Focus"))
			{
				auto worldPos = vec3(blockNod.Coord.x * 32, (blockNod.Coord.y - 8) * 8, blockNod.Coord.z * 32);
				auto diff = worldPos - _editor.OrbitalCameraControl.m_TargetedPosition;
				_editor.OrbitalCameraControl.m_TargetedPosition += diff;
				_editor.OrbitalCameraControl.Pos += diff;
			}	
			UI::PopID();
			UI::SameLine();
			if (blockNod.WaypointSpecialProperty !is null)
			{
				int order = blockNod.WaypointSpecialProperty.Order;
				UI::PushStyleColor(UI::Col::Text, GetOrderColor(order));
				UI::Text("[" + GetOrderColorString(order) + "]");
				UI::PopStyleColor();
				UI::SameLine();
			}
			UI::Text( " " + blockNod.DescId.GetName() 
				+ " Coord:(" + blockNod.Coord.x + ", " + blockNod.Coord.y + ", " + blockNod.Coord.z + ")"
				+ " Dir: " + blockNod.BlockDir);
			
		}
		
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

	int c = 0;
	array<int3> coords();

	for (int i = 0; i < _map.Blocks.Length; i++)
	{

		auto thisBlock = _map.Blocks[i];
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
		bool res = _mapEditor.RemoveBlock(coords[i]);
		print(res + " removed: " + "(" + coords[i].x + ", " + coords[i].y + ", " +coords[i].z + ")");
		if(!res){
			// common.OrbitalCameraControl.m_TargetedPosition = vec3(float(coords[i].x)*32, float(coords[i].y)*8,float(coords[i].z)*32);
		}
	}
}

string GetOrderColorString(int order)
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

vec4 GetOrderColor(int order)
{
	switch (order)
	{
		case 1: return vec4(1,1,1,1);
		case 2: return vec4(0,1,0,1);
		case 3: return vec4(0,0,1,1);
		case 4: return vec4(1,0,0,1);
		case 5: return vec4(.5f,.5f,.5f,1);
		default: return vec4(1,1,1,1);
	}
	return vec4(1,1,1,1);
}