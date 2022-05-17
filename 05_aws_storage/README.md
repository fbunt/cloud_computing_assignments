# AWS EBS and S3 with Terraform

**Fred Note: Alden put this assignment together. I seem to recall students
having issues with this assignment.**

## Part 1
Follow the steps in
https://networknuts.net/attaching-ebs-volume-ec2-instance-using-terraform/.
Read the 4 benefits of using EBS volumes.  What are the two types of EBS
volumes?

Change the availability zone to us-west-2a.  (Note that this is the region name
followed by "a".)  Note that the device_name for the volume attachment is
limited to a few options: "/dev/sdd" worked for me.

The key name in the example is "aws4" and this is set in the "variables.tf"
file.  Add another variable to set the availability zone.

The public IP address is included in the "outputs.tf" file.  Add the
availability zone to the "outputs.tf" file.

Your created EBS volume does not contain partitions or a file system.  The
website
https://networknuts.net/creating-filesystem-on-ebs-volume-to-store-data/ (not
assigned) gives the steps to create a partition and a file system on that
partition, and to mount the file system.  I suggest you look at the website to
an idea of how this is done. 

Deliverables:

1. Your main.tf, variables.tf, and outputs.tf files which should be in your
   repository.

2. Your "terraform.tfstate" file.  Note that if you destroy the resources, your
   "terraform.tfstate" file is copied to "terraform.tfstate.backup" and the new
   "terraform.tfstate" no longer contains   information about the resource.  I
   want the version before the destroy operation.

3. Use ssh to login to your EC2 instance.  If the user "ec2-user" doesn’t work,
   try "ubuntu".  Do the "sudo fdisk -l" command with output redirected to a
   file called "fdisk.txt".  scp this file back to your local system.   You
   should see 4 small volumes with "loop" in their name, and 2 more volumes.
   Which of these is the EBS volume that you just created, and which is the
   volume that comes with the EC2 instance?  How can you tell?  Append your
   answer to the end of your "fdisk.txt" file.

## Part 2

Start with the file S3_demo/main.tf which is in your repository.  Change the
names "umcs-bucket" to something based on your name, and change the comments in
your code to match.  Do terraform init/plan/apply to create the bucket.

The website https://www.thegeekstuff.com/2019/04/aws-s3-cli-examples/ shows
many examples of how to access S3 buckets from the command line.  Create a file
<yourname>.txt, and copy it to your bucket.  Then do the "ls" command to show
the file in your bucket.

The bucket you created has versioning enabled.  This makes it hard to delete
files because when you to the "rm" command, it saves the older version.  This
also applies to the "terraform destroy" command.  Your challenge is to figure
out how to remove all files including versions so that you can delete the
bucket or to the "terraform destroy" command.

Deliverables:

1. Your main.tf, variables.tf, and outputs.tf files which should be in your
   repository.

2. Your terraform.tfstate and terraform.tfstate.backup files after you
   successfully destroy your bucket.

3. A file showing your AWS CLI "ls" command to show your file in the bucket,
   and the results of doing this command.

4. A file "delete_versions.txt" which describes how you were able to delete or
   destroy the bucket.
