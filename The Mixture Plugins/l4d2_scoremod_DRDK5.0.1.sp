#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2lib>

#define CLAMP(%0,%1,%2) (((%0) > (%2)) ? (%2) : (((%0) < (%1)) ? (%1) : (%0)))

#define PLUGIN_TAG "" // \x04[Air Bonus]

#define SM2_DEBUG    0

/** 
	Bibliography:
	'l4d2_scoremod' by CanadaRox, ProdigySim
	'damage_bonus' by CanadaRox, Stabby
	'l4d2_scoringwip' by ProdigySim
	'srs.scoringsystem' by AtomicStryker
**/

new Handle:hCvarBonusPerSurvivorMultiplier;
new Handle:hCvarPermanentHealthProportion;
new Handle:hCvarPillsHpFactor;
new Handle:hCvarPillsMaxBonus;
new Handle:hCvarPillsBonusFactor;
new Handle:hCvarMedHpFactor;
new Handle:hCvarMedMaxBonus;
new Handle:hCvarMedBonusFactor;
new Handle:hCvarThrowFactor;
new Handle:hCvarMaxThrowBonus;
new Handle:hCvarThrowBonusFactor;
new Handle:hCvarTempWorth;
new Handle:hCvarPermWorth;
// new Handle:hCvarPRBonusFactor;
// new Handle:hCvarTiebreakerBonus;

new Handle:hCvarValveSurvivalBonus;
new Handle:hCvarValveTieBreaker;

new Float:fMapBonus;
new Float:fMapHealthBonus;
new Float:fMapDamageBonus;
new Float:fMapTempHealthBonus;
new Float:fPermHpWorth;
new Float:fTempHpWorth;
new Float:fPRBonus;
new Float:fSurvivorBonus[2];

new iMapDistance;
new iTeamSize;
new iPillWorth;
new iMedWorth;
new iThrowWorth;
new iPRWorth;
new iLostTempHealth[2];
new iTempHealth[MAXPLAYERS + 1];
new iSiDamage[2];

new String:sSurvivorState[2][32];

new bool:bLateLoad;
new bool:bRoundOver;
new bool:bTiebreakerEligibility[2];

public Plugin:myinfo =
{
	name = "L4D2 Scoremod+++",
	author = "Visor",
	description = "The next generation scoring mod",
	version = "2.2.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	bLateLoad = late;
	return APLRes_Success;
}

public __pl_mapinfo_SetNTVOptional()
{
    MarkNativeAsOptional("MI_GetMapValueInt");
    MarkNativeAsOptional("MI_GetMapValueFloat");
    MarkNativeAsOptional("MI_GetMapValueVector");
    MarkNativeAsOptional("MI_GetMapValueString");
    MarkNativeAsOptional("MI_CopyMapSubsection");
    MarkNativeAsOptional("MI_IsEntityInStartSaferoom");
    MarkNativeAsOptional("MI_IsEntityInEndSaferoom");
    MarkNativeAsOptional("MI_IsPlayerInStartSaferoom");
    MarkNativeAsOptional("MI_IsPlayerInEndSaferoom");
    return 0;
}

