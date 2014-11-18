import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import pandas.io.data as web

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

dlogreturns = np.log(wetfs).diff()
