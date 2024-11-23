---
layout: post
title:  "Using coroutines in Neovim Lua"
date:   2024-10-20 11:00:00
tags: coroutine lua neovim
---
In this blog post:

- I describe the use of Lua coroutines in the context of Lua programming for
  Neovim.
- I provide generic converters from callback-based code for easy interaction
  with existing, non-coroutine codebases.

The big pay-off of using coroutines is making asynchronous code significantly
more readable.

## Motivation

[Neovim has adopted Lua as its de-facto config and plugin language.](https://neovim.io/doc/user/lua.html#Lua)
Neovim provides a standard library that is, unfortunately, callback-based
(e.g., [uv.fsopen](https://neovim.io/doc/user/luvref.html#uv.fs_open())).
This is unfortunate, because callbacks lead to significantly poorer readability.
Even if you avoid [the immediate problem of deeply-nested callback hells](https://web.archive.org/web/20240723133820/http://callbackhell.com/),
some constructs still end up way more complex.

Consider the use-case of grepping files in a directory.
We first get a directory listing, and then grep through each file. In a
synchronous setup, it’s a simple for-loop:

```lua
-- `ls_dir_sync` and `match_sync` are simplified API for listing a directory
-- and finding a match in a file. For example, `ls_dir_sync` could implemented
-- with `vim.uv.fs_scandir`.

function grep_dir_sync(dir, needle, cb) do
  for file in ls_dir_sync(dir) do
    if match_sync(file, needle) then
      return file
    end
  end
end
```

This is readable, but has the potential drawback of blocking the editor.
[A popular path completion plugin, cmp-path, suffers from this.](https://github.com/hrsh7th/cmp-path/pull/67)
When we address this flaw with callbacks, our code becomes egregious:

```lua
-- `ls_dir_cb` and `match_cb` use callbacks.

function grep_dir_cb(dir, needle, cb)
  ls_dir_cb(dir, function(entries)
    if is_empty(entries) then
      cb(nil)
    end

    local file = table.remove(entries, 1)
    match_cb(file, needle, function(match)
      grep_file_cb(match, file, entries, needle, cb)
    end)
  end)
d

function grep_file_cb(match, file, entries, needle, cb)
  if match then
    cb(file)
  end

  if is_empty(entries) then
    cb(nil)
  end

  file = table.remove(entries, 1)
  match_cb(file, needle, function(match)
    grep_file_cb(match, file, entries, needle, cb)
  end)
end
```

Modern languages solve this problem through the addition of async-await syntax
and an event loop
([JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function),
 [Python](https://docs.python.org/3/library/asyncio-task.html)).
Lua, somewhat uniquely, doesn’t have that kind of specialized syntax nor a
built-in event loop system, but it has coroutines that are designed in such a
way that you can use them to cleanly express your asynchronous code.

## Lua coroutines to the rescue

If you haven’t encountered Lua coroutines yet, then take a look at
[their brief documentation][lua-coroutine].
I’m going to assume you are familiar with it.

Before diving into coroutine use, let’s agree on nomenclature:

- A **coroutine function** is a Lua function that may yield with `coroutine.yield`.
- A **coroutine** (AKA **thread**) is the result of passing a
  **coroutine function** to `coroutine.create`.

This distinction is important. For example:

- `coroutine.resume` operates on **threads** and not on **coroutine functions**.
- **Coroutine functions** yield up to the level of their **thread** delimited by
  `coroutine.resume`.
- `coroutine.yield` can only happen within a **thread**.

Let’s now assume that we have coroutine versions of the filesystem API,
`ls_dir_co` and `match_co` ([I’ll show how to construct them shortly](#callbackcoroutine-conversion)).
`grep_dir_co` looks as follows:

```lua
--- Greps files in `dir` for `needle`.
---
--- This is a fire-and-forget coroutine function.
function grep_dir_co(dir, needle)
  for file in ls_dir_co(dir) do
    if match_co(file) then
      return file
    end
  end
end
```

This looks exactly like the synchronous version but is nonblocking, which is
a big win.

Lua’s coroutines are transparent.
All functions can be coroutine functions with no special syntax required.
They are also “contagious.”
Using a coroutine function inside a function makes the function into a
coroutine function, so it’s good to document that.
It’s a good practice to indicate that a function may yield by, for example,
adding a `_co` suffix.

We can use the coroutine functions _almost_ like a regular function by wrapping
it with a thread:

```lua
function find_and_print_co()
  local file = grep_dir_co("foo_dir", "needle")
  if file then
    print("Found the file: " .. file .. ".")
  else
    print("Could not find the file.")
  end
end

coroutine.resume(coroutine.create(find_and_print_co))
```

This code will asynchronously print a message with the result of the grep.

You might notice that we only call `coroutine.resume` once instead of resuming
the coroutine till it finishes. This brings us to the topic of
**fire-and-forget coroutine functions**.

### Fire-and-forget coroutine functions

[Lua introduces coroutines](https://www.lua.org/pil/9.html) as functions that
can yield (return) and resume multiple times.
You can use Lua coroutines like Python generators,
but that’s not how we’ll be using coroutines most of the time, because
our concern here is to use asynchronicity to deal with blocking I/O calls.

In our context, calls like `ls_dir_co` and `match_co` yield until the
corresponding I/O call is ready.
The **Neovim’s event loop** will _resume_ the corresponding thread when that is
the case. This pattern of control flow is so common for I/O operations that I
call such coroutines **fire-and-forget coroutine functions**.
You only resume such coroutines once from your Lua code,
and the event loop will resume them till the end.

```lua
function fire_and_forget(co)
  coroutine.resume(coroutine.create(co))
end
```

**fire-and-forget coroutine functions** are also contagious and should be
documented.

## Callback–coroutine conversion

So I promised to show you how to get `ls_dir_co` and `match_co`,
and I’ll do that by adapting `ls_dir_cb` and `match_cb`.
In fact, I can do so generically:

```lua
--- Converts a callback-based function to a coroutine function.
---
---@tparam function f The function to convert. The callback needs to be its
---                   first argument.
---@treturn function A coroutine function. Accepts the same arguments as f
---                  without the callback. Returns what f has passed to the
---                  callback.
M.cb_to_co = function(f)
  local f_co = function(...)
    local this = coroutine.running()
    assert(this ~= nil, "The result of cb_to_co must be called within a coroutine.")

    local f_status = "running"
    local f_ret = nil
    -- f needs to have the callback as its first argument, because varargs
    -- passing doesn’t work otherwise.
    f(function(ret)
      f_status = "done"
      f_ret = ret
      if coroutine.status(this) == "suspended" then
        -- If we are suspended, then f_co has yielded control after calling f.
        -- Use the caller of this callback to resume computation until the next yield.
        local cb_ret = table.pack(coroutine.resume(this))
        if not cb_ret[1] then
          error(cb_ret[2])
        end
        return cb_ret[]
      end
      -- If we are here, then the coroutine is still running, so `f` must have
      -- worked synchronously. There’s nothing for us to resume.
    end, ...)
    if f_status == "running" then
      -- If we are here, then `f` must not have called the callback yet, so it
      -- will do so asynchronously.
      -- Yield control and wait for the callback to resume it.
      coroutine.yield()
    end
    return f_ret
  end

  return f_co
end
```

`cb_to_co` is a mouthful. I simplified it slightly and omitted handling of
multiple returns, but you can see the full implementation in [coerce.nvim](https://github.com/gregorias/coerce.nvim/blob/4ea7e31b95209105899ee6360c2a3a30e09d361d/lua/coerce/coroutine.lua#L9-L55).

With `cb_to`, we can adapt any callback-based function.
We only need to ensure that the callback becomes the first argument:

```lua
ls_dir_co = cb_to_co(function(cb, dir) ls_dir_cb(dir, cb) end)
match_co = cb_to_co(function(cb, dir, needle) match_cb(dir, needle, cb) end)
```

In my codebases, I wrap existing callback-based APIs into such coroutine
functions and only use coroutines avoiding callbacks altogether.

### Coroutine to callback conversion

The last thing to discuss is the conversion from coroutines to callback-based
functions.
This is useful, because we don’t always want to just fire-and-forget like we
did with `find_and_print_co`.
Sometimes we can’t use coroutines, because our code needs to work with an
existing framework, where a non-coroutine function is expected
(AKA [the function-color problem](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/)).
In such cases, it is possible to turn a coroutine function into a
callback-based function like so:

```lua
--- Calls `cb` once the file has been found and printed.
function find_and_print_cb(cb)
    local co = function()
        fire_and_print_co()
        cb()
    end
    fire_and_forget(co)
end
```

## Conclusion

I hope that this post will make it more common for Lua code writers to use
coroutines. Coroutines are significantly easier to work with than callbacks and
it’s easy to adapt existing asynchronous APIs to coroutines.
Ubiquitous use of asynchronous programming should also make Neovim plugins less
likely to block.

## Addendum: What’s wrong with Plenary Async?

You might be aware of
[an attempt by Plenary to make asynchronous easy: `async.run`](https://gregorias.github.io/posts/how-does-plenary.async.run-run-asynchronously/).
I don’t think it’s a good library for a few reasons:

- `async` uses a complicated machinery that is hard to understand.
  It’s unnecessary, because native coroutines work just fine.
- The machinery is fragile.
  [You can’t even nest two coroutine functions](https://github.com/nvim-lua/plenary.nvim/issues/395),
  which is a pretty basic thing you’d want to do.

I’d say just stick to native coroutines.

[lua-coroutine]: https://www.lua.org/pil/9.html
