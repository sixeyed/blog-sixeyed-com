---
title: 'An Evening with Claude Code  - or - How I Learned to Stop Worrying and Love AI'
date: '2025-07-10 09:00:00'
tags:
- ai
- claude
- claude-code
- productivity
- development
- automation
- parallel-programming
- artificial-intelligence
- software-engineering
description: One evening running three parallel development projects with Claude Code - building a client POC, creating course demos, and fixing blog UI issues simultaneously. AI isn't replacing developers, it's transforming us into directors of multiple AI workers.
header:
  teaser: /content/images/2025/07/claude-multi-cloud.png
---

It's 7pm, Friday night and I'm working on three different projects simultaneously with my new favorite colleague: [Claude Code](https://www.anthropic.com/claude-code). 

- Claude #1 is building a multi-cloud proof-of-concept for a client. 
- Claude #2 is creating demos for my next Pluralsight course
- Claude #3 is fixing the UI issues on this blog that I've ignored for years. 

Actually... I'm mostly watching [Incredibles 2](https://www.imdb.com/title/tt3606756/) with my kids, and just checking in on each of the Claudes in turn to nudge them to their next step. This is AI coding today.

## Welcome to the Paradigm Shift

We - engineers and architects - shouldn't feel we're competing with AI. 🎬 Our role is to direct it. Bandwidth is no longer the limit, because we can distribute work to as many AI agents as we can manage. With multiple Claudes I can productively work on multiple tasks in parallel. 

The mythical 10X developer turns out to be a regular 1X developer directing 10 instances of Claude Code. Even the best multitasking developers pay a cost every time they context switch, but AI doesn't have that overhead. Each instance maintains its full context, while you operate on a higher level checking in and guiding them all.

> I've heard the same joke from my consultancy clients for years - they want to clone me so they can run me at scale. It feels like Anthropic are doing that with Claude Code.

I've been using Claude Code more and more, and this parallel workflow is a real breakthrough. This post covers what I think where AI is going in the short term: not replacing developers, but fundamentally changing what engineering roles look like. One person running multiple AI agents is like a tech lead with a hugely knowledgeable, experienced and dedicated team. 🚀 So yes, AI is coming for your job - not to take it from you, but to transform it into something entirely more awesome.

## Project #1: The Cloud Proof-of-Concept

I have a consulting client who are multi-cloud, but the area I work in is 100% Azure. They're looking at broadening that to include AWS but they're skeptical about how easy it is to migrate apps between clouds. 

🐳 For years I've been saying that Docker and Kubernetes are the keystones of portable apps. They wanted a generic, simple proof of concept they could use to see if that was true, and to diff the Azure and AWS setup. I thought that was something Claude could help me with.

> The full code Claude generated is on GitHub: [sixeyed/multi-cloud-demo](https://github.com/sixeyed/multi-cloud-demo). Here's a snap of the app running in Azure with fully automated deployments built by Claude:

![Multi-cloud demo application running in Azure showing distributed system with frontend, Redis queue, and SQL Server database deployed by Claude Code](/content/images/2025/07/claude-azure-demo.png)

This is how the conversation with Claude Code started - using the [VS Code integration](https://docs.anthropic.com/en/docs/claude-code/ide-integrations#installation) in an empty folder:

<div class="prompt-wrap">1. "this is a new simple demo app for showing how Kubernetes deployments can work the same way in different clouds. i'd like to create a basic multi service application - a web app which posts text to a redis queue, and a background worker which reads from the queue. both should be .NET, and the web app should have a very simple form for the user to enter text. i'd also like docker files and docker compose.yml so this runs locally for development"

2. "great. now let's have a helm folder with a chart to deploy this app to kubernetes. we'll want the chart to have a redis dependency - probably bitnami's chart"</div>

At this point I had the source code, Docker and Kubernetes artifacts for a working demo. Then it gets interesting because I'm designing this out loud and Claude is reacting to changes in requirements:

<div class="prompt-wrap">3. "now i want to demonstrate different kubernetes features. can we add to the worker process so it writes logs to a file or persists data somewhere so we can see PVCs and different storage options"

4. "no, scratch that. leave the logging to console but also add SQL server container to docker-compose.yml and have the worker write the messages to a database table"</div>

And now I have a database defined in my Docker Compose spec, with the source code extended to include persistent storage. Claude also added it to the Kubernetes model without my asking, because by now it had enough context to know we'd be using both. 

This is impressive enough, but the output isn't perfect and - like any developer - Claude does get things wrong. What's _really_ impressive is that you can tell Claude there's an issue, and it will use the same tools you would to debug, track down the root cause and fix it:

<div class="prompt-wrap">5. "the data isn't getting into sql server from the worker. check the connection string and the ef core code"</div>

That triggered lots of approval requests so Claude could use tools like `kubectl` and `curl` - nothing happens without your permission. It found the problem, fixed the Kubernetes specs and we were off again. 

🤖 Generative AI for code is like having an engineer on the team who's extremely knowledgeable and very enthusiastic, but lacking experience. Your role is to guide them, feed them tasks which you break down into sensible steps and describe clearly, and give feedback when something needs more work.

Some of these prompts take Claude a minute or two to work on, sometimes longer. That's when you - as the AI team lead - switch to another instance on another part of the project, or a different project entirely. That other Claude has finished its latest task so you guide it on to the next one.

I'm always polite with Claude because of [Terminator 2](https://www.imdb.com/title/tt0103064/), but it doesn't mind criticism. Sometimes it approaches tasks in an odd way, and you just point out what you'd prefer and it goes off and corrects it:

<div class="prompt-wrap">36. "this is very cool. let's add another page to the web app which shows the messages in sql server. probably best to split it out so the html isn't all in a string now too :)"

37. "also - why do we have HTML strings at all? shouldn't we be using razor pages or something."</div>

You get the idea. The [full conversation](https://github.com/sixeyed/multi-cloud-demo/blob/main/user-prompts.txt) ran to 90 prompts, and at the end I had a full stack repo with Terraform configurations to create the Azure and AWS infrastructure, Helm charts to deploy the same app to both, and detailed documentation.

> I made a point of not touching any code myself. Anything that didn't work or needed changing went into a prompt. So Claude did it all - but Claude couldn't have done it without me. 

This is why there's still a place for human engineers. Maybe not for long, but for now the AI needs guidance. The more knowledge and experience you bring as the human guide, the more productive the AI can be. Rough guess I think this would have taken one human about 3 days to write; with Claude it was done in a few hours of intermittent guidance.

## Project #2: Pluralsight Course Demo

And while that goes on there, look at this going on here. In a different VS Code window I have a separate Claude Code session.

I'm working on a new [SRE learning path for Pluralsight](). There are four courses and I like to have a different demo app for each course. Those apps are built to show specific behavior to highlight how SRE approaches and tools can fix issues.

In the old days I might spend the first week of a new course building the demo app. I quite enjoyed that - it's responsibility-free coding because the app will never run in anger - and it gave me a chance to use all the latest tech stacks and keep up to date.

But actually it's not a very effective use of time. Far better to get Claude to write that throwaway code for me, freeing up my time to work on the content. 

After a few iterations Claude had built a demo app which could be configured to deliberately fail in interesting ways, with a full GitOps stack to create Azure infrastructure with Terraform and deploy to Kubernetes with Argo. 

Here's part of Claude's summary for that session, running while the other Claude was building my multi-cloud demo:

```
## Final State
Repository is now:
- ✅ PowerShell standardized
- ✅ Self-bootstrapping infrastructure  
- ✅ Simplified testing approach
- ✅ Zero-configuration user experience
- ✅ Production-ready GitOps setup

## Key Takeaways
1. Complex test frameworks can become dead ends - simpler is often better
2. Self-bootstrapping infrastructure eliminates user setup pain
3. Consistency (PowerShell only) reduces maintenance overhead
4. Real infrastructure validation > mocked tests for reliability demos
```

This was another app which started from scratch. ⏰ I saved a week of tinkering and could get straight onto the content for the course. It takes a little bit of introspection to admit: _this task is better suited to Claude than to me_ . But it is and it means that course is getting to completion more quickly.

## Project #3: The Blog UI (Finally!)

And the last thing Claude was helping me with was this blog. I've always focused on the content and have pretty much zero interest in HTML and CSS. Over the years I've used different frameworks and platforms, the current setup is Jekyll powered by GitHub pages.

The theme is a modification of [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) and the mobile experience has always sucked, but it's one of those things I never fancied working on.

So in my third session I fired up Claude and introduced it to the blog repo. With the `init` command it inspected the source code and generated the [CLAUDE.md](https://docs.anthropic.com/en/docs/claude-code/memory) document for its own guidance, including a high level overview:

<div class="prompt-wrap">## Project Overview

This is a Jekyll-based blog using the Minimal Mistakes theme, hosted on GitHub Pages. The blog belongs to Elton Stoneman, a freelance IT consultant and trainer.</div>

While the other two Claudes were working on their own things, I had this Claude fixing up the responsive design, adding SEO-metadata to recent posts and generally tidying things up. 

I even got Claude to write a url-shortening component, to make it easier to control links. So my Pluralsight author page is available through my blog at https://blog.sixeyed.com/l/ps-home.

Years of technical debt fixed while my other projects built themselves. 📱 The blog finally looks professional on mobile. You can actually read my posts on your phone without zooming and scrolling horizontally.

![Responsive blog design showing mobile-optimized layout with proper text wrapping and improved user experience created by Claude Code](/content/images/2025/07/claude-blog.png)

## The Evening's Tally

Final check-in across all three terminals:
- **Client POC**: Full distributed system deployed on both AKS and EKS - frontend accepting jobs, Redis queuing them, workers processing, results in SQL
- **Course demos**: Six architectural patterns, fully containerized with documentation
- **Blog**: Responsive, dark mode enabled, finally entering the 2020s

✨ I accomplished three different project milestones in one evening (and a little bit into the following morning). Not by working faster - by working on multiple things simultaneously.

## The Realization

💪 What I've realized is that the value of human oversight across multiple AI workers is the new superpower. You become the tech lead doing rounds, checking on your team's progress, providing direction, ensuring quality.

Here's the hardest habit to break: _the urge to jump in and edit code manually_. Every time I see a small bug or want to tweak something, muscle memory says "I'll just quickly fix this." But that's the old way. It's always more effective to describe the change to Claude and move on to push forward another project. Let the AI make the change while you're being productive elsewhere. Breaking this habit is like learning to delegate - uncomfortable at first, but essential for scaling.

## The Competitive Reality

💯 Here's the uncomfortable truth: one AI-enabled developer can now deliver what used to take a small team. Not because AI is better at coding than humans, but because one human can effectively direct multiple AI developers working in parallel.

The good news? If you adapt, you become incredibly valuable. The concerning news? If you're still working sequentially, you're competing against people running parallel workstreams.

My advice:

- Start thinking in parallel projects (or at least parallel tasks in the same project), not sequential tasks
- Get comfortable being a reviewer/director/tester/product manager rather than an implementer
- Practice managing multiple contexts simultaneously
- Focus on the skills AI can't replicate: understanding business value, making architectural decisions, ensuring quality

🎬 Think of yourself as a director, managing all the talent. You couldn't do it without them - but they couldn't do it without you either.
{: .notice--info}

The code from all three projects is on GitHub. And the entire Claude Code transcript for the multi-cloud demo app is there too - every prompt. You can see exactly how a distributed system went from nothing to multi-cloud deployment without me writing a single line of code.

Stop thinking about AI as just a faster way to code, or maybe a threat to your job. Start thinking about it as your development team.

Now if you'll excuse me, I've got a few more Claude Code instances to spin up. My next Pluralsight course demo isn't going to build itself. 😏 Well, actually...