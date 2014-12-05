import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

budget = 1000000
index = 100


def prepare_data(df):
    '''
        Return: (pdf,sdf), dataframes containing data on
                portfolio and statistics.
    '''
    df['Time'] = pd.to_datetime(df['Time'])
    df = df.set_index('Time')

    statscolumns = ['Maximum Value', 'Minimum Value', 'Expected Value', 'CVaR', 'Trading Cost']

    pdf = df[[c for c in df.columns if c not in statscolumns]]
    sdf = df[[c for c in df.columns if c in statscolumns] + ['Type']]

    # Calculate some extra values
    sdf['Current Value'] = pdf.sum(axis=1)
    sdf['Expected Profit'] = sdf['Expected Value'] - sdf['Current Value']
    sdf['Actual Profit'] = sdf['Current Value'].diff(2)  # Shift by two due to two types

    sdf = sdf.reset_index().set_index(['Type', 'Time'])
    sdf['Cumulative Trading Cost'] = df.reset_index().groupby(by=['Type', 'Time'])['Trading Cost'].sum().groupby(level=[0]).cumsum()
    sdf = sdf.reset_index().set_index('Time')
    sdf['Net Value'] = sdf['Current Value'] - sdf['Cumulative Trading Cost']
    return pdf, sdf

df = pd.read_csv('../data/portfolio_revision_all_bootstrap.csv')
pdf, sdf = prepare_data(df)

mdf = pd.read_csv('../data/portfolio_revision_all_moment.csv')
mpdf, msdf = prepare_data(mdf)

# Figure: Portfolio revisions

gp = pdf.groupby('Type').get_group('risk_averse').drop('Type', 1)
gp2 = pdf.groupby('Type').get_group('risk_neutral').drop('Type', 1)

gp = gp.T.div(gp.sum(1)).T
gp2 = gp2.T.div(gp2.sum(1)).T

# Tick axis every n months
n = 12
plt.figure(1, figsize=(6, 8), dpi=100)

ax1 = plt.subplot(211)
p1 = (gp.loc[:, gp.loc[gp.index[1]:].sum() > 0]*100).plot(
    kind='bar',
    ax=ax1,
    stacked=True,
    colormap=sns.cubehelix_palette(
        8, start=.5, rot=-1, as_cmap=True
    ),
    width=1
)
ticks = p1.xaxis.get_ticklocs()
ticklabels = [l.get_text() for l in p1.xaxis.get_ticklabels()]
p1.xaxis.set_ticks(ticks[::n])
p1.xaxis.set_ticklabels(map(lambda x: x[:-9], ticklabels[::n]))
plt.xticks(rotation=18)

# leg1 = p1.legend(loc='left', ncol=1, bbox_to_anchor=(1.0, 1.0), fontsize=8)
leg1 = p1.legend(
    bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
    ncol=7, mode="expand", borderaxespad=0.)
plt.ylim(0, 100)
plt.xlabel('')


ax2 = plt.subplot(212)
p2 = (gp2.loc[:, gp2.loc[gp2.index[1]:].sum() > 0]*100).plot(
    kind='bar',
    ax=ax2,
    stacked=True,
    colormap=sns.cubehelix_palette(
        8, start=.5, rot=-1, as_cmap=True
    ),
    width=1
)
ticks = p2.xaxis.get_ticklocs()
ticklabels = [l.get_text() for l in p2.xaxis.get_ticklabels()]
p2.xaxis.set_ticks(ticks[::n])
p2.xaxis.set_ticklabels(map(lambda x: x[:-9], ticklabels[::n]))
plt.xticks(rotation=18)

# leg2 = p2.legend(loc='center left', ncol=2, bbox_to_anchor=(1, 1.0), fontsize=8)
leg2 = p2.legend(
    bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
    ncol=7, mode="expand", borderaxespad=0.)
plt.ylim(0, 100)
plt.xlabel('')

plt.tight_layout(h_pad=2)
plt.subplots_adjust(top=0.93)
plt.savefig('../pic/trading_portfolio.pdf')

# Figure: Portfolio predictions vs. scenarios

gp = sdf.groupby('Type').get_group('risk_averse').drop('Type', 1)
gp2 = sdf.groupby('Type').get_group('risk_neutral').drop('Type', 1)

gp['Forecasted Value'] = gp['Expected Value'].shift(1)
gp['Max Forecasted Value'] = gp['Maximum Value'].shift(1)
gp['Min Forecasted Value'] = gp['Minimum Value'].shift(1)

gp2['Forecasted Value'] = gp2['Expected Value'].shift(1)
gp2['Max Forecasted Value'] = gp2['Maximum Value'].shift(1)
gp2['Min Forecasted Value'] = gp2['Minimum Value'].shift(1)

plt.figure(2)

ax1 = plt.subplot(211)
(gp['Forecasted Value']/budget).plot(c=sns.xkcd_rgb['salmon'], lw=3, ax=ax1)
(gp['Current Value']/budget).plot(c=sns.xkcd_rgb['black'], lw=2, alpha=0.7, ax=ax1)
plt.fill_between(
    gp.index,
    gp['Max Forecasted Value'].values/budget,
    gp['Min Forecasted Value'].values/budget,
    color=sns.xkcd_rgb['pale red']
)
plt.xlabel('')
plt.ylabel('Portfolio Value [MDKK]')

ax2 = plt.subplot(212)
(gp2['Forecasted Value']/budget).plot(c=sns.xkcd_rgb['salmon'], lw=3, ax=ax2)
(gp2['Current Value']/budget).plot(c=sns.xkcd_rgb['black'], lw=2, alpha=0.7, ax=ax2)
plt.xlabel('')
plt.ylabel('Portfolio Value [MDKK]')
plt.fill_between(
    gp2.index,
    gp2['Max Forecasted Value'].values/budget,
    gp2['Min Forecasted Value'].values/budget,
    color=sns.xkcd_rgb['pale red']
)

plt.tight_layout()
plt.savefig('../pic/trading_forecasted_value.pdf')

# Set up 1/N results
rawetfs = pd.read_csv('../data/etfs_max_mean_prices.csv', parse_dates=0)
rawetfs = rawetfs.rename(columns={u'Unnamed: 0': 'Time'})
rawetfs['Time'] = pd.to_datetime(rawetfs['Time'])
rawetfs = rawetfs.set_index('Time')
# Select date range of problem
rawetfs = rawetfs.ix[sdf.index]
# Normalize prices to initial prices
rawetfs = rawetfs / rawetfs.ix[0]
# Compute value of 1 over n portfolio
overnportfoliovalue = index * rawetfs.sum(1) / len(rawetfs.columns)

# Value of portfolio over time
plt.figure(3, figsize=(6, 3), dpi=100)
ax = plt.axes()
namedict = {
    'risk_averse': 'Risk Averse, bootstrap',
    'risk_neutral': 'Risk Neutral, bootstrap'
}

for l, d in sdf.groupby('Type'):
    (d['Net Value']*index/budget).plot(label=namedict[l], ax=ax)

mnamedict = {
    'risk_averse': 'Risk Averse, moment matching',
    'risk_neutral': 'Risk Neutral, moment matching'
}

for l, d in msdf.groupby('Type'):
    (d['Net Value']*index/budget).plot(label=mnamedict[l], ax=ax)

overnportfoliovalue.plot(label='1 over N', ax=ax)

plt.xlabel('')
plt.ylabel("Portfolio Net Value [DKK]")
plt.legend(ncol=1, loc='upper left')

plt.savefig('../pic/trading_portfolio_value.pdf')
