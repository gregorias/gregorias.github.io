---
layout: post
title:  "PixeloSolver - About the composability of Haskell monads"
date:   2015-04-02 22:00:00
uses_mathjax: true
tags: pixelosolver programming haskell
category: computer science
---

# PixeloSolver - An exercise in computer vision in Haskell

On one lazy evening I checked out what new flash games that have appeared on
Kongregate. That lead to me discover [Pixelo][pixelo] - a
[nonogram][nonogramwiki] puzzle game with well done GUI and lots of puzzles. I
really enjoy this kind of simple puzzles and there was also a badge for solving
a few of them. However due to the number of puzzles, I felt that I would be
wasting my time. Fortunately a nonogram puzzle has a simple solving strategy: in
each row find cells which are filled in all possible solutions or are not filled
in any. This check can be done independently from any other row. Now by
iteratively doing this check until the game is solved one can solve majority of
nonogram puzzles. This can easily be done by a computer. What's required is a
way to interact with the game. In this post I will explain how I have done it
Haskell and share some insights about how functional constructs make some ideas
simpler. I will especially focus on how monadic behavior helped make some idea
cleaner and more composable.

## I/O

Since the game itself does not provide any facilities for programmatic
communication the only way to play is to use the image that the game generates
by taking a screenshot, then recognize the board in the image, solve it, and
click out the solution. So first of all we need to check what Haskell has to
offer in terms of libraries.

Haskell provides a FFI interface to C, which has led many imperative libraries
to be ported into it. Most GUI libraries have a way to take a screenshot of the
screen and I chose wxHaskell as my go to library, because I knew it before from
Python and it is cross-plaftorm.

So in wxHaskell I take the screenshot and then I freeze it into an unboxed array
with RGB values so that I can later manipulate that screenshot. Here we get to
the first lesson I have gained.

### Composing IO loses laziness

wx gives as an FFI Pointer to an array of Word8 numbers for RGB values. We need
to transform it into more accessible Haskell array.

Initially I have done something like this:

{% highlight haskell %}
ptrToColorMap :: Int -> Int -> WXC.Ptr Word8 -> IO (UArray (Int, Int, Int) e)
ptrToColorMap width height p = do
  rgbAssocs <- fmap concat $ mapM (\(y, x) -> x `seq` y `seq` do
    red <- peekElemOff p (y * width * 3 + x * 3)
    green <- peekElemOff p (y * width * 3 + x * 3 + 1)
    blue <- peekElemOff p (y * width * 3 + x * 3 + 2)
    return [((y, x, 0), r), ((y, x, 1), g), ((y, x, 2), b)])
    (range ((0, 0), (height - 1, width - 1)))
  return $ listArray ((0, 0, 0), (height - 1, width - 1, 2)) rgbAssocs
{% endhighlight %}

So basically:

1. For each pixel position get RGB values and return 3 pairs of form: (index,
   value).
2. Use that association list to construct the unboxed array.

The mental model in my head was that the list would be lazy so that only after
`listArray` consumes the head and puts it in unboxed form to memory would the
rest of the list evaluate. Unfortunately this code lead to over 200MB memory
usage and a stack overflow. A quick calculation shows that the screenshot with
1920x1080 resolution should take $$1920\cdot 1080 \cdot 3 \approx 6MB$$.
The problem is that my model is invalid, similarly as in
[my previous post]({% post_url 2015-02-21-profiling-haskell %}). I forgot to
take into account the fact that before an IO monad evaluates all previous IO
actions need to be evaluated as well. So before `return` acts all monads
sequenced with `mapM` will be evaluated and the Haskell runtime will keep a list
with over 6 million unboxed elements in it.

This is a common pattern with IO. The general problem is that we have a pipeline
that accepts input and operates on it sequentially. We want to write that
pipeline in a composing way so that we have: `f :: x -> IO [y], g :: y -> IO
[z]` and we want to somehow compose `f` and `g` without running into the above
problem.  What's required is something like a yield:

{% highlight haskell %}
f x = do
  y0 <- doFst x
  yield y0
  y1 <- doSnd x
  yield y1
  y2 <- doTrd x
  return y2
{% endhighlight %}

This is impossible to do in bare bones Haskell, but there are powerful libraries
that do exactly that. For example [pipes][pipes] and [conduit][conduit].

Here fortunately the problem is small enough that I do not have to incorporate
those tools. Instead I just need to bring the process of putting produced values
into the array into the sequenced action:

