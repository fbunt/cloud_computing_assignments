# Serverless and AWS Lambda

**Fred Note: Alden put this together.**

The basis for this assignment is the Terraform tutorial at
https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway.  The
template repository for this assignment is the clone of
https://github.com/hashicorp/learn-terraform-lambda-api-gateway.git, so you
should be all set up to do the tutorial once you change the region from
us-east-1 to us-west-2. 

## Part 1

Do the tutorial up to but not including the 'Create an HTTP API with API
Gateway’ step.  You may need to do "terraform init -upgrade" to get "terraform
init" to work.  And you may need to comment out the main.tf line: 'acl =
"private"’.

Change the function in hello-world/hello.js to a Python function (and change
the file name to myhello.py) and get the functionality of this section of the
tutorial to work.  Some relevant resources are given at the end of the
assignment.

Hint:  I used 'runtime = "python3.8"’.  See a hint below for how to set
'handler = '.

At the end of this section of the tutorial you are asked to do the following
commands:

```sh
aws lambda invoke --region=us-east-1 --function-name=$(terraform output -raw function_name) response.json

cat response.json
```

Modify the first command so it works for you.  Create a file 'part1results.txt’
showing the execution of these commands and their results.

Make a subfolder called "part1" of your repository, and copy the following into
it:

1. Your hello-world/myhello.py file.

2. Your revised main.tf, variables.tf, outputs.tf, and terraform.tfstate files.

3. Your 'part1results.txt’ file.

These are all deliverables.

## Part 2

Do the rest of the tutorial.  Again, you are to get the functionality of the
tutorial to work with your Python Lambda function which will be further
modified.

At the end of the tutorial you asked to do the following command:

```sh
curl "$(terraform output -raw base_url)/hello?Name=Terraform"
```

Include a file part2results.txt showing your command with 'Terraform’ replaced
by '<yourname>’.   Show the results of your command.

Your main repository should include:

1. Your hello-world/myhello.py file.

2. Your revised main.tf, variables.tf, outputs.tf, and terraform.tfstate.backup
   files (since you should have done "terraform destroy’ before I look at your
   repository).

3. Your part2results.txt file.

These are deliverables.

Some useful resources:

https://docs.aws.amazon.com/code-samples/latest/catalog/python-lambda-lambda_handler_basic.py.html

https://docs.aws.amazon.com/lambda/latest/dg/nodejs-handler.html Explains the
nodejs handler in the tutorial.

https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html

Hint:  Here is an excerpt from this file: 

The Lambda function handler name specified at the time that you create a Lambda
function is derived from:

* The name of the file in which the Lambda handler function is located.

* The name of the Python handler function.

A function handler can be any name; however, the default name in the Lambda
console is lambda_function.lambda_handler. This function handler name reflects
the function name (lambda_handler) and the file where the handler code is
stored (lambda_function.py).

You can also look at the documentation for the AWS API gateway service.  I
searched for "aws api gateway lambda python example" and found some websites
that might be useful.