public OnPluginStart()
{
	hCvarBonusPerSurvivorMultiplier = CreateConVar("sm2_bonus_per_survivor_multiplier", "0.6", "Total Survivor Bonus = this * Number of Survivors * Map Distance", FCVAR_PLUGIN);
	hCvarPermanentHealthProportion = CreateConVar("sm2_permament_health_proportion", "0.77", "Permanent Health Bonus = this * Map Bonus; rest goes for Temporary Health Bonus", FCVAR_PLUGIN);
	hCvarPillsHpFactor = CreateConVar("sm2_pills_hp_factor", "1.0", "Unused pills HP worth = map bonus HP value / this", FCVAR_PLUGIN);
	hCvarPillsMaxBonus = CreateConVar("sm2_pills_max_bonus", "200", "Unused pills cannot be worth more than this", FCVAR_PLUGIN);
	hCvarPillsBonusFactor = CreateConVar("sm2_pills_bonus_factor", "50", "Unused pills cannot be worth more than this", FCVAR_PLUGIN);
	hCvarMedHpFactor = CreateConVar("sm2_med_hp_factor", "1.0", "Unused Med HP worth = map bonus HP value / this", FCVAR_PLUGIN);
	hCvarMedMaxBonus = CreateConVar("sm2_med_max_bonus", "300", "Unused Med cannot be worth more than this", FCVAR_PLUGIN);
	hCvarMedBonusFactor = CreateConVar("sm2_med_bonus_factor", "100", "Unused Med cannot be worth more than this", FCVAR_PLUGIN);
	hCvarThrowFactor = CreateConVar("sm2_throw_factor", "1", "Unused Throwable HP worth = map bonus HP value / this", FCVAR_PLUGIN);
	hCvarMaxThrowBonus = CreateConVar("sm2_throw_max_bonus", "100", "Unused Throwable cannot be worth more than this", FCVAR_PLUGIN);
	hCvarThrowBonusFactor = CreateConVar("sm2_throw_bonus_factor", "20", "Unused Throwable cannot be worth more than this", FCVAR_PLUGIN);
	hCvarTempWorth = CreateConVar("sm2_temp_worth", "2", "Unused Throwable cannot be worth more than this", FCVAR_PLUGIN);
	hCvarPermWorth = CreateConVar("sm2_perm_worth", "1.5", "Unused Throwable cannot be worth more than this", FCVAR_PLUGIN);
	// hCvarPRBonusFactor = CreateConVar("sm2_pr_bonus_factor", "1", "Perfect Round Bonus Factor", FCVAR_PLUGIN);
	// hCvarTiebreakerBonus = CreateConVar("sm2_tiebreaker_bonus", "25", "Tiebreaker for those cases when both teams make saferoom with no bonus", FCVAR_PLUGIN);
	
	hCvarValveSurvivalBonus = FindConVar("vs_survival_bonus");
	hCvarValveTieBreaker = FindConVar("vs_tiebreak_bonus");

	HookConVarChange(hCvarBonusPerSurvivorMultiplier, CvarChanged);
	HookConVarChange(hCvarPermanentHealthProportion, CvarChanged);

	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab", OnPlayerLedgeGrab);

	RegConsoleCmd("sm_health", CmdBonus);
	RegConsoleCmd("sm_damage", CmdBonus);
	RegConsoleCmd("sm_bonus", CmdBonus);
	RegConsoleCmd("sm_mapinfo", CmdMapInfo);

	if (bLateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i))
				continue;

			OnClientPutInServer(i);
		}
	}
}

public OnPluginEnd()
{
	ResetConVar(hCvarValveSurvivalBonus);
	ResetConVar(hCvarValveTieBreaker);
}

public OnConfigsExecuted()
{
	iTeamSize = GetConVarInt(FindConVar("survivor_limit"));
	SetConVarInt(hCvarValveTieBreaker, 0);

	iMapDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
	L4D_SetVersusMaxCompletionScore(iMapDistance);

	new Float:fPermHealthProportion = GetConVarFloat(hCvarPermanentHealthProportion);
	new Float:fTempHealthProportion = 1.0 - fPermHealthProportion;
	fMapBonus = iMapDistance * (GetConVarFloat(hCvarBonusPerSurvivorMultiplier) * iTeamSize);
	fMapHealthBonus = fMapBonus * fPermHealthProportion;
	fMapDamageBonus = fMapBonus * fTempHealthProportion;
	fMapTempHealthBonus = iTeamSize * 100/* HP */ / fPermHealthProportion * fTempHealthProportion;
	fPermHpWorth = fMapBonus / iTeamSize / 100 * fPermHealthProportion;
	fTempHpWorth = fMapBonus * fTempHealthProportion / fMapTempHealthBonus; // this should be almost equal to the perm hp worth, but for accuracy we'll keep it separate
	iPillWorth = CLAMP(RoundToNearest(GetConVarFloat(hCvarPillsBonusFactor) * (fPermHpWorth / GetConVarFloat(hCvarPillsHpFactor))), 1, GetConVarInt(hCvarPillsMaxBonus)); // make it pretty
        iMedWorth = CLAMP(RoundToNearest(GetConVarFloat(hCvarMedBonusFactor) * (fPermHpWorth / GetConVarFloat(hCvarMedHpFactor))), 1, GetConVarInt(hCvarMedMaxBonus)); // make it pretty
	iThrowWorth = CLAMP(RoundToNearest(GetConVarFloat(hCvarThrowBonusFactor) * (fPermHpWorth / GetConVarFloat(hCvarThrowFactor))), 1, GetConVarInt(hCvarMaxThrowBonus)); // make it pretty
	iPRWorth = (RoundToFloor(fMapHealthBonus));

#if SM2_DEBUG
	PrintToChatAll("\x01Map health bonus: \x05%.1f\x01, temp health bonus: \x05%.1f\x01, perm hp worth: \x03%.1f\x01, temp hp worth: \x03%.1f\x01, pill worth: \x03%i\x01, Med worth: \x03%i\x01, Throw worth: \x03%i\x01", fMapBonus, fMapTempHealthBonus, fPermHpWorth, fTempHpWorth, iPillWorth, iMedWorth, iThrowWorth);
#endif
}

