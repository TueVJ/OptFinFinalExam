* Generate scenarios using bootstrap method
* Authors: Tiago Soares, Tue Vissing Jensen
* DTU, fall 2014 for course "Optimization in Finance."
* WARNING: Not yet updated to use new data structure!

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
MonthStart(BaseDate) 'Beginning of months';

MonthStart(BaseDate) = 1$(
        MOD(ORD(BaseDate) - trainingperiod, 4) = 0
        AND ORD(BaseDate) + 4 < CARD(BaseDate)
);

// The new .csv file is read into the table prices
table prices(t,i)
$ondelim
$include ../data/raw_prices_test.csv
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

scalar number;
set tmonth(t) 'trading dates' ;
*Selecting the dates that will correspond to the number of months for the scenario set - 86
tmonth(t)$( (ord(t)>=149) and ( mod(ord(t),4) eq 0 ) ) =1;
number=card(tmonth);

display tmonth, number, t;

*set tmonth 'number of months' /1*86/;
*$ontext
PARAMETER WeeklyScenarios(i,st,s,t)        'Week scenarios return considering interval 1 (28/01/2005 to 28/02/2008)'
          MonthlyScenarios(i,s,t)          'Month scenarios return considering interval 1'
          ScenarioReport(*,*,*)            'Summary of the generated scenarios'
          temp(t)                          'Number of months for generating scenarios - since 2005 until end of 2014'
          temp_2(t)                        'Number of months for exponential'
;

scalars   BeginNum       'Number of the first period'
          EndNum         'Number of the last period'
          number_period  'number of months of each scenario set'
;

number_period=(393-149)/4;


*Generating scenarios for period between 2005-1-28 and 2008-2-28
*BeginNum - first period after 2005-1-28;
BeginNum=2;
*EndNum - last period before 2008-2-28;
EndNum=156;

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

ScenarioReport(i,s,tmonth)=MonthlyScenarios(i,s,tmonth);

display WeeklyScenarios, MonthlyScenarios, temp_2;

EXECUTE_UNLOAD 'Scenario_generation.gdx', MonthlyScenarios;

*$offtext
