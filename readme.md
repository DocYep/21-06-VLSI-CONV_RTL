The code is written by [仰天倀笑](https://blog.csdn.net/Hide_in_Code) and his friend in 21/06/20.

The mainly codes and the history version is in the path `code_history`, other files are our results for DC/formality check/gate level check.



1. the path of out RTL CODE: 

   ①top module： `DC_and_Gate_Level_Sim/tb_topModuleV4.v  `

   ②CONV module： `DC_and_Gate_Level_Sim/convModV3.v`

   ③ Testbench module：`DC_and_Gate_Level_Sim/topModuleV4.v`

2. DC
    The workspace of DC , Gate Level Simulation and RTL Simulation is `DC_and_Gate_Level_Sim`;

  To run the dc, you should input the command as follow:

  (1) `cd DC_and_Gate_Level_Sim`
  (2) `design_vision &`
  (3) `source run.tcl`
  The report of timing, area, power are saved in `DC_and_Gate_Level_Sim/rpt`
  The netlist is saved in `DC_and_Gate_Level_Sim/write/netlist.v`

3. Gate Level Simulation
    (1)  `cd DC_and_Gate_Level_Sim`
    (2)  `./Gate_Level_Simulation`

  We have saved the screenshot of Gate Level Simulation in `/Gate_level_result`

3. RTL Simulation
    (1) `cd DC_and_Gate_Level_Sim`
    (2) `./rtl_sim`

  The result of RTL Simulation and Gate Level Simulation will be saved in `DC_and_Gate_Level_Sim/numError.txt`

4. formality
The workspace of formality is `formality`
The screenshot path of formality is `formality/formality.png`
