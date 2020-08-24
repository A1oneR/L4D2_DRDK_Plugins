#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define QT		"\x03博士\x04%N\x03抽到了\x01%s \x05→ \x02%s"
#define PIE	"\x04你抽中了\x01%s \x05→ \x02%s"
#define PH		"\x03博士\x04%N\x03抽到了\x01%s \x05→ \x02%s"

#define DD		"buttons/button14.wav"

new String:SavePath[255];
new Handle:PlayerStatsSave = INVALID_HANDLE;
new Handle:hTimerAchieved[MAXPLAYERS+1];
new Handle:hTimerMiniFireworks[MAXPLAYERS+1];
new Handle:hTimerLoopEffect[MAXPLAYERS+1];
new bool:rolled[MAXPLAYERS+1];
new bool:sift[MAXPLAYERS+1];
new count[MAXPLAYERS+1];
new L[MAXPLAYERS+1];
new gain[MAXPLAYERS+1];
new prize1[MAXPLAYERS+1];
new prize2[MAXPLAYERS+1];
new prize3[MAXPLAYERS+1];
new prize4[MAXPLAYERS+1];
new prize5[MAXPLAYERS+1];
new prize6[MAXPLAYERS+1];
new Handle:StopTime[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};

new iTotal[MAXPLAYERS + 1];
new i6s[MAXPLAYERS + 1];
new i5s[MAXPLAYERS + 1];
new i4s[MAXPLAYERS + 1];
new i3s[MAXPLAYERS + 1];
new i2s[MAXPLAYERS + 1];
new i1s[MAXPLAYERS + 1];

new Handle:kills;
new Handle:infected_count;
new Handle:tank_count;
new Handle:LDW_MSG_time;

new Handle:timer_handle=INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_xf",LDW);
	HookEvent("infected_death",		infected_death);
	HookEvent("player_death",		player_death);
	HookEvent("round_start", round_start);
	HookEvent("round_end",				Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	
	kills = CreateConVar("common_kills", "50", "击杀多少小僵尸可获得一次抽奖机会", FCVAR_PLUGIN);
	infected_count = CreateConVar("infected_kill_counts", "3", "击杀一个特感可获得多少次抽奖机会", FCVAR_PLUGIN);
	tank_count = CreateConVar("tank_iskill_count", "5", "tank死亡时所有幸存者可获得多少次抽奖机会", FCVAR_PLUGIN);
	LDW_MSG_time = CreateConVar("ldw_msg_time", "60.0", "抽奖系统公告多少时间(秒)播放一次", FCVAR_PLUGIN);
	AutoExecConfig(true, "L4D2_Lucky_Draw");
}

public OnMapStart()
{
	for(new i=1; i<=MaxClients; i++)
	{
		rolled[i]=false;
		sift[i]=true;
	}
	PrecacheSound("ui/littlereward.wav", true);
	PrecacheSound("level/gnomeftw.wav", true);
	PrecacheSound("npc/moustachio/strengthattract05.wav", true);
	PrecacheSound(DD, true);
	PlayerStatsSave = CreateKeyValues("Player Stats Save");
	BuildPath(Path_SM, SavePath, 255, "data/PlayerStatsSave.txt");
	FileToKeyValues(PlayerStatsSave, SavePath);
}

public OnClientDisconnect(Client)
{
	if(!IsFakeClient(Client))
	{
		L[Client]=0;
		if (StopTime[Client] != INVALID_HANDLE) {
			KillTimer(StopTime[Client]);
			StopTime[Client] = INVALID_HANDLE;
		}
		PrintToServer("清除玩家%N的寻访次数", Client);
	}
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
	if(timer_handle == INVALID_HANDLE)
				{
					timer_handle=CreateTimer(GetConVarFloat(LDW_MSG_time), Msg, 0, TIMER_REPEAT);
				}
}

public Action:infected_death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(IsValidClient(id))
	{
		if(GetClientTeam(id) == 2 && !IsFakeClient(id))
		{
			if(count[id]<GetConVarInt(kills))
			{
				count[id]+=1;
			} else 
			{
				count[id]=0;
			}
		}
	}
}

public Action:player_death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new vic = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client) && IsValidClient(vic))
	{
		if(IsClientInGame(vic) && IsClientInGame(client) && !IsFakeClient(client) && !(IsCommonInfected(vic) || IsWitch(vic)))
		{
			if(GetClientTeam(client) == 2 && GetClientTeam(vic) == 3)
			{
				if(GetEntProp(vic, Prop_Send, "m_zombieClass") != 8)
				{
				}
			}
		}
		
		if(!(IsCommonInfected(vic) || IsWitch(vic)))
		{
			if(GetClientTeam(vic) == 3 && GetEntProp(vic, Prop_Send, "m_zombieClass") == 8 && IsClientInGame(vic))
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(GetClientTeam(i) == 2)
						{
						}
					}
				}
			}
		}
	
		if(GetClientTeam(vic) == 2 && rolled[vic])
		{
			KillTimer(StopTime[vic]);
			rolled[vic]=false;
			sift[vic]=true;
			PrintToChat(vic, "\x04由于角色死亡,寻访强制終止!");
			PrintCenterText(vic, "寻访终止!");
		}
	}
}

public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			KillTimer(StopTime[i]);
		}
	}
	
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
				
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			rolled[i]=false;
			sift[i]=true;
		}
	}
}

public Action:LDW(Client, args)
{
	draw_function(Client);
}

