# Assignment 9: Web App with RDS

The purpose of this assignment is to demonstrate how to create a web
application that does not store data on its local server instance. In the
cloud, compute and storage are generally separate. Compute is whatever is being
used to run your application, so in our case, VM instances. The two are
separated because most cloud applications need to be able to scale. Compute
needs to be able to come online and go offline as needed and you don't want a
bottleneck from syncing data across instances. This results in compute instances
being treated as disposable resources that simply display or manipulate a remote
data store. Because they could be discarded at any moment, they don't store any
application critical data locally.

For this assignment, you will deploy a Django web application that uses an AWS
RDS instance for its remote data store. You will package the app as a Docker
image and deploy it to an EC2 instance where it will be connected to an RDS
server. Finally, you will perform some basic system administrator duties and
kick-start the database in order to make the website functional. To deploy the
Docker image, you will be reusing the S3 mechanism that you created in
assignment 7. 

Note that the end result can be easily converted to an auto scaling application
by using the machinery you developed in assignment 7. This assignment is focused
on the remote data store however, so an auto scaling/load balanced solution is
not used.

The repo is laid out like so:

```
/
├── app/
├── README.md
└── terraform/
```

`app/` contains the Django application source code and `terraform/` contains the
terraform files.

The app copied from Mozilla's Django tutorial. It is a simple site that acts as
a portal for a library. It keeps track of the book inventory, users, and what
books are checked out and by who. All of this data is stored in a database.

## Building and Packaging the App

`cd` to the app directory and poke around some. `locallibrary/settings.py`
contains the settings for the app. Open it and find the line where `DATABASES`
is set. Replace it with the following to enable dynamic discovery of the RDS DB
you will uses.

```python
if "RDS_DB_NAME" in os.environ:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql_psycopg2",
            "NAME": os.environ["RDS_DB_NAME"],
            "USER": os.environ["RDS_USERNAME"],
            "PASSWORD": os.environ["RDS_PASSWORD"],
            "HOST": os.environ["RDS_HOSTNAME"],
            "PORT": os.environ["RDS_PORT"],
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": os.path.join(BASE_DIR, "db.sqlite3"),
        }
    }
```

This checks for the RDS DB information and falls back to a local SQLite DB if no
information is found. Save and close the file.

A Dockerfile has been provided. Open it and take note of the port that is being
set in the `CMD` statement. The web server that will run in the final docker
containers will run on port 8000. You will need to map that port to the EC2
instance's port 80 when you run the container.

Close the Dockerfile and build the image. Use `-t <TAG>` to give it a tag. You
can look back at previous assignments if you don't remember the command. Next,
save the generated image as a `.tar` file in the **root** of the project repo with
the `docker save -o <filename>.tar` command.


## Terraform

You will add the following components to the terraform code:

* S3 docker image delivery mechanism from assignment 7
* Security groups
* RDS server instance
* EC2 server instance

### S3
`cd` to the `terraform/` directory. Basic `main.tf` and `variables.tf` files are
provided. Open `variables.tf`. Set the `docker_img_tar_file` and
`docker_img_tar` variables to the appropriate values. This is the filename of
the image file you just saved and the tag you used when building the image.
Close the file.

Open `main.tf`. You will find sections for the infrastructure components you
will be adding. In the "S3 Bucket" section copy your S3 code from assignment 7
here. This includes the creation of the S3 bucker and S3 object for the image
file. It should also include the policy, role, attachment, and instance profile
resources. This code will not work without the role and policy files so in the
`terraform/` directory copy over the `roles/` and `policies/` directories from
assignment 7.

### Security Groups

Create two `aws_security_group` instances. One for the RDS instance and one for
your app server. The app server security group should have the standard SSH and
HTTP ingress blocks as well as an egress block for all traffic. The RDS security
group needs an ingress block for port 5432, protocol `tcp`, and, instead of
`cider_blocks`, a `security_groups = [aws_security_group.<server sg>.id]`
statement. It also needs an egress block for all traffic.

### RDS Instance

Create an RDS instance like this:

```hcl
resource "aws_db_instance" "<db resource name>" {
  name                    = "dj_app_db"
  username                = var.db_username
  password                = var.db_password
  port                    = "5432"
  engine                  = "postgres"
  engine_version          = "12"
  instance_class          = "db.t2.micro"
  allocated_storage       = "20"
  storage_encrypted       = false
  vpc_security_group_ids  = [aws_security_group.<rds security group>.id]
  multi_az                = false
  storage_type            = "gp2"
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
}
```

