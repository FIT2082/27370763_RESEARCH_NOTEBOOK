This week we have been working on the accuracy algorithm for testing the output from the ARIMA algorithm.

Originally, we were taking a ratio of true positive and true negative values as a one-to-one ratio, such that some of the values may be ignored when detecting accuracies and the output may not be giving the correct values.

However, Mahsa told us we can try to implement the accuracy detection algorithm by varying the ratio of true positvies and true negatives and try to get the most accurate results by varying numbers and variables. Unfortunately as time was very tight for us, we could not implement the algorithm on time according to our time schedule. Therefore, we decided to use the old  result although it is not the most accurate implementation but it still gives a reasonable result for us to use in our poster and final report.

We in fact get a 67% accuracy when using the ARIMA detection algorithm using "house0002.mat" as our database. There are some cases that the ARIMA model was working better than the statistical model:

[!arima img](/images/arima-statcompare.png)
a
