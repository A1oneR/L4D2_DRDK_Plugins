#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <l4d2d_timers>

new Handle:hCvarTimeToSuicide;

new TimeToSuicide;

new SuicideTimer[MAXPLAYERS + 1];
new bool:bSpecial[MAXPLAYERS + 1];
new bool:g_bLeft4Dead2;
public Plugin:myinfo = 
{
    name = "L4D2 timely kill SI",
    author = "A1R",
    description = "Kill the SI Timely.",
    version = "0.1",
    url = "https://github.com/A1oneR/L4D2_DRDK_Plugins"
};

public OnPluginStart()
{
	HookEvent("player_spawn",               Event_PlayerSpawn,              EventHookMode_Post);
	decl String:sGameFolder[32];
	GetGameFolderName(sGameFolder, 32);
	g_bLeft4Dead2 = StrEqual(sGameFolder, "left4dead2");
    hCvarTimeToSuicide = CreateConVar("l4d2_time_to_suicide", "15", "How many time should the SI be alive.");

}

public OnConfigsExecuted()
{
    TimeToSuicide = GetConVarInt(hCvarTimeToSuicide);
}

public Action: Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
		SuicideTimer[client] = TimeToSuicide;
		bSpecial[client] = false;
		if (GetClientTeam(client) == 3 && IsPlayerTank(client) == false && IsFakeClient(client) == false)
		{
	        CreateTimer(1.0,ForceSuicide,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
}

public Action:ForceSuicide(Handle:timer,any:userid)
{
	new Client = GetClientOfUserId(userid);
	if(!IsPlayerAlive(Client)) 
	{
	        SuicideTimer[Client] = TimeToSuicide;
		    //PrintToHint(Client, "死亡，结束计时."); //DEBUG
	        return Plugin_Stop;
	}
	if (bSpecial[Client] == true)
	{
	    PrintHintText(Client, "进入特殊状态，结束计时");
		SuicideTimer[Client] = TimeToSuicide;
		return Plugin_Stop;
	}
	if (IsPlayerTank(Client) == true)
	{
	    PrintHintText(Client, "我们是Tank，我们不处死，结束计时");
		SuicideTimer[Client] = TimeToSuicide;
		return Plugin_Stop;
	}
	SuicideTimer[Client]--;
	PrintHintText(Client, "你已复活，你将在%i秒后被处死", SuicideTimer[Client]);
	if (SuicideTimer[Client] <= 0)
	{
	    ForcePlayerSuicide(Client);
		PrintHintText(Client, "你已被处死，下次不要再猥琐不上了");
		SuicideTimer[Client] = TimeToSuicide;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public L4D_OnEnterGhostState(client)
{
    bSpecial[client] = true;
	//PrintToChatAll("进入灵魂状态，结束计时."); //DEBUG
}

stock bool IsClientAndInGame(int index) {
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

bool:IsPlayerTank(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2 ? 8 : 5);
}

stock int GetZombieClass(int client) { return GetEntProp(client, Prop_Send, "m_zombieClass"); }