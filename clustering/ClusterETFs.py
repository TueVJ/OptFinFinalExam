import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import pandas.io.data as web
import scipy.cluster.hierarchy as hier
import seaborn as sns

from collections import defaultdict
from matplotlib.ticker import FuncFormatter
from sklearn.decomposition import PCA


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

instruments = pd.read_csv('../input_data/instruments2.csv')

startdate = '2005-01-28'
enddate = '2014-11-10'

# Download the asset data if the data isn't there,
# or it doesn't match the instruments in the csv file.
try:
    baseetfs = pd.read_csv('../data/base_price_data.csv')
    baseetfs = baseetfs.set_index(
        baseetfs.columns[0]
    ).convert_objects(convert_numeric=True)
    baseetfs.index = baseetfs.index.to_datetime()
except IOError:
    baseetfs = web.DataReader(instruments.values.flatten().tolist(), 'google', startdate, enddate)
    baseetfs = baseetfs.Close.convert_objects(convert_numeric=True)
    baseetfs.to_csv('../data/base_price_data.csv')

# Filter out ETFs with a low number of observations
baseetfs = baseetfs.loc[:, baseetfs.count() > 2400]

print "Using {} ETFs with more than 2400 price entries".format(len(baseetfs.columns))

# Weekly ETF prices. Missing data is filled forward.
wetfs = baseetfs.resample('W-WED', how='first', fill_method='pad')

# Build correlation matrix of weekly returns
dlogreturns = np.log(wetfs).diff()
#dlc = dlogreturns.cov()
dlc = dlogreturns.corr()

# Colormap used for clusters
cluster_cmap = sns.cubehelix_palette(
    as_cmap=True,
    start=0.5,
    rot=2.0,
    hue=1.3,
    gamma=1.0,
    dark=0.2,
    light=0.8
)


# Get eigenvalues and eigenvectors for plotting.
pca = PCA().fit(np.nan_to_num(dlogreturns.values))
# Extract largest eigenvalue and its eigenvector
eig1, evec1 = pca.explained_variance_[0], pca.components_[0]
# Extract second-largest eigenvalue and its eigenvector
eig2, evec2 = pca.explained_variance_[1], pca.components_[1]

print 'Explained variance by component 1: {:.02f} %'.format(
    pca.explained_variance_ratio_[0]*100)
print 'Explained variance by component 2: {:.02f} %'.format(
    pca.explained_variance_ratio_[1]*100)

# Clustering methods:
# 'single': duv = min(d(u[i], v[j]))_ij
# 'complete': duv = max(d(u[i], v[j]))_ij
# 'average': duv = avg(d(u[i], v[j]))_ij
# 'weighted': duv = (d(s,v) + d(t,v))/2 ,
#             u is formed from s,t
methods = ['single', 'complete', 'average', 'weighted']
# Labels to be plotted on projection graphs
plotted_labels = ['IAU', 'IEF', 'VNQ', 'IXG', 'FXI', 'EWM']


Zs = [hier.linkage(1 - dlc.values ** 2, method=m) for m in methods]
# Create nclust clusters from the linkage matrix data
idxs = []
for i, (Z, m) in enumerate(zip(Zs, methods)):
    plt.figure(1, dpi=100, figsize=(6, 4))
    plt.subplot(2, 2, i)
    idx = hier.fcluster(
        Z, nclust,
        criterion='maxclust'
    )
    idxs.append(idx)
    #Plot dendrogram
    hier.dendrogram(
        Z, color_threshold=Z[-nclust+1, 2],
        # labels=['']*len(dlc.index),
        labels=dlc.index,
        leaf_font_size=4)
    plt.title(m)

    # Construct dataframe
    plotdf = pd.DataFrame(dict(
        e1=evec1.dot(dlc), e2=evec2.dot(dlc),
        cluster=idx, label=dlc.index
    ))

    plt.figure(2, dpi=100, figsize=(6, 4))
    ax = plt.subplot(2, 2, i)
    plotdf.plot(
        kind='scatter',
        x='e1', y='e2',
        c=plotdf.cluster,
        cmap=cluster_cmap,
        ax=ax
    )
    label_point(plotdf.e1, plotdf.e2, [x if x in plotted_labels else '' for x in plotdf.label], ax)
    plt.xlabel('Projection on first PCA')
    plt.ylabel('Projection on second PCA')
    plt.title(m)
    plt.ylim([plotdf.e2.min()*1.10, plotdf.e2.max()*1.10])

plt.figure(1)
plt.tight_layout()
plt.savefig('pic/dendro_methods.pdf')
plt.figure(2)
plt.tight_layout()
plt.savefig('pic/pca_methods.pdf')

idx = idxs[2]

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

plt.figure(3, dpi=100, figsize=(6, 4))
axl = plt.subplot(121)
#selected_etfs = ['IAU', 'VNQ', 'IXG']
(baseetfs/baseetfs.ix[1])[selected_etfs_mean].plot(
    color=map(cluster_cmap, clusteridx),
    ax=axl
)
plt.gca().yaxis.set_major_formatter(FuncFormatter(percentformatter))
plt.tight_layout()
plt.ylabel('Price index')
plt.legend(ncol=2)
plt.title('Max return')

axr = plt.subplot(122)
(baseetfs/baseetfs.ix[1])[selected_etfs_std].plot(
    color=map(cluster_cmap, clusteridx),
    ax=axr,
)
plt.gca().yaxis.set_major_formatter(FuncFormatter(percentformatter))
plt.title('Min stdev')
plt.legend(ncol=2)
plt.tight_layout()
plt.savefig('pic/prices_selected_assets.pdf')


np.savetxt('../data/etfs_max_mean.csv', selected_etfs_mean, fmt='%s')
np.savetxt('../data/etfs_min_std.csv', selected_etfs_std, fmt='%s')
wetfs[selected_etfs_mean].to_csv('../data/etfs_max_mean_prices.csv', date_format='%Y-%m-%d')
wetfs[selected_etfs_std].to_csv('../data/etfs_min_std_prices.csv', date_format='%Y-%m-%d')
np.savetxt('../data/dates.csv', wetfs.index.format(), fmt='%s')
