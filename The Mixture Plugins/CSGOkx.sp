#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define QT		"\x03玩家\x04%N\x03抽到了\x01%s \x02%s(%s)%s"
#define PIE	"\x04你抽中了\x01%s \x05→ \x02%s"
#define PH		"\x03玩家\x04%N\x03抽到了\x01%s \x05→ \x02%s"

#define DD		"buttons/button14.wav"

new Handle:hTimerAchieved[MAXPLAYERS+1];
new Handle:hTimerMiniFireworks[MAXPLAYERS+1];
new Handle:hTimerLoopEffect[MAXPLAYERS+1];
new bool:rolled[MAXPLAYERS+1];
new bool:sift[MAXPLAYERS+1];
new bool:Lsift[MAXPLAYERS+1];
new bool:G2sift[MAXPLAYERS+1];
new count[MAXPLAYERS+1];
new float:L[MAXPLAYERS+1];
new float:H[MAXPLAYERS+1];
new float:T[MAXPLAYERS+1];
new gain[MAXPLAYERS+1];
new prize1[MAXPLAYERS+1];
new prize2[MAXPLAYERS+1];
new prize3[MAXPLAYERS+1];
new prize4[MAXPLAYERS+1];
new prize5[MAXPLAYERS+1];
new Lprize2[MAXPLAYERS+1];
new Lprize3[MAXPLAYERS+1];
new Lprize4[MAXPLAYERS+1];
new Lprize5[MAXPLAYERS+1];
new G2prize2[MAXPLAYERS+1];
new G2prize3[MAXPLAYERS+1];
new G2prize4[MAXPLAYERS+1];
new G2prize5[MAXPLAYERS+1];
new pingzhi[MAXPLAYERS+1];
new aj[MAXPLAYERS+1];
new prize6[MAXPLAYERS+1];
new Handle:StopTime[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:LDW_MSG_time;

new Gold[MAXPLAYERS+1];
new Red[MAXPLAYERS+1];
new Pink[MAXPLAYERS+1];
new Purple[MAXPLAYERS+1];
new Blue[MAXPLAYERS+1];
new GCount[MAXPLAYERS+1];
new RCount[MAXPLAYERS+1];
new PiCount[MAXPLAYERS+1];
new PuCount[MAXPLAYERS+1];
new BCount[MAXPLAYERS+1];

new Handle:timer_handle=INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_opencase",LDW);
	HookEvent("round_start", round_start);
	HookEvent("round_end",				Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	
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
		Format(line, sizeof(line), "   -CSGO开箱系统-");
		SetPanelTitle(menu, line);
		Format(line, sizeof(line), "你已花费了%d元人民币", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "【详情请查看规则说明】");
		DrawPanelText(menu, line);
		
		Format(line, sizeof(line), "准备开箱");
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
		Format(line, sizeof(line), "   开箱中...  ", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "~~~~~~~~~~~~~~", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "-开箱-");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "如果列表关闭,请再次打开,选择:-开箱-", ITEMDRAW_DISABLED);
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
				Opencase(Client);
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

public Action:Opencase(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    请选择你要打开的箱子");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "棱彩武器箱");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "裂网大行动武器箱");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "光谱2号武器箱");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, OpenCase, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public OpenCase(Handle:menu, MenuAction:action, Client, param)
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
						sift[Client]=false;
					}
					Lprize2[Client] = 0;
					Lprize3[Client] = 0;
					Lprize4[Client] = 0;
					Lprize5[Client] = 0;
					G2prize2[Client] = 0;
					G2prize3[Client] = 0;
					G2prize4[Client] = 0;
					G2prize5[Client] = 0;
					Award_List(Client);
			}
			case 2:
			{
                    if(sift[Client])
					{
						sift_start1(Client);
						Lsift_start2(Client);
						Lsift_start3(Client);
						Lsift_start4(Client);
						Lsift_start5(Client);
						Lsift[Client]=false;
					}
					prize2[Client] = 0;
					prize3[Client] = 0;
					prize4[Client] = 0;
					prize5[Client] = 0;
					G2prize2[Client] = 0;
					G2prize3[Client] = 0;
					G2prize4[Client] = 0;
					G2prize5[Client] = 0;
					Award_List(Client);
			}
			case 3:
			{
                    if(sift[Client])
					{
						sift_start1(Client);
						G2sift_start2(Client);
						G2sift_start3(Client);
						G2sift_start4(Client);
						G2sift_start5(Client);
						G2sift[Client]=false;
					}
					Lprize2[Client] = 0;
					Lprize3[Client] = 0;
					Lprize4[Client] = 0;
					Lprize5[Client] = 0;
					prize2[Client] = 0;
					prize3[Client] = 0;
					prize4[Client] = 0;
					prize5[Client] = 0;
					Award_List(Client);
			}
			case 4:
			{
				draw_function(Client);
			}
		}
	}
}

