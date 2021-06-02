#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <l4d2d_timers>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3

#define ZC_BOOMER       2
#define ZC_HUNTER       3
#define ZC_JOCKEY       5
#define ZC_CHARGER      6

new Handle:hCvarJockeyDMGMaxStage;
new Handle:hCvarJockeyDMGPerStage;
new Handle:hCvarJockeyDMGTimePerStage;
new Handle:hCvarJockeyClawDMGMaxStage;
new Handle:hCvarJockeyClawDMGPerStage;
new Handle:hCvarHunterDMGMaxStage;
new Handle:hCvarHunterDMGPerStage;
new Handle:hCvarHunterDMGTimePerStage;
new Handle:hCvarHunterClawDMGMaxStage;
new Handle:hCvarHunterClawDMGPerStage;
new Handle:hCvarChargerDMGMaxStage;
new Handle:hCvarChargerDMGPerStage;
new Handle:hCvarChargerClawDMGMaxStage;
new Handle:hCvarChargerClawDMGPerStage;
new Handle:hCvarBoomerClawDMGMaxStage;
new Handle:hCvarBoomerClawDMGPerStage;
new Handle:hCvarChargerDMG;
new Handle:hCvarChargerClawDMG;

new Float:HunterDmgTimePerStage;
new Float:JockeyDmgTimePerStage;

new HunterDmgMaxStage;
new HunterDmgPerStage;
new JockeyDmgMaxStage;
new JockeyDmgPerStage;
new ChargerDmgMaxStage;
new ChargerDmgPerStage;
new HunterClawDmgMaxStage;
new HunterClawDmgPerStage;
new JockeyClawDmgMaxStage;
new JockeyClawDmgPerStage;
new ChargerClawDmgMaxStage;
new ChargerClawDmgPerStage;
new BoomerClawDmgMaxStage;
new BoomerClawDmgPerStage;

new Handle:OriginBoomerClawDMG;
new OriginChargerClawDMG;
new OriginChargerPunchDMG;
new Handle:OriginHunterClawDMG;
new Handle:OriginHunterPounceDMG;
new Handle:OriginJockeyClawDMG;
new Handle:OriginJockeyRideDMG;

new Handle: hInflictorTrie = INVALID_HANDLE;

new HunterStage[MAXPLAYERS + 1];
new HunterStageClaw[MAXPLAYERS + 1];
new JockeyStage[MAXPLAYERS + 1];
new JockeyStageClaw[MAXPLAYERS + 1];
new ChargerStage[MAXPLAYERS + 1];
new ChargerStageClaw[MAXPLAYERS + 1];
new BoomerStageClaw[MAXPLAYERS + 1];

new bool:bShoved[MAXPLAYERS + 1];
new bool:bGhost[MAXPLAYERS + 1];
new bool:bPounced[MAXPLAYERS + 1];
new bool:bRidden[MAXPLAYERS + 1];
new bool:bCharged[MAXPLAYERS + 1];
new bool:StartHunterPounceTimer[MAXPLAYERS + 1];
new bool:StartJockeyRideTimer[MAXPLAYERS + 1];

new bool:bLateLoad;

enum TankOrSIWeapon
{
        TANKWEAPON,
        CHARGERWEAPON,
	BOOMERWEAPON,
	HUNTERWEAPON,
	JOCKEYWEAPON,
        SIWEAPON
}

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
    bLateLoad = late;
    return APLRes_Success;    
}

public Plugin:myinfo = 
{
    name = "L4D2 Infected Stage Damage",
    author = "A1R",
    description = "Customize the infected damage in stage.",
    version = "0.3",
    url = "https://github.com/A1oneR/L4D2_DRDK_Plugins"
};

