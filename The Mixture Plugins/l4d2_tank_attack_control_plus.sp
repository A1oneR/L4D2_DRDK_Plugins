#include <sourcemod>
#include <left4downtown>

const TANK_ZOMBIE_CLASS = 8;

//requires at least left4downtown2 v0.5.4
//throw sequences:
//48 - (not used unless tank_rock_overhead_percent is changed)

//49 - 1handed overhand (+attack2),
//50 - underhand (+use),
//51 - 2handed overhand (+reload)

new g_iQueuedThrow[MAXPLAYERS + 1];
new Handle:g_hBlockPunchRock = INVALID_HANDLE;
new Handle:g_hBlockJumpRock = INVALID_HANDLE;
new Handle:hOverhandOnly;

new Float:throwQueuedAt[MAXPLAYERS + 1];

#pragma semicolon 1
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"
#define CUESOUND "level/popup.wav"

new Handle:hMode = INVALID_HANDLE;
new Handle:hMultiplier = INVALID_HANDLE;
new Handle:hLimit = INVALID_HANDLE;
new Handle:hOffset = INVALID_HANDLE;

new bool:bCueAllowed[MAXPLAYERS+1] = false;
new bool:bBunnyhopOff[MAXPLAYERS+1] = false;
new iOffset = 0;
new iDirectionCache[MAXPLAYERS+1] = 0;

public Plugin:myinfo = 
{
	name = "Tank Attack Control PLUS", 
	author = "vintik, CanadaRox, Jacob, Visor",
	description = "",
	version = "0.7",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
}

public OnPluginStart()
{
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	
	//future-proof remake of the confogl feature (could be used with lgofnoc)
	g_hBlockPunchRock = CreateConVar("l4d2_block_punch_rock", "1", "Block tanks from punching and throwing a rock at the same time");
	g_hBlockJumpRock = CreateConVar("l4d2_block_jump_rock", "0", "Block tanks from jumping and throwing a rock at the same time");
	hOverhandOnly = CreateConVar("tank_overhand_only", "0", "Force tank to only throw overhand rocks.", FCVAR_PLUGIN);

	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
	
	CreateConVar("l4d_bunnyhop_version", PLUGIN_VERSION, "version of bunnyhop+", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hMode = CreateConVar("l4d_bunnyhop_mode",
		"1.0",
		"Plugin mode: (0)disabled (1)auto-bunnyhop (2)manual bunnyhop training",
		FCVAR_PLUGIN,true,0.0,true,2.0);

	hMultiplier = CreateConVar("l4d_bunnyhop_multiplier",
		"50.0",
		"Multiplier: set the value multiplied to the lateral velocity gain for each successful bunnyhop.",
		FCVAR_PLUGIN,true,0.0,true,200.0);

	hLimit = CreateConVar("l4d_bunnyhop_limit",
		"3000.0",
		"Limit: set player speed value at which lateral velocity no longer multiplies lateral velocity.",
		FCVAR_PLUGIN,true,0.0,true,500.0);

	hOffset = CreateConVar("l4d_bunnyhop_delay",
		"0",
		"Cue offset: for manual mode, set integer value for how early the cue is to be heard. Higher values mean earlier cues.",
		FCVAR_PLUGIN,true,0.0,true,5.0);


	HookConVarChange(hOffset, ConVar_Delay);
	HookEvent("player_jump_apex", Event_PlayerJumpApex);
	RegConsoleCmd("sm_bhop", Command_Autobhop);

	AutoExecConfig(true, "bunnyhop");
}

public ConVar_Delay(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iOffset = StringToInt(newValue);
}

public OnMapStart()
{
	PrecacheSound(CUESOUND, true);
	iOffset = GetConVarInt(hOffset);
}

public OnRoundStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		throwQueuedAt[i] = 0.0;
		bBunnyhopOff[i] = true;
	}
}

public Action:Command_Autobhop(client, args)
{	
	if (GetConVarInt(hMode) == 1
		&& client > 0
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& IsTank(client))
	{
		if (bBunnyhopOff[client] == true)
		{
			bBunnyhopOff[client] = false;
			new HP = GetEntProp(client, Prop_Data, "m_iHealth");
			SetEntProp(client, Prop_Data, "m_iHealth", HP - 3000);
			PrintToChat(client, "自动连跳\n开启");
		}
		else
		{
			bBunnyhopOff[client] = true;
			PrintToChat(client, "自动连跳\n关闭");
		}
	}
	else
	{
	    PrintToChat(client, "只有Tank才能使用此命令！");
	}
	return Plugin_Handled;
}

public OnGameFrame()
{
	if (!IsServerProcessing()
		|| GetConVarInt(hMode) != 2)
		return;
	for (new i=1 ; i<=MaxClients ; i++)
	{
		if (!bBunnyhopOff[i]
			&& IsClientInGame(i)
			&& IsPlayerAlive(i)
			&& bCueAllowed[i]
			&& GetEntProp(i, Prop_Data, "m_nWaterLevel") < 1 + iOffset)
		{
			bCueAllowed[i] = false;
			EmitSoundToClient(i, CUESOUND);
		}	
	}
}

