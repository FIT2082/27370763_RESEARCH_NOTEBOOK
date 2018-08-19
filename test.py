import scipy.io
import numpy as np
import matplotlib.pyplot as plt
data = scipy.io.loadmat('house00002.mat')
matrix = data['image']

#convert data into array (each row = 1 time slot, column(item) = day)
matrixlist = np.squeeze(np.matrix(matrix)).tolist()

def colormap(matrixlist): #plotting
    plt.pcolor(matrixlist)
    plt.gca().invert_yaxis()
    plt.show()
    
#####################################################################################
def findSD_hr(matrixlist): #find the standard deviation of whole day (per hour)
    SD_hour = []
    for day in matrixlist:
        SD_hour.append(np.std(day))
    return SD_hour
    
def findVar_hr(matrixlist): #find the variance of whole day (per hour)
    var_hour = []
    for day in matrixlist:
        var_hour.append(np.var(day))
    return var_hour

def findmean_hr(matrixlist): #find the mean of whole day (per hour)
    mean_hour = []
    for day in matrixlist:
        mean_hour.append(np.mean(day))
    return mean_hour

def findmeansdratio_hr(matrixlist): #find the mean - standard deviation ratio of whole day (per hour)
    msr_hour = []
    for day in matrixlist:
        msr_hour.append(np.mean(day)/np.std(day))
    return msr_hour
#####################################################################################

def clean(matrixlist): #remove noises
    pass
colormap(matrixlist)
print(findmeansdratio_hr(matrixlist))
