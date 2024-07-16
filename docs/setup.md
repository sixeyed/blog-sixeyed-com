
# Setup

For local dev.

## Pre-reqs

See: https://jekyllrb.com/docs/installation/macos/

```
brew install chruby ruby-install xz

ruby-install ruby 3.1.3

echo "source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh" >> ~/.zshrc
echo "source $(brew --prefix)/opt/chruby/share/chruby/auto.sh" >> ~/.zshrc
echo "chruby ruby-3.1.3" >> ~/.zshrc # run 'chruby' to see actual version
```

> Quit & restart terminal

## Jekyll

```
gem install jekyll bundler
```

From this folder:

```
bundle install
```

## Run locally

```
bundle exec jekyll serve
```

> http://localhost:4000