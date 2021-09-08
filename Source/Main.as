
bool _isMapEditorActive = false;

CGameCtnEditorCommon@ _editor;
CGameEditorPluginMapMapType@ _mapEditor;
CGameCtnChallenge@ _map;

bool windowsVisible = true;

string _searchText = "";
bool _showGoals = true;
bool _showSpawns = true;
bool _showCps = false;

bool _dirty = true;

ListBlockItem@[] blockList;

const float pi = 3.141592656f;


void Main()
{
}

void OnSettingsChanged()
{
}

float _lastDt;
void Update(float dt)
{	
	_lastDt = dt;
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
	if(!windowsVisible) return;
	
	auto app = GetApp();
	@_editor = cast<CGameCtnEditorCommon>(app.Editor);
	if (_editor is null) return;
	@_mapEditor = _editor.PluginMapType;
	@_map = app.RootMap;

	auto pg = app.CurrentPlayground;

	_isMapEditorActive = !(_editor is null || _mapEditor is null || pg !is null);	
	if(!_isMapEditorActive) return;

	Render2();
	//RenderMem();
}


void RenderMem()
{
	auto app = GetApp();

	UI::Begin("mem",windowsVisible);
	
	UI::Text( Text::FormatPointer( Dev::BaseAddress()));

	@_editor = cast<CGameCtnEditorCommon>(app.Editor);
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
	SameLineAtXPosition(130);
	if(UI::Button("Race")) _mapEditor.SetMapType("TrackMania\\TM_Race");
	UI::SameLine();	
	if(UI::Button("Royal")) _mapEditor.SetMapType("TrackMania\\TM_Royal");
	
	// UI::Text("picked: " + ((picked is null) ? "" : picked.DescId.GetName()));
	UI::Text("Delete All Except:");	
	SameLineAtXPosition(130);

	UI::PushID("WhitePurge");
	if (UI::Button("White")) AntiPurge(1);	
	UI::PopID();
	UI::SameLine();

	UI::PushID("GreenPurge");
	if (UI::Button("Green")) AntiPurge(2);	
	UI::PopID();
	UI::SameLine();

	UI::PushID("BluePurge");
	if (UI::Button("Blue")) AntiPurge(3);	
	UI::PopID();
	UI::SameLine();

	UI::PushID("RedPurge");
	if (UI::Button("Red")) AntiPurge(4);	
	UI::PopID();
	UI::SameLine();

	UI::PushID("BlackPurge");
	if (UI::Button("Black")) AntiPurge(5);	
	UI::PopID();


	UI::Text("Save As:");
	SameLineAtXPosition(130);
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "White", "$fff");
	UI::SameLine();	
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Green", "$0f0");
	UI::SameLine();	
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Blue", "$00f");
	UI::SameLine();	
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Red", "$f00");
	UI::SameLine();	
	DoSaveAsButton(_map.MapInfo.Path, _map.MapInfo.NameForUi, "Black", "$000");

	auto newShowSpawns = UI::Checkbox("Show Spawns", _showSpawns);
	if (newShowSpawns != _showSpawns) {	_showSpawns = newShowSpawns; _dirty = true;	}
	UI::SameLine();
	auto newShowGoals = UI::Checkbox("Show Goals", _showGoals);
	if (newShowGoals != _showGoals){ _showGoals = newShowGoals;	_dirty = true; }
	UI::SameLine();
	auto newShowCps = UI::Checkbox("Show Checkpoints", _showCps);
	if (newShowCps != _showCps){ _showCps = newShowCps;	_dirty = true; }

	if (UI::Button("x")){
		_searchText = "";
		_dirty = true;
	}

	UI::SameLine();
	auto newSearchText = UI::InputText("Search", _searchText);
	if (newSearchText != _searchText){ _searchText = newSearchText; _dirty = true; }

	UI::Text("Block List: [Order/Color] (* = free block)");

	DrawBlockList();

	UI::End();
}

void SameLineAtXPosition(float xPosition){
	UI::SameLine();	
	auto cPos = UI::GetCursorPos();
	cPos.x = xPosition;
	UI::SetCursorPos(cPos);
}

