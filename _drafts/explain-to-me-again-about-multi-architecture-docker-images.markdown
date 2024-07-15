---
layout: post
title: Explain to me again about multi-architecture Docker images?
---

OS: Windows or Linux  
if Windows -  
os.version: etc

Architecture: amd64, arm64  
if arm64 -  
variant: v7 (32-bit), v8 (64-bit)

    docker manifest inspect mcr.microsoft.com/dotnet/runtime:5.0
    {
       "schemaVersion": 2,
       "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
       "manifests": [
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1160,
             "digest": "sha256:82a87ab900e99f07aa357b03f6e39c5012428fe57b1dfccf4bbc1e3f6b3d2138",
             "platform": {
                "architecture": "amd64",
                "os": "linux"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1160,
             "digest": "sha256:0491818c2b50eb669f9e33c60f72e151e29ecd54adda176b68441d20f563d997",
             "platform": {
                "architecture": "arm",
                "os": "linux",
                "variant": "v7"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1160,
             "digest": "sha256:35f01ad9816ceb401f8c1dfab70941a19a1ae3e3f81d5650996d35cfe50e14d1",
             "platform": {
                "architecture": "arm64",
                "os": "linux",
                "variant": "v8"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1958,
             "digest": "sha256:8615ddb0a8672f1149e62e10944ba536e5598ae17b5ec152e1b2b1d850826f7e",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.17763.1697"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1958,
             "digest": "sha256:3870b537e207955e2a913be6f708b22206ff7759d4a2cc7799019ccb1992dbe1",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.18363.1316"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1958,
             "digest": "sha256:ccccd4ee408ff0ce20c8844873803b67e386b4e9b85804bc19af076f2a6b7864",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.19041.746"
             }
          },
          {
             "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
             "size": 1958,
             "digest": "sha256:7b59ceef4e69031649d8fd501bcb20336540377787ca5a537acc1c26eda63126",
             "platform": {
                "architecture": "amd64",
                "os": "windows",
                "os.version": "10.0.19042.746"
             }
          }
       ]
    }

<!--kg-card-end: markdown-->