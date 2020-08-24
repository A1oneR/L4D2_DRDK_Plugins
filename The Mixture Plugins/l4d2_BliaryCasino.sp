#define PLUGIN_VERSION "1.0beta"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma semicolon 1

/*=====================
	   $ ConVar $
=======================*/
new Cards[MAXPLAYERS + 1][44];
new Bet[MAXPLAYERS + 1];
new BetSetBJ[MAXPLAYERS + 1];
new BetSetHoL[MAXPLAYERS + 1];
new BetSetRS[MAXPLAYERS + 1];
new SumCardsA[MAXPLAYERS + 1];
new SumCardsB[MAXPLAYERS + 1];
new SumDiceA[MAXPLAYERS + 1];
new SumDiceB[MAXPLAYERS + 1];
new diceA[MAXPLAYERS + 1];
new diceB[MAXPLAYERS + 1];
new diceC[MAXPLAYERS + 1];
new bullet[MAXPLAYERS + 1];
new GotShot[MAXPLAYERS + 1];
new HoLFactor[MAXPLAYERS + 1];
new RSFactor[MAXPLAYERS + 1];
new totalStats = 3456;
new bool:bHaveGot[MAXPLAYERS + 1];
new bool:bWash[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[L4D2] BliaryCasino",
	author = "A1R",
	description = "",
	version = PLUGIN_VERSION,
	url = "www.drdkplugins.club"
}

/*=====================
	$ PLUGIN START! $
=======================*/
public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("plugin supports Left 4 Dead 2 only.");
	}
	
	RegConsoleCmd("sm_bet", Cmd_Bet, "Open Menu");
}

public OnMapStart()
{
}

public OnRoundStart()
{
	CasinoInitialize();
	for (new i = 0; i < MAXPLAYERS; i++)
	{
	    for (new n = 0; n < 44; n++)
		{
		    new m = 0;
		    Cards[i][n] = 1 + m;
		    m += 1;
		    if (Cards[i][n] == 11)
		    {
		        m = 0;
		    }
		}
		bHaveGot[i] = false;
		
	}
}

/*=====================
		$ Cmd $
=======================*/
public Action:Cmd_Bet(Client, args)
{
	BliaryMenu(Client);
}

public Action:BliaryMenu(Client)
{
    CasinoAddBet(Client);
	decl String:line[256];
	new Handle:menu = CreatePanel();
		Format(line, sizeof(line), "   -Bliary皇家赌场菜单-");
		SetPanelTitle(menu, line);
		Format(line, sizeof(line), "欢迎前来进行有趣的赌博");
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "希望临走时不要把裤衩子都赔光哦");
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
		DrawPanelText(menu, line);
		
		Format(line, sizeof(line), "每轮救济金");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "购买筹码");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "进入赌场");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "赌场规则");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "赌场商店");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "查看筹码量排名");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, MenuHandlerM, MENU_TIME_FOREVER);
		CloseHandle(menu);
}

public MenuHandlerM(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				DailySalary(Client);
			}
			case 2:
			{
				BuyTheBet(Client);
			}
			case 3:
			{
				IntoTheCasino(Client);
			}
			case 4:
			{
				CasinoRules(Client);
			}
			case 5:
			{
				CasinoShop(Client);
			}
			case 6:
			{
				Top100(Client);
			}
		}
	}
}

public Action:DailySalary(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场救济金领取处");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "哦，你来了？拿了这点钱快走吧，穷鬼。");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "领取100Bet（限1次）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, DailySalary2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public DailySalary2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				if (bHaveGot[Client] == false)
				{
				    Bet[Client] += 100;
					bHaveGot[Client] = true;
					PrintToChat(Client, "100B已到账，享受你的赌场时光吧");
				}else
				{
				    PrintToChat(Client, "你已经领取过救济金了");
				}
			}
			case 2:
			{
				BliaryMenu(Client);
			}
		}
	}
}

public Action:BuyTheBet(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场筹码更换处");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "欢迎来到皇家赌场，请来更换筹码以进入赌场游玩");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "使用20HP更换100Bet");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "使用管理员权限获取100Bet");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BuyTheBet2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public BuyTheBet2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			new HP = GetClientHealth(Client);
			
				if (HP > 20)
				{
				    Bet[Client] += 100;
					SetEntProp(Client, Prop_Send, "m_iHealth", HP - 20);
					PrintToChat(Client, "100B已到账，享受你的赌场时光吧");
				}else
				{
				    PrintToChat(Client, "你并没有足够的血量");
				}
			}
			case 2:
			{
			new HP = GetClientHealth(Client);
				if (GetUserFlagBits(Client)&ADMFLAG_ROOT || GetUserFlagBits(Client)&ADMFLAG_CONVARS)
				{
				    Bet[Client] += 100;
					SetEntProp(Client, Prop_Send, "m_iHealth", HP - 20);
					PrintToChat(Client, "管理员先生，你的100B已到账，享受你的赌场时光吧");
				}else
				{
				    PrintToChat(Client, "哪个哈卖批装管理取钱？");
				}
			}
			case 3:
			{
				BliaryMenu(Client);
			}
		}
	}
}

