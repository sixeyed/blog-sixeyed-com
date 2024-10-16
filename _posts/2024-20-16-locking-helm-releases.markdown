---
title: 'Locking Helm Releases to Prevent Upgrades (and Downgrades)'
date: '2024-10-16 08:00:00'
tags:
- helm
- kubernetes
description: Sometimes you want to run a Helm upgrade command but stop it doing anything. Here's how to lock your release to do that.
header:
  teaser: /content/images/2024/10/helm-locked.png
---

It's great having a single 'Up' pipeline for your apps which deploys the whole stack, creating whatever resources it needs and ensuring the deployment matches the spec in your source repo. Idempotence is the key here so your IaC will create or update infrastructure as required, and if you're using Kubernetes and Helm then you get desired-state deployment for the software.

One small issue you might see is if you have common services - say a data storage or monitoring subsystem - which are shared for multiple deployments of the app. If those deployments are different test environments running from different branches of the code then you might get into a tricky scenario:

- you update the shared service Helm chart to v1.1 in the dev branch
- you run the Up pipeline to deploy to the latest code to the dev environment
- later someone deploys an earlier version from a release branch to the test environment
- the release branch uses v1.0 of the Helm chart, so your shared service gets downgraded

Helm has the `upgrade --install` command which supports this idempotent approach, but there's no flag to say _install it if it hasn't been deployed yet, or upgrade it if it has - but only upgrade it if this version number is higher than the one for the current release_. In that case it would be useful to lock the release to prevent any further upgrades or downgrades, but there's no `helm lock` command either.

## Pending Status to the Rescue

When Helm installs and upgrades get interrupted they can leave the release in a pending state - `pending-upgrade` or `pending-rollback`, usually when an operation times out. It's a nasty situation which requires manually deleting the Helm release Secret (until this [HIP](https://github.com/helm/community/pull/354) is completed) - but it effectively prevents any further changes to the release, so we can abuse it to create a lock.

The scripting for this is fairly simple, but it does rely on the internals of how Helm represents a release, so it's liable to be broken at some point (it's working as of Helm 3.16). Every time you install or upgrade a release Helm creates a Kubernetes Secret which contains an encoded representation of the release. 

