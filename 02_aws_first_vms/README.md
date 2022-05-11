# Getting Started with AWS
## Account Creation

* Go to https://aws.amazon.com/free/ and create an account. A free account
  gives you access to basic AWS services for free for 12 months. Take a moment
  to consider what email you want to use for this. If you would like to use AWS
  for personal projects later, maybe use your school email for this account.
  That way you could use your personal email to create a new account later.
  * The account name can be anything you like.
  * The email and password you create are your root user credentials. Consider
    storing them in a password manager so as not to lose them.
  * You will need a credit card.
  * After creating the account, sign in as a root user and go to the AWS home
    console.
* AWS splits its service into regions. We will be using the US West 2 region
  (Northwest US) so go to the dropdown in the top right and change the region
  to us-west-2.
* Next you will create an admin account. This is the account that you will use
  for creating infrastructure on AWS. We do this because the root user account
  you created in the last step has super-user privileges over your AWS account.
  This is too much power to have when carrying out regular tasks and we only
  want to use root when we have to. This is very much like a traditional user
  system on personal computers where there is a super-user/admin and regular
  users. Follow the directions here:
  https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html
  for "Creating an administrator IAM user and user group (console)". Note that
  the search bar in the top left is very helpful.
  * At the final screen after creating the admin account there will be a link
    for signing in under that account. Click it and save the "Account ID" that
    is shown. You will need it for signing into this account in the future.
  * I recommend storing these credentials, the account ID, username
    (Administrator, and password, in a password manager as well.
    Sign in as the new admin user. If something went wrong and you need to
    reset the admin password, you can sign in as the root user and reset
    through IAM > Users > Administrator > Security Credentials. Next, go to
    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    and follow the instructions for installing the AWS CLI program. You can use
    your local VM if you choose but it is not required. Windows users may have
    an easier time with the CLI inside of a Linux VM.

## VM Creation

On AWS, VMs are created using the EC2 (Elastic Compute Cloud) service. You will
create two VM instances, one through the web console and one through the CLI.
Console

1. Go to the EC2 service page by searching "EC2" in the AWS search bar. Click
   "Instances" on the left side.
1. Click the orange "Launch Instances" in the top right.
1. Select "Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type". This is
   Amazon’s own flavor of Linux that is optimized for their cloud platform.
1. Select "t2.micro". This is a small VM that is Free Tier eligible.
1. Click "Review and Launch" and then "Launch" on the next screen.
1. A pop up will appear. Select "Create a new key pair" and give the keys a
   name. My pair is "aws_ras01" but you are free to give it any reasonable
   name. This is the ssh key pair you will use to ssh into your new instance.
   * Click the "Download Key Pair" button to download the private key. It is a
     good idea to move the key to the `$HOME/.ssh` directory.
   * Once downloaded, run `chmod 400 /path/to/your_shiney_new_private_key.pem`
     to set the proper file permission on the key.
   * Click "Launch Instance"
1. Click "View Instances" and wait a minute or two for the VM to boot up.
1. Click on the new instance and then click "Connect" in the upper right.
1. Copy the example ssh command that it shows you.
1. Go to your favorite terminal application and paste the command in. Adjust
   the `-i <key path>` option to match where your key is found. The part after
   the @ symbol is the public DNS name for your new instance. You can also use
   the public IP address for your instance which can be viewed in the web
   console.
1. SSH in and run `w >> w.aws1` to create the w.aws1 file
1. Exit by typing exit or control-d.
1. [SCP](https://haydenjames.io/linux-securely-copy-files-using-scp/) the file
   to your local system. You will need to use the `-i` flag to specify your key
   file like with SSH.
1. Make sure to terminate the VM or it will eat into your free hours. You can
   do this by clicking on the VM in the EC2 instances console and then clicking
   "Instance State" > "Terminate instance".

## CLI

Now you will create a VM instance using the command line interface (CLI).

1. Make sure that you are signed into the Administrator account and not root in
   the browser.
2. Go to
   https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds-create
   and follow the instructions for creating an access key pair. Save the key
   pair as it is how you will sign API calls using the CLI program. I use a
   password manager for this as well. If you lose the secret key string, you
   will have to make another.
3. Configure the AWS CLI using the new access key in the terminal. An example
   is shown in the link. Make sure to set the region to us-west-2:
   https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config
4. Go to
   https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#SecurityGroups:
   and select the security group there. A security group is basically a virtual
   firewall that wraps VMs. There should only be one security group at this
   point. Take note of its "Security Group ID”.
5. Next click the VPC ID link to take you to the VPC console. This lists your
   VPCs. Click Subnets on the left and then select any of the subnets that are
   shown in the list. Take note of its "Subnet ID”
6. In the terminal, use the following AWS CLI to create an EC2 VM instance. You
   will need to fill in the missing bits with your appropriate data. The image
   ID is the ID for the operating system that will be installed. Use
   "ami-0ca285d4c2cda3300" which is the latest amazon linux 2 release for the
   US West 2 region. Use the ssh key pair name that you created when creating
   the first AWS VM.
   1. `aws ec2 run-instances --image-id ami-0ca285d4c2cda3300 --count 1
      --instance-type t2.micro --key-name <your ssh key pair name>
      --security-group-ids <your security group ID> --subnet-id <your subnet ID>`
   2. Press q to get out of the prompt that the CLI program places you in.
   3. Note the `InstanceId` in the json data that is printed.
7. After a minute or two run the following to get the public DNS name for the
   VM. The bar or pipe character causes the output of the AWS command to be
   piped into the grep command which searches for `PublicDnsName`.
   1. `aws ec2 describe-instances --instance-ids <Instance ID> | grep PublicDnsName`
8. SSH into the instance using your key from before:
   1. `ssh -i $HOME/.ssh/<your key>.pem ec2-user@<public DNS name>`
   2. (OPTIONAL) If you get an error that says "Connection reset by peer", it
      means that for some reason the security group is interfering with the
      connection. You will need to create a new security group.
      1. Go to the EC2 console and terminate the VM.
      2. Go to the link from step 4 and click "Create security group" using the
         following settings.
         1. Name: something simple
         2. INBOUND
            * type: SSH
            * source: IPv4 anywhere
         3. OUTBOUND
            * leave as is
      3. Repeat steps 6, 7, and 8.
9. Run `w >> w.aws2`. Exit with the exit command.
9. SCP the w.aws2 file to your local machine.
9. Kill the VM using `aws ec2 terminate-instances --instance-ids <instance ID>`

## Submission
**FRED NOTE: normally you would commit and push the files you scp'd from the
servers to the Github classroom repo.**
