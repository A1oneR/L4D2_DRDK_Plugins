//
//  Name: prop_physics_revert
//  Description:
//    Tankで定点オブジェクトの練習をより簡易にするためのSourceModプラグインです
//    prop_physics_save_all と prop_physics_restore_all を任意の好きなキーにbindして使ってください
//    もちろんbindしなくてもOKです
//
//    prop_physics_save_all - すべてのphysicsオブジェクトの現在位置と向きを保存します
//    prop_physics_restore_all - 保存したすべてのphysicsオブジェクトの位置と向きを復元します
//
//    physicsオブジェクトとは、物理演算が適用されたオブジェクトのことです
//    プレイヤーが動かすことが出来るすべてのオブジェクトがこれに含まれます
//    たとえばゴミ箱だったり、木材などなど
//  TODO:
//    処理がまだ重いので、プレイヤーが触ったオブジェクトの情報のみ保存するようにする
//  Changelog:
//    2011/03/14: v0.3 source code cleanup
//    2011/03/14: v0.2 first release
//
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.3"
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define PLUGIN_FILENAME "prop_physics_revert"
#define DEBUG_STRING_BUFFER_SIZE 256
#define DATA_STRUCTURE_SIZE 7

new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hDebug = INVALID_HANDLE;
new bool:g_bEnable = true;
new bool:g_bDebug = true;

//  Data Structure
//    [ entity_index, origin1, origin2, origin3, rotation1, rotation2, rotation3 ]
new Handle:g_hPropPhysicsObjectInfo = INVALID_HANDLE;

//new String:allow_objects[][256] = {
  //"models/props_vehicles/police_car_rural.mdl",
  //"models/props_vehicles/cara_82hatchback_wrecked.mdl"
  //"models/props_vehicles/cara_95sedan.mdl",
  //"models/props_vehicles/cara_69sedan.mdl",
  //"models/props_vehicles/cara_84sedan.mdl"
//};

public Plugin:myinfo = 
{
  name = "prop_physics_revert",
  author = "kimoto",
  description = "prop_physics_revert",
  version = PLUGIN_VERSION,
  url = ""
}

public OnPluginStart()
{
  CreateConVar("prop_physics_revert_version", PLUGIN_VERSION, "prop_physics_revert plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_hEnable   = CreateConVar("prop_physics_revert_enable", "1", "Enable/Disable prop_physics_revert plugin", FCVAR_PLUGIN);
  // default debug mode off
  g_hDebug    = CreateConVar("prop_physics_revert_debug", "0", "Enable/Disable prop_physics_revert debug show", FCVAR_PLUGIN);
  
  HookConVarChange(g_hEnable, OnConVarsChanged);
  HookConVarChange(g_hDebug, OnConVarsChanged);

  AutoExecConfig(true, PLUGIN_FILENAME);
  ReloadConvars();
  
  RegConsoleCmd("sm_savett", Command_PropPhysicsSaveAll);
  RegConsoleCmd("sm_restorett", Command_PropPsysicsRestoreAll);
}

public DebugPrint(const String:Message[], any:...)
{
  if (g_bDebug)
  {
    decl String:DebugBuff[DEBUG_STRING_BUFFER_SIZE];
    VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
    LogMessage(DebugBuff);
  }
}

public Action:Command_PropPhysicsSaveAll(client, args)
{
  DebugPrint("Command_PropPhysicsSaveAll");

  decl Float:data[DATA_STRUCTURE_SIZE];
  decl Float:origin[3];
  decl Float:rotation[3];

  g_hPropPhysicsObjectInfo = CreateArray(DATA_STRUCTURE_SIZE);
  DebugPrint("%d", GetArraySize(g_hPropPhysicsObjectInfo));

  new index = -1;
  decl String:modeldata[256];
  while ((index = FindEntityByClassname(index, "prop_physics")) != -1){
    // entityの座標と方向を取得する
    GetEntPropVector(index, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(index, Prop_Send, "m_angRotation", rotation);

    GetEntPropString(index, Prop_Data, "m_ModelName", modeldata, sizeof(modeldata));
    DebugPrint("%s: %f %f %f", modeldata, origin[0], origin[1], origin[2]);

    data[0] = index;
    data[1] = origin[0];
    data[2] = origin[1];
    data[3] = origin[2];
    data[4] = rotation[0];
    data[5] = rotation[1];
    data[6] = rotation[2];
    
    // 全部保存する
    PushArrayArray(g_hPropPhysicsObjectInfo, data, DATA_STRUCTURE_SIZE);
  }
  
  // 表示してみる
  new limit = GetArraySize(g_hPropPhysicsObjectInfo);
  DebugPrint("%d", limit);
  
  // debug print
  for(new i = 0; i<limit; i++){
    GetArrayArray(g_hPropPhysicsObjectInfo, i, data, DATA_STRUCTURE_SIZE);
    DebugPrint("%d origin: %f %f %f, rotation: %f %f %f", data[0], data[1], data[2], data[3],
    data[4],data[5],data[6]);
  }
  
  return Plugin_Continue;
}

public Action:Command_PropPsysicsRestoreAll(client, args)
{
  DebugPrint("Command_PropPsysicsRestoreAll");
  
  decl Float:data[DATA_STRUCTURE_SIZE];
  decl Float:origin[3];
  decl Float:rotation[3];
  decl Float:velocity[3];

  // 表示してみる
  new limit = GetArraySize(g_hPropPhysicsObjectInfo);
  DebugPrint("%d", limit);
  
  for(new i = 0; i<limit; i++){
    GetArrayArray(g_hPropPhysicsObjectInfo, i, data, DATA_STRUCTURE_SIZE);
    DebugPrint("%d origin: %f %f %f, rotation: %f %f %f", data[0], data[1], data[2], data[3],
    data[4],data[5],data[6]);
    
    origin[0] = data[1];
    origin[1] = data[2];
    origin[2] = data[3];
    
    rotation[0] = data[4];
    rotation[1] = data[5];
    rotation[2] = data[6];
    
    velocity[0] = velocity[1] = velocity[2] = 0.0;
    
    TeleportEntity(data[0], origin, rotation, velocity);
  }
  
  return Plugin_Continue;
}

// modify convars
public OnConVarsChanged(Handle:hConVar, const String:oldValue[], const String:newValue[])
{
  ReloadConvars();
}

public ReloadConvars()
{
  // reload convars
  g_bEnable = GetConVarBool(g_hEnable);
  g_bDebug = GetConVarBool(g_hDebug);
  DebugPrint("convar reloaded");
}
