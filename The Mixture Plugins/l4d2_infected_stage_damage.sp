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

#define ZC_SMOKER       1
#define ZC_BOOMER       2
#define ZC_HUNTER       3
#define ZC_SPITTER      4
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
new Handle:hCvarHunterIncapDMGBonus;
new Handle:hCvarSmokerDMGMaxStage;
new Handle:hCvarSmokerDMGPerStage;
new Handle:hCvarSmokerDMGTimePerStage;
new Handle:hCvarSmokerClawDMGMaxStage;
new Handle:hCvarSmokerClawDMGPerStage;
new Handle:hCvarSmokerIncapDMGBonus;
new Handle:hCvarChargerDMGMaxStage;
new Handle:hCvarChargerDMGPerStage;
new Handle:hCvarChargerClawDMGMaxStage;
new Handle:hCvarChargerClawDMGPerStage;
new Handle:hCvarBoomerClawDMGMaxStage;
new Handle:hCvarBoomerClawDMGPerStage;
new Handle:hCvarSpitterClawDMGMaxStage;
new Handle:hCvarSpitterClawDMGPerStage;
new Handle:hCvarChargerDMG;
new Handle:hCvarChargerClawDMG;

new Handle:hCvarEnableHunter;
new Handle:hCvarEnableJockey;
new Handle:hCvarEnableSmoker;
new Handle:hCvarEnableCharger;
new Handle:hCvarEnableBoomer;
new Handle:hCvarEnableSpitter;
new Handle:hCvarEnableShoveResetClawStage;

new Float:HunterDmgTimePerStage;
new Float:JockeyDmgTimePerStage;
new Float:SmokerDmgTimePerStage;

new HunterDmgMaxStage;
new HunterDmgPerStage;
new SmokerDmgMaxStage;
new SmokerDmgPerStage;
new JockeyDmgMaxStage;
new JockeyDmgPerStage;
new ChargerDmgMaxStage;
new ChargerDmgPerStage;
new HunterClawDmgMaxStage;
new HunterClawDmgPerStage;
new Float:HunterIncapDmgBonus;
new SmokerClawDmgMaxStage;
new SmokerClawDmgPerStage;
new Float:SmokerIncapDmgBonus;
new JockeyClawDmgMaxStage;
new JockeyClawDmgPerStage;
new ChargerClawDmgMaxStage;
new ChargerClawDmgPerStage;
new BoomerClawDmgMaxStage;
new BoomerClawDmgPerStage;
new SpitterClawDmgMaxStage;
new SpitterClawDmgPerStage;

new Handle:OriginBoomerClawDMG;
new Handle:OriginSpitterClawDMG;
new OriginChargerClawDMG;
new OriginChargerPunchDMG;
new Handle:OriginHunterClawDMG;
new Handle:OriginHunterPounceDMG;
new Handle:OriginJockeyClawDMG;
new Handle:OriginJockeyRideDMG;
new Handle:OriginSmokerDragDMG;
new Handle:OriginSmokerClawDMG;

new Handle: hInflictorTrie = INVALID_HANDLE;

new HunterStage[MAXPLAYERS + 1];
new HunterStageClaw[MAXPLAYERS + 1];
new JockeyStage[MAXPLAYERS + 1];
new JockeyStageClaw[MAXPLAYERS + 1];
new ChargerStage[MAXPLAYERS + 1];
new ChargerStageClaw[MAXPLAYERS + 1];
new SmokerStage[MAXPLAYERS + 1];
new SmokerStageClaw[MAXPLAYERS + 1];
new BoomerStageClaw[MAXPLAYERS + 1];
new SpitterStageClaw[MAXPLAYERS + 1];

new bool:bShoved[MAXPLAYERS + 1];
new bool:bGhost[MAXPLAYERS + 1];
new bool:bPounced[MAXPLAYERS + 1];
new bool:bRidden[MAXPLAYERS + 1];
new bool:bCharged[MAXPLAYERS + 1];
new bool:bDraged[MAXPLAYERS + 1];
new bool:StartHunterPounceTimer[MAXPLAYERS + 1];
new bool:StartJockeyRideTimer[MAXPLAYERS + 1];
new bool:StartSmokerDragTimer[MAXPLAYERS + 1];

new bool:bLateLoad;