public OnMapStart()
{
	OnConfigsExecuted();

	iLostTempHealth[0] = 0;
	iLostTempHealth[1] = 0;
	iSiDamage[0] = 0;
	iSiDamage[1] = 0;
	bTiebreakerEligibility[0] = false;
	bTiebreakerEligibility[1] = false;
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnConfigsExecuted();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnRoundStart()
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		iTempHealth[i] = 0;
	}
	bRoundOver = false;
}

public Action:CmdBonus(client, args)
{
	if (bRoundOver || !client)
		return Plugin_Handled;

	decl String:sCmdType[64];
	GetCmdArg(1, sCmdType, sizeof(sCmdType));

	new Float:fHealthBonus = GetSurvivorHealthBonus();
	new Float:fDamageBonus = GetSurvivorDamageBonus();
	new Float:fPillsBonus = GetSurvivorPillBonus();
	new Float:fMaxPillsBonus = float(iPillWorth * iTeamSize);
	new Float:fMedBonus = GetSurvivorMedBonus();
	new Float:fMaxMedBonus = float(iMedWorth * iTeamSize);
	new Float:fThrowBonus = GetSurvivorThrowBonus();
	new Float:fMaxThrowBonus = float(iThrowWorth * iTeamSize);
	new Float:fPRBonus = GetSurvivorPRBonus();
	
	if (StrEqual(sCmdType, "full"))
	{
		if (InSecondHalfOfRound())
		{
			PrintToChat(client, "%s\x01R\x04#1\x01 得分: \x05%d\x01/\x05%d\x01 <\x03%.1f%%\x01> [%s]", PLUGIN_TAG, RoundToFloor(fSurvivorBonus[0]), RoundToFloor(fMapBonus + fMaxPillsBonus), RoundToFloor(fMapBonus + fMaxMedBonus), RoundToFloor(fMapBonus + fMaxThrowBonus), CalculateBonusPercent(fSurvivorBonus[0]), sSurvivorState[0]);
		}
		PrintToChat(client, "%s\x01R\x04#%i\x01 得分: \x05%d\x01 <\x03%.1f%%\x01> [血量: \x05%d\x01 <\x03%.1f%%\x01> | 伤害: \x05%d\x01 <\x03%.1f%%\x01> | 药: \x05%d\x01 <\x03%.1f%%\x01> | 包: \x05%d\x01 <\x03%.1f%%\x01>| 投掷: \x05%d\x01 <\x03%.1f%%\x01>]", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus, fMapHealthBonus + fMapDamageBonus + fMaxPillsBonus + fMaxMedBonus + fMaxThrowBonus), RoundToFloor(fHealthBonus), CalculateBonusPercent(fHealthBonus, fMapHealthBonus), RoundToFloor(fDamageBonus), CalculateBonusPercent(fDamageBonus, fMapDamageBonus), RoundToFloor(fPillsBonus), CalculateBonusPercent(fPillsBonus, fMaxPillsBonus), RoundToFloor(fMedBonus), CalculateBonusPercent(fMedBonus, fMaxMedBonus), RoundToFloor(fThrowBonus), CalculateBonusPercent(fThrowBonus, fMaxThrowBonus));
		PrintToChat(client, "%s\x01R\x04#%i\x01 完美通关分: \x05%d\x01", PLUGIN_TAG, RoundToFloor(fPRBonus)); 
		// R#1 Bonus: 556 <69.5%> [HB: 439 <73.1%> | DB: 117 <58.5%> | Pills: 90 <75.0%> | Med: 120 <25.0%>]
	}
	else if (StrEqual(sCmdType, "lite"))
	{
		PrintToChat(client, "%s\x01R\x04#%i\x01 得分: \x05%d\x01 <\x03%.1f%%\x01>", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus, fMapHealthBonus + fMapDamageBonus + fMaxPillsBonus + fMaxMedBonus + fMaxThrowBonus));
		PrintToChat(client, "%s\x01R\x04#%i\x01 完美通关分: \x05%d\x01", PLUGIN_TAG, RoundToFloor(fPRBonus)); 
		// R#1 Bonus: 556 <69.5%>
	}
	else
	{
		if (InSecondHalfOfRound())
		{
			PrintToChat(client, "%s\x01R\x04#1\x01 得分: \x05%d\x01 <\x03%.1f%%\x01>", PLUGIN_TAG, RoundToFloor(fSurvivorBonus[0]), CalculateBonusPercent(fSurvivorBonus[0]));
		}
		PrintToChat(client, "%s\x01R\x04#%i\x01 得分: \x05%d\x01 <\x03%.1f%%\x01> [血量: \x03%.0f%%\x01 | 伤害: \x03%.0f%%\x01 | 药: \x03%.0f%%\x01 | 包: \x03%.0f%%\x01| 投掷: \x03%.0f%%\x01]", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPillsBonus + fMedBonus + fThrowBonus, fMapHealthBonus + fMapDamageBonus + fMaxPillsBonus + fMaxMedBonus + fMaxThrowBonus), CalculateBonusPercent(fHealthBonus, fMapHealthBonus), CalculateBonusPercent(fDamageBonus, fMapDamageBonus), CalculateBonusPercent(fPillsBonus, fMaxPillsBonus), CalculateBonusPercent(fMedBonus, fMaxMedBonus), CalculateBonusPercent(fThrowBonus, fMaxThrowBonus));
		PrintToChat(client, "%s\x01R\x04#%i\x01 完美通关分: \x05%d\x01", PLUGIN_TAG, RoundToFloor(fPRBonus)); 
		// R#1 Bonus: 556 <69.5%> [HB: 73% | DB: 58% | Pills: 75% | Med: 25% ]
	}
	return Plugin_Handled;
}

