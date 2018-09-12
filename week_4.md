Since the project specification is due this Friday night, we are focusing on the spec instead of doing research in this week. However, we also have time to plan our timeline:

WEEK 2: [\n]
Understanding the project requirements, exploring different ways to detect edges and proposing them to the research supervisor, literature review on different machine learning including image recognition techniques and statistics

WEEK 3:
Understanding the resources and data available and getting the initial MATLAB code to set up. Re-writing MATLAB code to Python to primarily detect edges, and finding examples where mean:sd does not work to establish the research question

WEEK 3-5
Implementing and optimising Python code to properly replicate the MATLAB code. Statistical methods of mean:sd ratio with other calculations are still to be tested to find out better features and calculations of detecting edges

WEEK 6-10
Implementing Machine learning algorithms including Image classification, Logic Regression and LSTM classification methods. We will continue to find the right features to detect edge candidates accurately, we will implement these techniques on the previous samples where mean:sd failed

WEEK 10-12
Comparing all the implementations and outcomes to discard unreliable and failed implementations. Running benchmark tests and comparing datasets with human vision to determine accuracy. Final changes and revisions made to the implementation of edge detection method. Writing Final Report

WEEK 11
Presentation of the project and discussion about writing Final Report


Also, we have implemented code in detecting edges horizontally instead of vertically, that is, we looked at the data by going through each time slot instead of looking at each day. 
Below is the rects detected by the algorithm:
![rect img](/images/rect.jpg)
However, the old approach will be taken as our main algorithm as looking at each time slot gave us rects intead of edges, which is not the result we want as we only consider edges as our target to investigate. So, we need to denoise the image before processing instead of finding a new way to detect edges, as we already have an appropriate algorithm for detecting edges.