public Action:IntoTheCasino(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场入场处（求生分部）");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "欢迎来到皇家赌场，享受你在这里的时光！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "21点");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "排列3 & 排列5（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "高或低");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "德州扑克（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "梭哈（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "俄罗斯轮盘赌");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "轮盘赌（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "老虎机（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "骰子王（施工中..）");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, IntoTheCasino2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public IntoTheCasino2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    BlackJack(Client);
			}
			case 2:
			{
                NotServeNow(Client);
			}
			case 3:
			{
                HighOrLow(Client);
			}
			case 4:
			{
                NotServeNow(Client);
			}
			case 5:
			{
                NotServeNow(Client);
			}
			case 6:
			{
                RussianSpin(Client);
			}
			case 7:
			{
                NotServeNow(Client);
			}
			case 8:
			{
                NotServeNow(Client);
			}
			case 9:
			{
                NotServeNow(Client);
			}
			case 10:
			{
				BliaryMenu(Client);
			}
		}
	}
}

public Action:NotServeNow(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "施工中...！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, NSN2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public NSN2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    IntoTheCasino(Client);
			}
		}
	}
}

//=====================================
//=======21点赌场Part==================
//=====================================
public Action:BlackJack(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "欢迎来到21点会场！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "请选择你需要了解的项目！");
    DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "开始赌博");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "规则详情");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "更换筹码");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BlackJack2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public BlackJack2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    StartTheBJ(Client);
			}
			case 2:
			{
			    Rules(Client);
			}
			case 3:
			{
				BuyTheBet(Client);
			}
            case 4:
			{
				IntoTheCasino(Client);
			}
		}
	}
}
		
public Action:StartTheBJ(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "进入赌场，请选择你要下注的金额");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "5Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "5000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "一半Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全部Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BlackJackA1, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public BlackJackA1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetBJ[Client] = 5;
				Bet[Client] -= 5;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
			case 2:
			{
			if (Bet[Client] >= 50)
			    {
			    BetSetBJ[Client] = 50;
				Bet[Client] -= 50;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
			case 3:
			{
			if (Bet[Client] >= 500)
			    {
			    BetSetBJ[Client] = 500;
				Bet[Client] -= 500;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
            case 4:
			{
			if (Bet[Client] >= 5000)
			    {
			    BetSetBJ[Client] = 5000;
				Bet[Client] -= 5000;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
			case 5:
			{
			if (Bet[Client] >= 50000)
			    {
			    BetSetBJ[Client] = 50000;
				Bet[Client] -= 50000;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
			case 6:
			{
			if (Bet[Client] >= 500000)
			    {
			    BetSetBJ[Client] = 500000;
				Bet[Client] -= 500000;
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheBJ(Client);
			}
			}
			case 7:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetBJ[Client] = RoundToNearest(Bet[Client] / 10) * 10;
				Bet[Client] -= BetSetBJ[Client];
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你的Bet少于5，无法执行半下注操作");
				StartTheBJ(Client);
			}
			}
			case 8:
			{
			if (Bet[Client] >= 0)
			    {
			    BetSetBJ[Client] = Bet[Client];
				Bet[Client] -= BetSetBJ[Client];
				BlackJackA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有Bet");
				StartTheBJ(Client);
			}
			}
		}
	}
}

public Action:BlackJackA2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
    SumCardsA[Client] = SumCardsB[Client] = 0;
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "庄家:[ ][ ][ ][ ][ ] = %i", SumCardsA[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[ ][ ][ ][ ][ ] = %i", SumCardsB[Client]);
	DrawPanelText(menu, line);
	if (bWash[Client] == false)
	{
	Format(line, sizeof(line), "洗牌");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BlackJackA3, MENU_TIME_FOREVER);
	CloseHandle(menu);
	}
	else
	{
	Format(line, sizeof(line), "发牌");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BlackJackA4, MENU_TIME_FOREVER);
	CloseHandle(menu);
	}
	
}

public BlackJackA3(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    WashTheCards(Client);
				bWash[Client] = true;
				BlackJackA2(Client);
			}
		}
	}
}

public Action:WashTheCards(Client)//说明
{
	for (new i = GetRandomInt(50,340); i >= 0; i--)
	{
        new changes1 = GetRandomInt(0,43);
		new changes2 = GetRandomInt(0,43);
		new save;
		save = Cards[Client][changes2];
		Cards[Client][changes2] = Cards[Client][changes1];
		Cards[Client][changes1] = save;
	}
}

public BlackJackA4(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				BlackJackA5(Client);
			}
		}
	}
}

public Action:BlackJackA5(Client)//第一轮
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[暗][%i][ ][ ][ ] = %i + ?", Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "发牌");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "过牌");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "弃牌（退一半Bet）");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, BlackJackA6, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
	
}

public BlackJackA6(Handle:menu, MenuAction:action, Client, param)//第一轮选择
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    CreateTimer(2.5, BlackJackA7a, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "发牌中...");
			}
			case 2:
			{
			    CreateTimer(2.5, BlackJackA7b, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "等待庄家...");
			}
			case 3:
			{
			    Bet[Client] += RoundToNearest(BetSetBJ[Client] / 2);
				BetSetBJ[Client] = 0;
				PrintToChat(Client, "已退还 %i Bet，期待你的下次光临！");
				StartTheBJ(Client);
			}
		}
	}
}

public Action:BlackJackA7a(Handle:timer, any:Client)//第二轮
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[暗][%i][ ][ ][ ] = %i + ?", Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	if (SumCardsB[Client] > 21)
	{
	    BetSetBJ[Client] = 0;
	    PrintToChat(Client, "\x04你的点数爆掉了，输掉了本局，期待你的下次光临！");
		StartTheBJ(Client);
	}
	else
	{
	    Format(line, sizeof(line), "发牌");
	    DrawPanelItem(menu, line);
		Format(line, sizeof(line), "过牌");
	    DrawPanelItem(menu, line);
		Format(line, sizeof(line), "弃牌（退一半Bet）");
	    DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, BlackJackA8, MENU_TIME_FOREVER);
		CloseHandle(menu);
	}
	
}

