This week, we have been working on improving the accuracy of the ARIMA algorithm. To achieve this, we intended to compare the output given by the algorithm to the original datasets that was given by Lachlan Andrew, which are rectangles plotted within the dataset:
![savedrect img](/images/saverect.png)
We intend to plot the area that was classified as "rects" using ARIMA. In fact, we originally plotted less than half of the pixels (image from week9 workbook), but we improved the algorithm by adding all datasets to the algorithm instead of using only one timeslot of data everytime. After making the above changes, the algorithm has successfully detect more than 60% of the area that was considered as "rects":
![improvedrect img](/images/improved.png)
