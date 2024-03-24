---
layout: post
title:  "Parsing Recipe Pattern"
date:   2023-12-29 11:00:00
tags: haskell parsing
---
This note introduces **the parsing recipe pattern**. This Haskell parsing
pattern addresses the newtype proliferation problem that arises with
typeclass-based generic parsers like Cassava or Aeson. At the same time, the
recipe pattern keeps the ergonomy of auto-deriving parsers.
It’s a pattern I haven’t seen yet anywhere else as of December 2023 , and I
think it could be a good addition to Haskell’s parsing ecosystem.

## Motivation

I develop a personal Haskell utility that parses financial statement data from
various institutions ([findata-transcoder]). In that problem domain,
statements use all kinds of formats that I need to parse:

```plaintext
# coop.csv — A supermarket sale record
"13/02/2023","Sale","Coop","$1234.56"

# bank.csv — A bank deposit record
"Jan 16, 2023", "Deposit", "900.12 USD"

# broker.json — A forex transaction
{
  date: "2023-12-02",
  name: "Forex",
  from: "USD",
  // ...
}
```

For each financial statement, I create record type that represents a single
record in a statement (most statements are collections of records) and create a
parser for it.

```haskell
data FooRecord = FooRecord
  { frDay :: Day
  , frTitle :: Text
  }

parseRecord :: Text -> Maybe FooRecord
parseStatement :: Text -> Maybe [FooRecord]
```

Haskell already has a strong ecosystem for writing parsers using
[monadic parser combinators][megaparsec]. This is one of the reasons why
I chose to use Haskell for this problem. However, the existing functionality
was somewhat lacking for me.

### Existing Parsing Approaches

#### Megaparsec

A Parsec-derived library [Megaparsec][megaparsec] is a swiss-army knife. It can
handle parsing most things imaginable, but it’s low-level. It requires you to
write your own record parsers like so:

```haskell
fooRecordP :: Parsec Void Text FooRecord
fooRecordP = do
  day <- dayP
  MP.char ','
  title <- titleP
  return $ FooRecord day title
```

That’s tedious and boilerplate’y. If our record type’s structure already
follows its CSV row structure, then couldn’t we somehow autogenerate a parser?
The answer is yes.

### Cassava and Aeson

[Cassava][cassava] and [Aeson][aeson] are high-level parsing libraries for CSV
and JSON files respectively. One of their features is that one can get a parser
for free based on the record type:

```haskell
deriving stock instance Generic FooRecord

-- The default implementation uses the generic instance to
-- figure out the structure of the JSON object.
instance FromJson Record
```

```haskell
-- This now works
>>> decode "{ \"frDay\": \"2023-11-12\", \"frTitle\": \"Foo\" }"
FooRecord { -- ...
          }
```

The big drawback to these high-level libraries is that they are based on type
classes. We tie a type to how its parsed. For record types that’s fine but it’s
not so much for primitives. In the motivating example we saw how different
financial institutions have different standards for formatting things like
dates, monetary amounts, numbers, etc. The solution to this is using the
newtype pattern to have different parsing instances, but it then
leads to record types like this:

```haskell
data CharlesSchwabRecord = CharlesSchwabRecord {
  day :: CharlesSchwabDay,
  amount :: CharlesSchwabAmount,
  -- ...
}

data InteractiveBrokersRecord = InteractiveBrokersRecord {
  day :: InteractiveBrokersDay,
  amount :: InteractiveBrokersAmount,
}

-- Note: there are other approaches, but none of them satisfactory.
```

We are polluting core business logic with different day types that only differ
in how they are parsed. That’s neither ergonomical nor elegant.

The challenge here is to devise a generic parsing engine that will combine the
benefits of Megaparsec and Cassava/Aeson:

1. Allow defining pure record types without tightly coupling them to a specific
   parsing implementation.
2. Allow defining parsers as terms, so that we can freely change parsing
   implementations without changing the record type. We want what Megaparsec
   does with its `Parsec` terms.
3. Keep the ergonomics of automatically deriving parsers from a record’s type structure.

## Parsing Recipe Pattern

Let’s start with a sketch of what a solution to those three design goals might
look like:

```haskell
-- | The pure record type.
data FooRecord = FooRecord
  { frDay :: Day
  , frTitle :: Text
  }

-- | The higher-kinded type version of FooRecord.
data FooRecordH f = FooRecordH f
  { frrDay :: f Day
  , frrTitle :: f Text
  }

-- | A recipe of a record is a record of parsers
type FooRecordRecipe = FooRecordH Parser

-- | A recipe that uses ISO 8601 for the day format.
exampleFooRecordRecipe :: FooRecordRecipe
exampleFooRecordRecipe = FooRecordRecipe iso8601DayP textP

-- | Cooks any recipe into a parser of the record
cook :: recordH Parser -> Parser (recordH Identity)
cook = _cook

-- | Collapses FooRecordH into the record type.
--
-- Useful for ergonomics to be combined with cook: fmap toFooRecord . cook
toFooRecord :: FooRecordH Identity -> FooRecord
toFooRecord (FooRecordH (Identity d) (Identity t)) = FooRecord d h
```

The sketch above shows the essence of the recipe pattern:

- We have **recipes**: a higher-kinded type variant that represents a record of
  field parsers.
