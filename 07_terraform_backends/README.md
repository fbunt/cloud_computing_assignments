# Backends

**Fred Note: Alden put this assignment together.**

This assignment will give you practice in setting up and using a Terraform
remote backend based on AWS S3 buckets for remote state storage and a DynamoDB
table for locking.  The Terraform code for creating the backend S3 bucket and
DynamoDB table is included in the repository for this assignment in the
subdirectory "create-s3-backend".  The Terraform code is based on "Shared
Storage for State Files" page 110 of Brikman's "Up and Running" book (available
from the library) and on
https://www.techcrumble.net/2020/01/how-to-configure-terraform-aws-backend-with-s3-and-dynamodb-table/.

A file "backend.tf" is included in a subdirectory "use-s3-backend".  This file
cannot be included in the subdirectory where you create the backend because you
cannot create a backend and use it in the same folder.  (This is a
chicken-and-egg problem.)  You will include a revised version of this file as
"backend.tf" in the folder where you use the backend.

You are to make some revisions to the repository Terraform code before you
"terraform apply" it.

1. Change the "Owner" tag on the aws_s3_bucket resource to your name.
   Including tags like the ones given is very important to help you and
   collaborators keep track of resources.

2. Change the name of the "folder" from "terraform-aws/" to something more
   informative, such as something including the course and the assignment
   number.

3. Create an "outputs.tf" file so that the name of the S3 bucket and the name
   of the DynamoDB table will be output after the apply.

Then apply your code and record the name of the S3 bucket.

Create a new directory where you will copy the Terraform files from one of your
previous Terraform assignments into this directory.  Copy only the Terraform
files and any README files---do not do a recursive copy.  Copy the
"backend.tf.sav" file from your backend creation folder to your new folder with
the name "backend.tf".  You will need to modify the file to reflect the name of
your S3 bucket.  You might get an error that your security group from previous
assignment already exists.  If so, you can use this previously created security
group in your new folder by including the following with the name of your
security group name substituted for "http-ssh":

```hcl
data "aws_security_group" "http-ssh" {
  name = "http-ssh"
}
```

After making these revisions, validate and apply.  Do the following before you
destroy.

1. Are there terraform.tfstate or terraform.tfstate.backup files in your
   folder?  If so, what is are their sizes? (deliverable)

2. Use the AWS cli to show the objects in the S3 bucket.  You might want to use
   the "--recursive" option.  (deliverable)

3. Use the AWS cli to copy the terraform.tf state file to the file
   "terraform.tfstate.remote" file in your local directory.

4. Use the AWS cli to show the names of the objects in the DynamoDB table.
   (deliverable)

5. Change the "backend.tf" file to one that specifies a "local" backend. Do "tf
   init -migrate-state".  What happened?  You should how have a
   "terraform.tfstate" file.  Copy (don’t move) it to
   "terraform.tfstate.local". Then change back to the S3 backend.tf file.  What
   happened?  (deliverable)

Do a "terraform destroy" in the directory that uses the backend.

Do a "terraform destroy" in the directory that creates the backend.  What steps
did you need to do to delete the S3 bucket?  (deliverable)

Deliverables:

1. A file "aws_cli.txt" with aws cli commands and their results from items 2
   and 3 above.

2. A file "answers.txt" with the answers to the questions from items 1 and 5
   and the steps you used to destroy the S3 bucket.

3. The terraform.tfstate.remote file that you copied from the  S3 bucket to
   your local directory.

4. The terraform.tfstate.local file that you created in item 5.

**This is good advice**
You might want to recreate the backend for use by your team.  If so, I would
suggest that you add a reminder to your calendar at the end of the course to
destroy the backend so you will not be charged when your free-tier runs out.
