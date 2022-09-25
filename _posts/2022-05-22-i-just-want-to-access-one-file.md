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
  our test relies on the filesystem.

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

### Generalising required effects

To ditch the `IO` monad, I could have made the monad into a parameter:

```haskell
-- m doesn't need to be a monad. It just needs to encode required effects
-- somehow.
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
-- Callers could accept an evaluation function
ignoreFlakes :: (m a -> IO a) -> Mark m -> IO ()
ignoreFlakes eval mark = do
  ts <- eval $ readMark mark
  --
  eval $ writeMark mark ts'

-- Callers could run only specific Marks
ignoreFlakes' :: Mark IO -> IO ()

-- Callers that don't need special effects could just run in the monad
foo :: (Monad m) => Mark m -> m a
foo eval mark = do
  ts <- readMark mark
  --
  writeMark mark ts'
  --

mkFileMark :: FilePath -> Mark IO
mkInMemoryMark :: Mark (State UTCTime)

ignoreFlakes id (mkFileMark fp) :: IO ()
ignoreFlakes (runState initTs) mkInMemoryMark :: IO ()
```

It's not the worst option, but the IO-version seems more ergonomical.

## Self-made monad
The approach presented so far is very much like an interface in OO programming.
Are there more FP approaches? Haskell is big on monads to encode effects.

### LimitedIO monad
One thing we could do is create a limitted version of the IO monad.
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

The limited IO approach is more verbose, but limits the potential power of
`ignoreFlakes`, which is safer.

This approach is quite uncomposable, we can't easily compose this with other
effects or monads. The only thing we can do with `MarkOnlyIO` is evaluate it to
`IO`.

### `MarkM` monad?

Maybe we can create `MarkM` monad with `readMark :: Something -> MarkM m
UTCTime`. We could possibly have a free monad, with `ReadMark`, `WriteMark`
constructors, but it doesn't seem possible to create a credible `MarkF`
functor. How would an `fmap` on `ReadMark` look like?
## Extensible Effects

The problem with creating a functor `MarkF` for a free monad can be overcome by
using [Polysemy][polysemy] as the free effect system doesn't require effects to be
functors. In fact, limited-resource access is [one of the prototypical
use-cases of
effects](https://haskell-explained.gitlab.io/blog/posts/2019/07/28/polysemy-is-cool-part-1/index.html).

```haskell
data MarkFile m a where
  ReadMarkFile :: MarkFile m UTCTime
  WriteMarkFile :: UTCTime -> MarkFile m ()

makeSem ''MarkFile

runMarkFileInMemory :: Sem (MarkFile : r) a -> Sem (PS.State UTCTime : r) a
runMarkFileInMemory =
  reinterpret
    ( \case
        ReadMarkFile -> PS.get
        WriteMarkFile content -> PS.put content
    )

runMarkFileOnDisk :: (Member (Embed IO) r)
                  => Sem (MarkFile : r) a
                  -> Sem (Input FilePath : r) a
runMarkFileOnDisk =
  reinterpret
    ( \case
        ReadMarkFile -> do
          filename <- P.input
          embed $ readFile filename
        WriteMarkFile content -> do
          filename <- P.input
          embed $ writeFile filename content
    )
```

I implemented it at [GitHub](https://github.com/gregorias/polysemy-mark).

The extensible effects approach is neat. I don't think it can be approved upon.

We avoid defining the effects required for the `MarkFile`, they are encoded in
interpreters. Same applies for encoding the source. This approach simplifies
callers that need a single mark file: `ignoreFlakes :: (Member MarkFile r) => Sem r ()`.

## Conclusion

The plain object/interface style or the extensible effects approach are the
only approaches that seem credible and would result in clean code. The
object/interface approach is not polymorphic, but it gets the primary job of
turning single-file manipulation into a visible dependency done. The fancy
monad solutions considered in-between all have deficiencies (primarily in
being hard to compose) that are solved by extensible effects.

[polysemy]: https://hackage.haskell.org/package/polysemy
