* Generate scenarios using the moment matching method
* Authors: Tue Vissing Jensen
* DTU, fall 2014 for course "Optimization in Finance."

$eolcom //

* Sets:
*  ETF, i: Assets to use.
*  BaseDate, t: Month of price info
*  scenario, s: Scenarioindex
*  MonthStart(BaseDate): 
*  tmonth(t):

* PARAMETERS:
*  prices(t,i): Price of asset i at time t
*  HistoricalWeeklyReturn(i,t): Return for week starting at t
*  HistoricalMonthlyReturn(i,t): Return for month starting at t
*  MonthlyScenarios(i, s, t): Return of asset i
*      for month starting at t under scenario s.

HistoricalMonthlyReturn(i,t)$(ORD(t) < CARD(t)-3) =
	(1 + HistoricalWeeklyReturn(i,t  )) *
	(1 + HistoricalWeeklyReturn(i,t+1)) *
	(1 + HistoricalWeeklyReturn(i,t+2)) *
	(1 + HistoricalWeeklyReturn(i,t+3)) - 1;

PARAMETERS
	Mean(i) 'Mean of monthly returns'
	Variance(i) 'Variance of monthly returns'
	Skewness(i) 'Skewness of monthly returns'
	Kurtosis(i) 'Kurtosis of monthly returns'
;

Variables
	scenarioreturn(i,s) 'Monthly return of asset i in scenario s at time t'
	error 'Total error'
	ensemble_mean(i) 'Ensemble mean'
	ensemble_variance(i) 'Ensemble variance'
	ensemble_skewness(i) 'Ensemble skewness'
	ensemble_kurtosis(i) 'Ensemble kurtosis';


PARAMETER MonthlyScenarios(i, s, t);

EQUATIONS
	totalerror
	defmean(i)
	defvar(i)
	defskewness(i)
	defkurtosis(i)
;

totalerror.. error =e=
				sum(i, power(ensemble_mean(i) - Mean(i), 2)) + 
				sum(i, power(ensemble_variance(i) - Variance(i), 2)) + 
				sum(i, power(ensemble_skewness(i) - Skewness(i), 2)) + 
				sum(i, power(ensemble_kurtosis(i) - Kutosis(i), 2))
;

defmean(i)..		ensemble_mean(i) = sum(s, scenarioreturn(i,s))
defvar(i)..			ensemble_variance(i) = sum(s, power(scenarioreturn(i,s) - ensemble_mean, 2))
defskewness(i)..	ensemble_skewness(i) = sum(s, power(scenarioreturn(i,s) - ensemble_mean, 3))
defkurtosis(i)..	ensemble_variance(i) = sum(s, power(scenarioreturn(i,s) - ensemble_mean, 4))
					

model MomentError //;


loop(t$tmonth(t),


* Generate mean, variance, etc. from MonthlyScenarios

* solve MomentError minimizing error using nlp
);