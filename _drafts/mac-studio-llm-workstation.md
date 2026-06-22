---
title: "Mac Studio: The Best Local LLM Workstation Money Can('t) Buy"
date: '2026-06-19 09:00:00'
tags:
- ai
- llm
- local-llm
- apple-silicon
- mac-studio
- llama-cpp
- mlx
- developer-productivity
description: Why an M4 Max Mac Studio with 128GB of unified memory is the best local LLM workstation for developers - running Qwen3, Ling and Gemma with llama.cpp and MLX.
header:
  teaser: /content/images/2026/06/openwebui-qwen.png
---

Frontier AI models from Anthropic, OpenAI etc. are closed source: you can only use them from the provider's own platform. Open-weight models are alternatives which you can run yourself on fairly modest hardware. They're reckoned to be about 9 months behind the frontier models; I use Qwen (from Alibaba), and it is a very capable model - it certainly feels like where Sonnet was 6-9 months ago.

You don't need super high-end kit to run a local model, and in the latest VS Code release you can use Copliot directly with your own LLM. No prompts or responses ever leave your network, you're not charged for any tokens, no presidents can turn off your access, and your data won't be used to train the next generation.

I started running smaller models on my old M1 Mac Studio last year and hit two problems: 64GGB of memory is not enough to run a high-fidelity model, and the speed and number of GPU cores on my box meant responses were too slow for daily use. So I did a bunch of research and finally settled on what I think is the best box for local inference: a newer Mac Studio :)

The Mac Studio M4 Max with 128GB of unified memory is a very performant LLM workstation. It's Apple Silicon, which is ARM64 architecture - and that runs very efficiently. It's quieter, cooler and cheaper to run than the alternativces, and far simpler to buy than building something yourself.

> Actually you can't buy it today. I bought mine at the end of 2025, and I had the choice of M4 Max up to 128GB or M3 Ultra up to 512GB. Now the RAM shortage has even hit Apple and 96GB is the most you can buy (and prices are going up). It's not clear if the M5 Max/Ultra Studios will launch this year, and how much RAM they'll have if they do.