public Action:draw_function(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	if(!rolled[Client])
	{
		Format(line, sizeof(line), "   -人事部简历投递-");
		SetPanelTitle(menu, line);
		if(iTotal[Client] > 0)
		{
			Format(line, sizeof(line), "你已寻访%d次", iTotal[Client]);
			DrawPanelText(menu, line);
			Format(line, sizeof(line), "【详情请查看规则说明】");
			DrawPanelText(menu, line);
		} else
		{
			iTotal[Client] = 0;
			Format(line, sizeof(line), "你暂时没有寻访");
			DrawPanelText(menu, line);
			Format(line, sizeof(line), "【详情请查看规则说明】");
			DrawPanelText(menu, line);
		}
		
		Format(line, sizeof(line), "准备寻访");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "规则说明");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "刷新列表");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, MenuHandler, MENU_TIME_FOREVER);
		CloseHandle(menu);
	} else 
	{
		Format(line, sizeof(line), "  -祝您好运-");
		SetPanelTitle(menu, line);
		Format(line, sizeof(line), "~~~~~~~~~~~~~~", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "   寻访中...  ", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "~~~~~~~~~~~~~~", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "-开包-");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "如果列表关闭,请再次打开,选择:-开包-", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, Stop, MENU_TIME_FOREVER);
		CloseHandle(menu);
	}
}

public MenuHandler(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
					if(sift[Client])
					{
						sift_start1(Client);
						sift_start2(Client);
						sift_start3(Client);
						sift_start4(Client);
						sift_start5(Client);
						sift_start6(Client);
						sift[Client]=false;
					}
					Award_List(Client);
			}
			case 2:
			{
				Explain(Client);
			}
			case 3:
			{
				draw_function(Client);
				EmitSoundToClient(Client, DD);
			}
		}
	}
}

public Stop(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				KillTimer(StopTime[Client]);
				rolled[Client]=false;
				sift[Client]=true;
				Award(Client);
			}
		}
	}
}

public Action:Explain(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    -驴子的规则说明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "请选择你想了解的说明");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "操作说明");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "已获得干员展示");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "简历出现概率");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Declare, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Declare(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1(Client);
			}
			case 2:
			{
				E2(Client);
			}
			case 3:
			{
				E3(Client);
			}
			case 4:
			{
				draw_function(Client);
			}
		}
	}
}

public Action:E1(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -手把手教你脱非入欧-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">如果你有寻访机会");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">请点击主菜单的 【准备寻访】");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">此时会出现一个列表,上面显示你本次星级的简历");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">然后选择【开始寻访】");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "下一页");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Page1, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Page1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1_1(Client);
			}
			case 2:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E1_1(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -操作说明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">此时你准心上方会出现一个跳动的星级条");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">当你选择菜单中的【-开包-】时,星级条停止跳动");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">你即可获得星级栏对应的简历");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">祝您顺利，Doctor");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">输入/xfStat了解寻访记录");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "上一页");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Page2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Page2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1(Client);
			}
			case 2:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E2(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "  -已获得干员展示-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">已获得6星干员：%d个", GetConVarInt(i6s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">已获得5星干员：%d个", GetConVarInt(i5s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">已获得4星干员：%d个", GetConVarInt(i4s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">已获得3星干员：%d个", GetConVarInt(i3s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">已获得2星干员：%d个", GetConVarInt(i2s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">已获得1星干员：%d个", GetConVarInt(i1s[Client]));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Back, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Back(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E3(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -简历出现概率-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "以下为星级条跳动时,各类星级出现概率:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">6星干员2％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">5星干员8％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">4星干员16％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">3星干员30％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">2星干员34％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">1星干员10％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Back, MENU_TIME_FOREVER);
	CloseHandle(menu);
}