public BlackJackA8(Handle:menu, MenuAction:action, Client, param)//第二轮选择
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    CreateTimer(2.5, BlackJackA9a, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "发牌中...");
			}
			case 2:
			{
			    CreateTimer(2.5, BlackJackA9b, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "等待庄家...");
			}
			case 3:
			{
			    Bet[Client] += RoundToNearest(BetSetBJ[Client] / 2);
				BetSetBJ[Client] = 0;
				PrintToChat(Client, "已退还 %i Bet，期待你的下次光临！");
				StartTheBJ(Client);
			}
		}
	}
}

public Action:BlackJackA9a(Handle:timer, any:Client)//第三轮
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[暗][%i][ ][ ][ ] = %i + ?", Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	if (SumCardsB[Client] > 21)
	{
	    BetSetBJ[Client] = 0;
	    PrintToChat(Client, "\x04你的点数爆掉了，输掉了本局，期待你的下次光临！");
		StartTheBJ(Client);
	}
	else
	{
	    Format(line, sizeof(line), "发牌");
	    DrawPanelItem(menu, line);
		Format(line, sizeof(line), "过牌");
	    DrawPanelItem(menu, line);
		Format(line, sizeof(line), "弃牌（退一半Bet）");
	    DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, BlackJackA10, MENU_TIME_FOREVER);
		CloseHandle(menu);
	}
	
}

public BlackJackA10(Handle:menu, MenuAction:action, Client, param)//第三轮选择
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    CreateTimer(2.5, BlackJackA11a, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "发牌中...");
			}
			case 2:
			{
			    CreateTimer(2.5, BlackJackA11b, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "等待庄家...");
			}
			case 3:
			{
			    Bet[Client] += RoundToNearest(BetSetBJ[Client] / 2);
				BetSetBJ[Client] = 0;
				PrintToChat(Client, "已退还 %i Bet，期待你的下次光临！");
				StartTheBJ(Client);
			}
		}
	}
}

public Action:BlackJackA11a(Handle:timer, any:Client)//第三轮
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5] + Cards[Client][6];
	Format(line, sizeof(line), "庄家:[暗][%i][ ][ ][ ] = %i + ?", Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][%i] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], Cards[Client][6],SumCardsB);
	DrawPanelText(menu, line);
	if (SumCardsB[Client] > 21)
	{
	    BetSetBJ[Client] = 0;
	    PrintToChat(Client, "\x04你的点数爆掉了，输掉了本局，期待你的下次光临！");
		StartTheBJ(Client);
	}
	else
	{
		Format(line, sizeof(line), "过牌");
	    DrawPanelItem(menu, line);
		Format(line, sizeof(line), "弃牌（退一半Bet）");
	    DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, BlackJackA12, MENU_TIME_FOREVER);
		CloseHandle(menu);
	}
	
}

public BlackJackA12(Handle:menu, MenuAction:action, Client, param)//第三轮选择
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    CreateTimer(2.5, BlackJackA13, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(Client, "等待庄家...");
			}
			case 2:
			{
			    Bet[Client] += RoundToNearest(BetSetBJ[Client] / 2);
				BetSetBJ[Client] = 0;
				PrintToChat(Client, "已退还 %i Bet，期待你的下次光临！");
				StartTheBJ(Client);
			}
		}
	}
}

