#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

public const char g_sSniperWeapon[][ENTITY_MAX_NAME_LENGTH] =
{
	"weapon_sniper_scout",
	"weapon_sniper_awp"
};

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Sniper Hunter Bodyshot",
	author = "Visor, A1m`",
	description = "Remove sniper weapons' stomach hitgroup damage multiplier against hunters",
	version = "2.2",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public void OnPluginStart()
{
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_TraceAttack, TraceAttack);
}

public Action TraceAttack(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, \
								int &fDamageType, int &iAmmoType, int iHitBox, int iHitGroup)
{
	if (iHitGroup != HITGROUP_HEAD) {
		return Plugin_Continue;
	}

	if (!IsValidSurvivor(iAttacker) || IsFakeClient(iAttacker)) {
		return Plugin_Continue;
	}
	
	if (IsTank(iVictim) || IsWitch(iVictim) || IsValidSurvivor(iVictim))
	{
		return Plugin_Continue;
	}
	int iWeapon = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
	if (iWeapon == -1) {
		return Plugin_Continue;
	}

	char sClassName[64];
	GetEdictClassname(iWeapon, sClassName, sizeof(sClassName));
	if (!IsValidSniper(sClassName)) {
		return Plugin_Continue;
	}

#if DEBUG
	char szHitgroup[32];
	HitgroupToString(iHitGroup, szHitgroup, sizeof(szHitgroup));
	PrintToChatAll("Victim %N, attacker %N, hitgroup %s (%d), weapon: %s, ", iVictim, iAttacker, szHitgroup, iHitGroup, sClassName);
#endif
	int HP = GetEntProp(iVictim, Prop_Send, "m_iHealth");
	 PrintToChatAll("\x04%N\x01 用\x05狙击枪\x01爆头了 \x04%N\x01", iAttacker, iVictim);
	fDamage = HP * 0.25;
	return Plugin_Changed;
}

bool IsValidSniper(const char[] sWeaponName)
{
	for (int i = 0; i < sizeof(g_sSniperWeapon); i++) {
		if (strcmp(sWeaponName, g_sSniperWeapon[i]) == 0) {
			return true;
		}
	}

	return false;
}

bool IsHunter(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == L4D2Team_Infected
		&& GetEntProp(iClient, Prop_Send, "m_zombieClass") == L4D2Infected_Hunter
		&& GetEntProp(iClient, Prop_Send, "m_isGhost") != 1);
}

stock bool IsWitch(int iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}