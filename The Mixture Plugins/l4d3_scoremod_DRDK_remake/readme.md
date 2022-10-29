New Scoremod for my own configs. It may be unbalanced, so you can modify to whatever you want.

CVAR:

v1:

am_survivor_multi 0.5 //Map Basic scores (Also means Damage Bonus) Scores = thisValue * survivorAmounts * mapDistance

am_perm_bonus_proportion 0.5 //The factors of Perm damage bonus holds in Total damage bonus

am_items_bonus_allow_pills 1 //Allow Pills Scores? Set 1 to Allow.

am_items_pills_bonus_factor 0.1 //Pills Total Bonus = thisValue * survivorAmounts * MapBasicScores

am_items_bonus_allow_adrenaline 1 //Allow Adrenaline Scores? Set 1 to Allow.

am_items_adrenaline_bonus_factor 0.1 //Adrenaline Total Bonus = thisValue * survivorAmounts * MapBasicScores

am_items_bonus_allow_med 1 //Allow Med kits Scores? Set 1 to Allow.

am_items_med_bonus_factor 0.4 //Med kits Total Bonus = thisValue * survivorAmounts * MapBasicScores

am_items_bonus_allow_throw 1 //Allow Throwable Scores? Set 1 to Allow.

am_items_throw_bonus_factor 0.02 //Throwable Total Bonus = thisValue * survivorAmounts * MapBasicScores

am_perm_total 400 //The theory of the amounts of Perm HP. Perm Damage Bonus Value = TotalPermHPScores / thisValue

am_temp_total 240 //The theory of the amounts of Temp HP. Temp Damage Bonus Value = TotalTempHPScores / thisValue

am_bonus_allow_temp_extra 1 //Allow Extra Bonus for Survivors go into the saferoom without any temp HP loss?

am_temp_extra_bonus_factor 0.5 //ExtraBonus = thisValue * MapBasicScores

am_incap_penalty 1 //Score loss for Incap

v2:

am_health_damage_mix 1 //Mix the Perm HP total and Temp HP Total?

am_health_damage_ptt 1.0 //Perm HP Value when mix the Total HP

am_health_damage_ttp 1.0 //Temp HP Value when mix the Total HP


Example:(Default Cvars)

4 Survivors go in the saferoom with total 160 Perm Damage and 35 Temp Damage, holding total 3 Meds and 2 Pills in c2m1.

The Distance is 400, MapBasicScores is 800. The Value of the PermHP is 400 / 400 = 1, The Value of the TempHP is 400 / 240 = 1.67. 

The Survivor teams should get:

400 Distance Scores + (400 - 160 * 1)PermHP Scores + (400 - 35 * 1.67)TempHP Scores + (800 * 0.4 * 3/4)Medkits Scores + (800 * 0.1 * 2/4)Pills Scores

Together is 400+240+342+150+40=1172 Scores

-------------------------------------------------------------------------------------------------------

拿HybridScoremod插件进行改装，从而在包抗中能够运行，有bug反馈（我也不一定会看(。・ω・。)）

CVAR:

v1:
confogl_addcvar am_survivor_multi 0.5 //地图基础总分（也是伤害分）=该参数*生还者人数*地图路程分

confogl_addcvar am_perm_bonus_proportion 0.5 //实血伤害分占比总伤害分

confogl_addcvar am_items_bonus_allow_pills 1 //允许药物得分

confogl_addcvar am_items_pills_bonus_factor 0.1 //药物总得分=该参数*生还者人数*地图基础总分

confogl_addcvar am_items_bonus_allow_adrenaline 1 //允许肾上腺素得分

confogl_addcvar am_items_adrenaline_bonus_factor 0.1 //肾上腺素总得分=该参数*生还者人数*地图基础总分

confogl_addcvar am_items_bonus_allow_med 1 //允许急救包得分

confogl_addcvar am_items_med_bonus_factor 0.4 //急救包总得分=该参数*生还者人数*地图基础总分

confogl_addcvar am_items_bonus_allow_throw 1 //允许投掷物得分

confogl_addcvar am_items_throw_bonus_factor 0.02 //投掷物总得分=该参数*生还者人数*地图基础总分

confogl_addcvar am_perm_total 400 //生还者实血理论总量 实血伤害分价值=地图基础分 / 总量

confogl_addcvar am_temp_total 240 //生还者虚血理论总量 虚血伤害分价值=地图基础分 / 总量

confogl_addcvar am_bonus_allow_temp_extra 1 //允许完美过关额外得分（无虚血掉分）

confogl_addcvar am_temp_extra_bonus_factor 0.5 //完美过关额外得分=该参数*地图基础分

confogl_addcvar am_incap_penalty 1 //倒地惩罚（扶起来之后应该会补上的）

v2:
confogl_addcvar am_health_damage_mix 1 //是否合并血池

confogl_addcvar am_health_damage_ptt 1.0 //合并血池时，实血分数

confogl_addcvar am_health_damage_ttp 1.0 //合并血池时，虚血分数