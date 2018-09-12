
import scipy.io
import scipy.signal
import numpy as np
import matplotlib.pyplot as plt
data = scipy.io.loadmat('house00008.mat')
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
        colormap(matrixlist)
        colormap(findedges(matrixlist, findSD(matrixlist, True)))
    
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
def find_sub_list(sl,l):
    results=[]
    sll=len(sl)
    for ind in (i for i,e in enumerate(l) if e==sl[0]):
        if l[ind:ind+sll]==sl:
            results.append((ind,ind+sll-1))
    return results
#https://stackoverflow.com/questions/17870544/find-starting-and-ending-indices-of-sublist-in-list

#####################################################################################

def findedges(matrixlist, varlist):
    matrix = []
    for item in matrixlist:
        item = scipy.signal.medfilt(item,[15])
        matrix.append(item)
        
    matrix = np.swapaxes(matrix, 0, 1).tolist()    
    for i in range(len(matrix)):
        for j in range(len(matrix[i])):
            if abs(matrix[i][j] - matrix[i][j-1]) > varlist[i] and matrix[i][j-1] != 2:
                matrix[i][j] = 2
    for i in range(len(matrix)):
        for j in range(len(matrix[i])):
            if matrix[i][j] != 2:
                matrix[i][j] = 0
    matrix = np.swapaxes(matrix, 0, 1).tolist()
    #############################
    #This part links the edges together
    #instead removing unlikely edges, link them and mark them as unedge when classifying
    for rows in range(len(matrix)):
        if not 2 in matrix[rows]:
            pass
        for i in range(len(matrix[rows])):
            try:
                if matrix[rows][i] != 2:
                    for j in range(1,6):
                        if matrix[rows][i+j] == 2:
                            matrix[rows][i] = 2
            except IndexError:
                pass
        for num in range(16):
            cleanlist = find_sub_list([0]+[2]*num+[0],matrix[rows])
            if cleanlist != []:
                for item in cleanlist:
                    for i in range(item[0],item[1]+1):
                        matrix[rows][i] = 0
    
            
    
    return matrix

#####################################################################################

def clean(matrixlist): #remove noises
    pass

#scipy.signal.medfilt(matrixlist)
#matrixlist = np.swapaxes(matrixlist,0,1).tolist()
#colormap(matrixlist)
#unclearedge = findedges(matrixlist, findSD(matrixlist,True))
#colormap(unclearedge)
multiplot(100,500)
##LINK EDGE: TRY LOOKING AT ORIGINAL DATA and compare
