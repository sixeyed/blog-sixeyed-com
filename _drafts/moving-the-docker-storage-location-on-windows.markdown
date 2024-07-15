---
layout: post
title: Moving the Docker Storage Location on Windows
---

docker system prune

edit C:\programdata\docker\config\daemon.json:

{  
"data-root": "D:\docker-data-root",  
"insecure-registries": [  
"registry.sixeyed:5000"  
],  
"tlscacert": "C:\ProgramData\docker\certs.d\ca.pem",  
"tlsverify": true,  
"hosts": [  
"tcp://0.0.0.0:2376",  
"npipe://"  
],  
"tlskey": "C:\ProgramData\docker\certs.d\server-key.pem",  
"tlscert": "C:\ProgramData\docker\certs.d\server-cert.pem"  
}

download [https://github.com/jhowardmsft/docker-ci-zap](https://github.com/jhowardmsft/docker-ci-zap)

.\docker-ci-zap.exe -folder "C:\ProgramData\Docker\windowsfilter"

<!--kg-card-end: markdown-->