//======================================
//======这里是闲家两张牌的所有情况======
//======================================
public Action:BlackJackA7b(Handle:timer, any:Client)//第一轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	if (SumCardsB[Client] == 21 && SumCardsA[Client] < 21)
	{
	    Bet[Client] += BetSetBJ[Client] * 4;
		PrintToChat(Client, "你获得了黑杰克！获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 4);
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else if (SumCardsB[Client] == 21 && SumCardsA[Client] == 21)
	{
	    Bet[Client] -= 100;
		PrintToChat(Client, "你获得了黑杰克！\n只可惜庄家也获得了黑杰克...\n你额外失去了 100 Bet，期待你的下次光临！");
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else if (SumCardsB[Client] < 21 && SumCardsA[Client] == 21)
	{
	    Bet[Client] -= 100;
		PrintToChat(Client, "庄家获得了黑杰克，你额外失去了 100 Bet，期待你的下次光临！");
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else if (SumCardsB[Client] < 21 && SumCardsA[Client] < 21)
	{
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackB1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackB1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:BlackJackB1a(Handle:timer, any:Client)//第二轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][4];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackC1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackC1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackB1b(Handle:timer, any:Client)//第一轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackC1a(Handle:timer, any:Client)//第三轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][4] + Cards[Client][5];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], Cards[Client][5], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackD1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackD1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackC1b(Handle:timer, any:Client)//第二轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][4];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackD1a(Handle:timer, any:Client)//第四轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][4] + Cards[Client][5] + Cards[Client][6];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][%i] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], Cards[Client][5], Cards[Client][6], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] <= 21)
		{
		    Bet[Client] -= 1000;
		    PrintToChat(Client, "庄家获得了一条龙，你额外失去了 1000 Bet，期待你的下次光临！");
		    BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
		else
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！你获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
}

public Action:BlackJackD1b(Handle:timer, any:Client)//第三轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][4] + Cards[Client][5];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], Cards[Client][5], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][ ][ ][ ] = %i", Cards[Client][1], Cards[Client][3], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}


//======================================
//======这里是闲家三张牌的所有情况======
//======================================
public Action:BlackJackA9b(Handle:timer, any:Client)//第一轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
    if (SumCardsB[Client] < 21 && SumCardsA[Client] == 21)
	{
	    Bet[Client] -= 100;
		PrintToChat(Client, "庄家获得了黑杰克，你额外失去了 100 Bet，期待你的下次光临！");
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else if (SumCardsB[Client] < 21 && SumCardsA[Client] < 21)
	{
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackB2a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackB2b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:BlackJackB2a(Handle:timer, any:Client)//第二轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][5];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][5], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackC1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackC1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackB2b(Handle:timer, any:Client)//第一轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackC2a(Handle:timer, any:Client)//第三轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][5] + Cards[Client][6];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][4], Cards[Client][5], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackD1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackD1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackC2b(Handle:timer, any:Client)//第二轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][5];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][5], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackD2a(Handle:timer, any:Client)//第四轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][5] + Cards[Client][6] + Cards[Client][7];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][%i] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][5], Cards[Client][6], Cards[Client][7], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] <= 21)
		{
		    Bet[Client] -= 1000;
		    PrintToChat(Client, "庄家获得了一条龙，你额外失去了 1000 Bet，期待你的下次光临！");
		    BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
		else
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！你获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
}

public Action:BlackJackD2b(Handle:timer, any:Client)//第三轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][5] + Cards[Client][6];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][5], Cards[Client][6], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][ ][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

//======================================
//======这里是闲家四张牌的所有情况======
//======================================
public Action:BlackJackA11b(Handle:timer, any:Client)//第一轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
    if (SumCardsB[Client] < 21 && SumCardsA[Client] == 21)
	{
	    Bet[Client] -= 100;
		PrintToChat(Client, "庄家获得了黑杰克，你额外失去了 100 Bet，期待你的下次光临！");
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else if (SumCardsB[Client] < 21 && SumCardsA[Client] < 21)
	{
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackB3a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackB3b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:BlackJackB3a(Handle:timer, any:Client)//第二轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][6];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][6], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackC1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackC1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackB3b(Handle:timer, any:Client)//第一轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackC3a(Handle:timer, any:Client)//第三轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][6] + Cards[Client][7];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][6], Cards[Client][7], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] < 17)
		{
		    PrintToChat(Client, "庄家继续要牌...");
			CreateTimer(2.5, BlackJackD1a, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
		    PrintToChat(Client, "庄家过牌...");
			CreateTimer(2.5, BlackJackD1b, _, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:BlackJackC3b(Handle:timer, any:Client)//第二轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][6];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][ ][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][6], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

public Action:BlackJackD3a(Handle:timer, any:Client)//第四轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][6] + Cards[Client][7] + Cards[Client][8];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][%i] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][6], Cards[Client][7], Cards[Client][8], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] <= 21)
		{
		    Bet[Client] -= 1000;
		    PrintToChat(Client, "庄家获得了一条龙，你额外失去了 1000 Bet，期待你的下次光临！");
		    BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
		else
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！你获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
		    StartTheBJ(Client);
		}
}

public Action:BlackJackD3b(Handle:timer, any:Client)//第三轮结果
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0] + Cards[Client][6] + Cards[Client][7];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][%i][%i][ ] = %i", Cards[Client][0], Cards[Client][2], Cards[Client][6], Cards[Client][7], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][ ] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], SumCardsB);
	DrawPanelText(menu, line);
	    if (SumCardsA[Client] > 21)
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家爆点！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
	    else if (SumCardsB[Client] > SumCardsA[Client])
		{
		    Bet[Client] += BetSetBJ[Client] * 2;
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 2);
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
		else
		{
		    PrintToChat(Client, "庄家点数为：%i，闲家点数为：%i\n庄家赢了本局，期待你的下次光临！");
			BetSetBJ[Client] = 0;
			StartTheBJ(Client);
		}
}

//======================================
//======这里是闲家五张牌的所有情况======
//======================================
public Action:BlackJackA13(Handle:timer, any:Client)//第一轮庄家选择
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	SumCardsA[Client] = Cards[Client][2] + Cards[Client][0];
	SumCardsB[Client] = Cards[Client][1] + Cards[Client][3] + Cards[Client][4] + Cards[Client][5];
	Format(line, sizeof(line), "庄家:[%i][%i][ ][ ][ ] = %i", Cards[Client][0], Cards[Client][2], SumCardsA);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闲家:[%i][%i][%i][%i][%i] = %i", Cards[Client][1], Cards[Client][3], Cards[Client][4], Cards[Client][5], Cards[Client][6], SumCardsB);
	DrawPanelText(menu, line);
    if (SumCardsA[Client] == 21)
	{
	    Bet[Client] -= 100;
		PrintToChat(Client, "你获得了一条龙！\n只可惜庄家获得了黑杰克...\n你额外失去了 100 Bet，期待你的下次光临！");
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
	else
	{
	    Bet[Client] += BetSetBJ[Client] * 4;
	    PrintToChat(Client, "你获得了一条龙！\n你赢了本局，获得了 %i Bet，期待你的下次光临！", BetSetBJ[Client] * 4);
		BetSetBJ[Client] = 0;
		StartTheBJ(Client);
	}
}

public Action:Rules(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场的21点介绍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在这里，总有人走好运或者走霉运");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你所面对的对手很简单，只是一个庄家");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "庄家只会听从既定的规则行事");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "希望下一个赢完庄家的钱就是你！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "具体介绍");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RulePage2(Client);
			}
			case 2:
			{
			    BlackJack(Client);
			}
		}
	}
}

public Action:RulePage2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "游戏的目的很简单，手中的牌尽可能接近21点而不大于");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在每一轮，你可以选择过牌，发牌（即要牌），弃牌");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "庄家手中的牌在低于17点时会去要牌，而高于则会过牌");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当双方的牌点数相同时，判定庄家获胜");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "特殊牌型：");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "黑杰克，即在第一轮要牌前获得了21点，此时获得Bet翻4倍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "但要是庄家完成了黑杰克，则闲家（即玩家）需支付额外100Bet作为惩罚");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "一条龙，即在三轮发牌后，点数仍低于21点，此时获得Bet翻4倍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "但要是庄家完成了一条龙，则闲家（即玩家）需支付额外1000Bet作为惩罚");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "PS：能被庄家一条龙这得有多倒霉...");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "赢下赌局获得的Bet为2倍，祝愿玩家能够多多胜利！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "上一页");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules3, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules3(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    Rules(Client);
			}
			case 2:
			{
			    BlackJack(Client);
			}
		}
	}
}

