---
title: 'An Evening with Claude Code  - or - How I Learned to Stop Worrying and Love AI'
date: '2025-06-05 10:00:00'
tags:
- ai
- claude
- productivity
- development
description: One evening running three parallel development projects with Claude Code - building a client POC, creating course demos, and fixing blog UI issues simultaneously. AI isn't replacing developers, it's transforming us into conductors of multiple AI workers.
header:
  teaser: /content/images/2025/07/claude-multi-cloud.png
---

It's 7pm, Friday night and I'm working on three different projects simultaneously with my new favorite colleague: [Claude Code](https://www.anthropic.com/claude-code). 

- Claude #1 is building a multi-cloud proof-of-concept for a client. 
- Claude #2 is creating demos for my next Pluralsight course
- Claude #3 is fixing the UI issues on this blog that I've ignored for years. 

Actually... I'm mostly watching [Incredibles 2](https://www.imdb.com/title/tt3606756/) with my kids, and just checking in on each of the Claudes in turn to nudge them to their next step. This is AI coding today.

## Welcome to the Paradigm Shift

We - engineers and architects - shouldn't feel we're competing with AI. Our role is to conduct it. Bandwidth is no longer the limit, because we can distribute work to as many AI agents as we can manage. With multiple Claudes I can productively work on multiple tasks in parallel. 

The mythical 10X developer turns out to be a regular 1X developer orchestrating 10 instances of Claude Code. Even the best multitasking developers pay a cost every time they context switch, but AI doesn't have that overhead. Each instance maintains its full context, while you operate on a higher level checking in and guiding them all.

I've been using Claude Code more and more, and this parallel workflow is a real breakthrough. This post covers what I think where AI is going in the short term: not replacing developers, but fundamentally changing what engineering roles look like. One person running multiple AI agents is like a tech lead with a hugely knowledgeable, experienced and dedicated team. So yes, AI is coming for your job - not to take it from you, but to transform it into something entirely more awesome.

> I've had the same joke from my consultancy clients for years - they want to clone me so they can run me at scale. It feels like Anthropic are doing that with Claude Code.

## Project #1: The Cloud Proof-of-Concept

I have a client i've worked with for many years who are multi-cloud, but the area I work in is 100% Azure. They're looking at broadening that to include AWS but they're skeptical about how easy it is to migrate apps between clouds. 

For years I've been saying that Docker and Kubernetes are the keystones of portable apps. They wanted a generic, simple proof of concept they could use to diff the Azure and AWS setup.

> The full code Claude generated is here: [github.com/sixeyed/multi-cloud-demo].

This is how the conversation with Claude Code started - using the [VS Code integration](https://docs.anthropic.com/en/docs/claude-code/ide-integrations#installation) in an empty folder:

```
1. "this is a new simple demo app for showing how Kubernetes deployments can work the same way in different clouds. i'd like to create a basic multi service application - a web app which posts text to a redis queue, and a background worker which reads from the queue. both should be .NET, and the web app should have a very simple form for the user to enter text. i'd also like docker files and docker compose.yml so this runs locally for development"

2. "great. now let's have a helm folder with a chart to deploy this app to kubernetes. we'll want the chart to have a redis dependency - probably bitnami's chart"
```

At this point I had the source code, Docker and Kubernetes artifacts for a working demo. Then it gets interesting because I'm designing this out loud and Claude is reacting to changes in requirements:

```
3. "now i want to demonstrate different kubernetes features. can we add to the worker process so it writes logs to a file or persists data somewhere so we can see PVCs and different storage options"

4. "no, scratch that. leave the logging to console but also add SQL server container to docker-compose.yml and have the worker write the messages to a database table"
```

And now I have a database defined in my Docker Compose spec, with the source code extended to include persistent storag. Claude also added it to the Kubernetes model without my asking, because by now it had enough context to know we'd be using both. 

This is impressive enough, but the output isn't perfect and - like any developer - Claude does get things wrong. What's _really_ impressive is that you can tell Claude there's an issue, and it can use the same tools you would to debug, track down the root cause and fix it:

```
5. "the data isn't getting into sql server from the worker. check the connection string and the ef core code"
```

That triggered lots of approval requests so Cluade could use tools like `kubectl` and `curl` - nothing happens without your permission. It found the problem, fixed the Kubernetes specs and we were off again. 

Generative AI for code is like having an engineer on the team who's extremely knowledgable and very enthusiastic, but lacking experience. Your role is to guide them, feed them tasks which you break down into sensible steps and describe clearly, and give feedback when something needs more work.

Some of these prompts take Claude a minute or two to work on, sometimes longer. That's when you - as the AI team lead - switch to another instance on another project. That Claude has finished it's latest task so you guide it on to the next one.

I'm always polite with Claude because of [Terminator 2](), but it doesn't mind criticism. Sometimes it approaches tasks in an odd way, and you just point out what you'd prefer and it goes off and corrects it:

```
36. "this is very cool. let's add another page to the web app which shows the messages in sql server. probably best to split it out so the html isn't all in a string now too :)"

37. "also - why do we have HTML strings at all? shouldn't we be using razor pages or something."
```

You get the idea. The full conversation ran to 100 or so prompts, and at the end I had a full stack repo with Terraform configurations to create the Azure and AWS infrastructure, Helm charts to deploy the same app to both, and detailed documentation.

> I made a point of not tocuhing any code myself. Claude did it all - but Claude couldn't have done it without me. 

This is why there's still a place for human engineers. Maybe not for long, but for now the AI needs guidance. The more knowledge and experience you bring at the human guide, the more productive the AI can be.

## Project #2: Pluralsight Course Demo

And while that goes on there, look at this going on here. In a different VS Code window I have a separate Claude Code session.

I'm working on a new [SRE learning path for Pluralsight](). There are four courses and I like to have a differnt demo app for each course. Those apps are built to show specific behavior to highlight how SRE approaches and tools can fix issues.

In the old days I might spend the first week of a new course building the demo app. I quite enjoyed that - it's responsilbity-free coding because the app will never run in anger - and it gave me a chance to use all the latest tech stacks and keep up to date.


DONE TO HERE


Different VS Code window, completely different context:

```
Build a demo showing microservices anti-patterns. Start with a tightly 
coupled order service calling inventory service directly via HTTP.
```

This is for my next course on microservices architecture. While the client POC churns away, I'm building teaching materials. The beauty? I can ask for variations:

```
Now show the same functionality with proper event-driven architecture 
using RabbitMQ
```

Then:

```
Add a version using Dapr for service invocation. Include configuration 
for local development.
```

By 8pm, I have six different architectural patterns demonstrated, all containerized, all with clear progression from anti-pattern to best practice. Previously, building these demos would take a week of evenings. The ROI on Claude credits is obvious when you do the math against consulting rates.

## Project #3: The Blog UI (Finally!) (6:30pm - 8:00pm)

Here's my confession: I've been writing at blog.sixeyed.com for over 20 years, and the mobile experience has been broken for... most of them. I'm a backend developer. CSS is not my happy place.

Third terminal:

```
I need you to fix the responsive design issues on my blog. Here's the current CSS: [paste]. Mobile menu doesn't work, code blocks overflow, images break the layout.
```

I was never particularly interested in CSS, and now I don't have to be. Check back 10 minutes later:

```
Add dark mode support with automatic detection and a manual toggle. Keep it simple but modern.
```

Years of technical debt fixed while my other projects built themselves. The blog finally looks professional on mobile. My wife can actually read my posts on her phone without zooming and scrolling horizontally.

## The Evening's Tally

9pm check-in across all three terminals:
- **Client POC**: Full distributed system deployed on both AKS and EKS - frontend accepting jobs, Redis queuing them, workers processing, results in SQL
- **Course demos**: Six architectural patterns, fully containerized with documentation
- **Blog**: Responsive, dark mode enabled, finally entering the 2020s

I accomplished three different project milestones in one evening. Not by working faster - by working on multiple things simultaneously.

## The Realization

What I've realized is that the value of human oversight across multiple AI workers is the new superpower. You become the tech lead doing rounds, checking on your team's progress, providing direction, ensuring quality.

Here's the hardest habit to break: the urge to jump in and edit code manually. Every time I see a small bug or want to tweak something, muscle memory says "I'll just quickly fix this." But that's the old way. It's always more effective to describe the change to Claude and move on to check another project. Let the AI make the change while you're being productive elsewhere. Breaking this habit is like learning to delegate - uncomfortable at first, but essential for scaling.

## The Competitive Reality

Here's the uncomfortable truth: one AI-enabled developer can now deliver what used to take a small team. Not because AI is better at coding than humans, but because one human can effectively orchestrate multiple AI developers working in parallel.

The good news? If you adapt, you become incredibly valuable. The concerning news? If you're still working sequentially, you're competing against people running parallel workstreams.

My advice:
- Start thinking in parallel projects, not sequential tasks
- Get comfortable being a reviewer/director rather than an implementer
- Practice orchestrating multiple contexts simultaneously
- Focus on the skills AI can't replicate: understanding business value, making architectural decisions, ensuring quality

Learn to be a conductor, or watch conductors outdeliver entire orchestras.

The code from all three projects is on GitHub. But more importantly, the entire Claude Code transcript for the POC is there too - every prompt, every response. You can see exactly how a distributed system went from nothing to multi-cloud deployment without me writing a single line of code.

Stop thinking about AI as a faster way to code. Start thinking about it as your development team.

Now if you'll excuse me, I've got three more Claude Code instances to spin up. My next Pluralsight course isn't going to build itself. Well, actually...