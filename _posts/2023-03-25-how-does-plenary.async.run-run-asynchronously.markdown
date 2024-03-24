---
layout: post
title:  "How does plenary.async.run run asynchronously?"
date:   2023-03-25 11:00:00
tags: neovim plenary coroutine
---

[Neovim Plenary](https://github.com/nvim-lua/plenary.nvim)’s
[`async.run`](https://github.com/nvim-lua/plenary.nvim/blob/253d34830709d690f013daf2853a9d21ad7accab/lua/plenary/async/async.lua#L104)
seems to be doing an impossible trick. It starts a concurrent computation that
runs even after the main script has finished and calls the provided callback
once it's done. It seemed impossible to me, because Lua uses
[non-preemptive coroutines](https://www.lua.org/pil/9.4.html).
The caller needs to orchestrate when its coroutines can resume. So when the
main script is done, there should be nothing that can resume remaining
coroutines.

This note is my investigation into why this is happening. Surprise is important
for learning.

## Testing

I tested whether my understanding of the situation is accurate with the following script:

```lua
local a = require("plenary.async")

local function read_first_dir_entry()
  os.execute("sleep 2")
  vim.notify("Opening .")
  local fs, err = vim.loop.fs_opendir(".")
  if not fs then return vim.notify("Could not opendir: " .. err, vim.log.levels.ERROR) end
  vim.notify("Opened .")

  local readdir_err, entries = a.uv.fs_readdir(fs)
  vim.notify("After async.uv.fs_readdir")
  if readdir_err then vim.notify("Could not readdir: " .. readdir_err, vim.log.levels.ERROR) end
  if not entries then return end
  print(vim.inspect(entries[1]))
end

vim.notify("Before a.run")
a.run(read_first_dir_entry, function() vim.notify("Done") end)
vim.notify("After a.run")
os.execute("sleep 2")
```


Here's the execution that I got:

```
main         read_first_dir_entry
  │
  │Before a.run
  │
  └──────────────────┐sleep 2
                     │Opening .
                     │Opened .
  ┌──────────────────┘
  │
  │After a.run
  │sleep 2
  ▼
                     │After async.uv.fs_readdir
                     │Done
                     ▼
```

This confirms that I was right. `async.run` has some surprising ability to
continue created coroutines.

## Hypotheses
I analysed Plenary's codebase, and I couldn't find anything special that could explain this, so I started testing.

### Does Neovim Lua resume created coroutines until completion?
I checked if this behaviour is particular for Plenary. Perhaps there's some Neovim or Lua specific functionality that tries to resume all created coroutines.

```lua
local f = function()
  vim.notify("I'm in a thread 1.")
  coroutine.yield(1)
  vim.notify("I'm in a thread 2.")
  coroutine.yield(2)
  vim.notify("I'm in a thread 3.")
  return 3
end
coroutine.create(f)
```

This snippet didn't print anything, so no. Neovim's Lua doesn't try to complete all coroutines. It would be surprising if it did as such a functionality would be highly fragile. How would Lua know what arguments to pass through `resume`? What should happen if a coroutine never ends?

### Does `async.run` work with non-[Libuv](https://libuv.org/) coroutines?
It turns out that `async.run` doesn't work with plain coroutines. The following snippet prints an error:

```lua
local a = require("plenary.async")
local f = function()
  vim.notify("I'm in a thread 1.")
  coroutine.yield(1)
  vim.notify("I'm in a thread 2.")
  coroutine.yield(2)
  vim.notify("I'm in a thread 3.")
  return 3
end
a.run(f, function() end)
```

One lesson from it is that `async.run` is built to work with async wrappers around Libuv.

## Libuv's callbacks are the explanation
My current best explanation for this behaviour is that this asynchronous behaviour stems from [Neovim's Libuv implementation](https://neovim.io/doc/user/luvref.html). [Libuv][libuv] functions are truly asynchronous, because there's a long-running C thread in Neovim that runs an event-loop:

```
Neovim C thread      main        read_first_dir_entry
     │Start script
     └─────────────────┐
                       │
                       │Before a.run
                       │
                       └─────────────────┐sleep 2
                                         │Opening .
       schedules fs_readdir              │Opened .
      ◄───────────────────────────────── │async.uv.fs_readdir
                        ┌────────────────┘
                        │After a.run
                        │sleep 2
     ┌──────────────────┘
     │Runs fs_readdir
     │Calls callback
     └───────────────────────────────────┐
                                         │After async.uv.fs_readdir
                                         │Done
                                         ▼
```

This makes sense. [An event-loop](https://docs.python.org/3/library/asyncio-eventloop.html#asyncio-event-loop) is also how Python coroutines achieve their asynchronicity without a visible orchestrator.

What `async.run` does to simplify code by linearizing it is neat, however, this specific non-callback architecture has a limitation in that we can't create truly concurrent calls, e.g., we can't start two `fs_readdir` calls and resume once one of them has finished. [You can do this in Python](https://docs.python.org/3/library/asyncio-task.html#asyncio.wait), because in Python, you have lower level access to the event-loop.

[libuv]: https://libuv.org/
