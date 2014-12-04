import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv('../data/portfolio_revision_all.csv').set_index('Time')

statscolumns = ['Expected Value', 'CVaR', 'Trading Cost']

pdf = df[[c for c in df.columns if c not in statscolumns]]
sdf = df[[c for c in df.columns if c in statscolumns] + ['Type']]

sdf['Current Value'] = pdf.sum(axis=1)
sdf['Expected Profit'] = sdf['Expected Value'] - sdf['Current Value']
sdf['Actual Profit'] = sdf['Current Value'].diff()
sdf['Cumulative Trading Cost'] = sdf['Trading Cost'].cumsum()
raise SystemExit
# Plot portfolios

plt.ion()
plt.figure(figsize=(6, 3), dpi=100)
ax = plt.axes()
pdf.loc[:, pdf.sum() > 0].plot(kind='bar', stacked=True, ax=ax)
plt.ylim((0, 1200000))
plt.legend(ncol=5)
plt.xticks(rotation=0)
plt.ylabel("Asset Value [DKK]")
plt.xlabel('')
plt.tight_layout()
plt.savefig('../pic/portfoliorevision_portfolio.pdf')

# Export latex table
sdf['Expected Profit'] = sdf['Expected Value'] - pdf.sum(axis=1)
sdf.to_latex('../tex/portfoliorevision_table.tex', columns=['Expected Profit', 'CVaR', 'Trading Cost'])
