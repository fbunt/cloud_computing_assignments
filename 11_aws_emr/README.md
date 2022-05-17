# Monte Carlo Pi Calculation using EMR

Pi is the ratio of a circle's circumference to its diameter. Unfortunately it
is an irrational number which means it cannot be expressed using a fraction.
This also means that it has an infinite number of digits when expressed as a
decimal. Because of its importance in so many fields and the unlimited high
score potential, calculating digits of Pi has become a favorite target for
programmers. The current world record is around 62.8 **trillion** digits set
using [y-cruncher](http://www.numberworld.org/y-cruncher/). Incidentally, the
author of y-cruncher also holds the record for the most upvoted [answer of
all time](https://stackoverflow.com/questions/11227809/why-is-processing-a-sorted-array-faster-than-processing-an-unsorted-array)
on stackoverflow. I recommend checking it out some time as it's a good read and
a nice intro to branch prediction with some compiler optimization sprinkled in.

Anyway. For this assignment you will be calculating Pi using a Monte Carlo (MC)
method that can easily take advantage of distributed systems. For the
distributed system, you will use AWS EMR (Elastic Map Reduce) which Alden
covered in class a while ago. If you aren't familiar with the term, Monte Carlo
is a fancy way of saying calculate something using random numbers.

The method you will use to calculate Pi is a classic. It uses the ratio of
areas between a circle and a square that perfectly contains it. The area of a
circle is given by ``πr^2``. The area of the square that just contains the
circle (i.e. it has sides of length ``2r``) is then ``4r^2``. The ratio of the
areas is ``πr^2 / 4r^2 = π/4``. If you were to randomly throw darts at the
square with the circle inscribed inside, the number of darts that land within
the circle divided by the total number of darts thrown would approximate that
ratio of ``π/4``. The more darts thrown, the better the approximation. This is
where random numbers come in. You can sample a function that uses random
numbers to generate a point in the square and return whether the point 'hit'
the circle or not. The more you sample this function, the better your
approximation will get. Your estimate of Pi is then ``4 * hits /
total_samples``.

EMR works by pushing data to nodes, mapping a function to that data on each
node and then applying a reduction to the results in order to obtain a final
result. The MC method described above can easily fit into this paradigm. The
data pushed to each node would be the number of samples to take, the function
is the sample function and the reduction is the addition operation. That is, on
each node, you sample the function some number of times, add the results, then
add the result(s) from the other nodes and you get the total number of hits.
From there, you can calculate an estimate of ``π``.

## PySpark

The easiest way to do work on an EMR cluster is with Python and PySpark.
PySpark is a set of Python bindings for Spark, which you may remember Alden
covering in class. To use PySpark you first obtain a `SparkSession` and then
use it to map data to nodes and reduce the results. The documentation for
PySpark [can be found here](https://spark.apache.org/docs/latest/api/python/getting_started/index.html).
Remember that API reference docs are your best friend, followed closely by the
actual source code.

## The Assignment

For this assignment, you will spin up an EMR cluster and create a Jupyter
notebook on it to calculate Pi. Once you have that bugs worked out, you will
then create a script that does the same thing but runs without user input on
the cluster. Both of these will write the results to an S3 bucket.

## Create S3 Bucket

Navigate to the S3 console on AWS. Make sure that you set your region to
`us-west-2` like usual. Create a bucket with private access and a unique name.
For example, I have been naming my buckets `com.fbunt.<task>`. Objects in that
bucket can then be referenced like so: `s3://com.fbunt.<task>/somefile.sh`

## Building an EMR Cluster

You will construct a cluster of one master node and some number of worker
nodes. The master node is where you run the notebook or scripts. PySpark then
delegates work to the nodes for you.

* Navigate to the EMR console on AWS and click 'Create Cluster'. 
* By default, you can't run a notebook on a cluster so click 'Go to advanced
  options'. **Note that anything you configure before going to the advanced
  options will be lost like the cluster name.**
* Select EMR 6.5.0
* Check the boxes for:
  - Hadoop
  - Hive
  - JuypyterEnterpriseGateway
  - Spark
  - Livy
  - Pig
* Click next
* This screen allows you to select the number of nodes or 'Cores' in your
  cluster. The default is 2 but you can add more if you want. Just be aware
  that they cost money and more nodes mean much longer spin up times. Do not
  add any 'Task' nodes. **Be careful if you decide to change the instance type.
  Some of the types are not available in `us-west-2` and others are too
  limited in resources.**
* Click next
* This screen is where you can add custom scripts for initializing the nodes.
  For this assignment, you won't need that however. Name your cluster and click
  next.
* Select a key pair to use. You won't need it but it's nice to have the option.
* Click create cluster
* Wait until the cluster's state reads 'Waiting' or 'Running'. Spinning up can
  take a few minutes.

## Create a Jupyter Notebook on the Cluster

On the left side of the EMR console select Notebooks. Name the notebook, select
your newly minted cluster and create the notebook. This will drop you into a
detail view of the notebook. Wait for you cluster to reach the 'Waiting' or
'Running' state before clicking 'Open in JupyterLab'. Once ready, click it and
it will drop you into a JupyterLab tab. Select PySpark under Notebook. This
will drop you into a notebook with a PySpark kernel. Kernel is the word Jupyter
uses for the shell that will run your code. In this case a PySpark enabled
Python shell will be used. You can run a cell by hitting shift-return while
your cursor is in it.

### Calculate Pi

In the first cell import PySpark:

```python
import pyspark
```

This will cause the kernel to initialize a `SparkSession` that you can interact
with using the variable `spark`. Next add the imports you will need:

```python
from random import random
from operator import add
import numpy as np
```

Next add the sample function:

```python
def sample(_):
    x = random() * 2 - 1
    y = random() * 2 - 1
    return 1 if x ** 2 + y ** 2 < 1 else 0
```

This generates a random point within a box centered on the origin with a size
of 2. It then checks if the point 'hit' the circle or not. It returns 1 for
hits and 0 for misses. It takes an argument that is ignored (given the name
`_`). This is because Spark will provide the iteration number to the function
but you don't need it for the sample calculation.

Now add the main function for calculating pi:

```python
def calculate_pi(partitions, samples_per, output_uri=None):
    """
    Calculates pi by testing a large number of random numbers against a unit circle
    inscribed inside a square. The trials are partitioned so they can be run in
    parallel on cluster instances.

    Parameters
    ----------
    partitions : int
        The number of partitions to use for calculations. The partitions are
        distributed across the nodes. 13 seems to work well.
    samples_per : int
        The number of samples to run on each partition. The total samples
        will be ``partitions * samples_per``.
    output_uri : str, optional
        The URI where the output is written, like an Amazon S3
        bucket, such as 's3://example-bucket/pi-calc'. Default is None
        which does nothing.
        
    Returns
    -------
    pyspark.sql.DataFrame
        A dataframe containing the reduced stats for the pi calculation.
        This is a single row dataframe containing the number of samples,
        the number landing inside the circle, and the calculated value of
        pi.
        
    """
    total_samples = samples_per * partitions
    hits = (
        spark.sparkContext.parallelize(range(total_samples), partitions)
        .map(sample)
        .reduce(add)
    )
    pi = 4.0 * hits / total_samples
    df = spark.createDataFrame(
        [(total_samples, hits, pi)], ["samples", "hits", "pi"]
    )
    if output_uri is not None:
        df.write.mode("overwrite").json(output_uri)
    return df
```

Look over this code carefully. The function takes the number of partitions, the
number of samples to run on each node, and an optional S3 URI. The partitions
are the number of processes to distribute across your worker nodes in the
cluster. It looks like you can run around 12 partitions per node comfortably.
The URI is optional so you can play around with the function before actually
saving a result. It first calculates the total number of samples. Then it
distributes them across the nodes/partitions and maps the sample function. Next
it reduces the results using the addition operator. It then calculates pi with
the results and creates a `DataFrame`. If a URI is provided, it saves the data
as a CSV. Finally it returns the `DataFrame`.

To run the code you can add a cell like this:

```python
df = calculate_pi(2, 100_000, None)
row = df.first()
total, hits, pi_est = row

# Or with a URI
calculate_pi(2, 100_000_000, "s3://<bucket-name>/pi-calc-notebook")
```

You can compare to numpy's Pi value like so:

```python
print(f"Diff: {np.abs(np.pi - pi_est):.10e}")
# or simply
print(np.pi - pi_est)
```

Experiment with different samples per node. Based on my experimentation,
`100_000_000` is probably as high as you want to go (1_000_000_000 took 30
minutes for me). You can experiment with the number of nodes in your cluster
though. This will increase the number of samples you can run in a given amount
of time.


### Save Results

Run the `calculate_pi` function with a valid URI pointing to your bucket. Spark
is peculiar in that it creates a folder using your URI and then writes 3 files.
Inside the folder, it creates a file named '_SUCCESS' and two files of the type
specified in the write operation. The code above uses the `.json` method so two
JSON files will be written. They have generated names and the first is empty
while the second will contain the actual payload. Download the resulting
payload file from your bucket to this repo. Save the notebook and download it
to this repo as well.

## Run a Script on the Cluster

On your local computer open a python script and copy in the following template:

```python
from random import random
from operator import add
import numpy as np

from pyspark.sql import SparkSession


# Create SparkSession instance
spark = SparkSession.builder.appName("Pi-Calc").getOrCreate()

# Add code from notebook below
```

Then add the code from the notebook (`sample()`, `calculate_pi()`, and a call
to `calculate_pi`). This script should also save a dataframe to your S3 bucket
using the `calculate_pi` function. Make sure to change the file name so that it
writes a file that is separate from the file written by your notebook. Upload
the script to your S3 bucket.

Now, follow these steps to run the script on your cluster.

* Go to the EMR console and click on your cluster.
* Go to the 'Steps' tab and click 'Add Step'.
* Select 'Spark Application' for Step Type.
* Click the folder to the right of 'Application Location' and select your
  script.
* Make sure that 'Action on failure' is set to continue. This keeps it running
  in case your script fails.
* Finally, click 'Add'.

Your script will get queued up and begin running shortly. Keep refreshing to
follow the status. If the script fails, click 'View Logs' and check the stderr
file. It is actually very useful. Note that anything printed to stdout in the
script will be hoovered up into the stdout log file.

Once your script runs successfully, go to your S3 bucket. You should find a
new folder that matches the URI you provided. Download the payload file to the
repo.


## Cleanup

**Make sure that you have downloaded the notebook and output files before
continuing.**

In the EMR console, navigate to your cluster and 'Terminate' it. This will
destroy the cluster and prevent you from incurring further charges. You can
'Delete' the notebook as well but you can also leave it and attach it to
another cluster later. Just make sure to shutdown the notebook and close out of
your active session.

In the S3 console, you will find two buckets that were created for log files.
You can delete these if you like. Personally, I like to keep things tidy so I
deleted mine. If I was running serious jobs, however, I would keep these
because EMR actually produces very useful logs files.

# Deliverables

* The Jupyter notebook from your PySpark session
* The output payload file from your notebook's Pi calculation
* Your python script that you added as a step on your cluster
* The output payload file from your script's Pi calculation

# Final Thoughts

This method of calculating Pi turns out to be extremely inefficient and prone
to fluctuations thanks to its random nature. Using 4 worker nodes and
1,000,000,000 samples per node, I still only got 5 decimal places of accuracy.
There are much better ways of calculating Pi, but I hope it demonstrated how
the map-reduce paradigm works.
