#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define GAMEDATA	"ai_hardsi"
#define DEBUG 0

float 
	VictimPosition[MAXPLAYERS+1][3],
	AttackerPosition[MAXPLAYERS+1][3];

ConVar
	g_hCvarRockMinDamage = null,
	g_hCvarRockMaxDamage = null,
	g_hCvarRockMinDistance = null,
	g_hCvarRockMaxDistance = null;

bool
	g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Tank Linear Rock damage",
	author = "A1R",
	description = "Letz the rock damage judged by the distance",
	version = "1.0",
	url = "https://github.com/A1oneR/L4D2_DRDK_Plugins"
};

public void OnPluginStart()
{
	vLoadGameData();

	g_hCvarRockMinDamage = CreateConVar("l4d2_rock_min_damage", "2.0", "Minimum damage does a rock can be done.");
	g_hCvarRockMaxDamage = CreateConVar("l4d2_rock_max_damage", "48.0", "Maxinum damage does a rock can be done.");
	g_hCvarRockMinDistance = CreateConVar("l4d2_rock_min_distance", "200.0", "Any distance shorter than this will be considered a min damage");
	g_hCvarRockMaxDistance = CreateConVar("l4d2_rock_max_distance", "2000.0", "Any distance farther than this will be considered a max damage");

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
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	vSetupDetours(hGameData);

	delete hGameData;
}

void vSetupDetours(GameData hGameData = null)
{
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "CTankRock::OnRelease");
	if(dDetour == null)
		SetFailState("Failed to find signature: CTankRock::OnRelease");

	if(!dDetour.Enable(Hook_Pre, mreTankRockReleasePre))
		SetFailState("Failed to detour pre: CTankRock::OnRelease");

	/*if(!dDetour.Enable(Hook_Post, mreTankRockReleasePost))
		SetFailState("Failed to detour post: CTankRock::OnRelease");*/
}

MRESReturn mreTankRockReleasePre(int pThis, DHookParam hParams)
{
	int iThrower = GetEntPropEnt(pThis, Prop_Data, "m_hThrower");
	GetClientAbsOrigin(iThrower, AttackerPosition[iThrower]);

	return MRES_Ignored;
}

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (iDamagetype != DMG_CLUB) {
		return Plugin_Continue;
	}

	if (!IsValidSurvivor(iVictim) || !IsValidTank(iAttacker)) {
		return Plugin_Continue;
	}

	if (iInflictor <= MaxClients || !IsValidEdict(iInflictor)) {
		return Plugin_Continue;
	}

	char sClassName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iInflictor, sClassName, sizeof(sClassName));

#if DEBUG
	PrintToChatAll("iVictim: %N, iAttacker: %N, iInflictor, %s (%d), fDamage: %f, iDamagetype: %d", \
							iVictim, iAttacker, sClassName, iInflictor, fDamage, iDamagetype);
#endif
	if (strcmp("tank_rock", sClassName) == 0) 
	{
		GetClientAbsOrigin(iVictim, VictimPosition[iVictim]);
		float xdistance = FloatAbs(AttackerPosition[iAttacker][0] - VictimPosition[iVictim][0]);
		float ydistance = FloatAbs(AttackerPosition[iAttacker][1] - VictimPosition[iVictim][1]);
		float zdistance = FloatAbs(AttackerPosition[iAttacker][2] - VictimPosition[iVictim][2]);
		float distance = SquareRoot(Pow(xdistance, 2.0) + Pow(ydistance, 2.0) + Pow(zdistance, 2.0));

		if (distance <= g_hCvarRockMinDistance.FloatValue)
		{
			fDamage = g_hCvarRockMinDamage.FloatValue;
			//PrintToChatAll("Very short, guys. Need Farther. DAMAGE:%.1f%  Distance:%.1f%", fDamage, distance); //DEBUG
			return Plugin_Changed;
		}
		else if (distance >= g_hCvarRockMaxDistance.FloatValue)
		{
			fDamage = g_hCvarRockMaxDamage.FloatValue;
			CPrintToChatAll("{red}Jackpot!{default} {olive}%N {default}eat a LongRange Rock. (DAMAGE:{red}%.1f%{default}  Distance:{olive}%.1f{default})", iVictim, fDamage, distance); //DEBUG
			return Plugin_Changed;
		}
		float percentage = distance / g_hCvarRockMaxDistance.FloatValue;
		fDamage = g_hCvarRockMaxDamage.FloatValue * percentage;
		//PrintToChatAll("Letz see what we got. DAMAGE:%.1f%  Distance:%.1f%", fDamage, distance); //DEBUG

		return Plugin_Changed;
	}

	return Plugin_Continue;
}