public Action:Award(Client)//** 发放简历 **//
{
	decl String:ms[512];
	decl String:hd[8192];
	if(gain[Client]==1)
	{
		if(prize1[Client]==1)
		{	
			Format(hd, sizeof(hd), "安洁莉娜");
		} else if(prize1[Client]==2)
		{	
			Format(hd, sizeof(hd), "星熊");
		} else if(prize1[Client]==3)
		{	
			Format(hd, sizeof(hd), "能天使");
		} else if(prize1[Client]==4)
		{	
			Format(hd, sizeof(hd), "陈");
		} else if(prize1[Client]==5)
		{
			Format(hd, sizeof(hd), "闪灵");
		} else if(prize1[Client]==6)
		{
			Format(hd, sizeof(hd), "夜莺");
		} else if(prize1[Client]==7)
		{
			Format(hd, sizeof(hd), "银灰");
		} else if(prize1[Client]==8)
		{
			Format(hd, sizeof(hd), "艾雅法拉");
		} else if(prize1[Client]==9)
		{
			Format(hd, sizeof(hd), "伊芙利特");
		} else if(prize1[Client]==10)
		{
			Format(hd, sizeof(hd), "斯卡蒂");
		} else if(prize1[Client]==11)
		{
			Format(hd, sizeof(hd), "推进之王");
		} else if(prize1[Client]==12)
		{
			Format(hd, sizeof(hd), "塞雷娅");
		} else if(prize1[Client]==13)
		{
			Format(hd, sizeof(hd), "黑");
		} else if(prize1[Client]==14)
		{
			Format(hd, sizeof(hd), "赫拉格");
		} else if(prize1[Client]==15)
		{
			Format(hd, sizeof(hd), "麦哲伦");
		} else if(prize1[Client]==16)
		{
			Format(hd, sizeof(hd), "莫斯提马");
		} else if(prize1[Client]==17)
		{
			Format(hd, sizeof(hd), "煌");
		} else if(prize1[Client]==18)
		{
			Format(hd, sizeof(hd), "年");
		} else if(prize1[Client]==19)
		{
			Format(hd, sizeof(hd), "阿");
		} else if(prize1[Client]==20)
		{
			Format(hd, sizeof(hd), "刻俄柏");
		} else if(prize1[Client]==21)
		{
			Format(hd, sizeof(hd), "风笛");
		} else if(prize1[Client]==22)
		{
			Format(hd, sizeof(hd), "傀影");
		} else if(prize1[Client]==23)
		{
			Format(hd, sizeof(hd), "W");
		} else if(prize1[Client]==24)
		{
			Format(hd, sizeof(hd), "温蒂");
		}
		Format(ms, sizeof(ms), "6星干员");
		PrintToChatAll(QT, Client, ms, hd);
	        i6s[Client] += 1;  
		iTotal[Client] += 1;
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client] == 2)
	{
		if(prize2[Client]==1)
		{
			Format(hd, sizeof(hd), "白面鸮");
		} else if(prize2[Client]==2)
		{
			Format(hd, sizeof(hd), "凛冬");
		} else if(prize2[Client]==3)
		{	
			Format(hd, sizeof(hd), "德克萨斯");
		} else if(prize2[Client]==4)
		{
			Format(hd, sizeof(hd), "芙兰卡");
		} else if(prize2[Client]==5)
		{
			Format(hd, sizeof(hd), "拉普兰德");
		} else if(prize2[Client]==6)
		{
			Format(hd, sizeof(hd), "幽灵鲨");
		} else if(prize2[Client]==7)
		{
			Format(hd, sizeof(hd), "蓝毒");
		} else if(prize2[Client]==8)
		{
			Format(hd, sizeof(hd), "白金");
		} else if(prize2[Client]==9)
		{	
			Format(hd, sizeof(hd), "陨星");
		} else if(prize2[Client]==10)
		{
			Format(hd, sizeof(hd), "天火");
		} else if(prize2[Client]==11)
		{
			Format(hd, sizeof(hd), "梅尔");
		} else if(prize2[Client]==12)
		{
			Format(hd, sizeof(hd), "赫默");
		} else if(prize2[Client]==13)
		{
			Format(hd, sizeof(hd), "华法琳");
		} else if(prize2[Client]==14)
		{
			Format(hd, sizeof(hd), "临光");
		} else if(prize2[Client]==15)
		{
			Format(hd, sizeof(hd), "红");
		} else if(prize2[Client]==16)
		{
			Format(hd, sizeof(hd), "雷蛇");
		} else if(prize2[Client]==17)
		{
			Format(hd, sizeof(hd), "可颂");
		} else if(prize2[Client]==18)
		{	
			Format(hd, sizeof(hd), "普罗旺斯");
		} else if(prize2[Client]==19)
		{
			Format(hd, sizeof(hd), "守林人");
		} else if(prize2[Client]==20)
		{
			Format(hd, sizeof(hd), "崖心");
		} else if(prize2[Client]==21)
		{
			Format(hd, sizeof(hd), "初雪");
		} else if(prize2[Client]==22)
		{
			Format(hd, sizeof(hd), "真理");
		} else if(prize2[Client]==23)
		{
			Format(hd, sizeof(hd), "空");
		} else if(prize2[Client]==24)
		{
			Format(hd, sizeof(hd), "狮蝎");
		} else if(prize2[Client]==25)
		{
			Format(hd, sizeof(hd), "食铁兽");
		} else if(prize2[Client]==26)
		{
			Format(hd, sizeof(hd), "夜魔");
		} else if(prize2[Client]==27)
		{
			Format(hd, sizeof(hd), "诗怀雅");
		} else if(prize2[Client]==28)
		{
			Format(hd, sizeof(hd), "火神");
		} else if(prize2[Client]==29)
		{
			Format(hd, sizeof(hd), "因陀罗");
		} else if(prize2[Client]==30)
		{
			Format(hd, sizeof(hd), "阿米娅");
		} else if(prize2[Client]==31)
		{
			Format(hd, sizeof(hd), "暴行");
		} else if(prize2[Client]==32)
		{
			Format(hd, sizeof(hd), "格拉尼");
		} else if(prize2[Client]==33)
		{
			Format(hd, sizeof(hd), "锡兰");
		} else if(prize2[Client]==34)
		{
			Format(hd, sizeof(hd), "格劳克斯");
		} else if(prize2[Client]==35)
		{
			Format(hd, sizeof(hd), "星极");
		} else if(prize2[Client]==36)
		{
			Format(hd, sizeof(hd), "送葬人");
		} else if(prize2[Client]==37)
		{
			Format(hd, sizeof(hd), "槐琥");
		} else if(prize2[Client]==38)
		{
			Format(hd, sizeof(hd), "苇草");
		} else if(prize2[Client]==39)
		{
			Format(hd, sizeof(hd), "布洛卡");
		} else if(prize2[Client]==40)
		{
			Format(hd, sizeof(hd), "灰喉");
		} else if(prize2[Client]==41)
		{
			Format(hd, sizeof(hd), "哞");
		} else if(prize2[Client]==42)
		{
			Format(hd, sizeof(hd), "惊蛰");
		} else if(prize2[Client]==43)
		{
			Format(hd, sizeof(hd), "慑砂");
		} else if(prize2[Client]==44)
		{
			Format(hd, sizeof(hd), "巫恋");
		} else if(prize2[Client]==45)
		{
			Format(hd, sizeof(hd), "极境");
		}
		Format(ms, sizeof(ms), "5星干员");
		PrintToChatAll(QT, Client, ms, hd);
		i5s[Client] += 1;
		iTotal[Client] += 1;
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==3)
	{
		if(prize3[Client]==1)
		{
			Format(hd, sizeof(hd), "夜烟");
		} else if(prize3[Client]==2)
		{
			Format(hd, sizeof(hd), "远山");
		} else if(prize3[Client]==3)
		{
			Format(hd, sizeof(hd), "杰西卡");
		} else if(prize3[Client]==4)
		{
			Format(hd, sizeof(hd), "流星");
		} else if(prize3[Client]==5)
		{
			Format(hd, sizeof(hd), "白雪");
		} else if(prize3[Client]==6)
		{
			Format(hd, sizeof(hd), "清道夫");
		} else if(prize3[Client]==7)
		{
			Format(hd, sizeof(hd), "红豆");
		} else if(prize3[Client]==8)
		{
			Format(hd, sizeof(hd), "杜宾");
		} else if(prize3[Client]==9)
		{
			Format(hd, sizeof(hd), "缠丸");
		} else if(prize3[Client]==10)
		{
			Format(hd, sizeof(hd), "霜叶");
		} else if(prize3[Client]==11)
		{
			Format(hd, sizeof(hd), "慕斯");
		} else if(prize3[Client]==12)
		{
			Format(hd, sizeof(hd), "砾");
		} else if(prize3[Client]==13)
		{
			Format(hd, sizeof(hd), "暗索");
		} else if(prize3[Client]==14)
		{
			Format(hd, sizeof(hd), "末药");
		} else if(prize3[Client]==15)
		{
			Format(hd, sizeof(hd), "调香师");
		} else if(prize3[Client]==16)
		{	
			Format(hd, sizeof(hd), "角峰");
		} else if(prize3[Client]==17)
		{
			Format(hd, sizeof(hd), "蛇屠箱");
		} else if(prize3[Client]==18)
		{
			Format(hd, sizeof(hd), "古米");
		} else if(prize3[Client]==19)
		{
			Format(hd, sizeof(hd), "深海色");
		} else if(prize3[Client]==20)
		{
			Format(hd, sizeof(hd), "地灵");
		} else if(prize3[Client]==21)
		{
			Format(hd, sizeof(hd), "阿消");
		} else if(prize3[Client]==22)
		{
			Format(hd, sizeof(hd), "猎蜂");
		} else if(prize3[Client]==23)
		{
			Format(hd, sizeof(hd), "格雷伊");
		} else if(prize3[Client]==24)
		{
			Format(hd, sizeof(hd), "艾丝黛尔");
		} else if(prize3[Client]==25)
		{
			Format(hd, sizeof(hd), "讯使");
		} else if(prize3[Client]==26)
		{
			Format(hd, sizeof(hd), "嘉维尔");
		} else if(prize3[Client]==27)
		{
			Format(hd, sizeof(hd), "苏苏洛");
		} else if(prize3[Client]==28)
		{
			Format(hd, sizeof(hd), "桃金娘");
		} else if(prize3[Client]==29)
		{
			Format(hd, sizeof(hd), "红云（腐竹最爱）");
		} else if(prize3[Client]==30)
		{
			Format(hd, sizeof(hd), "梅");
		} else if(prize3[Client]==31)
		{
			Format(hd, sizeof(hd), "安比尔");
		} else if(prize3[Client]==32)
		{
			Format(hd, sizeof(hd), "宴");
		} else if(prize3[Client]==33)
		{
			Format(hd, sizeof(hd), "刻刀");
		}
		Format(ms, sizeof(ms), "4星干员");
		PrintToChatAll(QT, Client, ms, hd);
		i4s[Client] += 1;
		iTotal[Client] += 1;
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==4)
	{
		if(prize4[Client]==1)
		{
			Format(hd, sizeof(hd), "芬");
		} else if(prize4[Client]==2)
		{
			Format(hd, sizeof(hd), "香草");
		} else if(prize4[Client]==3)
		{
			Format(hd, sizeof(hd), "翎羽");
		} else if(prize4[Client]==4)
		{
			Format(hd, sizeof(hd), "玫兰莎");
		} else if(prize4[Client]==5)
		{
			Format(hd, sizeof(hd), "卡缇");
		} else if(prize4[Client]==6)
		{
			Format(hd, sizeof(hd), "米格鲁");
		} else if(prize4[Client]==7)
		{
			Format(hd, sizeof(hd), "克洛丝");
		} else if(prize4[Client]==8)
		{
			Format(hd, sizeof(hd), "炎熔");
		} else if(prize4[Client]==9)
		{	
			Format(hd, sizeof(hd), "芙蓉");
		} else if(prize4[Client]==10)
		{	
			Format(hd, sizeof(hd), "安赛尔");
		} else if(prize4[Client]==11)
		{
			Format(hd, sizeof(hd), "史都华德");
		} else if(prize4[Client]==12)
		{	
			Format(hd, sizeof(hd), "梓兰");
		} else if(prize4[Client]==13)
		{	
			Format(hd, sizeof(hd), "空爆");
		} else if(prize4[Client]==14)
		{
			Format(hd, sizeof(hd), "月见夜");
		} else if(prize4[Client]==15)
		{	
			Format(hd, sizeof(hd), "斑点");
		} else if(prize4[Client]==16)
		{
			Format(hd, sizeof(hd), "泡普卡");
		} else if(prize4[Client]==17)
		{
			Format(hd, sizeof(hd), "安德切尔");
		}
		Format(ms, sizeof(ms), "3星干员");
		PrintToChatAll(QT, Client, ms, hd);
		i3s[Client] += 1;
	        iTotal[Client] += 1;
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==5)
	{
		if(prize5[Client]==1)
		{
			Format(hd, sizeof(hd), "夜刀");
		} else if(prize5[Client]==2)
		{
			Format(hd, sizeof(hd), "黑角");
		} else if(prize5[Client]==3)
		{
			Format(hd, sizeof(hd), "巡林者");
		} else if(prize5[Client]==4)
		{
			Format(hd, sizeof(hd), "杜林");
		} else if(prize5[Client]==5)
		{
			Format(hd, sizeof(hd), "12F");
		}
		Format(ms, sizeof(ms), "2星干员");
		PrintToChatAll(QT, Client, ms, hd);
		i2s[Client] += 1;
	        iTotal[Client] += 1;
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==6)
	{
		if(prize6[Client]==1)
		{
			Format(hd, sizeof(hd), "Lancet-2");
		} else if(prize6[Client]==2)
		{
			Format(hd, sizeof(hd), "Castle-3");
		} else if(prize6[Client]==3)
		{
			Format(hd, sizeof(hd), "THRM-EX");
		}
		Format(ms, sizeof(ms), "1星干员");
		i1s[Client] += 1;
		iTotal[Client] += 1;
		PrintToChatAll(PH, Client, ms, hd);
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
	}
	
}

