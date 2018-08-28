import scipy.io
import numpy as np
import matplotlib.pyplot as plt
data = scipy.io.loadmat('house00004.mat')
matrix = data['image']
matrixlist = np.squeeze(np.matrix(matrix)).tolist()

#####################################################################################
def colormap(matrixlist): #plotting
    plt.pcolor(matrixlist)
    plt.gca().invert_yaxis()
    plt.show()
    
def multiplot(start,ran): #plotting multiple graphs (can be improved to edge multiple)
    for i in range(start,ran):
        data = scipy.io.loadmat(('house'+str(i).zfill(5))+'.mat')
        matrix = data['image']
        matrixlist = np.squeeze(np.matrix(matrix)).tolist()
        colormap(findedges(matrixlist, findmean(matrixlist, True)))
    
#####################################################################################
def findSD(matrixlist,eachday = False):#find the standard deviation of each time slot (per horizontal)
    if eachday == True: #if eachday is true, sd of each day
        matrixlist = np.swapaxes(matrixlist,0,1).tolist()
    SD = []
    for item in matrixlist:
        SD.append(np.std(item))
    return SD
    
def findVar(matrixlist,eachday = False): #find the variance of each time slot (per horizontal)
    if eachday == True:
        matrixlist = np.swapaxes(matrixlist,0,1).tolist()
    var = []
    for day in matrixlist:
        var.append(np.var(day))
    return var

def findmean(matrixlist,eachday = False): #find the mean of each time slot (per horizontal)
    if eachday == True:
        matrixlist = np.swapaxes(matrixlist,0,1).tolist()
    mean = []
    for day in matrixlist:
        mean.append(np.mean(day))
    return mean

def findmeansdratio(matrixlist,eachday = False): #find the mean - standard deviation ratio of each time slot (per horizontal)
    if eachday == True:
        matrixlist = np.swapaxes(matrixlist,0,1).tolist()
    msr = []
    for day in matrixlist:
        msr.append(np.mean(day)/np.std(day))
    return msr
#####################################################################################

def findedges(matrixlist, varlist):
    matrix = []
    for item in matrixlist:
        item = scipy.ndimage.filters.minimum_filter1d(item,2)
        matrix.append(item)
        
    matrix = np.swapaxes(matrix,0,1).tolist()
    for i in range(len(matrix)):
        for j in range(len(matrix[i])):
            if abs(matrix[i][j] - matrix[i][j-1]) > varlist[i] and matrix[i][j-1] != 2:
                matrix[i][j] = 2
    for i in range(len(matrix)):
        for j in range(len(matrix[i])):
            if matrix[i][j] != 2:
                matrix[i][j] = 0
    
    return np.swapaxes(matrix,0,1).tolist()

#####################################################################################

def clean(matrixlist): #remove noises
    pass

#scipy.signal.medfilt(matrixlist)
#matrixlist = np.swapaxes(matrixlist,0,1).tolist()
multiplot(1,50)

