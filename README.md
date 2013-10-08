Hierarchical Scene Analysis (HSA) - Benchmark
---------------------------------------------

This project contains all benchmark code and data used in:

> [Hierarchical Scene Annotation]
> (http://vision.caltech.edu/~mmaire/papers/pdf/seg_annotate_bmvc2013.pdf)  
> Michael Maire, Stella X. Yu, and Pietro Perona  
> British Machine Vision Conference (BMVC), 2013  

It includes the results of evaluating the gPb-UCM algorithm on the Shore
dataset with hierarchical groundtruth, as described in the above paper.

To evaluate your own segmentation algorithm on this benchmark:  
1. Replace the files in `datasets/shore/ucm/` with weighted boundary maps
output by your segmentation algorithm.  
2. Run `build.m` in the `benchmark/correspond/` directory (compiles
boundary correspondence MATLAB mex file).  
3. Run `run_bench_batch.m` with "datasets/shore" as the first
argument.  Generated results will be placed in `datasets/shore/bench/`.  
4. Optionally use `combine_bench.m` to summarize benchmark results.

Code Overview
-------------

MATLAB code within `benchmark/` is organized as follows:  
`bench/eval_boundary.m` - main benchmark function  
`bench/combine_bench.m` - benchmark stats summarization  
`bench/run_bench_batch.m` - script for running benchmark  
`correspond/` - boundary correspondence code  
`mpi/` - tools for distributed benchmark execution  
`render/` - rendering of region tree annotations  
`util/` - utilities for working with region trees and UCMs  
`vis/` - benchmark visualization code  

Shore Dataset Images
--------------------

We are able to redistribute the original images of the Shore dataset free of
charge, but for the purpose of research use only.  To obtain a copy of the
images, please use the following form to submit your request:

https://docs.google.com/forms/d/1CNqyGc23VuIyokwkC7sHyk5YMhtMUrz4HBiaQn4zsis/viewform

If you do not receive a response within one business day, please contact
Michael Maire via email: mmaire@gmail.com.

The benchmark code expects the image .jpg files to reside in:
`datasets/shore/images/`

License
-------

Copyright (C) 2013 Michael Maire <mmaire@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

External Dependencies
---------------------

This project includes code from various external sources:

### BSDS Benchmark Boundary Correspondence Code ###
> Website: http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/segbench/  
> License: GPL  
> Include Location: `benchmark/correspond/`

### Image & Video Matlab Toolbox by Piotr Dollar ###
> Website: http://vision.ucsd.edu/~pdollar/toolbox/doc/index.html  
> License: Simplified BSD  
> Include Location: `benchmark/mpi/toolbox/`