public Action:sift_start1(Client)//6
{
	new diceNum = GetRandomInt(1, 24);
	switch (diceNum)
	{
		case 1:
		{
			prize1[Client]=1;
		}
		case 2:
		{
			prize1[Client]=2;
		}
		case 3:
		{
			prize1[Client]=3;
		}
		case 4:
		{
			prize1[Client]=4;
		}
		case 5:
		{
			prize1[Client]=5;
		}
		case 6:
		{
			prize1[Client]=6;
		}
		case 7:
		{
			prize1[Client]=7;
		}
		case 8:
		{
			prize1[Client]=8;
		}
		case 9:
		{
			prize1[Client]=9;
		}
		case 10:
		{
			prize1[Client]=10;
		}
		case 11:
		{
			prize1[Client]=11;
		}
		case 12:
		{
			prize1[Client]=12;
		}
		case 13:
		{
			prize1[Client]=13;
		}
		case 14:
		{
			prize1[Client]=14;
		}
		case 15:
		{
			prize1[Client]=15;
		}
		case 16:
		{
			prize1[Client]=16;
		}
		case 17:
		{
			prize1[Client]=17;
		}
		case 18:
		{
			prize1[Client]=18;
		}
		case 19:
		{
			prize1[Client]=19;
		}
		case 20:
		{
			prize1[Client]=20;
		}
		case 21:
		{
			prize1[Client]=21;
		}
		case 22:
		{
			prize1[Client]=22;
		}
		case 23:
		{
			prize1[Client]=23;
		}
		case 24:
		{
			prize1[Client]=24;
		}
	}
}

