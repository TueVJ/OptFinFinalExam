$TITLE Conditional Value at Risk model

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
ALIAS (BaseDate, t, l);
ALIAS (scenariotimes, st);
ALIAS (scenario, s);

set tmonth(t) 'trading dates' ;
*Selecting the dates that will correspond to the number of months for the scenario set - 87
tmonth(t)$( (ord(t)>=161) and ( mod(ord(t)-1,4) eq 0 ) ) =1;

*Including monthly scenarios from scenario generation code
Parameter MonthlyScenarios(i,s,t);
$gdxin Scenario_generation
$Load MonthlyScenarios

SCALARS
        Budget        'Nominal investment budget'
        alpha         'Confidence level'
        MU_Target     'Target portfolio return'
        MU_STEP       Target return step
        MIN_MU        Minimum return in universe
        MAX_MU        Maximum return in universe
        RISK_TARGET   Bound on CVaR (risk)
;

*Initial portfolio budget - 1 million kr.
Budget = 1000000;
alpha  = 0.5;

PARAMETERS
        pr(s)       Scenario probability
        P(i,s)      Final values
        EP(i)       Expected final values
         stdev(i);

pr(s) = 1.0 / CARD(s);
*Considering initial data as 2008-02-27
P(i,s) = 1 + MonthlyScenarios(i,s,'2008-02-27');
EP(i) = SUM(s, pr(s) * P(i,s));
stdev(i) = sqrt(SUM(s, pr(s) * power(P(i,s) - EP(i), 2)));
display EP, stdev;

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
        DefCVaR         Objective function definition for CVaR minimization
        DefReturn       Objective function definition for return maximization
        LossDef(s)      Equations defining the losses
        VaRDevCon(s)    Equations defining the VaR deviation constraints
        Targetcon       Equation fo CVaR target for be used to the 10 runs;

BudgetCon ..         SUM(i, x(i)) =E= Budget;

ReturnCon ..         MeanReturn =G= MU_TARGET * Budget;

VaRDevCon(s) ..      VaRDev(s) =G= Losses(s) - VaR;

LossDef(s)..         Losses(s) =E= (SUM(i, x(i)) - SUM(i, P(i,s) * x(i)));

DefCVaR ..           CVaR =E= VaR + SUM(s, pr(s) * VaRDev(s)) / (1 - alpha);

DefReturn ..         MeanReturn =E= SUM(i, EP(i) * x(i));

Targetcon..          CVaR =l= CVaR_target;

MODEL MinCVaR  'Minimizing CVaR' /BudgetCon, ReturnCon, LossDef, VaRDevCon, DefCVaR, DefReturn/;

MODEL MaxReturn 'Final' /BudgetCon, ReturnCon, LossDef, VaRDevCon, DefCVaR, DefReturn, Targetcon/;

SET DifferentRuns / PP_1 * PP_10 /;
ALIAS (DifferentRuns, dr);


Parameter
         bonds(i,dr)             'ETF portfolio solution for the 10 runs'
         CVaR_DR(dr)             'CVaR target by each step of the 10 runs'
         RES_CVaR(dr)            'CVaR results for each of the 10 runs'
         RES_VaR(dr)             'VaR results for each of the 10 runs'
         Mean(dr)                'Expected value (return) for each of the 10 runs'
         Min_value_CVaR          'The minimum value of CVaR for mean return superior to 0'
         Max_value_CVaR          'The maximum value of CVar for mean return superior to 0'
;
scalar lambda;

* Determining point of minimum CVaR value
MU_TARGET=0;
solve MinCVaR minimizing CVaR using LP;
Min_value_CVar=CVaR.l;
display MeanReturn.l, Min_value_CVar, x.l, VaR.l;

* Determining point of maximum CVaR value
solve MinCVaR maximizing MeanReturn using LP;
Max_value_CVaR=CVaR.l;
display MeanReturn.l, Max_value_CVaR, x.l, VaR.l;

* Maximizing expected value return based on CVaR target
CVaR_target=Max_value_CVar;
solve MaxReturn maximizing MeanReturn using LP;
display CVaR.l, MeanReturn.l;

Parameter ScenarioReturn(dr,s);


* Assume we want 10 portfolios in the frontier
MU_STEP = (Max_value_CVaR - Min_value_CVar) / 10;
CVaR_target=Min_value_CVar;
loop(dr,
         CVaR_DR(dr)= CVaR_target;
* Determining expected value return for each CVaR step
         SOLVE MaxReturn maximizing MeanReturn USING LP;
         CVaR_target = CVaR_target + MU_STEP;
         bonds(i,dr)= x.l (i);
         RES_CVaR(dr)=CVaR.l;
         RES_VaR(dr)=VaR.l;
         Mean(dr)=MeanReturn.l;
         ScenarioReturn(dr,s) = Sum(i, P(i,s) * x.l(i));
);

* Writing scenario return results on csv file
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

* Writing portfolio assets
File Cvar_frontier /'..\Data\Cvar_frontier.csv'/;

