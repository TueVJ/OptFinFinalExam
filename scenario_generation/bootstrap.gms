* Generate scenarios using bootstrap method
* Author: Tue Vissing Jensen and Tiago Soares
* DTU fall 2014 for course "Optimization in Finance."

$eolcom //

SETS
scenariotimes 'Index over weeks included in monthly scenarios' /t1*t4/
scenario 'Index of scenario' /s1*s250/;

SET ETF /
$include "..\data\etfs_max_mean.csv"
/;

set BaseDate /
$include "..\data\dates.csv"
/;

ALIAS (ETF, i);
ALIAS (BaseDate, t);
ALIAS (scenariotimes, st);
ALIAS (scenario, s);

// The new .csv file is read into the table prices
table prices(t,i)
$ondelim
$include ..\data\etfs_max_mean_prices.csv
$offdelim
;

PARAMETER HistoricalWeeklyReturn(i,t), HistoricalMonthlyReturn(i,t) ;
* Determining weekly return
HistoricalWeeklyReturn(i,t) = prices(t+1,i)/prices(t,i) - 1;
* Determining monthly return (used in the portfolio revision model)
HistoricalMonthlyReturn(i,t)$(ord(t) > 3) =  (1+HistoricalWeeklyReturn(i,t)) * (1+HistoricalWeeklyReturn(i,t-1)) * (1+HistoricalWeeklyReturn(i,t-2)) * (1+HistoricalWeeklyReturn(i,t-3)) - 1;

set tmonth(t) 'trading dates' ;
*Selecting the dates that will correspond to the number of months for the scenario set - 87
tmonth(t)$( (ord(t)>=161) and ( mod(ord(t)-1,4) eq 0 ) ) =1;

PARAMETER WeeklyScenarios(i,st,s,t)        'Week scenarios return considering interval 1 (28/01/2005 to 28/02/2008)'
          MonthlyScenarios(i,s,t)          'Month scenarios return considering interval 1'
          ScenarioReport(*,*,*)            'Summary of the generated scenarios'
          temp(t)                          'Number of months for generating scenarios - since 2005 until end of 2014'
          temp_2(t)                        'Number of months for exponential'
;

scalars   BeginNum       'Number of the first period'
          EndNum         'Number of the last period';

*Generating scenarios for period between 2005-1-28 and 2008-2-28
*BeginNum - first period after 2005-1-28;
BeginNum=1;
*EndNum - last period before 2008-2-28;
EndNum=161;

loop(tmonth,
loop(s,
    loop(st,
*random uniform function
temp(tmonth)=uniformint(BeginNum,EndNum);
*exponetial function for select more current data
temp_2(tmonth)=(1/2)*exp( (1/2)*(EndNum-BeginNum));

*Getting week scenarios
WeeklyScenarios(i,st,s,tmonth)=sum(t$(ord(t)=temp(tmonth)),HistoricalWeeklyReturn(i,t));
);
);
*Getting monthly scenarios
MonthlyScenarios(i,s,tmonth)= prod(st, (1+WeeklyScenarios(i,st,s,tmonth)))-1;
*selecting new period
BeginNum=BeginNum+4;
EndNum=EndNum+4;
);

display WeeklyScenarios, MonthlyScenarios, temp_2;

* Extracting MonthlyScenarios data to gdx file (to be used on CVaR model)
EXECUTE_UNLOAD '../data/Scenario_generation_bootstrap.gdx', MonthlyScenarios;
* Extracting historicalMonthlyreturn to gdx file (to be used on portfolio revision model)
Execute_unload '../data/Historical_month_return.gdx', HistoricalMonthlyReturn;