{% highlight haskell %}
ptrToColorMap :: Int -> Int -> WXC.Ptr Word8 -> IO (UArray (Int, Int, Int) e)
ptrToColorMap width height p = do
  ioArr :: (IOUArray (Int, Int, Int) Word8) <-
    newListArray ((0, 0, 0), (height - 1, width - 1, 2)) (repeat 0)
  mapM_ (\(y, x) -> x `seq` y `seq` do
    red <- peekElemOff p (y * width * 3 + x * 3)
    green <- peekElemOff p (y * width * 3 + x * 3 + 1)
    blue <- peekElemOff p (y * width * 3 + x * 3 + 2)
    writeArray ioArr (y, x, 0) red
    writeArray ioArr (y, x, 1) green
    writeArray ioArr (y, x, 2) blue)
    (range ((0, 0), (height - 1, width - 1)))
  freeze ioArr :: IO (UArray (Int, Int, Int) Word8)
{% endhighlight %}

### Problems

Imperative GUI libraries are single-threaded and taking any GUI action needs to
take place in the main thread. However stuff unrelated to GUI should be done in
a separate thread so that the GUI is responsive. Here I have a problem, because
a way to do that in wx is with custom defined events yet in wxHaskell I can't
find any way to this. It seems like it wasn't imported into wxHaskell. This
causes the button in my application to be unresponsive, which is a small
problem.  The bigger problem is that the program leaks a lot of memory (100MB)
and this leak is solved only when I do not use wx GUI, only screenshot taking
capabilities.

A different kind of problem is that I couldn't find a cross-platform library to
click the mouse so I just use X11 for that.

## OCR

OCR is the largest part of the program, but here I'll talk only how Haskell's
glue made my construct more understandable and cleaner.

The OCR does not use any sophisticated machinery. Firstly it tries to recognize
the board by finding groups of white pixels in one dimension that are not too
far away from each other. Then it cuts strips with hints by checking where is
the last row/column with a black pixel. Then it cuts groups of black pixels and
tries to recognize which number it is by scanning it from top to bottom and
based on groups of black pixels it forms.

### Using standard glue

In my first try I felt that Haskell was awkward for this kind of program,
because I thought about my problems in terms of loops. For example given a strip
with hints I need to find the last row with black pixels, such that it is
followed `tolerance` number of rows without a black pixel. In imperative
language this might be done in a loop where we iterate over rows and accumulate
the number of consecutive rows without a pixel. Once `tolerance` is reached we
return the last seen black row. Here's how its done in a clunky fashion in a
Haskell function:

{% highlight haskell %}
findFirstHintRow' :: Int -> Int -> Int -> Map RGB -> Int
findFirstHintRow' currentRow lastBlackRow tolerance m
  | currentRow < 0 = 0
  | currentRow - lastBlackRow >= tolerance = lastBlackRow
  | otherwise =
    if any (\i -> (== black) . mapGet (currentRow, i)) $ m)
      $ mapGetRow currentRow m
    then trimColumnHintsStripe' (currentRow - 1) lastBlackRow
{% endhighlight %}

Ugly, isn't it? But this kind of problem can have much nicer declarative
description. Instead of thinking in terms of loops we might think like this:
We have a list of rows, each row either has a black pixel or not. What we want
to find is the last row such that after it there is a group of rows without a
black pixel of length at least `tolerance`. It seems as if I am saying the same
thing so let me paraphrase it again.

Given a list of rows we are only interested in **whether** they have a black
pixel or not. Then we are interested in **groups** of rows without a black
pixel.  We should **cut** the list of groups when we find a group without black
pixel and of length larger then `tolerance`. In the end we are interested in the
**length** of the strip so we should **sum up** what's left.

If it's still not clear then please look at the code:

{% highlight haskell %}
(height + 1 -)
. length
. concat
. takeWhile (\bs -> head bs == True || length bs <= tolerance)
. group
. map (\i -> hasRowBlack . getRow i)
$ reverse [0..height]

hasRowBlack :: (Row r RGB) => r RGB -> Bool
hasRowBlack r = any (== black) rowElems
  where
    size = rowGetSize r
{% endhighlight %}

Much nicer.

### Recognizing a digit

The last step in the OCR process is to recognize a number given a bitmap with
black and white pixels. The simplest and non-sophisticated way to do it is
to analyze what kind of groups of black pixels show up if we were to scan from
top to bottom. For example one is a list of the same group. Four has 
fork with two groups first, then a bar covering the entire bitmap, then one
group constituting the ending. If you want to see how would you fare with this
kind of information you may want to play [z-rox][zrox].