public Action:Explain(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel(); 
	Format(line, sizeof(line), "    -G胖的规则说明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "请选择你想了解的说明");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "操作说明");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "获得饰品颜色展示");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "饰品出现概率");
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
	Format(line, sizeof(line), ">开箱想开多少就开多少");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">请点击主菜单的 【准备开箱】");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">此时会出现一个列表,上面显示会获得的饰品");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">然后选择【开始开箱】");
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
	Format(line, sizeof(line), ">此时你准心上方会出现一个跳动的条");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">当你选择菜单中的【-开箱-】时,条停止跳动");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">你即可获得颜色栏对应的饰品");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">祝您顺利，玩家");
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
	Format(line, sizeof(line), "  -您已获得的饰品颜色数量-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">金色：%d(带计数器：%d) 红色：%d(带计数器：%d)", Gold[Client], GCount[Client], Red[Client], RCount[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">粉色：%d(带计数器：%d) 紫色：%d(带计数器：%d)", Pink[Client], PiCount[Client], Purple[Client], PuCount[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">蓝色：%d(带计数器：%d)", Blue[Client], BCount[Client]);
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
	Format(line, sizeof(line), "   -饰品出现概率-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "以下为抽奖跳动时,各类颜色出现概率:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">金色饰品0.5％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">红色饰品2％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">粉色饰品5％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">紫色饰品20％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">蓝色饰品72.5％出现");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">所有暗金饰品几率均为普通的1/5");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Back, MENU_TIME_FOREVER);
	CloseHandle(menu);
}


