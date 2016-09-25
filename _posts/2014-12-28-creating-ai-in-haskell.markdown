---
layout: post
title:  "Creating a minmax AI for Pentago board game in Haskell"
date:   2014-12-28 22:00:00
uses_mathjax: true
tags: pentago programming haskell
category: computer science
---

Motivation
==========

My roommate received a Pentago game for Christmas. She knew and liked it,
hence the gift, and wanted to try it out to me. Unfortunately for me, I really
dislike losing - I'm afraid it's a feeling more motivated by my egocentrism than
ambition - so I reluctantly agreed. I lost that game. "I'm a programmer not a
lowly player" - I could almost think to myself, and even before I started that
game I already knew that writing an AI that would play for me would be a good
Haskell starter project. Here I will explain how I have designed this program,
make some remarks about functional paradigm, and compare it to my experience with
imperative languages. This is not a tutorial or an introduction, more like a
notebook for some ideas and thoughts that occured while writing.

Pentago
=======
The Pentago is a game similar to gomoku.  It is played on a 6x6 board divided
into 3x3 squares. Each player takes turns placing one of his stones on the board
and rotating one of the squares by $$\frac{\pi}{2}$$. The player who gets 5 of
his stones in a row wins. So the game has a branching factor of
$$36 \cdot 8 = 288$$ (at the beginning much less due to symmetry, but it might
be counterproductive to check that in a program). Not a small number, but should
be doable to write a reasonably good AI to challenge an amateur.

<figure>
<img src="/images/2014/12/PentagoBoard.png" />
<figcaption>Pentago board</figcaption>
</figure>

The core idea is that the program will have a main menu that will allow the
user to choose players, human or artificial intelligence for each side, and
start a game. Then the program will display a board and wait for
moves from each player, which will be calculated by an AI or typed by a human,
displaying the board in-between. The AI will use
[minmax algorithm with alpha-beta pruning][minmax].

Once I had this rough sketch in my mind I started coding from bottom-up. First
the game logic - representing and manipulating the game.

Game logic
----------
The Haskell's expressive type system and naming should explain everything.

{% highlight haskell %}
module Pentago.Data.Pentago

data Player = BlackPlayer | WhitePlayer
  deriving (Eq, Ord, Show)

data Position = Empty | Black | White
  deriving (Eq, Ord, Show)

data Quadrant = RightTop | LeftTop | LeftBottom | RightBottom
  deriving (Eq, Ord, Show)

data RotationDirection = LeftRotation | RightRotation
  deriving (Eq, Ord, Show)

type BoardArray = Array (Int, Int) Position

type PlacementOrder = (Int, Int)

type RotationOrder = (Quadrant, RotationDirection)

type MoveOrder = (PlacementOrder, RotationOrder)

data Result = BlackWin | Draw | WhiteWin
  deriving (Eq, Ord, Show)

class GameState s where
  getBoardArray :: (GameState s) => s -> BoardArray
  getPossiblePlacementOrders :: (GameState s) => s -> [PlacementOrder]
  getResult :: (GameState s) => s -> Maybe Result
  makeMove :: (GameState s) => MoveOrder -> s -> s
  whoseTurn :: (GameState s) => s -> Maybe Player

isFinished :: (GameState s) => s -> Bool
isFinished = isJust . getResult

data SimpleGameState = SimpleGameState {
  simpleBoardArray :: BoardArray
} deriving (Eq, Ord, Show)
{% endhighlight %}

Thanks to type inference and terse syntax, creating and using new types is
quicker and more elegant than in Java or C++. So I didn't have any second
thoughts when I creating a type for a noun in game logic. The main class
representing the game is called a `GameState`. Initially it was a concrete data
type, but due to efficiency concerns I have created a type class for it and
later provided a few implementations. Here is only the simplest implementation,
`SimpleGameState` which stores the current state in a lazy array.

