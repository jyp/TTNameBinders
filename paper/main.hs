{-# LANGUAGE QuasiQuotes, OverloadedStrings, UnicodeSyntax #-}
{-# OPTIONS_GHC -F -pgmF frquotes -fno-warn-missing-signatures #-}
-- VIM :source config.vim

import Language.LaTeX

import System.Cmd (system)
import System.Directory (doesFileExist)
import System.Environment (getArgs)
import Control.Monad.Writer

import Language.LaTeX.Builder.QQ (texm, texFile)

import Kit (document, itemize, it, dmath, {-pc, pcm,-} printAgdaDocument, writeAgdaTo, startComment, stopComment, citet, citeauthor, acknowledgements)
import NomPaKit
import NomPaKit.QQ

--import qualified MiniTikz.Builder as D -- hiding (node)
--import MiniTikz.Builder (right, below, nodeDistance, oF, dnode, spath, scope)

--import System.Directory (copyFile)

-- sections
[keys|intro
      overview
      termStructure
      examples
      comparison
      performance
      proofs
      discussion
      implementationExtras
      functorSec
      cpsSec
      nbeSec
     |]

-- figures
-- [keys|TODO|]

-- citations
[keys|pouillard_unified_2012
      mcbride_not_2010
      chlipala_parametric_2008
      guillemette_type-preserving_2007
      guillemette_type-preserving_2008
      miller_proof_2003
      bird-paterson-99
      washburn_boxes_2003
      de_bruijn_lambda_1972
      shinwell_freshml_2003
      berger_normalization_1998
      mcbride_applicative_2007

      de-bruijn-72 mcbride-mckinna-04 altenkirch-reus-99
      atkey-hoas-09 pouillard-pottier-10 pouillard-11
      bernardy-10 reynolds-83 mcbride-paterson-08 altenkirch-93 wadler-free-89
      bellegarde-94

      shinwell-03 pitts-06 licata-harper-09 pottier-lics-07 urban-04

      poplmark guillemette-monnier-08 elphin-05 delphin-08 delphin-09
      pientka-08 pitts-10 harper-93
      atkey-lindley-yallop-09 weirich-yorgey-sheard-11
      wadler-views-87

      taha-99 engler-96 norell-07 hutton-07 tapl attapl pottier-alphacaml
      fresh-ocaml pollack-sato-ricciotti-11 sato-pollack-10
      chargueraud-11-ln aydemir-08 cave-12
     |]

{-
alphacaml = pottieralphacaml
nominalsigs = urban04
lfcite = harper93
lncites = [chargueraud11ln, aydemir08]
spcites = [pollacksatoricciotti11, satopollack10]
-}
belugamu = cave12
fincites = [altenkirch93, mcbridemckinna04]
nestedcites = [bellegarde94, birdpaterson99, altenkirchreus99]
nbecites = [bergernormalization1998, shinwell03, pitts06, licataharper09, belugamu]

title =  «Names For Free --- A Polymorphic Interface to Names and Binders»
  -- «Parametric Nested Abstract Syntax» -- Sounds like it's for a representation
  --
  -- «A Classy Kind of Nested Abstract Syntax»
  -- «Implementing Names and Binders with Polymorphism»
-- Ingredients:
-- Classes
-- Polymorphism
-- Nested


authors = [ («Jean-Philippe Bernardy» , «bernardy@chalmers.se» , «Chalmers University of Technology and University of Gothenburg»)
           ,(«Nicolas Pouillard»      , «npou@itu.dk»          , «IT University Copenhagen»)
          ]
abstract = [texFile|abstract|]
keywords = [texFile|keywords|]
_Agda's = «{_Agda}'s»

notetodo x = p"" $ red «TODO {x}»
--notecomm x = p"" $ red «COMMENT {x}»
-- notetodo _ = return ()
--notecomm _ = return ()

long = True
short = not long
debug = False

doComment :: ParItemW → ParItemW
doComment x = startComment >> x >> stopComment

commentWhen :: Bool → ParItemW → ParItemW
commentWhen True  x = doComment x
commentWhen False x = x

commentCode = doComment

unpackCode =  [agdaFP|
  |unpack :: f (Succ a) → (∀ v. v → f (a ▹ v) → r) → r
  |unpack e k = k () e
  |]

q = p ""

apTm =
  [agdaFP|
  |-- Building the following term: λ f x → f x
  |apTm = lam $ λ f → lam $ λ x → var f `App` var x
  |]

canEta =
  [agdaFP|
  |canEta (Lam e) = unpack e $ λ x t → case t of
  |  App e1 (Var y) → y `isOccurenceOf` x &&
  |                   not (x `occursIn` e1)
  |  _ → False
  |canEta _ = False
  |]

{-
Arguments for having v ▹ a instead of a ▹ v

  * If we consider v to be a dummy type then
    this functor ((▹) v) seems more common than
    this functor ((▹) a)
  * Same direction as List.(:), Nompa.(◅), Bound.Var, (∈)
  * If we see this as a morphism (inj :: v -> a) then
    the order is the same

Arguments for keeping the current order

  * Same direction as Γ,x

fmap     :: Functor f     => (a -> b) -> f a -> f b
(=<<)    :: Monad   m     => (a -> m b) -> m a -> m b
traverse :: Applicative f => (a -> f b) -> t a -> f (t b)

isClosed :: Foldable f => f a -> Bool
closed   :: Traversable f => f a -> Maybe (f b)
elem     :: (Foldable t, Eq a) => a -> t a -> Bool
vacuous  :: Functor f => f Void -> f a

On top of Bound:

  type a ▹ v = Var v a

  class v ∈ a where
    inj :: v → a

  instance x ∈ (γ ▹ x) where
    inj = B

  instance (x ∈ γ) ⇒ x ∈ (γ ▹ y) where
    inj = F . inj

  var :: ∀ f v a. (v ∈ a, Monad f) ⇒ v → f a
  var = return . inj

  abs :: ∀ f a. (∀ v. v → f (a ▹ v)) → f (Succ a)
  abs k = k ()

  unpack :: f (Succ a) → (∀ v. v → f (a ▹ v) → r) → r
  unpack e k = k () e

  pack :: Functor tm ⇒ v → tm (a ▹ v) → tm (Succ a)
  pack x = fmap (bimap id (const ()))

  lam :: ∀ a. (∀ v. v → Tm (a ▹ v)) → Tm a
  lam k = Lam (abs k)

  -- Scopes

  abs :: ∀ f a. Monad f ⇒ (∀ v. v → f (a ▹ v)) → Scope () f a
  abs k = toScope . k ()

  lam :: ∀ a. (∀ v. v → Tm (a ▹ v)) → Tm a
  lam k = Lam (abs k)

  class a ⊆ b where
    injMany :: a → b

  instance a ⊆ a where injMany = id

  instance Zero ⊆ a where injMany = magic

  instance (γ ⊆ δ) ⇒ (γ ▹ v) ⊆ (δ ▹ v) where
    injMany = bimap injMany id

  instance (a ⊆ c) ⇒ a ⊆ (c ▹ b) where
    injMany = F . injMany

  wk :: (Functor f, γ ⊆ δ) ⇒ f γ → f δ
  wk = fmap injMany

* Term structure:
    * Monad =>
        * substitution
        * Functor (=> renaming)
        * pure scope manipulation
            * a close term can inhabit any "world": 'vacuous'
    * Traversable =>
        * effectful scope manipulation
            * 'traverse (const Nothing)' is 'closed'
        * Foldable =>
            * fold over the free variables
            * monoidal action on the free-vars
                * 'all (const False)' is 'isClosed'
                * toList
                * elem
* Scope as an abstraction:
    * Once we have an abstraction the concrete definition
      can be changed according to different criterions:
        * efficiency (as the 'Scope' from Bound)
        * simplicity (improve reasoning)

* Nice packing and unpacking of scopes
    * could be better than 'abstract'/'instantiate'
    * higher-order style:
        * ∀ v. v → f (a ▹ v)
        * nice constructions: lam λ x → lam λ y → ...
        * nice unpacking: unpack λ x t → ...
    * nominal style:
        * ∃ v. (v , f (a ▹ v))
        * "fresh x in ..." stands for "case fresh of Fresh x -> ..."
        * fresh x in fresh y in lam x (lam y ...)

-}


  {- NP:
  These throwaway arguments might be a bit worrisome. A more involved
  version would use a type known as Tagged

  data Tagged a b = Tagged b

  Or more specific to our usage

  data Binder v = TheBinder
  -- Iso to Tagged v ()

  unpack :: (∀ v. v → tm (w ▹ v)) →
            (∀ v. Binder v → tm (w ▹ v) → a) → a
  unpack b k = k TheBinder (b TheBinder)

  remove :: Binder v → [a ▹ v] → [a]
  remove _ xs = [x | There x ← xs]

  ...

  in this case we should also have:

  (∀ v. Binder v → tm (w ▹ v))
  -}


body includeUglyCode = {-slice .-} execWriter $ do -- {{{
  notetodo «ACM classification (JP: no clue how it's done these days!)»

  when includeUglyCode $ do 
     [agdaP|
     |{-# LANGUAGE RankNTypes, UnicodeSyntax,
     |    TypeOperators, GADTs, MultiParamTypeClasses,
     |    FlexibleInstances, UndecidableInstances,
     |    IncoherentInstances, ScopedTypeVariables, StandaloneDeriving #-}
     |import Prelude hiding (elem,any)
     |import Data.Foldable
     |import Data.Traversable
     |import Control.Applicative
     |import Data.List (nub,elemIndex)
     |import Data.Maybe
     |-- import Data.Bifunctor 
     |
     |main :: IO ()
     |main = putStrLn "It works!"
     |]

  notetodo «unify the terminology names/context/free variables»
-- JP (when the rest is ready)
  section $ «Intro» `labeled` intro

  p"the line of work where we belong"
   «One of the main application area of functional programming languages
    such as Haskell is programming language technology. In particular,
    Haskell programmers often finds themselves manipulating data
    structures which involve binders and names.»

  p"identifying the gap"
   «Yet, the most commonly used representation for names and binders
    yield code which is difficult to read, and error-prone to write
    and maintain. The techniques in question are often referred as
    “nominal”, “de Bruijn indices” and “HOAS: Higher-Order Abstract
    Syntax”.»

  -- NP: We can make this better.
  p"Nominal pros&cons"
   «In the nominal approach, one typically use some atomic type to
    represent names. Because a name is referred to by any variable
    which contains the atom representing it, the nominal style is
    natural. The main issue with this techniques are that variables
    must sometimes be renamed in order to avoid name capture (that is,
    if a binder refers to an already used name, variables might end up
    referring to the wrong binder). The need for renaming means a way
    to generate fresh atoms. This side effect can be resolved with a
    supply for unique atoms or using an abstraction such as a monad
    but is finally disturbing if one wishes to write functional code.
    Then nominal name abstraction being non-canonical it should be
    prevented from violations. For instance, if one has two α-equivalent
    representations of the same term, no program should be able to
    distinguish them (such as {|λx.x|} and {|λy.y|}). »

  -- NP: Note that in a safe interface for binders the supply does not
  -- have to be threaded, only passed downward and can be represented
  -- by a single number that we know all the numbers above are fresh
  -- names.

  p"de Bruijn pros&cons"
   «To avoid the problem of name capture, one can represent names
    canonically, for example by the number of binders (λ for instance)
    to cross between an occurrence and its binding site. In practice
    however, this representation makes it hard to manipulate terms:
    instead of calling things by name, programmers have to rely on their
    arithmetic abilities, which turn out to be error-prone. As soon as
    one has to deal with more than just a few open bindings, it becomes
    easy to make mistakes.»

  p"DB make α-eq easy"
   «For instance deciding if two terms are α-equivalent is
    straightforward and efficient with de Bruijn indices and is more
    involved and error-prone in nominal.»

  p"HOAS"
   «TODO HOAS»

  p"contribution"
   «We contribute a new programming interface for binders, which
    provides the ability to write terms in a natural style close to
    concrete syntax. We can for example build the application function
    of the untyped λ-calculus as follows.»

  commentCode apTm

  q«and we are able to test is a term is eta-contractible using the
    following function:»

  commentCode canEta

  p"contribution continued"
   «All the while, the representation does not require either a
    name supply, not is there to worry about a chance of name capture
    and testing terms for α-equivalence remains straightforward. The cost of this
    achievement is the use of somewhat more involved types for terms,
    and the use type system extensions implemented only in the Glasgow
    Haskell Compiler. This new construction is described in sec. {ref
    overview}.»

  notetodo «survey the rest of the paper.»

  section $ «Overview» `labeled` overview

  p"flow"
   «In this section we describe our interface. We begin
    by describing a simple implementation which can support it.»

  subsection $ «de Bruijn Indices»

  p"de Bruijn indices"
   «{citet[debruijnlambda1972]} proposed to represent a variable {|x|}
    by counting the number binders that one has to cross over to reach the
    binding site of {|x|}. A direct implementation of the idea may yield
    the following representation of untyped λ-terms:»

  [agdaFP|
  |data Nat = Zero | Succ Nat
  |data TmDB where
  |  VarDB :: Nat → TmDB
  |  AppDB :: TmDB → TmDB → TmDB
  |  LamDB :: TmDB → TmDB
  |]

  p"apDB"
   «Using this representation, the implementation of the application
    function {|λ f x → f x|} is the following:»

  [agdaFP|
  |apDB :: TmDB
  |apDB = LamDB $ LamDB $ VarDB (Succ Zero)
  |                       `AppDB`
  |                       VarDB Zero
  |]

  p"no static scoping"
   «However, such a direct implementation is cumbersome and naïve. For
    instance it cannot statically distinguish bound and free variables.
    That is, a closed term has the same type as an open term.»

  paragraph «Nested Abstract Syntax»

  p"nested data types"
   «In functional programming languages such as Haskell, it is possible
    to remedy to this situation by using “nested recursion”. That is, one
    parameterises the type of terms by a type that can represent
    {emph«free»} variables. If the parameter is the empty type, terms
    are closed. If the parameter is the unit type, there is at most one
    free variable, etc.»

  -- Because the parameter is the type of free-variables,
  -- it does not affect the representation of bound variables
  -- at all.

  p"citation"
   «This representation in known as Nested Abstract
    Syntax {cite nestedcites}»

  -- NP,TODO: 'type', 'class', 'instance', '::', '⇒' are not recognized as keywords
  -- NP: explain the meaning of Here and There
  [agdaFP|
  |data Tm a where
  |  Var :: a → Tm a
  |  App :: Tm a → Tm a → Tm a
  |  Lam :: Tm (Succ a) → Tm a
  |]

  p"the type of Lam"
   «The recursive case {|Lam|} changes the type parameter, increasing
    its cardinality by one, since the body can refer to one more
    variable.»

  p"flash-forward"«Anticipating on the amendements we propose, we define {|Succ a|} type as 
   a proper sum of {|a|} and the unit type {|()|} instead of {|Maybe a|} as customary. 
   Because the sum is used in an
   assymetric fashinon (the left-hand-side corresponds to variables bound earlier and the right-hand-side
   to the freshly bound one), we give a special definition, whose the syntax reflects the
   intended semantics.»
  
  [agdaFP|
  |type Succ a = a ▹ ()
  |
  |data a ▹ v = There a | Here v
  |
  |bimap :: (a → a') → (v → v') → (a ▹ v) → (a' ▹ v')
  |bimap f _ (There x) = There (f x)
  |bimap _ g (Here x)  = Here (g x)
  |
  |untag :: a ▹ a → a
  |untag (There x) = x
  |untag (Here  x) = x
  |]
--  |instance Bifunctor (▹) where

  p"apNested example"
   «Using the {|Tm|} representation, the implementation of the application
    function {|λ f x → f x|} is the following:»

  [agdaFP|
  |apNested :: Tm Zero
  |apNested = Lam $ Lam $ Var (There $ Here ())
  |                       `App`
  |                       Var (Here ())
  |]

  p"the type of apNested"
   «As promised, the type is explicit about {|apNested|} being a closed
    term: this is ensured by using the empty type {|Zero|} as an
    argument to {|Tm|}.»

  [agdaFP|
  |data Zero -- no constructor
  |magic :: Zero → a
  |magic _ = error "magic!"
  |]

  p"polymorphic terms are closed"
   «In passing, we remark that another type which faithfully captures
    closed terms is {|∀ a. Tm a|} --- literally: the type of terms which
    are meaningful in any context.
    Indeed, because {|a|} is universally quantified, there is no way
    to construct an inhabitant of it; therefore one cannot possibly refer to any
    free variable. In particular one can instantiate {|a|} to be the
    type {|Zero|}.»

  p"DB drawback"
   «However the main drawback of using de Bruijn indices remains: one must still
    count the number of binders between the declaration of a variable and its occurrences.»

  subsection «Referring to bound variables by name»

  p"flow"
   «To address the issues touched upon in the previous section, we
    propose to build λ-abstractions with a function called {|lam|}. What
    matters the most is its type:»

  [agdaFP|
  |lam :: (∀ v. v → Tm (a ▹ v)) → Tm a
  |lam f = Lam (f ())
  |]

    {-
  [agdaFP|
  |data Tm a where
  |  Var :: a → Tm a
  |  App :: Tm a → Tm a → Tm a
  |  Lam :: (∀ v. v → Tm (a ▹ v)) → Tm a
  |]
  -}

  p"explain ∀ v"
   «That is, instead of adding a concrete unique type (namely {|()|}) in
    the recursive parameter of {|Tm|}, we quantify universally over a
    type variable {|v|} and add this type variable to the type of free
    variables.»

  p"explain v →"
   «The sub-term receives an arbitrary value of type {|v|},
    to be used at occurrences of the variable bound by {|lam|}.»

  -- NP: "provide the sub-term" is one side of the coin, the other side
  -- would be to say that a name abstraction receives a value of type v
  -- to be....

  p"const"
   «The application function is then built as follows:»

  [agdaFP|
  |apTm_ :: Tm Zero
  |apTm_ = lam $ λ f → lam $ λ x →
  |              Var (There (Here f))
  |        `App` Var (Here x)
  |]

  p"still the same elephant"
   «By unfolding the definition of {|lam|} in {|apTm|} one recovers
    the definition of {|apNested|}.»

  paragraph «Safety»

  p"host bindings are the spec"
   «Using our approach, the binding structure, which can be identified as
    the {emph«specification»}, is written using the host language binders.

    However at variable occurrences, de Bruijn indices are still present
    in the form of the constructors {|Here|} and {|There|}, and are
    purely part of the {emph«implementation»}.»

  p"type-checking the number of There..."
   «The type-checker will make sure that the implementation matches the specification:
    for example if one now makes a mistake and forgets one {|There|} when typing the
    term, the Haskell type system rejects the definition.»

  commentCode [agdaFP|
  |oops_ = lam $ λ f → lam $ λ x →
  |              Var (Here f)
  |        `App` Var (Here x)
  |-- Couldn't match expected type `v1'
  |--             with actual type `v'
  |]

  p"no mistakes at all"
   «In fact, if all variables are introduced with the {|lam|} combinator,
    the possibility of making a mistake in the
    {emph«implementation»} is inexistent (if we ignore diverging terms).
    Indeed, because the type {|v|} corresponding to a bound variable is
    universally quantified, the only way to construct a value of its
    type is to use the variable bound by {|lam|}.»

  p"unicity of injections"
   «Conversely, in a closed context, if one considers the
    expression {|Var (Thereⁿ (Here x))|}, only one possible value
    of {|n|} is admissible. Indeed, anywhere in the formation of a
    term using {|lam|}, the type of variables is {|a = a0 ▹ v0 ▹
    v1 ▹ ⋯ ▹ vn|} where {|v0|}, {|v1|}, … , {|vn|} are all distinct and
    universally quantified, and none of them occurs as part of {|a0|}.
    Hence, there is only one injection function from a given {|vi|}
    to {|a|}.»

  paragraph «Auto-inject»

  p"auto-inject"
   «Knowing that the injection functions are uniquely determined by
    their type, one may wish to infer them mechanically. Thanks the
    the powerful instance search mechanism implemented in GHC, this
    is feasible. We can define a class {|v ∈ a|} capturing that {|v|}
    occurs as part of a context {|a|}:»

  [agdaFP|
  |class v ∈ a where
  |  inj :: v → a
  |]

  p"var"
   «We can then wrap the injection function and {|Var|} in a convenient
    package:»

  commentCode [agdaFP|
  |var :: ∀ v a. (v ∈ a) ⇒ v → Tm a
  |var = Var . inj
  |]

  p"apTm"
   «and the application function can be conveniently written:»

  apTm

  p"more intuitions"
   «In a nutshell, our de Bruijn indices are typed with the context
    where they are valid. If that context is sufficiently polymorphic,
    they can not be mistakenly used in a wrong context. Another
    intuition is that these {|Here|} and {|There|} are building proofs
    of “context membership”. Thus, a de Bruijn index in a given context
    is similar to a well-scoped name.»

  p"flow to next section"
   «So far, we have seen that by taking advantage of polymorphism, 
    our interface allows to construct
    terms with de Bruijn indices, combined with the safety and
    convenience of named variables. In the next section we will show how
    to use the same idea to provide the same advantages for the analysis
    and manipulation on terms.»

  subsection «Pack/Unpack: Referring to free variables by name»

  p"unpack"
   «A common use case is that one wants to be able to check if an
    occurrence of a variable is a reference to some previously bound
    variable. With de Bruijn indices, one must (yet again) count the
    number of binders traversed between the variable bindings and
    its potential occurrences --- an error prone task. Here as well,
    we can take advantage of polymorphism to ensure that no mistake
    happens. We provide a combinator {|unpack|}, which hides the 
    type of the newly bound variables (the type {|()|}) as an existentially
    quantified type {|v|}. The combinator {|unpack|} takes a binding
    structure (of type {|Tm (Succ a)|}) and gives a pair of
    a value {|x|} of type {|v|} and a
    sub-term of type {|Tm (a ▹ v)|}. Here we write the combinator in
    continuation-passing style as it seems the most convenient to use
    this way. (See section TODO FORWARD REFERENCE for another solution
    based on view patterns.) Because this combinator is not specific to our
    type {|Tm|} we generalize it to any type constructor {|f|}:»

  unpackCode

  p"why unpack works"
   «Because {|v|} is existentially bound and occurs only positively
    in {|Tm|}, {|x|} can never be used in a computation. It acts as a
    reference to a variable in a context, but in a way which is only
    accessible to the type-checker.

    For instance, when facing a term {|t|} of type
    {|Tm (a ▹ v0 ▹ v1 ▹ v)|}, {|x|} refers to the last introduced free
    variable in {|t|}.

    Using {|unpack|}, one can write a function which can recognise an
    eta-contractible term as follows: (Recall that an a eta-contractible
    term has the form {|λ x → e x|}, where {|x|} does not occur free
    in {|e|}.)»

  [agdaFP|
  |canEta :: Tm Zero → Bool
  |]
  canEta

  {-
   NP: Issue with unpack: it becomes hard to tell if a recursive function is
       total. Example:

       foo :: Tm a → ()
       foo (Lam e) = unpack e $ λ x t → foo t
       foo _       = ()

   As long as unpack is that simple, this might be one of those situations
   where we want to inline unpack. This new code is then termination checked
   and kept as the running program (let's not make the same mistakes as Coq).
  -}

  p"canEta"
   «In the above example, the functions {|isOccurenceOf|}
    and {|occursIn|} use the {|inj|} function to lift {|x|} to
    a reference in the right context before comparing it to the
    occurrences. The calls to these functions do not get more
    complicated in the presence of multiple binders. For example, the
    code which recognises the pattern {|λ x y → e x|} is as follows:»

  [agdaFP|
  |recognize :: Tm Zero → Bool
  |recognize t0 = case t0 of
  |    Lam f → unpack f $ λ x t1 → case t1 of
  |      Lam g → unpack g $ λ y t2 → case t2 of
  |        App e1 (Var y) → y `isOccurenceOf` x &&
  |                         not (x `occursIn` e1)
  |        _ → False
  |      _ → False
  |    _ → False
  |]

  p"slogan"
   «Again, even though variables are represted by mere indices, the use
    of polymorphism allows to refer to them by name, using the instance
    search mechanism to fill in the details of implementation.»

  {-
  subsection $ «Packing and Unpacking Binders»

  p""«In order to examine the content of a term with another bound variable,
      one must apply a concrete argument to the function of type {|∀v. v → Term (a ▹ v)|}.
      The type of that argument can be chosen freely --- that freedom is sometimes useful
      to write idiomatic code. One choice is
      unit type and its single inhabitant {|()|}. However this choice locally reverts to using
      plain Nested Abstract Syntax, and it is often advisable to chose a more specific type.

      In particular, a canonical choice is a maximally polymorphic type. This is the choice
      is made by using the {|unpack|} combinator.
      »
      -- While I agree that using the unit type everywhere reverts to using
      -- Nested Abstract Syntax, the one time use of () is I think
      -- a good style since there is nothing to confuse about free variables
      -- since there is only one.

      -- In a total language, unpack would be
      -- defined as unpack b k = k () (b ()). Which essentially turns
      -- unpack b λ x t → E into let { x = () ; t = b () } in E.
      --
      -- However, a real implementation of the technique would need something like the
      -- nabla combinator, where unpack would essentially be provided natively.
      --
      -- I still like the pack/unpack mode a lot it shines well when multiple
      -- binders are opened at once.
  commentCode unpackCode

  {-
  [agdaP|
  |unpack binder k = k fresh (binder fresh)
  |  where fresh = ()
  |]
  -}

  p""«The continuation {|k|}
  is oblivious to the
  the monomorphic type used by the implementation of {|fresh|}: this is expressed by universally quantifing {|v|} in the type of the continuation {|k|}.

  In fact, thanks to parametricity, and because {|v|} occurs only positively in the arguments of {|k|},
  it is guaranteed that {|k|} cannot observe the implementation of {|fresh|} at all (except for the escape hatch of {|seq|}).
  In particular one could even define {|fresh = undefined|}, and the code would continue to work.»

  p""«As we have seen in previous examples, the {|unpack|} combinator gives the possibility
  to refer to a free variable by name, enabling for example to compare a variable
  occurrence with a free variable. Essentially, it offers a nominal interface to free variables:
  even though the running code will use de Bruijn indices, the programmer sees names; and
  the correspondence is enforced by the type system.
  »
  -}

  paragraph «Pack»

  p"pack"
   «As we shall shortly terms form an instance of {|Functor|}. The
    function {|pack|} is therefore defined uniformly for all {|tm|}
    instance of {|Functor|}. It is then easy to invert the job
    of {|unpack|}. Indeed, given a value {|x|} of type {|v|} and a term
    of type {|Tm (a ▹ v)|} one can reconstruct a binder as follows: »

  [agdaFP|
  |pack :: Functor tm ⇒ v → tm (a ▹ v) → tm (Succ a)
  |pack x = fmap (bimap id (const ()))
  |]

  p"dynamically useless, statically useful"
   «As we can see, the value {|x|} is not used by pack. However it
    statically helps as a specification of the user intention. Therefore
    we rely on names and not indices.»

  p"lamP"
   «Hence, the {|pack|} combinator makes it possible to give a nominal-style
    interface to binders. For example an alternative way to build
    the {|Lam|} constructor is the following:»

  [agdaFP|
  |lamP :: v → Tm (a ▹ v) → Tm a
  |lamP x t = Lam (pack x t)
  |]

  -- TODO
  q«It is even possible to make {|pack|} bind any known variable in a
    context, by using a typeclass similar to {|∈|}. This extension is
    straightforward and the implementation is deferred to the appendix.»

  -- section $ «»

  section $ «Contexts»


  p"flow, ▹"
   «We have seen that the type of free variables essentially describes
    the context where they are meaningful. A context can either be
    empty (and we represent it by the type {|Zero|}) or not (which we
    can represent by the type {|a ▹ v|}).»

  p"explain remove"
   «An important functon of the {|v|} type variable is to make sure 
    programmers refer to the variable they intend to. For example, 
    consider the following function, which takes a list of (free) variables
    and removes one of them from the list. Hence it takes a list of variables
    in the context_{|a ▹ v|} and returns a list in the context_{|a|}. For extra
    safety, it also takes a name of the variable being removed, which is used only for
    type-checking purposes.»
  [agdaFP|
  |remove :: v → [a ▹ v] → [a]
  |remove _ xs = [x | There x ← xs]
  |]

  p"explain freeVars"
   «The function which computes the list of occurences of free variables in a term can
    be directly transcribed from its nominal-style definition, thanks
    to the {|unpack|} combinator.»

  [agdaFP|
  |freeVars :: Tm a → [a]
  |freeVars (Var x) = [x]
  |freeVars (Lam b) = unpack b $ λ x t →
  |   remove x (freeVars t)
  |freeVars (App f a) = freeVars f ++ freeVars a
  |]

  subsection $ «Equality between names»


  p"Eq Zero"
   «Many useful functions depend on weather two names are equal.
    To implement comparison between names, we provide the following two {|Eq|} instances.
    First, the {|Zero|} type is vaccuously equipped with equality:»

  [agdaFP|
  |instance Eq Zero where
  |  (==) = magic
  |]

  p""
   «Second, if two indices refer to the first variables they are equal;
    otherwise we recurse. We stress that this equality tests only the
    {emph«indices»}, not the values contained in the type. For
    example {|Here 0 == Here 1|} is {|True|}»

  {-
  instance (Eq a, Eq v) ⇒ Eq (a ▹ v) where
    Here  x == Here  y = x == y
    There x == There y = x == y
    _       == _       = False

  instance Eq (Binder a) where
    _ == _ = True
  -}

  [agdaFP|
  |instance Eq a ⇒ Eq (a ▹ v) where
  |  Here  _ == Here  _ = True
  |  There x == There y = x == y
  |  _       == _       = False
  |]
  q«
    Comparing naked de Bruijn indices for equality is an error prone operation, 
    because one index might be valid in
    a context different from the other, and thus an arbitrary adjustment might be required.
    With nested abstract syntax, the situation improves: by requiring equality to be 
    performed between indices of the same type, a whole class of errors are prevented by
    type-checking. Some mistakes are possible though: given two names of type {|a ▹ () ▹ ()|},
    swapping the two first variables might be necessary, but one cannot decide if it is so 
    from the types only. 
    By making the contexts fully
    polymorphic as we propose, no mistake is possible. 
    Hence the slogan: names are polymorphic indices.»

  q«Transitively the derived equality instance of {|Tm|} gives α-equality, and is guaranteed 
    safe in fully-polymorphic contexts.»
  [agdaFP|
  |deriving instance Eq a => Eq (Tm a)
  |]


  subsection «Membership»
  q«Given this, we can implement
    the relation of context membership by a type class {|∈|}, whose
    sole method performs the injection from a member of the context to
    the full context. The relation is defined by two inference rules,
    corresponding to finding the variable in the first position of the
    context, or further away in it, with the obvious injections:»

  [agdaFP|
  |instance v ∈ (a ▹ v) where
  |  inj = Here
  |
  |instance (v ∈ a) ⇒ v ∈ (a ▹ v') where
  |  inj = There . inj
  |]

  p"incoherent instances"
   «The cognoscenti will recognize the two above instances as
    {emph«incoherent»}, that is, if {|v|} and {|v'|} were instanciated
    to the same type, both instances would apply equally. Fortunately,
    this incoherency will never trigger as long as one uses the
    interface provided by our combinators: the injection function will
    always be used on maximally polymorphic contexts, and therefore {|v|} and {|v'|}
    will be different.»

  -- NP: maybe mention the fact that GHC let us do that

  p"inj enables var"
   «We have seen before that the overloading of the {|inj|} function
    in the type class {|∈|} allows to automatically convert a type-level
    reference to a term into a properly tagged de Bruijn index, namely
    the function {|var|}.»

  p"explain isOccurenceOf"
   «Conversely, one can implement occurence-check by combining  {|inj|} with {|(==)|}:
    one first lifts the bound variable to the context of the chosen occurence and
    then test for equality.»

  [agdaFP|
  |isOccurenceOf :: (Eq a, v ∈ a) ⇒ a → v → Bool
  |x `isOccurenceOf` y = x == inj y
  |]

  p"occursIn"
   «A test of occurrence of any given bound variable can then be given the following expression:»

  [agdaFP|
  |occursIn :: (Eq a, v ∈ a) ⇒ v → Tm a → Bool
  |x `occursIn` t = any (`isOccurenceOf` x) (freeVars t)
  |]
--- |x `occursIn` t = (`any` freeVars t) (`isOccurenceOf` x)
  -- OR: inj x `elem` t
  -- x `occursIn` t = inj x `elem` freeVars t
  -- OR: Using Data.Foldable.elem
  -- x `occursIn` t = inj x `elem` t



  subsection «Inclusion»
  p"context inclusion, ⊆"
   «Context inclusion is another useful relation between contexts, which we also
    represent by a type class, namely {|⊆|}. The sole method of the
    typeclass is again an injection, from the small context to the
    bigger one. The main application of {|⊆|} is presented at the end of sec. {ref functorSec}.»
  [agdaFP|
  |class a ⊆ b where
  |  injMany :: a → b
  |]

  p"⊆ instances"
   «This time we have four instances: inclusion is reflexive; the empty
    context is the smallest one; adding a variable makes the context
    larger; and variable append {|(▹ v)|} is monotonic for inclusion.»

  [agdaFP|
  |instance a ⊆ a where injMany = id
  |
  |instance Zero ⊆ a where injMany = magic
  |
  |instance (a ⊆ b) ⇒ a ⊆ (b ▹ v) where
  |  injMany = There . injMany
  |
  |instance (a ⊆ b) ⇒ (a ▹ v) ⊆ (b ▹ v) where
  |  injMany = bimap injMany id
  |]

  p"(▹) functoriality"
   «This last case uses the fact that {|(▹)|} is functorial in its first argument.»


  -- NP
  section $ «Term Structure» `labeled` termStructure

  p"motivation"
   «It is well-known that every term representations parameterised
    on the type of free variables should exhibit monadic structure,
    with substitution corresponding to the binding operator {cite
    nestedcites{-TODO-}}. This implies that the representation is stable
    under substitution. In this section we review this structure,
    as well as other standard related structures on terms. Theses
    structures are perhaps easier to implement directly on a concrete
    term representation, rather than our interface. However, we give an
    implementation solely based on our interface, to demonstrate that
    our interface is complete with respect to these structures. By doing
    so, we also demonstrate how to work with our interface in practice.»

  subsection $ «Renaming and Functors» `labeled` functorSec

  p"intro functor"
   «The first, perhaps simplest, property of terms is that free
    variables can be renamed. This property is captured by
    the {|Functor|} structure.»

  p"describe Functor Tm"
   «The “renaming” to apply is given as a function {|f|} from {|a|}
    to {|b|} where {|a|} is the type of free variables of the input
    term ({|Tm a|}) and {|b|} is the type of free variables of the
    “renamed” term ({|Tm b|}). The renaming operation then simply
    preserves the structure of the input term. At occurence sites,
    using {|f|} to rename free variables. At binding sites, {|f|} is
    upgraded form {|a → b|} to {|a ▹ v → b ▹ v|} using the functoriality
    of {|(▹ v)|} with {|bimap f id|}. Adapting the function {|f|} is
    necessary to protect the bound name from being altered by {|f|}, and
    thanks to our use of polymorphism, the type-checker ensures that we
    make no mistake in doing so.»

  [agdaFP|
  |instance Functor Tm where
  |  fmap f (Var x)   = Var (f x)
  |  fmap f (Lam b)   = unpack b $ λ x t →
  |                       Lam . pack x $ fmap (bimap f id) t
  |  fmap f (App t u) = App (fmap f t) (fmap f u)
  |]

  p"functor laws"
   «As usual satisfying functor laws implies that the structure is
    preserved by the function action (fmap). The type for terms being a
    functor therefore means that applying a renaming is going to only
    affect the free variables and leave the structure untouched. Namely
    that whatever the function {|f|} is doing, the bound names are not
    going to change. As expected the laws are the following:»

  doComment
    [agdaFP|
    |fmap id ≡ id
    |fmap (f . g) ≡ fmap f . fmap g
    |]

  p"reading the laws"
   «Therefore the identity function corresponds to not renaming anything
    and compositions of renaming functions corresponds to two sequential
    renaming operations.»

  q«Assuming only a functor structure, it is possible to write useful
    function on terms which involve only renaming. A couple examples
    follow.»

  q«First, let us assume an equality test on “names” (the argument
    of the functor structure. We can then write a function
    {|rename (x,y) t|} which replaces free occurences of {|x|} in {|t|}
    by {|y|} and {|swap (x,y) t|} which exchanges free occurences
    of {|x|} and {|y|} in {|t|}.»

  [agdaFP|
  |rename0 :: Eq a ⇒ (a, a) → a → a
  |rename0 (x,y) z | z == x    = y
  |                | otherwise = z
  |
  |rename :: (Functor f, Eq a) ⇒ (a, a) → f a → f a
  |rename = fmap . rename0
  |]

  [agdaP|
  |swap0 :: Eq a ⇒ (a, a) → a → a
  |swap0 (x,y) z | z == y    = x
  |              | z == x    = y
  |              | otherwise = z
  |
  |swap :: (Functor f, Eq a) ⇒ (a, a) → f a → f a
  |swap = fmap . swap0
  |]

    {-
  -- "proofs", appendix, long version, useless...
  -- using: fmap f (Lam g) = Lam (fmap (bimap f id) . g)
  doComment
    [agdaFP|
    |fmap id (Var x)
    |  = Var (id x) = Var x
    |
    |fmap id (Lam g)
    |  = Lam (fmap (bimap id id) . g)
    |  = Lam (fmap id . g)
    |  = Lam (id . g)
    |  = Lam g
    |
    |fmap (f . g) (Var x)
    |  = Var ((f . g) x)
    |  = Var (f (g x))
    |  = fmap f (Var (g x))
    |  = fmap f (fmap g (Var x))
    |
    |fmap (f . g) (Lam h)
    |  = Lam (fmap (bimap (f . g) id) . h)
    |  = Lam (fmap (bimap f id . bimap g id) . h)
    |  = Lam (fmap (bimap f id) . fmap (bimap g id) . h)
    |  = fmap f (Lam (fmap (bimap g id) . h))
    |  = fmap f (fmap g (Lam h))
    |]
  -}

  p"auto-weakening"
   «Second, let us assume two arguments {|a|} and {|b|} related by the
    type class {|⊆|}. Hence we have {|injMany|} of type {|a → b|}, which
    can be seen as a renaming of free variables via the functorial
    structure of terms. By applying it to {|fmap|}, one obtains
    an arbitrary weakening from the context {|a|} to the bigger
    context {|b|}.»

  [agdaFP|
  |wk :: (Functor f, a ⊆ b) ⇒ f a → f b
  |wk = fmap injMany
  |]

  q«Again, this arbitrary weakening function relieves programmer from
    tediously counting indices when doing a program transformation. We
    demonstrate this feature in section {ref cpsSec}.»

  subsection $ «Substitution and Monads»

  q«Another property of terms is that free variables can be substituted
    with terms. This property is captured algebraically by asserting
    that terms form a {|Monad|}, where the {|return|} is the variable
    constructor and {|>>=|} acts as parallel substitution. Indeed, one
    can see a substitution from a context {|a|} to a context {|b|} as
    mapping {|a|} to {|Tm b|}, (Technically, substitutions are Kleisli
    arrows.) and {|(>>=)|} applies a substitution everywhere in a term.»

  q«The definition of the {|Monad|} instance is straightforward for
    variable and application, and we isolate the handling of binders in
    the {|(>>>=)|} function.»

  [agdaFP|
  |instance Monad Tm where
  |  Var x   >>= θ = θ x
  |  Lam s   >>= θ = Lam (s >>>= θ)
  |  App t u >>= θ = App (t >>= θ) (u >>= θ)
  |  return = Var
  |]

  q«At binding sites, one needs to lift the substitution so it does not
    act on the newly bound variables. As for the {|Functor|} instance,
    the type system will guarantee that no mistake is made. Perhaps
    noteworthy is that this operation is independent of the concrete
    term structure. We only “rename” with {|fmap|} and inject variables
    with {|return|}.»

  [agdaFP|
  |liftSubst :: (Functor tm, Monad tm) ⇒ 
  |             (a → tm b) → (a ▹ v) → tm (b ▹ v)
  |liftSubst θ (There x) = fmap There (θ x) 
  |liftSubst θ (Here  x) = return (Here x)  
  |]

  q«Substitution under a binder {|(>>>=)|} is then the wrapping
    of {|liftSubst|} between {|unpack|} and {|pack|}. It is uniform as
    well, and thus can be reused for every structure with binders.»

  [agdaP|
  |(>>>=) :: (Functor tm, Monad tm) ⇒
  |          tm (Succ a) → (a → tm b) → tm (Succ b)
  |s >>>= θ = unpack s $ λ x t →
  |             pack x (t >>= liftSubst θ)
  |]

  q«We can combine the monadic structure with the membership ({|∈|})
    type class to get useful polymorphic code, such as a generic
    reference to a variable:»

  [agdaP|
  |var :: (Monad tm, v ∈ a) ⇒ v → tm a
  |var = return . inj
  |]

  q«Or substitution of an arbitrary variable:»

  [agdaP|
  |substitute :: (Monad tm, Eq a, v ∈ a) ⇒
  |              v → tm a → tm a → tm a
  |substitute x t u = u >>= λ y →
  |     if y `isOccurenceOf` x then t else return y
  |]

  -- NP: I changed the names again, I agree that this often the function
  -- we should be using, however this is not what is expected to correspond
  -- to one substitution as in t[x≔u]
  q«One might however also want to remove the substituted
    variable from the context while performing the substitution:»
  [agdaP|
  |substituteTop :: Monad tm ⇒
  |              v → tm a → tm (a ▹ v) → tm a
  |substituteTop x t u = u >>= λ y → case y of
  |     Here _ → t
  |     There x → return x
  |]

  p"laws"
   «The associativity law ensure that applying a composition of
    substitutions is equivalent to sequentially applying them, while the
    identity law ensure that variables act indeed as such.»

  {-
  lift Var x = Var x
  lift Var (There x) = wk (Var x) = fmap injMany (Var x) = Var (injMany x) =?= Var (There x)
  lift Var (Here  x) = var x = Var (inj x) =?= Var (Here x)
  -}

  {-
  lift return x = return x
  lift return (There x) = fmap There (return x) = return (There x)
  lift return (Here  x) = return (Here x)
  -}

  subsection «Traversable»

  p"explain traverse"
   «Functors enable to apply any pure function {|f :: a → b|} to the
    elements of a structure to get a new structure holding the images
    of {|f|}. Traversable structures enable to apply an effectful
    function {|f :: a → m b|} where {|m|} can be any {|Applicative|}
    functor. An {|Applicative|} functor is strictly more powerful
    than a {|Functor|} and strictly less powerful than a {|Monad|}.
    Any {|Monad|} is an {|Applicative|} and any {|Applicative|}
    is a {|Functor|}. To be traversed a structure only need
    an applicative and therefore will support monadic actions
    directly {cite[mcbrideapplicative2007]}.»

  [agdaFP|
  |instance Traversable Tm where
  |  traverse f (Var x) =
  |    Var <$> f x
  |  traverse f (App t u) =
  |    App <$> traverse f t <*> traverse f u
  |  traverse f (Lam t) =
  |    unpack t $ λ x b →
  |      Lam . pack x <$> traverse (bitraverse f pure) b
  |]

  p"explain bitraverse"
   «In order to traverse name abstractions, indices need to be traversed
    as well. The type {|(▹)|} is a bi-functor that is bi-traversable.
    The function {|bitraverse|} is given two effectful functions, one for
    each case:»

  [agdaFP|
  |bitraverse :: Functor f ⇒ (a → f a') → (b → f b') →
  |                              a ▹ b → f (a' ▹ b')
  |bitraverse f _ (There x) = There <$> f x
  |bitraverse _ g (Here x)  = Here  <$> g x
  |]

  q«If a term has no free variable, then it can be converted from the
    type {|Tm a|} to {|Tm Zero|}, but this requires a dynamic check. It
    may seem like a complicated implementation is necessary, but in fact
    it is a direct application of the {|traverse|} function.»

  [agdaFP|
  |close :: Traversable tm ⇒ tm a → Maybe (tm Zero)
  |close = traverse (const Nothing)
  |]

  p"explain foldMap"
   «Any traversable structure is also foldable.»

  [agdaFP|
  |instance Foldable Tm where
  |  foldMap = foldMapDefault
  |]

  p"freeVars is toList"
   «Thanks to terms being an instance of {|Traversable|} they are
    also {|Foldable|} meaning that we can combine all the elements of
    the structure (i.e. the occurrences of free variables in the term)
    using any {|Monoid|}. One particular monoid is the free monoid of
    lists. Consequently, {|Data.Foldable.toList|} is computing the free
    variables of a term:»

  [agdaFP|
  |freeVars' :: Tm a → [a]
  |freeVars' = toList
  |]

{- NP: cut off-topic?
  -- TODO flow
  p""
   «Here the function {|size|} takes as an argument how to assign
    a size to each free variable (the type {|a|}). An alternative
    presentation would instead require a term whose variables are
    directly of type {|Size|}. One can recover this alternative by
    passing the identity function as first argument. However the other
    way around requires to traverse the term.»

  -- TODO maybe too much
  [agdaFP|
  |type S f b = forall a. (a -> b) -> f a -> b
  |type T f b = f b -> b
  |
  |to :: S f b -> T f b
  |to s = s id
  |
  |from :: Functor f =>  T f b -> S f b
  |from t f = t . fmap f
  |]

could we get some fusion?

s f . fmap g
==
s (f . g)

-}

  section $ «Scopes» 

  p"flow"«
  Armed with an intuitive understanding of safe interfaces to manipulate de Bruijn indices, 
  and the knowlegde that one can abstract over any 
  substitutive structure using standard type-classes, we can recapitulate and succintly describe
  the essence of our constructions.»

  q«In nested abstract systax, a binder introducing one variable in scope, for an arbitrary term structure {|tm|}
    is represented as follows:»
  [agdaP|
  |type SuccScope tm a = tm (Succ a)
  |]

  q«In essence, we propose two new, dual representations of binders,
                                             one based on universal
  quantification, the other one based on existential quantification.»

  commentCode [agdaFP|
  |type PolyScope  tm a = ∀ v.  v → tm (a ▹ v) -- JP: TODO The dual of Exist is Univ. 
  |type ExistScope tm a = ∃ v. (v , tm (a ▹ v))
  |]
  q«The above syntax for existentials is not supported in Haskell, so we must use
    one of the lightweight encodings available. In the absence of view patterns,   
    a CPS encoding is
    convenient for programming (so we used this so far),
    but in the following a datatype representation is more convenient in the following:»

  [agdaFP|
  |data ExistScope tm a where
  |  E :: v → tm (a ▹ v) → ExistScope tm a
  |] 

  q«As we observe in a number of examples, these representations are dual from a safety perspective: 
  the universal-based representation
  ensures safety in the construction of terms, while the existential-based representation is
  ensures safety in the analysis of terms.

  For this reason, we do not commit to either side, and use the suitable representation on 
  a case-by-case basis. This is possible because the representations are both isomorphic to
  a concrete represention of binders such as {|SuccScope|} (and by transivitity between each other).
  »
  subsection«Isomorphisms»

  p"conversions"
   «The conversion functions witnessing the isomorphisms are the following.»

  [agdaFP|
  |succToPoly :: Functor tm ⇒ SuccScope tm a → PolyScope tm a
  |succToPoly t = λ x → fmap (bimap id (const x)) t
  |
  |polyToSucc :: PolyScope tm a → SuccScope tm a
  |polyToSucc f = f ()
  |
  |succToExist :: SuccScope tm a → ExistScope tm a
  |succToExist t = E () t
  |
  |existToSucc :: Functor tm ⇒ ExistScope tm a → SuccScope tm a
  |existToSucc (E _ t) = fmap (bimap id (const ())) t
  |]

  q«One will recognise {|pack|} and {|unpack|} as CPS versions of {|existToSucc|} and {|succToExist|}.
    The {|polyToSucc|} function has not been given a name in the previous sections, but was implicitly used 
    in the definition of {|lam|}. This is the first occurence of the {|succToPoly|} function.»

  q«The first isomorphism property is to prove that {|PolyScope|} is a proper representation of {|SuccScope|},
    that is, {|polyToSucc . succToPoly == id|}. This can be done by simple equational reasoning:»
  [agdaFP|
  |    polyToSucc (succToPoly t)
  | == {- by def -}
  |    existToSucc (λ x → fmap (bimap id (const x)) t)
  | == {- by def -}
  |    fmap (bimap id (const ())) t
  | == {- by () having just one element -}
  |    fmap (bimap id id) t
  | == {- by (bi)functor laws -}
  |    t
  |]
  q«The dual property is harder to prove. We need to use the Paterson-style free theorem for a value {|f|} of type {|PolyScope tm a|},
    yielding the following lemma:»
  [agdaFP|
  | ∀ v₁:*.  ∀v₂:*. ∀v:v₁ → v₂.
  | ∀ x₁:v₁. ∀x₂:*. v x₁ == v₂.
  | ∀ g:(a ▹ v₁) → (a ▹ v₂).
  | (∀ y:v₁. Here (v y) == g (Here y)) → 
  | (∀ n:a.  There n    == g (Here n)) → 
  | f x₂ == fmap g (f x₁)
  |]
  q«We can then specialise to {|v₁ = ()|}, {|x₁ = ()|}, and {|g = bimap id (const x₂)|}, indeed {|g|} satisfies 
    the condition of the lemma. We can then reason equationally:»
  [agdaFP|
  |    f 
  | ==  {- by the above -}
  |    \x -> fmap (bimap id (const x)) (f ())
  | == {- by def -}
  |    succToPoly (f ())
  | == {- by def -}
  |    succToPoly (polyToSucc f)
  |]

{- 
  [agdaFP|
  |    existToSucc (succToExist t)
  | == {- by def -}
  |    existToSucc (E () t)
  | == {- by def -}
  |    fmap (bimap id (const ())) t
  | == {- by () having just one element -}
  |    fmap (bimap id id) t
  | == {- by (bi)functor laws -}
  |    t
  |]
-}  
  subsection $ «Committing to a representation»
  subsection $ «Dual Styles»

  q «One can take the example of a size function, counting the number of
    data constructors in a term:»

  [agdaFP|
  |type Size = Int
  |]

  [agdaFP|
  |size :: (a → Size) → Tm a → Size
  |size ρ (Var x)   = ρ x
  |size ρ (App t u) = 1 + size ρ t + size ρ u
  |size ρ (Lam b)   = 1 + size ρ' b
  | where ρ' (Here  ()) = 1
  |       ρ' (There  x) = ρ x
  |]

  p"Nominal aspect"
   «However one might prefer using our interface in particular in larger examples.
    Each binder is simply {|unpack|}ed.
    Using this technique, the size computation looks as follows:»

  [agdaP|
  |-- sizeU is using 'unpack'
  |sizeU :: (a → Size) → Tm a → Size
  |sizeU ρ (Var x)   = ρ x
  |sizeU ρ (App t u) = 1 + sizeU ρ t + sizeU ρ u
  |sizeU ρ (Lam b)   = unpack b $ λ x t →
  |                      1 + sizeU (extend (x,1) ρ) t
  |
  |extend :: (v, r) → (a → r) → (a ▹ v → r)
  |extend (_, x) _ (Here _)  = x
  |extend _      f (There x) = f x
  |]



{-

  Catamorphism written in Nominal style

  p"cata"
   «This pattern can be generalized to any algebra over terms, yielding
    the following catamorphism over terms. Note that the algebra
    corresponds to the higher-order representation of λ-terms.»

  [agdaFP|
  |data TmAlg a r = TmAlg { pVar :: a → r
  |                       , pLam :: (r → r) → r
  |                       , pApp :: r → r → r }
  |
  |cata :: TmAlg a r → Tm a → r
  |cata φ s = case s of
  |   Var x   → pVar φ x
  |   Lam b   → pLam φ (λ x → cata (extendAlg x φ) b)
  |   App t u → pApp φ (cata φ t) (cata φ u)
  |
  |extendAlg :: r → TmAlg a r → TmAlg (Succ a) r
  |extendAlg x φ = φ { pVar = pVarSucc }
  |  where
  |    pVarSucc (Here  _) = x
  |    pVarSucc (There y) = pVar φ y
  |]

  p"cataSize"
   «Finally, it is also possible to use {|cata|} to compute the size:»

  [agdaFP|
  |sizeAlg :: (a → Size) → TmAlg a Size
  |sizeAlg ρ = TmAlg { pVar = ρ
  |                  , pLam = λ f → 1 + f 1
  |                  , pApp = λ x y → 1 + x + y }
  |
  |cataSize :: (a → Size) → Tm a → Size
  |cataSize = cata . sizeAlg
  |]
-}


{-

  q«
   Our represtentation features three aspects which are usually kept separate. It
   has a nominal aspect, an higher-order aspect, and a de Bruijn indices aspect.
   Consequently, one can take advtantage of the benefits of each of there aspects when
   manipulating terms.

  ...»

  ...

  p"higher-order"«Second, we show the higher-order aspect. It is common in higher-order representations
   to supply a concrete value to substitute for a variable at each binding site.
   Consequently we will assume that all free variables
   are substituted for their size, and here the function will have type {|Tm Int → Int|}.

   In our {|size|} function, we will consider that each variable occurrence as the constant
   size 1 for the purpose of this example.

   This is be realised by applying the constant 1 at every function argument of a {|Lam|} constructor. One then needs
   to adjust the type to forget the difference between the new variable and the others, by applying an {|untag|} function
   for every variable. The variable and application cases then offer no surprises.
   »

  [agdaFP|
  |size1 :: Tm Size → Size
  |size1 (Var x) = x
  |size1 (Lam g) = 1 + size1 (fmap untag (g 1))
  |size1 (App t u) = 1 + size1 t + size1 u
  |]

  -- Scope Tm a → v → Tm (a ▹ v)
  -- Scope Tm a → a → Tm a

  {- NP: not sure about the usefulness of this

  p"de Bruijn"«Third, we demonstrate the de Bruijn index aspect. This time we assume an environment mapping
      de Bruijn indices {|Nat|} to the  their value of the free variables they represent (a {|Size|}
      in our case).
      In the input term, free variables
      are repenented merely by their index.
      When going under a binder represented by a function {|g|}, we apply {|g|} to a dummy argument {|()|},
      then we convert the structure of free variables {|Nat :> ()|} into {|Nat|}, using the {|toNat|} function.
      Additionally the environment is extended with the expected value for the new variable.»

  [agdaP|
  |size3 :: (Nat → Size) → Tm Nat → Size
  |size3 f (Var x) = f x
  |size3 f (Lam g) = 1 + size3 f' (fmap toNat (g ()))
  |  where f' Zero = 1
  |        f' (Succ n) = f n
  |size3 f (App t u) = 1 + size3 f t + size f u
  |
  |toNat (Here ()) = Zero
  |toNat (There x) = Succ x
  |]

  p"mixed style"«
  In our experience it is often convenient to combine the first and third approaches, as we
  illustrate below.
  This time the environment maps an arbitrary context {|a|} to a value.
  For each new variable,
  we pass the size that we want to assign to it to the binding function, and
  we extend the environment to use that value on the new variable, or
  lookup in the old environment otherwise.
  »
  -}
-}


  section $ «Bigger Examples» `labeled` examples
{-

  subsection $ «Test of α-equivalence»
  p""«
   Using our technique, two α-equivalent terms will have the same underlying representation. Despite this property,
   a Haskell compiler will refuse to generate an equality-test via a {|deriving Eq|} clause.
   This is caused by the presence of a function type inside the {|Tm|} type. Indeed, in general, extensional equality
   of functions is undecidable. Fortunately, equality for the parametric function type that we use {emph«is»} decidable.
   Indeed, thanks to parametricity, the functions cannot inspect their argument at all, and therefore it is
   sufficient to test for equality at the unit type, as shown below:
  »
  commentCode [agdaFP|
  |instance Eq a ⇒ Eq (Tm a) where
  |  Var x == Var x' = x == x'
  |  Lam g == Lam g' = g == g'
  |  App t u == App t' u' = t == t' && u == u'
  |]
  -- NP: I would like to see my more general cmpTm

  q«However the application of {|()|} is somewhat worrisome, because now different
    indices might get the same {|()|} type. Even though the possibility of a mistake is very low
    in code as simple as equality, one might want to do more complex analyses where the
    possibility of a mistake is real. In order to preempt errors, one should like to use the {|unpack|}
    combinator as below:»

  commentCode [agdaFP|
  |  Lam g == Lam g' = unpack g  $ λx  t  →
  |                    unpack g' $ λx' t' →
  |                    t == t'
  |]
  q«This is however incorrect. Indeed, the fresh variables {|x|} and {|x'|} would receive incompatible types, and
    in turn {|t|} and {|t'|} would not have the same type and cannot be compared. Hence we must use another variant
    of the {|unpack|} combinator, which maintains the correspondance between contexts in two different terms.»

  [agdaFP|
  |unpack2 :: (∀ v. v → f (a ▹ v)) →
  |           (∀ v. v → g (a ▹ v)) →
  |
  |           (∀ v. v → f (a ▹ v) →
  |                       g (a ▹ v) → b) →
  |           b
  |unpack2 f f' k = k fresh (f fresh) (f' fresh)
  |  where fresh = ()
  |]

  q«One can see {|unpack2|} as allocating a single fresh name {|x|} which is shared between {|t|} and {|t'|}.»

  commentCode [agdaFP|
  |  Lam g == Lam g' = unpack2 g g' $ λ x t t' →
  |                    t == t'
  |]

  [agdaFP|
  |type Cmp a b = a → b → Bool
  |
  |cmpTm :: Cmp a b → Cmp (Tm a) (Tm b)
  |cmpTm cmp (Var x1)    (Var x2)    =
  |  cmp x1 x2
  |cmpTm cmp (App t1 u1) (App t2 u2) =
  |  cmpTm cmp t1 t2 && cmpTm cmp u1 u2
  |cmpTm cmp (Lam f1) (Lam f2) =
  |  unpack f1 $ λ x1 t1 →
  |  unpack f2 $ λ x2 t2 →
  |  cmpTm (extendCmp x1 x2 cmp) t1 t2
  |cmpTm _ _ _ = False
  |
  |-- The two first arguments are ignored and thus only there
  |-- to help the user not make a mistake about a' and b'.
  |extendCmp :: a' → b' → Cmp a b → Cmp (a ▹ a') (b ▹ b')
  |extendCmp _ _ f (There x) (There y)  = f x y
  |extendCmp _ _ _ (Here _)  (Here _)   = True
  |extendCmp _ _ _ _         _          = False
  |]
-}
  subsection $ «Normalisation by evaluation» `labeled` nbeSec

  p"intro"
   «One way to evaluate terms is to evaluate each subterm to normal
    form. If a redex is encountered, a hereditary substitution is
    performed. This technique is known as normalisation by evaluation
    {cite nbecites}.»

  q«We can then define (by mutual recursion) the application of normal forms to normal forms, and a substittuer which hereditarily
  uses it.»

  [agdaFP|
  |app :: Tm a → Tm a → Tm a
  |app (Lam b) u = unpack b $ \x t → substituteTop x u t --TODO JP: FIXME: use hereditary subst.
  |app t u = App t u
  |]
  
  notetodo «stress the relation with >>=.»

  [agdaFP|
  |(=<<<) :: (a → Tm b) → Tm a → Tm b
  |θ =<<< Var x   = θ x
  |θ =<<< Lam b   = unpack b $ \x t → lamP x (liftSubst θ =<<< t)
  |θ =<<< App t u = app (θ =<<< t) (θ =<<< u)
  |]

  q«The evaluator can then be written as a simple recursion on the term structure:»
  [agdaFP|
  |eval :: Tm w → Tm w
  |eval (Var x) = Var x
  |eval (Lam t) = Lam (eval t)
  |eval (App t u) = app (eval t) (eval u)
  |]

  startComment -- TODO

  subsection $ «Closure Conversion»
  p"" «Following {citet[guillemettetypepreserving2007]}»
  q«We first define the target language. It features variables and applications as usual.
    Most importantly, it has a constructor for {|Closure|}s, composed of a body and an
    environment. The body of closures have exactly
    two free variables: {|vx|} for the parameter of the closure and {|venv|} for its environment.
    An environment will be realised by a {|Tuple|}. Inside the closure, elements of the environment
    will be accessed via their {|Index|} in the tuple. Finally, the {|LetOpen|} construction
    allows to access the components  of a closure (its first argument) in an arbitrary expression
    (its second argument). This arbitrary expression has two extra free variables:
    {|vf|} for the code of the closure and {|venv|} for its environment.
    »
  [agdaFP|
  |data LC w where
  |  VarLC :: w → LC w
  |  AppLC :: LC w → LC w → LC w
  |  Closure :: (∀ vx venv. vx → venv →
  |           LC (Zero ▹ venv ▹ vx)) →
  |           LC w →
  |           LC w
  |  Tuple :: [LC w] → LC w
  |  Index :: LC w → Int → LC w
  |  LetOpen :: LC a →
  |             (∀ vf venv. vf → venv →
  |              LC (a ▹ vf ▹ venv)) → LC a
  |]
  q«This representation is an instance of {|Functor|} and {|Monad|}, and the corresponding code
    offers no surprise.»

  q«We give a couple helper functions to construct applications and indexwise access in a tuple:»
  [agdaFP|
  |($$) = AppLC
  |infixl $$
  |
  |idx :: (v ∈ a) ⇒ v → Int → LC a
  |idx env = Index (var env)
  |]
  q«Closure conversion can then be implemented as a function from {|Tm|} to {|LC|}.
    The case of variables is trivial. For an abstraction, one must construct a closure,
    whose environment contains each of the free variables in the body. The application must
    open the closure, explicitly applying the argument and the environment.
  »

  dmath
   [texm|
   |\begin{array}{r@{\,}l}
   |  \llbracket x \rrbracket &= x \\
   |  \llbracket \hat\lambda x. e \rrbracket &= \mathsf{closure} (\hat\lambda x~x_\mathnormal{env}. e_\mathnormal{body}) e_\mathnormal{env} \\
   |                                         &\quad \mathsf{where}~\begin{array}[t]{l@{\,}l}
   |                                                                  y_1,\ldots,y_n & = FV(e) \\
   |                                                                  e_\mathnormal{body} & = \llbracket e \rrbracket[x_{env}.i/y_i] \\
   |                                                                  e_\mathnormal{env} & = \langle y_1,\ldots,y_n \rangle
   |                                                               \end{array}\\
   |  \llbracket e_1@e_2 \rrbracket &= \mathsf{let} (x_f,x_\mathnormal{env}) = \mathsf{open} \llbracket e_1 \rrbracket \\
   |                                &\quad \mathsf{in} x_f \langle \llbracket e_2 \rrbracket , x_\mathnormal{env} \rangle
   |\end{array}
   |]

  notetodo «Include fig. 2 from {cite[guillemettetypepreserving2007]}»
  q«The implementation follows the pattern given by {citet[guillemettetypepreserving2007]}.
    We make one modification: in closure creation, instead of binding one by one the free variables {|yn|} in the body
    to elements of the environment, we bind them all at once, using a substitution which maps variables to their
    position in the list {|yn|}.»

  [agdaFP|
  |cc :: Eq a ⇒ Tm a → LC a
  |cc (Var x) = VarLC x
  |cc t0@(Lam b) =
  |  let yn = nub $ freeVars t0
  |  in closure (λ x env → cc (f x) >>=
  |                   liftSubst (idxFrom yn env))
  |             (Tuple $ map VarLC yn)
  |cc (App e1 e2) =
  |  letOpen (cc e1)
  |          (\f x → var f $$ wk (cc e2) $$ var x)
  |
  |idxFrom :: Eq a ⇒ [a] → v → a → LC (Zero ▹ v)
  |idxFrom yn env z = idx env $ fromJust $ elemIndex z yn
  |]
  stopComment

  q«
    Notably, {citeauthor[guillemettetypepreserving2007]} modify the function to
    take an additional substitution argument, citing the difficulty to support
    a direct implementation with de Bruijn indices. We need not do any such thing:
    modulo our slight modification,
    our representation is natural enough to support a direct implementation of the
    algorithm.»

  subsection $ «CPS Transform» `labeled` cpsSec

  p"intro"
   «The next example is a transformation to continuation-passing
    style (CPS) based partially on {cite[chlipalaparametric2008]} and
    {cite[guillemettetypepreserving2008]}.

    The main objective of the transformation is to make explicit the
    order of evaluation, {|let|}-binding every intermediate {|Value|} in
    a specific order. To this end, we target as special representation,
    every intermediate result is named. We allow for {|Value|}s to be
    pairs, so we can easily replace each argument with a pair of an
    argument and a continuation.»

{-
  [agdaFP|
  |data TmC a where
  |  HaltC :: a → TmC a
  |  AppC  :: a → a → TmC a
  |  LetC  :: Value a → TmC (Succ a) → TmC a
  |
  |data Value a where
  |  LamC  :: TmC (Succ a) → Value a
  |  PairC :: a → a → Value a
  |  FstC  :: a → Value a
  |  SndC  :: a → Value a
  |]
-}

  [agdaFP|
  |data TmC a where
  |  HaltC :: Value a → TmC a
  |  AppC  :: Value a → Value a → TmC a
  |  LetC  :: Value a → TmC (Succ a) → TmC a
  |
  |data Value a where
  |  LamC  :: TmC (Succ a) → Value a
  |  PairC :: Value a → Value a → Value a
  |  VarC  :: a → Value a
  |  FstC  :: a → Value a
  |  SndC  :: a → Value a
  |]

  p"smart constructors"
   «We do not use {|Value|}s directly, but instead their composition with injection.»

  {-
  [agdaFP|
  |type PolyScope f a = ∀ v. v → f (a ▹ v)
  |
  |haltC :: (v ∈ a) ⇒ v → TmC a
  |appC  :: (v ∈ a, v' ∈ a) ⇒ v → v' → TmC a
  |letC  :: Value a → PolyScope TmC a → TmC a
  |
  |lamC  :: PolyScope TmC a → Value a
  |pairC :: (v ∈ a, v' ∈ a) ⇒ v → v' → Value a
  |fstC  :: (v ∈ a) ⇒ v → Value a
  |sndC  :: (v ∈ a) ⇒ v → Value a
  |]
  -}

  [agdaFP|
  |type PolyScope f a = ∀ v. v → f (a ▹ v)
  |
  |varC :: (v ∈ a) ⇒ v → Value a
  |letC :: Value a → PolyScope TmC a → TmC a
  |lamC :: PolyScope TmC a → Value a
  |fstC :: (v ∈ a) ⇒ v → Value a
  |sndC :: (v ∈ a) ⇒ v → Value a
  |]

  -- smart constructor for
  --    λ(x1,x2)→f x1 x2
  -- internally producing
  --    λp→ let x1 = fst p in
  --        let x2 = snd p in
  --        f x1 x2

  [agdaFP|
  |type PolyScope2 f a = forall v1 v2. v1 → v2 → f (a ▹ v1 ▹ v2)
  |
  |lamPairC :: PolyScope2 TmC a → Value a
  |lamPairC f = lamC $ \p →
  |              letC (fstC p) $ \x1 →
  |              letC (sndC p) $ \x2 →
  |              wk $ f x1 x2
  |]

  p"Functor TmC"
   «As {|Tm|}, {|TmC|} enjoys a functor structure, with a
    straightforward implementation found in appendix. However, this
    new syntax is not stable under substitution. Building a monadic
    structure would be more involved, and is directly tied to the
    transformation we perform and the operational semantics of the
    language, so we omit it.»

  p"the transformation"
   «We implement a one-pass CPS transform (administrative redexes are
    not created). This is done by passing a host-language continuation
    to the transformation. At the top-level the halting continuation
    is used. A definition of the transformation using mathematical
    notation could be written as follows. We use a hat to distinguish
    object-level abstractions ({tm|\hat\lambda|}) from host-level ones.
    Similarly, the {tm|@|} sign is used for object-level applications. »

  dmath
   [texm|
   |\begin{array}{r@{\,}l}
   | \llbracket x \rrbracket\,\kappa &= \kappa\,x \\
   | \llbracket e_1 \,@\, e_2 \rrbracket\,\kappa &= \llbracket e_1 \rrbracket (\lambda f. \\
   |                                       &\quad \llbracket e_2 \rrbracket (\lambda x. \\
   |                                       &\quad \mathsf{let}\, p = \langle x, \kappa \rangle \\
   |                                       &\quad \mathsf{in}\,\quad f \, @ \, p ) ) \\
   | \llbracket \hat\lambda x. e \rrbracket \kappa &= \mathsf{let}\, f = \hat\lambda p. \begin{array}[t]{l}
   |                                       \mathsf{let}\, x_1 = \mathsf{fst}\, p \,\mathsf{in}\\
   |                                       \mathsf{let}\, x_2  = \mathsf{snd}\, p \,\mathsf{in} \\
   |                                       \llbracket e[x_1/x] \rrbracket (\lambda r.\, x_2 \, @ \, r) \end{array}  \\
   |                                      &\quad \mathsf{in} \, \kappa\,f
   |\end{array}
   |]

  p"latex vs. haskell"
   «The implementation follows the above definition, except for the
    following minor differences. For the {|Lam|} case, the only
    deviation are is an occurrence of {|wk|}. In the {|App|} case, we
    have an additional reification of the host-level continuation as a
    proper {|Value|}, {|LamC|} constructor.

    In the variable case, we must pass the variable {|v|} to the continuation. Doing so
    yields a value of type {|TmC (a ▹ a)|}. To obtain a result of the right type it suffices to remove
    the extra tagging introduced by {|a ▹ a|} everywhere in the term, using {|fmap untag|}.»

  {-
  [agdaFP|
  |cps :: Tm a → (∀ v. v → TmC (a ▹ v)) → TmC a
  |cps (Var x)     k = fmap untag (k x)
  |cps (App e1 e2) k =
  |  cps e1 $ \f →
  |  cps (wk e2) $ \x →
  |  LetC (LamC (\x → wk (k x))) $ \k' →
  |  LetC (pairC x k') $ \p →
  |  appC f p
  |cps (Lam e')    k =
  |  LetC (LamC $ \p → LetC (fstC p) $ \x →
  |                   LetC (π2 p) $ \k' →
  |                   cps (wk (e' x)) $ \r →
  |                   appC k' r)
  |      k
  |]
  -}

  -- |cps :: Tm a -> Poly TmC a -> TmC a
  [agdaFP|
  |-- same as succToPoly
  |inst1 :: Functor f ⇒ f (Succ a) → v → f (a ▹ v)
  |inst1 t x = fmap (bimap id (const x)) t
  |
  |cps :: Tm a → (∀ v. v → TmC (a ▹ v)) → TmC a
  |cps (Var x)     k = untag <$> k x
  |cps (App e1 e2) k =
  |  cps e1 $ \x1 →
  |  cps (wk e2) $ \x2 →
  |  AppC (varC x1)
  |       (PairC (varC x2)
  |              (lamC (\x → wk $ k x)))
  |cps (Lam e')    k =
  |  letC (lamPairC $ \x1 x2 →
  |        cps (fmap There $ inst1 e' x1) $ \r →
  |        AppC (varC x2) (varC r)) k
  |
  |cps0 :: Tm a → TmC a
  |cps0 t = cps t $ HaltC . varC
  |]

  -- |cpsMain :: Tm a → TmC a
  -- |cpsMain x = cps x haltC

  q«It is folklore that a CPS transformation is easier to implement with higher-order abstract
  syntax {cite[guillemettetypepreserving2008,washburnboxes2003]}. Our representation of
  abstraction features a very limited form of higher-order representation.
  (Namely, a quantification, over a universally quantified type.)
  However limited, this higher-order aspect is enough to allow an easy implementation of
  the CPS transform.»

  
  section $ «Comparisons» `labeled` comparison

  notetodo «Why don't we compare interfaces instead of representation?»
  notetodo «Tell that any representation embodies an interface»
  notetodo «Tell how interfaces of locally-nameless (including Binders Unbound), α-caml, Fresh(OCaml)ML are all
            unsafe and require some side effects.»

  subsection $ «Fin»

  p"Fin approach description"
   «Another approach already used and described in {cite fincites} is
    to index terms, names, etc. by a number, a bound. This bound is the
    maximum number of distinct free variables allowed in the value. This
    rule is enforced in two parts: variables have to be strictly lower
    than their bound, and the bound is incremented by one when crossing
    a name abstraction (a λ-abstraction for instance).»

  p"Fin type description"
   «The type {|Fin n|} is used for variables and represents natural
    numbers strictly lower than {|n|}. The name {|Fin n|} comes from the
    fact that it defines finite sets of size {|n|}.»

  p"Fin/Maybe connection"
   «We can draw a link with the Nested Abstract Syntax. Indeed,
    as with the type {|Succ|} ({|(▹ ())|} or {|Maybe|}), the
    type {|Fin (suc n)|} has exactly one more element than the
    type {|Fin n|}. However, these approaches are not equivalent for at
    least two reasons. The Nested Abstract Syntax can accept any type to
    represent variables. This makes the structure more like a container
    and this can be particularly helpful to define the monadic structure
    (substitution). The {|Fin|} approach has advantages as well: the
    representation is concrete and simpler since closer to the original
    approach for de Brujin indices. In particular the representation of
    variables free and bound is more regular and could be more amenable
    to optimize variables as machine integers.»

  {- There might even be ways to get a similar interface for Fin,
     it might get closer McBride approach, tough -}

  subsection $ «Kmett's Bound» -- TODO: NP

  -- TODO flow
  q«The main performance issue with de Brujin indices from the cost
    of importing terms into scopes without capture, this requires to
    increment the free-variables which incures not only a cost but a
    lost of sharing.»

  -- TODO off-topic
  q«On top of that Nested Abstract Syntax misses a controlled and
    uniform way to represent variables which prevents from using machine
    integers to represent all the variables.»

  subsection $ «HOAS: Higher-Order Abstract Syntax»

  q«A way to represent bindings of an object language is via the
    bindings of the host language. One naive translation of this idea
    yields the following term representation:»

  [agdaP|
  |data TmH = LamH (TmH → TmH) | AppH TmH TmH
  |]

  q«An issue with this kind of representation is the presence of
    so-called “exotic terms”: a function of type {|TmH → TmH|} which
    performs pattern matching on its argument does not necessarily
    represent a term of the object language. A proper realisation of the
    HOAS ideas should only allow functions which use their argument for
    substitution.»

  q«It has been observed before that one can implement this restriction
    by using polymorphism. This observation also underlies the safety of
    our {|PolyScope|} representation.»

  q«Another disadvantage of HOAS is the negative occurrence
    of the recursive type, which makes it tricky to analyse
    terms {citet[washburnboxes2003]}.»

  subsection «PHOAS: Parametric Higher-Order Abstract Syntax» 

  q«{citet[chlipalaparametric2008]} describes a way to represent binders
    using polymorphism and functions. Using that technique, called
    Parametric Higher-Order Abstract Syntax (PHOAS), terms of the
    untyped λ-calculus are as represented follows:»

  [agdaFP|
  |data TmP a where
  |  VarP :: a → TmP a
  |  LamP :: (a → TmP a) → TmP a
  |  AppP :: TmP a → TmP a → TmP a
  |]

  q«Then, only universally quantified terms corresponds to terms of the λ-calculus:»

  [agdaFP|
  |type TmP' = ∀ a. TmP a
  |]

  q«The reprensentation of binders used by Chlipala can be seen as a
    special version of {|PolyScope|}, where all variables are assigned
    the same type. This specialisation has pros and cons. On the plus
    side, substitution is easier to implement with PHOAS: one needs not
    handle fresh variables specially. The corresponding implementation
    of the monadic {|join|} is as follows:»

  [agdaP|
  |joinP (VarP x)   = x
  |joinP (LamP f)   = LamP (λ x → joinP (f (VarP x)))
  |joinP (AppP t u) = AppP (joinP t) (joinP u)
  |]

  q«On the minus side, all the variables (bound and free) have the
    same representation. This means that they cannot be told apart
    within a term of type {|∀a. TmP a|}. Additionally, once the type
    variable {|a|} is instantiated to a closed type, one cannot recover
    the polymorphic version. Furthermore while {|Tm Zero|} denotes a
    close term, {|TmP Zero|} denotes a term without variables, hence no
    term at all. Therefore, whenever a user of PHOAS needs to perform
    some manipulation on terms, they must make an upfront choice of a
    particular instantiation for the parameter of {|TmP|} that supports
    all the operations required on free variables. This limitation is
    not good for modularity and code clarity in general. Another issue
    arises from the negative occurence of the variable type. Indeed this
    makes the type {|TmP|} invariant: it cannot be made a {|Functor|}
    nor a {|Traversable|} and this not a proper {|Monad|} either.»

  q«The use-case of PHOAS presented by Chlipala is the representation
    of well-typed terms. That is, the parameter to {|TmP|} can be made
    a type-function, to capture the type associated with each variable.
    This is not our concern here, but we have no reason to believe that
    our technique cannot support this, beyond the lack of proper for
    type-level computation in Haskell --- Chlipala uses {_Coq} for his
    development.»

  subsection «Syntax for free»

  q«Robert Atkey {cite[atkeyhoas09]} revisited the polymorphic encoding
    of the HOAS representation of the untyped lambda calculus. By
    constructing a model of System F's parametricity in {_Coq} he could
    formally prove that polymorphism indeed rules out the exotic terms.
    Name abstractions, while represented by computational functions,
    these functions cannot react to the shape of their argument and thus
    behave as substitutions. Here is this representation in Haskell:»

  [agdaFP|
  |type TmF = ∀ a. ((a → a) → a)  -- lam
  |              → (a → a → a)    -- app
  |              → a
  |]

  q«And our familiar application function:»

  [agdaFP|
  |apTmF :: TmF
  |apTmF lam app = lam $ λ f → lam $ λ x → f `app` x
  |]

  p"catamorphism only & can't go back"
   «Being a polymorphic encoding, this technique is locked away in the
    use of fold-based/catamorphism-based elimination of terms. Moreover
    there seems to be no safe way to convert a term of this polymorphic
    encoding to another safe representation of names. Indeed, as Atkey
    shows it, this conversion relies on the Kripke version of the
    parametricity result of this type.»

{- NP: what about putting this in the catamorphism section with a forward ref
  - to here?
  [agdaFP|
  |tmToTmF :: Tm Zero → TmF
  |tmToTmF t lam app = cata (TmAlg magic lam app)
  |]
  -}

  subsection $ «McBride's “Classy Hack”»

  -- the point of types isn’t the crap you’re not allowed to write,
  -- it’s the other crap you don’t want to bother figuring out.

  p "" «{citet[mcbridenot2010]} has devised a set of combinators to construct
        λ-terms in de Brujin representation, with the ability to refer to
        bound variables by name. Terms constructed using McBride's technique are
        textually identical to terms constructed using ours. Another point of
        similiarity is the use of instance search to recover the indices from a
        host-language variable name.

        Another difference is that McBride integrates the injection in the abstraction
        constructor rather than the variable constructor. The type of the {|var|} combinator becomes then
        simpler, at the expense of {|lam|}:
        »

  commentCode [agdaP|
  |lam :: ((∀ n. (Leq (S m) n ⇒ Fin n)) → Tm (S m))
  |       → Tm m
  |var :: Fin n → Tm n
  |]
  p "" «An advantage of McBride's interface is that it does not require the “incoherent instances” extension. »
  -- 'Ordered overlapping type family instances' will improve the situation for us.
  p "" «However the above interface reveals somewhat less precise types than what we use.
        Notably, the {|Leq|} class captures only one aspect of context inclusion (captured by the class {|⊆|}
        in our development),
        namely that one context should be smaller than another.
        This means, for example, that the class constraint {|w ⊆ w'|} can be meaning fully resolved
        in more cases than {|Leq m n|}, in turn making functions such as {|wk|} more useful in practice.»

  q«Additionally, our {|unpack|} and {|pack|} combinators extend the technique to term analysis and manipulation.»

  subsection $ «NomPa (nominal fragment)» -- TODO: NP (revise -- optional eq. tests.) 

{-
    -- minimal kit to define types
    World  : Set
    Name   : World → Set
    Binder : Set
    _◅_    : Binder → World → World

    -- An infinite set of binders
    zeroᴮ : Binder
    sucᴮ  : Binder → Binder

    -- Converting names and binders back and forth
    nameᴮ   : ∀ {α} b → Name (b ◅ α)
    binderᴺ : ∀ {α} → Name α → Binder

    -- There is no name in the empty world
    ø      : World
    ¬Nameø : ¬ (Name ø)

    -- Names are comparable and exportable
    _==ᴺ_   : ∀ {α} (x y : Name α) → Bool

    -- The fresh-for relation
    _#_  : Binder → World → Set
    _#ø  : ∀ b → b # ø
    suc# : ∀ {α b} → b # α → (sucᴮ b) # (b ◅ α)

    Since we follow a de Bruijn style these are moot: type (:#) a b = (),
      const (), const ()

    -- inclusion between worlds
    _⊆_     : World → World → Set
    coerceᴺ  : ∀ {α β} → (α ⊆ β) → (Name α → Name β)
    ⊆-refl  : Reflexive _⊆_
    ⊆-trans : Transitive _⊆_
    ⊆-ø     : ∀ {α} → ø ⊆ α
    ⊆-◅     : ∀ {α β} b → α ⊆ β → (b ◅ α) ⊆ (b ◅ β)
    ⊆-#     : ∀ {α b} → b # α → α ⊆ (b ◅ α)

    In Haskell respectively (->), id, id, (.), magic, \f -> bimap f id,
      const There.

  zeroᴮ : Binder
  zeroᴮ = Zero

  sucᴮ : Binder → Binder
  sucᴮ = Succ

* name abstraction
ƛ   : ∀ b → Tm (b ◅ α) → Tm α
-}

  p""
   «{citet[pouillardunified2012]} describe an interface for names and
    binders which provides maximum safety. The library {|NomPa|} is
    writen in {_Agda}, using dependent types. The interface makes use
    of a notion of {|World|}s (intuitively a set of names), {|Binder|}s
    (name declaration), and {|Name|}s (the occurrence of a name).

    A {|World|}   can   either   be {|Empty|}   (called {|ø|}   in   the
    library {|NomPa|}) in or  result of the addition  of a {|Binder|} to
    an existing {|World|}, using the operator {|(◅)|}. The type {|Name|}
    is indexed by {|World|}s: this ties occurrences to the context where
    they make sense.»

  commentCode [agdaP|
  |World :: *
  |Binder :: *
  |Empty :: World
  |(◅) :: Binder → World → World
  |Name :: World → *
  |]

  p""«
  On top of these abstract notions, one can construct the following representation of terms (we use
  a Haskell-like syntax for dependent types, similar to that of {_Idris}):
  »

  commentCode [agdaP|
  |data Tm α where
  |  Var :: Name α → Tm α
  |  App :: Tm α → Tm α → Tm α
  |  Lam :: (b :: Binder) → Tm (b ◅ α) → Tm α
  |]

  q«The safety of the technique comes from the abstract character of the
    interface. If one were to give concrete definitions for {|Binder|},
    {|World|} and their related operations, it becomes possible for user
    code to cheat the system.

    A drawback of the interface being abstract is that some subterms
    do not evaluate. This point is of prime concern in the context of
    reasoning about programs involving binders.

    In contrast, our is interfaces are concrete (code using it
    will always evaluate), but it requires the user to chose the
    representation appropriate to the current use ({|SuccScope|},
    {|PolyScope|} or {|ExistScope|}).»

  {- NP

    NomPa names are always comparable for equality (when they inhabit a common
    world). I would now prefer some notion of equality-world (Eqᵂ).

    Eqᵂ : World → Set
    _==ᴺ_ : ∀ {α} {{αᴱ : Eqᵂ α}} → Name α → Name α → Bool

    and then some rules for Eqᵂ (instances):

    øᴱ : Eqᵂ ø
    _◅ᴱ_ : ∀ {α} b → Eqᵂ α → Eqᵂ (b ◅ α)
    _+1ᴱ : ∀ α → Eqᵂ α → Eqᵂ (α +1)

    Derived
    _↑1ᴱ : ∀ α → Eqᵂ α → Eqᵂ (α ↑1)
    α ↑1ᴱ = 0ᴮ ◅ᴱ (α +1ᴱ)

    The goal then would be to gain stronger free-thms for instance:
      E = ∀ {α} → Eqᵂ α → Tm α → Tm α

      vs.

      F = ∀ {α} → Tm α → Tm α

    In the old model both where undistinguished. Now E is as the old one
    and F is stronger. Functions of type E commutes with injective functions,
    and F commutes with all functions.

    It seems that the construction would be as follows:
    ⟦World⟧ was a relation on names which preserves equalities, now have
    two parts:

    ⟦World⟧ α₁ α₂ = Name α₁ → Name α₂ → Set

    ⟦Eqᴱ⟧ αᵣ = Preserve-≡ αᵣ
    -- expanded
    ⟦Eqᴱ⟧ αᵣ = ∀ x₁ y₁ x₂ y₂ → αᵣ x₁ x₂ → αᵣ y₁ y₂
                             → x₁ ≡ y₁ ↔ x₂ ≡ y₂

    ⟦Name⟧ = id
    -- expanded
    ⟦Name⟧ αᵣ x₁ x₂ = αᵣ x₁ x₂

    ⟦ø⟧ and _⟦◅⟧_ carry only their relation part.
    ⟦øᴱ⟧ and _⟦◅ᴱ⟧_ carry the preservation property.

    _⟦==ᴺ⟧_ is the only one needing this property and now it's the only
    one receiving it!

    The main benefit is when using a parametricity theorem of a truly
    (no Eq) world-polymorphic object, we would now be able to pick any
    relation and thus such a relation can be the graph (i.e. underlying
    relation) of any function!

    In the end this seems like to fit very nicely alotgether and the design
    was really close to that. One question could be: What process could
    have let us uncover this sooner? I think that definition of ⟦World⟧ was
    culpirt. It was a subset of all the relations and this should seen as
    a signal for further separation of concerns.
  -}

  subsection $ «Multiple Binders/Rec/Pattern/Telescope» -- TODO: NP


{-
  Lam :: Binding Tm a -> Tm a
  type BindingS tm a = tm (Succ a) -- = tm (a :▹ ()) ≅ tm (Maybe a)
  type BindingH tm a = ∀ v. v -> tm (a :▹ v)
  data BindingN tm a where
    Binding :: v -> tm (a :▹ v) -> Binding tm a

  Tm bnd a -> Tm bnd' a'

  BindingS f a ≅ BindingH f a ≅ BindingN f a

  Functor f =>
  f () ≅ ∀ v. v → f v ≅ ∃ v. (v, f v)

  to :: f () → ∃ v. (v, f v)
  to t = ((), t)

  {- recall the definition of void from Control.Monad

  -- | @'void' value@ discards or ignores the result of evaluation, such as the return value of an 'IO' action.
  void :: Functor f => f a -> f ()
  void = fmap (const ())
  -}

  from :: Functor f => ∃ v. (v, f v) → f ()
  from (_, t) = void t

  to (from (x, t)) = to (void t)
                   = ((), void t)
                   TODO
                   ... this works because of the way "extensional" equality on existentials (should) work

  ⟨ f ⟩ x y = f x ≡ y
  (⟨ id ⟩ x y) ≡ (id x ≡ y) ≡ (x ≡ y)

  ⟦f⟧ : (a → b → ★) → f a → f b → ★

  ⟦f⟧-refl : ∀ x → ⟦f⟧ _≡_ x x

  ⟦f⟧-fmap : ∀ g x → ⟦f⟧ ⟨ g ⟩ x (fmap g x)

    note that
      ⟦f⟧-fmap id : ∀ x → ⟦f⟧ ⟨ id ⟩ x (fmap id x)
                  : ∀ x → ⟦f⟧ ⟨ id ⟩ x (id x)
                  : ∀ x → ⟦f⟧ ⟨ id ⟩ x x
                  : ∀ x → ⟦f⟧ _≡_    x x
   so
      ⟦f⟧-refl = ⟦f⟧-fmap id -- provided fmap id = id

  R-∃ : (p1 p2 : ∃a. f a) → ★
  R-∃ (X1 , x1) (X2 , x2) = ⟦f⟧ Full x1 x2

  ∀ (t :: f ()) -> void t = t

  -- at type (), const () = id
  const () ≗ id :: () -> ()

  -- at type (), void = id
  void = fmap (const ()) = fmap id = id :: Functor f => f () -> f ()

  from (to t) = from ((), t)
              = void t
              = t
-}

  --------------------------------------------------
  -- JP
  section $ «Discussion» `labeled` discussion

  subsection «Power of the representation»
  p"" «{citet[guillemettetypepreserving2008]}
     change representation from HOAS to de Bruijn indices, arguing that HOAS is more suitable for
     CPS transform, while de Bruijn indices are more suitable for closure conversion.
     Our reprensentation supports a natural implementation of both transformations.
     »

  subsection «Future work: both aspects in one»

  p "even more safety by no instanciation" «
  Each of the dual representation of bindings ensure one aspect of safety. One may
  wonder if it is possible to combine the safety of both. This suggest a type-system feature
  to represent the intersection of {|PolyScope tm|} and {|ExistScope tm|}.
  This is reminiscent of the ∇ quantifier of {citet[millerproof2003]}.
  »

  p "performance!" «
  One could also wish to obtain performance aspects of both representations.
  A moment's thought  reveals that it might be possible not to pay the cost
  of the application to {|()|} in the definition of {|unpack|}. Indeed, because
  of parametricity, the continuation can never inspect the values which have
  been substituted for the variables. This means that a clever compiler may
  implement the application specially, omitting to perform any substitution.
  »

  subsection «Future work: no injections»

  p "getting rid of the injections by using a stronger type system" «
    We use the powerful GHC instance search in a very specific way: only to discover in injections.
    This suggests that a special-purpose type-system (featuring a form of subtyping)
    could be built to take care of those injections automatically.
    An obvious benefit would be some additional shortening of programs manipulating terms.
    A more subtle one is that, since injections would not be present at all, the performance
    would be increased. Additionally, this simplification of programs would imply an
    even greater simplification of the proofs about them; indeed, a variation in complexity in
    an object usually yields a greater variation in complexity in proofs about it.
  »

  subsection «Misc.»


  p "more remarks about safety" «
  We do not suffer from name-capture and complicated α-equivalence problems; but
  we can conveniently call variables by their name.
  »


  p "" «impredicativity»


  notetodo «What about:»
  itemize $ do
--    it «PHOAS»
--    it «Functor/Monad/Categorical structure»
--    it «Traversable»
 --   it «Maybe»
 --   it «succ-less (Kmett)» -- http://www.slideshare.net/ekmett/bound-making-de-bruijn-succ-less
    it «isomorphisms»
 --   it «safety»
 --   it «Worlds»
    it «free theorem: world-polymorphic term functions»
 --   it «example programs (fv, eta?, nbe, CPS, closure-conv.)»
--    it «type class coercions»
--    it «performance benchmark (fv, nbe)»
--    it «functions are only substitutions»
  --  it «our binder is closest to the "real meaning" of bindings»
 --   it «shallow interface/smart constructors»
--    it «mcbride "classy hack"»
--    it «"free" substitutions»

  acknowledgements   «We thank Emil Axelsson and Koen Claessen for enlightening discussions.»


appendix = execWriter $ do
  section $ «Implementation details» `labeled` implementationExtras
  subsection «CPS»

{-
  |  fmap f (FstC x)    = FstC (f x)
  |  fmap f (SndC x)    = SndC (f x)
  |  fmap f (PairC x y) = PairC (f x) (f y)
  |  fmap f (LamC t)    = LamC (fmap (bimap f id) t)

  |  fmap f (HaltC x)  = HaltC (f x)
  |  fmap f (AppC x y) = AppC (f x) (f y)
  |  fmap f (LetC p t) = LetC (fmap f p) (fmap (bimap f id) t)
  -}
  [agdaP|
  |instance Functor Value where
  |  fmap f (VarC x)      = VarC (f x)
  |  fmap f (FstC x)      = FstC (f x)
  |  fmap f (SndC x)      = SndC (f x)
  |  fmap f (PairC v1 v2) = PairC (fmap f v1) (fmap f v2)
  |  fmap f (LamC t)      = LamC (fmap (bimap f id) t)
  |
  |instance Functor TmC where
  |  fmap f (HaltC v)    = HaltC (fmap f v)
  |  fmap f (AppC v1 v2) = AppC  (fmap f v1) (fmap f v2)
  |  fmap f (LetC p t)   = LetC (fmap f p) (fmap (bimap f id) t)
  |]

  [agdaP|
  |letC p f = LetC p (f ())
  |varC = VarC . inj
  |lamC f = LamC (f ())
  |fstC = FstC . inj
  |sndC = SndC . inj
  |]

{-
  |letC p f  = LetC p (f ())
  |lamC f    = LamC (f ())
  |pairC x y = PairC (inj x) (inj y)
  |fstC      = FstC . inj
  |sndC      = SndC . inj
  |appC x y  = AppC (inj x) (inj y)
  |haltC     = HaltC . inj
  -}

  subsection «Closure Conversion»

  startComment -- TODO: uncomment
  [agdaP|
  |instance Functor LC where
  |  fmap f t = t >>= return . f
  |
  |instance Monad LC where
  |  return = VarLC
  |  VarLC x >>= θ = θ x
  |  Closure c env >>= θ = Closure c (env >>= θ)
  |  LetOpen t g >>= θ =
  |    LetOpen (t >>= θ) (λ f env → g f env >>= liftSubst (liftSubst θ))
  |  Tuple ts >>= θ = Tuple (map (>>= θ) ts)
  |  Index t i >>= θ = Index (t >>= θ) i
  |  AppLC t u >>= θ = AppLC (t >>= θ) (u >>= θ)
  |]
  stopComment

  section $ «Bind and substitute an arbitrary name»
  [agdaP|
  |packGen :: ∀ f v a b w. (Functor f, Insert v a b) ⇒
  |           v → f b → (w → f (a ▹ w))
  |packGen _ t x = fmap (shuffle cx) t
  |  where cx :: v → w
  |        cx _ = x
  |
  |class (v ∈ b) ⇒ Insert v a b where
  |  -- inserting 'v' in 'a' yields 'b'.
  |  shuffle :: (v → w) → b → a ▹ w
  |
  |instance Insert v a (a ▹ v) where
  |  shuffle f (Here x) = Here (f x)
  |  shuffle f (There x) = There x
  |
  |instance Insert v a b ⇒ Insert v (a ▹ v') (b ▹ v') where
  |  shuffle f (Here x) = There (Here x)
  |  shuffle f (There x) = case shuffle f x of
  |    Here y → Here y
  |    There y → There (There y)
  |
  |substituteGen :: (Insert v a b, Functor tm, Monad tm) ⇒ 
  |                 v → tm a → tm b → tm a
  |substituteGen x t u = 
  |   substituteTop x t (fmap (shuffle id) u)
  |]

  section $ «NomPa details»
  [agdaP|
  |-- ¬Nameø : ¬ (Name ø)
  |noEmptyName :: Zero → a
  |noEmptyName = magic
  |
  |-- nameᴮ : ∀ {α} b → Name (b ◅ α)
  |name :: b → a ▹ b
  |name = Here
  |
  |-- In Agda: exportᴺ? : ∀ {b α} → Name (b ◅ α) → Maybe (Name α)
  |exportM :: a ▹ b → Maybe a
  |exportM (Here _)  = Nothing
  |exportM (There x) = Just x
  |
  |-- In Agda: exportᴺ : ∀ {α b} → Name (b ◅ α) → Name (b ◅ ø) ⊎ Name α
  |export :: a ▹ b → Either (Zero ▹ b) a
  |export (Here x)  = Left (Here x)
  |export (There x) = Right x
  |]

  stopComment
  stopComment
  stopComment
  stopComment
  stopComment
  return ()
-- }}}

-- {{{ build
-- NP: what about moving this outside, such as run.sh
-- JP: Nope. I'd rather not leave emacs haskell mode.
refresh_jp_bib = do
  let jpbib = "../../gitroot/bibtex/jp.bib"
  e ← doesFileExist jpbib
  when e $ do putStrLn "refreshing bib"
              void . system $ "cp " ++ jpbib ++ " ."

main = do
  args ← getArgs
  refresh_jp_bib
  case args of
    ["--tex"]  → printLatexDocument (doc False)
    ["--agda"] → printAgdaDocument  (doc True)
    [] → do
      writeAgdaTo "PaperCode.hs" $ (doc True)
      compile ["sigplanconf"] "paper" (doc False)
    _ → error "unexpected arguments"

doc includeUglyCode = document title authors keywords abstract (body includeUglyCode) appendix
-- }}}

-- vim: foldmarker
-- -}


{-

Pie in the sky:
---------------

We can then represent binders as:

∇v. v ⊗ (v → Tm (a ▹ v))


- 'destroying'/analysis of the term is done by applying the function to the 1st
  argument of the pair.
- constructing a term feels like it should use excluded middle (of LL) to
  produce the argument of the pair from whatever is passed to the function.
  Intuitively, you can do this because any code using either component of the pair
  must use the other part as well. Unfortunately I cannot see how to implement this
  technically.


Linear logic treatment of ∇:

   α; Γ, A[α] ⊢
------------------ ∇
   Γ, ∇α.A[α] ⊢


∇ eliminates with itself:


   α; Γ, A[α] ⊢              β; Δ, ~A[β] ⊢
------------------ ∇      ------------------ ∇
   Γ, ∇α.A[α] ⊢              Γ, ∇β.~A[β] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


   α; Γ, A[α] ⊢              α; Δ, ~A[α] ⊢
----------------------------------------------- cut
      α; Γ, Δ ⊢ prf
   --------------------
      Γ, Δ ⊢ να. prf


For the fun we can also see the following, but that's just
a bonus:

∇ eliminates with ∃ (identical to the above)
∇ eliminates with ∀:


  α; Γ, A[α] ⊢              Δ, ~A[B] ⊢
------------------ ∇      ------------------ ∀
   Γ, ∇α.A[α] ⊢              Γ, ∀β.~A[β] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


   Γ, A[~B] ⊢              Δ, ~A[B] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


So it's easy to see that ∇ is a subtype of ∃ and ∀.



-}
