# Kubernetes (k8s)

In this assignment, you will go through the process of building up a web app on
a running local k8s cluster. The app is a simple guestbook page that logs
messages from guests. Its frontend is a simple page that takes messages and
displays them. The backend data-store is a Redis database. If you aren't
familiar with it, Redis is a distributed, in-memory, key-store database. You
will then add a second site that runs in parallel to the first one, on the same
cluster.

## K8s Theory
If you are not familiar with it, k8s is the canonical abbreviation of
Kubernetes. The 8 represents the 8 characters in between k and s.

K8s works by taking a specification and applying it to a cluster similar to how
Terraform applies a specification for cloud infrastructure. A big difference is
that after applying the specification, k8s then continually works to maintain
that specification. It does this as nodes crash and go offline and come online
again, as application containers fail and need to be restarted, and as app
components need to be scaled up and down.

The k8s conceptual model is based on objects. The cluster admin supplies k8s
with a specification of k8s objects. These k8s objects are "records of intent"
that k8s then works to maintain. There are a few ways to supply these objects
to k8s but the easiest is through YAML files. YAML is similar to JSON and is
in fact a superset of the JSON specification with added syntax and extensions
like comments.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

The above snippet is an example of a k8s object specification for a deployment
of nginx containers. The left most fields shown above (`apiVersion`, `kind`,
`metadata`, and `spec`) are required. `apiVersion` gives the k8s API version
which should always be `apps/v1` for deployments and `v1` for services. `kind`
gives the object type. `metadata` allows you to set the object name, UID, etc.

Under `spec`, `selector` is used to find copies of the object that are already
running. `replicas` sets the number of redundant copies. If k8s finds that
there are not enough replicas running (searching through its managed objects
using the selector), it spins up more. In the example above, the selector
matches the `app: nginx` label under `spec.template.metadata.labels`. The
labels for an object are a set of key-value pairs. They can be anything you
want as long as you are consistent between parts of the spec file or your other
files. They are like tags in AWS. `template` gives a template for the pod that
will be created. `selector` and `template` are required. The `spec` field in
the template gives the specification for the pod. In this case the pod has a
container running nginx 1.14.2 with port 80 exposed for incoming traffic.

A file like above is applied to a cluster using the `kubectl` command-line
tool like so:

```sh
kubectl apply -f filename.yaml
```

Below are some documentation links for object specification:

