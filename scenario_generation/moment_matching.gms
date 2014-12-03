* Generate scenarios using bootstrap method
* Author: Tue Vissing Jensen
* DTU fall 2014 for course "Optimization in Finance."

$eolcom //

SETS
scenariotimes 'Index over weeks included in monthly scenarios' /t1*t4/
scenario 'Index of scenario' /s1*s250/;

SET ETF /
$include "../data/etfs_max_mean.csv"
/;

set BaseDate /
$include "../data/dates.csv"
/;
display ETF, BaseDate;

*$exit
ALIAS (ETF, i);
ALIAS (BaseDate, t);
ALIAS (scenariotimes, st);
ALIAS (scenario, s);


// The new .csv file is read into the table prices
table prices(t,i)
$ondelim
$include ../data/etfs_max_mean_prices.csv
$offdelim
;

PARAMETER HistoricalWeeklyReturn(i,t);

HistoricalWeeklyReturn(i,t) = prices(t+1,i)/prices(t,i) - 1;

display HistoricalWeeklyReturn, prices;

set tmonth(t) 'trading dates' ;
*Selecting the dates that will correspond to the number of months for the scenario set - 86
tmonth(t)$( (ord(t)>=161) and ( mod(ord(t)-1,4) eq 0 ) ) =1;
scalar number;
number=card(tmonth);

display tmonth, number, t;

PARAMETERS
          ScenarioReport(*,*,*)            'Summary of the generated scenarios'
		  MonthlyScenarios(i,s,t)          'Monthly scenario return'
;

scalars   BeginNum       'Number of the first period'
          EndNum         'Number of the last period'
          mean_weight      'weight given to mean'
          variance_weight  'weight given to variance'
          skewness_weight  'weight given to skewness'
          kurtosis_weight  'weight given to kurtosis';	


PARAMETERS
	Mean(i) 'Mean of monthly returns'
	Variance(i) 'Variance of monthly returns'
	Skewness(i) 'Skewness of monthly returns'
	Kurtosis(i) 'Kurtosis of monthly returns'
;


variable
		xi(i,s)    'Scenario of return for asset i under scenario s'
		error      'Error in moment matching'
		ensemble_mean(i)       'Mean of scenario ensemble'
		ensemble_variance(i)   'Variance of scenario ensemble'
		ensemble_skewness(i)   'Skewness of scenario ensemble'
		ensemble_kurtosis(i)   'Kurtosis of scenario ensemble'
;

EQUATIONS
	totalerror
	defmean(i)
	defvar(i)
	defskewness(i)
	defkurtosis(i)
;

totalerror.. error =e=
				mean_weight *     sum(i, power(ensemble_mean(i) - Mean(i), 2)) + 
				variance_weight * sum(i, power(ensemble_variance(i) - Variance(i), 2)) + 
				skewness_weight * sum(i, power(ensemble_skewness(i) - Skewness(i), 2)) + 
				kurtosis_weight * sum(i, power(ensemble_kurtosis(i) - Kurtosis(i), 2))
;

defmean(i)..		ensemble_mean(i) =e= sum(s, xi(i,s))/CARD(s);
defvar(i)..			ensemble_variance(i) =e= sum(s, power(xi(i,s) - ensemble_mean(i), 2))/CARD(s);
defskewness(i)..	ensemble_skewness(i) =e= sum(s, power(xi(i,s) - ensemble_mean(i), 3))/CARD(s);
defkurtosis(i)..	ensemble_kurtosis(i) =e= sum(s, power(xi(i,s) - ensemble_mean(i), 4))/CARD(s);


model MomentMatch 'Moment matching model' /totalerror, defmean, defvar, defskewness, defkurtosis/;

Mean(i) = 0;
Variance(i) = 1;
Skewness(i) = 0;
Kurtosis(i) = 3;

mean_weight = 1;
variance_weight = 1;
skewness_weight = 1;
kurtosis_weight = 1;

xi.l(i,s) = normal(Mean(i),Variance(i));

solve MomentMatch minimizing error using nlp;

display ensemble_mean.l, ensemble_variance.l, ensemble_skewness.l, ensemble_kurtosis.l;




$exit
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

Mean(i) = // Calculate mean
Variance(i) = // Calculate Variance
Skewness(i) = // Calculate Skewness
Kurtosis(i) = // Calculate Kurtosis

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

display MonthlyScenarios;

EXECUTE_UNLOAD 'Scenario_generation_moment.gdx', MonthlyScenarios;