Notice that some GameState's functions, that is `getResult` and `whoseTurn`,
return Maybe types. If the game has not finished yet then `getResult` can not
return a result, but instead signals that the game is still in progress by being
equal to `Nothing`. Maybe allows cleaner and safer expressions of a common
pattern of returning a lack of value. This is the simplest example of the power
of sum types in functional languages. That is types that have alternative,
possibly completely different, constructors. In imperative languages a lazy or
practical programmer might just return null, risking a NullPointerException.
However it is nowadays more common to see this pattern in modern libraries and
languages. The eigth version of Java 8, which focuses on bringing the functional
paradigm goodies into its realm, has introduced a cumbersome implementation of
this idea in a form of a `Optional<T>` type. As a sidenote I'd like to point out
that having many small types increases the potential need for glue (conversion
functions), but it increases readability and safety. I think the tradeoff is
worth it.

AI
==

Players
-------
So we have written the representation and logic for the game. Now what's left is
how to play it. Our main loop will need to know what moves are being made. We
will hide that logic in `Player` type. Now what can a player type be?
It could be a function `(GameState s) => s -> s`, unfortunately that is too
restrictive. Haskell is referentially transparent, meaning that on the same
input the function returns the same output, therefore when provided a given
state the player will always return the same state. This does not allow to
represent a human player who will make his decision at the time the state is
provided. So instead we have to make the player a function which returns a
computation of the next state and by computation I mean a monad:
`(GameState s, Monad m) => s -> m s`. Once provided a state, the player will
provide a computation that when evaluated will return the next state. In code this
looks as so:

{% highlight haskell %}
type Player m s = s -> m s

type HumanPlayer s = Player IO s

type AIPlayer s g = Player (State g) s
{% endhighlight %}

So a `HumanPlayer` wraps the computation in an IO monad, which will wait until
he types his move. `AIPlayer` on the other hand uses a random number generator,
so that he can provide a variety into his plays.

Notice that there are no type classes inside these definitions. This comes from
a limitation in a Haskell 2010. On default, Haskell function does not allow
for a function to return a polymorphic function, like for example:

{% highlight haskell %}
-- | Given integer return any requested player function.
player :: Int i -> forall s . (GameState s, Monad m) s -> m s
{% endhighlight %}

If Haskell allowed for a typeclass specification inside a type synonym than it
would have to allow for:

{% highlight haskell %}
player' :: Int i -> Player m s
{% endhighlight %}

As is usually the case GHC has an extension which removes this obstacle:
`-XRank2Types` and `-XRankNTypes`.

MinMax
------
AIPlayer uses minmax algorithm to calculate the best move. Here's where
laziness, sum types, first-order functions allow us to create a very cohesive
and modularized code. Let's start from the top.

The entire mechanism has to traverse a game tree, evaluating the game score
at leaves, and finding the best move which maximizes or minimizes the score.
Since the number of potential game states is large the tree has to be
pruned, cut-off at small enough depth.

There are at least 3 different operations in this specification. First of
the essence of maximize and minimize operations is traverse of game
state tree with getting scores. Having that the rest of type specification is a
technicality, my solutions looks like this:

{% highlight haskell %}
-- |Tree with values only in leaves
data LeafValueTree e v = Node [(e, LeafValueTree e v)] |
                         Leaf v

-- |ScoreMoveTree
type SMTree e v = LeafValueTree e v

maximize :: (Bounded v, Ord v) => SMTree e v -> (v, Maybe e)
{% endhighlight %}

Thanks to the laziness, the nodes will be evaluated only as needed and, on
correct maximize implementation, unused nodes will be garbage collected after
traversal. 

Now, how do we get this tree? We have to generate it recursively:

{% highlight haskell %}
-- |Tree with edges
data EdgeTree e v = ValueNode v [(e, EdgeTree e v)]
  deriving (Show) 

type PentagoGameTree s = EdgeTree MoveOrder s

-- | Generate complete game tree from current state to all possible states
generatePentagoGameTree :: (GameState s) => s -> PentagoGameTree s
generatePentagoGameTree gameState
  | isFinished gameState = ValueNode gameState []
  | otherwise = ValueNode gameState (map (fmap generatePentagoGameTree)
    childStatesWithMoves)
  where 
    possibleMoveOrders = getPossibleMoveOrders gameState
    childStatesWithMoves = map
      (\moveOrder -> (moveOrder, makeMove moveOrder gameState))
      possibleMoveOrders
{% endhighlight %}

