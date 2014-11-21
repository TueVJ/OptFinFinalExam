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
alpha  = 0.99;
RISK_TARGET = 0.1;


PARAMETERS
        pr(t)       Scenario probability
        P(i,t)      Final values
        EP(i)       Expected final values;

pr(tmonth) = 1.0 / CARD(tmonth);

P(i,tmonth) = 1 + MonthlyScenarios(i,'s1',tmonth);

EP(i) = SUM(tmonth, pr(tmonth) * P(i,tmonth));


MIN_MU = SMIN(i, EP(i));
MAX_MU = SMAX(i, EP(i));

*scalar lambda;
*lambda=0.5;
*MU_TARGET = lambda*MAX_MU + (1-lambda)*MIN_MU;


* Assume we want 10 portfolios in the frontier

MU_STEP = (MAX_MU - MIN_MU) / 10;


POSITIVE VARIABLES
        x(i)            Holdings of assets
        VaRDev(t)       Measures of the deviations from the VaR;


VARIABLES
        VaR             Value-at-Risk
        CVaR            Objective function value - CVaR
        Losses(t)       Measures of the losses;

EQUATIONS
        BudgetCon       Equation defining the budget contraint
        ReturnCon       Equation defining the portfolio return constraint
        CVaRCon         Equation defining the CVaR allowed
        ObjDefCVaR      Objective function definition for CVaR minimization
        ObjDefReturn    Objective function definition for return maximization
        LossDef(t)      Equations defining the losses
        VaRDevCon(t)    Equations defining the VaR deviation constraints;

BudgetCon ..         SUM(i, x(i)) =E= Budget;

ReturnCon ..         SUM(i, EP(i) * x(i)) =G= MU_TARGET * Budget;

VaRDevCon(tmonth) .. VaRDev(tmonth) =G= Losses(tmonth) - VaR;

LossDef(tmonth)..    Losses(tmonth) =E= (Budget - SUM(i, P(i,tmonth) * x(i)));

ObjDefCVaR ..        CVaR =E= VaR + SUM(tmonth, pr(tmonth) * VaRDev(tmonth)) / (1 - alpha);



ObjDefReturn ..      CVaR =E= SUM(i, EP(i) * x(i));

CVaRCon ..           VaR + SUM(tmonth, pr(tmonth) * VaRDev(tmonth)) / (1 - alpha) =L= RISK_TARGET;

MODEL MinCVaR  'PFO Model 5.5.1' /BudgetCon, ReturnCon, LossDef, VaRDevCon, ObjDefCVaR/;

*MODEL MaxReturn 'PFO Model 5.5.2' /BudgetCon, CVaRCon, LossDef, VaRDevCon, ObjDefReturn/;

SET DifferentRuns / PP_1 * PP_10 /;
ALIAS (DifferentRuns, dr);


Parameter
         bonds(i,dr)             'bonds'
         MU_TARGET_DR(dr)        'target by step'
         RES_CVaR(dr)
         RES_VaR(dr)
         Mean(dr)
;

MU_TARGET=MIN_MU;
loop(dr,
MU_TARGET_DR(dr)= MU_TARGET;
MU_TARGET = MU_TARGET + MU_STEP;

         SOLVE MinCVaR MINIMIZING CVaR USING LP;
         bonds(i,dr)= x.l (i);
         RES_CVaR(dr)=CVaR.l;
         RES_VaR(dr)=VaR.l;
         Mean(dr)=MU_TARGET * Budget;

);

display bonds, RES_CVaR, MU_TARGET_DR, MIN_MU, MAX_MU;