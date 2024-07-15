---
layout: post
title: 'DevOps: Should You Change Your Company, or Change Your Company?'
---

If you've seen any presentations on DevOps, you've probably heard this quote from Don Jones: "change your company, or change your company". It gets to the heart of DevOps, which is fundamentally a cultural change. Changing a company's culture is hard, and it's much easier to move on to somewhere that's already on the DevOps path. But if you stick with your current company and help to make that change, you'll be making an improvement for everybody.

- Top-Down and Bottom-Up

There are some typical reactions emerging to the DevOps trend. Devs tend to be enthusiastic, because they see their friction points with Ops disappearing, they see their work expanding into infrastructure automation, and they know there are a bunch of great tools they can start learning about. IT Ops people tend to be a little more muted, because they see there's a whole lot of dev tools they'll need to learn about, and they can be worried their work will be contracting, but they see definite advantages in bringing devs into line. Management can have their own spectrum of reactions, which are as widely varied as 'this is the latest fad - ignore it' to 'this will help me halve my head count - do it'.

Teams who have transitioned to DevOps, or who are helping other teams make the transition, are finding the change needs support from the bottom up and from the top down. The devs and ops need to be excited and enthused, because it's their energy that will make the change happen and make it succeed. Bu the higher-ups need to be supportive too, beyond just okaying the new approach or signing off the budget. Teams trying a new approach need to be protected - isolated from external work requests, and insulated from existing processes and red-tape. A team running their first DevOps project will benefit from being siloed, and it will take a lot of management strength to preserve that silo.

- Be Realistic

If you want to get management on-board though, you need to be realistic about what DevOps will bring and what it will cost. There are definitely long-term financial benefits to be had, but they're benefits from increased efficiency, decreased time-to-market and improved product offerings, which are hard to quantify. Management looking at DevOps as a way to reduce head-count are looking at it upside-down. The goal of DevOps is to maximize the efficiency of your existing resources - hardware and humans - so IT can support business change quickly, reliably and effectively.

The first DevOps project will likely cost more than previous projects, because there will be Ops people taken from their normal roles and put into the project team, so they'll need to be backfilled. And building that deployment pipeline which creates, deploys, tests and publishes an entire environment within a few minutes after every code change takes a lot of scripting. Automating everything in that pipeline is a major benefit of the DevOps approach, but for teams starting fresh, building the pipeline takes a lot of work.

- Find Easy Targets

Which is why DevOps practitioners recommend starting small, on a dedicated project that can be done in the DevOps way from the start. I'm inclined to be a bit braver and say the first project doesn't need to be tiny, but it does need to be well-defined, so it's clear what is being delivered and what the success metrics are. Many teams are finding that once people see the early achievments of the DevOps project, they're far more eager to adopt the practice on a larger scale.

But convincing the management team to try a cultural change on a whole project, even a small one, might be a difficult sell in an organization that doesn't really believe in the benefits. In that case, it's a good idea to be on the lookout for easy targets and communicate what DevOps would bring to those specific cases. Problems are always a good candidate - did a platform upgrade cause a product failure? Did a minor change cause an unexpected outage? Are the product team struggling to reproduce a defect in the test environment?

Those are all good examples of where you can be talking up DevOps, because they're all cases where a closer working relationship between dev and ops would have saved wasted time. That's easier for management to make sense of than a broader proposition about making 'better software'.

- Foster Relationships

If you're struggling to get the message across, and there's really no traction for DevOps in your company, there's nothing to stop you doing it anyway. It's a movement which is based on better communications between dev and ops, and no-one can complain if you start doing that by yourself. Delivering software is a very human practice, and a friendly attitude towards other humans goes a long way.

In the ops team and want to understand what's coming in the next product release? Ask the devs if you listen in on their stand-up, or get read access to their task board. If there are new technologies or new archiectural approaches, ask what it's all about - you'll get an early indicator and you can start getting skilled up in advance.

In the dev team and want to understand what's coming in the next round of hardware upgrades? Ask the ops people about the current specs, and about where the upgrades are focused. If the next round is restricted to upgrading existing machines with more RAM or with SSDs, then that's something which will inform your solution design - your servers will be getting faster, so do you need to spend time optimizing code?

Those are basic examples, but the idea is important - if the best you can do right now is to informally break down barriers, even that should lead to real improvements. Real improvements will help support your push for DevOps.

- Turn Negatives Around

See if you've heard this one before:

U - Why isn't my new feature ready?  
T - We didn't get enough time to test it properly  
U - Why not?  
T -Because we didn't get a release to test until last week  
U - Why not?  
D - Because the deployment to the test environment kept being screwed up  
U - Why?  
D - Because the environment wasn't set up correctly  
U - Why not?  
O - Because we only found out what the environment was meant to look like last week

- etc.

It's a cycle of why/because/why not/because and it doesn't make any progress. The project team are actually behaving as three separate teams - dev, ops and test - and each team is focused on their own success (or at least on not being to blame for failure). But the project team is only one team, and until high-quality new features are delivered to production, none of the team has succeeded.

How about this instead:

U - Why isn't my new feature ready for me to use?  
T - We didn't get enough time to test it properly  
U - Why not?  
D - We added some new components to the build but didn't update the deployment docs. That was our fault, and we've been working with O to do things differently next time

- etc.

That's much better - focus on the solution to the friction and propose a new and better way. In this example, the conversation could move onto automated provisioning and blue-green deployments. There's an up-front cost to making that happen, but that discussion takes place against a background of a prevous failure and a desire to improve.

- Keep On Keepin' On

If things aren't changing but you're convinced they could - keep trying. Don't sit quietly in meetings when you could be raising a valid point to support a change for the better. If

<!--kg-card-end: markdown-->