As I write you can get an M5 Max Macbook Pro with 128GB. If you can get hold of a suitable machine, you can use the scripts and config on my repo to get up and running quickly: [sixeyed/local-llms on GitHub](https://github.com/sixeyed/local-llms).

## Apple's unified memory architecture

LLMs are memory hogs. All model weights have to be loaded to memory before you can use them, and the good models are big. A 122-billion parameter model needs around 77GB just to load at a sensible quantization - and that's before you add in the prompt's context window, which uses far more memory server-side than you would expect.

Traditional domestic GPU setups don't scale to these large models. Even a high-end Nvidia card (like the RTX 4090) only has 24GB of VRAM. You could buy two and wire them together, but now you're looking at $000s in graphics cards alone, plus the practical difficulties of rigging and managing multi-GPU configuration, and you've still only got 48GB to play with. You would have to run smaller models, or full-sized models at higher quants (which means lower fidelity and and worse performance).

Apple Silicon has a unified memory architecture. The 128GB in my Mac Stduio is one pool of memory, shared between the CPU and GPU cores. Metal (Apple's GPU framework) can use almost all of the system memory. On my M4 Max, very capable coding models can take 100GB+ which still leaves plenty for the OS and everything else. That's roughly four times what you get from a single high-end NVIDIA card.

The Mac Studio isn't the only unified-memory box. The Framework Desktop uses the same idea with AMD's Ryzen AI Max+ 395, and NVIDIA's DGX Spark does it with the GB10 Grace Blackwell chip - both put 128GB in one pool shared between CPU and GPU. The Spark pairs an Arm CPU with an NVIDIA GPU; the Framework runs an x86 chip with an integrated Radeon GPU. Both are capable machines - but the memory bus on each is much slower than the Mac's, and for inference that's the number that counts.

Inference is memory-bound - generating each token means reading the whole active model out of memory. The speed that data moves from memory to the GPU cores is the limiter for how fast your model responds. Apple's memory bandwidth is about twice the others':

| Machine | Unified memory (max) | Memory bandwidth | GPU cores (max) | Price |
|---------|----------------|------------------|---------------|---------------|
| **Mac Studio (M4 Max)** | 128GB LPDDR5x | **546 GB/s** | 40 (Apple) | ~£3,800 (Nov '25) |
| **MacBook Pro (M5 Max)** | 128GB LPDDR5x | **614 GB/s** | 40 (Apple) | ~£5,100 |
| **NVIDIA DGX Spark (GB10)** | 128GB LPDDR5x | 273 GB/s | 6,144 (CUDA) | ~£4,600 |
| **Framework Desktop (Ryzen AI Max+ 395)** | 128GB LPDDR5x | 256 GB/s | 40 (RDNA 3.5 CU) | ~£4,200 |

> Don't read those GPU-core counts as a league table - they're different units. An Apple GPU core, an AMD compute unit, and an NVIDIA CUDA core aren't the same thing, so the Spark's 6,144 "cores" aren't 150 times the Mac's 40 - each Apple core packs roughly 128 ALUs of its own.

Those prices are June 2026. They've all gone up about £1000 since January. The M5 Max is a laptop,  but it's the only Apple Silicon you can still buy at 128GB - and at 614 GB/s it's faster than my Studio. The M4 Max Studio price is what I paid in late 2025; maybe it will come back...

They all fit the same big models, but the memory bandwidth should give the Mac boxes the edge. I haven't spent £10K on the other boxes to run a comparison, but it's reasonable to assume the Studio decodes about twice as fast as the Spark or the Framework would. In inference terms, that means higher tokens per second, and a better user experience.

## The setup: llama.cpp and MLX, not Ollama

If you've dabbled with local models you've probably used Ollama. It's a great on-ramp, super easy to use and lots of models available. But it doesn't have all the tweaks to configure model performance, and there can be a lag between models being released on HugingFace and making it through to Ollama.

There are more powerful inference engines which are Mac friendly:

- **llama.cpp** - runs GGUF models with fine-grained control over context and quantization. A good fit for the Qwen3 family.
- **MLX** - Apple's own framework, which runs MLX-format models natively on Apple Silicon. Use for models that are only published as MLX weights, like Ling 2.6 Flash and Gemma 4.

Both serve an OpenAI-compatible API, so every client you might want to use talks to them the same way. I've tried Open WebUI, Cline, opencode and VS Code's chat - they all work fine.

I also did a bunch of performance tuning with Claude. I used Claude Code to run the models and monitor the output logs while I ran a task in client on a remote machine. Claude made performance recommendations, we tweaked the settings and ran again. Those optimizations are all the in GitHubt repo, and the model-start process is in a Python script which has all the flags.

You can start from scratch with these commands. Model weights are pulled on first use, so that will take a few minutes:

```bash
# Install the engines (macOS)
brew install llama.cpp
pip3 install --user mlx-lm

# Launch a model - run.py picks the right engine for you
python run.py                       # default: qwen3.6-moe via llama-server

# or try other families:
python run.py --family ling         # ling-2.6-flash via MLX
python run.py --family gemma        # gemma-4-31b via MLX

# Stop whatever's running
python stop.py
```

I run this just for me, and the parameters are set for a good working context (250K), and a single prompt (no concurrency betwee clients). Only one model runs at a time, so I use a standard port (8083) and then I can switch models without changing client config.

The optimizations in the repo are all tuned for the M4 Max (128GB): the right quantization for each model, context length pushed as far as the memory allows, and batch sizes set for this chip. The scripts detect whatever Mac you're on and print its capabilities, but the numbers are tuned for this machine.

## Usable local coding models

The model landscape moves fast, so treat this is a snapshot (I have a scheduled task in Claude which runs daily to research open-weight models and recommend any new ones). The big shift in the last year is mixture-of-experts (MoE) models, which have huge total parameter counts but only activate a subset of agents per request. So you get the knowledge of a big model with the speed of a small one. That combination is what makes local LLMs genuinely productive on (fairly) modest hardware.

Here's what I run. I've put each model's SWE-bench Verified score next to it - that's the "can it fix a real GitHub issue on its own" benchmark, and the one that tracks day-to-day coding usefulness best:

| Model | Engine | Params (active) | SWE-bench Verified | Best for |
|-------|--------|-----------------|--------------------|----------|
| qwen3.6-moe | llama.cpp | 35B-A3B (MoE) | 73.4% | Fast coding - my default |
| qwen3.6 | llama.cpp | 27B (dense) | ~75% | General coding, agentic tasks |
| qwen3.5 | llama.cpp | 122B-A10B (MoE) | ~72% | Large context, broad knowledge |
| qwen3-coder-next | llama.cpp | 80B-A3B (MoE) | 70.6% | Code-specialized |
| ling-2.6-flash | MLX | 104B-A7.4B (MoE) | not published | Fast agentic tasks |
| gemma-4-31b | MLX | 31B (dense) | 52.0% | Cline / agentic coding |

Those are the vendor- and community-reported SWE-bench Verified figures at the time of writing - rough ranking, because the hardware impacts the numbers. This is also an old benchmark. But it shows what `qwen3.6-moe` can do objectively: it lands at 73.4% with just 3 billion active parameters.

For context, the frontier closed models still lead this benchmark - but by less than the marketing suggests. The current Claude models score in the low-to-mid 80s on SWE-bench Verified (Opus 4.8 around 84%, Sonnet 4.6 around 82%), and the GPT-5 class is in the same range. That's a gap of roughly ten points to `qwen3.6-moe` - except those models run in someone else's datacenter on metered tokens, and this one runs silently on a box under my desk.

The model families are from three providers:

- **Qwen** (Alibaba Cloud) - the most capable open-weight coding models I've used. The `qwen3.x` releases come in both dense and MoE variants, and run on llama.cpp as GGUF.
- **Ling** (Ant Group's inclusionAI) - a MoE-first family tuned for fast agentic work. Ling 2.6 Flash ships as MLX weights, so it runs natively on Apple Silicon.
- **Gemma** (Google DeepMind) - Google's open-weight models, built from the same research as Gemini. Dense, easy to run, and solid for agentic coding in Cline.

`qwen3.6-moe` is genuinely usable for planning, debugging and coding. It's big enough to handle difficult, long-running tasks, and it's fast enough to feel responsive. It works nicely with my [centralized chat interface](/monitor-ai-agents-with-rocket-chat/) and it supports tool use and vision.

## Connecting your tools

The OpenAI-compatible API makes local models available to most tools. I point clients at the Studio with the base URL as the host and port plus `/v1`, and the API key can be any non-empty string because the backend inference engines ignore it.

VS Code's chat supports custom OpenAI-compatible models. Make sure you set your agents to run _Local_ and in the model selector click the cog to add a new model:

![Configuring a custom OpenAI-compatible model in VS Code](/content/images/2026/06/vs-code-configure-agent.png)
{: alt="VS Code chat model picker with the agent mode set to Local and the cog icon for adding a new custom model endpoint"}

Then you drop into the JSON editor and you can set up your local model connection::

```json
[
  {
    "name": "http://192.168.2.145:8083/v1",
    "vendor": "customendpoint",
    "apiKey": "none",
    "apiType": "chat-completions",
    "models": [
      {
        "id": "qwen3.6-moe",
        "name": "qwen3.6-moe",
        "url": "http://192.168.2.145:8083/v1/chat/completions",
        "toolCalling": true,
        "vision": true,
        "maxInputTokens": 250000,
        "maxOutputTokens": 16000
      }
    ]
  }
]
```

The `name` and `url` point at the Studio on my network; `toolCalling` and `vision` switch on the features `qwen3.6-moe` supports, and the token limits match the 250K context the server is tuned for. I also run  Open WebUI on my network, and that also connects to Qwen.

## Beware thinking-mode

The Qwen3 models can do "thinking" - generating a chain of reasoning before they answer. It's usually a good option for one-off questions, but coding agents can get confused. Cline and VS Code's agent can get tripped up with Qwen3: sometimes it gets stuck thinking. It writes "let me investigate..." and keeps deferring instead of committing to an action, and it'll keep looping in the client and never making any progress.

My launcher disables thinking by default - it sets `--reasoning-budget 0`, which makes the model commit straight to output. I haven't seen any drop in quality on multi-step planning, and the shoegazing think-loop has gone. If you want to experiment with thinking back on, the repo documents how to dial it back up with a capped budget. But for day-to-day agentic coding, off is going to be fine.

## Comparing to a DIY GPU rig

Now, you might be thinking, "But I could build a custom rig with a couple of graphics cards!" And you could. Let's be fair about what that actually costs you:

```text
# Custom rig with 2x RTX 4090
# GPUs:           ~£3,000
# Plus:           motherboard, CPU, RAM, PSU, case ~£1,200
# Total:          ~£4,200

# Usable VRAM:    48GB (still can't load a 77GB model)
# Power draw:     900W+ under load
# Setup:          CUDA, multi-GPU config, Linux drivers
# Noise:          serious cooling required
```

That's £700 more than the Studio cost me, and the extra money buys you less usable memory, ten times the power draw, and a box you can't hold a phone call next to. The dual-4090 rig will win on raw tokens per second for a model that fits in 48GB, no question. But it physically can't load the larger models, and you pay for that speed in heat, noise, and a build you maintain yourself.

People try the laptop-plus-external-GPU route too. Clever idea, worst of both worlds - you're throttled by Thunderbolt bandwidth, the eGPU adds another £400-800, and the power efficiency goes out the window. You end up with a complicated setup that still can't match the unified memory advantage.

## The power efficiency nobody mentions

This is the part that doesn't get talked about enough. My M4 Max pulls somewhere around 80-100 watts under full LLM load. A comparable NVIDIA setup is drawing 450+ watts for the GPU alone, plus a couple of hundred more for the rest of the system.

If you're running models regularly, that adds up:

```text
# Daily usage comparison (4 hours of LLM work)
# Mac Studio M4 Max:  ~0.36 kWh/day = ~£35/year
# Dual RTX 4090 rig:  ~2.6 kWh/day  = ~£250/year

# Over three years, the Studio saves you around £650 in electricity
```

And it's silent. No fan ramp, no coil whine, just a machine sitting there quietly running a 122-billion parameter model. Try getting that from a dual-GPU build.

## Getting started

If I've convinced you, where you land depends on what you're after.

**For serious local LLM work**, get the M4 Max Studio with 128GB - it's the machine the configs are tuned for, and it'll run everything in the table above. **For most developers**, an M2 or M4 Studio with 64GB (often available refurbished) handles the smaller MoE models comfortably; you'll skip the 122B monsters, but `qwen3.6-moe` will still fly. **And to get a feel for it**, even a base Mac Mini with 16GB will run a 7B model well enough to be worth an afternoon.

The software side is genuinely mature now. `brew install llama.cpp`, clone the [local-llms repo](https://github.com/sixeyed/local-llms), and `python run.py` - that's pretty much all there is to it. Everything else is picking a model and pointing a client at it.

## The bottom line

The Mac Studio isn't sold as an AI machine, but for running large models locally it's the best option on the market. The unified memory lets you load models nothing else in this price range can touch, the MoE models run fast enough for interactive work, and you get all of that silently and on a tenth of the power.

A dual-4090 rig will out-pace it on inference for models that fit in 48GB - I won't pretend otherwise. But it costs more, draws ten times the power, sounds like a hairdryer, and still can't load the big models. For developers doing real work with local LLMs, the Studio hits the sweet spot, and it's not close.

The future of development includes AI assistance running on your own hardware - private, fast enough, and always available. The Mac Studio makes that future affordable today. All the scripts and tuned configs are on GitHub at [sixeyed/local-llms](https://github.com/sixeyed/local-llms) - clone it, run it, and let me know how you get on.
