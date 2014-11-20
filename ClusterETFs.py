import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import pandas.io.data as web
import scipy.cluster.hierarchy as hier
import seaborn as sns

from collections import defaultdict
from matplotlib.ticker import FuncFormatter


def percentformatter(x, pos=0):
    return "{:.0f}%".format(100 * x)


def label_point(x, y, val, ax):
    # http://stackoverflow.com/questions/15910019/
    a = pd.DataFrame({'x': x, 'y': y, 'val': val})
    offsetx = (a.x.max() - a.x.min()) * 0.01
    offsety = (a.y.max() - a.y.min()) * 0.01
    for i, point in a.iterrows():
        ax.text(point['x'] + offsetx, point['y'] + offsety, str(point['val']), alpha=0.4)

#Set number of clusters
nclust = 10

plt.ion()

instruments = pd.read_csv('instruments2.csv')

startdate = '2005-01-28'
enddate = '2014-11-10'

# Download the asset data if the data isn't there,
# or it doesn't match the instruments in the csv file.
try:
    baseetfs = pd.read_csv('data/base_price_data.csv')
    baseetfs = baseetfs.set_index(
        baseetfs.columns[0]
    ).convert_objects(convert_numeric=True)
    baseetfs.index = baseetfs.index.to_datetime()
except IOError:
    baseetfs = web.DataReader(instruments.values.flatten().tolist(), 'google', startdate, enddate)
    baseetfs = baseetfs.Close.convert_objects(convert_numeric=True)
    baseetfs.to_csv('data/base_price_data.csv')

# Filter out ETFs with a low number of observations
baseetfs = baseetfs.loc[:, baseetfs.count() > 2400]

print "Using {} ETFs with more than 2400 price entries".format(len(baseetfs.columns))

# Weekly ETF prices. Missing data is filled forward.
wetfs = baseetfs.resample('W-WED', how='first', fill_method='pad')

# Build correlation matrix of weekly returns
dlogreturns = np.log(wetfs).diff()
c = dlogreturns.corr()

# Colormap used for clustering
cluster_cmap = sns.cubehelix_palette(
    as_cmap=True,
    start=0.5,
    rot=-1.5,
    hue=1.0,
    gamma=1.0,
    dark=0.3,
    light=0.7
)


# Get eigenvalues and eigenvectors for plotting.
eigs, evecs = np.linalg.eigh(c)
# Extract largest eigenvalue and its eigenvector
eig1, evec1 = eigs[-1], evecs[-1]
# Extract second-largest eigenvalue and its eigenvector
eig2, evec2 = eigs[-2], evecs[-2]

# Clustering methods:
# 'single': duv = min(d(u[i], v[j]))_ij
# 'complete': duv = max(d(u[i], v[j]))_ij
# 'average': duv = avg(d(u[i], v[j]))_ij
# 'weighted': duv = (d(s,v) + d(t,v))/2 ,
#             u is formed from s,t
methods = ['single', 'complete', 'average', 'weighted']

Zs = [hier.linkage(1 - c.values ** 2, method=m) for m in methods]
# Create nclust clusters from the linkage matrix data
idxs = []
for i, (Z, m) in enumerate(zip(Zs, methods)):
    plt.figure(1)
    plt.subplot(2, 2, i)
    idx = hier.fcluster(
        Z, nclust,
        criterion='maxclust'
    )
    idxs.append(idx)
    #Plot dendrogram
    hier.dendrogram(
        Z, color_threshold=Z[-nclust+1, 2],
        labels=[],
        # labels=c.index,
        leaf_font_size=10)
    plt.title(m)

    # Construct dataframe
    plotdf = pd.DataFrame(dict(
        e1=evec1.dot(c), e2=evec2.dot(c),
        cluster=idx, label=c.index
    ))

    plt.figure(2)
    ax = plt.subplot(2, 2, i)
    plotdf.plot(
        kind='scatter',
        x='e1', y='e2',
        c=plotdf.cluster,
        cmap=cluster_cmap,
        ax=ax
    )
    #label_point(plotdf.e1, plotdf.e2, plotdf.label, ax)
    plt.xlabel('Projection on first PCA')
    plt.ylabel('Projection on second PCA')

idx = idxs[0]

clustered_etfs = defaultdict(list)
for l, c in zip(plotdf.label, plotdf.cluster):
    clustered_etfs[c].append(l)

selected_etfs_mean = []
selected_etfs_std = []
clusteridx = []
for c, l in clustered_etfs.iteritems():
    # Select asset with highest mean weekly return
    selected_etfs_mean.append(wetfs[l].mean().idxmax())
    # Select assets with lowest standard deviation
    selected_etfs_std.append(wetfs[l].std().idxmin())
    # Save cluster index for coloring
    clusteridx.append(c*1.0/(nclust-1))

#selected_etfs = ['IAU', 'VNQ', 'IXG']
(baseetfs/baseetfs.ix[1])[selected_etfs_mean].plot(
    color=map(cluster_cmap, clusteridx),
)
plt.gca().yaxis.set_major_formatter(FuncFormatter(percentformatter))
plt.tight_layout()

np.savetxt('data/etfs_max_mean.csv', selected_etfs_mean)
np.savetxt('data/etfs_min_std.csv', selected_etfs_std)