public Event_PlayerJumpApex(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMode = GetConVarInt(hMode);
	if (iMode == 0) return;
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (!IsClientInGame(client)
		|| GetClientTeam(client)!= 2
		|| !IsPlayerAlive(client)
		|| bBunnyhopOff[client])
		return;
	
	if (iMode == 2) bCueAllowed[client] = true;
	
	if ((GetClientButtons(client) & IN_MOVELEFT)
		|| (GetClientButtons(client) & IN_MOVERIGHT))
	{	
		if (GetClientButtons(client) & IN_MOVELEFT) 
		{
			if (iDirectionCache[client] > -1)
			{
				iDirectionCache[client] = -1;
				return;
			}
			else iDirectionCache[client] = -1;
		}
		else if (GetClientButtons(client) & IN_MOVERIGHT)
		{
			if (iDirectionCache[client] < 1)
			{
				iDirectionCache[client] = 1;
				return;
			}
			else iDirectionCache[client] = 1;
		}
		new Float:fAngles[3];
		new Float:fLateralVector[3];
		new Float:fForwardVector[3];
		new Float:fNewVel[3];
		
		GetEntPropVector(client, Prop_Send, "m_angRotation", fAngles);
		GetAngleVectors(fAngles, NULL_VECTOR, fLateralVector, NULL_VECTOR);
		NormalizeVector(fLateralVector, fLateralVector);
		
		if (GetClientButtons(client) & IN_MOVELEFT) NegateVector(fLateralVector);

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fForwardVector);
		if (RoundToNearest(GetVectorLength(fForwardVector)) > GetConVarFloat(hLimit)) return;
		else ScaleVector(fLateralVector, GetVectorLength(fLateralVector) * GetConVarFloat(hMultiplier));
		
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fNewVel);
		for(new i=0;i<3;i++) fNewVel[i] += fLateralVector[i];

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,fNewVel);
	}
}

public TankSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(tank)) return;

	new bool:hidemessage = false;
	decl String:buffer[3];
	if (GetClientInfo(tank, "rs_hidemessage", buffer, sizeof(buffer)))
	{
		hidemessage = bool:StringToInt(buffer);
	}
	if (!hidemessage && (GetConVarBool(hOverhandOnly) == false))
	{
		PrintToChat(tank, "[SM] 扔石头的姿势");
		PrintToChat(tank, "使用键(E) -> 低手抛石(砸屋檐下)");
		PrintToChat(tank, "推键(右键) -> 单手抛石(万能姿势)");
		PrintToChat(tank, "换弹键(R) -> 双手抛石(过高墙)");
		PrintToChat(tank, "输入!bhop开启自动连跳（损失3000血量）");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 3
		|| GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
			return Plugin_Continue;
	
	//if tank
	if ((buttons & IN_JUMP) && ShouldCancelJump(client))
	{
		buttons &= ~IN_JUMP;
	}
	
	if (GetConVarBool(hOverhandOnly) == false)
	{
		if (buttons & IN_RELOAD)
		{
			g_iQueuedThrow[client] = 3; //two hand overhand
			buttons |= IN_ATTACK2;
		}
		else if (buttons & IN_USE)
		{
			g_iQueuedThrow[client] = 2; //underhand
			buttons |= IN_ATTACK2;
		}
		else
		{
			g_iQueuedThrow[client] = 1; //one hand overhand
		}
	}
	else
	{
		g_iQueuedThrow[client] = 3; // two hand overhand
	}
	
	if (GetConVarInt(hMode) == 1
		&& !bBunnyhopOff[client]
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& IsTank(client))
	{
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityMoveType(client) & MOVETYPE_LADDER))
			{
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2) buttons &= ~IN_JUMP;
			}
		}
	}
	return Plugin_Continue;
}

public Action:L4D_OnCThrowActivate(ability)
{
	if (!IsValidEntity(ability))
	{
		LogMessage("Invalid 'ability_throw' index: %d. Continuing throwing.", ability);
		return Plugin_Continue;
	}
	new client = GetEntPropEnt(ability, Prop_Data, "m_hOwnerEntity");
	
	if (GetClientButtons(client) & IN_ATTACK)
	{
		if (GetConVarBool(g_hBlockPunchRock))
			return Plugin_Handled;
	}
	
	throwQueuedAt[client] = GetGameTime();
	return Plugin_Continue;
}

public Action:L4D2_OnSelectTankAttack(client, &sequence)
{
	if (sequence > 48 && g_iQueuedThrow[client])
	{
		//rock throw
		sequence = g_iQueuedThrow[client] + 48;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:ShouldCancelJump(client)
{
	if (!GetConVarBool(g_hBlockJumpRock))
	{
		return false;
	}
	return (1.5 > GetGameTime() - throwQueuedAt[client]);
}

bool:IsTank( client ) {
    if ( client <= 0
    || !IsClientInGame(client)
    || GetClientTeam(client) != 3 ) {
        return false;
    }
    
    new playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    
    if ( playerClass == TANK_ZOMBIE_CLASS ) {
        return true;
    }
    
    return false;
}