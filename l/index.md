---
layout: page
title: Link Directory
permalink: /l/
---

# Redirect Links

This directory contains redirect links managed through the blog. These links are generated automatically from `_data/redirects.yml`.

## Available Redirects:

{% for redirect in site.data.redirects.redirects %}
- [/l/{{ redirect.slug }}](/l/{{ redirect.slug }}) → {{ redirect.url }}{% if redirect.description %} - {{ redirect.description }}{% endif %}
{% endfor %}

---

*These redirects are managed in `_data/redirects.yml` and generated automatically during site build.*