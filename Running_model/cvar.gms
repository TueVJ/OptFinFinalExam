$TITLE Conditional Value at Risk model


*Sets
SETS
ETF 'ETFs' /SPY, XLF, QQQ, IWM/
scenariotimes 'Index over weeks included in monthly scenarios' /t1*t4/
scenario 'Index of scenario' /s1*s250/;

$INCLUDE dates.inc

ALIAS (ETF, i);
ALIAS (BaseDate, t, l);
ALIAS (scenariotimes, st);
ALIAS (scenario, s);

set tmonth(t) 'trading dates' ;
*Selecting the dates that will correspond to the number of months for the scenario set - 86
tmonth(t)$( (ord(t)>=149) and ( mod(ord(t),4) eq 0 ) ) =1;

display tmonth;
*$exit
Parameter MonthlyScenarios(i,s,t);
*EXECUTE_LOAD 'Scenario_generation.gdx', ScenarioReport;
$gdxin Scenario_generation
$Load MonthlyScenarios


display MonthlyScenarios;




SCALARS
        Budget        'Nominal investment budget'
        alpha         'Confidence level'
        MU_Target     'Target portfolio return'
        MU_STEP       Target return step
        MIN_MU        Minimum return in universe
        MAX_MU        Maximum return in universe
        RISK_TARGET   Bound on CVaR (risk)
;

Budget = 100.0;
alpha  = 0.5;
RISK_TARGET = 0.1;


PARAMETERS
        pr(s)       Scenario probability
        P(i,s)      Final values
        EP(i)       Expected final values
         stdev(i);

pr(s) = 1.0 / CARD(s);

P(i,s) = 1 - MonthlyScenarios(i,s,'2008-1-24');

EP(i) = SUM(s, pr(s) * P(i,s));
stdev(i) = sqrt(SUM(s, pr(s) * power(P(i,s) - EP(i), 2)));
display EP, stdev;

*MIN_MU = SMIN(i, EP(i));
*MAX_MU = SMAX(i, EP(i));

*scalar lambda;
*lambda=0.5;
*MU_TARGET = lambda*MAX_MU + (1-lambda)*MIN_MU;


* Assume we want 10 portfolios in the frontier

*MU_STEP = (MAX_MU - MIN_MU) / 10;

scalar CVaR_target;

POSITIVE VARIABLES
        x(i)            Holdings of assets
        VaRDev(s)       Measures of the deviations from the VaR;


VARIABLES
        VaR             Value-at-Risk
        CVaR            Objective function value - CVaR
        Losses(s)       Measures of the losses
        MeanReturn      Mean Return;

EQUATIONS
        BudgetCon       Equation defining the budget contraint
        ReturnCon       Equation defining the portfolio return constraint
*        CVaRCon         Equation defining the CVaR allowed
        DefCVaR         Objective function definition for CVaR minimization
        DefReturn       Objective function definition for return maximization
        LossDef(s)      Equations defining the losses
        VaRDevCon(s)    Equations defining the VaR deviation constraints
        Targetcon       Equation fo CVaR target for be used to the 10 runs;

BudgetCon ..         SUM(i, x(i)) =E= Budget;

ReturnCon ..         MeanReturn =G= MU_TARGET * Budget;

VaRDevCon(s) ..      VaRDev(s) =G= Losses(s) - VaR;

LossDef(s)..         Losses(s) =E= (Budget - SUM(i, P(i,s) * x(i)));

DefCVaR ..           CVaR =E= VaR + SUM(s, pr(s) * VaRDev(s)) / (1 - alpha);

DefReturn ..         MeanReturn =E= SUM(i, EP(i) * x(i));

*CVaRCon ..           VaR + SUM(s, pr(s) * VaRDev(s)) / (1 - alpha) =L= RISK_TARGET;

Targetcon..          CVaR =l= CVaR_target;

MODEL MinCVaR  'Minimizing CVaR' /BudgetCon, ReturnCon, LossDef, VaRDevCon, DefCVaR, DefReturn/;

MODEL MaxReturn 'Final' /BudgetCon, ReturnCon, LossDef, VaRDevCon, DefCVaR, DefReturn, Targetcon/;

SET DifferentRuns / PP_1 * PP_10 /;
ALIAS (DifferentRuns, dr);


Parameter
         bonds(i,dr)             'bonds'
         CVaR_DR(dr)             'CVaR target by step'
         RES_CVaR(dr)
         RES_VaR(dr)
         Mean(dr)
         Min_value_CVaR          'The minimum value of CVaR for mean return superior to 0'
         Max_value_CVaR          'The maximum value of CVar for mean return superior to 0'
;
scalar lambda;

MU_TARGET=0;
solve MinCVaR minimizing CVaR using LP;
Min_value_CVar=CVaR.l;
display MeanReturn.l, Min_value_CVar, x.l, VaR.l;

solve MinCVaR maximizing MeanReturn using LP;
Max_value_CVaR=CVaR.l;
display MeanReturn.l, Max_value_CVaR, x.l, VaR.l;
*$exit
$ontext
for (lambda=0.0 to 1 by 0.1,

         CVaR_target=lambda*(Max_value_CVaR - Min_value_CVaR) + Min_value_CVaR;
         solve MaxReturn maximazing MeanReturn using LP;

);
$offtext

CVaR_target=Max_value_CVar;
solve MaxReturn maximizing MeanReturn using LP;
display CVaR.l, MeanReturn.l;

Parameter ScenarioReturn(dr,s);


*MU_TARGET=SMAX(i, EP(i));
*$exit
* Assume we want 10 portfolios in the frontier
MU_STEP = (Max_value_CVaR - Min_value_CVar) / 10;
CVaR_target=Min_value_CVar;
loop(dr,
         CVaR_DR(dr)= CVaR_target;

         SOLVE MaxReturn maximizing MeanReturn USING LP;
         CVaR_target = CVaR_target + MU_STEP;
         bonds(i,dr)= x.l (i);
         RES_CVaR(dr)=CVaR.l;
         RES_VaR(dr)=VaR.l;
         Mean(dr)=MeanReturn.l;
         ScenarioReturn(dr,s) = Sum(i, P(i,s) * x.l(i));
);

File scenarios /'../Data/ScenarioReturn.csv'/;

scenarios.pc=5;
scenarios.pw=1048;
put scenarios;
put 'PP','Scenario', 'ScenarioReturn'/;
loop (dr,
loop (s,

 put dr.tl, s.tl, ScenarioReturn(dr,s)/;

);

);


Parameter
SummaryReport(*,*)
SummaryScenario(*,*);

SummaryReport('Mean',dr)=Mean(dr);
SummaryReport('CVaR',dr)=RES_CVaR(dr);
SummaryReport(i,dr)=bonds(i,dr);


display Min_value_CVar, Max_value_CVaR, bonds, CVaR_DR, RES_CVaR, Mean, MU_TARGET, SummaryReport, ScenarioReturn;
$exit
* Write into an Excel file
EXECUTE_UNLOAD 'CVaR_results.gdx', SummaryReport;
EXECUTE 'gdxxrw.exe CVaR_results.gdx O=Frontier.xls par=SummaryReport rng=Bootstrap!a1' ;