enum TankOrSIWeapon
{
        TANKWEAPON,
        CHARGERWEAPON,
	BOOMERWEAPON,
	HUNTERWEAPON,
	JOCKEYWEAPON,
	SMOKERWEAPON,
	SPITTERWEAPON,
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
    version = "0.9.2",
    url = "https://github.com/A1oneR/L4D2_DRDK_Plugins"
};

public OnPluginStart()
{
        HookEvent("jockey_ride",                Event_JockeyRide,               EventHookMode_Post);
	HookEvent("jockey_ride_end",            Event_JockeyRideEnd,            EventHookMode_Post);
	//HookEvent("charger_carry_start",        Event_ChargeCarryStart,         EventHookMode_Post);
        //HookEvent("charger_carry_end",          Event_ChargeCarryEnd,           EventHookMode_Post);
	HookEvent("charger_pummel_start",       Event_ChargePummelStart,        EventHookMode_Post);
	HookEvent("charger_pummel_end",         Event_ChargePummelEnd,          EventHookMode_Post);
	HookEvent("lunge_pounce",               Event_LungePounce,              EventHookMode_Post);
	HookEvent("pounce_end",                 Event_PounceEnd,                EventHookMode_Post);
	HookEvent("tongue_grab",                OnTongueGrab,                   EventHookMode_Post);
	HookEvent("tongue_pull_stopped",        Event_TonguePullStopped,        EventHookMode_Post);
	HookEvent("player_death",               Event_PlayerDeath,              EventHookMode_Pre);
	HookEvent("player_shoved",              Event_PlayerShoved,             EventHookMode_Post);
	
        hCvarJockeyDMGMaxStage = CreateConVar("l4d2_jockey_dmg_maxstage", "2", "Maximum Stage of the DMG can be done.");
	hCvarJockeyDMGPerStage = CreateConVar("l4d2_jockey_dmg_perstage", "1", "For Each Stage the DMG added.");
	hCvarJockeyDMGTimePerStage = CreateConVar("l4d2_jockey_dmg_time_perstage", "3", "How much time will the stage go on to the next one.");
	hCvarJockeyClawDMGMaxStage = CreateConVar("l4d2_jockey_claw_dmg_maxstage", "4", "Maximum Stage of the Claw DMG can be done.");
	hCvarJockeyClawDMGPerStage = CreateConVar("l4d2_jockey_claw_dmg_perstage", "3", "For Each Stage the Claw DMG added.");
	hCvarEnableJockey = CreateConVar("l4d2_enable_jockey_stagedmg", "1", "Set 1 to enable jockey do the stage dmg.");
	hCvarHunterDMGMaxStage = CreateConVar("l4d2_hunter_dmg_maxstage", "2", "Maximum Stage of the DMG can be done.");
	hCvarHunterDMGPerStage = CreateConVar("l4d2_hunter_dmg_perstage", "1", "For Each Stage the DMG added.");
	hCvarHunterDMGTimePerStage = CreateConVar("l4d2_hunter_dmg_time_perstage", "3", "How much time will the stage go on to the next one.");
	hCvarHunterClawDMGMaxStage = CreateConVar("l4d2_hunter_claw_dmg_maxstage", "5", "Maximum Stage of the Claw DMG can be done.");
	hCvarHunterClawDMGPerStage = CreateConVar("l4d2_hunter_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarHunterIncapDMGBonus = CreateConVar("l4d2_hunter_incap_dmg_bonus", "2", "Extra multiply damage to the incapped survivor.");
	hCvarEnableHunter = CreateConVar("l4d2_enable_hunter_stagedmg", "1", "Set 1 to enable hunter do the stage dmg.");
	hCvarChargerDMGMaxStage = CreateConVar("l4d2_charger_dmg_maxstage", "4", "Maximum Stage of the DMG can be done.");
	hCvarChargerDMGPerStage = CreateConVar("l4d2_charger_dmg_perstage", "4", "For Each Stage the DMG added.");
	hCvarChargerClawDMGMaxStage = CreateConVar("l4d2_charger_claw_dmg_maxstage", "6", "Maximum Stage of the Claw DMG can be done.");
	hCvarChargerClawDMGPerStage = CreateConVar("l4d2_charger_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarEnableCharger = CreateConVar("l4d2_enable_charger_stagedmg", "1", "Set 1 to enable charger do the stage dmg.");
	hCvarSmokerDMGMaxStage = CreateConVar("l4d2_smoker_dmg_maxstage", "1", "Maximum Stage of the DMG can be done.");
	hCvarSmokerDMGPerStage = CreateConVar("l4d2_smoker_dmg_perstage", "1", "For Each Stage the DMG added.");
	hCvarSmokerDMGTimePerStage = CreateConVar("l4d2_smoker_dmg_time_perstage", "5", "How much time will the stage go on to the next one.");
	hCvarSmokerClawDMGMaxStage = CreateConVar("l4d2_smoker_claw_dmg_maxstage", "5", "Maximum Stage of the Claw DMG can be done.");
	hCvarSmokerClawDMGPerStage = CreateConVar("l4d2_smoker_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarSmokerIncapDMGBonus = CreateConVar("l4d2_smoker_incap_dmg_bonus", "3", "Extra multiply damage to the incapped survivor.");
	hCvarEnableSmoker = CreateConVar("l4d2_enable_smoker_stagedmg", "1", "Set 1 to enable smoker do the stage dmg.");
	hCvarBoomerClawDMGMaxStage = CreateConVar("l4d2_boomer_claw_dmg_maxstage", "4", "Maximum Stage of the Claw DMG can be done.");
	hCvarBoomerClawDMGPerStage = CreateConVar("l4d2_boomer_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarEnableBoomer = CreateConVar("l4d2_enable_boomer_stagedmg", "1", "Set 1 to enable boomer do the stage dmg.");
	hCvarSpitterClawDMGMaxStage = CreateConVar("l4d2_spitter_claw_dmg_maxstage", "4", "Maximum Stage of the Claw DMG can be done.");
	hCvarSpitterClawDMGPerStage = CreateConVar("l4d2_spitter_claw_dmg_perstage", "2", "For Each Stage the Claw DMG added.");
	hCvarEnableSpitter = CreateConVar("l4d2_enable_spitter_stagedmg", "1", "Set 1 to enable spitter do the stage dmg.");
	hCvarChargerDMG = CreateConVar("charger_dmg_pound", "10", "Special for charger pound dmg since original plugin may have bug.");
	hCvarChargerClawDMG = CreateConVar("charger_dmg_punch", "6", "Special for charger punch dmg since original plugin may have bug.");
	hCvarEnableShoveResetClawStage = CreateConVar("l4d2_enable_shove_reset", "1", "Set 1 the shove will reset the infected stage,Set 0 the shove will not reset the infected Claw stage.");

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
	HunterIncapDmgBonus = GetConVarFloat(hCvarHunterIncapDMGBonus);
	SmokerDmgMaxStage = GetConVarInt(hCvarSmokerDMGMaxStage);
	SmokerDmgPerStage = GetConVarInt(hCvarSmokerDMGPerStage);
	SmokerDmgTimePerStage = GetConVarFloat(hCvarSmokerDMGTimePerStage);
	SmokerClawDmgMaxStage = GetConVarInt(hCvarSmokerClawDMGMaxStage);
	SmokerClawDmgPerStage = GetConVarInt(hCvarSmokerClawDMGPerStage);
	SmokerIncapDmgBonus = GetConVarFloat(hCvarSmokerIncapDMGBonus);
	ChargerDmgMaxStage = GetConVarInt(hCvarChargerDMGMaxStage);
	ChargerDmgPerStage = GetConVarInt(hCvarChargerDMGPerStage);
	ChargerClawDmgMaxStage = GetConVarInt(hCvarChargerClawDMGMaxStage);
	ChargerClawDmgPerStage = GetConVarInt(hCvarChargerClawDMGPerStage);
	BoomerClawDmgMaxStage = GetConVarInt(hCvarBoomerClawDMGMaxStage);
	BoomerClawDmgPerStage = GetConVarInt(hCvarBoomerClawDMGPerStage);
	SpitterClawDmgMaxStage = GetConVarInt(hCvarSpitterClawDMGMaxStage);
	SpitterClawDmgPerStage = GetConVarInt(hCvarSpitterClawDMGPerStage);
	OriginHunterPounceDMG = FindConVar("z_pounce_damage");
	OriginHunterClawDMG = FindConVar("hunter_pz_claw_dmg");
	OriginJockeyRideDMG = FindConVar("z_jockey_ride_damage");
	OriginJockeyClawDMG = FindConVar("jockey_pz_claw_dmg");
	OriginSmokerDragDMG = FindConVar("tongue_choke_damage_amount");
	OriginSmokerClawDMG = FindConVar("smoker_pz_claw_dmg");
	OriginChargerPunchDMG = GetConVarInt(hCvarChargerDMG);
	OriginChargerClawDMG = GetConVarInt(hCvarChargerClawDMG);
	OriginBoomerClawDMG = FindConVar("boomer_pz_claw_dmg");
	OriginSpitterClawDMG = FindConVar("spitter_pz_claw_dmg");
}

public Action: Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
    for ( new i = 1; i <= MaxClients; i++ )
    {
                bCharged[i] = false;
		bPounced[i] = false;
                bRidden[i] = false;
		bDraged[i] = false;
		
		HunterStage[i] = 0;
		HunterStageClaw[i] = 0;
		ChargerStage[i] = 0;
		ChargerStageClaw[i] = 0;
		JockeyStage[i] = 0;
		JockeyStageClaw[i] = 0;
		SmokerStage[i] = 0;
		SmokerStageClaw[i] = 0;
		BoomerStageClaw[i] = 0;
		SpitterStageClaw[i] = 0;
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
	bShoved[client] = false;
	bGhost[client] = false;
}

public Action: Event_PounceEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId( GetEventInt(event, "userid") );
    
	bPounced[client] = false;
	HunterStage[client] = 0;
	StartHunterPounceTimer[client] = false;
}

public Action: Event_ChargePummelStart( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt(event, "userid") );
    new victim = GetClientOfUserId( GetEventInt(event, "victim") );
    if ( !IS_VALID_INFECTED(client) ) { return; }
    
    if ( !IS_VALID_SURVIVOR(victim) ) { return; }
    
    bCharged[client] = true;
}

public Action: Event_ChargePummelEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId( GetEventInt(event, "userid") );

        bCharged[client] = false;
	ChargerStage[client] = 0;
}

public Action: Event_JockeyRide( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId( GetEventInt(event, "userid") );
  
        bRidden[client] = true;
	bShoved[client] = false;
	bGhost[client] = false;
}

public Action: Event_JockeyRideEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId( GetEventInt(event, "userid") );
  
        bRidden[client] = false;
	JockeyStage[client] = 0;
	StartJockeyRideTimer[client] = false;
}

public OnTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	bDraged[client] = true;
	bShoved[client] = false;
	bGhost[client] = false;
}

public Event_TonguePullStopped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "smoker"));
	
	bDraged[client] = false;
	StartSmokerDragTimer[client] = false;
	SmokerStage[client] = 0;
}

public Action: Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bPounced[client] = false;
        bRidden[client] = false;
	bDraged[client] = false;
	bShoved[client] = false;
	bGhost[client] = false;
	StartHunterPounceTimer[client] = false;
	StartJockeyRideTimer[client] = false;
	StartSmokerDragTimer[client] = false;
    
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
	if (GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_CHARGER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_HUNTER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_JOCKEY && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_BOOMER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_SMOKER && GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_SPITTER) { return Plugin_Continue; }
	
	// only check tank punch/rock and SI claws (also rules out anything but infected-to-survivor damage)
	new TankOrSIWeapon: inflictorID;
	if (!GetTrieValue(hInflictorTrie, classname, inflictorID)) { return Plugin_Continue; }
	if (inflictorID != CHARGERWEAPON && inflictorID != BOOMERWEAPON && inflictorID != HUNTERWEAPON && inflictorID != JOCKEYWEAPON && inflictorID != SMOKERWEAPON && inflictorID != SPITTERWEAPON) { return Plugin_Continue; }
	
	if ( inflictorID == HUNTERWEAPON)
	{
	        if (GetConVarInt(hCvarEnableHunter) == 0) return Plugin_Continue;

	        if (bPounced[attacker] == true)
		{
		        //PrintToChatAll("It's A Hunter Pouncing."); //DEBUG
			bGhost[attacker] = false;
			bShoved[attacker] = false;
			float OHPDMG = GetConVarFloat(OriginHunterPounceDMG);
			float StageDMG = float(HunterStage[attacker] * HunterDmgPerStage);
			float multiply = HunterIncapDmgBonus;
			if (IsIncapped(victim) == true)
			{
			    damage = (OHPDMG + StageDMG) * multiply; //Extra DMG Done TO Incapped Survivor.
			} 
			else
			{
		            damage = OHPDMG + StageDMG; //DMG Done TO Survivor.
			}
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
			float oridamage = damage;
			float OHCDMG = GetConVarFloat(OriginHunterClawDMG);
			float StageDMG = float(HunterStageClaw[attacker] * HunterClawDmgPerStage);
			if (oridamage >= OHCDMG + StageDMG) //Like HunterPouncing
			{
			    damage = oridamage;
			}
			else
			{
			    damage = OHCDMG + StageDMG; //DMG Done TO Survivor.
			}
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
	        if (GetConVarInt(hCvarEnableJockey) == 0) return Plugin_Continue;

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
			float oridamage = damage;
			float OJCDMG = GetConVarFloat(OriginJockeyClawDMG);
			float StageDMG = float(JockeyStageClaw[attacker] * JockeyClawDmgPerStage);
			if (oridamage >= OJCDMG + StageDMG) //Like JockeyPouncing
			{
			    damage = oridamage;
			}
			else
			{
			    damage = OJCDMG + StageDMG; //DMG Done TO Survivor.
			}
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
	else if ( inflictorID == SMOKERWEAPON)
	{
	        if (GetConVarInt(hCvarEnableSmoker) == 0) return Plugin_Continue;

	        if (bDraged[attacker] == true)
		{
		        //PrintToChatAll("It's A Smoker Draging."); //DEBUG
			bGhost[attacker] = false;
			bShoved[attacker] = false;
			float OHPDMG = GetConVarFloat(OriginSmokerDragDMG);
			float StageDMG = float(SmokerStage[attacker] * SmokerDmgPerStage);
			float multiply = SmokerIncapDmgBonus;
			if (IsIncapped(victim) == true)
			{
			    damage = (OHPDMG + StageDMG) * multiply; //Extra DMG Done TO Incapped Survivor.
			}
			else
			{
		            damage = OHPDMG + StageDMG; //DMG Done TO Survivor.
			}
			//PrintToChatAll("Smoker DMG Survivor For %.1f% damage, Stage %i.", damage, SmokerStage[attacker]); //DEBUG
			if (StartSmokerDragTimer[attacker] == false)
			{
			        StartSmokerDragTimer[attacker] = true;
				CreateTimer(SmokerDmgTimePerStage,SmokerStageIncrease,GetClientUserId(attacker),TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				//PrintToChatAll("The Smoker Timer is going on."); //DEBUG
			}
			return Plugin_Changed;
		}
		else
		{
		        //PrintToChatAll("It's A Smoker Claw."); //DEBUG
			float OHCDMG = GetConVarFloat(OriginSmokerClawDMG);
			float StageDMG = float(SmokerStageClaw[attacker] * SmokerClawDmgPerStage);
			damage = OHCDMG + StageDMG; //DMG Done TO Survivor.
			//PrintToChatAll("Smoker DMG Survivor For %.1f% damage, Stage %i.", damage, SmokerStageClaw[attacker]); //DEBUG
			SmokerStageClaw[attacker] += 1;
			if (SmokerStageClaw[attacker] > SmokerClawDmgMaxStage)
			{
			        SmokerStageClaw[attacker] = SmokerClawDmgMaxStage;
				//PrintToChatAll("Smoker Claw DMG has got to it Max Stage."); //DEBUG
			}
			return Plugin_Changed;
		}
	}
	else if (inflictorID == CHARGERWEAPON)
	{
	        if (GetConVarInt(hCvarEnableCharger) == 0) return Plugin_Continue;

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
			if (OCCDMG == 2.0)
			{
			    damage = OCCDMG; //It's a charger stumble
			}
			else
			{
			    damage = OCCDMG + StageDMG; //DMG Done TO Survivor.
			}
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
	        if (GetConVarInt(hCvarEnableBoomer) == 0) return Plugin_Continue;

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
	else if (inflictorID == SPITTERWEAPON)
	{
	        if (GetConVarInt(hCvarEnableSpitter) == 0) return Plugin_Continue;

	        //PrintToChatAll("It's A Spitter Claw."); //DEBUG
		float OBCDMG = GetConVarFloat(OriginSpitterClawDMG);
		float StageDMG = float(SpitterStageClaw[attacker] * SpitterClawDmgPerStage);
		damage = OBCDMG + StageDMG; //DMG Done TO Survivor.
		//PrintToChatAll("Spitter DMG Survivor For %.1f% damage, Stage %i.", damage, SpitterStageClaw[attacker]); //DEBUG
		SpitterStageClaw[attacker] += 1;
		if (SpitterStageClaw[attacker] > SpitterClawDmgMaxStage)
		{
		        SpitterStageClaw[attacker] = SpitterClawDmgMaxStage;
			//PrintToChatAll("Spitter Claw DMG has got to it Max Stage."); //DEBUG
		}
		return Plugin_Changed;
	}
	return Plugin_Handled;
}
 
public Action:HunterStageIncrease(Handle:timer,any:userid)
{
	new Client = GetClientOfUserId(userid);
	if(!IsPlayerAlive(Client) || bShoved[Client] == true || bGhost[Client] == true || bPounced[Client] == false) 
	{
	        HunterStage[Client] = 0;
		//PrintToChatAll("Reset Hunter Pouncing Stage."); //DEBUG
		StartHunterPounceTimer[Client] = false;
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
	if(!IsPlayerAlive(Client) || bShoved[Client] == true || bGhost[Client] == true || bRidden[Client] == false) 
	{
	        JockeyStage[Client] = 0;
		//PrintToChatAll("Reset Jockey Riding Stage."); //DEBUG
		StartJockeyRideTimer[Client] = false;
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

public Action:SmokerStageIncrease(Handle:timer,any:userid)
{
	new Client = GetClientOfUserId(userid);
	if(!IsPlayerAlive(Client) || bShoved[Client] == true || bGhost[Client] == true || bDraged[Client] == false) 
	{
	        SmokerStage[Client] = 0;
		//PrintToChatAll("Reset Smoker Draging Stage."); //DEBUG
		StartSmokerDragTimer[Client] = false;
	        return Plugin_Stop;
	}
	SmokerStage[Client]++;
	if (SmokerStage[Client] > SmokerDmgMaxStage)
	{
	        SmokerStage[Client] = SmokerDmgMaxStage;
		//PrintToChatAll("Smoker Draging DMG has got to it Max Stage."); //DEBUG
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
    SetTrieValue(trie, "weapon_smoker_claw",    SMOKERWEAPON);
    SetTrieValue(trie, "weapon_spitter_claw",   SPITTERWEAPON);
    return trie;    
}

public L4D_OnEnterGhostState(client)
{
        bGhost[client] = true;
	bShoved[client] = false;
	bPounced[client] = false;
	bRidden[client] = false;
	bCharged[client] = false;
	bDraged[client] = false;
	HunterStage[client] = 0;
	JockeyStage[client] = 0;
	ChargerStage[client] = 0;
	HunterStageClaw[client] = 0;
	JockeyStageClaw[client] = 0;
	ChargerStageClaw[client] = 0;
	SmokerStageClaw[client] = 0;
	BoomerStageClaw[client] = 0;
	SpitterStageClaw[client] = 0;
	StartHunterPounceTimer[client] = false;
	StartJockeyRideTimer[client] = false;
	StartSmokerDragTimer[client] = false;
	//PrintToChatAll("Enter Ghost State,reset the stage."); //DEBUG
}

public Action: Event_PlayerShoved( Handle:event, const String:name[], bool:dontBroadcast )
{
        new victim = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
        if ( !IS_VALID_SURVIVOR(attacker) || !IS_VALID_INFECTED(victim) || GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_CHARGER) { return Plugin_Continue; }
        bShoved[victim] = true;
	bPounced[victim] = false;
	bRidden[victim] = false;
	bCharged[victim] = false;
	bDraged[victim] = false;
	HunterStage[victim] = 0;
	JockeyStage[victim] = 0;
	ChargerStage[victim] = 0;
	if ( GetConVarInt(hCvarEnableShoveResetClawStage) >= 1)
	{
	        HunterStageClaw[victim] = 0;
	        JockeyStageClaw[victim] = 0;
	        ChargerStageClaw[victim] = 0;
		SmokerStageClaw[victim] = 0;
	        BoomerStageClaw[victim] = 0;
	        SpitterStageClaw[victim] = 0;
	}
	StartHunterPounceTimer[victim] = false;
	StartJockeyRideTimer[victim] = false;
	StartSmokerDragTimer[victim] = false;
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
		bDraged[victim] = false;
	        HunterStage[victim] = 0;
	        JockeyStage[victim] = 0;
	        ChargerStage[victim] = 0;
	        HunterStageClaw[victim] = 0;
	        JockeyStageClaw[victim] = 0;
	        ChargerStageClaw[victim] = 0;
		SmokerStageClaw[victim] = 0;
	        BoomerStageClaw[victim] = 0;
		SpitterStageClaw[victim] = 0;
		StartHunterPounceTimer[victim] = false;
	        StartJockeyRideTimer[victim] = false;
		StartSmokerDragTimer[victim] = false;
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


bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}