This function creates the complete tree, but again. Since Haskell is lazy and we
use lazy-friendly functions such as map, that tree will be evaluated only when
needed.

Since we do not want to run minmax on a complete tree, we have to prune it a
bit:

{% highlight haskell %}
prune :: Int -> PentagoGameTree s -> PentagoGameTree s
prune 0 (ValueNode a _) = ValueNode a []
prune d (ValueNode a xs) = ValueNode a $ map (fmap $ prune (d - 1)) xs
{% endhighlight %}

There's one step left, how to assign scores to nodes. If the state is final it's
easy. Assign 1 if white wins, otherwise -1. In case of a non-final state we may
assign 0.0 or try to estimate. For example by playing multiple random games and
averaging their results. Anyway the types for evaluation look as so:

{% highlight haskell %}
type PentagoEvaluationTree = LeafValueTree MoveOrder Score

type GameStateEvaluation s = s -> Score

evaluateTree :: GameStateEvaluation
  -> LeafValueTree MoveOrder s
  -> PentagoEvaluationTree
evaluateTree = fmap
{% endhighlight %}

In the end the entire minimax algorithm mechanism is a composition of all those
parts:

{% highlight haskell %}
maximizeState = 
      maximize
      . evaluateTree randomPlayEvaluate
      . toLeafValueTree
      . prune depth
      . generatePentagoGameTree 
{% endhighlight %}

In an imperative language we would probably implement all those steps inside one
method. Haskell allows as to succintly express the essence of this algorithm.
This advantage comes from the fact that part of the control in the program
(laziness and garbage collection) is handled by the language itself, more
declarative languages would perhaps allow us to write some ideas even more
succintly, perhaps focusing only on data representation and rules for data
derivation.

Reliance on laziness and garbage collection comes with some overhead.
Fortunately Haskell is very well optimized, rivaling C/C++ on some
applications. Also often it's easier to optimize cleaner code and it might be
that C/C++'s theoretical maximal performance is higher than for haskell, but
this difference is often small enough that Haskell's smaller maintance overhead 
highly tips the weights to its favour.

Note that in case of more complicated data/control flow, the code will have to
be uglier for performance sake. For example what if the tree is needed somewhere
else and evaluated nodes will node be garage collected? We might then use
immutability and simply give `maximizeState` a copy of the tree. But then what
if evaluating state is expensive and we may want to cache some results? We need
  to again reconsider the essence of the mechanism and introduce some accidental
complexity.

I highly recommend reading ["out of the tar pit" paper][outoftarpit].
It constructs a clean and elegant programming paradigm from first
principles, explaining the relationship between accidental and essential
complexity, data/logic and control flow, and performance. It brings a lot of
insight into the core of complicated systems.

Also the minmax construction you see here was perhaps influenced by another
great paper: ["Why functional programming matters"][whymatters]. It is a good
read into reasons why functional programming paradigm is considered important
and should be learned by programmers.

Final notes
===========

The implementation of this game is available on [my Github page][github].

Main menu
---------

The main menu is implemented as a set of monads with monad transformers. Each
submenu uses only the monad it needs. A `Reader IO` where only configuration is
needed, `StateT MainMenuState IO` for stateful menu with changing configuration.
Since I want the `runGame` monad which runs the game to work well with any type
of player, without custom checking for its type, I need to wrap them into a
monad that may handle them all:

{% highlight haskell %}
type PlayerWrapperMonad = StateT StdGen IO
type PlayerWrapper s = Player PlayerWrapperMonad s

aiPlayerWrapper :: (GameState s) => AIPlayer s StdGen -> PlayerWrapper s
aiPlayerWrapper aiPlayer board =
  do
    gen <- get
    let (newState, newGen) = runState (aiPlayer board) gen
    put newGen
    return newState

humanPlayer :: (GameState s) => HumanPlayer s
humanPlayer currentGameState = do
  putStrLn moveHelp
  moveOrder <- readMoveOrder
  return $ makeMove moveOrder currentGameState

humanPlayerWrapper :: (GameState s) => PlayerWrapper s
humanPlayerWrapper = lift . humanPlayer
{% endhighlight %}