public Action:sift_start2(Client)//5
{
	new diceNum2 = GetRandomInt(1, 45);
	switch (diceNum2)
	{
		case 1:
		{
			prize2[Client]=1;
		}
		case 2:
		{
			prize2[Client]=2;
		}
		case 3:
		{
			prize2[Client]=3;
		}
		case 4:
		{
			prize2[Client]=4;
		}
		case 5:
		{
			prize2[Client]=5;
		}
		case 6:
		{
			prize2[Client]=6;
		}
		case 7:
		{
			prize2[Client]=7;
		}
		case 8:
		{
			prize2[Client]=8;
		}
		case 9:
		{
			prize2[Client]=9;
		}
		case 10:
		{
			prize2[Client]=10;
		}
		case 11:
		{
			prize2[Client]=11;
		}
		case 12:
		{
			prize2[Client]=12;
		}
		case 13:
		{
			prize2[Client]=13;
		}
		case 14:
		{
			prize2[Client]=14;
		}
		case 15:
		{
			prize2[Client]=15;
		}
		case 16:
		{
			prize2[Client]=16;
		}
		case 17:
		{
			prize2[Client]=17;
		}
		case 18:
		{
			prize2[Client]=18;
		}
		case 19:
		{
			prize2[Client]=19;
		}
		case 20:
		{
			prize2[Client]=20;
		}
		case 21:
		{
			prize2[Client]=21;
		}
		case 22:
		{
			prize2[Client]=22;
		}
		case 23:
		{
			prize2[Client]=23;
		}
		case 24:
		{
			prize2[Client]=24;
		}
		case 25:
		{
			prize2[Client]=25;
		}
		case 26:
		{
			prize2[Client]=26;
		}
		case 27:
		{
			prize2[Client]=27;
		}
		case 28:
		{
			prize2[Client]=28;
		}
		case 29:
		{
			prize2[Client]=29;
		}
		case 30:
		{
			prize2[Client]=30;
		}
		case 31:
		{
			prize2[Client]=31;
		}
		case 32:
		{
			prize2[Client]=32;
		}
		case 33:
		{
			prize2[Client]=33;
		}
		case 34:
		{
			prize2[Client]=34;
		}
		case 35:
		{
			prize2[Client]=35;
		}
		case 36:
		{
			prize2[Client]=36;
		}
		case 37:
		{
			prize2[Client]=37;
		}
		case 38:
		{
			prize2[Client]=38;
		}
		case 39:
		{
			prize2[Client]=39;
		}
		case 40:
		{
			prize2[Client]=40;
		}
		case 41:
		{
			prize2[Client]=41;
		}
		case 42:
		{
			prize2[Client]=42;
		}
		case 43:
		{
			prize2[Client]=43;
		}
		case 44:
		{
			prize2[Client]=44;
		}
		case 45:
		{
			prize2[Client]=45;
		}
	}
}

public Action:sift_start3(Client)//4
{
	new diceNum3 = GetRandomInt(1, 33);
	switch (diceNum3)
	{
		case 1:
		{
			prize3[Client]=1;
		}
		case 2:
		{
			prize3[Client]=2;
		}
		case 3:
		{
			prize3[Client]=3;
		}
		case 4:
		{
			prize3[Client]=4;
		}
		case 5:
		{
			prize3[Client]=5;
		}
		case 6:
		{
			prize3[Client]=6;
		}
		case 7:
		{
			prize3[Client]=7;
		}
		case 8:
		{
			prize3[Client]=8;
		}
		case 9:
		{
			prize3[Client]=9;
		}
		case 10:
		{
			prize3[Client]=10;
		}
		case 11:
		{
			prize3[Client]=11;
		}
		case 12:
		{
			prize3[Client]=12;
		}
		case 13:
		{
			prize3[Client]=13;
		}
		case 14:
		{
			prize3[Client]=14;
		}
		case 15:
		{
			prize3[Client]=15;
		}
		case 16:
		{
			prize3[Client]=16;
		}
		case 17:
		{
			prize3[Client]=17;
		}
		case 18:
		{
			prize3[Client]=18;
		}
		case 19:
		{
			prize3[Client]=19;
		}
		case 20:
		{
			prize3[Client]=20;
		}
		case 21:
		{
			prize3[Client]=21;
		}
		case 22:
		{
			prize3[Client]=22;
		}
		case 23:
		{
			prize3[Client]=23;
		}
		case 24:
		{
			prize3[Client]=24;
		}
		case 25:
		{
			prize3[Client]=25;
		}
		case 26:
		{
			prize3[Client]=26;
		}
		case 27:
		{
			prize3[Client]=27;
		}
		case 28:
		{
			prize3[Client]=28;
		}
		case 29:
		{
			prize3[Client]=29;
		}
		case 30:
		{
			prize3[Client]=30;
		}
		case 31:
		{
			prize3[Client]=31;
		}
		case 32:
		{
			prize3[Client]=32;
		}
		case 33:
		{
			prize3[Client]=33;
		}
	}
}

