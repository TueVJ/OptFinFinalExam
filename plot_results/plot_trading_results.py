import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

budget = 1000000

df = pd.read_csv('../data/portfolio_revision_all.csv')
df['Time'] = pd.to_datetime(df['Time'])
df = df.set_index('Time')

statscolumns = ['Expected Value', 'CVaR', 'Trading Cost']

pdf = df[[c for c in df.columns if c not in statscolumns]]
sdf = df[[c for c in df.columns if c in statscolumns] + ['Type']]


# Calculate some extra values
sdf['Current Value'] = pdf.sum(axis=1)
sdf['Expected Profit'] = sdf['Expected Value'] - sdf['Current Value']
sdf['Actual Profit'] = sdf['Current Value'].diff()

sdf = sdf.reset_index().set_index(['Type', 'Time'])
sdf['Cumulative Trading Cost'] = df.reset_index().groupby(by=['Type', 'Time'])['Trading Cost'].sum().groupby(level=[0]).cumsum()
sdf = sdf.reset_index().set_index('Time')
sdf['Net Value'] = sdf['Current Value'] - sdf['Cumulative Trading Cost']


# Figure: Portfolio revisions

gp = pdf.groupby('Type').get_group('risk_averse').
gp2 = pdf.groupby('Type').get_group('risk_neutral')

plt.figure(1)

plt.subplot(211)
gp.loc[gp.sum() > 0].plot()

plt.legend('upper left', ncol=5)

plt.subplot(212)
gp.loc[gp.sum() > 0].plot()

plt.legend('upper left', ncol=5)


# Figure: Portfolio predictions vs. scenarios
if False:
    pass

# Set up 1/N results
rawetfs = pd.read_csv('../data/etfs_max_mean_prices.csv', parse_dates=0)
rawetfs = rawetfs.rename(columns={u'Unnamed: 0': 'Time'})
rawetfs['Time'] = pd.to_datetime(rawetfs['Time'])
rawetfs = rawetfs.set_index('Time')
# Select date range of problem
rawetfs = rawetfs.ix[df.index]
# Normalize prices to initial prices
rawetfs = rawetfs / rawetfs.ix[0]
# Compute value of 1 over n portfolio
overnportfoliovalue = budget * rawetfs.sum(1) / len(rawetfs.columns)

# Value of portfolio over time
plt.figure(3, figsize=(6, 3), dpi=100)
ax = plt.axes()
namedict = {
    'risk_averse': 'Risk Averse, bootstrap',
    'risk_neutral': 'Risk Neutral, bootstrap'
}

for l, d in sdf.groupby('Type'):
    d['Net Value'].plot(label=namedict[l], ax=ax)

overnportfoliovalue.plot(label='1 over N', ax=ax)

plt.xlabel('')
plt.ylabel("Portfolio Net Value [DKK]")
plt.legend(ncol=1, loc='upper left')

plt.savefig('../pic/trading_portfolio_value.pdf')