public Action:CmdMapInfo(client, args)
{
	new Float:fMaxPillsBonus = float(iPillWorth * iTeamSize);
	new Float:fMaxMedBonus = float(iMedWorth * iTeamSize);
	new Float:fMaxThrowBonus = float(iThrowWorth * iTeamSize);
	new Float:fTotalBonus = fMapBonus + fMaxPillsBonus + fMaxMedBonus;
	PrintToChat(client, "\x01[\x04Air Bonus\x01 :: \x03%iv%i\x01] 地图设置", iTeamSize, iTeamSize);
	PrintToChat(client, "\x01路程: \x05%d\x01", iMapDistance);
	PrintToChat(client, "\x01总分: \x05%d\x01 <\x03100.0%%\x01>", RoundToFloor(fTotalBonus));
	PrintToChat(client, "\x01血分: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapHealthBonus), CalculateBonusPercent(fMapHealthBonus, fTotalBonus));
	PrintToChat(client, "\x01伤害分: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapDamageBonus), CalculateBonusPercent(fMapDamageBonus, fTotalBonus));
	PrintToChat(client, "\x01药分: \x05%d\x01(最高 \x05%d\x01) <\x03%.1f%%\x01>", iPillWorth, RoundToFloor(fMaxPillsBonus), CalculateBonusPercent(fMaxPillsBonus, fTotalBonus));
	PrintToChat(client, "\x01包分: \x05%d\x01(最高 \x05%d\x01) <\x03%.1f%%\x01>", iMedWorth, RoundToFloor(fMaxMedBonus), CalculateBonusPercent(fMaxMedBonus, fTotalBonus));
	PrintToChat(client, "\x01投掷分: \x05%d\x01(最高 \x05%d\x01) <\x03%.1f%%\x01>", iThrowWorth, RoundToFloor(fMaxThrowBonus), CalculateBonusPercent(fMaxThrowBonus, fTotalBonus));
	PrintToChat(client, "\x01完美通关分: \x05%d\x01", iPRWorth);
	PrintToChat(client, "\x01破平分: \x05%d\x01", iPillWorth);
	// [ScoreMod 2 :: 4v4] Map Info
	// Distance: 400
	// Bonus: 1400 <100.0%>
	// Health Bonus: 600 <65.2%>
	// Damage Bonus: 200 <21.7%>
	// Pills Bonus: 30(max 120) <13.1%>
	// Med Bonus: 120(max 480) <13.1%>
	// Tiebreaker: 30
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsSurvivor(victim) || IsPlayerIncap(victim))
		return Plugin_Continue;

#if SM2_DEBUG
	if (GetSurvivorTemporaryHealth(victim) > 0) PrintToChatAll("\x04%N\x01 has \x05%d\x01 temp HP now(damage: \x03%.1f\x01)", victim, GetSurvivorTemporaryHealth(victim), damage);
#endif
	iTempHealth[victim] = GetSurvivorTemporaryHealth(victim);
	
	// Small failsafe/workaround for stuff that inflicts more than 100 HP damage (like tank hittables); we don't want to reward that more than it's worth
	iSiDamage[InSecondHalfOfRound()] += (damage <= 100.0 ? RoundFloat(damage) : 100);
	
	return Plugin_Continue;
}

public OnPlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	iLostTempHealth[InSecondHalfOfRound()] += L4D2Direct_GetPreIncapHealthBuffer(client);
}