- We have the process of **cooking**. Cooking translates a **recipe** into the
  desired parser of a record. What makes the **cooking** process special is
  that it takes into account row parsing details, e.g., that fields need to
  be separated by a comma (e.g., for CSV cooking) or that records need to be
  surrounded by braces (for JSON parser cooking).

Within this scheme, the only thing a programmer needs to do is define the
higher-kinded type of their record and provide a parsing recipe. `cook` will be
a generic function. It's implemented it once per file format.
There’s some higher-kinded type related boilerplate that can be further
eliminated by [Barbies][barbies]. I didn’t do it in this post to keep the
number of concepts manageable.

### Kitchen

What’s left to do to is show how to implement `cook`. We’ll do it using
generics. For simplicity, I’ll focus on a CSV-specific implementation, but the
pattern can work with any kind of parser.

Let’s first implement cooking for generics:

```haskell
type CsvParser = MegaParsec.Parsec Void Text

-- If we are given a generic recipe, we can cook it.
--
-- Ignore (k -> Type) and `a`'s. Those are Generic's curiosities.
class GCsvCookable (repRecipe :: k -> Type) (repFood :: k -> Type) where
  gCook :: repRecipe a -> CsvParser (repFood a)

-- Throw away any metadata you may encounter.
instance (GCsvCookable recipe food)
   => GCsvCookable (M1 i c recipe) (M1 i c food) where
  gCook (M1 x) = M1 <$> gCook x

-- The moment you encounter a product type (i.e., fields of a record),
-- separate them with comma.
instance
  ( GCsvCookable recipe0 food0
  , GCsvCookable recipe1 food1
  ) =>
  GCsvCookable (recipe0 :*: recipe1) (food0 :*: food1)
  where
  gCook (a :*: b) = do
    ra <- gCook a
    void $ MP.char ','
    rb <- gCook b
    return $ ra :*: rb

-- The moment you encounter a recipe field, parse it with the field's recipe.
--
-- Note that we only implement GCsvCookable for fields of type `CsvParser food`.
-- If we try to cook a record type that is not a recipe, compilation will fail.
instance GCsvCookable
    (K1 Generic.R (CsvParser food))
    (K1 Generic.R (Identity food)) where
  -- Optionally, we may also consider optional unwrapping from quotes.
  -- We don't do it in this example.
  gCook (K1 a) = K1 . Identity <$> a
```

Now we implement the cooking default for any generic type that has a
recipe-like structure:

```haskell
-- The generic implementation for cooking.
gCookDefault ::
  ( Generic recipe
  , Generic food
  , GCsvCookable (Generic.Rep recipe) (Generic.Rep food)
  ) =>
  recipe ->
  CsvParser food
gCookDefault recipe = Generic.to <$> gCook (Generic.from recipe)

-- We can make the structure of recipes and food clearer in `cook`.
cook ::
  ( Generic (recordH CsvParser)
  , Generic (recordH Identity)
  , GCsvCookable (Generic.Rep (recordH CsvParser))
                 (Generic.Rep (recordH Identity))
  ) =>
  (recordH CsvParser) ->
  CsvParser (recordH Identity)
cook = gCookDefault
```

Voila, bon appétit.

You can check the full implementation at [my GitHub](https://github.com/gregorias/parsing-recipe).

## Further Extensions

In this example, I’ve showcased the recipe pattern for a constrained problem of
parsing unnamed CSV records. The machinery though (which I like to call **the
kitchen**) can be made significantly more generic to accommodate named CSV
records, JSON objects or arrays. The `CsvParser` type can be made into any kind
of monad or possibly even a monad transformer.
The way to do this is to make `GCsvCookable` into a more generic class and give
`gCook` more parameters that could control things like separators, wrappers,
and other record-level options.

## Related work

I haven’t seen this particular pattern documented before, but it’s built on the
shoulders of giants.

I’ve already mentioned Cassava and Aeson. There’s also [Tomland][tomland].
Libraries like those rely heavily on generics to provide default parser
implementations. They don’t seem to facilitate the use of **recipes** or HKTs
though.

### bsequence

In Barbies, there’s already
[`bsequence`](https://hackage.haskell.org/package/barbies-2.0.5.0/docs/Data-Barbie.html#v:bsequence-39-),
which has a similar type signature as our `cook`:

```haskell
bsequence' :: (Applicative e, TraversableB b) => b e -> e (b Identity)
```

The difference lies in `GCsvCookable` which a parsing-specific alternative for
`TraversableB`. which is adjusted specially for parsing.

Barbies also has an ingenious naming approach, which helps working with the
library. It inspired me to do the same for the recipe pattern.

### Blog Posts

[“Higher Kinded Option Parsing” by Chris
Penner](https://chrispenner.ca/posts/hkd-options) shows the use of HKTs to
extract data from an environment, to combine with defaults, and then have a
pure option type to work with. All of these operations are relevant to recipes
and higher-kinded record types as well. Chris doesn’t however go into how HKTs
can help with parsing records.

[aeson]: https://hackage.haskell.org/package/aeson
[barbies]: https://hackage.haskell.org/package/barbies
[cassava]: https://hackage.haskell.org/package/cassava
[findata-transcoder]: https://github.com/gregorias/findata-transcoder
[megaparsec]: https://hackage.haskell.org/package/megaparsec
[tomland]: https://hackage.haskell.org/package/tomland