I don't know if there is a cleaner solution than that. If there ever comes another
type of a player I need to provide a wrapper type implementation for it. It may
sound nit-picky, but provides a small sense of inelegance.

Optimizations
-------------
The final version of the program has to optimize a few things.

### Smarter game states

If we were to use simple board state for everything we might notice that it
would often do redundant computation. Calculating results, possible moves
etc. has to be done multiple times and is time consuming. Therefore we might
want to use a game state which stores this information once calculated. This is
done by `SmartGameState`.

{% highlight haskell %}
-- | GameState which uses unboxed array as board representation and store
-- evaluation of some functions.
data SmartGameState = SmartGameState {
  smartBoardArray :: UnboxedBoardArray
  , possiblePlacementsOrders :: [PlacementOrder]
  , result :: Maybe Result
  , turn :: Maybe Player
} deriving (Eq, Ord, Show)
{% endhighlight %}

It also uses `UArray` storing Chars underneath. It's strict, but faster and we
need the entire board anyway.

### MoveOrder shuffling

The order in which moves are traversed matters. Originally I had the following
implementation of tree generations.

{% highlight haskell %}
generatePentagoGameTree gameState
  | isFinished gameState = ValueNode gameState []
  | otherwise = ValueNode gameState (map (fmap generatePentagoGameTree)
    uniqueChildStatesWithMoves)
  where 
    possibleMoveOrders = getPossibleMoveOrders gameState
    childStatesWithMoves = map
      (\moveOrder -> (moveOrder, makeMove moveOrder gameState))
      possibleMoveOrders
    uniqueChildStatesWithMoves = nub `on` snd . sort `on` snd
      $ childStatesWithMoves
{% endhighlight %}

This implementation reduces the number of child states by removing the
duplicates. This caused the move orders to group by rotation order. If you have
played a Pentago game then you might know that rotation is more "powerful" then
placement. That is more often than not the winning is done by forcing the
opponent to rotate two quadrants at once to prevent the winning move, not by
blocking his placement. So if we group move orders by rotation we might be
unlucky and have the more forceful rotations at the end of traversed orders.

Eliminating this instruction, although increases the number of states, it
decreases the computation time and performs much better with alpha-beta pruning.

Additionally I have also added a shuffling method, which effectively increases
the performance by randomizing the order of move orders.

Haskell build tools
-------------------
Since it was my first non trivial project in Haskell for a long time I decided
to use proper build tools. In the case of Haskell the choice is simple: Cabal.
Cabal is a package manager and build tool. It handles package dependency,
linking, compilation, and documentation phases of the build.

I have written a little bit about Gradle and have to say that Cabal is a bit of
a disappointment. It doesn't provide much flexibility and tasks it performs have
to adhere to Cabal templates for a project.

### Dependency hell

As in any package manager dependency versions can mismatch. Gradle and Ivy
provide a way to specify custom rules which packages should be used, if they do
older versions do not conflict with newer ones then the project will compile.

In Haskell this problem is exacerbated due to its very strong typing. There are
currently two semi-solutions to this problem:

* Using a package repository which maintains stable snapshots of all packages.
  That is packages which dependency are known to form a stable, non-conflicting
  forest. This is for example done by stackage:
  [Stackage](http://www.stackage.org/)

* Since last year cabal implements sandboxes that is a project can
  have its own set of dependency packages, independent from the system packages.

  Sandbox is created and initialized using the sandbox command:

      cabal sandbox init
      cabal install --only-dependencies

That would be it for this blog post. I have explained how to think about some
ideas in Haskell to write a small application. Now looking back through the post
you might say that all I have done is explain the types behind it. There's still
a lot of code around it. I think that in most cases, where the software does not
perform computationally complex stuff, designing the API and architecture is 90%
of the creative work and the rest, if the core is properly designed, follows
easily.

[minmax]: https://en.wikipedia.org/wiki/Minimax
[github]: https://github.com/gregorias/Pentago
[outoftarpit]: https://github.com/papers-we-love/papers-we-love/blob/master/design/out-of-the-tar-pit.pdf?raw=true
[whymatters]: https://github.com/papers-we-love/papers-we-love/blob/master/functional_programming/why-functional-programming-matters.pdf
