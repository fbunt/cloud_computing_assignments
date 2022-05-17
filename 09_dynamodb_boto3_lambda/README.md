# DynamoDB, Boto3, and Lambda

**Fred Note: Alden put this assignment together. I think students had a few
problems with it.**

## DynamoDB

AWS DynamoDB is one of the most popular NoSQL databases.  Some of the features
of DynamoDB are scaling, replication, encryption at rest, point-in-time and
on-demand backup.  With point-in-time backups, you can restore a table to any
point in time during the last 35 days.  All data is automatically replicated
across availability zones.  The default is eventual consistency, but a user can
request strong consistency when reading a table.  Global tables can be used to
keep DynamoDB databases in sync across multiple regions (but multi-region
strong consistency is not offered).

Reference:
https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html

Each DynamoDB is a table which is a collection of items.  Items in DynamoDB
correspond to records (or rows) in a SQL database.  An item is a group of
attributes that is uniquely identifiable among all other items.  An attribute
is a fundamental data element (although nested attributes are possible).
Attributes in DynamoDB correspond to columns in SQL databases.  However, the
possible attributes of an item are not fixed when the table is set
up—attributes of items can differ, and  a new item can have newly defined
attributes.

A table has a partition (hash) key attribute, and table items with the same
partition key are stored together.  If you use only the partition key, then
DynamoDB is a key-value database.  You can also use a second attribute called a
sort (or range) key, and if a sort key is used, table items with the same
partition key are stored ordered by their sort key.  The combination of the
partition key and the sort (range) key (if it exists) is the primary key for
the table, and every item in the table must have a unique primary key.  The
only possible data types for the partition key and sort key are string, number,
or binary.

A table can also have secondary indexes.  A global secondary index has a
partition key and a sort key that can be different from those of the table.  A
local secondary index has the same partition key as the table but a different
sort key.  Using secondary indexes speeds up access to the table.

Reference with examples:
https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html
 
## Boto3

Boto3 (and Botocore) implement the Python SDK for AWS.  Please read
https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html
Assignment

If you search for "hashicorps terraform DynamoDB module" you can find
"Terraform module which creates DynamoDB table on AWS" which is a GitHub
repository.  Clone this repository into a directory on your computer.  Note
that there is a subdirectory "examples/basic/".   Change the region in main.tf
to us-west-2.  You should be able to run (init, validate, plan, apply) the
terraform code to create the DynamoDB table.   Only the attributes that are
used as keys or indexes need to be defined when the table is built.  Other
attributes can be constructed as data is added to the table.

There is a moderate sized table in CSV format at
https://www.stats.govt.nz/assets/Uploads/Household-living-costs-price-indexes/Household-living-costs-price-indexes-December-2021-quarter/Download-data/Household-living-costs-price-indexes-December-2021-quarter-group-facts.csv.
Your objective is to create a DynamoDB table using Terraform that is consistent
with this CSV file, and to write a Boto3 Python program to add a subset of rows
of the CSV table to the DynamoDB table.  Your DynamoDB table should have
partition key "year" and sort key "hlpi".  You should also create a local
secondary index with key "tot_hhs".

The website
https://boto3.amazonaws.com/v1/documentation/api/latest/guide/dynamodb.html has
examples of using Boto3 to do operations on DynamoDB tables.  A suggested
intermediate step is to use Terraform to create the table of the example of
this URL and then check that you can perform the basic operations of the
example in Python.

Deliverables
1. You should have subdirectory of your repository
   "terraform-aws-dynamodb-table/examples/basic/" which should contain your
   terraform code to create the DynamoDB table which is compatible with the
   above CSV file.  The "terraform.tfstate.backup" file should contain the
   state after you have created the table.

2. Write a Boto3 Python function called "add_csv_rows_to_db" which will have
   arguments "db_table", "csv_filename", and "columns" where "columns" is the
   list of rows of the CSV file to add to the db.  Your function should be in a
   subdirectory "boto3" of your repository.  One way to do this is to convert
   the CSV file to JSON format, and then convert the JSON file to a boto3
   function to add items to the DynamoDB table.  A resource to convert a CSV
   file to a JSON file is https://pythonexamples.org/python-csv-to-json/. 

3. Show the function call and the results of running your "add_csv_rows_to_db"
   function to add rows 1 through 29 of the CSV file to your DynamoDB created
   in deliverable 1.  Then show how you would scan the table to find all items
   with "tot_hhs" <= 300000 and "own_prop" >= 30.0, and give your results from
   this scan.  Your results should be in "deliv34.txt" in your "boto3"
   subdirectory

4. Do deliverable 3 with adding the remaining columns of the CSV file to the DB
   and the same scan. Your results should be appended to "deliv34.txt".
