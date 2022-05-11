# Using Terraform to create an AWS VM.
## Part 1

Do the AWS getting started with AWS tutorial at
https://learn.hashicorp.com/collections/terraform/aws-get-started.  Each
section is preceded by a video.  Watching these videos is optional.

Section 1 of the website is "What is Infrastructure as Code with Terraform?".
Read this section.

Section 2 of this website describes installing Terraform.  You should install
Terraform on all systems that you might use to do assignments for this class.
This will probably include your Linux VM and the OS of your PC. You will also
need to install the AWS CLI program on your machine. There is a link in this
section that takes you to AWS's installation instructions.

Do the "Build Infrastructure" and "Change Infrastructure" sections.

Go to the AWS console at
https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2.  You
will need to login.  You should have an IAM user set up (your Admin account
from last assignment), and if so, use this account.  Go to "Instances" and view
your instances.  You should see the instance that you just created.

You can skip the "Destroy Infrastructure" section for now.

Do the "Define Input Variables" section.  Note that when you do "terraform
apply", Terraform does not need to destroy and create a new instance.  It can
determine whether your proposed changes require a new instance.  After you do
the ‘terraform apply -var "instance_name=YetAnotherName"’ step, check your
instances using the AWS console again, and note that your instance shows up
with the new name.

After you have completed the above, edit the "variables.tf" file to delete or
comment out the line: `default     = "ExampleAppServerInstance"`.  The "#"
character can be used as a comment symbol.  Redo the "terraform apply" step
(without the -var option).  You should be asked for the instance name when you
do the apply.  Supply something that includes your name.   Did Terraform need
to recreate the instance? Look at your instances in the console as in the
previous step.  Do you see your new instance name? 

## Part 2
A limitation of the Linux VM created above is that ssh access to the VM is not
enabled.  In order to enable ssh access, a security group resource needs to be
added to the main.tf file.  Following is a  Terraform specification of an
appropriate AWS security group.  Add it as a top-level block to your main.tf
file.

```hcl
resource "aws_security_group" "enable_ssh" {
    name = "enable_ssh"
    ingress {
        from_port   = 22
        to_port     =  22
        protocol   = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

You will also need to specify the name of the AWS key that you created for
assignment 3 in your main.tf file.  My key name is "aws_rsa01", so I added the
line `key_name  = "aws_rsa01"` after the line `instance_type = "t2.micro"`. 

And you will need to include a reference to the above security group in
resource description.  Just after your "key_name" line, include the line

```hcl
vpc_security_group_ids = [aws_security_group.enable_ssh.id]
```

I suggest running `terraform fmt` and `terraform validate` from the command
line in the same directory after editing your main.tf file.

Run `terraform apply`.

Now you can login to this instance with:

```sh
ssh -i aws_rsa01.pem ubuntu@35.162.175.27
```

where "aws_rsa01" is replaced by your key name and 35.162.175.27 is replaced by
the public IP of created instance.  As in assignment 2, create a file "wtf.txt"
that captures the output of the "w" command.  Append to this file as a new line
the public IP of this instance which you can see using the Ubuntu command
"ifconfig".  Then scp this file back to your PC for submission. 

Go to the console page that shows your instances, and stop this instance.  Then
restart the instance.  It can take a while to initialize, so wait until the
console shows the instance as "running".  Check whether the public IP of your
instance has changed.  Login to your instance again, and see if the wtf.txt
file is still there.  If so, append the public IP address of your instance as
another line.  As in assignment 3, scp this file back to your PC as a
deliverable.

Do "terraform destroy" to terminate your instance.

Deliverable 1:  Create a file "tfproviders.txt" that gives the output of the
"terraform providers" command on the system that you are using to do this
assignment. 

Deliverable 2:  The file wtf.txt described above.

Remember that you need to add, commit, and push your deliverable files.
