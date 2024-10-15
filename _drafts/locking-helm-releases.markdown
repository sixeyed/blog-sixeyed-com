---
title: 'Locking Helm Releases to Prevent Upgrades (and Downgrades)'
date: '2024-10-15 10:00:00'
tags:
- helm
- kubernetes
description: Sometimes you want to run a Helm upgrade command knowing that it won't do anything. Here's how to lock your release to do that.
header:
  teaser: /content/images/2024/07/workflow-2-error.png
---

It's great having a single 'Up' pipeline for your apps which deploys the whole stack, creating whatever resources it needs and ensuring the deployment matches the spec in your source repo. Idempotence is the key here so your IaC will create or update infrastructure as required, and if you're using Kubernetes and Helm then you get desired-state deployment for the software.

One small issue you might see is if you have common services - say a data storage or monitoring subsystem - which are shared for multiple deployments of the app. If those deployments are different test environments running from different branches of the code then you might get into a tricky scenario:

- you update the shared service Helm chart to v1.1 in the dev branch
- you run the Up pipeline to deploy to the latest code to the dev environment
- later someone deploys an earlier version from a release branch to the test environment
- the release branch uses v1.0 of the Helm chart, so your shared service gets downgraded

Helm has the `upgrade --install` command which supports this idempotent approach, but there's no flag to say _install it if it hasn't been deployed yet, or upgrade it if it has - but only upgrade it if this version number is higher than the one for the current release_. In that case it would be useful to ock the release to prevent any further upgrades or downgrades, but there's no `helm lock` command either.

## Pending Status to the Rescue

When Helm installs and upgrades get interrupted they can leave the release in a pending state - `pending-upgrade` or `pending-rollback`, usually when an operation times out. It's a nasty situation which requires manually deleting the Helm release secret (until this [HIP](https://github.com/helm/community/pull/354) is completed) - but it effectively prevents any further changes to the release, so we can abuse it to create a lock.

The scripting for this is fairly simple, but it does rely on the internals of how Helm represents a release, so it's liable to be broken at some point (it's working as of Helm 3.16). Every time you install or upgrade a release Helm creates a Kubernetes Secret which contains an encoded representation of the release. You can try this with a simple Helm chart from my book [Learn Kubernetes in a Month of Lunches](https://amzn.to/3x3O7mt):

```
helm upgrade --install TODO
```

