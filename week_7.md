This will be the last week for Andrew Lachlan to be the supervisor of our research project. Mahsa Salehi will be our new supervisor starting from next week.

This week, I am focusing on working in linking edges and remove edges that have be detected mistakenly by the old algorithm. I have been trying different approaches:

First approach:
Extending edges that have been detected until the next pixel is considered as "not edge", while removing single pixels from each time slot.

(FIRST TRY)
![link img](images/linkedge.jpg)
It looks like this approach works pretty well. However, it will extends by mistake and make edges that did not exist. This is due to wrong implementations in code. 