public Action:sift_start4(Client)//3
{
	new diceNum4 = GetRandomInt(1, 17);
	switch (diceNum4)
	{
		case 1:
		{
			prize4[Client]=1;
		}
		case 2:
		{
			prize4[Client]=2;
		}
		case 3:
		{
			prize4[Client]=3;
		}
		case 4:
		{
			prize4[Client]=4;
		}
		case 5:
		{
			prize4[Client]=5;
		}
		case 6:
		{
			prize4[Client]=6;
		}
		case 7:
		{
			prize4[Client]=7;
		}
		case 8:
		{
			prize4[Client]=8;
		}
		case 9:
		{
			prize4[Client]=9;
		}
		case 10:
		{
			prize4[Client]=10;
		}
		case 11:
		{
			prize4[Client]=11;
		}
		case 12:
		{
			prize4[Client]=12;
		}
		case 13:
		{
			prize4[Client]=13;
		}
		case 14:
		{
			prize4[Client]=14;
		}
		case 15:
		{
			prize4[Client]=15;
		}
		case 16:
		{
			prize4[Client]=16;
		}
		case 17:
		{
			prize4[Client]=17;
		}
	}
}

public Action:sift_start5(Client)//2
{
	new diceNum5 = GetRandomInt(1, 5);
	switch (diceNum5)
	{
		case 1:
		{
			prize5[Client]=1;
		}
		case 2:
		{
			prize5[Client]=2;
		}
		case 3:
		{
			prize5[Client]=3;
		}
		case 4:
		{
			prize5[Client]=4;
		}
		case 5:
		{
			prize5[Client]=5;
		}
	}
}

public Action:sift_start6(Client)//1
{
	new diceNum6 = GetRandomInt(1, 2);
	switch (diceNum6)
	{
		case 1:
		{
			prize6[Client]=1;
		}
		case 2:
		{
			prize6[Client]=2;
		}
	}
}