//=====================================
//=======高或低赌场Part==================
//=====================================
public Action:HighOrLow(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "欢迎来到高或低会场！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "请选择你需要了解的项目！");
    DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "开始赌博");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "规则详情");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "更换筹码");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, HighOrLow2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public HighOrLow2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    StartTheHoL(Client);
			}
			case 2:
			{
			    RulesHoL(Client);
			}
			case 3:
			{
				BuyTheBet(Client);
			}
            case 4:
			{
				IntoTheCasino(Client);
			}
		}
	}
}

public Action:StartTheHoL(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "进入赌场，请选择你要下注的金额");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "5Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "5000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "一半Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全部Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, HighOrLowA1, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public HighOrLowA1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetHoL[Client] = 5;
				Bet[Client] -= 5;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
			case 2:
			{
			if (Bet[Client] >= 50)
			    {
			    BetSetHoL[Client] = 50;
				Bet[Client] -= 50;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
			case 3:
			{
			if (Bet[Client] >= 500)
			    {
			    BetSetHoL[Client] = 500;
				Bet[Client] -= 500;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
            case 4:
			{
			if (Bet[Client] >= 5000)
			    {
			    BetSetHoL[Client] = 5000;
				Bet[Client] -= 5000;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
			case 5:
			{
			if (Bet[Client] >= 50000)
			    {
			    BetSetHoL[Client] = 50000;
				Bet[Client] -= 50000;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
			case 6:
			{
			if (Bet[Client] >= 500000)
			    {
			    BetSetHoL[Client] = 500000;
				Bet[Client] -= 500000;
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheHoL(Client);
			}
			}
			case 7:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetHoL[Client] = RoundToNearest(Bet[Client] / 10) * 10;
				Bet[Client] -= BetSetBJ[Client];
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你的Bet少于5，无法执行半下注操作");
				StartTheHoL(Client);
			}
			}
			case 8:
			{
			if (Bet[Client] >= 0)
			    {
			    BetSetBJ[Client] = Bet[Client];
				Bet[Client] -= BetSetBJ[Client];
				HighOrLowA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有Bet");
				StartTheHoL(Client);
			}
			}
		}
	}
}

public Action:HighOrLowA2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "当前赌注因子：X %i", HoLFactor[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "骰子数：[ ][ ][ ]");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "投掷骰子");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, HighOrLowA3, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public HighOrLowA3(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RollTheDice(Client);
				HighOrLowA4(Client);
			}
		}
	}
}

public Action:HighOrLowA4(Client)//说明
{
    SumDiceA[Client] = diceA[Client] + diceB[Client] + diceC[Client];
	HoLFactor[Client] = 1;
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "当前赌注因子：%i X %i",BetSetHoL[Client], HoLFactor[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "骰子数：[%i][%i][%i]",diceA, diceB, diceC);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "猜大");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "猜小");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "猜平");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "闪人");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, HighOrLowA5, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public HighOrLowA5(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RollTheDice(Client);
				SumDiceB[Client] = diceA[Client] + diceB[Client] + diceC[Client];
				if (SumDiceB[Client] > SumDiceA[Client])
				{
				    HoLFactor[Client] *= 2;
					PrintToChat(Client, "本次投掷骰子数为：%i，符合猜测！因子上涨！");
				    HighOrLowA4(Client);
				}
				else
				{
				    BetSetHoL[Client] = 0;
					PrintToChat(Client, "本次投掷骰子数为：%i，猜测失败！筹码失去！");
					StartTheHoL(Client);
				}
			}
			case 2:
			{
			    RollTheDice(Client);
				SumDiceB[Client] = diceA[Client] + diceB[Client] + diceC[Client];
				if (SumDiceB[Client] < SumDiceA[Client])
				{
				    HoLFactor[Client] *= 2;
					PrintToChat(Client, "本次投掷骰子数为：%i，符合猜测！因子上涨！");
				    HighOrLowA4(Client);
				}
				else
				{
				    BetSetHoL[Client] = 0;
					PrintToChat(Client, "本次投掷骰子数为：%i，猜测失败！筹码失去！");
					StartTheHoL(Client);
				}
			}
			case 3:
			{
			    RollTheDice(Client);
				SumDiceB[Client] = diceA[Client] + diceB[Client] + diceC[Client];
				if (SumDiceB[Client] == SumDiceA[Client])
				{
				    HoLFactor[Client] *= 32;
					PrintToChat(Client, "本次投掷骰子数为：%i，符合猜测！因子上涨！");
				    HighOrLowA4(Client);
				}
				else
				{
				    BetSetHoL[Client] = 0;
					PrintToChat(Client, "本次投掷骰子数为：%i，猜测失败！筹码失去！");
					StartTheHoL(Client);
				}
			}
			case 4:
			{
			    Bet[Client] += BetSetHoL[Client] * HoLFactor[Client];
				BetSetHoL[Client] = 0;
				PrintToChat(Client, "谢谢惠顾，期待您的下一次光临！");
				StartTheHoL(Client);
			}
		}
	}
}