public Action:Award(Client)//** 发放结果 **//
{
	decl String:ms[128];
	decl String:hd[8192];
	decl String:pz[8192];
	if(gain[Client]==1)
	{
		if(prize1[Client]==1)
		{
			Format(hd, sizeof(hd), "鲍伊猎刀（★）| 致命紫罗兰");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9465.74;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2695.7;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1422.48;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1195.45;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1129.21;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 828.08;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 785.58;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 826.1;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 898.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 687.9;
				}
			}
		} else if(prize1[Client]==2)
		{
			Format(hd, sizeof(hd), "鲍伊猎刀（★）| 深红之网");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15415.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9415.8;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5100.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2469.66;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1487.58;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1263.66;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1473.62;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1277.4;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1071.45;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1001.99;
				}
			}
		} else if(prize1[Client]==3)
		{
			Format(hd, sizeof(hd), "鲍伊猎刀（★）| 表面淬火");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4675.17;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2510.46;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2608.79;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1533.69;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1487.65;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1161.73;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1275.66;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1203.02;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1087.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1130.91;
				}
			}
		} else if(prize1[Client]==4)
		{
			Format(hd, sizeof(hd), "蝴蝶刀（★）| 北方森林");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2817.75;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2452.15;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2408.1;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2105.63;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1664.67;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1411.43;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3608.79;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1481.77;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1561.25;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1629.25;
				}
			}
		} else if(prize1[Client]==5)
		{
			Format(hd, sizeof(hd), "蝴蝶刀（★）| 噩梦之夜");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 12425.31;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12235.46;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7217.58;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2833.48;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2257.08;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1749.89;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2871.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1793.03;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1859.33;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1514.57;
				}
			}
		} else if(prize1[Client]==6)
		{
			Format(hd, sizeof(hd), "蝴蝶刀（★）| 蓝钢");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1997.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1524;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1554;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1418.5;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1598;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1416;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1599;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1505;
				}
			}
		} else if(prize1[Client]==7)
		{
			Format(hd, sizeof(hd), "蝴蝶刀（★）| 渐变大理石");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4940;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4918;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4150;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4150;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4150;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4150;
				}
			}
		} else if(prize1[Client]==8)
		{
			Format(hd, sizeof(hd), "熊刀（★）| 深红之网");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 16000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 16000;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2570;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2570;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1439;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1439;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1318.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1318.5;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 887.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 887.5;
				}
			}
		} else if(prize1[Client]==9)
		{
			Format(hd, sizeof(hd), "折叠刀（★）| 多普勒");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "P3");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1177;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 941.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "P1");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1198;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 959;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "红宝石");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5699;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "蓝宝石");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9500;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 7033;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "黑珍珠");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4800;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3300;
				}
			}
		} else if(prize1[Client]==10)
		{
			Format(hd, sizeof(hd), "爪子刀（★）| 自动化");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==11)
		{
			Format(hd, sizeof(hd), "爪子刀（★）| 蓝钢");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==12)
		{
			Format(hd, sizeof(hd), "爪子刀（★）| 传说");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==13)
		{
			Format(hd, sizeof(hd), "爪子刀（★）| 人工染色");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==14)
		{
			Format(hd, sizeof(hd), "爪子刀（★）| 自动化");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==15)
		{
			Format(hd, sizeof(hd), "折刀（★）| 夜色");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==16)
		{
			Format(hd, sizeof(hd), "求生匕首（★）| 夜色");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==17)
		{
			Format(hd, sizeof(hd), "求生匕首（★）| 深红之网");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==18)
		{
			Format(hd, sizeof(hd), "流浪者匕首（★）| 北方森林");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==19)
		{
			Format(hd, sizeof(hd), "流浪者匕首（★）| 表面淬火");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==20)
		{
			Format(hd, sizeof(hd), "骷髅匕首（★）| 人工染色");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		} else if(prize1[Client]==21)
		{
			Format(hd, sizeof(hd), "骷髅匕首（★）| 表面淬火");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9000;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5443.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3468;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 3210;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2475;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2349;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2789.05;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2290;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1897.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1728;
				}
			}
		}
		if(aj[Client]==1)
				{
				    GCount[Client] += 1;
				}
		Gold[Client] += 1;
		Format(ms, sizeof(ms), "金色");
		PrintToChatAll(QT, Client, ms, hd, pz, aj);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client] == 2)
	{
		if(prize2[Client]==1)
		{
			Format(hd, sizeof(hd), "M4A4 | 皇帝");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2997.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 698.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 830;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 320;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 359.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 129;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 320;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 109;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 190;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 76;
				}
			}
		} else if(prize2[Client]==2)
		{
			Format(hd, sizeof(hd), "FN57 | 怒氓");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 280;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 54.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 91;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 32;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 44.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.9;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 49.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 18.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.3;
				}
			}
		} else if(Lprize2[Client]==1)
		{
			Format(hd, sizeof(hd), "AWP | 冲出重围");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2997.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 698.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 830;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 320;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 359.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 129;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 320;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 109;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 190;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 76;
				}
			}
		} else if(Lprize2[Client]==2)
		{
			Format(hd, sizeof(hd), "MAC-10 | 潜行者");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 280;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 54.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 91;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 32;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 44.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.9;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 49.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 18.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.3;
				}
			}
		} else if(G2prize2[Client]==1)
		{
			Format(hd, sizeof(hd), "AK-47 | 皇后");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2997.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 698.5;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 830;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 320;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 359.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 129;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 320;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 109;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 190;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 76;
				}
			}
		} else if(G2prize2[Client]==2)
		{
			Format(hd, sizeof(hd), "P250 | 生化短吻鳄");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 280;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 54.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 91;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 32;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 44.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.9;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 49.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 18.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.3;
				}
			}
		}
		if(aj[Client]==1)
				{
				    RCount[Client] += 1;
				}
		Red[Client] += 1;
		Format(ms, sizeof(ms), "红色");
		PrintToChatAll(QT, Client, ms, hd, pz, aj);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==3)
	{
		if(prize3[Client]==1)
		{
			Format(hd, sizeof(hd), "R8 | 头骨粉碎者");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.85;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 16.57;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.39;
				}
			}
		} else if(prize3[Client]==2)
		{
			Format(hd, sizeof(hd), "AUG | 动量");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 748;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 132.48;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 141.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.5;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.3;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 25.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 11.5;
				}
			}
		} else if(prize3[Client]==3)
		{
			Format(hd, sizeof(hd), "XM1014 | 焚烬之鳄");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 212.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 24.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.1;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.89;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			}
		} else if(Lprize3[Client]==1)
		{
			Format(hd, sizeof(hd), "Tec-9 | 屠杀者");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.85;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 16.57;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.39;
				}
			}
		} else if(Lprize3[Client]==2)
		{
			Format(hd, sizeof(hd), "SG 553 | 四号栖息地");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 748;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 132.48;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 141.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.5;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.3;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 25.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 11.5;
				}
			}
		} else if(Lprize3[Client]==3)
		{
			Format(hd, sizeof(hd), "SSG 08 | 喋血战士");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 212.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 24.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.1;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.89;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			}
		} else if(G2prize3[Client]==1)
		{
			Format(hd, sizeof(hd), "PP-野牛 | 买定离手");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 27.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.18;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.85;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 16.57;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.39;
				}
			}
		} else if(G2prize3[Client]==2)
		{
			Format(hd, sizeof(hd), "M4A1 消音型 | 破碎铅秋");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 748;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 132.48;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 141.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.5;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 43;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 10.3;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 25.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 11.5;
				}
			}
		} else if(G2prize3[Client]==3)
		{
			Format(hd, sizeof(hd), "R8 左轮手枪 | 美洲驼炮");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 212.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 39.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 24.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.1;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 15.89;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 12.8;
				}
			}
		}
		if(aj[Client]==1)
				{
				    PiCount[Client] += 1;
				}
		Pink[Client] += 1;
		Format(ms, sizeof(ms), "粉色");
		PrintToChatAll(QT, Client, ms, hd, pz, aj);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==4)
	{
		if(prize4[Client]==1)
		{
			Format(hd, sizeof(hd), "AWP | 树蝰");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 213.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 60.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 92.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 28.7;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 50;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 39.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 41.69;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			}
		} else if(prize4[Client]==2)
		{
			Format(hd, sizeof(hd), "Tec-9 | 青竹伪装");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 18.75;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.75;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.47;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.83;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.96;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.33;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.1;
				}
			}
		} else if(prize4[Client]==3)
		{
			Format(hd, sizeof(hd), "沙漠之鹰 | 轻轨");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 81;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 20;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 37;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.4;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.47;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.73;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.4;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.16;
				}
			}
		} else if(prize4[Client]==4)
		{
			Format(hd, sizeof(hd), "MP5-SD | 高斯");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.65;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 6.14;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 11.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.85;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.71;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.96;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.86;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.45;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.88;
				}
			}
		} else if(prize4[Client]==5)
		{
			Format(hd, sizeof(hd), "UMP-45 | 城里的月光");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 14.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.85;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.42;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.82;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			}
		} else if(Lprize4[Client]==1)
		{
			Format(hd, sizeof(hd), "PP-野牛 | 路霸");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 213.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 60.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 92.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 28.7;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 50;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 39.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 41.69;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			}
		} else if(Lprize4[Client]==2)
		{
			Format(hd, sizeof(hd), "AK-47 | 复古浪潮");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 18.75;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.75;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.47;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.83;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.96;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.33;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.1;
				}
			}
		} else if(Lprize4[Client]==3)
		{
			Format(hd, sizeof(hd), "AUG | 绝地孤狼");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 81;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 20;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 37;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.4;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.47;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.73;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.4;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.16;
				}
			}
		} else if(Lprize4[Client]==4)
		{
			Format(hd, sizeof(hd), "MP7 | 七彩斑斓");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.65;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 6.14;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 11.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.85;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.71;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.96;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.86;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.45;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.88;
				}
			}
		} else if(Lprize4[Client]==5)
		{
			Format(hd, sizeof(hd), "P2000 | 黑曜石");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 14.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.85;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.42;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.82;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			}
		} else if(G2prize4[Client]==1)
		{
			Format(hd, sizeof(hd), "MP9 | 焦油缠绕");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 213.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 60.9;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 92.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 28.7;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 50;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 17.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 39.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 41.69;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 14;
				}
			}
		} else if(G2prize4[Client]==2)
		{
			Format(hd, sizeof(hd), "SG 553 | 幻影");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 18.75;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.75;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.47;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.83;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.96;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.33;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.1;
				}
			}
		} else if(G2prize4[Client]==3)
		{
			Format(hd, sizeof(hd), "CZ75 自动手枪 | 战术高手");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 81;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 20;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 37;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 9.4;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.47;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 19.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.73;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.4;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.16;
				}
			}
		} else if(G2prize4[Client]==4)
		{
			Format(hd, sizeof(hd), "UMP-45 | X射线");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 29.65;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 6.14;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 11.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.85;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.71;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3.96;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.86;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.45;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.88;
				}
			}
		} else if(G2prize4[Client]==5)
		{
			Format(hd, sizeof(hd), "XM1014 | 五彩斑驳");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 14.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.85;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.42;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.82;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.25;
				}
			}
		}
		if(aj[Client]==1)
				{
				    PuCount[Client] += 1;
				}
		Purple[Client] += 1;
		Format(ms, sizeof(ms), "紫色");
		PrintToChatAll(QT, Client, ms, hd, pz, aj);
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==5)
	{
		if(prize5[Client]==1)
		{
			Format(hd, sizeof(hd), "法玛斯 | 保护色");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.23;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.32;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.98;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.54;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.36;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.97;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.35;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(prize5[Client]==2)
		{
			Format(hd, sizeof(hd), "AK-47 | 迷踪秘境");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 35.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 8.38;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.35;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.2;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.64;
				}
			}
		} else if(prize5[Client]==3)
		{
			Format(hd, sizeof(hd), "MAC-10 | 白鲑鱼");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.24;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.98;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.43;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.88;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.58;
				}
			}
		} else if(prize5[Client]==4)
		{
			Format(hd, sizeof(hd), "加利尔AR | 战吼斑纹");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.68;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.62;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.95;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.6;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(prize5[Client]==5)
		{
			Format(hd, sizeof(hd), "MP7 | 恶作剧");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.82;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.67;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			}
		} else if(prize5[Client]==6)
		{
			Format(hd, sizeof(hd), "P250 | 铜绿");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.44;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.2;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.48;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.87;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.84;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.74;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			}
		} else if(prize5[Client]==7)
		{
			Format(hd, sizeof(hd), "P90 | 异星世界");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.26;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.56;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.67;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.06;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.72;
				}
			}
		} else if(Lprize5[Client]==1)
		{
			Format(hd, sizeof(hd), "MP5-SD | 鼻青脸肿");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.23;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.32;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.98;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.54;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.36;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.97;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.35;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(Lprize5[Client]==2)
		{
			Format(hd, sizeof(hd), "新星 | 风卷残云");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 35.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 8.38;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.35;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.2;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.64;
				}
			}
		} else if(Lprize5[Client]==3)
		{
			Format(hd, sizeof(hd), "G3SG1 | 黑砂");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.24;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.98;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.43;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.88;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.58;
				}
			}
		} else if(Lprize5[Client]==4)
		{
			Format(hd, sizeof(hd), "R8 左轮手枪 | 记忆碎片");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.68;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.62;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.95;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.6;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(Lprize5[Client]==5)
		{
			Format(hd, sizeof(hd), "双持贝瑞塔 | 左右开花");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.82;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.67;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			}
		} else if(Lprize5[Client]==6)
		{
			Format(hd, sizeof(hd), "SCAR-20 | 撕起来");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.44;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.2;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.48;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.87;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.84;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.74;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			}
		} else if(Lprize5[Client]==7)
		{
			Format(hd, sizeof(hd), "M249 | 战隼");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.26;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.56;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.67;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.06;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.72;
				}
			}
		} else if(G2prize5[Client]==1)
		{
			Format(hd, sizeof(hd), "截断霰弹枪 | 夜百合");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.23;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.32;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.98;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.54;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.68;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.36;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.97;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
			    if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.35;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(G2prize5[Client]==2)
		{
			Format(hd, sizeof(hd), "AUG | 三角战术");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 35.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 8.38;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 21;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 4.35;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.8;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 17.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 5.2;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 15.7;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.64;
				}
			}
		} else if(G2prize5[Client]==3)
		{
			Format(hd, sizeof(hd), "G3SG1 | 猎人");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.24;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.98;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.43;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 3;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.61;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.88;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.58;
				}
			}
		} else if(G2prize5[Client]==4)
		{
			Format(hd, sizeof(hd), "格洛克 18 型 | 异星世界");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 7.87;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.68;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.99;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.62;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.95;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.6;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.49;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.69;
				}
			}
		} else if(G2prize5[Client]==5)
		{
			Format(hd, sizeof(hd), "MAC-10 | 海洋");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 9.82;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.67;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.9;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.47;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.59;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.71;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.46;
				}
			}
		} else if(G2prize5[Client]==6)
		{
			Format(hd, sizeof(hd), "Tec-9 | 碎蛋白石");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.44;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.2;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 4.94;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.48;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.87;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.84;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 1.74;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.55;
				}
			}
		} else if(G2prize5[Client]==7)
		{
			Format(hd, sizeof(hd), "SCAR-20 | 丛林滑流");
			if(pingzhi[Client]==1)
			{
			    Format(pz, sizeof(pz), "崭新出厂");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 8.38;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 2.26;
				}
			} else if(pingzhi[Client]==2)
			{
			    Format(pz, sizeof(pz), "略有磨损");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 5;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 1.56;
				}
			} else if(pingzhi[Client]==3)
			{
			    Format(pz, sizeof(pz), "久经沙场");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.2;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.8;
				}
			} else if(pingzhi[Client]==4)
			{
			    Format(pz, sizeof(pz), "破损不堪");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.67;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.78;
				}
			} else if(pingzhi[Client]==5)
			{
			    Format(pz, sizeof(pz), "战痕累累");
				if(aj[Client]==1)
				{
				    Format(aj, sizeof(aj), "暗金");
					H[Client] += 2.06;
				} else if(aj[Client]==2)
				{
				    Format(aj, sizeof(aj), "");
				    H[Client] += 0.72;
				}
			}
		}
		if(aj[Client]==1)
				{
				    BCount[Client] += 1;
				}
		Blue[Client] += 1;
		Format(ms, sizeof(ms), "蓝色");
		PrintToChatAll(QT, Client, ms, hd, pz, aj);
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
}

