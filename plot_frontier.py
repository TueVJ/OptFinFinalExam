# -*- coding: utf-8 -*-
"""
Spyder Editor

This temporary script file is located here:
C:\Users\tiasoar\.spyder2\.temp.py
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.ticker import FormatStrFormatter

majorFormatter= FormatStrFormatter('%.02f')

data = pd.read_csv('data/Cvar_frontier.csv', sep=',')
data['CVaR Bound'] = np.round(np.linspace(0.0,1.0,len(data['CVaR'])),2)
data = data.set_index('CVaR Bound')

plt.figure(figsize=(6,4), dpi=200)
data.plot(x='Mean', y='CVaR', marker='.', x_compat=True)
plt.ylabel('CVaR')
plt.xlabel('Mean return')
plt.gca().xaxis.set_major_formatter(majorFormatter)
plt.gca().yaxis.set_major_formatter(majorFormatter)

plt.tight_layout()
plt.savefig('pic/frontier.pdf')

plt.figure(figsize=(6,4), dpi=200)
data.plot(kind='bar', y=[l for l in data.columns if l not in ('Mean', 'CVaR') and data[l].sum() > 0], stacked=True)
#plt.gca().xaxis.set_major_formatter(majorFormatter)

plt.legend(ncol=10)
plt.ylim(0,110)

plt.tight_layout()
plt.savefig('pic/Stake_vs_CVaR.pdf')

tdict = {pp: cvb for pp, cvb in zip(data.PP,data.index)}

plt.figure(figsize=(6,4), dpi=200)
scenario_data = pd.read_csv('data/ScenarioReturn.csv')
scenario_data['CVaR Bound'] = map(tdict.__getitem__, scenario_data.PP)
gsd=scenario_data.pivot(index='Scenario',columns='CVaR Bound', values='ScenarioReturn')
sns.violinplot(gsd, bw=0.2)
plt.ylabel('Scenario Return')


plt.tight_layout()
plt.savefig('pic/Scenario_Return.pdf')