# Grzegorz Milka's Blog

## Overview

This is the source repository for my personal blog.
The blog is hosted on GitHub Pages at
[https://gregorias.github.io](https://gregorias.github.io) and uses
[Jekyll](https://jekyllrb.com/) for site generation.

## Development

### Dev environment setup

1. Install [rbenv](https://github.com/rbenv/rbenv) and
   [direnv](https://direnv.net/) and hook them into your shell.
1. Allow `.envrc`.

   ```bash
   direnv allow
   ```

1. Install project dependencies:

    ```bash
    rbenv install
    gem install bundler
    bundler install
    ```
