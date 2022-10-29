#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "Medkit Nerf",
    author = "A1R",
    version = "0.1",
    description = "Nerf the medkit."
};

new incapCount[MAXPLAYERS + 1];
new bool:OverIncap[MAXPLAYERS + 1];

public OnPluginStart() 
{
	HookEvent("heal_success",				Event_FirstAid);
	HookEvent("revive_success",				Event_ReviveSuccess);
}

public OnRoundStart()
{
	for (new i=1 ; i<=MaxClients ; i++)
	{
		OverIncap[i] = false;
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1 ; i<=MaxClients ; i++)
	{
		incapCount[i] = GetSurvivorIncapCount(i);
        if (incapCount[i] > 1)
        {
            OverIncap[i] = true;
		}
	}
}

public Event_FirstAid(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "subject"));
		if( client && IsClientInGame(client) )
		{
			if (OverIncap[client] == false)
			{

			}else if (OverIncap[client] == true)
			{
			    PrintToChat(client, "Reduce the incap count to 1 from 2."); //DEBUG
			    SetEntProp(client, Prop_Send, "m_currentReviveCount", 1);
				OverIncap[client] = false;
			}
		}
}

GetSurvivorIncapCount(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}