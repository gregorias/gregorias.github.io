---
layout: post
title:  "I just want to access one file"
date:   2022-05-22 01:00:00
tags: blog
---
How do I enable a function to read and write to just one file? This post
explores some options I've considered.

I was writing [a program that needed to read and write a timestamp from a file
in order to ignore flake'y
programs](https://github.com/gregorias/ignore-flakes). I could have gone
classic imperative programming style and wrote functions like the following:

```haskell
ignoreFlakes :: FilePath -> IO ()
ignoreFlakes markFp = do
  -- Just do read/writes on markFp
```

That however wouldn't be the best way to write `ignoreFlakes`, because it has a
few disadvantages:

* The interface doesn't communicate what is being done to `markFp`. We only
  need to access a timestamp. We don't need full I/O capabilities.
* Testing is harder and it requires
  [medium-sized](https://testing.googleblog.com/2010/12/test-sizes.html) tests:
  our test rely on the filesystem.

## Object/interface style

It is a good practice to create minimal interfaces, so I started thinking about
idiomatic ways to represent the mark interface. I could have implemented an
imperative class analogue:

```haskell
data Mark = Mark {
  readMark :: IO UTCTime
  writeMark :: UTCTime -> IO ()
}
```

It still relies on the `IO` monad, but it no longer relies on the file system.
I can use `IORef` to hold the timestamp in-memory.

To ditch the `IO` monad, I could have made the monad into a parameter:

```haskell
data Mark m = Mark {
  readMark :: m UTCTime
  writeMark :: UTCTime -> m ()
}
```

That could have made it possible to use the state monad (`State UTCTime`) to
implement an in-memory mark. However, it's hard to see for me how callers could
be written generically to use such a mark. Perhaps they would also need to
accept the monad evaluation function:

```haskell
ignoreFlakes :: (m a -> IO a) -> Mark m -> IO ()
ignoreFlakes eval mark = eval $ do
  ts <- readMark mark
  --
  writeMark mark ts'

mkFileMark :: FilePath -> Mark IO
mkInMemoryMark :: Mark (State UTCTime)

ignoreFlakes id (mkFileMark fp) :: IO ()
ignoreFlakes (runState initTs) mkInMemoryMark :: IO ()
```

It's not the worst option, but the IO-version seems more ergonomical.

## Limited IO monad pattern

The approach presented so far is very much like an interface in OO programming.
Are there more FP approaches? Haskell is big on monads to encode effects.
Monads such as `IO` or `ST` expose read and write functions to files or refs
given a handle, so in my case there could be a monad that exposes reads/writes
to either a mark container or any mark containers identified by a handle.

```haskell
module MarkOnlyIO (
  MarkOnlyIO,
  runMarkOnlyIO,
  Mark,
  readMark,
  writeMark,
  createMarkFromFile,
  createMarkFromIORef
) where
data MarkOnlyIO a = MarkOnlyIO (IO a)
instance Monad MarkOnlyIO

data Mark = Mark {
  readMark' :: IO UTCTime
  writeMark' :: UTCTime -> IO ()
}

runMarkOnlyIO :: MarkOnlyIO a -> IO a
readMark :: Mark -> MarkOnlyIO UTCTime
writeMark :: UTCTime -> MarkOnlyIO ()

createMarkFromFile :: FilePath -> Mark
createMarkFromIORef :: IORef UTCTime -> Mark
```

```haskell
ignoreFlakes :: Mark -> MarkOnlyIO ()
```

This approach is more verbose, but limits the potential power of `ignoreFlakes`, which improves composability. It can be extended by parametrizing the base monad of `MarkOnlyIO`.

I don't see a use for this solution.