public Action:sift_start1(Client)//6
{
	new diceNum = GetRandomInt(1, 21);
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
	}
}

public Action:sift_start2(Client)//5
{
	new diceNum2 = GetRandomInt(1, 2);
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
	}
}

public Action:Lsift_start2(Client)//5
{
	new diceNum2 = GetRandomInt(1, 2);
	switch (diceNum2)
	{
		case 1:
		{
			Lprize2[Client]=1;
		}
		case 2:
		{
			Lprize2[Client]=2;
		}
	}
}

public Action:G2sift_start2(Client)//5
{
	new diceNum2 = GetRandomInt(1, 2);
	switch (diceNum2)
	{
		case 1:
		{
			G2prize2[Client]=1;
		}
		case 2:
		{
			G2prize2[Client]=2;
		}
	}
}

public Action:sift_start3(Client)//4
{
	new diceNum3 = GetRandomInt(1, 3);
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
	}
}

public Action:Lsift_start3(Client)//4
{
	new diceNum3 = GetRandomInt(1, 3);
	switch (diceNum3)
	{
		case 1:
		{
			Lprize3[Client]=1;
		}
		case 2:
		{
			Lprize3[Client]=2;
		}
		case 3:
		{
			Lprize3[Client]=3;
		}
	}
}

public Action:G2sift_start3(Client)//4
{
	new diceNum3 = GetRandomInt(1, 3);
	switch (diceNum3)
	{
		case 1:
		{
			G2prize3[Client]=1;
		}
		case 2:
		{
			G2prize3[Client]=2;
		}
		case 3:
		{
			G2prize3[Client]=3;
		}
	}
}