Note the variables for the username and password.

### EC2 Instance

Add an `aws_instance` resource for your app server. Use `var.ami_al2_ecs` for
the AMI and `t2.micro` for the `instance_type`. Set the key like usual. Set the
security group to the app server security group like usual. Add a `depends_on`
list with your `aws_s3_bucket_object.<bucket object name>` and
`aws_db_instance.<db resource name>` so that the instance won't be created until
after the components it depends on.

Next add a `user_data` script like below in order to initialize the server and
spin up the docker container for your app. Note the use of the `--env` flag in
the `docker run` command to pass in the database information. Make sure to set
the port mapping using the port from the Dockerfile earlier.

```hcl
resource "aws_instance" "<server name>" {
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
aws s3 cp s3://${aws_s3_bucket.<s3 bucket name>.id}/${aws_s3_bucket_object.<bucket object name>.id} .

# Load and run image
sudo docker load -i ./${aws_s3_bucket_object.<bucket object name>.id}
sudo docker run -dp 80:<port> \
  --env RDS_DB_NAME=${aws_db_instance.<db instance name>.name} \
  --env RDS_HOSTNAME=${aws_db_instance.<db instance name>.address} \
  --env RDS_PORT=${aws_db_instance.<db instance name>.port} \
  --env RDS_USERNAME=${var.db_username} \
  --env RDS_PASSWORD=${var.db_password} \
  --name ${var.app_container_name} \
  ${var.docker_img_tag}
docker exec ${var.app_container_name} python manage.py collectstatic

# Cleanup
rm awscliv2.zip
rm ${aws_s3_bucket_object.s3_app_image.id}
  EOF
}
```

Note the `docker exec ... python manage.py collectstatic` line. This uses the
exec command in docker to run a command inside the container. The `collectstatic`
command builds the static files for the site and puts them in a single location
for the app to use in the container. You will use the exec command later to
kick-start the database.

### Outputs

Create `outputs.tf` and add two outputs:

```hcl
output "ec2_ip" {
  value = aws_instance.<app server name>.public_ip
}
output "db_host_name" {
  value = aws_db_instance.<db instance name>.address
}
```

These will print the IP address for you EC2 instance and the URL of your
database should you need to debug it or wish to poke around in it. Note that
because of the tunnel you set in the security groups, you can only connect to
the RDS database from the EC2 instance.

### Apply

Run terraform's init and validate functions to initialize and set everything up
and make sure your configuration is valid. Next, set environment variables for
the DB username and password.

Bash:

```sh
export TF_VAR_db_username="<db username>"
export TF_VAR_db_username="<db password>"
```

Powershell:

```powershell
$env:TF_VAR_db_username='<db username>'
$env:TF_VAR_db_password='<db password>'
```

Setting these causes terraform to read in the variable values from the
environment rather than making you type them in every time you run apply (and
oddly enough, destroy, at least for me). 

Finally apply your configuration.

## Kick-Start

Use the output EC2 IP address to ssh into your instance. Check that your
container is running with `docker ps` and get the container name, also. In your
browser, paste in the IP address to go to the site. You should be presented with
an error about the database tables. This is good. It means you need to set up
the database. Using `docker exec` initialize the database:

```sh
docker exec <container name> python manage.py migrate
```

The database should be initialized. Now you need create an admin user account
for your site. This requires your input so you will need an interactive session
inside of your container. Run the following:

```sh
docker exec -it <container name> bash
```

`-it` runs the command you give docker in an interactive setting and the command
given is bash so you should end up in a bash session running inside the
container. Create and admin user with

```sh
python manage.py createsuperuser
```

It will ask you to give a username and password for your new admin account. Once
this is done, you can exit the session with `exit`. You should now have a fully
functional web app complete with a remote database.

## Web Admin

In your browser, refresh the page and you should see a pretty web page now. Go
to `<IP address>/admin` and log in with your new admin account to confirm that
things are working. You can add some entries in the various tables through the
admin page and view them on the main page. All of the data is stored in the RDS
database.


## Deliverables

The deliverables to add, commit, and push are: 

* `app/locallibrary/settings.py`
* `terraform/main.tf`
* `terraform/variables.tf`
* `terraform/outputs.tf`
* `terraform/policies/s3-policy.json`
* `terraform/roles/s3-role.json`
* Any other files you changed

We need to be able to build and run your project so make sure you add any files
you changed.


**Make sure to destroy your infrastructure when you are done.**
