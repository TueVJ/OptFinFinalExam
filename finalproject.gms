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

$offorder
HistoricalWeeklyReturn(i,t) = prices(t+1,i)/prices(t,i) - 1;
$onorder

PARAMETER ScenarioMonthlyReturn(i,s,t);

*loop(t$(ORD(t) + trainingperiod),
*
*)

display MonthStart;