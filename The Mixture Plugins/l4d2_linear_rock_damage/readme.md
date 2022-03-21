Tank's rock will deal a linear damage to the survivor.

CVAR:

l4d2_rock_min_damage 2.0 //Minimum damage does a rock can be done.

l4d2_rock_max_damage 48.0 //Maxinum damage does a rock can be done.

l4d2_rock_min_distance 200.0 //Any distance shorter than this will be considered a min damage.

l4d2_rock_max_distance 2000.0 //Any distance farther than this will be considered a max damage.

How to calculate: (Distance between Tank and survivor) / (Max distance) * (Max Damage)

-------------------------------------------------------------------------------------------------------

Tank石头会随距离造成线性伤害，原创插件，有bug反馈（我也不一定会看(。・ω・。)）

CVAR:

l4d2_rock_min_damage 2.0 //石头所能造成的最小伤害（低于最低距离时）

l4d2_rock_max_damage 48.0 //石头所能造成的最大伤害（高于最高距离时）

l4d2_rock_min_distance 200.0 //石头线性计算起步

l4d2_rock_max_distance 2000.0 //石头线性计算终点

计算方法为 Tank丢石瞬间与生还者的距离 / 石头线性计算终点 * 最大伤害