int lastBlockCount = 0;
void UpdateBlockList(){
	
	if( _map.Blocks.Length == lastBlockCount && _dirty != true) return;
	_dirty = false;
	blockList.RemoveRange(0, blockList.Length);

	for (int i = 0 ; i < _map.Blocks.Length && blockList.Length < 100; i++)
	{
		auto curBlock = _map.Blocks[i];
		if ((_showGoals || _showSpawns || _showCps) && curBlock.WaypointSpecialProperty !is null) {
			auto tag = curBlock.WaypointSpecialProperty.Tag;
			if ( (_showGoals && tag == "Goal") || (_showSpawns && tag == "Spawn") || (_showCps && tag == "Checkpoint") ) {
				blockList.InsertLast(ListBlockItem(curBlock)); 
				continue;
			}
		}

		auto descName = curBlock.DescId.GetName();
		auto sString = _searchText.Trim().ToLower();
		if (sString != "" && descName.ToLower().Contains(sString))
		{
			blockList.InsertLast(ListBlockItem(curBlock)); 
		}
	}

	if (blockList.Length > 2)
	{
		blockList.Sort(function(a,b) 
		{ 
			return a.Order < b.Order; 
		});	
	}

	lastBlockCount = _map.Blocks.Length;
}

float timer = 0;
void DrawBlockList()
{
	auto app = GetApp();

	UpdateBlockList();

	auto cursorPos = UI::GetCursorPos();
	auto curSize = UI::GetWindowSize();

	UI::BeginChild("blockList");

	for (int i = 0 ; i < blockList.Length; i++)
	{
		auto curBlock = blockList[i].Block;

		auto isFree = Dev::GetOffsetInt8(curBlock, 0x50) == 0;

		if (isFree)
		{		
			auto pos = Dev::GetOffsetVec3(curBlock, 0x6c);
			auto rot = Dev::GetOffsetVec3(curBlock, 0x78) / pi * 180;	
			UI::PushID("Focus" + i);
			if (UI::Button("Focus"))
			{
				auto diff = pos - _editor.OrbitalCameraControl.m_TargetedPosition;
				_editor.OrbitalCameraControl.m_TargetedPosition += diff;
				_editor.OrbitalCameraControl.Pos += diff;
			}	
			UI::PopID();
			UI::SameLine();
			if (curBlock.WaypointSpecialProperty !is null && curBlock.WaypointSpecialProperty.Order != 0)
			{
				int order = curBlock.WaypointSpecialProperty.Order;
				UI::PushStyleColor(UI::Col::Text, GetOrderColor(order));
				UI::Text("[" + GetOrderColorString(order) + "]");
				UI::PopStyleColor();
				UI::SameLine();
			}
			UI::Text( "* " + curBlock.DescId.GetName()
				+ " pos:(" + pos.x + ", " + pos.y + ", " + pos.z + ")"
				+ " rot:(" + rot.x + ", " + rot.y + ", " + rot.z + ")");
		} else 
		{
			UI::PushID("Focus" + i);			
			if (UI::Button("Focus"))
			{
				auto worldPos = vec3(curBlock.Coord.x * 32, (curBlock.Coord.y - 8) * 8, curBlock.Coord.z * 32);
				auto diff = worldPos - _editor.OrbitalCameraControl.m_TargetedPosition;
				_editor.OrbitalCameraControl.m_TargetedPosition += diff;
				_editor.OrbitalCameraControl.Pos += diff;
			}	
			UI::PopID();
			UI::PushID("x" + i);
			UI::SameLine();
			bool didRemoveBlock = false;
			int3 blockCoord;
			if (UI::Button("x"))
			{
				didRemoveBlock = true;
				blockCoord = int3(curBlock.Coord.x,curBlock.Coord.y,curBlock.Coord.z);
			}	
			UI::PopID();
			UI::SameLine();
			if (curBlock.WaypointSpecialProperty !is null && curBlock.WaypointSpecialProperty.Order != 0)
			{
				int order = curBlock.WaypointSpecialProperty.Order;
				UI::PushStyleColor(UI::Col::Text, GetOrderColor(order));
				UI::Text("[" + GetOrderColorString(order) + "]");
				UI::PopStyleColor();
				UI::SameLine();
			}
			UI::Text( "  " + curBlock.DescId.GetName() 
				+ " Coord:(" + curBlock.Coord.x + ", " + curBlock.Coord.y + ", " + curBlock.Coord.z + ")"
				+ " Dir: " + curBlock.BlockDir);		

			if (didRemoveBlock)
			{
				_mapEditor.RemoveBlock(blockCoord);
			}

			if (blockList.Length == 99){
				UI::Text( "---trimmed to spare your CPU, try narrowing your search---" );
			}
		}		
	}
	UI::EndChild();
}

void DoSaveAsButton( const string&in path,const string&in name, const string&in color, const string&in colorCode){
	if(UI::Button(color)){
		_mapEditor.SaveMap(path + name + "-" + colorCode + color);
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
		_mapEditor.RemoveBlock(coords[i]);
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
	return "" + order;
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