public Action:sift_start4(Client)//3
{
	new diceNum4 = GetRandomInt(1, 5);
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
	}
}

public Action:Lsift_start4(Client)//3
{
	new diceNum4 = GetRandomInt(1, 5);
	switch (diceNum4)
	{
		case 1:
		{
			Lprize4[Client]=1;
		}
		case 2:
		{
			Lprize4[Client]=2;
		}
		case 3:
		{
			Lprize4[Client]=3;
		}
		case 4:
		{
			Lprize4[Client]=4;
		}
		case 5:
		{
			Lprize4[Client]=5;
		}
	}
}

public Action:G2sift_start4(Client)//3
{
	new diceNum4 = GetRandomInt(1, 5);
	switch (diceNum4)
	{
		case 1:
		{
			G2prize4[Client]=1;
		}
		case 2:
		{
			G2prize4[Client]=2;
		}
		case 3:
		{
			G2prize4[Client]=3;
		}
		case 4:
		{
			G2prize4[Client]=4;
		}
		case 5:
		{
			G2prize4[Client]=5;
		}
	}
}

public Action:sift_start5(Client)//2
{
	new diceNum5 = GetRandomInt(1, 7);
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
		case 6:
		{
			prize5[Client]=6;
		}
		case 7:
		{
			prize5[Client]=7;
		}
	}
}