public Action:Award_List(Client)
{
	decl String:line[1024];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "-本次简历-");
	SetPanelTitle(menu, line);
	if(prize1[Client]==1)
	{
		Format(line, sizeof(line), "【★★★★★★】安洁莉娜");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==2)
	{
		Format(line, sizeof(line), "【★★★★★★】星熊");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==3)
	{
		Format(line, sizeof(line), "【★★★★★★】能天使");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==4)
	{
		Format(line, sizeof(line), "【★★★★★★】陈");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==5)
	{
		Format(line, sizeof(line), "【★★★★★★】闪灵");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==6)
	{
		Format(line, sizeof(line), "【★★★★★★】夜莺");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==7)
	{
		Format(line, sizeof(line), "【★★★★★★】银灰");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==8)
	{
		Format(line, sizeof(line), "【★★★★★★】艾雅法拉");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==9)
	{
		Format(line, sizeof(line), "【★★★★★★】伊芙利特");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==10)
	{
		Format(line, sizeof(line), "【★★★★★★】斯卡蒂");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==11)
	{
		Format(line, sizeof(line), "【★★★★★★】推进之王");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==12)
	{
		Format(line, sizeof(line), "【★★★★★★】塞雷娅");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==13)
	{
		Format(line, sizeof(line), "【★★★★★★】黑");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==14)
	{
		Format(line, sizeof(line), "【★★★★★★】赫拉格");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==15)
	{
		Format(line, sizeof(line), "【★★★★★★】麦哲伦");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==16)
	{
		Format(line, sizeof(line), "【★★★★★★】莫斯提马");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==17)
	{
		Format(line, sizeof(line), "【★★★★★★】煌");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==18)
	{
		Format(line, sizeof(line), "【★★★★★★】年");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==19)
	{
		Format(line, sizeof(line), "【★★★★★★】阿");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==20)
	{
		Format(line, sizeof(line), "【★★★★★★】刻俄柏");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==21)
	{
		Format(line, sizeof(line), "【★★★★★★】风笛");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==22)
	{
		Format(line, sizeof(line), "【★★★★★★】傀影");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==23)
	{
		Format(line, sizeof(line), "【★★★★★★】W");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==24)
	{
		Format(line, sizeof(line), "【★★★★★★】温蒂");
		DrawPanelText(menu, line);
	}
	
	if(prize2[Client]==1)
	{
		Format(line, sizeof(line), "【★★★★★】白面鸮");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==2)
	{
		Format(line, sizeof(line), "【★★★★★】凛冬");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==3)
	{
		Format(line, sizeof(line), "【★★★★★】德克萨斯");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==4)
	{
		Format(line, sizeof(line), "【★★★★★】芙兰卡");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==5)
	{
		Format(line, sizeof(line), "【★★★★★】拉普兰德");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==6)
	{
		Format(line, sizeof(line), "【★★★★★】幽灵鲨");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==7)
	{
		Format(line, sizeof(line), "【★★★★★】蓝毒");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==8)
	{
		Format(line, sizeof(line), "【★★★★★】白金");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==9)
	{
		Format(line, sizeof(line), "【★★★★★】陨星");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==10)
	{
		Format(line, sizeof(line), "【★★★★★】天火");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==11)
	{
		Format(line, sizeof(line), "【★★★★★】梅尔");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==12)
	{
		Format(line, sizeof(line), "【★★★★★】赫默");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==13)
	{
		Format(line, sizeof(line), "【★★★★★】华法琳");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==14)
	{
		Format(line, sizeof(line), "【★★★★★】临光");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==15)
	{
		Format(line, sizeof(line), "【★★★★★】红");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==16)
	{
		Format(line, sizeof(line), "【★★★★★】雷蛇");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==17)
	{
		Format(line, sizeof(line), "【★★★★★】可颂");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==18)
	{
		Format(line, sizeof(line), "【★★★★★】普罗旺斯");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==19)
	{
		Format(line, sizeof(line), "【★★★★★】守林人");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==20)
	{
		Format(line, sizeof(line), "【★★★★★】崖心");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==21)
	{
		Format(line, sizeof(line), "【★★★★★】初雪");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==22)
	{
		Format(line, sizeof(line), "【★★★★★】真理");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==23)
	{
		Format(line, sizeof(line), "【★★★★★】空");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==24)
	{
		Format(line, sizeof(line), "【★★★★★】狮蝎");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==25)
	{
		Format(line, sizeof(line), "【★★★★★】食铁兽");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==26)
	{
		Format(line, sizeof(line), "【★★★★★】夜魔");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==27)
	{
		Format(line, sizeof(line), "【★★★★★】诗怀雅");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==28)
	{
		Format(line, sizeof(line), "【★★★★★】火神");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==29)
	{
		Format(line, sizeof(line), "【★★★★★】因陀罗");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==30)
	{
		Format(line, sizeof(line), "【★★★★★】阿米娅");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==31)
	{
		Format(line, sizeof(line), "【★★★★★】暴行");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==32)
	{
		Format(line, sizeof(line), "【★★★★★】格拉尼");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==33)
	{
		Format(line, sizeof(line), "【★★★★★】锡兰");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==34)
	{
		Format(line, sizeof(line), "【★★★★★】格劳克斯");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==35)
	{
		Format(line, sizeof(line), "【★★★★★】星极");
		DrawPanelText(menu, line);
	}
	
	if(prize3[Client]==1)
	{
		Format(line, sizeof(line), "【★★★★】夜烟");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==2)
	{
		Format(line, sizeof(line), "【★★★★】远山");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==3)
	{
		Format(line, sizeof(line), "【★★★★】杰西卡");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==4)
	{
		Format(line, sizeof(line), "【★★★★】流星");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==5)
	{
		Format(line, sizeof(line), "【★★★★】白雪");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==6)
	{
		Format(line, sizeof(line), "【★★★★】清道夫");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==7)
	{
		Format(line, sizeof(line), "【★★★★】红豆");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==8)
	{
		Format(line, sizeof(line), "【★★★★】杜宾");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==9)
	{
		Format(line, sizeof(line), "【★★★★】缠丸");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==10)
	{
		Format(line, sizeof(line), "【★★★★】霜叶");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==11)
	{
		Format(line, sizeof(line), "【★★★★】慕斯");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==12)
	{
		Format(line, sizeof(line), "【★★★★】砾");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==13)
	{
		Format(line, sizeof(line), "【★★★★】暗索");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==14)
	{
		Format(line, sizeof(line), "【★★★★】末药");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==15)
	{
		Format(line, sizeof(line), "【★★★★】调香师");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==16)
	{
		Format(line, sizeof(line), "【★★★★】角峰");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==17)
	{
		Format(line, sizeof(line), "【★★★★】蛇屠箱");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==18)
	{
		Format(line, sizeof(line), "【★★★★】古米");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==19)
	{
		Format(line, sizeof(line), "【★★★★】深海色");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==20)
	{
		Format(line, sizeof(line), "【★★★★】地灵");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==21)
	{
		Format(line, sizeof(line), "【★★★★】阿消");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==22)
	{
		Format(line, sizeof(line), "【★★★★】猎蜂");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==23)
	{
		Format(line, sizeof(line), "【★★★★】格雷伊");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==24)
	{
		Format(line, sizeof(line), "【★★★★】艾丝黛尔");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==25)
	{
		Format(line, sizeof(line), "【★★★★】讯使");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==26)
	{
		Format(line, sizeof(line), "【★★★★】嘉维尔");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==27)
	{
		Format(line, sizeof(line), "【★★★★】苏苏洛");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==28)
	{
		Format(line, sizeof(line), "【★★★★】桃金娘");
		DrawPanelText(menu, line);
	}
	
	if(prize4[Client]==1)
	{
		Format(line, sizeof(line), "【★★★】芬");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==2)
	{
		Format(line, sizeof(line), "【★★★】香草");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==3)
	{
		Format(line, sizeof(line), "【★★★】翎羽");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==4)
	{
		Format(line, sizeof(line), "【★★★】玫兰莎");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==5)
	{
		Format(line, sizeof(line), "【★★★】卡缇");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==6)
	{
		Format(line, sizeof(line), "【★★★】米格鲁");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==7)
	{
		Format(line, sizeof(line), "【★★★】克洛丝");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==8)
	{
		Format(line, sizeof(line), "【★★★】炎熔");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==9)
	{
		Format(line, sizeof(line), "【★★★】芙蓉");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==10)
	{
		Format(line, sizeof(line), "【★★★】安赛尔");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==11)
	{
		Format(line, sizeof(line), "【★★★】史都华德");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==12)
	{
		Format(line, sizeof(line), "【★★★】梓兰");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==13)
	{
		Format(line, sizeof(line), "【★★★】空爆");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==14)
	{
		Format(line, sizeof(line), "【★★★】月见夜");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==15)
	{
		Format(line, sizeof(line), "【★★★】斑点");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==16)
	{
		Format(line, sizeof(line), "【★★★】泡普卡");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==17)
	{
		Format(line, sizeof(line), "【★★★】安德切尔");
		DrawPanelText(menu, line);
	}
	
	if(prize5[Client]==1)
	{
		Format(line, sizeof(line), "【★★】夜刀");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==2)
	{
		Format(line, sizeof(line), "【★★】黑角");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==3)
	{
		Format(line, sizeof(line), "【★★】巡林者");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==4)
	{
		Format(line, sizeof(line), "【★★】杜林");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==5)
	{
		Format(line, sizeof(line), "【★★】12F");
		DrawPanelText(menu, line);
	}
	
	if(prize6[Client]==1)
	{
		Format(line, sizeof(line), "【★】Lancet-2");
		DrawPanelText(menu, line);
	} else if(prize6[Client]==2)
	{
		Format(line, sizeof(line), "【★】Castle-3");
		DrawPanelText(menu, line);
	}
	
	Format(line, sizeof(line), "开始寻访");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Start, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
	
