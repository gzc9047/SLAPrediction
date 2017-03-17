# SLAPrediction
## Introduction
Predict SLA for multiple dependencies. This tool can help you predict it SLA before your make design decision and write the real code. Like:

* Your code calls multiple APIs sequentially (or concurrently), you want to estimate the SLA of its latency based on these APIs latency.
* Your App will allow user store many documents in it, you want to estimate the SLA of all documents' size for one user based on: 1) the SLA of how many documents each user own, 2) the SLA of one users' all documents size. `This use case is supported now. But the formula is not perfect, use it carefully. TODO (louix): improve it.`

## Usage
SLA in this project means collection of probability and values. This is a SLA example (SLA_A.txt), first column means the probability of value no more than the second column (it is sample of CDF, cumulative distribution function).
```
0.1 1 // 10% items no more than 1
0.5 2
0.9 3
0.99 4
0.999 5
0.9999 6
1 7 // All items no more than 7
```

Here is SLA_B.txt.
```
0.1 2
0.5 3
0.9 5
0.99 7
0.999 11
0.9999 13
1 17
```

We can image that SLA_A.txt and SLA_B.txt show the latency of service A and B.

### SLA of A + B
If you want to predict the latency of A + B (means call A synchronously until it finish, than call B and wait until it returns), run this command in shell:
`merge_general.sh merge_sequence.awk SLA_A.txt SLA_B.txt`

It will show this as result:
```
0.1036	3.7999999999999998
0.2012	4.2000000000000002
0.3004	4.5999999999999996
0.4012	5.0000000000000000
0.50098	5.4000000000000004
0.60066	5.7999999999999998
0.700756	6.2999999999999998
0.80022	6.8000000000000007
0.900343	7.7000000000000002
0.95014	8.5000000000000000
0.990026	10.3000000000000007
0.999008	13.8000000000000007
0.9999	16.1999999999999993
1	24.0000000000000000
```

This means 10.35%’s latency is no more than 3.7999999999999998, 20.12% no more than 4.2000000000000002 and so on.

### SLA of max(A, B)
If you want to predict the latency of the maximum of A and B (means call A and B concurrently, wait until all of them return), run this command in shell:
`merge_general.sh merge_parallel_max.awk SLA_A.txt SLA_B.txt`

It will show:
```
0.1012	2.2000000000000002
0.2004	2.5000000000000000
0.3004	2.7999999999999998
0.4036	3.0000000000000000
0.50022	3.2999999999999998
0.60106	3.7999999999999998
0.70083	4.2000000000000002
0.80051	4.5999999999999996
0.900081	5.2000000000000002
0.950135	6.2000000000000002
0.99	7.0000000000000000
0.999	11.0000000000000000
0.9999	13.0000000000000000
1	17.0000000000000000
```

### SLA of min(A, B)
If you want to predict the latency of the minimum of A and B (means call A and B concurrently, wait until first of them return), run this command in shell:
`merge_general.sh merge_parallel_min.awk SLA_A.txt SLA_B.txt`

It will show:
```
0.1	1.0000000000000000
0.2	1.3000000000000000
0.304	1.6000000000000001
0.4016	1.8000000000000000
0.504	2.0000000000000000
0.6	2.1000000000000001
0.70028	2.2999999999999998
0.8012	2.6000000000000001
0.9004	2.8999999999999999
0.95	3.0000000000000000
0.990026	3.7999999999999998
0.999006	4.5999999999999996
0.9999	5.0000000000000000
1	7.0000000000000000
```


### SLA of multiply(A, B)
If you want to predict the entire size of one user's documents, A means document number, and B means document size, run this command in shell:
`merge_general.sh merge_multiply.awk SLA_A.txt SLA_B.txt`

It will show:
```
0.1004	3.120000
0.2028	4.000000
0.3004	4.800000
0.4014	5.520000
0.5013	6.400000
0.900059	12.920000
0.990031	21.460000
0.999002	31.960000
0.999901	44.000000
1	119.000000
```

## Limitation
* Assume input SLAs are independent.
* Input: This tool assume (do not means it have check for these item) that SLA content format is:
  * First column is probability, second column is SLA value.
  * SLA value is incremental with the probability.
  * There are not item have the same probability.
  * There is always a item have 1 as the probability.
* Output:
  * SLA probability and value have at most 18 digitals after radix point.
  * SLA probability and value do not use round to make it easier to read.
  * Default output probability list is 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.99 0.999 0.9999 1.
  * If your input SLA is exponentially distributed (or near), the value of SLA result will be larger then the real one but near.


## Internal detail
How I implement it? Simulation:

* 1 Extend the input SLA to be more elaborate.
  * For example if input SLA have “0.1 1” and “0.2 3”, then this tool will generate several SLA item like “0.1 1” “0.01 1.2” “0.01 1.4” “0.01 1.6” … “0.01 3”. These means 10% of the value are 1, 1% values are 1.2 … 1% values are 3. This is linear estimation, if your input SLA is exponentially distributed (or near), these values are larger than the real one.
  * Result will be better if your input is more elaborate, because there will be less error between the real one than my tool’s estimation.
* 2 Then calculate the probability of UserFunction(Ai, Bj).
  * If input are SLA A & SLA B, Ai, Bj are some special values), UserFunction may be add, max or min.
  * Probability result is P(Ai) * P(Bj).
  * The second example in the introduction will be complex here because we cannot just multiply them. Like 1% user have 10 documents, and 1% documents’ size is 1MB, the result is not 0.01% with 10MB. It should calculate the special SLA (or call it probability distribution) for the size of 10 documents (this part is one kind of first example, just consider is as we call an API 10 times sequencially, what is the SLA of latency), and do this process for every number of document’s probability. I think this way is a little complex that Shell and AWK are not up to this job.
* 3 Accumulate the probability of result, give the SLA.
  * Sort the step 2’s result with descending order and value with ascending order.
  * Accumulate the probability and output the value once we reach a output flag (0.1 0.2 0 … 0.9999 1)