public Action:Lsift_start5(Client)//2
{
	new diceNum5 = GetRandomInt(1, 7);
	switch (diceNum5)
	{
		case 1:
		{
			Lprize5[Client]=1;
		}
		case 2:
		{
			Lprize5[Client]=2;
		}
		case 3:
		{
			Lprize5[Client]=3;
		}
		case 4:
		{
			Lprize5[Client]=4;
		}
		case 5:
		{
			Lprize5[Client]=5;
		}
		case 6:
		{
			Lprize5[Client]=6;
		}
		case 7:
		{
			Lprize5[Client]=7;
		}
	}
}

public Action:G2sift_start5(Client)//2
{
	new diceNum5 = GetRandomInt(1, 7);
	switch (diceNum5)
	{
		case 1:
		{
			G2prize5[Client]=1;
		}
		case 2:
		{
			G2prize5[Client]=2;
		}
		case 3:
		{
			G2prize5[Client]=3;
		}
		case 4:
		{
			G2prize5[Client]=4;
		}
		case 5:
		{
			G2prize5[Client]=5;
		}
		case 6:
		{
			G2prize5[Client]=6;
		}
		case 7:
		{
			G2prize5[Client]=7;
		}
	}
}

public Action:Award_List(Client)
{
	decl String:line[1024];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "-准备好你的开箱-");
	Format(line, sizeof(line), "开始开箱");
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
				L[Client]+=16;
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
	new extract = GetRandomInt(1, 200);
	switch (extract)
	{
		case 1:
		{
			Format(show, sizeof(show), "金色");
			gain[Client]=1;
		}
		case 2:
		{
			Format(show, sizeof(show), "红色");
			gain[Client]=2;
		}
		case 3:
		{
			Format(show, sizeof(show), "红色");
			gain[Client]=2;
		}
		case 4:
		{
			Format(show, sizeof(show), "红色");
			gain[Client]=2;
		}
		case 5:
		{
			Format(show, sizeof(show), "红色");
			gain[Client]=2;
		}
		case 6:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 7:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 8:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 9:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 10:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 11:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 12:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 13:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 14:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 15:
		{
			Format(show, sizeof(show), "粉色");
			gain[Client]=3;
		}
		case 16:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 17:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 18:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 19:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 20:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 21:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 22:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 23:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 24:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 25:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 26:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 27:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 28:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 29:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 30:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 31:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 32:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 33:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 34:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 35:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 36:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 37:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 38:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 39:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 40:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 41:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 42:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 43:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 44:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 45:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 46:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 47:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 48:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 49:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 50:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 51:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 52:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 53:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 54:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 55:
		{
			Format(show, sizeof(show), "紫色");
			gain[Client]=4;
		}
		case 56:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 57:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 58:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 59:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 60:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 61:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 62:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 63:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 64:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 65:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 66:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 67:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 68:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 69:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 70:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 71:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 72:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 73:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 74:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 75:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 76:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 77:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 78:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 79:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 80:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 81:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 82:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 83:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 84:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 85:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 86:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 87:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 88:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 89:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 90:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 91:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 92:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 93:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 94:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 95:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 96:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 97:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 98:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 99:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 100:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 101:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 102:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 103:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 104:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 105:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 106:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 107:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 108:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 109:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 110:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 111:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 112:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 113:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 114:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 115:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 116:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 117:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 118:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 119:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 120:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 121:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 122:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 123:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 124:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 125:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 126:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 127:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 128:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 129:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 130:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 131:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 132:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 133:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 134:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 135:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 136:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 137:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 138:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 139:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 140:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 141:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 142:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 143:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 144:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 145:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 146:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 147:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 148:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 149:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 150:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 151:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 152:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 153:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 154:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 155:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 156:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 157:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 158:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 159:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 160:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 161:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 162:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 163:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 164:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 165:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 166:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 167:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 168:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 169:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 170:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 171:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 172:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 173:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 174:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 175:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 176:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 177:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 178:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 179:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 180:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 181:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 182:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 183:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 184:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 185:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 186:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 187:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 188:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 189:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 190:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 191:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 192:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 193:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 194:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 195:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 196:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 197:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 198:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 199:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
		case 200:
		{
			Format(show, sizeof(show), "蓝色");
			gain[Client]=5;
		}
	}
	PrintCenterText(Client, "★开箱中★     → %s     请在列表中选择: -开箱- ", show);
	EmitSoundToClient(Client, "ui/littlereward.wav");
	
	new pz = GetRandomInt(1, 5);
	switch (pz)
	{
		case 1:
		{
			pingzhi[Client]=1;
		}
		case 2:
		{
			pingzhi[Client]=2;
		}
		case 3:
		{
			pingzhi[Client]=3;
		}
		case 4:
		{
			pingzhi[Client]=4;
		}
		case 5:
		{
			pingzhi[Client]=5;
		}
    }
	new aj1 = GetRandomInt(1, 5);
	switch (aj1)
	{
		case 1:
		{
			aj[Client]=1;
		}
		case 2:
		{
			aj[Client]=2;
		}
		case 3:
		{
			aj[Client]=2;
		}
		case 4:
		{
			aj[Client]=2;
		}
		case 5:
		{
			aj[Client]=2;
		}
    }
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
	PrintToChatAll("\x03CSGO开箱V2活动已启动！ 增加了更多箱子！聊天框输入 \x04!opencase \x03打开 \x01【\x04开箱系统\x01】");

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