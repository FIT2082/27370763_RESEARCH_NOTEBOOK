This week, we are going around some noise clearing techniques in order to get the edges exactly for our classification.
We have implemented median filter to the data set in order to try clearing most of the noise in the edge.

Figure: Edges detected without noise clearing
![noisyedges](/images/minfilttest.png)

As we can see from the above, the edges are really unclear and in order to make the dataset usable, we used median filter to clear most of the noises as the above image,

Figure: Data after applying median-filter to it
![medfilt](/images/cleanedge.png)

From the figure we can see that most of the noises are cleared. However, the edges are also kind of cleared out after using the median filter function.
Our aim next week is to link these broken edges together and also, we are going to look at machine learning and calculations on the data in order to find out a way to classify edges.

Also, a function that plots multiple graphs has been implemented for our convenience when testing for algorithms.

Our aim next week is to improve the median filter that we were using, so that we can get what we needed.