So to recognize a number we need state machine. Again doing that in a function
gave me an inelegant solution which does not compose.  Here's for example how I
recognized zero:

{% highlight haskell %}
data RecognizeZeroState = RecognizeZeroStart
  | RecognizeZeroFirstEnd (Int, Int)
  | RecognizeZeroMiddle (Int, Int) (Int, Int)
  | RecognizeZeroFinalEnd (Int, Int)

recognizeZero :: BWMap -> Maybe Int
recognizeZero bwMap =
  recognizeZero' RecognizeZeroStart (map (\i -> getRow i bwMap) [0..h])
  where
    h = fst . snd . bounds $ bwMap

recognizeZero' :: (Row r BW) => RecognizeZeroState -> [r BW] -> Maybe Int
recognizeZero' (RecognizeZeroFinalEnd _) [] = return 0

recognizeZero' _ [] = Nothing
recognizeZero' RecognizeZeroStart (r : rs) =
  case blackGroups of
    [b] ->
      if (fst b < middleW) && (snd b > middleW)
      then recognizeZero' (RecognizeZeroFirstEnd b) rs
      else Nothing
    _ -> Nothing
  where
    blackGroups = getBlackGroups r
    w = rowGetSize r
    middleW = w `div` 2

recognizeZero' (RecognizeZeroFirstEnd b) (r : rs) =
  case blackGroups of
    [b'] ->
      if ((fst b) >= (fst b')) && ((snd b) <= (snd b'))
      then recognizeZero' (RecognizeZeroFirstEnd b') rs
      else Nothing
    [b0, b1] ->
      if ((fst b) >= (fst b0)) && ((snd b) <= (snd b1))
      then recognizeZero' (RecognizeZeroMiddle b0 b1) rs
      else Nothing
    _ -> Nothing
  where
    blackGroups = getBlackGroups r

recognizeZero' (RecognizeZeroMiddle b0 b1) (r : rs) =
  case blackGroups of
    [b'] ->
      if ((fst b0) <= (fst b')) && ((snd b1) >= (snd b'))
        && (fst b' < middleW) && (snd b' > middleW)
      then recognizeZero' (RecognizeZeroFinalEnd b') rs
      else Nothing
    [b0', b1'] -> recognizeZero' (RecognizeZeroMiddle b0' b1') rs
    _ -> Nothing
  where
    blackGroups = getBlackGroups r
    w = rowGetSize r
    middleW = w `div` 2

recognizeZero' (RecognizeZeroFinalEnd b) (r : rs) =
  case blackGroups of
    [b'] ->
      if ((fst b) <= (fst b')) && ((snd b) >= (snd b'))
        && (fst b' < middleW) && (snd b' > middleW)
      then recognizeZero' (RecognizeZeroFinalEnd b') rs
      else Nothing
    _ -> Nothing
  where
    blackGroups = getBlackGroups r
    w = rowGetSize r
    middleW = w `div` 2
{% endhighlight %}

As you can see there's a lot of boilerplate, repetitive constructs and it's
completely non-composable. But again, this problem fits a pattern that many
others have faced. We are going through a list of elements and while we do that
we maintain state. In the end we are interested in whether the final state is
accepting. Such problem pattern is a typical job for parsers and Haskell has an
excellent general parsing library called [Parsec][parsec].

This is not a simple parsing library found in other languages, but rather a
parser combinator library. Thanks to Haskell's type system and design it
provides constructs for defining parser over any stream of data, maintaining any
state and which can to be evaluated in any context. Where by any I mean any can
be chosen. Here for example I'm parsing over list of groups of black pixels
(`[(Int, Int)]`) and the state is the last such parsed group (`(Int, Int)`).
Additionally while parsing I want to have access to width of the image (`Reader
Int`). So the Parser is:

{% highlight haskell %}
type DigitRecognizer = ParsecT [(Int, Int)] (Int, Int) (Reader Int)
{% endhighlight %}

Here's some of the new code for parsing zero and more.

{% highlight haskell %}
type BlackGroups = [(Int, Int)]
type RowWidth = Int

type DigitRecognizer = ParsecT [BlackGroups] BlackGroups (Reader RowWidth)

-- | Accepts any token that satisfies given predicate and saves the accepted
-- token in the state
blackGroupToken :: (BlackGroups -> Bool)
  -> DigitRecognizer ()
blackGroupToken predicate = tokenPrim show (\s _ _ -> incSourceColumn s 1)
  (\t -> if predicate t then return t else fail "")
  >>= putState