Cvar_frontier.pc=5;
Cvar_frontier.pw=1048;
put Cvar_frontier;
put 'PP';
loop(i,
       put i.tl;
);
put 'Mean', 'CVaR'/;
loop(dr,
    put dr.tl;
         loop(i,
            put bonds(i,dr);
         );
    put Mean(dr), RES_CVaR(dr)/;
);

****************************************************
* Updating the model to a portfolio revision model *
****************************************************

scalar lambda            '1 - Risk averse, 0 - Risk neutral'
       penalty           'penalty cost for change the portfolio'
       M                 'High constant';

*50 kr. per trade
penalty=50;
*High constant
M=1000000;

* Updating value with new data time
P(i,s) = 1 + MonthlyScenarios(i,s,'2008-03-26');
* Updating expected value data
EP(i) = SUM(s, pr(s) * P(i,s));

Parameter     x_old(i)   'Base ETF portfolio from previous cvar model'
              HistoricalMonthlyReturn(i,t) 'Historical Monthly Return';
*`including historical monthly return data from gdx file
$gdxin Historical_month_return
$Load HistoricalMonthlyReturn

* Establishing old portfolio concerning the choosing a specific run of previous CVaR model (risk averse solution - PP_1)
x_old(i)= bonds(i,'PP_1') * (1 + HistoricalMonthlyReturn(i,'2008-03-26'));


variable Total_cost      'Objective function value'
         TC(i)           'Trade cost for each change in ETF'
         Trade_cost      'Total trade cost of changes'
         x_difference(i) 'the change on for each ETF';

Binary variable bin(i)   '0/1 set the change on portfolio by each ETF';

equation
         obj                     'Objective function '
         portfoliovaluecon       'Value before = value after'
         bondsport(i)            'Settlement of new portfolio assets'
         diflinearweight(i)      'Difference portofolio ipper bound'
         diflinearweight_less(i) 'Difference portofolio lower bound'
         costequ                 'Cost equation'
         TCpenalty(i)            'Penalty applied to each change in each ETF'
         TCbound(i)              'value of ETF change - upper bound'
         TCbound_less(i)         'value of ETF change - lower bound';


obj..                    Total_cost =E= lambda*CVaR - (1-lambda)*MeanReturn + Trade_cost;

portfoliovaluecon..      sum(i, x_old(i)) =e= sum(i, x(i));

bondsport(i)..           x_old(i) + x_difference(i) =E= x(i);

diflinearweight(i)..     x_difference(i) =L= bin(i)*M;

diflinearweight_less(i)..  -x_difference(i) =L= bin(i)*M;

costequ..                Trade_cost =E= sum(i, TC(i));

TCpenalty(i)..           TC(i) =G= bin(i)*penalty;

TCbound(i)..             TC(i) =G= 0.001*x_difference(i);

TCbound_less(i)..        TC(i) =G= -0.001*x_difference(i);


MODEL revision 'Minimizing Total cost' /obj, portfoliovaluecon, bondsport, diflinearweight, diflinearweight_less, costequ, TCpenalty, TCbound, TCbound_less, ReturnCon, LossDef, VaRDevCon, DefCVaR, DefReturn/;

*Risk averse
lambda=1;

x_difference.up(i)=0;
x_difference.lo(i)=0;
x.l(i) = x_old(i);
*bin.up(i)=0;
solve  revision minimizing Total_cost using MIP;

parameter MR_initial, CVaR_initial, bonds_initial(i), trading_costs_initial;
MR_initial=MeanReturn.l;
CVaR_initial=CVaR.l;
bonds_initial(i)=x.l(i);
trading_costs_initial=trade_cost.l;


display bonds, x_old, x.l, x_difference.l, CVaR_initial, MR_initial, trading_costs_initial;
*$exit

******************************
* Implementing the back-test *
******************************

*clearing variables because of initial solution
x_difference.up(i)=inf;
x_difference.lo(i)=-inf;
option clear=x.l;

* code for all the months taking into account risk averse and risk neutral

Parameter MR_averse(t), CVaR_averse(t), bonds_averse(t,i), trading_costs_averse(t), max_value_averse(t), min_value_averse(t),
          MR_neutral(t), CVaR_neutral(t), bonds_neutral(t,i), trading_costs_neutral(t), max_value_neutral(t), min_value_neutral(t);

* Risk averse code
x_old(i)= bonds(i,'PP_1') * (1 + HistoricalMonthlyReturn(i,'2008-03-26'));
* loop for all tmonth >1
loop(t$( (ord(t)>=165) and ( mod(ord(t)-1,4) eq 0 ) ) ,

P(i,s) = 1 + MonthlyScenarios(i,s,t);
EP(i) = SUM(s, pr(s) * P(i,s));
*Risk averse
lambda=1;
solve  revision minimizing Total_cost using MIP;
max_value_averse(t)=smax(s, SUM(i, P(i,s) * x.l(i)));
min_value_averse(t)=smin(s, SUM(i, P(i,s) * x.l(i)));
MR_averse(t)=MeanReturn.l;
CVaR_averse(t)=CVaR.l;
bonds_averse(t,i)=x.l(i);
trading_costs_averse(t)=trade_cost.l;
*t-4 to give the rate of the previous tmonth
x_old(i)= bonds_averse(t,i) * (1 + HistoricalMonthlyReturn(i,t+4));
);

**********

* Risk neutral code
x_old(i)= bonds(i,'PP_1') * (1 + HistoricalMonthlyReturn(i,'2008-03-26'));
loop(t$( (ord(t)>=165) and ( mod(ord(t)-1,4) eq 0 ) ) ,

P(i,s) = 1 + MonthlyScenarios(i,s,t);
EP(i) = SUM(s, pr(s) * P(i,s));
*Risk neutral
lambda=0;
solve  revision minimizing Total_cost using MIP;
max_value_neutral(t)=smax(s, SUM(i, P(i,s) * x.l(i)));
min_value_neutral(t)=smin(s, SUM(i, P(i,s) * x.l(i)));
MR_neutral(t)=MeanReturn.l;
CVaR_neutral(t)=CVaR.l;
bonds_neutral(t,i)=x.l(i);
trading_costs_neutral(t)=trade_cost.l;
*t-4 to give the rate of the previous tmonth
x_old(i)= bonds_neutral(t,i) * (1 + HistoricalMonthlyReturn(i,t+4));
);

display trading_costs_averse;

***** Portfolio revision model solution to csv file
* Writing portfolio assets
File portfolio_revision /'..\Data\portfolio_revision.csv'/;

portfolio_revision.pc=5;
portfolio_revision.pw=1048;
put portfolio_revision;

put 'Type';
loop(i,
      put i.tl;
     );
put 'Expected Value', 'CVaR', 'Trading Cost'/;
* put initial values
put 'Initial';
loop(i,
       put bonds_initial(i);
    );
put MR_initial, CVaR_initial, trading_costs_initial/;

*put risk averse solution
put 'Risk Averse';
loop(i,
      put bonds_averse('2008-03-26',i);
    );
put MR_averse('2008-03-26'), CVaR_averse('2008-03-26'), trading_costs_averse('2008-03-26')/;

* put risk neutral solution
put 'Risk Neutral';
loop(i,
      put bonds_neutral('2008-03-26',i);
    );
put MR_neutral('2008-03-26'), CVaR_neutral('2008-03-26'), trading_costs_neutral('2008-03-26')/;
*$offtext


***************Writing in csv file all the solution for every tmonth - back-test solution
File portfolio_revision_all /'..\Data\portfolio_revision_all.csv'/;

portfolio_revision_all.pc=5;
portfolio_revision_all.pw=1048;
put portfolio_revision_all;

set risk/risk_averse, risk_neutral/;
Parameter Mr_total(t,risk), bonds_total(t,i,risk), CVaR_total(t,risk), trading_costs_total(t,risk), maximum_value(t,risk), minimum_value(t,risk);
Mr_total(t,'risk_averse')=MR_averse(t);
Mr_total(t,'risk_neutral')=MR_neutral(t);
bonds_total(t,i,'risk_averse')=bonds_averse(t,i);
bonds_total(t,i,'risk_neutral')=bonds_neutral(t,i);
CVaR_total(t,'risk_averse')=CVaR_averse(t);
CVaR_total(t,'risk_neutral')=CVaR_neutral(t);
trading_costs_total(t,'risk_averse')= trading_costs_averse(t);
trading_costs_total(t,'risk_neutral')= trading_costs_neutral(t);
maximum_value(t,'risk_averse') = max_value_averse(t);
maximum_value(t,'risk_neutral') = max_value_neutral(t);
minimum_value(t,'risk_averse')= min_value_averse(t);
minimum_value(t,'risk_neutral')= min_value_neutral(t);
*initial values on the table of the first cvar model from february choosing PP_1
Mr_total('2008-02-27','risk_averse')=Mean('PP_1');
Mr_total('2008-02-27','risk_neutral')=Mean('PP_1');
bonds_total('2008-02-27',i,'risk_averse')=bonds(i,'PP_1');
bonds_total('2008-02-27',i,'risk_neutral')=bonds(i,'PP_1');
CVaR_total('2008-02-27','risk_averse')=RES_CVaR('PP_1');
CVaR_total('2008-02-27','risk_neutral')=RES_CVaR('PP_1');
trading_costs_total('2008-02-27','risk_averse')= 0;
trading_costs_total('2008-02-27','risk_neutral')= 0;

put 'Time', 'Type', 'Expected Value', 'CVaR', 'Trading Cost', 'Maximum Value', 'Minimum Value';
loop(i,
     put i.tl;
);
put /;

loop(tmonth,

            loop(risk,
                 put tmonth.tl, risk.tl, Mr_total(tmonth,risk), CVaR_total(tmonth,risk), trading_costs_total(tmonth,risk), maximum_value(tmonth,risk), minimum_value(tmonth,risk);
                             loop(i,
                                 put bonds_total(tmonth,i,risk);
                                 );
                     put /;
                 );
);