public Action:L4D2_OnRevived(client)
{
	iLostTempHealth[InSecondHalfOfRound()] -= GetSurvivorTemporaryHealth(client);
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!IsSurvivor(victim))
		return;
		
#if SM2_DEBUG
	PrintToChatAll("\x03%N\x01\x05 lost %i\x01 temp HP after being attacked(arg damage: \x03%.1f\x01)", victim, iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTemporaryHealth(victim) : 0), damage);
#endif
	if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerLedged(victim)))
	{
		iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim];
	}
	else if (!IsPlayerLedged(victim))
	{
		iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim] ? (iTempHealth[victim] - GetSurvivorTemporaryHealth(victim)) : 0;
	}
	iTempHealth[victim] = IsPlayerIncap(victim) ? 0 : GetSurvivorTemporaryHealth(victim);
}

// Compatibility with Alternate Damage Mechanics plugin
// This plugin(i.e. Scoremod2) will work ideally fine with or without the aforementioned plugin
public L4D2_ADM_OnTemporaryHealthSubtracted(client, oldHealth, newHealth)
{
	new healthLost = oldHealth - newHealth;
	iTempHealth[client] = newHealth;
	iLostTempHealth[InSecondHalfOfRound()] += healthLost;
	iSiDamage[InSecondHalfOfRound()] += healthLost; // this forward doesn't fire for ledged/incapped survivors so we're good
}

public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
#if SM2_DEBUG
	PrintToChatAll("CDirector::OnEndVersusModeRound() called. InSecondHalfOfRound(): %d, countSurvivors: %d", InSecondHalfOfRound(), countSurvivors);