zero :: DigitRecognizer Int
zero = ellipse >> eof >> return 0

ellipse :: DigitRecognizer [()]
ellipse = many1 ellipseBeg >> many1 ellipseMid >> many1 ellipseEnd

-- | Accepts any group that might be the beginning of an ellipse
ellipseBeg :: DigitRecognizer ()
ellipseBeg = do
  s <- getState
  width <- ask
  case s of
    [] -> blackGroupToken (coveringMiddle width)
    [(xBeg, xEnd)] -> blackGroupToken
      ((&&) <$> coveringMiddle width <*> predicate)
      where
        predicate [(xBeg', xEnd')] = xBeg' <= xBeg
          && xEnd' >= xEnd
        predicate _ = False
    _ -> fail ""
  where
    coveringMiddle width [(xBeg, xEnd)] = xEnd > (width `div` 2)
      && xBeg < (width `div` 2)
    coveringMiddle _ _ = False
{% endhighlight %}

Now I can use parsers defined for parsing ends of ellipses to
recognize the number six:

{% highlight haskell %}
six :: DigitRecognizer Int
six = many ellipseBeg >> many1 leftEdge >> many1 ellipseMid
  >> many1 ellipseEnd
  >> eof
  >> return 6
{% endhighlight %}

The introduction of parsers not only made the code more comprehensible but also
shortened it by half.

Solving the game
----------------

The last piece of the program is solving the nonogram. The most important part
is generating all solutions for given row and merging them. Here I use the list
monad. The implementation of `xs >>= f` for list applies the `f` for each `x`
and returns concatenation of the result. This allows for clean expression of
algorithms that search through problem space.

{% highlight haskell %}
-- | generate possible solutions for a row/columns
generateSolutions :: [Int] -- ^ hints for this row/column
  -> [PixeloTile] -- ^ partially filled row/column
  -> [[PixeloTileFill]] -- ^ possible solutions
generateSolutions [] cs =
  if any (== Done Full) cs
  then []
  else [replicate (length cs) Empty]
generateSolutions [0] cs =
  if any (== Done Full) cs
  then []
  else [replicate (length cs) Empty]
generateSolutions _ [] = []
generateSolutions hints@(h : hs) constraints@(c : cs) =
  delayedSolutions ++ eagerSolutions
  where
    delayedSolutions =
      if c == Done Full
      then []
      else do
        solution <- generateSolutions hints cs
        return $ Empty : solution
    eagerSolutions = case maybeApplied of
      Nothing -> []
      Just (appliedHint, restOfConstraints) -> do
        solution <- generateSolutions hs restOfConstraints
        return $ appliedHint ++ solution
      where
        maybeApplied = applyHint h constraints

applyHint :: Int -> [PixeloTile] -> Maybe ([PixeloTileFill], [PixeloTile])
applyHint hint currentTiles =
  if doesHintAgree hint front
  then Just $ (take (length front) (replicate hint Full ++ [Empty]), rest)
  else Nothing
  where
    (front, rest) = splitAt (hint + 1) currentTiles

doesHintAgree :: Int -> [PixeloTile] -> Bool
doesHintAgree hint currentTiles =
  not
  $ length currentTiles < hint
    || any (== Done Empty) front
    || (length rest > 0 && head rest == Done Full)
  where
    (front, rest) = splitAt hint currentTiles
{% endhighlight %}


Monad composability
-------------------

Notice that the post is dominated by monads. First it was about composing an IO
monad to get a screenshot and what pitfalls it brings. Then it was about how
Parsec makes parsing simpler by making complex parsing more composable allowing
usage of smaller pieces. Then it was how using a list as monad makes
combinatorial solutions cleaner.

For the end of this post I would also like to point out that at first I thought
about IO monad as a *trick* that allows functional Haskell to introduce
impurity. Now I think that it is much more. First of all IO monad is about
adding effect to the computation of the value, just like most monads. Second of
all IO monads are more syntactically convenient to combine than a typical
imperative construct.

[pixelo]: http://www.kongregate.com/games/tamaii/pixelo
[nonogramwiki]: http://en.wikipedia.org/wiki/Nonogram
[github]: https://github.com/gregorias/pixelosolver
[pipes]: https://hackage.haskell.org/package/pipes
[conduit]: https://hackage.haskell.org/package/conduit
[zrox]: http://www.kongregate.com/games/evildog/z-rox
[parsec]: https://hackage.haskell.org/package/parsec

