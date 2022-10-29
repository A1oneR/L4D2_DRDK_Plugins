// Changelog:
//
// 2.0 (robex):
//     - Code rework, cleaned up old sourcemod functions
//     - Allow limiting individual melees, to limit them with l4d_wlimits_add
//       use names in MeleeWeaponNames array (l4d2util_constants.inc)
//

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util> //#include <weapons>
#include <colors>

#define MAX_WEAPON_NAME_LENGTH	32
#define GAMEDATA_FILE			"l4d_wlimits"
#define GAMEDATA_USE_AMMO		"CWeaponAmmoSpawn_Use"

#define MAX_PLAYER_WEAPON_SLOTS 5

#define TEAM_SURVIVOR 2

enum struct LimitArrayEntry
{
	int LAE_iLimit;
	int LAE_iGiveAmmo;
	int LAE_WeaponArray[WEPID_SIZE / 32 + 1];
	int LAE_MeleeArray[WEPID_MELEES_SIZE / 32 + 1];
}

int 
	TankAmount,
	TryTime[MAXPLAYERS + 1];

ArrayList
	hLimitArray;

bool
	bIsTankAlive,
	bIsLocked,
	bIsPressingButtonUse[MAXPLAYERS + 1],
	bIsHoldingButtonUse[MAXPLAYERS + 1];

StringMap hMeleeWeaponNamesTrie = null;

public Plugin myinfo =
{
	name = "L4D GasCans Deny In Tank Time",
	author = "CanadaRox, Stabby, Forgetest, A1m`, robex, A1R",
	description = "You should not pick the gascans in c1m4 Tank ROund!!!",
	version = "1.0",
	url = "https://github.com/A1oneR/AirMod"
};

public void OnPluginStart()
{
	L4D2Weapons_Init();

	hLimitArray = new ArrayList(sizeof(LimitArrayEntry));

	/* Preparing SDK Call */
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);

	if (conf == null) {
		SetFailState("Gamedata missing: %s", GAMEDATA_FILE);
	}
	
	StartPrepSDKCall(SDKCall_Entity);

	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, GAMEDATA_USE_AMMO)) {
		SetFailState("Gamedata missing signature: %s", GAMEDATA_USE_AMMO);
	}

	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_killed", OnTankKilled, EventHookMode_Post);
	HookEvent("tank_spawn", OnTankSpawn, EventHookMode_Post);
    HookEvent("player_death",           Event_PlayerDeath,          EventHookMode_Post);
	
	delete conf;
}

public void OnMapStart()
{
	PrecacheSound("player/suit_denydevice.wav");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ 
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (client && IsTank(client))
    {
        TankKilled();
    }
}

public void TankKilled()
{
    bIsTankAlive = false;
	TankAmount++;
	PrintToChatAll("UnFreeze now");
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bIsTankAlive = false;
	TankAmount = 0;
	for (int i = 0; i < MAXPLAYERS; i++) 
	{
		TryTime[i] = 0;
	}
}

public void OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	bIsTankAlive = true;
	//PrintToChatAll("Frozen Now.");
}

public void OnTankKilled(Event event, const char[] name, bool dontBroadcast)
{
	bIsTankAlive = false;
	TankAmount++;
	PrintToChatAll("UnFreeze now.");
}

public void OnClientPutInServer(int client)
{
	bIsPressingButtonUse[client] = false;
	bIsHoldingButtonUse[client] = false;
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	bIsPressingButtonUse[client] = false;
	bIsHoldingButtonUse[client] = false;
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
		bIsHoldingButtonUse[client] = bIsPressingButtonUse[client];
		bIsPressingButtonUse[client] = !!(buttons & IN_USE);
	} else {
		bIsHoldingButtonUse[client] = false;
		bIsPressingButtonUse[client] = false;
	}
	
	return Plugin_Continue;
}

void denyWeapon(int wep_slot, LimitArrayEntry arrayEntry, int client)
{
	// Notify the client only when they are attempting to pick this up
	// in which way spamming gets avoided due to auto-pick-up checking left since Counter:Strike.
	if (bIsPressingButtonUse[client] && !bIsHoldingButtonUse[client])
	{
		bIsHoldingButtonUse[client] = true;
		if (TryTime[client] <= 2)
		{
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					CPrintToChat(client, "{red}请不要在克局期间拿油");
				}
				case 2:
				{
					CPrintToChat(client, "{red}拿油可是会刷二克的哦");
				}
				case 3:
				{
					CPrintToChat(client, "{red}请在克局时，不要动手拿油");
				}
				case 4:
				{
					CPrintToChat(client, "{red}猜猜为什么不让你拿这个油？");
				}
				case 5:
				{
					CPrintToChat(client, "{red}油桶虽好，但不要在克局时拿哦");
				}
			}
		}
		else if (TryTime[client] <= 4)
		{
			switch (GetRandomInt(1, 3))
			{
				case 1:
				{
					CPrintToChat(client, "{red}油桶我啊，是真的要生气了哦");
				}
				case 2:
				{
					CPrintToChat(client, "{red}这是一次警告，你也不希望社死是吧");
				}
				case 3:
				{
					CPrintToChat(client, "{red}这条消息只有你能看到，因为你正在尝试做出傻逼行为！");
				}
			}
		}
		else
		{
			switch (GetRandomInt(1, 3))
			{
				case 1:
				{
					CPrintToChatAll("{blue}%N{default}: 我是傻逼，因为我在克局拿油桶", client);
				}
				case 2:
				{
					CPrintToChatAll("{blue}%N{default}: 我是脑残，我要给队友施加压力", client);
				}
				case 3:
				{
					CPrintToChatAll("{blue}%N{default}: 我是智障，我想要看见第二只克", client);
				}
			}
		}
		TryTime[client]++;
		EmitSoundToClient(client, "player/suit_denydevice.wav");
	}
}

public Action WeaponCanUse(int client, int weapon)
{
	if (GetClientTeam(client) != TEAM_SURVIVOR) {
		return Plugin_Continue;
	}
	
	int wepid = IdentifyWeapon(weapon);
	int is_melee = (wepid == WEPID_MELEE);
	int meleeid = 0;
	if (is_melee) {
		meleeid = IdentifyMeleeWeapon(weapon);
	}
	int wep_slot = GetSlotFromWeaponId(wepid);

	int player_weapon = GetPlayerWeaponSlot(client, wep_slot);
	int player_wepid = IdentifyWeapon(player_weapon);
	/*int player_meleeid = 0;
	if (player_wepid == WEPID_MELEE) {
		player_meleeid = IdentifyMeleeWeapon(player_weapon);
	}*/

	LimitArrayEntry arrayEntry;
	//PrintToChatAll("U should report111");
	
	int iSize = hLimitArray.Length;
	if (wepid == WEPID_GASCAN && bIsTankAlive && TankAmount == 0) 
	{
		//PrintToChatAll("Status TF:%i Amo:%i", bIsTankAlive, TankAmount);
		//PrintToChatAll("U should report");
		denyWeapon(wep_slot, arrayEntry, client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
