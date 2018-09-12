This week, I have been working on improving the median filter that have implemented last week. At first, my algorithm took only 1-D arrays for median filter while this is totally incorrect as the whole graph should be considered as 2-D graph. With the help of my groupmate, Surayez, we have successfully implemented an algorithm that using median filter that looks at 2d matrices as reference and replace the specific pixel as the median of the whole matrix. (Matrix size can be picked)

1D MEDFILT:
![med1D img](/images/medfiltlow.jpg)
From here, we can see that most of the noise is still unprocessed, this is due to the fact that most of the pixels are just looking at the same row to decide its' value, so that if there are many noises in the right or left of that pixel, median filter will fail to denoise these small pixels (but it still denoised a lot). Therefore, we improved the algorithm. Instead of taking 1D median filter, we take 2D median filter as our main tool to denoise the data.

2D MEDFILT:
![med2D img](/image/medfilthi.jpg)
2D median filter has been used here. Compare to the last one, there are obviously less noise in the image. Although there are still small noises in the graph (just some small pixels).

However, there is a new issue for us. We can see that some of the edges were seperated, which is likely caused by the fact that median filter filtered out some of the data which our algorithm fails to detect the difference between pixels. And some part of the edges is removed accidentally (which mainly because of medfilt as well). This will be our aim for next week: recover all edges and extract them out so that machine learning can be applied to it.