public Action:RollTheDice(Client)//说明
{
    diceA[Client] = GetRandomInt(1, 6);
	diceB[Client] = GetRandomInt(1, 6);
	diceC[Client] = GetRandomInt(1, 6);
}

public Action:RulesHoL(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场的高或低介绍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在这里，总有人走好运或者走霉运");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你所面对的对手很简单，只是三个毫无生气的骰子");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "骰子只会显示它们应该显示的东西");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "希望下一个赢完庄家的钱就是你！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "具体介绍");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules2HoL, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules2HoL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RuleHoLPage2(Client);
			}
			case 2:
			{
			    HighOrLow(Client);
			}
		}
	}
}

public Action:RuleHoLPage2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家高或低赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "游戏的目的很简单，只需要猜下次的骰子数高于或低于上次");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在每一轮，你可以选择猜高，猜低，猜平或闪人");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "计算因子：猜中高或低X2倍，猜中平X32倍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闪人时可带走下的 Bet X 因子 ");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "祝愿玩家百猜百中！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "上一页");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules3HoL, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules3HoL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RulesHoL(Client);
			}
			case 2:
			{
			    HighOrLow(Client);
			}
		}
	}
}

//=====================================
//=======俄罗斯轮盘赌赌场Part==================
//=====================================
public Action:RussianSpin(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家俄罗斯轮盘赌赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "欢迎来到俄罗斯轮盘赌会场！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "请选择你需要了解的项目！");
    DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "开始赌博");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "规则详情");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "更换筹码");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, RussianSpin2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public RussianSpin2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    StartTheRS(Client);
			}
			case 2:
			{
			    RulesRS(Client);
			}
			case 3:
			{
				BuyTheBet(Client);
			}
            case 4:
			{
				IntoTheCasino(Client);
			}
		}
	}
}

public Action:StartTheRS(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家俄罗斯轮盘赌赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "进入赌场，请选择你要下注的金额");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "5Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "5000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "50000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "500000Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "一半Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全部Bet");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, RussianSpinA1, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public RussianSpinA1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetRS[Client] = 5;
				Bet[Client] -= 5;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
			case 2:
			{
			if (Bet[Client] >= 50)
			    {
			    BetSetRS[Client] = 50;
				Bet[Client] -= 50;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
			case 3:
			{
			if (Bet[Client] >= 500)
			    {
			    BetSetRS[Client] = 500;
				Bet[Client] -= 500;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
            case 4:
			{
			if (Bet[Client] >= 5000)
			    {
			    BetSetRS[Client] = 5000;
				Bet[Client] -= 5000;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
			case 5:
			{
			if (Bet[Client] >= 50000)
			    {
			    BetSetRS[Client] = 50000;
				Bet[Client] -= 50000;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
			case 6:
			{
			if (Bet[Client] >= 500000)
			    {
			    BetSetRS[Client] = 500000;
				Bet[Client] -= 500000;
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有这么多Bet");
				StartTheRS(Client);
			}
			}
			case 7:
			{
			if (Bet[Client] >= 5)
			    {
			    BetSetRS[Client] = RoundToNearest(Bet[Client] / 10) * 10;
				Bet[Client] -= BetSetBJ[Client];
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你的Bet少于5，无法执行半下注操作");
				StartTheRS(Client);
			}
			}
			case 8:
			{
			if (Bet[Client] >= 0)
			    {
			    BetSetRS[Client] = Bet[Client];
				Bet[Client] -= BetSetBJ[Client];
				RussianSpinA2(Client);
				}
			else
			{
			    PrintToChat(Client, "你并没有Bet");
				StartTheRS(Client);
			}
			}
		}
	}
}

public Action:RussianSpinA2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家俄罗斯轮盘赌赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "当前赌注因子：X %i", RSFactor[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "左轮枪内子弹数：0/6");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "放入子弹");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, RussianSpinA3, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public RussianSpinA3(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				RussianSpinA4(Client);
			}
		}
	}
}

public Action:RussianSpinA4(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家21点赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "当前赌注因子：%i X %i",BetSetRS[Client], RSFactor[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "左轮枪内子弹数：%i/6",bullet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "开枪");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "更换子弹数量");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "闪人");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, RussianSpinA5, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public RussianSpinA5(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			
				GotShot[Client] = GetRandomInt(1, 6);
				if (GotShot[Client] > bullet[Client])
				{
				    if (bullet[Client] == 1)
					{
				        RSFactor[Client] *= 2;
					} else if (bullet[Client] == 2)
					{
					RSFactor[Client] *= 4;
					}else if (bullet[Client] == 3)
					{
					RSFactor[Client] *= 8;
					}else if (bullet[Client] == 4)
					{
					RSFactor[Client] *= 16;
					}else if (bullet[Client] == 5)
					{
					RSFactor[Client] *= 32;
					}
					PrintToChat(Client, "咔嗒！子弹并没有发射出来，因子增高！");
				    RussianSpinA4(Client);
				}
				else
				{
				    BetSetRS[Client] = 0;
					PrintToChat(Client, "砰！子弹发射！失去筹码！");
					StartTheRS(Client);
				}
			}
			case 2:
			{
			    SetTheAmmo(Client);
			}
			case 3:
			{
			    Bet[Client] += BetSetRS[Client] * RSFactor[Client];
				BetSetRS[Client] = 0;
				PrintToChat(Client, "谢谢惠顾，期待您的下一次光临！");
				StartTheRS(Client);
			}
		}
	}
}

