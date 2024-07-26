# Grzegorz Milka’s Blog

This is the source repository for my personal blog.

The blog is hosted on GitHub Pages at
[https://gregorias.github.io](https://gregorias.github.io) and uses
[Jekyll](https://jekyllrb.com/) for site generation.

## Development

### Dev environment setup

1. Install [rbenv](https://github.com/rbenv/rbenv) and
   [direnv](https://direnv.net/) and hook them into your shell.
1. Install Lefthook.

   ```bash
   lefthook install
   ```

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

### Testing

To preview your drafts, run

```shell
jekyll serve --drafts
```

This will run a local server instance with live updates.

### Build

To build the static website before release, run

```shell
jekyll build
```

### Updating dependencies

#### Updating Ruby

To update the used Ruby version:

1. Update `.ruby-version`.
2. Update `.github/workflows/jekyll-build-and-deploy.yml`.
3. Clean currently generated files and regenerate them:

    ```bash
    git clean -xdf
    bundler install
    just build

### Updating gems

To update the used Bundler, delete the lockfile and regenerate with
`bundler install`.
