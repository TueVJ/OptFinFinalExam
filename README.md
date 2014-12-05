OptFinFinalExam
===============

Project for the final exam of course 42123

Gams files tested Dec. 2014 on GAMS 22.2.9 using CPLEX and conopt4.

Python files tested Dec. 2014 on python 2.7.6 with modules Numpy, Pandas 0.14, Matplotlib, SKLearn and Seaborn.

File overview
---------------

### Code ###
./clustering/clustering.py:
	- Downloads price data for assets in ./input_data/instruments2.csv over the relevant period.
	- Clusters assets based on correlation of weekly returns

./scenario\_generation/boostrap.gms:
	- Generates monthly scenarios via the bootstrap model

./scenario\_generation/moment\_matching.gms:
	- Generates monthly scenarios via the moment matching method

./running\_model/cvar.gms:
	- Main model code
	- Runs CVaR model for initial portfolio selection
	- Runs portfoliorevision to show effect of scenarios
	- Runs back-test

./plot\_results/plot\_CVaR\_frontier.py:
	- Plots results from CVaR model

./plot\_results/plot\_portfolio\_revision\_results.py:
	- Plots results for the portfolio revision model

./plot\_results/plot\_trading\_results.py:
	- Plots results for the trading model