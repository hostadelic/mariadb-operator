MariaDB operator
================

*WARNING!* Currently in development! Use at your own risk!

A MariaDB operator for provisioning MariaDB servers, databases and users based
on Ansible.

# Usage

## Instanciate a MariaDB service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: mariadb.hostadelic.com/v1alpha1
kind: Mariadb
metadata:
  name: mariadb-sample
spec:
  volumeSize: 2Gi
  architecture: standalone # No replicas
EOF
```

Wait for a moment.

## Instanciate a MariaDB database

```bash
cat <<EOF | kubectl apply -f -
apiVersion: mariadb.hostadelic.com/v1alpha1
kind: MariadbDatabase
metadata:
  name: mariadb-sample
spec:
  mariadb: mariadb-sample
  name: sample
EOF
```

## Instanciate a user with privileges

```bash
cat <<EOF | kubectl apply -f -
apiVersion: mariadb.hostadelic.com/v1alpha1
kind: MariadbUser
metadata:
  name: mariadb-sample
spec:
  mariadb: mariadb-sample
  name: sample
  privs:
EOF
```


# Installation

## With Helm (recommended)

Please refer to [Helm chart](https://github.com/hostadelic/helm-charts/mariadb-operator).

## Manually

First install the CRDs:

```bash
kubectl apply -f https://github.com/hostadelic/mariadb-operator/
```

# Reference

## mariadb.hostadelic.com/v1alpha1.Mariadb



# Contributing

## Development dependencies

- [Kind](https://kind.sigs.k8s.io/) (could be installed for the project only).
- [Docker](https://www.docker.com/).
- [Ansible](https://www.ansible.com/) (will be installed for the project only
  by the `bootstrap` command).
- [Molecule](https://molecule.readthedocs.io/en/stable/).
- [yamllint](https://yamllint.readthedocs.io/en/stable/).
- [Kustomize](https://kustomize.io/), the standalone version.
- [GNU Make](https://www.gnu.org/software/make/).

## Linting

Linting is ran via molecule. To only lint:

```bash
molecule lint
```

## Testing

We use two ways to test at the moment and so document only these two. Refer to
the Ansible Operator SDK for more trails to follow.

### Manual testing with Kind

#### Create a cluster

```bash
kind create cluster --name 'mariadb-operator-tests'
```

This will create a new cluster and add a context for it in the default Kubectl
configuration file. This new context will be made the default.

```bash
kind get clusters
```

Will show it.

As the context is the default one, you probably can run `make deploy` and have
the operator be installed.

```bash
MARIADB_OPERATOR_VERSION=$(< Makefile sed -e '/^VERSION/!d' -e 's/.*=[[:space:]]*//')
make docker-build
kind load docker-image --name mariadb-operator-tests hostadelic/mariadb-operator:"$MARIADB_OPERATOR_VERSION"
make deploy
```


### Testing with Molecule

There are two scenarios: `default` and `kind`.

Scenario `kind` uses [Kind](https://kind.sigs.k8s.io/), a tool which emulate
Kubernetes clusters in containers, and is configured to run the operator from
the locally built image (pull policy set to `Never`).

```bash
molecule test -s kind
```

Let's get a refresher on molecule:

#### Commands

`molecule` is a subcommand kind of command-line application, like `kubectl`,
`git`, etc.

To list the commands:

```bash
molecule --help
...
Commands:
  check        Use the provisioner to perform a Dry-Run (destroy, dependency, create, prepare, converge).
  cleanup      Use the provisioner to cleanup any changes made to external systems during the stages of testing.
  converge     Use the provisioner to configure instances (dependency, create, prepare converge).
  create       Use the provisioner to start the instances.
  dependency   Manage the role's dependencies.
...
```

Then to get help of one command:

```bash
molecule test --help
...
Options:
  -s, --scenario-name TEXT        Name of the scenario to target. (default)
  -d, --driver-name [delegated|vagrant]
                                  Name of driver to use. (delegated)
  --all / --no-all                Test all scenarios. Default is False.
...
```

#### Tests scenarios

To list the scenarios:

```bash
molecule list
INFO     Running default > list
INFO     Running kind > list
                ╷             ╷                  ╷               ╷         ╷            
  Instance Name │ Driver Name │ Provisioner Name │ Scenario Name │ Created │ Converged  
╶───────────────┼─────────────┼──────────────────┼───────────────┼─────────┼───────────╴
  cluster       │ delegated   │ ansible          │ default       │ false   │ false      
  cluster       │ delegated   │ ansible          │ kind          │ false   │ false      
```

Each scenario is a subdirectory under the `molecule` subdirectory of this
repository containing Ansible playbooks.

```bash
ls -1F molecule/default
converge.yml
create.yml
destroy.yml
kustomize.yml
molecule.yml
prepare.yml
tasks/
verify.yml
```

```bash
ls -1F molecule/kind
converge.yml
create.yml
destroy.yml
molecule.yml
```

The default scenario is named... `default`.

Each scenario directory contains a `molecule.ya?ml` configuration file.

### Steps ? Stages ?

The list of ... is fixed:

- `dependency`
- `lint`
- `cleanup`
- `destroy`
- `syntax`
- `create`
- `prepare`
- `converge`
- `idempotence`
- `side_effect`
- `verify`
- `cleanup`
- `destroy`

Their content is determined as follows:

- Either a playbook with the ... name exists.

molecule.ya?ml

provisioner
verifier


```yaml
dependency:  {name: galaxy}
driver:      {name: delegated}
lint:        "set -e; yamllint ..."
platforms:   [{...}]
provisioner: {name: ansible, lint: "...", inventory: {group_vars:{}}, env: {KUBECONFIG:"..."}}
  name: ansible
  lint: |
    set -e
    ansible-lint
  inventory:
    group_vars:
      all:
        namespace: ${TEST_OPERATOR_NAMESPACE:-osdk-test}
    host_vars:
      localhost:
        ansible_python_interpreter: '{{ ansible_playbook_python }}'
        config_dir: ${MOLECULE_PROJECT_DIRECTORY}/config
        samples_dir: ${MOLECULE_PROJECT_DIRECTORY}/config/samples
        operator_image: ${OPERATOR_IMAGE:-"hostadelic/mariadb-operator"}
        operator_pull_policy: ${OPERATOR_PULL_POLICY:-"Always"}
        kustomize: ${KUSTOMIZE_PATH:-kustomize}
  env:
    K8S_AUTH_KUBECONFIG: ${KUBECONFIG:-"~/.kube/config"}
verifier:
  name: ansible
  lint: |
```

create.yml prepare.yml converge.yml verify.yml destroy.yml

```
WARNING  Skipping, missing the requirements file.
INFO     Running kind > lint
COMMAND: set -e
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" .

INFO     Running kind > cleanup
WARNING  Skipping, cleanup playbook not configured.
INFO     Running kind > destroy

PLAY [Destroy] *****************************************************************

TASK [Destroy test kind cluster] ***********************************************
changed: [localhost]
```

## Building

```bash
make docker-build
```

Will build the image. It requires your Docker daemon to be running.

## Publishing

You'll need write permissions to the `hostadelic/mariadb-operator` repository.

```bash
docker login
```

Then:

```bash
make docker-push
```

Will push it to Docker Hub.

## Custom Resources Definitions (CRD)

We think that the Prometheus operators CRD are good examples.

The following command line will show you a sample that we advise to follow:

```bash
curl 'https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/jsonnet/prometheus-operator/prometheus-crd.libsonnet' \
  | jq -C \
  | less -R
```
