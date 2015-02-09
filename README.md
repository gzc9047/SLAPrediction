# SLAPrediction
## Introduction
Predict SLA for multiple dependencies. This tool can help you predict it SLA before your make design decision and write the real code. Like:

* Your code calls multiple APIs sequentially (or concurrently), you want to estimate the SLA of its latency based on these APIs latency.
* Your App will allow user store many documents in it, you want to estimate the SLA of all documents' size for one user based on: 1) the SLA of how many documents each user own, 2) the SLA of single document's size.

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
`merge_general.sh merge_add.awk SLA_A.txt SLA_B.txt`

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

## Limitation

## Internal detail