public OnPluginStart()
{
        HookEvent("jockey_ride",                Event_JockeyRide,               EventHookMode_Post);
	//HookEvent("charger_carry_start",        Event_ChargeCarryStart,         EventHookMode_Post);
        //HookEvent("charger_carry_end",          Event_ChargeCarryEnd,           EventHookMode_Post);
	HookEvent("charger_pummel_start",       Event_ChargePummelStart,        EventHookMode_Post);
	HookEvent("lunge_pounce",               Event_LungePounce,              EventHookMode_Post);
	HookEvent("player_death",               Event_PlayerDeath,              EventHookMode_Pre);
	HookEvent("player_shoved",              Event_PlayerShoved,             EventHookMode_Post);
	
        hCvarJockeyDMGMaxStage = CreateConVar("l4d2_jockey_dmg_maxstage", "2", "Maximum Stage of the DMG can be done.");
	hCvarJockeyDMGPerStage = CreateConVar("l4d2_jockey_dmg_perstage", "1", "For Each Stage the DMG added.");
	hCvarJockeyDMGTimePerStage = CreateConVar("l4d2_jockey_dmg_time_perstage", "3", "How much time will the stage go on to the next one.");
	hCvarJockeyClawDMGMaxStage = CreateConVar("l4d2_jockey_claw_dmg_maxstage", "4", "Maximum Stage of the Claw DMG can be done.");
	hCvarJockeyClawDMGPerStage = CreateConVar("l4d2_jockey_claw_dmg_perstage", "3", "For Each Stage the Claw DMG added.");
	hCvarHunterDMGMaxStage = CreateConVar("l4d2_hunter_dmg_maxstage", "2", "Maximum Stage of the DMG can be done.");
	hCvarHunterDMGPerStage = CreateConVar("l4d2_hunter_dmg_perstage", "1", "For Each Stage the DMG added.");
	hCvarHunterDMGTimePerStage = CreateConVar("l4d2_hunter_dmg_time_perstage", "3", "How much time will the stage go on to the next one.");
	hCvarHunterClawDMGMaxStage = CreateConVar("l4d2_hunter_claw_dmg_maxstage", "5", "Maximum Stage of the Claw DMG can be done.");
	hCvarHunterClawDMGPerStage = CreateConVar("l4d2_hunter_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarChargerDMGMaxStage = CreateConVar("l4d2_charger_dmg_maxstage", "4", "Maximum Stage of the DMG can be done.");
	hCvarChargerDMGPerStage = CreateConVar("l4d2_charger_dmg_perstage", "4", "For Each Stage the DMG added.");
	hCvarChargerClawDMGMaxStage = CreateConVar("l4d2_charger_claw_dmg_maxstage", "6", "Maximum Stage of the Claw DMG can be done.");
	hCvarChargerClawDMGPerStage = CreateConVar("l4d2_charger_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarBoomerClawDMGMaxStage = CreateConVar("l4d2_boomer_claw_dmg_maxstage", "4", "Maximum Stage of the Claw DMG can be done.");
	hCvarBoomerClawDMGPerStage = CreateConVar("l4d2_boomer_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarChargerDMG = CreateConVar("charger_dmg_pound", "10", "Special for charger pound dmg since original plugin may have bug.");
	hCvarChargerClawDMG = CreateConVar("charger_dmg_punch", "6", "Special for charger punch dmg since original plugin may have bug.");

        if (bLateLoad) 
        {
            for (new i = 1; i <= MaxClients; i++) 
            {
                if (IsClientInGame(i)) 
                {
                    OnClientPutInServer(i);
                }
            }
        }
		// trie
        hInflictorTrie = BuildInflictorTrie();
}

public OnConfigsExecuted()
{
        JockeyDmgMaxStage = GetConVarInt(hCvarJockeyDMGMaxStage);
	JockeyDmgPerStage = GetConVarInt(hCvarJockeyDMGPerStage);
	JockeyDmgTimePerStage = GetConVarFloat(hCvarJockeyDMGTimePerStage);
	JockeyClawDmgMaxStage = GetConVarInt(hCvarJockeyClawDMGMaxStage);
	JockeyClawDmgPerStage = GetConVarInt(hCvarJockeyClawDMGPerStage);
	HunterDmgMaxStage = GetConVarInt(hCvarHunterDMGMaxStage);
	HunterDmgPerStage = GetConVarInt(hCvarHunterDMGPerStage);
	HunterDmgTimePerStage = GetConVarFloat(hCvarHunterDMGTimePerStage);
	HunterClawDmgMaxStage = GetConVarInt(hCvarHunterClawDMGMaxStage);
	HunterClawDmgPerStage = GetConVarInt(hCvarHunterClawDMGPerStage);
	ChargerDmgMaxStage = GetConVarInt(hCvarChargerDMGMaxStage);
	ChargerDmgPerStage = GetConVarInt(hCvarChargerDMGPerStage);
	ChargerClawDmgMaxStage = GetConVarInt(hCvarChargerClawDMGMaxStage);
	ChargerClawDmgPerStage = GetConVarInt(hCvarChargerClawDMGPerStage);
	BoomerClawDmgMaxStage = GetConVarInt(hCvarBoomerClawDMGMaxStage);
	BoomerClawDmgPerStage = GetConVarInt(hCvarBoomerClawDMGPerStage);
	OriginHunterPounceDMG = FindConVar("z_pounce_damage");
	OriginHunterClawDMG = FindConVar("hunter_pz_claw_dmg");
	OriginJockeyRideDMG = FindConVar("z_jockey_ride_damage");
	OriginJockeyClawDMG = FindConVar("jockey_pz_claw_dmg");
	OriginChargerPunchDMG = GetConVarInt(hCvarChargerDMG);
	OriginChargerClawDMG = GetConVarInt(hCvarChargerClawDMG);
	OriginBoomerClawDMG = FindConVar("boomer_pz_claw_dmg");
}

public Action: Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
    for ( new i = 1; i <= MaxClients; i++ )
    {
                bCharged[i] = false;
		bPounced[i] = false;
                bRidden[i] = false;
		
		HunterStage[i] = 0;
		HunterStageClaw[i] = 0;
		ChargerStage[i] = 0;
		ChargerStageClaw[i] = 0;
		JockeyStage[i] = 0;
		JockeyStageClaw[i] = 0;
		BoomerStageClaw[i] = 0;
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action: Event_LungePounce( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId( GetEventInt(event, "userid") );
    
	bPounced[client] = true;
	
        return Plugin_Continue;
}

public Action: Event_ChargePummelStart( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt(event, "userid") );
    new victim = GetClientOfUserId( GetEventInt(event, "victim") );
    if ( !IS_VALID_INFECTED(client) ) { return; }
    
    if ( !IS_VALID_SURVIVOR(victim) ) { return; }
    
    bCharged[client] = true;
}

public Action: Event_JockeyRide( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt(event, "userid") );
    new victim = GetClientOfUserId( GetEventInt(event, "victim") );
    
    if ( !IS_VALID_INFECTED(client) || !IS_VALID_SURVIVOR(victim) ) { return Plugin_Continue; }
    
    bRidden[client] = true;
    
    return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	if (!inflictor || !attacker || !victim || !IsValidEdict(victim) || !IsValidEdict(inflictor)) { return Plugin_Continue; }

	// only check player-to-player damage
	decl String:classname[64];
	if (IsClientAndInGame(attacker) && IsClientAndInGame(victim))
	{
		if (attacker == inflictor)                                              // for claws
		{
			GetClientWeapon(inflictor, classname, sizeof(classname));
		}
		else
		{
			GetEdictClassname(inflictor, classname, sizeof(classname));         // for tank punch/rock
		}
	}
	else { return Plugin_Continue; }

	// check teams
	if (GetClientTeam(attacker) != TEAM_INFECTED || GetClientTeam(victim) != TEAM_SURVIVOR) { return Plugin_Continue; }

	// only allow selected infected
	if (GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_CHARGER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_HUNTER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_JOCKEY && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_BOOMER) { return Plugin_Continue; }
	
	// only check tank punch/rock and SI claws (also rules out anything but infected-to-survivor damage)
	new TankOrSIWeapon: inflictorID;
	if (!GetTrieValue(hInflictorTrie, classname, inflictorID)) { return Plugin_Continue; }
	if (inflictorID != CHARGERWEAPON && inflictorID != BOOMERWEAPON && inflictorID != HUNTERWEAPON && inflictorID != JOCKEYWEAPON) { return Plugin_Continue; }
	
	if ( inflictorID == HUNTERWEAPON)
	{
	        if (bPounced[attacker] == true)
		{
		        //PrintToChatAll("It's A Hunter Pouncing."); //DEBUG
			bGhost[attacker] = false;
			bShoved[attacker] = false;
			float OHPDMG = GetConVarFloat(OriginHunterPounceDMG);
			float StageDMG = float(HunterStage[attacker] * HunterDmgPerStage);
		        damage = OHPDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Hunter DMG Survivor For %.1f% damage, Stage %i.", damage, HunterStage[attacker]); //DEBUG
			if (StartHunterPounceTimer[attacker] == false)
			{
			        StartHunterPounceTimer[attacker] = true;
				CreateTimer(HunterDmgTimePerStage,HunterStageIncrease,GetClientUserId(attacker),TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				//PrintToChatAll("The Hunter Timer is going on."); //DEBUG
			}
			return Plugin_Changed;
		}
		else
		{
		        //PrintToChatAll("It's A Hunter Claw."); //DEBUG
			float OHCDMG = GetConVarFloat(OriginHunterClawDMG);
			float StageDMG = float(HunterStageClaw[attacker] * HunterClawDmgPerStage);
			damage = OHCDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Hunter DMG Survivor For %.1f% damage, Stage %i.", damage, HunterStageClaw[attacker]); //DEBUG
			HunterStageClaw[attacker] += 1;
			if (HunterStageClaw[attacker] > HunterClawDmgMaxStage)
			{
			        HunterStageClaw[attacker] = HunterClawDmgMaxStage;
				//PrintToChatAll("Hunter Claw DMG has got to it Max Stage."); //DEBUG
			}
			return Plugin_Changed;
		}
	}
	else if (inflictorID == JOCKEYWEAPON)
	{
	        if (bRidden[attacker] == true)
		{
		        //PrintToChatAll("It's A Jockey Riding."); //DEBUG
			bGhost[attacker] = false;
		        bShoved[attacker] = false;
			float OJRDMG = GetConVarFloat(OriginJockeyRideDMG);
			float StageDMG = float(JockeyStage[attacker] * JockeyDmgPerStage);
		        damage = OJRDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Jockey DMG Survivor For %.1f% damage, Stage %i.", damage, JockeyStage[attacker]); //DEBUG
			if (StartJockeyRideTimer[attacker] == false)
			{
			        StartJockeyRideTimer[attacker] = true;
				CreateTimer(JockeyDmgTimePerStage,JockeyStageIncrease,GetClientUserId(attacker),TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				//PrintToChatAll("The Jockey Timer is going on."); //DEBUG
			}
			return Plugin_Changed;
		}
		else
		{
		        //PrintToChatAll("It's A Jockey Claw."); //DEBUG
			float OJCDMG = GetConVarFloat(OriginJockeyClawDMG);
			float StageDMG = float(JockeyStageClaw[attacker] * JockeyClawDmgPerStage);
			damage = OJCDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Jockey DMG Survivor For %.1f% damage, Stage %i.", damage, JockeyStageClaw[attacker]); //DEBUG
			JockeyStageClaw[attacker] += 1;
			if (JockeyStageClaw[attacker] > JockeyClawDmgMaxStage)
			{
			        JockeyStageClaw[attacker] = JockeyClawDmgMaxStage;
				//PrintToChatAll("Jockey Claw DMG has got to it Max Stage."); //DEBUG
			}
			return Plugin_Changed;
		}
	}
	else if (inflictorID == CHARGERWEAPON)
	{
	        if (bCharged[attacker] == true)
		{
		        //PrintToChatAll("It's A Charger Pounding."); //DEBUG
			bGhost[attacker] = false;
		        bShoved[attacker] = false;
			float OCPDMG = float(OriginChargerPunchDMG);
			if (OCPDMG <= 0.0)
			{
			    OCPDMG = 15.0;
			}
			float StageDMG = float(ChargerStage[attacker] * ChargerDmgPerStage);
		        damage = OCPDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Charger DMG Survivor For %.1f% damage, Stage %i.", damage, ChargerStage[attacker]); //DEBUG
			ChargerStage[attacker] += 1;
			if (ChargerStage[attacker] > ChargerDmgMaxStage)
			{
			        ChargerStage[attacker] = ChargerDmgMaxStage;
				//PrintToChatAll("Charger DMG has got to it Max Stage."); //DEBUG
			}
			return Plugin_Changed;
		}
		else
		{
		        //PrintToChatAll("It's A Charger Claw."); //DEBUG
			float OCCDMG = float(OriginChargerClawDMG);
			if (OCCDMG <= 0.0)
			{
			    OCCDMG = 10.0;
			}
			float StageDMG = float(ChargerStageClaw[attacker] * ChargerClawDmgPerStage);
			damage = OCCDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Charger DMG Survivor For %.1f% damage, Stage %i.", damage, ChargerStageClaw[attacker]); //DEBUG
			ChargerStageClaw[attacker] += 1;
			if (ChargerStageClaw[attacker] > ChargerClawDmgMaxStage)
			{
			        ChargerStageClaw[attacker] = ChargerClawDmgMaxStage;
				//PrintToChatAll("Charger Claw DMG has got to it Max Stage."); //DEBUG
			}
			return Plugin_Changed;
		}
	}		
	else if (inflictorID == BOOMERWEAPON)
	{
	        //PrintToChatAll("It's A Boomer Claw."); //DEBUG
		float OBCDMG = GetConVarFloat(OriginBoomerClawDMG);
		float StageDMG = float(BoomerStageClaw[attacker] * BoomerClawDmgPerStage);
		damage = OBCDMG + StageDMG; //DMG Done TO Survivor.
		//PrintToChatAll("Boomer DMG Survivor For %.1f% damage, Stage %i.", damage, BoomerStageClaw[attacker]); //DEBUG
		BoomerStageClaw[attacker] += 1;
		if (BoomerStageClaw[attacker] > BoomerClawDmgMaxStage)
		{
		        BoomerStageClaw[attacker] = BoomerClawDmgMaxStage;
			//PrintToChatAll("Boomer Claw DMG has got to it Max Stage."); //DEBUG
		}
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

public Action:HunterStageIncrease(Handle:timer,any:userid)
{
	new Client = GetClientOfUserId(userid);
	if(!IsPlayerAlive(Client) || bShoved[Client] == true || bGhost[Client] == true) 
	{
	        HunterStage[Client] = 0;
		//PrintToChatAll("Reset Hunter Pouncing Stage."); //DEBUG
	        return Plugin_Stop;
	}
	HunterStage[Client]++;
	if (HunterStage[Client] > HunterDmgMaxStage)
	{
	        HunterStage[Client] = HunterDmgMaxStage;
		//PrintToChatAll("Hunter Pouncing DMG has got to it Max Stage."); //DEBUG
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:JockeyStageIncrease(Handle:timer,any:userid)
{
	new Client = GetClientOfUserId(userid);
	if(!IsPlayerAlive(Client) || bShoved[Client] == true || bGhost[Client] == true) 
	{
	        JockeyStage[Client] = 0;
		//PrintToChatAll("Reset Jockey Riding Stage."); //DEBUG
	        return Plugin_Stop;
	}
	JockeyStage[Client]++;
	if (JockeyStage[Client] > JockeyDmgMaxStage)
	{
	        JockeyStage[Client] = JockeyDmgMaxStage;
		//PrintToChatAll("Jockey Riding DMG has got to it Max Stage."); //DEBUG
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Handle:BuildInflictorTrie()
{
    new Handle: trie = CreateTrie();
    //SetTrieValue(trie, "weapon_tank_claw",      TANKWEAPON);
    //SetTrieValue(trie, "tank_rock",             TANKWEAPON);
    SetTrieValue(trie, "weapon_boomer_claw",    BOOMERWEAPON);
    SetTrieValue(trie, "weapon_charger_claw",   CHARGERWEAPON);
    SetTrieValue(trie, "weapon_hunter_claw",    HUNTERWEAPON);
    SetTrieValue(trie, "weapon_jockey_claw",    JOCKEYWEAPON);
    //SetTrieValue(trie, "weapon_smoker_claw",    SIWEAPON);
    //SetTrieValue(trie, "weapon_spitter_claw",   SIWEAPON);
    return trie;    
}

public L4D_OnEnterGhostState(client)
{
        bGhost[client] = true;
	bShoved[client] = false;
	bPounced[client] = false;
	bRidden[client] = false;
	bCharged[client] = false;
	HunterStage[client] = 0;
	JockeyStage[client] = 0;
	ChargerStage[client] = 0;
	HunterStageClaw[client] = 0;
	JockeyStageClaw[client] = 0;
	ChargerStageClaw[client] = 0;
	BoomerStageClaw[client] = 0;
	//PrintToChatAll("Enter Ghost State,reset the stage."); //DEBUG
}

public Action: Event_PlayerShoved( Handle:event, const String:name[], bool:dontBroadcast )
{
        new victim = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
        if ( !IS_VALID_SURVIVOR(attacker) || !IS_VALID_INFECTED(victim) ) { return Plugin_Continue; }
        bShoved[victim] = true;
	bPounced[victim] = false;
	bRidden[victim] = false;
	bCharged[victim] = false;
	HunterStage[victim] = 0;
	JockeyStage[victim] = 0;
	ChargerStage[victim] = 0;
	HunterStageClaw[victim] = 0;
	JockeyStageClaw[victim] = 0;
	ChargerStageClaw[victim] = 0;
	BoomerStageClaw[victim] = 0;
	//PrintToChatAll("Be Shoved,reset the stage."); //DEBUG
        return Plugin_Continue;
}

public Action: Event_PlayerDeath( Handle:hEvent, const String:name[], bool:dontBroadcast )
{
    new victim = GetClientOfUserId( GetEventInt(hEvent, "userid") );
	
    if ( IS_VALID_INFECTED(victim) )
    {
                bGhost[victim] = true;
		bShoved[victim] = false;
		bPounced[victim] = false;
	        bRidden[victim] = false;
	        bCharged[victim] = false;
	        HunterStage[victim] = 0;
	        JockeyStage[victim] = 0;
	        ChargerStage[victim] = 0;
	        HunterStageClaw[victim] = 0;
	        JockeyStageClaw[victim] = 0;
	        ChargerStageClaw[victim] = 0;
	        BoomerStageClaw[victim] = 0;
		//PrintToChatAll("Died,reset the stage."); //DEBUG
    }
	
    return Plugin_Continue;
}

stock bool IsClientAndInGame(int index) {
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

stock int GetZombieClass(int client) { return GetEntProp(client, Prop_Send, "m_zombieClass"); }