* Generate scenarios using bootstrap method
* Author: Tue Vissing Jensen
* DTU fall 2014 for course "Optimization in Finance."

$eolcom //

SETS
ETF 'ETFs' /SPY, XLF, QQQ, IWM/
scenariotimes 'Index over weeks included in monthly scenarios' /t1*t4/
scenario 'Index of scenario' /s1*s250/;

$INCLUDE dates.inc

ALIAS (ETF, i);
ALIAS (BaseDate, t);
ALIAS (scenariotimes, st);
ALIAS (scenario, s);


PARAMETER
    tau(t) 'Week index from start';

tau(t) = ORD(t) -1;

scalars
                trainingperiod 'Length of training set'
                curoffset 'Current offset for scenario generation';
trainingperiod = sum(t$SAMEAS(t,"2008-2-29"),ORD(t));
curoffset = 0;

SET
MonthStart(BaseDate) 'Beginning of month for scenario';

MonthStart(BaseDate) = 1$(
        MOD(ORD(BaseDate)-trainingperiod, 4) = 0
        AND ORD(BaseDate) > trainingperiod
        AND ORD(BaseDate) + 4 < CARD(BaseDate)
);

// The new .csv file is read into the table prices
table prices(t,i)
$ondelim
$include raw_prices_test.csv
$offdelim
;


PARAMETER HistoricalWeeklyReturn(i,t);

HistoricalWeeklyReturn(i,t) = prices(t+1,i)/prices(t,i) - 1;

display HistoricalWeeklyReturn, prices;
*$exit
*$offorder
*HistoricalWeeklyReturn(i,t) = prices(t+1,i)/prices(t,i) - 1;
*$onorder



display trainingperiod;


PARAMETER WeeklyScenarios(i,st,s)        'Week scenarios return considering interval 1 (28/01/2005 to 28/02/2008)'
          MonthlyScenarios(i,s)          'Month scenarios return considering interval 1'
          WeeklyScenarios_2(i,st,s)      'Week scenarios return considering interval 2 (28/02/2005 to 28/03/2008)'
          MonthlyScenarios_2(i,s)        'Month scenarios return considering interval 2'
          ScenarioReport(*,*,*)            'Summary of the generated scenarios'
;

scalars   temp           'random number of the week fo interval 1'
          BeginNum       'Number of the first period of interval 1'
          EndNum         'Number of the last period of interval 1'
          BeginNum_2     'Number of the first period of interval 2'
          EndNum_2       'Number of the last period of interval 2'
          temp_2         'random number of the week fo interval 2'
;
*Generating scenarios for period between 2005-1-28 and 2008-2-28
*BeginNum - first period after 2005-1-28;
BeginNum=2;
*EndNum - last period before 2008-2-28;
EndNum=156;

*Generating scenarios for period between 2005-2-28 and 2008-3-28 - rollon four weeks forward
*BeginNum - first period after 2005-1-28;
BeginNum_2=6;
*EndNum - last period before 2008-2-28;
EndNum_2=160;

loop(s,
    loop(st,
*random uniform function
temp=uniformint(BeginNum,EndNum);
temp_2=uniformint(BeginNum_2,EndNum_2);
*Getting week scenarios
WeeklyScenarios(i,st,s)=sum(t$(ord(t)=temp),HistoricalWeeklyReturn(i,t));
WeeklyScenarios_2(i,st,s)=sum(t$(ord(t)=temp_2),HistoricalWeeklyReturn(i,t));
);
);
*Getting monthly scenarios
MonthlyScenarios(i,s)= prod(st, (1+WeeklyScenarios(i,st,s)))-1;
MonthlyScenarios_2(i,s)= prod(st, (1+WeeklyScenarios_2(i,st,s)))-1;

ScenarioReport(i,s,'Interval_1')=MonthlyScenarios(i,s);
ScenarioReport(i,s,'Interval_2')=MonthlyScenarios_2(i,s);
display WeeklyScenarios, MonthlyScenarios_2, ScenarioReport;

EXECUTE_UNLOAD 'Scenario_generation.gdx', ScenarioReport;


