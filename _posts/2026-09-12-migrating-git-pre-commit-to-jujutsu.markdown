---
layout: post
title: "Migrating Git pre-commit to Jujutsu"
date: 2026-09-12 02:00:00
tags: git jujutsu
---

This note explains my solution of migrating a Git pre-commit workflow to
Jujutsu.

## Problem: no hook-support in Jujutsu

I used to use Git’s pre-commit hook (powered by [Lefthook][lefthook]) to run
linters, formatters, and tests as a form of guarantee that each commit passes
rudimentary sanity checks.
The hook wasn’t foolproof.
Rebases could, in effect, modify a commit without running the pre-commit hook.
Nevertheless, the hook served as a foundation of my CI workflow.

Since I switched to Jujutsu, I can no longer use the hook, because Jujutsu
doesn’t support hooks.
This is a major feature gap in Jujutsu that for a moment made me question
whether Jujutsu is worth switching to.
I eventually concluded that Jujutsu is just too good and that I can live without
hook support; at least for a while.

Even if Jujutsu came with hooks in the future, the pre-commit hook doesn’t make
much sense in Jujutsu’s model:
Jujutsu changes are meant to be fluid.
Jujutsu snapshots file changes to the working copy as they come, and it’s why
Jujutsu works so well.

## New workflow

My Jujutsu CI workflow now consists of two components:

1. Set up change-level checks through VCS-agnostic scripts.
2. Set up JJ aliases for checking to-be-submitted changes during push events.

### Decouple checks from VCS (`just check`)

It’s a good idea to have a local command for running checks that you can run
independently from your VCS.
I like [Just][just] for this purpose (it provides completion and easy grouping
of commands).
In addition to defining a command for each check, I set up a catch-all `check`
command for running all change-level checks.

For example, my Lefthook command for formatting Fish files

```yaml
pre-commit:
  commands:
    fish-indent:
      tags: style
      files: git diff --name-only --cached --diff-filter=AM
      glob: "*.fish"
      run: fish_indent -c {files}
```

became:

```just
check: check-fish check-markdown lint-lua test

# Check Fish files formatting
check-fish:
    fd -e fish -X fish_indent -c
# Format Fish files
format-fish:
    fd -e fish -X fish_indent -w
```

We lose the convenience of running the test on just changed files, but either
that’s not a problem on small repos or we can reimplement fetching the file diff
for the pre-push check.

### Jujutsu pre-push aliases

It is no longer a good idea to run checks on each commit change.
In my workflow, those checks are moved to the push event.
`git push` marks changes as immutable, so it’s the best time to verify if they
pass tests.

Jujutsu doesn’t have hooks, so instead I define repo-local aliases:
`check` and `ship`.
The former runs `just check` on all changes between the working copy and remote
bookmarks.
The latter runs `jj check` before `jj git push`.

```shell
jj config set --repo 'aliases.check' '["run", "--ignore-changes", "-r", "(remote_bookmarks()..@-) ~ root()", "--", "just", "check"]'
jj config set --repo 'aliases.ship' '["util", "exec", "--", "sh", "-c", "jj check && jj git push", "ship"]'
```

Overall, this setup provides a reasonable guarantee that I do not ship broken
changes.

You can also wrap these aliases into a script and track them inside the repo to
make sure that when you change them, fixes are transferred across repos:

```shell
jj config set --repo 'aliases.check' '["util", "exec", "--", "sh", "-c", "\"$JJ_WORKSPACE_ROOT/scripts/check.sh\" \"$@\"", "check"]'
jj config set --repo 'aliases.ship' '["util", "exec", "--", "sh", "-c", "\"$JJ_WORKSPACE_ROOT/scripts/ship.sh\" \"$@\"", "ship"]'
 ```

## Alternatives considered

### Using pre-push Git hook

We could have translated our pre-commit into pre-push checks per uploaded commit
like so:

```sh
#!/bin/sh

set -e

remote="$1"
url="$2"
zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')

while read local_ref local_oid remote_ref remote_oid; do
  if test "$local_oid" = "$zero"; then
    # Handle delete
    continue
  fi

  if test "$remote_oid" = "$zero"; then
    # New branch, examine all since main.
    range="main..$local_oid"
  else
    # Update to existing branch, examine new commits
    range="$remote_oid..$local_oid"
  fi

  echo "Verifying every commit in $range…"

  for commit in $(git rev-list "$range" --reverse); do
    git checkout $commit
    just check || exit 1
  done
  git checkout $local_oid
done
```

This would have avoided having to create another JJ subcommand and having to
remember to call it.
Unfortunately, `jj git push` ignores Git hooks.
We shouldn’t just call `git push` by itself, because it is a mutating Git
command, and we shouldn’t call those in a colocated repo.

### Using Jujutsu fix

Jujutsu comes with the `fix` command that we can certainly utilize, but that
command is meant for formatting.
It is not meant to run checks, which include linters and tests.

An additional problem with the `fix` feature is that it doesn’t sync across
repositories.

### Using `jj-hooks` and similar

The community has published tools for solving this problem, e.g.,
[jj-hooks][jj-hooks], but I found them at too much risk of becoming abandonware.
In my assessment, it’s better to have a small, “works-most-of-the-time” setup
and wait for some officialish support than couple one’s workflow to small,
non-trivial tools.

### Using GitHub Actions

We could use GitHub Actions to run tests, but I believe in local-first developer
experience.
One should be able to work even when Internet cuts off in a train tunnel.

## Learn more

Abysmal support for lifecycle/CI hooks compared with Git is an open problem at
Jujutsu:
[#405: Integrate with pre-commit.com][jj-405].

[jj-405]: https://github.com/jj-vcs/jj/issues/405
[jj-hooks]: https://crates.io/crates/jj-hooks
[just]: https://github.com/casey/just
[lefthook]: https://github.com/evilmartians/lefthook