public Action:SetTheAmmo(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
    Format(line, sizeof(line), "调整子弹数量");
	DrawPanelText(menu, line);
    Format(line, sizeof(line), "1发");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "2发");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "3发");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "4发");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "5发");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, SetTheAmmo2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public SetTheAmmo2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    bullet[Client] = 1;
				RussianSpinA4(Client);
			}
			case 2:
			{
			    bullet[Client] = 2;
				RussianSpinA4(Client);
			}
			case 3:
			{
			    bullet[Client] = 3;
				RussianSpinA4(Client);
			}
			case 4:
			{
			    bullet[Client] = 4;
				RussianSpinA4(Client);
			}
			case 5:
			{
			    bullet[Client] = 5;
				RussianSpinA4(Client);
			}
			case 6:
			{
				RussianSpinA4(Client);
			}
		}
	}
}

public Action:RulesRS(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家俄罗斯轮盘赌赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场的俄罗斯轮盘赌介绍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在这里，总有人走好运或者走霉运");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你所面对的对手很简单，只是一把毫无生气的左轮");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "左轮中的子弹只会停留在它该停留的位置");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "希望下一个赢完庄家的钱就是你！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "具体介绍");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules2RS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules2RS(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RuleRSPage2(Client);
			}
			case 2:
			{
			    RussianSpin(Client);
			}
		}
	}
}

public Action:RuleRSPage2(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家俄罗斯轮盘赌赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "游戏的目的很简单，只需要赌下次扣动扳机子弹不会出来");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在每一轮，你可以选择开枪，更换子弹数量或闪人");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "计算因子：X 2的子弹数次方");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闪人时可带走下的 Bet X 因子 ");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "祝愿玩家百枪全空！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "上一页");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Rules3RS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public Rules3RS(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    RulesRS(Client);
			}
			case 2:
			{
			    RussianSpin(Client);
			}
		}
	}
}

//============================================
//=============赌场杂项=======================
//============================================
public Action:CasinoRules(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场全部介绍");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在这里，总有人走好运或者走霉运");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你所需要做的只是洗脸赚钱");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "Top100显示了筹码量最高的前一百名");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "赌场商店有大量稀有物品可以购买");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "施工中的设施将会在之后推出（MAYBE?）");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, CasinoRules2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public CasinoRules2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    BliaryMenu(Client);
			}
		}
	}
}

public Action:CasinoShop(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场商店（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场商店");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "请选择商贩");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "武器商");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "医药商");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, CasinoShop2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public CasinoShop2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    WeaponShop(Client);
			}
			case 2:
			{
			    MedicShop(Client);
			}
			case 3:
			{
			    BliaryMenu(Client);
			}
		}
	}
}

