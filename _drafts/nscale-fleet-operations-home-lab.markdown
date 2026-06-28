---
title: "Exploring Nscale's Fleet Operations - in a Home Lab"
date: '2026-06-29 09:00:00'
tags:
- homelab
- bare-metal
- maas
- temporal
- openstack
- slurm
- kubernetes
- devops
description: I rebuilt the node lifecycle from Nscale's Fleet Operations in a home lab - MAAS, Temporal, Slurm and OpenStack provisioning Intel NUCs from rack to workload to reclaim.
image: /content/images/2026/06/fleet-lab-architecture.png
header:
  teaser: /content/images/2026/06/fleet-lab-architecture.png
faq:
  - question: Do you need real GPUs or a data centre to learn data-centre provisioning?
    answer: >-
      No. The orchestration pattern is identical whether the node is a £40,000 GPU
      server or a second-hand Intel NUC - only the burn-in payload changes. I run
      CPU, memory and disk stress with stress-ng instead of gpu-burn, but MAAS,
      Temporal, Slurm and OpenStack behave exactly the same. You can even run the
      whole lifecycle with no hardware at all, using stub adapters.
  - question: What does each tool in the stack actually do?
    answer: >-
      MAAS is the bare-metal provisioner - it PXE-boots, enrols, commissions and
      deploys an OS to each machine. Temporal runs the durable lifecycle workflows
      that drive everything else. Slurm runs the burn-in stress test. OpenStack
      turns a burned-in node into compute capacity and launches a workload VM on it.
      A custom Python app - the Fleet Manager - ties them together.
  - question: Why use smart plugs instead of Redfish and BMC?
    answer: >-
      Cost and reality. A real server has a baseboard management controller (BMC)
      that speaks Redfish for remote power and boot control. Consumer NUCs
      have none of that, so I use a Tapo smart plug as the power control and a
      one-time BIOS setting to make each NUC PXE-boot on power-on. The plug gives me
      power on/off/query, which is enough for the lifecycle - it just took some
      hard-won workarounds.
  - question: Can you run the lifecycle without any hardware?
    answer: >-
      Yes - that was the whole point of building it in phases. Phase 0 runs the
      Temporal workflows end-to-end with stub adapters for MAAS, Slurm and
      OpenStack, so you can prove the durable onboarding and reprovision loop before
      you own a single NUC. Each later phase swaps one stub for a real backend.
  - question: Why orchestrate with Temporal instead of cron jobs or scripts?
    answer: >-
      Provisioning a node is a long, failure-prone, multi-step process - deploy,
      burn-in, register, allocate - that can take the best part of an hour and fail
      at any step. Temporal gives you durable execution: a workflow survives
      restarts, retries activities, and you can watch every step in the Web UI.
      Nscale uses Temporal for exactly this, and so do I.
---

[Nscale](TODO) wrote up some interesting blog posts about their fleet management system. It's a Python service which uses [Temporal](https://temporal.io) for long-running workflows, which integrate with MAAS, Slurm and OpenStack for provisioning, verifying and enrolling new hardware into the consumer-facing fleet:

- [Fleet Operations](https://www.nscale.com/blog/fleet-operations)
- [The Lifecycle of a Node](https://www.nscale.com/blog/lifecycle-of-a-node) 

This all runs on Kubernetes and there are parts of the stack I'm very familiar with from production systems, plus some I've only used at home (MAAS, OpenStack), and some I haven't used at all (Temporal). It looked like a good learning opportunity, so I spent a couple of weeks building out my own implementation which is here on GitHub:

[sixeyed/fleet-lab](https://github.com/sixeyed/fleet-lab) - fleet provisioning for a home lab
{: .notice--info}

What does it do? There's a local k3d version you can run which stubs out the integration points but uses real Temporal workflows, so you can test the lifecycle of a fake node. The real version deploys to my local Kubernetes cluster and does the whole thing: I can plug a new machine into the provisioning network and it gets automatically deployed, burn-in tested and enrolled, and ends up running an Nginx workload which I can switch out to Apache at a click.

**TL;DR:** I built an approximation of Nscale's Fleet Operations node lifecycle as a home lab. The Python Fleet Manager drives the node lifecycle via Temporal workflows for a real-world _neocloud-in-your-home_ experience. Plug in a box → MAAS PXE-provisions the OS and configures networking → Slurm runs a burn-in stress test → OpenStack enrols it as a compute host and launches a workload VM. The UI shows the lifecycle and all workflows and event logs.
{: .notice--info}

## The physical architecture

If you want to try this out yourself, the big requirment is a network which you can partition into separate segments. The control plane runs on Kubernetes in your normal network range, but MAAS needs to own DHCP to allocate IP addresses for new machines - so you sit that in a separate range or it would interfere. And OpenStack also needs an IP range so it can allocate addresses for workloads. I use Unifi kit everywhere; the tiny USW-Flex-Mini are managed switches, so you can configure different segments for different ports. I have multiple NICs on my boxes (I use old Intel NUCs as the "fleet"):

![Network diagram showing three networks: the control-plane LAN on 192.168.2.0/24 running the Kubernetes cluster, and a flat VLAN 50 on 10.50.0.0/24 split into a MAAS-owned provisioning range and an OpenStack workload range, with the fleet NUC connected by two NICs - eno1 for PXE and management, and a USB NIC as the OpenStack bridge uplink](/content/images/2026/06/fleet-network-architecture.png)
{: alt="Network diagram with three networks - the control-plane LAN on 192.168.2.0/24 running the Kubernetes cluster, and a flat VLAN 50 on 10.50.0.0/24 carrying a MAAS provisioning range (10.50.0.10-.199) and an OpenStack workload range (10.50.0.200-.240), with the fleet NUC connected by two NICs: eno1 for PXE and management, and a USB NIC as the OpenStack br-ex uplink"}

So there are three network ranges. The control plane sits on my normal LAN (`192.168.2.0/24`) where the Kubernetes cluster runs. Everything else lives on a single flat VLAN 50 (`10.50.0.0/24`), which carries two ranges that don't overlap: MAAS owns DHCP and hands out the provisioning addresses (`.10-.199`), and OpenStack allocates workload VMs from a reserved provider range (`.200-.240`). Each fleet NUC has two NICs on that VLAN - one for PXE and management, and a USB NIC is the uplink for OpenStack's external bridge. The UniFi gateway routes between the LAN and VLAN 50.

The control plane is separate from the fleet - you don't want your orchestration layer running on OpenStack alongiside consumer workloads, because if there's an outage you lose your management layer too. In my lab, the control plane runs on an existing Kubernetes cluster on my LAN: Temporal and its Postgres database, the Fleet Manager app, the Slurm controller, and the power shim. MAAS and OpenStack run on a separate machine which bridges the control plane and provisioning networks. 

## Mapping a data centre onto two NUCs

You don't need complicated kit for the network setup, but there are parts of the industrial data centre you won't have at home. There are reasonable alternatives for the missing pieces, which make the orcehstration logic and lifecycle a faithful representation:

| Real data centre | My home lab |
|---|---|
| GPU servers racked in a hall | 2× Intel NUCs on my desk |
| Redfish on a BMC (remote power + boot) | Tapo smart plug + power shim API + BIOS settings |
| PXE enrol, commission, deploy | [MAAS](https://maas.io) |
| Burn-in (`gpu-burn`, DCGM) | [Slurm](https://slurm.schedmd.com) running `stress-ng` (CPU/memory/disk) |
| Node becomes schedulable capacity | [OpenStack](https://www.openstack.org) - NUC enrolled as a `nova-compute` host |
| Orchestration (Temporal) | Temporal |
| Observability (Grafana: Mimir, Loki, Tempo) | Can run all these - but that's for phase 2 |
| Reclaim / remediation workflows | `ReleaseMachine` / `ReprovisionMachine` workflows |

I don't have racks of GPUs (those are all in my [Mac Studio boxes](TODO)), so the burn-in is just a quick CPU, memory and disk stress rather than `gpu-burn`. The NUCs don't have BMC (the always-on remote management chip), so I can't remotely tell a machine to reboot. Instead I control the mains with a smart plug and a simple REST API which MAAS can call to turn it on or off. Before provisioning I set each NUC's BIOS to PXE-boot first, and power on whenever it gets mains power. 

The enrolment part is the lowest fidelity. Once the node is provisioned, burnt-in and enrolled as a compute instance in OpenStack I have two workloads it can run - either Nginx or Apache VMs. Those are lightweight and fast to start, and they prove connectivity through the network segments.

## The lifecycle in Temporal workflows

Temporal is a powerful project for workflow managment, it has built-in primitives for handling long-running tasks and manging failures. Workflows are defined in code using the Temporal SDK, where you define the orchestration steps. The real work happens in activities you execute from the workflow:\

- workflows need to be _deterministic_ - producing the same output from the same input, with no side-effects. Temporal works by recording all activity in its event history. A workflow can be running but not active if it's waiting on an external event. When it activates again, it is loaded into a worker which runs a replay: executing the whole workflow again, but serving completed activitied from the event history, before continuing with the next activity - if there are any inconsistencies from the replay Temporal throws `NondeterminismError`.

- activities need to be _idempotent_ - producing the same outcome if they are run repeatedly. Activities are automatically retried on failure by default (you can configure that in the workflow with `RetryPolicy`), so they need to be repeatable. 

This is the simple definition for commissioning a new machine in MAAS. This is where MAAS inventories the hardware and enrols the machine as ready for OS deployment:

```python
@workflow.defn
class CommissionMachine:
    @workflow.run
    async def run(self, system_id: str) -> str:
        await _mark(system_id, "provisioning")
        await workflow.execute_activity("commission", system_id, start_to_close_timeout=_ACT)
        await _await_status(system_id, "Ready")
        await _mark(system_id, "new")  # Ready in MAAS; not yet FM-provisioned
        return "ready"
```

The `_mark` function is a helper that records the state of the workflow; `_await_status` checks the machine status with a poll-and-sleep loop. The real work happens in the activity which calls into the MAAS API to commission the machine:

```python
@activity.defn
async def commission(system_id: str, force: bool = False) -> None:
    m = await _ctx.maas.machine(system_id)
    if m.status in ("Commissioning", "Testing"):
        return
    if not force and m.status in ("Ready", "Deployed"):
        return
    await _ctx.maas.commission(system_id)
```

The `CommissionMachine` workflow gets called as a child workflow of `ProvisionMachine`, which co-ordinates the full machine on-boarding: 

```
ProvisionMachine
 ├── CommissionMachine   # MAAS - inventory hardware & enrol machine (skipped if already done)
 ├── DeployMachine       # MAAS - install OS, configure network
 ├── BurnInMachine       # Slurm - run stress-ng, logs posted to Fleet Manager
 ├── RegisterCompute     # OpenStack - add the node as a nova-compute host
 └── AllocateWorkload    # OpenStack - launch a workload VM
```

All workflows in Temporal are durable - the event history stores everything (backed by Postgres in my lab, swappable for Cassandra at ultra-scale). That powers realiability - failures can be recovered at pretty much any level, providing the state store survives. It also supports long-running workflows - you can call `workflow.sleep` for a week if you need to. In my lab, deploying the OS can take 5 minutes, burn-in another 5, registration with OpenStack nearly 10. The full provisioning of a new machine takes about 25 minutes, and the event history also powers obsevability:

> IMG temporal-provisioning-workflow.pbg

The end state is fully automated: plug in a NUC which is set for PXE boot and start on power cycle, and it gets managed from enrolment to running a workload, with no manual intervention. 

### Scaling Temporal workers

Activities are custom code, run by workers which register in Temporal _task queues_. My worker is a single Docker image which has the logic to run any activity, but the workload is split by queue to support independent scaling. The Fleet Manager runs on Kubernetes, with [KEDA](https://keda.sh) to scale workers with the [Temporal scaler](https://keda.sh/docs/2.20/scalers/temporal/), with different configurations per queue:

| Queue | Logic | Scale |
|---|---|---|
| `scan` | scheduled inventory sync | scale-to-zero, pulses 0→1→0 each tick |
| `lifecycle` | machine workflows + short MAAS calls | scale-to-zero between jobs |
| `ops` | long backend activities (burn-in, register, deploy workload) | always-on, fixed at 1 |

Keeping the `ops` queue always-on lets the `lifecycle` worker(s) scale to zero. A lifecycle workflow hands off the slow work - the 7-minute burn-in - to the `ops` queue, then waits on a Temporal timer rather than staying active in a worker. During the long waits there's nothing sitting on the `lifecycle` queue at all, and KEDA scales to zero. If there's lots of worked queued in Temporal, KEDA will scale up more worker Pods.

## The learning points

I ran the Fleet Manager over a couple of weeks, iterating first on a single NUC to get the provisioning workflow fully reliable. Then plugging in the second NUC to prove the full hands-off provisioning. There were a few interesting problems, some were down to the lab hardware, some took experimentation on the workflow stages, others were implementation issues.

**Activity idempotency.** FM auto-commissions a node with MAAS as soon as it enrols. The `commission` activity needs to skip if the node is already commissioning or ready - otherwise a Temporal retry that happens to land during a brief `Ready` window re-commissions the node, and you get an endless commission loop. Same with deploy: the API itself isn't idempotent, so the activity has to tolerate an HTTP 409 ("already deploying") or a retry-after-success wedges the workflow forever. In durable orchestration at scale it's reasonable to assume *every* activity will be retried eventually, so you need to code for any initial state and you'll only uncover edge cases with lots of testing.

**Exiting cleanly.** Another edge case from testing - pulling a provisioned node out of OpenStack so it can be recommissioned (for hardware changes or drift correction). Sunbeam in OpenStack uses a [dqlite](TODO) cluster for its control state. I have a single OpenStack controller, but fleet nodes join as voting members of `dqlite` to keep the quorum. Failed or partial removal of a NUC leaves a stale voter behind, which breaks the quorum and then the entire OpenStack control plane. You can't tell `dqlite` that certain classes of node should not be voters, so the fix is to ensure clean removal before MAAS wipes the disk and redeploys. Thet's actually three steps: tear down the juju machine first, then remove the dqlite cluster member, then delete the stale compute record from nova. That took experimentation too - when I had though _reclaim_ would be the easiest part of the lifecycle.

**Token expiration.** This was a good one. I left the system alone for a coupe of days with a fully provisioned NUC, then came back and tried to reallocate the workload. This is a UI-triggered workflow which uses the OpenStack API to remove the running instance (which was Nginx) and deploy a replacement (Apache). I had tested all this before, but this time the workflow sat without progress for a long time, then the activity failed, then retried, then went into the same loop. Temporal records activity events but it doesn't surface the logs - for that you need to dig into the worker pod logs. I found the juju authentication had expired and the activity was waiting on a password input that was never going to happen. The fix was to store the token in the juju YAML config on the OpenStack node, so it stayed authenticated and didn't ask the activity for auth. Classic day-2 ops issue you only find with longitudinal testing.
 
**More NICs please.** My NUCs only have one onbaord NIC, which is wired to the provisioning network and owned by MAAS. When OpenStack allocates a workload VM it sets it up with a real IP address on the same VLAN - but there's no way to route to that, because the only NIC is already taken with the MAAS DHCP address. I experimented for a while with trying to set up a bridge but that was a dead end: both OpenStack and MAAS need to own the network config. This was a hardware fix - adding the USB NIC to get a separate network route which OpenStack could own as the provider uplink, with no host IP configured. Even then the config is fiddly - the `openstack-hypervisor`snap needs to set up the NIC through its own config otherwise it deletes chagnes from other processes.

**The not-so-smart plug.** My plugs are simple Tapo TP100 units which don't have power sensing, so we can tell if the plug is on but not if the NUC itself is on. MAAS does soft resets during comissioning and deployment - effectivlely running `shutdown` -  which leaves the plug ON but the machine OFF. Ask the plug to turn on and it reports "already on" and does nothing, while the NUC is still off. The fix is a hack in the power-shim API - the `on` endpoint does an AC cycle - off, pause, on. That ensures the box is running when the plug is powered on (at the cost of resetting if it is already on). The deploy & commission workflows check if we've had no activity from MAAS for a suspicious period and then does the power cycle to ensure the box is running again. Sounds nasty but works reliably.

## Closing the loop

The whole point of all that was to close the loop, and it does now - end to end, on the first NUC. I can plug in a wiped box and walk away: MAAS provisions it, Slurm burns it in, OpenStack turns it into a compute host and launches a workload VM I can browse to. Then I can release that node, and the cleanup tears the workload down, removes the node from OpenStack, and wipes the disk back to a blank machine - and re-provisioning the same box onboards it cleanly and brings up a *different* workload.

That last part - re-registering the same wiped hardware without anything stale wedging the control plane - was the demo I most wanted, because it's the bit that proves the lifecycle is genuinely repeatable rather than a one-shot. It works.

What's left is rolling it out. Everything above runs on the first NUC; the second one is next, and it should be close to a formality - the provider-NIC discovery picks the non-boot NIC automatically, so there's nothing NUC-specific to configure. Plug the dongle in before commissioning, and the same enlist → provision → burn-in → register → workload path should just run. That's the moment it stops being "a node with a lifecycle" and becomes "a fleet" - which was the whole idea.

## What I got out of it

You don't need a data centre, or GPUs, or a budget, to understand how a modern AI cloud provisions bare metal. You need the same four tools the big providers use, a couple of cheap machines, and the willingness to debug a smart plug at midnight. The patterns scale down perfectly - a durable workflow driving two NUCs is the same shape as one driving a hundred thousand GPUs, and every gotcha I hit is a smaller version of a real operational problem.

If you want to learn a stack like this, I can't recommend the approach enough: read how the experts describe their system, then build the smallest possible version that exercises every part of it. You'll understand the architecture diagram far better once you've made every box on it fail at least once.

The whole thing - the phased build guide, the Helm charts, the Fleet Manager code, and the design docs for every component - is on GitHub:

> [github.com/sixeyed/fleet-lab](https://github.com/sixeyed/fleet-lab)

It's built in independently-demoable phases, starting with Phase 0, which runs the entire lifecycle on stub adapters with no hardware at all. So you can clone it, bring up Temporal on a local cluster, and watch a (simulated) node go from rack to workload before you've bought a single NUC.

## FAQ

### Do you need real GPUs or a data centre to learn data-centre provisioning?

No. The orchestration pattern is identical whether the node is a £40,000 GPU server or a second-hand Intel NUC - only the burn-in payload changes. I run CPU, memory and disk stress with `stress-ng` instead of `gpu-burn`, but MAAS, Temporal, Slurm and OpenStack behave exactly the same. You can even run the whole lifecycle with no hardware at all, using stub adapters.

### What does each tool in the stack actually do?

MAAS is the bare-metal provisioner - it PXE-boots, enrols, commissions and deploys an OS to each machine. Temporal runs the durable lifecycle workflows that drive everything else. Slurm runs the burn-in stress test. OpenStack turns a burned-in node into compute capacity and launches a workload VM on it. A custom Python app - the Fleet Manager - ties them together.

### Why use smart plugs instead of Redfish and BMC?

Cost and reality. A real server has a baseboard management controller (BMC) that speaks Redfish for remote power and boot control. Consumer NUCs have none of that, so I use a Tapo smart plug as the power control and a one-time BIOS setting to make each NUC PXE-boot on power-on. The plug gives me power on/off/query, which is enough for the lifecycle - it just took some hard-won workarounds.

### Can you run the lifecycle without any hardware?

Yes - that was the whole point of building it in phases. Phase 0 runs the Temporal workflows end-to-end with stub adapters for MAAS, Slurm and OpenStack, so you can prove the durable onboarding and reprovision loop before you own a single NUC. Each later phase swaps one stub for a real backend.

### Why orchestrate with Temporal instead of cron jobs or scripts?

Provisioning a node is a long, failure-prone, multi-step process - deploy, burn-in, register, allocate - that can take the best part of an hour and fail at any step. Temporal gives you durable execution: a workflow survives restarts, retries activities, and you can watch every step in the Web UI. Nscale uses Temporal for exactly this, and so do I.
