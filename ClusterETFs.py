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
except IOError:
    baseetfs = web.DataReader(instruments.values.flatten().tolist(), 'google', startdate, enddate)
    baseetfs = baseetfs.Close
    baseetfs.to_csv('data/base_price_data.csv')