public Action:WeaponShop(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场商店（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场武器商");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "这里可以买到平常游戏不刷新的枪械哦！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "UZI     (1800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "SMG     (3200Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "Deagle  (8800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "SPAS    (10800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "SCAR    (10800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "M16     (18800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "M60     (68800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "Sniper  (68800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "AWP     (88800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, WeaponShop2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public WeaponShop2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    if (Bet[Client] >= 1800)
				{
				    CheatCommand(Client, "give", "smg");
				    PrintToChat(Client, "你订购的UZI冲锋枪已到货！");
					Bet[Client] -= 1800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 2:
			{
			    if (Bet[Client] >= 3200)
				{
				    CheatCommand(Client, "give", "smg_silenced");
				    PrintToChat(Client, "你订购的SMG冲锋枪已到货！");
					Bet[Client] -= 3200;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 3:
			{
			    if (Bet[Client] >= 8800)
				{
				    CheatCommand(Client, "give", "pistol_magnum");
				    PrintToChat(Client, "你订购的沙鹰已到货！");
					Bet[Client] -= 8800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 4:
			{
			    if (Bet[Client] >= 10800)
				{
				    CheatCommand(Client, "give", "shotgun_spas");
				    PrintToChat(Client, "你订购的SPAS霰弹枪已到货！");
					Bet[Client] -= 10800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 5:
			{
			    if (Bet[Client] >= 10800)
				{
				    CheatCommand(Client, "give", "rifle_desert");
				    PrintToChat(Client, "你订购的SCAR突击步枪已到货！");
					Bet[Client] -= 10800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 6:
			{
			    if (Bet[Client] >= 18800)
				{
				    CheatCommand(Client, "give", "rifle");
				    PrintToChat(Client, "你订购的SCAR突击步枪已到货！");
					Bet[Client] -= 18800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 7:
			{
			    if (Bet[Client] >= 68800)
				{
				    CheatCommand(Client, "give", "rifle_m60");
				    PrintToChat(Client, "你订购的M60机枪已到货！");
					Bet[Client] -= 68800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 8:
			{
			    if (Bet[Client] >= 68800)
				{
				    CheatCommand(Client, "give", "sniper_military");
				    PrintToChat(Client, "你订购的连狙已到货！");
					Bet[Client] -= 68800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 9:
			{
			    if (Bet[Client] >= 88800)
				{
				    CheatCommand(Client, "give", "sniper_awp");
				    PrintToChat(Client, "你订购的AWP毁天裂地狙击枪已到货！");
					Bet[Client] -= 88800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 10:
			{
			    CasinoShop(Client);
			}
		}
	}
}

public Action:MedicShop(Client)//说明
{
    decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场商店（求生分部）");
    SetPanelTitle(menu, line);
	Format(line, sizeof(line), "这里是Bliary赌场医药商");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "这里可以买到你所需要的医疗物资！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你目前所拥有的筹码：%i Bet", Bet[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "获得8HP (100Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "止痛药  (18800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "肾上腺素(38800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "急救包  (58800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "心电    (88800Bet)");
    DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
    DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MedicShop2, MENU_TIME_FOREVER);
	CloseHandle(menu);
	
}

public MedicShop2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
			    if (Bet[Client] >= 100)
				{
				    new HP = GetClientHealth(Client);
				    SetEntProp(Client, Prop_Send, "m_iHealth", HP + 8);
				    PrintToChat(Client, "你订购的微型血瓶已到货！");
					Bet[Client] -= 100;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 2:
			{
			    if (Bet[Client] >= 18800)
				{
				    CheatCommand(Client, "give", "pain_pills");
				    PrintToChat(Client, "你订购的止痛药已到货！");
					Bet[Client] -= 18800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 3:
			{
			    if (Bet[Client] >= 38800)
				{
				    CheatCommand(Client, "give", "adrenaline");
				    PrintToChat(Client, "你订购的肾上腺素已到货！");
					Bet[Client] -= 38800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 4:
			{
			    if (Bet[Client] >= 58800)
				{
				    CheatCommand(Client, "give", "first_aid_kits");
				    PrintToChat(Client, "你订购的急救包已到货！");
					Bet[Client] -= 58800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 5:
			{
			    if (Bet[Client] >= 88800)
				{
				    CheatCommand(Client, "give", "defibrillator");
				    PrintToChat(Client, "你订购的心电除颤仪已到货！");
					Bet[Client] -= 88800;
					WeaponShop(Client);
				}
				else
				{
				    PrintToChat(Client, "你好像Bet不太够哦");
					WeaponShop(Client);
				}
			}
			case 6:
			{
			    CasinoShop(Client);
			}
		}
	}
}

//=========================================================
//===============TOP 100部分（BUG可能会巨多）==============
//=========================================================
public Action:Top100(Client)//说明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    Bliary皇家赌场筹码量排行榜");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "制作中......");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Top100a, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Top100a(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				BliaryMenu(Client);
			}
		}
	}
}

public bool:CasinoInitialize()
{	
	
	
//Obtain key values from the stats file, if the stats file isn't present then make a blank one.
	new Handle:mckv = CreateKeyValues("mcEmpty");
	FileToKeyValues(mckv, "bliarycasino.txt");
	new String:rootSecName[64] = "";
	KvGetSectionName(mckv,rootSecName,sizeof(rootSecName));
	if(!StrEqual(rootSecName,"Bliary Casino Bet",false))
	{
		KvSetSectionName(mckv, "Bliary Casino Bet");
		KvRewind(mckv);
		KeyValuesToFile(mckv, "bliarycasino.txt");
	}
//If the 'Server Totals' section doesn't exist then create it
	if(!KvJumpToKey(mckv,"Server Totals"))
	{
		KvJumpToKey(mckv,"Server Totals",true);
		
		KvSetNum(mckv,"connections",0);
		
		KvSetNum(mckv,"is admin",1);
		
		new String:ClientLastConn[128] = "";
		FormatTime(ClientLastConn,sizeof(ClientLastConn),"%H-%j-%Y-%a %b %d, %Y at %I:%M %p");
		KvSetString(mckv,"last connect",ClientLastConn);
				
		KvSetNum(mckv,"total bet",0);
		
		KvRewind(mckv);
		KeyValuesToFile(mckv, "bliarycasino.txt");
	}

	CloseHandle(mckv);
}

//Collect stats from ALL pounces (+1 to pounce count)

public bool:CasinoAddBet(Client)
{
	new String:ClientAuth[32] = "";
	
	if(Client == totalStats)
	{
		ClientAuth = "Server Totals";
	}
	else
	{
		GetClientAuthId(Client,AuthId_Steam2,ClientAuth,sizeof(ClientAuth));
		
		//For servers without steamid's, set the ClientAuth to their name
		if(StrEqual(ClientAuth,"STEAM_1:0:0"))
		Format(ClientAuth,sizeof(ClientAuth),"%N",Client);
	}
	
	new Handle:mckv = CreateKeyValues("mcEmpty");
	FileToKeyValues(mckv, "bliarycasino.txt");
	
	
	KvRewind(mckv);
	KvJumpToKey(mckv,ClientAuth, true);
	new bet = KvGetNum(mckv,"total bet",0);
	bet += Bet[Client];
	KvSetNum(mckv,"total bet",bet);
	
	
	KvRewind(mckv);
	KeyValuesToFile(mckv, "bliarycasino.txt");
	
	CloseHandle(mckv);
	
	return true;
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
