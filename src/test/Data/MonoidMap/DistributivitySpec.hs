{-# LANGUAGE RankNTypes #-}
{- HLINT ignore "Redundant bracket" -}
{- HLINT ignore "Use camelCase" -}
{- HLINT ignore "Use null" -}

-- |
-- Copyright: © 2022–2025 Jonathan Knowles
-- License: Apache-2.0
--
module Data.MonoidMap.DistributivitySpec
    ( spec
    ) where

import Prelude

import Control.Monad
    ( forM_ )
import Data.Data
    ( typeRep )
import Data.Function
    ( (&) )
import Data.Maybe
    ( isJust )
import Data.MonoidMap
    ( MonoidMap, get )
import Data.Proxy
    ( Proxy (..) )
import Test.Common
    ( Key
    , Test
    , TestType (..)
    , TestValue
    , property
    , testTypesGCDMonoid
    , testTypesGroup
    , testTypesLCMMonoid
    , testTypesLeftGCDMonoid
    , testTypesLeftReductive
    , testTypesMonoidNull
    , testTypesMonus
    , testTypesOverlappingGCDMonoid
    , testTypesReductive
    , testTypesRightGCDMonoid
    , testTypesRightReductive
    )
import Test.Hspec
    ( Spec, describe, it )
import Test.QuickCheck
    ( Property, cover, (===) )

import qualified Data.Group as Group
    ( Group (..) )
import qualified Data.Monoid.GCD as LeftGCDMonoid
    ( LeftGCDMonoid (..) )
import qualified Data.Monoid.GCD as RightGCDMonoid
    ( RightGCDMonoid (..) )
import qualified Data.Monoid.GCD as OverlappingGCDMonoid
    ( OverlappingGCDMonoid (..) )
import qualified Data.Monoid.GCD as GCDMonoid
    ( GCDMonoid (..) )
import qualified Data.Monoid.LCM as LCMMonoid
    ( LCMMonoid (..) )
import qualified Data.Monoid.Monus as Monus
    ( Monus (..) )
import qualified Data.Semigroup as Semigroup
    ( Semigroup (..) )
import qualified Data.Semigroup.Cancellative as LeftReductive
    ( LeftReductive (..) )
import qualified Data.Semigroup.Cancellative as RightReductive
    ( RightReductive (..) )
import qualified Data.Semigroup.Cancellative as Reductive
    ( Reductive (..) )

spec :: Spec
spec = do
    specDistributiveGet
    specDistributiveGetMaybe

specDistributiveGet :: Spec
specDistributiveGet = do
    specForAll
        testTypesMonoidNull
        "Semigroup.<>"
        (Semigroup.<>)
        (Semigroup.<>)
    specForAll
        testTypesLeftGCDMonoid
        "LeftGCDMonoid.commonPrefix"
        (LeftGCDMonoid.commonPrefix)
        (LeftGCDMonoid.commonPrefix)
    specForAll
        testTypesRightGCDMonoid
        "RightGCDMonoid.commonSuffix"
        (RightGCDMonoid.commonSuffix)
        (RightGCDMonoid.commonSuffix)
    specForAll
        testTypesOverlappingGCDMonoid
        "OverlappingGCDMonoid.overlap"
        (OverlappingGCDMonoid.overlap)
        (OverlappingGCDMonoid.overlap)
    specForAll
        testTypesGCDMonoid
        "GCDMonoid.gcd"
        (GCDMonoid.gcd)
        (GCDMonoid.gcd)
    specForAll
        testTypesLCMMonoid
        "LCMMonoid.lcm"
        (LCMMonoid.lcm)
        (LCMMonoid.lcm)
    specForAll
        testTypesGroup
        "Group.minus"
        (Group.~~)
        (Group.~~)
    specForAll
        testTypesMonus
        "Monus.monus"
        (Monus.<\>)
        (Monus.<\>)
  where
    specForAll
        :: [TestType c]
        -> String
        -> (forall k v m. (Test k v, c v, m ~ MonoidMap k v) => (m -> m -> m))
        -> (forall v. (TestValue v, c v) => (v -> v -> v))
        -> Spec
    specForAll testTypes funName f g =
        describe description $ forM_ testTypes $ specFor f g
      where
        description = "Distributivity of 'get' with '" <> funName <> "'"

    specFor
        :: (forall k v m. (Test k v, c v, m ~ MonoidMap k v) => (m -> m -> m))
        -> (forall v. (TestValue v, c v) => (v -> v -> v))
        -> TestType c
        -> Spec
    specFor f g (TestType (_ :: Proxy v)) =
        it description $ property $ propDistributiveGet @Key @v f g
      where
        description = show $ typeRep $ Proxy @(MonoidMap Key v)

specDistributiveGetMaybe :: Spec
specDistributiveGetMaybe = do
    specForAll
        testTypesLeftReductive
        "LeftReductive.stripPrefix"
        (LeftReductive.stripPrefix)
        (LeftReductive.stripPrefix)
    specForAll
        testTypesRightReductive
        "RightReductive.stripSuffix"
        (RightReductive.stripSuffix)
        (RightReductive.stripSuffix)
    specForAll
        testTypesReductive
        "Reductive.minusMaybe"
        (Reductive.</>)
        (Reductive.</>)
  where
    specForAll
        :: [TestType c]
        -> String
        -> (forall k v m. (Test k v, c v, m ~ MonoidMap k v)
            => (m -> m -> Maybe m))
        -> (forall v. (TestValue v, c v)
            => (v -> v -> Maybe v))
        -> Spec
    specForAll testTypes funName f g =
        describe description $ forM_ testTypes $ specFor f g
      where
        description = "Distributivity of 'get' with '" <> funName <> "'"

    specFor
        :: (forall k v m. (Test k v, c v, m ~ MonoidMap k v)
            => (m -> m -> Maybe m))
        -> (forall v. (TestValue v, c v)
            => (v -> v -> Maybe v))
        -> TestType c
        -> Spec
    specFor f g (TestType (_ :: Proxy v)) =
        it description $ property $ propDistributiveGetMaybe @Key @v f g
      where
        description = show $ typeRep $ Proxy @(MonoidMap Key v)

propDistributiveGet
    :: Test k v
    => (MonoidMap k v -> MonoidMap k v -> MonoidMap k v)
    -> (v -> v -> v)
    -> k
    -> MonoidMap k v
    -> MonoidMap k v
    -> Property
propDistributiveGet f g k m1 m2 =
    get k (f m1 m2) === g (get k m1) (get k m2)
    & cover 2
        (get k (f m1 m2) == mempty)
        "get k (f m1 m2) == mempty"
    & cover 2
        (get k (f m1 m2) /= mempty)
        "get k (f m1 m2) /= mempty"
    & cover 2
        (get k m1 == mempty && get k m2 == mempty)
        "get k m1 == mempty && get k m2 == mempty"
    & cover 2
        (get k m1 == mempty && get k m2 /= mempty)
        "get k m1 == mempty && get k m2 /= mempty"
    & cover 2
        (get k m1 /= mempty && get k m2 == mempty)
        "get k m1 /= mempty && get k m2 == mempty"
    & cover 2
        (get k m1 /= mempty && get k m2 /= mempty)
        "get k m1 /= mempty && get k m2 /= mempty"

propDistributiveGetMaybe
    :: Test k v
    => (MonoidMap k v -> MonoidMap k v -> Maybe (MonoidMap k v))
    -> (v -> v -> Maybe v)
    -> k
    -> MonoidMap k v
    -> MonoidMap k v
    -> Property
propDistributiveGetMaybe f g k m1 m2 = property $
    all (\m -> g (get k m1) (get k m2) == Just (get k m)) (f m1 m2)
    & cover 2
        (isJust (f m1 m2) && g (get k m1) (get k m2) == Just mempty)
        "isJust (f m1 m2) && g (get k m1) (get k m2) == Just mempty"
    & cover 2
        (isJust (f m1 m2) && g (get k m1) (get k m2) /= Just mempty)
        "isJust (f m1 m2) && g (get k m1) (get k m2) /= Just mempty"