* [Understanding Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
* [StatefulSet AKA the contents of a spec file](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/stateful-set-v1/#StatefulSetSpec)


The central brain of a k8s cluster is the Control Plane (CP) where plane refers
to a plane of existence. The CP controls worker nodes in the cluster. The nodes
then run pods which are wrappers around one or more containers. Pods can be
grouped and scaled. A group of pods is a deployment. In order to expose pods
and their containers to traffic from the rest of the cluster or from internet
traffic, k8s provides the Service object. A service provides groups of pods
with IP addresses and a DNS name. It can also load-balance traffic to
the pods. Services are how you expose your application to the web. Below is an
example of a YAML specification file for a service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
```

This service matches pods with the `app=MyApp` label takes traffic on port 80
and routs it to port 9376 on the pods. If `targetPort` is not set, it defaults
to the same value as `port`. The documentation for creating a service is
[here](https://kubernetes.io/docs/concepts/services-networking/service/).
**NOTE: the service apiVersion must be v1 instead of apps/v1**

## Setup
For this assignment, you will need to install two components: kubectl and
minikube. If it isn't already installed, you will also need to install docker.

### kubectl
kubectl is the command-line tool for interacting with k8s clusters. You can
find the documentation for it here:
[https://kubernetes.io/docs/reference/kubectl/](https://kubernetes.io/docs/reference/kubectl/)
#### Install
Go to the following link and follow the instructions on the appropriate page
for your operating system.
[https://kubernetes.io/releases/download/](https://kubernetes.io/releases/download/)


### minikube
minikube is a tool that spins up a local k8s cluster for you to experiment
with. The cluster it creates has a single node that runs both the control plane
and the worker pods. minikube spins this up in the background on your
local system.
### Install
Follow the instructions at the following link to install minikube
[https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/).
You don't need to go past part 1.

### Docker
You can skip this if docker is already installed. minikube needs an engine to
run the k8s cluster on and docker is the easiest to get going.
#### Install
Install docker by following the instructions here:
[https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/). You
may need to reboot after. If you are on linux, you can follow the [post-install
steps](https://docs.docker.com/engine/install/linux-postinstall/) to avoid
this.

## The App
As stated above, the app is a simple guestbook that logs visitor messages. It
is made up of a user-visible frontend and a data-store backend. The frontend
and backend are divided into separate containers with the backend being further
subdivided into a leader and its worker replicas. The structure is like so:

* Scalable frontend
* Data-store backend leader
    * Data store replica
    * Data store replica
    * ...


## Building and Deploying the App
### Step 1: Start Your Cluster
Run the following to start a local k8s cluster with minikube:

```sh
minikube start
```

minikube sets up the cluster so that kubectl will automatically detect it.

If, at any point, you want to start over, you can run `minikube delete` to
destroy the cluster. You can then start the cluster again with a blank state
using the above command.

To delete all services and all deployments:

```sh
kubectl delete service --all
kubectl delete deployment --all
```

### Step 2: Run Through Tutorial
Go to the page for [k8s' guestbook
example](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/).
The files used in the tutorial have been copied into the `guestbook/` directory
in this repo. Run through the tutorial with one change. **Instead of using the
links to in  the `kubectl apply` commands, substitute the links with the paths
to the files in `guestbook/`. Also, ignore the `LoadBalancer` bit toward the
end.** Not that the `kubectl port-forward` command in the tutorial will block
block while it routes traffic.

### Step 3: Reset
Once you have finished the tutorial, delete everything on the cluster or
restart it through minikube. Then, **open another terminal window** and run the
following:

```sh
minikube tunnel
```

This will create a tunnel to the cluster that allows you to connect to it
without running the port forwarding through kubectl. It will map all ports on
`localhost` to the cluster. This command will block while it does its work,
which is why you needed to open a new terminal. Leave this running off to the
side. If you restart the cluster, you will need to restart the tunnel.

Apply all of the files again. With the tunnel running, you can visit
[localhost:8080](localhost:8080) to view the running guestbook site.

### Step 4: Consolidate the Object Definitions
Open a new file called `guestbook.yaml` in the repo. Copy the contents of the
other guestbook files into it with a `---` line in between each object
specification. Order doesn't matter. It should look like this:

```yaml
<contents of first yaml file>
---
<contents of second yaml file>
---
...
```

### Step 5: Apply the New File
Apply the new specification file:

```sh
kubectl apply -f guestbook.yaml
```

This applies all of the object specs at once. Since you already applied
everything to the cluster again in Step 3, this shouldn't make any changes to
the cluster. K8s uses the selectors in the object specifications to find all of
the already created components. It then checks the states of each against the
specification given and sees that nothing needs to be updated. This illustrates
the flexibility of k8s.

Visit [localhost:8080](localhost:8080) to verify that the app is working.

### Step 6: Add Something Extra
Now you are going to add a second site running along side the guestbook app. It
will just be the docker getting started tutorial.

Leave all of that running on your cluster. Open a new file in the repo named
`docker-getting-started.yaml`. Using the redis leader deployment as a template,
add a deployment for the docker getting-started tutorial image. Change the
names and labels (make sure they match between the selector and the spec). The
labels pairs can be whatever you like as long as they differ from from the
other objects so far. Set the number of replicas to 1 and use
`docker/getting-started` (not `docker.io/...`) for the image. K8s will know to
fetch it from docker hub. For the `containerPort`, set it to 80 since the
resulting container expects HTTP traffic.

A note about the labels: They can be anything you want. So, for example, you
can change `tier: frontend` to `bojangles: docker`, if you like. They just need
to match across the relevant spec files.

Next add the `---` divider line. Then use the redis leader service as a
template to create a service for the new deployment. Set the name and labels to
the same values as the deployment you just created. In the ports section, set
`port` to 8081 and `targetPort` to 80. This takes incoming traffic on port 8081
and routs it to port 80 where the container is expecting it. Remember to use v1
for the `apiVersion` in the service instead of apps/v1 like in the deployment.
Save and apply the new file. This should spin up a pod running the tutorial
container that is exposed through the service on port 8081. With the tunnel
running, you can now go to [localhost:8081](localhost:8081) to visit the
tutorial site. You don't need to run through the tutorial.

### Step 7: Tear down
Once everything is running correctly, run `minikube delete` to tear down the
cluster.

## Deliverables
Add and commit the following files:

* `guestbook.yaml`
* `docker-getting-started.yaml`
* Any files you changed in `guestbook/`
