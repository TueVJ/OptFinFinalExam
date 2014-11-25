
###
#  TODO: Move to seperate file.
###

# Return of 1/N strategy is mean quotient
# of prices when trading stops and starts.
tstart = 150
tstop = len(wetfs.index)-1

print 'Assuming trading starts at {0} and ends at {1}.'.format(
    wetfs.index[tstart], wetfs.index[tstop]
)

print 'Max mean ETFs result:'
r = (wetfs[selected_etfs_mean].ix[tstop]/wetfs[selected_etfs_mean].ix[tstart]).mean()
print 'Return of 1/N strategy: {:.02f} %'.format(
    (r-1)*100
)
print 'Annualized return of 1/N: {:.02f} %'.format(
    (r**(52./(tstop-tstart))-1)*100
)

print 'Min stdev ETFs result:'
r = (wetfs[selected_etfs_std].ix[tstop]/wetfs[selected_etfs_std].ix[tstart]).mean()
print 'Return of 1/N strategy: {:.02f} %'.format(
    (r-1)*100
)
print 'Annualized return of 1/N: {:.02f} %'.format(
    (r**(52./(tstop-tstart))-1)*100
)
# Plot returns from 1/N strategy
plt.figure(4, dpi=100, figsize=(6, 4))
(999000*wetfs[selected_etfs_mean].mean(axis=1)/(wetfs[selected_etfs_mean].mean(axis=1).ix[tstart])).ix[tstart:tstop].plot(label='Max mean ensemble')
(999000*wetfs[selected_etfs_std].mean(axis=1)/(wetfs[selected_etfs_std].mean(axis=1).ix[tstart])).ix[tstart:tstop].plot(label='Min stdev ensemble')
plt.legend()
plt.savefig('pic/returns_1overN_only.pdf')
