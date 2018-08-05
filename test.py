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

def findSD(matrixlist): #find the standard deviation of whole year (per day)
    SD_year = []
    for days in range(0, 365):
        current_day_array = []
        for hours in range(len(matrixlist)):
            current_day_array.append(matrixlist[hours][days])
        current_day_sd = np.std(current_day_array)
        SD_year.append(current_day_sd)
    return SD_year

colormap(matrixlist)
