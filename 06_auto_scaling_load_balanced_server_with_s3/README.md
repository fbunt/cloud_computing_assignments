# Load Balanced Auto-Scaling Website with S3 Content Storage
 
For this assignment you will create a website on AWS that auto-scales and uses
a load balancer to distribute traffic. The website itself will be containerized,
again. You will use Terraform to automate the process of storing the docker
image in an S3 (Simple Storage Service) bucket and deploying it to the
auto-scaling EC2 instances.

First you will create a static web page as a stand-in for an actual web app.
You will package the website in a container image. Then you will use terraform
to create an S3 bucket to store the image file. Finally you will use terraform
to create a group of EC2 instances that are managed by an auto-scaler with
traffic routed through a load-balancer. Through Terraform you will setup the
instances to pull the image from the S3 bucket. In this way you will have
automated the deployment of a "web app" to a scalable and load-balanced
cluster.

## Build the App

In the project repo, you will find the following:

```sh
/
├── app/
│   └── README.md
├── README.md
└── terraform/
    ├── main.tf
    ├── ouputs.tf
    ├── policies/
    │   └── s3-policy.json
    ├── roles/
    │   └── s3-role.json
    └── variables.tf
```

The `app` directory is where you will create the website. `cd` there and follow
the instructions in `app/README.md`. Once you have an `index.html` file and a
Dockerfile, build the docker image containing the website and tag it with
something simple (e.g. my-site). Then save the image to a file in the project
root. This container image will be your "web app". This should remind you of
docker web app assignment. For an actual project, this would be an actual app
but for this assignment, a simple static page will suffice.

```sh
# Inside the app dir
docker build -t <tag> .
docker save -o ../<image file name>.tar <tag>
```

The repo should now look like this:

```sh
/
├── app/
│   ├── Dockerfile
│   ├── index.html
│   └── README.md
├── <image name>.tar
├── README.md
└── terraform/
    └── ...
```

Your "web app" is packaged up in the container image and ready to be deployed.
Now you need to create the infrastructure for it.

## Build the Infrastructure

We want Terraform to automate as much as possible. This will help prevent drift
and reduce the work for us later. `cd` to the `terraform` directory and open
`main.tf` and `variables.tf`. A basic terraform config has been provided in
`main.tf`.

First, change the `docker_img_tar_file` variable to match the name of your
image file you just created. This should be the file name, **NOT** the full
path. Next, change the `owner` variable to an identifier for you. I used my
github username. This variable is used for the owner tag that is applied to all
components through the `provider` block in `main.tf`. It is not critical but a
good idea to not tag everything with the instructor's username. The `owner` and
`environment` variables can be used when working in a group on the same project
to distinguish builds.

In `main.tf`, take note of the sections. You will fill these in with the
appropriate components.

### Security Group

You will only use one security group for this project. In a real project you
would use more fine-grained security groups but one will suffice for this
project. Add a security group with two ingress blocks, one for SSH (port 22) and
one for HTTP (port 80) for all CIDR blocks (0.0.0.0/0). Then add an egress
block for all traffic (ports: 0, protocol: "-1", CIDR: 0.0.0.0/0).

### S3 Bucket

In the "S3 Bucket" section add an `aws_s3_bucket` resource. We want this bucket
to be completely managed by Terraform, so Terraform needs to be able to name it
and destroy it. To this end add only a single argument inside the bucket
resource: `force_destroy = true`. By not providing a bucket name, you force
Terraform to generate a unique name. We don't care what the name is since we
want everyting managed for us.

The bucket is what you will use to store the docker image. Normally you would
push the image up to a container registry like AWS ECR (Elastic Container
Registry), but this will demonstrate the general purpose utility of S3.

Next, add an `aws_s3_bucket_public_access_block` resource with 3 args: `bucket =
aws_s3_bucket.<your bucket>id`, `block_public_acls = true`, and
`block_public_policy = true`. This resource makes your bucket private. You will
give your EC2 instances permissions to access it later.


Next add an `aws_s3_bucket_object` resource that looks like this:

```hcl
resource "aws_s3_bucket_object" "<YOUR BUCKET OBJECT NAME>" {
  bucket = aws_s3_bucket.<BUCKET NAME>.id
  key    = "${var.docker_img_tar_file}"
  source = "../${var.docker_img_tar_file}"

  # This gets the md5 checksum of the image file and checks to see if it has
  # changed since the last apply
  etag = filemd5("../${var.docker_img_tar_file}")
}
```

This resource will upload the app image to the S3 bucket when you do an apply
operation. `filemd5` computes a hash of the app image file to see if it has
changed since the last apply. This allows Terraform to detect drift (changes)
when you update your app image.

The S3 section should look like this:

```hcl
resource "aws_s3_bucket" "<BUCKET NAME>" {
  ...
}
resource "aws_s3_bucket_public_access_block" "<ACCESS BLOCK NAME>" {
  ...
}
resource "aws_s3_bucket_object" "<BUCKET OBJECT NAME>" {
  ...
}
```

Next add the following policies to the S3 section:

```hcl
# S3 access
resource "aws_iam_policy" "ec2_s3_policy" {
  description = "Policy to give s3 permission to ec2"
  policy      = file("policies/s3-policy.json")
}
resource "aws_iam_role" "ec2_s3_role" {
  assume_role_policy = file("roles/s3-role.json")
}
resource "aws_iam_role_policy_attachment" "ec2_s3_role_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  role = aws_iam_role.ec2_s3_role.name
}
```