You can try this with a simple Helm chart from my book [Learn Kubernetes in a Month of Lunches](https://amzn.to/3x3O7mt):

```
helm repo add kiamol https://kiamol.net

helm repo update

helm -n default upgrade --install vweb kiamol/vweb
```

The [Helm chart](https://github.com/sixeyed/kiamol/tree/master/ch10/vweb/v1/vweb) models a Deployment and a Service, but the install also creates a Secret:

```
PS>kubectl get secret

NAME                         TYPE                 DATA   AGE
sh.helm.release.v1.vweb.v1   helm.sh/release.v1   1      3m18s
```

In the Secret is all the chart contents, plus metadata about the release.

## Inspecting the Helm Secret

You can decode the Secret but that won't help you much - the content is in the `release` field, and it's a ZIP file, encoded as a Base64 text stream. So to read the contents you need to decode the Base64 representation in Kubernetes, then _decode it again_ to get the raw ZIP content, then pass it through the `gunzip` tool.

This extracts the raw data into a JSON file (using a *nix shell):

```
kubectl get secrets sh.helm.release.v1.vweb.v1 -o=jsonpath='{ .data.release }' | base64 -d | base64 -d | gunzip -c > data_release.json
```

In the JSON you'll see the YAML manifest for the deployment which Helm generated, plus the original chart contents. The interesting fields for us though are `info` and `version`: 

```json
{
    "name": "vweb",
    "info": {
        "first_deployed": "2024-10-16T07:53:28.496644+01:00",
        "last_deployed": "2024-10-16T07:53:28.496644+01:00",
        "deleted": "",
        "description": "Install complete",
        "status": "deployed"
    },
    "version": 1
}
```

When you run a `helm upgrade` command it decodes all this and checks the value of `info.status` before it proceeds. If it sees the release is pending then it won't continue. 

## Updating the Helm Secret to Lock the Release

Now we can see how to trick Helm into blocking any updates. The process is:

- extract and decode and unzip the `release` value from the Secret into a JSON file
- update the `info.status` value in the JSON
- also increment the `version` field and set a useful description
- zip and encode the updated `release` JSON
- get the Secret and store as a YAML file
- update the `release` field in the YAML with the new data
- update the YAML metadata
- apply the updated Secret YAML

I use [yq](https://mikefarah.gitbook.io/yq) to make the JSON and YAML updates. 
{: .notice--info}

In Bash it looks like this - setting some variables first for the release we want to lock (fetch them from `helm ls`):

```bash
RELEASE_NAMESPACE="default"
RELEASE_NAME="vweb"
RELEASE_VERSION="1"

RELEASE_SECRET_NAME="sh.helm.release.v1.$RELEASE_NAME.v$RELEASE_VERSION"

echo "Fetching release JSON from secret: $RELEASE_SECRET_NAME"
kubectl get secrets -n $RELEASE_NAMESPACE $RELEASE_SECRET_NAME -o=jsonpath='{ .data.release }' | base64 -d | base64 -d | gunzip -c > data_release.json

let "NEW_VERSION=RELEASE_VERSION+1"
echo "Updating release JSON with lock data and new version: $NEW_VERSION"
v=$NEW_VERSION yq -i '.version = env(v)' data_release.json
yq -i '.info.status = "pending-upgrade"' data_release.json
yq -i '.info.description = "LOCKED"' data_release.json

echo "Fetching release secret YAML"
kubectl get secrets -n $RELEASE_NAMESPACE $RELEASE_SECRET_NAME -o=yaml > release_secret.yaml

NEW_SECRET_NAME="sh.helm.release.v1.$RELEASE_NAME.v$NEW_VERSION"
echo "Updating secret YAML with lock JSON and new name: $NEW_SECRET_NAME"
yq -i 'del(.data)' release_secret.yaml
yq -i 'del(.metadata.creationTimestamp)' release_secret.yaml
yq -i 'del(.metadata.resourceVersion)' release_secret.yaml
yq -i 'del(.metadata.uid)' release_secret.yaml
r=$(cat data_release.json | gzip -c | base64 -w0) yq -i '.stringData.release = env(r)' release_secret.yaml
v=$NEW_VERSION yq -i '.metadata.labels.version = strenv(v)' release_secret.yaml
yq -i '.metadata.labels.status = "pending-upgrade"' release_secret.yaml
yq -i '.metadata.labels.locked = "true"' release_secret.yaml
n=$NEW_SECRET_NAME yq -i '.metadata.name = env(n)' release_secret.yaml

kubectl apply -f release_secret.yaml
```

When you run this it creates a new Kubernetes Secret with the chart contents from the previous release, but with the status set to `pending-upgrade`, which is what locks the release. It also adds a label to the Secret - `locked=true` - which makes it easy to undo the lock later.

## Locking and Unlocking the Helm Release

If you try this out it should end with the happy message `secret/sh.helm.release.v1.vweb.v2 created`. Check your Helm releases and you'll see the `vweb` app is now at revision 2 and is in `pending-upgrade` status:

```bash
>helm ls --all
NAME    NAMESPACE       REVISION        UPDATED                              STATUS           CHART           APP VERSION
vweb    default         2               2024-10-16 07:53:28.496644 +0100 BST pending-upgrade  vweb-2.0.0      2.0.0
```

Adding the new Secret mimics a `helm upgrade` command which timed out and left the release pending. You can see the new Secret has the `status` label and also the `locked` label:

```bash
>kubectl get secret --show-labels
NAME                         TYPE                 DATA   AGE     LABELS
sh.helm.release.v1.vweb.v1   helm.sh/release.v1   1      29m     name=vweb,owner=helm,status=deployed,version=1
sh.helm.release.v1.vweb.v2   helm.sh/release.v1   1      2m56s   locked=true,name=vweb,owner=helm,status=pending-upgrade,version=2
```

> The status label is just a convenience - updating that on its own doesn't lock the release, you need to update the status field in the release JSON

Any attempt to run a `helm upgrade` will fail now:

```bash
>helm upgrade --install vweb kiamol/vweb
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

You can unlock the release by deleting the Secret:

```bash
kubectl delete secret -l owner=helm,locked=true
```

And now you can merrily upgrade again:

```bash
>helm upgrade --install vweb kiamol/vweb        
Release "vweb" has been upgraded. Happy Helming!
NAME: vweb
LAST DEPLOYED: Wed Oct 16 08:26:49 2024
NAMESPACE: tracing-sample
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

All that's left is to tidy up the Bash script and wrap it into a Docker image with `bash`, `kubectl` and `yq` installed so you can run it without needing all the dependencies...