#endif
	if (bRoundOver)
		return Plugin_Continue;

	new team = InSecondHalfOfRound();
	new iSurvivalMultiplier = GetUprightSurvivors();    // I don't know how reliable countSurvivors is and I'm too lazy to test
	fSurvivorBonus[team] = GetSurvivorHealthBonus() + GetSurvivorDamageBonus() + GetSurvivorPillBonus() + GetSurvivorMedBonus() + GetSurvivorThrowBonus() +GetSurvivorPRBonus();
	fSurvivorBonus[team] = float(RoundToFloor(fSurvivorBonus[team] / float(iTeamSize)) * iTeamSize); // make it a perfect divisor of team size value
	if (iSurvivalMultiplier > 0 && RoundToFloor(fSurvivorBonus[team] / iSurvivalMultiplier) >= iTeamSize) // anything lower than team size will result in 0 after division
	{
		SetConVarInt(hCvarValveSurvivalBonus, RoundToFloor(fSurvivorBonus[team] / iSurvivalMultiplier));
		fSurvivorBonus[team] = float(GetConVarInt(hCvarValveSurvivalBonus) * iSurvivalMultiplier);    // workaround for the discrepancy caused by RoundToFloor()
		Format(sSurvivorState[team], 32, "%s%i\x01/\x05%i\x01", (iSurvivalMultiplier == iTeamSize ? "\x05" : "\x04"), iSurvivalMultiplier, iTeamSize);
	#if SM2_DEBUG
		PrintToChatAll("\x01Survival bonus cvar updated. Value: \x05%i\x01 [multiplier: \x05%i\x01]", GetConVarInt(hCvarValveSurvivalBonus), iSurvivalMultiplier);
	#endif
	}
	else
	{
		fSurvivorBonus[team] = 0.0;
		SetConVarInt(hCvarValveSurvivalBonus, 0);
		Format(sSurvivorState[team], 32, "\x04%s\x01", (iSurvivalMultiplier == 0 ? "途中去世" : "没有得分"));
		bTiebreakerEligibility[team] = (iSurvivalMultiplier == iTeamSize);
	}

	// Check if it's the end of the second round and a tiebreaker case
	if (team > 0 && bTiebreakerEligibility[0] && bTiebreakerEligibility[1])
	{
		GameRules_SetProp("m_iChapterDamage", iSiDamage[0], _, 0, true);
		GameRules_SetProp("m_iChapterDamage", iSiDamage[1], _, 1, true);
		
		// That would be pretty funny otherwise
		if (iSiDamage[0] != iSiDamage[1])
		{
			SetConVarInt(hCvarValveTieBreaker, iPillWorth);
		}
	}
	
	// Scores print
	CreateTimer(3.0, PrintRoundEndStats, _, TIMER_FLAG_NO_MAPCHANGE);

	bRoundOver = true;
	return Plugin_Continue;
}

public Action:PrintRoundEndStats(Handle:timer) 
{
	for (new i = 0; i <= InSecondHalfOfRound(); i++)
	{
		PrintToChatAll("%s\x01本局轮数 \x04%i\x01 得分: \x05%d\x01/\x05%d\x01 <\x03%.1f%%\x01> [%s]", PLUGIN_TAG, (i + 1), RoundToFloor(fSurvivorBonus[i]), RoundToFloor(fMapBonus + float(iPillWorth * iTeamSize) + float(iMedWorth * iTeamSize) + float(iThrowWorth * iTeamSize)), CalculateBonusPercent(fSurvivorBonus[i]), sSurvivorState[i]);
		// [EQSM :: Round 1] Bonus: 487/1200 <42.7%> [3/4]
		// 本局完美通关分: 200
	}
	
	if (InSecondHalfOfRound() && bTiebreakerEligibility[0] && bTiebreakerEligibility[1])
	{
		PrintToChatAll("%s\x03TIEBREAKER\x01: Team \x04%#1\x01 - \x05%i\x01, Team \x04%#2\x01 - \x05%i\x01", PLUGIN_TAG, iSiDamage[0], iSiDamage[1]);
		if (iSiDamage[0] == iSiDamage[1])
		{
			PrintToChatAll("%s\x05Teams have performed absolutely equal! Impossible to decide a clear round winner", PLUGIN_TAG);
		}
	}
}

Float:GetSurvivorHealthBonus()
{
	new Float:fHealthBonus;
	new survivorCount;
	new survivalMultiplier;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
			{
				survivalMultiplier++;
				fHealthBonus += GetSurvivorPermanentHealth(i) * fPermHpWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 perm hp bonus contribution: \x05%d\x01 perm HP -> \x03%.1f\x01 bonus; new total: \x05%.1f\x01", i, GetSurvivorPermanentHealth(i), GetSurvivorPermanentHealth(i) * fPermHpWorth, fHealthBonus);
			#endif
			}
		}
	}
	return (fHealthBonus / iTeamSize * survivalMultiplier);
}