These are how you give your EC2 instances access to a private bucket. A policy
provides or excludes permissions to perform actions and a role can be attached
to a resource. The code above attaches the policy to the role and then makes all
of it ready to attach to a resource. The policy and role are provided in the
policies and roles directories, respectively. I recommend looking taking a look
at them just to get familiar.


### EC2 Configuration

In the "EC2 Instance Config" section create an `aws_launch_configuration`
resource. This is the similar to the `aws_instance` resource that you are ussed
to when creating EC2 instances, but is used as a template for spinning up EC2
instances for something like an auto-scaling group. You are using a container
for your app, so you will again use the Amazon Linux 2 with ECS AMI. This is
stored in a variable already. Set the following args:

* `image_id`: var.ami_al2_ecs
* `instance_type`: "t2.micro"
* `key_name`: "your_aws_key_name"
* `security_groups`: [aws_security_group.your_sg_name.id]
* `iam_instance_profile`: aws_iam_instance_profile.ec2_s3_profile.name

The last item is how the S3 permissions are attached to the EC2 instances. Next
add the following `user_data` script to the config:

```hcl
resource "aws_launch_configuration" "lc-main" {
  ...
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y unzip

# Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Fetch docker image
aws s3 cp s3://${aws_s3_bucket.your_bucket_name.id}/${aws_s3_bucket_object.your_bucket_object_name.id} .

# Load and run image
docker load -i ./${aws_s3_bucket_object.your_bucket_object_name.id}
docker run -dp 80:80 ${var.docker_img_tag}

# Cleanup
rm awscliv2.zip
rm ${aws_s3_bucket_object.your_bucket_object_name.id}
  EOF

  ...
}
```

This installs the AWS CLI on each instance, pulls the app image from the S3
bucket, loods it into docker and then spins up the container. Because you
attached the S3 permissions to the instances, the AWS CLI program doesn't need
to be configured.

Now add a `depends_on` list to the config, so that Terraform knows to build the
S3 bucket before any EC2 instances can start, and a `lifecyle` block. The
lifecyle block forces Terraform to create a new instance before destroying the
old one.

```hcl
resource "aws_launch_configuration" "lc-main" {
  ...
  depends_on = [
    aws_s3_bucket_object.your_bucket_object_name,
  ]
  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}
```

### Load Balancing

In the "Load Balancing" section create an `aws_lb` with 3 args:

* `load_balancer_type`: "application"
* `security_groups`: same as for the launch configuration
* `subnets`: `data.aws_subnet_ids.default.ids`

The type arg, indicates that the load balancer will be routing application
traffic. The subnets arg tells Terraform what availability zones to use.

Next create an `aws_lb_target_group`. Set `port` to 80, `protocol` to "HTTP",
and `vpc_id` to `data.aws_vpc.default.id`. This tells it to rout HTTP traffic to
a group of EC2 instances within your account's default VPC. Then add a
`health_check` block:

```hcl
resource "aws_lb_target_group" "default-target-group" {
  ...
  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}
```

This is how the load balancer and auto-scaling group find dead/crashed
instances. It will ping the instances and wait for an HTTP 200 response.

Create an `aws_lb_listener` resource. This listens for the specified type of
traffic for the load balancer so it can be routed. Set `load_balancer_arn` to
`aws_lb.your_lb_name.id`, `port` to 80, and `protocol` to "HTTP". Add a
`depends_on` list: `[aws_lb_target_group.your_target_group_name]`, so that
Terraform gets the dependency tree correct. Next add a `default_action` block to
the listener:

```hcl
resource "aws_lb_listener" "your_lb_listener" {
  ...
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
```

This action causes a 404 page to be returned if no instances are up.

Now add an `aws_lb_listener_rule` with `listener_arn` set to
`aws_lb_listener.your_listener.arn`. Then add condition and action blocks:

```hcl
resource "aws_lb_listener_rule" "lblr-default" {
  ...
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_target_group.arn
  }
```

The condition block matches the requested URL path. The site you are building
has all of the site running in one place (in each EC2 instance), so a wildcard
pattern is used. The action block forwards all traffic to the target group of
EC2 instances.


### Auto Scaling

Last component. Add an `aws_autoscaling_group` resource with
`launch_configuration` set to
`aws_launch_configuration.your_launch_config.name`, `vpc_zone_identifier` set to
`data.aws_subnet_ids.default.ids`, `target_group_arns` set to
`[aws_lb_target_group.your_target_group.arn]`, `health_check_type` set to "ELB",
`min_size` set to the min_size variable, `max_size` set to the max_size
variable, and desired_capacity set to the desired_size variable. Finally add a
lifecycle block like you did in the launch configuration.


That's it. You should now be ready to run `terraform apply`. Run `terraform
fmt` and `terraform validate` to make sure everything is set properly. After
building everything, wait a minute or two for the auto-scale instance to spin
up. The `outputs.tf` file causes the final DNS address to be printed to the
screen after building everything. Paste it into your browser and you should see
your `index.html` displayed. You can SSH into your instances to poke around and
check on the docker processes. You can also adjust the min/max and desired size
variables.

## Deliverables

`git add` the following files and push to the repo. With these, we can see if
your infrastructure specifications work. If you make any changes to the policy
or role files, commit them as well.

* `app/Dockerfile`
* `app/index.html`
* `terraform/main.tf`
* `terraform/outputs.tf` (if you edited it)
* `terraform/variables.tf`