public Start(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
				StopTime[Client] = CreateTimer(0.04, Roll, Client, TIMER_REPEAT);
				rolled[Client]=true;
				draw_function(Client);
				L[Client]-=1;
			}
			case 2:
			{
				draw_function(Client);
			}
		}
	}
}

public Action:Roll(Handle:timer, any:Client)
{
	decl String:show[128];
	new extract = GetRandomInt(1, 50);
	switch (extract)
	{
		case 1:
		{
			Format(show, sizeof(show), "★★★★★★");
			gain[Client]=1;
		}
		case 2:
		{
			Format(show, sizeof(show), "★★★★★");
			gain[Client]=2;
		}
		case 3:
		{
			Format(show, sizeof(show), "★★★★★");
			gain[Client]=2;
		}
		case 4:
		{
			Format(show, sizeof(show), "★★★★★");
			gain[Client]=2;
		}
		case 5:
		{
			Format(show, sizeof(show), "★★★★★");
			gain[Client]=2;
		}
		case 6:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 7:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 8:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 9:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 10:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 11:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 12:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 13:
		{
			Format(show, sizeof(show), "★★★★");
			gain[Client]=3;
		}
		case 14:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 15:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 16:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 17:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 18:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 19:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 20:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 21:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 22:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 23:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 24:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 25:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 26:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 27:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 28:
		{
			Format(show, sizeof(show), "★★★");
			gain[Client]=4;
		}
		case 29:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 30:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 31:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 32:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 33:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 34:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 35:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 36:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 37:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 38:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 39:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 40:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 41:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 42:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 43:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 44:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 45:
		{
			Format(show, sizeof(show), "★★");
			gain[Client]=5;
		}
		case 46:
		{
			Format(show, sizeof(show), "★");
			gain[Client]=6;
		}
		case 47:
		{
			Format(show, sizeof(show), "★");
			gain[Client]=6;
		}
		case 48:
		{
			Format(show, sizeof(show), "★");
			gain[Client]=6;
		}
		case 49:
		{
			Format(show, sizeof(show), "★");
			gain[Client]=6;
		}
		case 50:
		{
			Format(show, sizeof(show), "★");
			gain[Client]=6;
		}
	}
	PrintCenterText(Client, "★寻访中★     → %s     请在列表中选择: -开包- ", show);
	EmitSoundToClient(Client, "ui/littlereward.wav");
}

stock CheatCommand(Client, const String:command[], const String:arguments[])
{
    if (!Client) return;
    new admindata = GetUserFlagBits(Client);
    SetUserFlagBits(Client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(Client, admindata);
}

Handle:AttachParticle(ent, String:particleType[], Float:time=10.0)
{
	if (ent < 1)
	{
		return INVALID_HANDLE;
	}

	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		decl String:tName[32];
		new Float:pos[3];

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 60;

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		if (DispatchSpawn(particle))
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			SetVariantString("OnUser1 !self,Start,,0.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			SetVariantString("OnUser2 !self,Stop,,4.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			ActivateEntity(particle);
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");

			new Handle:pack;
			new Handle:hTimer;
			hTimer = CreateDataTimer(time, DeleteParticle, pack);
			WritePackCell(pack, particle); 
			WritePackString(pack, particleType);
			WritePackCell(pack, ent); 

			new Handle:packLoop;
			hTimerLoopEffect[ent] = CreateDataTimer(4.2, LoopParticleEffect, packLoop, TIMER_REPEAT);
			WritePackCell(packLoop, particle); 
			WritePackCell(packLoop, ent);

			return hTimer;
		} 
		else 
		{
			if (IsValidEdict(particle))
			{
				RemoveEdict(particle);
			}
			return INVALID_HANDLE;
		}
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, Handle:pack)
{
	decl String:particleType[32];

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	ReadPackString(pack, particleType, sizeof(particleType));
	new client = ReadPackCell(pack); 

	if (hTimerLoopEffect[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerLoopEffect[client]);
		hTimerLoopEffect[client] = INVALID_HANDLE;
	}

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}

	if (StrEqual(particleType, "achieved", true))
	{
		hTimerAchieved[client] = INVALID_HANDLE;
	} 
	else if (StrEqual(particleType, "mini_fireworks", true)) 
	{
		hTimerMiniFireworks[client] = INVALID_HANDLE;
	}
}

public Action:LoopParticleEffect(Handle:timer, Handle:pack)
{

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new client = ReadPackCell(pack);

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");
			return Plugin_Continue;
		}
	}
	hTimerLoopEffect[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Msg(Handle:timer, any:data)
{
	PrintToChatAll("\x03罗德岛v4寻访活动开启！优化系统加干员！聊天框输入 \x04!xf \x03打开 \x01【\x04寻访系统\x01】");

}

stock bool:IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}