Float:GetSurvivorDamageBonus()
{
	new survivalMultiplier = GetUprightSurvivors();
	new Float:fDamageBonus = (fMapTempHealthBonus - float(iLostTempHealth[InSecondHalfOfRound()]) * GetConVarFloat(hCvarTempWorth) - float(iSiDamage[InSecondHalfOfRound()]) * GetConVarFloat(hCvarPermWorth)) * fTempHpWorth / iTeamSize * survivalMultiplier;
#if SM2_DEBUG
	PrintToChatAll("\x01Adding temp hp bonus: \x05%.1f\x01 (eligible survivors: \x05%d\x01)", fDamageBonus, survivalMultiplier);
#endif
	return (fDamageBonus > 0.0 && survivalMultiplier > 0) ? fDamageBonus : 0.0;
}


Float:GetSurvivorPRBonus()
{			
	new PRBonus;
	new survivors_incapped = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		//Ingame, survivor and alive?
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			//incapped and final?
			if (IsPlayerIncap(i))
			{
				survivors_incapped += 1;
			}
		}
	}
	return (PRBonus > 0.0) ? PRBonus : 0.0;
}

Float:GetSurvivorPillBonus()
{			
	new pillsBonus;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && HasPills(i))
			{
				pillsBonus += iPillWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 pills contribution, total bonus: \x05%d\x01 pts", i, pillsBonus);
			#endif
			}
			if (IsPlayerAlive(i) && HasAdrenaline(i))
			{
			    pillsBonus += iPillWorth / 2;
			}
		}
	}
	return Float:float(pillsBonus);
}

Float:GetSurvivorMedBonus()
{			
	new MedBonus;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && HasMed(i))
			{
				MedBonus += iMedWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 Med contribution, total bonus: \x05%d\x01 pts", i, MedBonus);
			#endif
			}
		}
	}
	return Float:float(MedBonus);
}

Float:GetSurvivorThrowBonus()
{			
	new ThrowBonus;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && HasBile(i))
			{
				ThrowBonus += iThrowWorth * 3;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 Throw contribution, total bonus: \x05%d\x01 pts", i, MedBonus);
			#endif
			}
			if (IsPlayerAlive(i) && HasMolo(i))
			{
			    ThrowBonus += iThrowWorth;
			}
			if (IsPlayerAlive(i) && HasPipe(i))
			{
			    ThrowBonus += iThrowWorth;
			}
		}
	}
	return Float:float(ThrowBonus);
}

Float:CalculateBonusPercent(Float:score, Float:maxbonus = -1.0)
{
	return score / (maxbonus == -1.0 ? (fMapBonus + float(iPillWorth * iTeamSize) + float(iMedWorth * iTeamSize)) : maxbonus) * 100;
}

/************/
/** Stocks **/
/************/

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool:IsAnyInfected(entity)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return IsClientInGame(entity) && GetClientTeam(entity) == 3;
	}
	else if (entity > MaxClients)
	{
		decl String:classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected") || StrEqual(classname, "witch")) 
		{
			return true;
		}
	}
	return false;
}

bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerLedged(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

GetUprightSurvivors()
{
	new aliveCount;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
			{
				aliveCount++;
			}
		}
	}
	return aliveCount;
}

GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

GetSurvivorPermanentHealth(client)
{
	// Survivors always have minimum 1 permanent hp
	// so that they don't faint in place just like that when all temp hp run out
	// We'll use a workaround for the sake of fair calculations
	// Edit 2: "Incapped HP" are stored in m_iHealth too; we heard you like workarounds, dawg, so we've added a workaround in a workaround
	return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}

bool:HasPills(client)
{
	new item = GetPlayerWeaponSlot(client, 4);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_pain_pills");
	}
	return false;
}

bool:HasAdrenaline(client)
{
	new item = GetPlayerWeaponSlot(client, 4);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_adrenaline");
	}
	return false;
}

bool:HasMed(client)
{
	new item = GetPlayerWeaponSlot(client, 3);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_first_aid_kit");
	}
	return false;
}

bool:HasBile(client)
{
	new item = GetPlayerWeaponSlot(client, 2);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_vomitjar");
	}
	return false;
}

bool:HasMolo(client)
{
	new item = GetPlayerWeaponSlot(client, 2);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_molotov");
	}
	return false;
}

bool:HasPipe(client)
{
	new item = GetPlayerWeaponSlot(client, 2);
	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_pipe_bomb");
	}
	return false;
}
