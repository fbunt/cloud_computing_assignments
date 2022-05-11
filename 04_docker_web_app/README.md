# Docker, AWS, and Terraform

For this assignment you are going to use Docker to create a container image of
a web app, upload it to an EC2 instance created using terraform and run the app
with a database that persists between VM reboots.

## Installing Docker

You are free to carry out the local docker part of this assignment on your main
OS rather than in a VM. There is no need to run this inside a VM on your
machine. **Note that Docker requires WSL2 on Windows.**

1. Go to the [Docker Install page](https://docs.docker.com/get-docker/) and
   select your operating system. This should be straight forward for Mac and
   Windows users. Let us know if you run into any issues though.
2. For Linux users, select the appropriate distribution and follow the install
   directions.
    * If you are running Arch or Manjaro, you can install Docker using pacman.
      Follow the guide
      [HERE](https://linuxconfig.org/manjaro-linux-docker-installation).
3. Again for linux users, once you have Docker installed, follow the
   [instructions here](https://docs.docker.com/engine/install/linux-postinstall/)
   to enable using Docker without needing sudo. **You may need to log out and
   back in for changes to take affect.**


## The App

The app you will be using has been shamelessly copied from Docker's
getting-started tutorial. It is very simple TODO app but that is perfect for
our needs. We are more interested in the infrastructure than what the app is
doing for now. The app uses a SQLite3 database file for persisting data. We
will place the database in a docker volume so that the app can persist data
outside of the container.

1. Decompress the `app.tar.gz` file included in this repo. You can do this using tar:

    ```sh
    tar -xvf app.tar.gz
    ```

2. `cd` to the app directory, open the `Dockerfile`, and inspect the contents.
   Docker app images work by taking a base image and then adding further layers
   on top until the minimum necessary working environment for the app has been
   created. The app you are working with is a Node javascript app so it needs
   to have Node installed. We could do this ourselves in the Dockerfile but me
   might miss something so we will use a pre-built image available on
   Dockerhub. The image we are using installs Node on top of an Alpine Linux
   operating system image. Alpine is a very lightweight Linux distro. The parts
   of the Dockerfile are explained below.
    * `FROM`: this specifies the image we are layering our app on top of.
    * `WORKDIR`: This sets the working dir for the app. If it doesn't exist, it
      is created. After this command is used, you can use `.` to refer to it in
      subsequent commands.
    * `COPY`: This copies a local file into the image. Here, it is copying
      files into `/app` in the image.
    * `RUN`: This runs a shell command inside the image when it is being built.
      Here it is installing the node dependencies needed by the app, as
      specified in `package.json`.
    * `COPY . .`: This copies all files from the present dir on you local
      computer (`app`) to the image's working dir (`/app`).
    * `CMD`: This is the command to be run when the image is started along with
      its arguments.
3. In order to persist the web app's data between container restarts, we need
   to set up a storage location that is persistent. We can do this with a
   volume. A volume is another name for a drive or large storage partition.
   Docker provides docker volumes to persist data. You will use a docker volume
   and save the app's data to a database on that volume.
   A docker volume is simply a directory on the host OS that docker manages and
   that it can mount inside a running container like a hard drive. Inside the
   container, it looks like any other directory so the app can read and write
   data to it at will. The app checks the environment variable `SQLITE_DB_LOCATION`
   for the database location. It will create a new database in the working
   directory if `SQLITE_DB_LOCATION` is not set. You can to set the environment
   variable inside of the Dockerfile.
   Inside the Dockerfile, set the database location to
   `/data/todo.db` using the `ENV` command Just after `WORKDIR`. The
   `ENV` command format looks like: `ENV <VARIABLE_NAME>=<VALUE>`.
4. Build the image using docker inside the app dir:

    ```sh
    docker build -t todo-app .
    ```

5. Verify that the image built successfully by listing the images that docker has ready to go:

    ```sh
    docker images
    ```

6. Test the app by running it locally. The app uses port 3000 inside of the
   container so you need to map that to a local port on your machine. You do
   this with `-p <local port>:<container port>`. You also want the container to
   run in the background so specify the `-d` flag for daemon. In Linux/Unix,
   a program that runs in the background is a called a daemon.

    ```sh
    docker run -d -p 3000:3000 todo-app
    ```
 
7. Open `localhost:3000` in your browser to view the app. You haven't added a
   volume yet so nothing from this session will be saved between restarts if
   you add items to the TODO list.
8. List the running containers with `docker ps` and then kill the container using the ID shown.

    ```sh
    docker rm -f <container ID>
    ```

9. (Optional) If you want to test the app with a volume on your local machine, create a volume:

    ```sh
    docker volume create todo-app-vol
    ```

    Run again with the `-v` flag to mount the volume:

    ```sh
    docker run -d -p 3000:3000 -v todo-app-vol:/data todo-app
    ```

    Go to the local URL again and add some entries. Kill the container and
    remove it again (step 8), run again and refresh the web page. The entries
    should be there again. Repeat step 8.

10. The app is ready to ship. Save it to a file in the project root directory
    and compress it for travel. If you are using PowerShell, you don't have compress.

    ```sh
    docker save -o ../app-img.tar todo-app
    cd ..
    gzip app-img.tar
    ```


## The AWS EC2 Instance

You will use terraform to launch an EC2 instance on AWS. AWS provides an AMI
with docker already installed, so you will use that. This is an Amazon Linux 2
AMI so the username is `ec2-user`. The terraform files will live in the
`/terraform` directory where `/` is the project root directory. A `main.tf`
file with some basics is provided there.

We don't want your instance to trust anyone so you will add a security group
that only allows SSH and http access. At the moment there is no reason for
anything on the server to send messages out to the internet of its own accord
so there will be no egress rule in your security group. This is fine since
incoming requests can still reach the server and the security group will let
responses to those requests through.

Docker is already installed in the AMI you will be using so you won't need to
install it again. You will need to create our database volume, however. This can be
done with terraform in the provisioning stage. Provisioning is the process of
allocating and setting up a server or infrastructure.

1. `cd` to the terraform directory and open `main.tf`. The basic starter blocks
   are already present.
2. Add a variable for the AMI to `main.tf`.

    ```hcl
    # Variables
    variable "server-ami" {
      description = "AMI to use for server"
      type        = string
      # This is the AMI for Amazon Linux 2 with docker installed
      default     = "ami-0b250f625dc7f2bc9"
    }
    ```
3. Add a security group resource and name it. The documentation for an AWS
   security group can be found
   [HERE](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group).

    ```hcl
    resource "aws_security_group" "<SG NAME>" {
      ...
    }
    ```

4. In the security group add an ingress block that allows SSH access. SSH uses
   port 22 and the TCP protocol. It should allow all IPs as well.
   * `protocol`: 'tcp'
   * `from_port`: 22
   * `to_port`: 22
   * `cidr_blocks`: `["0.0.0.0/0"]`
5. Add another ingress block for HTTP traffic. HTTP uses port 80 and TCP.
   * `protocol`: 'tcp'
   * `from_port`: 80
   * `to_port`: 80
   * `cidr_blocks`: `["0.0.0.0/0"]`
6. Add an `aws_instance` resource. The documentation for an AWS instane is
   [HERE](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance).

    ```hcl
    resource "aws_instance" "<SERVER NAME>" {
      ami           = var.server-ami
      instance_type = "t2.micro" key_name = "<SSH KEY NAME>"
      vpc_security_group_ids = [aws_security_group.<SG NAME>.id]

      tags = {
        Name = "app-server"
      }
    }
    ```

7. Create the volume using a `user_data` field in the `aws_instance` resource:

    ```hcl
    resource "aws_instance" "<SERVER NAME>" {
      ...
      user_data = <<EOF
    #!/bin/bash
    docker volume create todo-app-vol
      EOF
      ...
    }
    ```

   This essentially runs everything between the EOF markers as a bash script on
   the server. `<<EOF` is a way in shell scripts to say "read the following
   until another EOF marker is seen." EOF stands for end of file.
8. Add an output block to `main.tf` at the bottom of the file that will print
   the public IP address of the server after terraform builds it.

    ```hcl
    # Outputs
    output "server-ip" {
      value = aws_instance.<SERVER NAME>.public_ip
    }
    ```
9. Run `terraform fmt` to clean up the file, `terraform init` to initialize,
   and `terraform validate` to make sure everything checks out.
10. Run `terraform apply` to create the server.


## Running the App
The server should now be running. 

1. `cd` back to the project root directory.
2. Use the public IP address that terraform printed to scp your app image to
   the server.

    ```sh
    scp -i /path/to/aws_key.pem app-img.tar.gz ec2-user@<SERVER IP>:/home/ec2-user/
    ```

3. ssh into the server and double check that the volume was created:

    ```sh
    ssh -i /path/to/aws_key.pem ec2-user@<SERVER IP>
    docker volume ls
    ```

4. Unzip the image and load it into docker:

    ```sh
    gunzip app-img.tar.gz
    docker load -i app-img.ta
    ```

5. Start the app. Use the `--restart=always` flag to set the container to
   restart when the server restarts and map to port 80 for HTTP traffic to get
   through. Also use `-v` to mount the data volume.

    ```sh
    docker run -d -p 80:3000 --restart=always -v todo-app-vol:/data todo-app
    ```

6. Point your browser to the public IP of your server and verify that the app is working.
7. (Optional) Restart your instance through the AWS web console to check that
   the container and its data persist. **You will need to get the new IP
   address from the console.**
8. In the ssh session on your server, run the following and close the ssh session.

    ```sh
    history > server.out; docker images >> server.out; docker ps >> server.out; cat /etc/os-release >> server.out;
    ```

9. scp the `server.out` file to the project root of your local machine:

    ```sh
    scp -i /path/to/aws_key.pem ec2-user@<SERVER IP>:/home/ec2-user/server.out ..
    ```

10. Run `terraform destroy` to tear down the server.
11. In the root directory of the repo run 

    ```sh
    git add server.out app-img.tar.gz app/Dockerfile terraform
    ```

12. Commit the changes and push them to the Github Classroom repo.
