{-# OPTIONS_GHC -fno-warn-orphans #-}
{- HLINT ignore "Redundant bracket" -}
{- HLINT ignore "Use camelCase" -}
{- HLINT ignore "Use null" -}

-- |
-- Copyright: © 2022–2023 Jonathan Knowles
-- License: Apache-2.0
--
module Data.Total.MonoidMap.TypeSpec
    where

import Prelude

import Data.Bifunctor
    ( bimap, first, second )
import Data.Function
    ( (&) )
import Data.Map.Strict
    ( Map )
import Data.Maybe
    ( isJust )
import Data.Monoid
    ( Sum (..) )
import Data.Monoid.GCD
    ( LeftGCDMonoid (..), RightGCDMonoid (..) )
import Data.Monoid.Null
    ( MonoidNull )
import Data.Proxy
    ( Proxy (..) )
import Data.Semigroup.Cancellative
    ( LeftReductive (..), RightReductive (..) )
import Data.Set
    ( Set )
import Data.Text
    ( Text )
import Data.Total.MonoidMap
    ( MonoidMap, nonNullCount )
import Data.Typeable
    ( Typeable, typeRep )
import GHC.Exts
    ( IsList (..) )
import Numeric.Natural
    ( Natural )
import Test.Hspec
    ( Spec, describe, it )
import Test.QuickCheck
    ( Arbitrary (..)
    , CoArbitrary (..)
    , Fun (..)
    , Function (..)
    , Gen
    , Property
    , Testable
    , applyFun
    , applyFun2
    , checkCoverage
    , choose
    , coarbitraryIntegral
    , cover
    , functionIntegral
    , listOf
    , oneof
    , scale
    , shrinkMapBy
    , (===)
    )
import Test.QuickCheck.Instances.Natural
    ()
import Test.QuickCheck.Instances.Text
    ()

import qualified Data.Foldable as F
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Total.MonoidMap as MonoidMap
import qualified Test.QuickCheck as QC

spec :: Spec
spec = describe "Type properties" $ do
    specPropertiesFor (Proxy @Key) (Proxy @(Set Key))
    specPropertiesFor (Proxy @Key) (Proxy @(Set Natural))
    specPropertiesFor (Proxy @Key) (Proxy @(Sum Key))
    specPropertiesFor (Proxy @Key) (Proxy @(Sum Natural))
    specPropertiesFor (Proxy @Key) (Proxy @Text)

specPropertiesFor
    :: forall k v. () =>
        ( Arbitrary k
        , Arbitrary v
        , CoArbitrary k
        , CoArbitrary v
        , Eq v
        , Function k
        , Function v
        , MonoidNull v
        , Ord k
        , Show k
        , Show v
        , Typeable k
        , Typeable v
        )
    => Proxy k
    -> Proxy v
    -> Spec
specPropertiesFor keyType valueType = do

    let description = mconcat
            [ "MonoidMap ("
            , show (typeRep keyType)
            , ") ("
            , show (typeRep valueType)
            , ")"
            ]

    let property :: Testable t => t -> Property
        property = checkCoverage . QC.property

    describe description $ do

        describe "Conversion to and from lists" $ do
            it "prop_fromList_get" $
                prop_fromList_get
                    @k @v & property
            it "prop_fromList_toMap" $
                prop_fromList_toMap
                    @k @v & property
            it "prop_fromList_toList" $
                prop_fromList_toList
                    @k @v & property
            it "prop_toList_fromList" $
                prop_toList_fromList
                    @k @v & property

        describe "Conversion to and from ordinary maps" $ do
            it "prop_fromMap_toMap" $
                prop_fromMap_toMap
                    @k @v & property
            it "prop_toMap_fromMap" $
                prop_toMap_fromMap
                    @k @v & property

        describe "Singleton" $ do
            it "prop_singleton_get" $
                prop_singleton_get
                    @k @v & property
            it "prop_singleton_nonNullKey" $
                prop_singleton_nonNullKey
                    @k @v & property
            it "prop_singleton_nonNullKeys" $
                prop_singleton_nonNullKeys
                    @k @v & property
            it "prop_singleton_null" $
                prop_singleton_null
                    @k @v & property
            it "prop_singleton_nullify" $
                prop_singleton_nullify
                    @k @v & property
            it "prop_singleton_nonNullCount" $
                prop_singleton_nonNullCount
                    @k @v & property
            it "prop_singleton_toList" $
                prop_singleton_toList
                    @k @v & property

        describe "Get" $ do
            it "prop_get_nonNullKey" $
                prop_get_nonNullKey
                    @k @v & property
            it "prop_get_nonNullKeys" $
                prop_get_nonNullKeys
                    @k @v & property

        describe "Set" $ do
            it "prop_set_get" $
                prop_set_get
                    @k @v & property
            it "prop_set_nonNullKey" $
                prop_set_nonNullKey
                    @k @v & property
            it "prop_set_nonNullKeys" $
                prop_set_nonNullKeys
                    @k @v & property
            it "prop_set_toList" $
                prop_set_toList
                    @k @v & property

        describe "Nullify" $ do
            it "prop_nullify_get" $
                prop_nullify_get
                    @k @v & property
            it "prop_nullify_nonNullKey" $
                prop_nullify_nonNullKey
                    @k @v & property
            it "prop_nullify_nonNullKeys" $
                prop_nullify_nonNullKeys
                    @k @v & property

        describe "Keys" $ do
            it "prop_nonNullKeys_get" $
                prop_nonNullKeys_get
                    @k @v & property

        describe "Filtering" $ do
            it "prop_filter_toList" $
                prop_filter_toList
                    @k @v & property
            it "prop_filterKeys_filter" $
                prop_filterKeys_filter
                    @k @v & property
            it "prop_filterKeys_toList" $
                prop_filterKeys_toList
                    @k @v & property
            it "prop_filterValues_filter" $
                prop_filterValues_filter
                    @k @v & property
            it "prop_filterValues_toList" $
                prop_filterValues_toList
                    @k @v & property

        describe "Partitioning" $ do
            it "prop_partition_filter" $
                prop_partition_filter
                    @k @v & property
            it "prop_partitionKeys_filterKeys" $
                prop_partitionKeys_filterKeys
                    @k @v & property
            it "prop_partitionValues_filterValues" $
                prop_partitionValues_filterValues
                    @k @v & property

        describe "Slicing" $ do
            it "prop_take_toList_fromList" $
                prop_take_toList_fromList
                    @k @v & property
            it "prop_drop_toList_fromList" $
                prop_drop_toList_fromList
                    @k @v & property
            it "prop_splitAt_toList_fromList" $
                prop_splitAt_toList_fromList
                    @k @v & property

        describe "Mapping" $ do
            it "prop_map_asList" $
                prop_map_asList
                    @k @v & property
            it "prop_mapWith_asList" $
                prop_mapWith_asList
                    @k @v & property
            it "prop_mapKeys_asList" $
                prop_mapKeys_asList
                    @k @v & property
            it "prop_mapKeys_get" $
                prop_mapKeys_get
                    @k @v & property
            it "prop_mapKeysWith_asList" $
                prop_mapKeysWith_asList
                    @k @v & property
            it "prop_mapValues_asList" $
                prop_mapValues_asList
                    @k @v & property

--------------------------------------------------------------------------------
-- Conversion to and from lists
--------------------------------------------------------------------------------

prop_fromList_get
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => [(k, v)]
    -> k
    -> Property
prop_fromList_get kvs k =
    MonoidMap.get k (MonoidMap.fromList kvs)
        ===
        F.foldMap snd (filter ((== k) . fst) kvs)
    & cover 2
        (matchingKeyCount == 0)
        "matchingKeyCount == 0"
    & cover 2
        (matchingKeyCount == 1)
        "matchingKeyCount == 1"
    & cover 2
        (matchingKeyCount == 2)
        "matchingKeyCount == 2"
    & cover 2
        (matchingKeyCount >= 3)
        "matchingKeyCount >= 3"
  where
    matchingKeyCount =
        length $ filter ((== k) . fst) kvs

prop_fromList_toMap
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => [(k, v)]
    -> Property
prop_fromList_toMap kvs =
    MonoidMap.toMap m === Map.filter (/= mempty) o
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m /= Map.size o)
        "MonoidMap.nonNull m && nonNullCount m /= Map.size o"
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m == Map.size o)
        "MonoidMap.nonNull m && nonNullCount m == Map.size o"
  where
    m = MonoidMap.fromList kvs
    o = Map.fromListWith (flip (<>)) kvs

prop_fromList_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => [(k, v)]
    -> Property
prop_fromList_toList kvs =
    MonoidMap.toList m === Map.toList (Map.filter (/= mempty) o)
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m /= Map.size o)
        "MonoidMap.nonNull m && nonNullCount m /= Map.size o"
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m == Map.size o)
        "MonoidMap.nonNull m && nonNullCount m == Map.size o"
  where
    m = MonoidMap.fromList kvs
    o = Map.fromListWith (flip (<>)) kvs

prop_toList_fromList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => MonoidMap k v
    -> Property
prop_toList_fromList m =
    MonoidMap.fromList (MonoidMap.toList m) === m
    & cover 1
        (MonoidMap.nonNull m)
        "MonoidMap.nonNull m"

--------------------------------------------------------------------------------
-- Conversion to and from ordinary maps
--------------------------------------------------------------------------------

prop_fromMap_toMap
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Map k v
    -> Property
prop_fromMap_toMap o =
    MonoidMap.toMap m === Map.filter (/= mempty) o
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m /= Map.size o)
        "MonoidMap.nonNull m && nonNullCount m /= Map.size o"
    & cover 1
        (MonoidMap.nonNull m && nonNullCount m == Map.size o)
        "MonoidMap.nonNull m && nonNullCount m == Map.size o"
  where
    m = MonoidMap.fromMap o

prop_toMap_fromMap
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => MonoidMap k v
    -> Property
prop_toMap_fromMap m =
    MonoidMap.fromMap (MonoidMap.toMap m) === m

--------------------------------------------------------------------------------
-- Singleton
--------------------------------------------------------------------------------

prop_singleton_get
    :: (Ord k, Eq v, MonoidNull v, Show v)
    => k
    -> v
    -> Property
prop_singleton_get k v =
    MonoidMap.get k (MonoidMap.singleton k v) === v
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_nonNullKey
    :: (Ord k, Eq v, MonoidNull v)
    => k
    -> v
    -> Property
prop_singleton_nonNullKey k v =
    MonoidMap.nonNullKey k (MonoidMap.singleton k v) === (v /= mempty)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_nonNullKeys
    :: (Ord k, Show k, Eq v, MonoidNull v)
    => k
    -> v
    -> Property
prop_singleton_nonNullKeys k v =
    MonoidMap.nonNullKeys (MonoidMap.singleton k v) ===
        (if v == mempty then Set.empty else Set.singleton k)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_null
    :: (Ord k, Eq v, MonoidNull v)
    => k
    -> v
    -> Property
prop_singleton_null k v =
    MonoidMap.null (MonoidMap.singleton k v) === (v == mempty)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_nullify
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => k
    -> v
    -> Property
prop_singleton_nullify k v =
    MonoidMap.nullify k (MonoidMap.singleton k v) === mempty
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_nonNullCount
    :: (Ord k, Eq v, MonoidNull v)
    => k
    -> v
    -> Property
prop_singleton_nonNullCount k v =
    nonNullCount (MonoidMap.singleton k v) ===
        (if v == mempty then 0 else 1)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_singleton_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => k
    -> v
    -> Property
prop_singleton_toList k v =
    MonoidMap.toList (MonoidMap.singleton k v) ===
        [(k, v) | v /= mempty]
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

--------------------------------------------------------------------------------
-- Get
--------------------------------------------------------------------------------

prop_get_nonNullKey
    :: (Ord k, Eq v, MonoidNull v)
    => MonoidMap k v
    -> k
    -> Property
prop_get_nonNullKey m k =
    MonoidMap.nonNullKey k m === (MonoidMap.get k m /= mempty)
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_get_nonNullKeys
    :: (Ord k, Eq v, MonoidNull v)
    => MonoidMap k v
    -> k
    -> Property
prop_get_nonNullKeys m k =
    Set.member k (MonoidMap.nonNullKeys m) === (MonoidMap.get k m /= mempty)
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

--------------------------------------------------------------------------------
-- Set
--------------------------------------------------------------------------------

prop_set_get
    :: (Ord k, Eq v, MonoidNull v, Show v)
    => MonoidMap k v
    -> k
    -> v
    -> Property
prop_set_get m k v =
    MonoidMap.get k (MonoidMap.set k v m) === v
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_set_nonNullKey
    :: (Ord k, Eq v, MonoidNull v)
    => MonoidMap k v
    -> k
    -> v
    -> Property
prop_set_nonNullKey m k v =
    MonoidMap.nonNullKey k (MonoidMap.set k v m) ===
        (v /= mempty)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_set_nonNullKeys
    :: (Ord k, Eq v, MonoidNull v)
    => MonoidMap k v
    -> k
    -> v
    -> Property
prop_set_nonNullKeys m k v =
    Set.member k (MonoidMap.nonNullKeys (MonoidMap.set k v m)) ===
        (v /= mempty)
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

prop_set_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => MonoidMap k v
    -> k
    -> v
    -> Property
prop_set_toList m k v =
    filter ((== k) . fst) (MonoidMap.toList (MonoidMap.set k v m)) ===
        [(k, v) | v /= mempty]
    & cover 1
        (v == mempty)
        "v == mempty"
    & cover 1
        (v /= mempty)
        "v /= mempty"

--------------------------------------------------------------------------------
-- Nullify
--------------------------------------------------------------------------------

prop_nullify_get
    :: (Ord k, Eq v, Monoid v, Show v)
    => MonoidMap k v
    -> k
    -> Property
prop_nullify_get m k =
    MonoidMap.get k (MonoidMap.nullify k m) === mempty
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_nullify_nonNullKey
    :: Ord k
    => MonoidMap k v
    -> k
    -> Property
prop_nullify_nonNullKey m k =
    MonoidMap.nonNullKey k (MonoidMap.nullify k m) === False
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_nullify_nonNullKeys
    :: Ord k
    => MonoidMap k v
    -> k
    -> Property
prop_nullify_nonNullKeys m k =
    Set.member k (MonoidMap.nonNullKeys (MonoidMap.nullify k m)) === False
    & cover 1
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 1
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

--------------------------------------------------------------------------------
-- Keys
--------------------------------------------------------------------------------

prop_nonNullKeys_get
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => MonoidMap k v
    -> Property
prop_nonNullKeys_get m =
    fmap
        (\k -> (k, MonoidMap.get k m))
        (Set.toList (MonoidMap.nonNullKeys m))
        === MonoidMap.toList m
    & cover 1
        (MonoidMap.null m)
        "MonoidMap.null m"
    & cover 1
        (not (MonoidMap.null m))
        "not (MonoidMap.null m)"

--------------------------------------------------------------------------------
-- Filtering
--------------------------------------------------------------------------------

prop_filter_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun (k, v) Bool
    -> MonoidMap k v
    -> Property
prop_filter_toList (applyFun2 -> f) m =
    toList n === List.filter (uncurry f) (toList m)
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n == nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n == nonNullCount m"
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n /= nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n /= nonNullCount m"
  where
    n = MonoidMap.filter f m

prop_filterKeys_filter
    :: (Ord k, Show k, Eq v, Show v)
    => Fun k Bool
    -> MonoidMap k v
    -> Property
prop_filterKeys_filter (applyFun -> f) m =
    n === MonoidMap.filter (\k _ -> f k) m
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n == nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n == nonNullCount m"
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n /= nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n /= nonNullCount m"
  where
    n = MonoidMap.filterKeys f m

prop_filterKeys_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun k Bool
    -> MonoidMap k v
    -> Property
prop_filterKeys_toList (applyFun -> f) m =
    toList n === List.filter (f . fst) (toList m)
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n == nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n == nonNullCount m"
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n /= nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n /= nonNullCount m"
  where
    n = MonoidMap.filterKeys f m

prop_filterValues_filter
    :: (Ord k, Show k, Eq v, Show v)
    => Fun v Bool
    -> MonoidMap k v
    -> Property
prop_filterValues_filter (applyFun -> f) m =
    n === MonoidMap.filter (\_ v -> f v) m
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n == nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n == nonNullCount m"
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n /= nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n /= nonNullCount m"
  where
    n = MonoidMap.filterValues f m

prop_filterValues_toList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun v Bool
    -> MonoidMap k v
    -> Property
prop_filterValues_toList (applyFun -> f) m =
    toList n === List.filter (f . snd) (toList m)
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n == nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n == nonNullCount m"
    & cover 1
        (MonoidMap.nonNull n && nonNullCount n /= nonNullCount m)
        "MonoidMap.nonNull n && nonNullCount n /= nonNullCount m"
  where
    n = MonoidMap.filterValues f m

--------------------------------------------------------------------------------
-- Partitioning
--------------------------------------------------------------------------------

prop_partition_filter
    :: (Ord k, Show k, Eq v, Show v)
    => Fun (k, v) Bool
    -> MonoidMap k v
    -> Property
prop_partition_filter (applyFun2 -> f) m =
    MonoidMap.partition f m === (x, y)
    & cover 1
        (nonNullCount x /= 0 && nonNullCount y /= 0)
        "nonNullCount x /= 0 && nonNullCount y /= 0"
  where
    x = MonoidMap.filter f m
    y = MonoidMap.filter ((fmap . fmap) not f) m

prop_partitionKeys_filterKeys
    :: (Ord k, Show k, Eq v, Show v)
    => Fun k Bool
    -> MonoidMap k v
    -> Property
prop_partitionKeys_filterKeys (applyFun -> f) m =
    MonoidMap.partitionKeys f m === (x, y)
    & cover 1
        (nonNullCount x /= 0 && nonNullCount y /= 0)
        "nonNullCount x /= 0 && nonNullCount y /= 0"
  where
    x = MonoidMap.filterKeys f m
    y = MonoidMap.filterKeys (not . f) m

prop_partitionValues_filterValues
    :: (Ord k, Show k, Eq v, Show v)
    => Fun v Bool
    -> MonoidMap k v
    -> Property
prop_partitionValues_filterValues (applyFun -> f) m =
    MonoidMap.partitionValues f m === (x, y)
    & cover 1
        (nonNullCount x /= 0 && nonNullCount y /= 0)
        "nonNullCount x /= 0 && nonNullCount y /= 0"
  where
    x = MonoidMap.filterValues f m
    y = MonoidMap.filterValues (not . f) m

--------------------------------------------------------------------------------
-- Slicing
--------------------------------------------------------------------------------

data Slice k v = Slice Int (MonoidMap k v)
    deriving (Eq, Show)

instance (Arbitrary k, Arbitrary v, MonoidNull v, Ord k) =>
    Arbitrary (Slice k v)
  where
    arbitrary = do
        m <- genMap
        i <- genIndex m
        pure $ Slice i m
      where
        genMap :: Gen (MonoidMap k v)
        genMap = arbitrary

        genIndex :: MonoidMap k v -> Gen Int
        genIndex m = oneof
            [ choose (negate (length m), -1)
            , pure 0
            , choose (1, length m - 1)
            , pure (length m)
            , choose (length m + 1, 2 * length m)
            ]

prop_take_toList_fromList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Slice k v
    -> Property
prop_take_toList_fromList (Slice i m) =
    MonoidMap.take i m
        === (fromList . Prelude.take i . toList) m
    & cover 1
        (i == 0 && 0 < nonNullCount m)
        "i == 0 && 0 < nonNullCount m"
    & cover 1
        (0 < i && i < nonNullCount m)
        "0 < i && i < nonNullCount m"
    & cover 1
        (0 < nonNullCount m && nonNullCount m == i)
        "0 < nonNullCount m && nonNullCount m == i"
    & cover 1
        (0 < nonNullCount m && nonNullCount m < i)
        "0 < nonNullCount m && nonNullCount m < i"

prop_drop_toList_fromList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Slice k v
    -> Property
prop_drop_toList_fromList (Slice i m) =
    MonoidMap.drop i m
        === (fromList . Prelude.drop i . toList) m
    & cover 1
        (i == 0 && 0 < nonNullCount m)
        "i == 0 && 0 < nonNullCount m"
    & cover 1
        (0 < i && i < nonNullCount m)
        "0 < i && i < nonNullCount m"
    & cover 1
        (0 < nonNullCount m && nonNullCount m == i)
        "0 < nonNullCount m && nonNullCount m == i"
    & cover 1
        (0 < nonNullCount m && nonNullCount m < i)
        "0 < nonNullCount m && nonNullCount m < i"

prop_splitAt_toList_fromList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Slice k v
    -> Property
prop_splitAt_toList_fromList (Slice i m) =
    MonoidMap.splitAt i m
        === (bimap fromList fromList . Prelude.splitAt i . toList) m
    & cover 1
        (i == 0 && 0 < nonNullCount m)
        "i == 0 && 0 < nonNullCount m"
    & cover 1
        (0 < i && i < nonNullCount m)
        "0 < i && i < nonNullCount m"
    & cover 1
        (0 < nonNullCount m && nonNullCount m == i)
        "0 < nonNullCount m && nonNullCount m == i"
    & cover 1
        (0 < nonNullCount m && nonNullCount m < i)
        "0 < nonNullCount m && nonNullCount m < i"

--------------------------------------------------------------------------------
-- Mapping
--------------------------------------------------------------------------------

prop_map_asList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun k k
    -> Fun v v
    -> MonoidMap k v
    -> Property
prop_map_asList (applyFun -> f) (applyFun -> g) m =
    n === (MonoidMap.fromList . fmap (bimap f g) . MonoidMap.toList $ m)
    & cover 1
        (0 < nonNullCount n && nonNullCount n < nonNullCount m)
        "0 < nonNullCount n && nonNullCount n < nonNullCount m"
  where
    n = MonoidMap.map f g m

prop_mapWith_asList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun (v, v) v
    -> Fun k k
    -> Fun v v
    -> MonoidMap k v
    -> Property
prop_mapWith_asList (applyFun2 -> c) (applyFun -> f) (applyFun -> g) m =
    n === (MonoidMap.fromListWith c . fmap (bimap f g) . MonoidMap.toList $ m)
    & cover 1
        (0 < nonNullCount n && nonNullCount n < nonNullCount m)
        "0 < nonNullCount n && nonNullCount n < nonNullCount m"
  where
    n = MonoidMap.mapWith c f g m

prop_mapKeys_asList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun k k
    -> MonoidMap k v
    -> Property
prop_mapKeys_asList (applyFun -> f) m =
    n === (MonoidMap.fromList . fmap (first f) . MonoidMap.toList $ m)
    & cover 1
        (0 < nonNullCount n && nonNullCount n < nonNullCount m)
        "0 < nonNullCount n && nonNullCount n < nonNullCount m"
  where
    n = MonoidMap.mapKeys f m

prop_mapKeys_get
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun k k
    -> k
    -> MonoidMap k v
    -> Property
prop_mapKeys_get (applyFun -> f) k m =
    MonoidMap.get k (MonoidMap.mapKeys f m)
        ===
        F.foldMap
            (`MonoidMap.get` m)
            (Set.filter ((==) k . f) (MonoidMap.nonNullKeys m))
    & cover 2
        (MonoidMap.nullKey k (MonoidMap.mapKeys f m))
        "MonoidMap.nullKey k (MonoidMap.mapKeys f m)"
    & cover 2
        (MonoidMap.nonNullKey k (MonoidMap.mapKeys f m))
        "MonoidMap.nonNullKey k (MonoidMap.mapKeys f m)"

prop_mapKeysWith_asList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun (v, v) v
    -> Fun k k
    -> MonoidMap k v
    -> Property
prop_mapKeysWith_asList (applyFun2 -> c) (applyFun -> f) m =
    n === (MonoidMap.fromListWith c . fmap (first f) . MonoidMap.toList $ m)
    & cover 1
        (0 < nonNullCount n && nonNullCount n < nonNullCount m)
        "0 < nonNullCount n && nonNullCount n < nonNullCount m"
  where
    n = MonoidMap.mapKeysWith c f m

prop_mapValues_asList
    :: (Ord k, Show k, Eq v, MonoidNull v, Show v)
    => Fun v v
    -> MonoidMap k v
    -> Property
prop_mapValues_asList (applyFun -> f) m =
    n === (MonoidMap.fromList . fmap (second f) . MonoidMap.toList $ m)
    & cover 1
        (0 < nonNullCount n && nonNullCount n < nonNullCount m)
        "0 < nonNullCount n && nonNullCount n < nonNullCount m"
  where
    n = MonoidMap.mapValues f m

--------------------------------------------------------------------------------
-- Association
--------------------------------------------------------------------------------

prop_mappend_get
    :: (Ord k, Eq v, Show v, MonoidNull v)
    => MonoidMap k v
    -> MonoidMap k v
    -> k
    -> Property
prop_mappend_get m1 m2 k =
    MonoidMap.get k (m1 <> m2) === MonoidMap.get k m1 <> MonoidMap.get k m2

--------------------------------------------------------------------------------
-- Prefixes and suffixes
--------------------------------------------------------------------------------

prop_stripPrefix_isJust
    :: (Ord k, MonoidNull v, LeftReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> Property
prop_stripPrefix_isJust m1 m2 =
    isJust (stripPrefix m1 m2) === m1 `isPrefixOf` m2

prop_stripSuffix_isJust
    :: (Ord k, MonoidNull v, RightReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> Property
prop_stripSuffix_isJust m1 m2 =
    isJust (stripSuffix m1 m2) === m1 `isSuffixOf` m2

prop_stripPrefix_get
    :: (Ord k, Eq v, MonoidNull v, LeftReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> k
    -> Property
prop_stripPrefix_get m1 m2 k = QC.property $
    all
        (\r ->
            Just (MonoidMap.get k r)
            ==
            stripPrefix (MonoidMap.get k m1) (MonoidMap.get k m2)
        )
        (stripPrefix m1 m2)

prop_stripSuffix_get
    :: (Ord k, Eq v, MonoidNull v, RightReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> k
    -> Property
prop_stripSuffix_get m1 m2 k = QC.property $
    all
        (\r ->
            Just (MonoidMap.get k r)
            ==
            stripSuffix (MonoidMap.get k m1) (MonoidMap.get k m2)
        )
        (stripSuffix m1 m2)

prop_stripPrefix_mappend
    :: (Ord k, Eq v, MonoidNull v, LeftReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> Property
prop_stripPrefix_mappend m1 m2 = QC.property $
    all
        (\r -> m1 <> r == m2)
        (stripPrefix m1 m2)

prop_stripSuffix_mappend
    :: (Ord k, Eq v, MonoidNull v, RightReductive v)
    => MonoidMap k v
    -> MonoidMap k v
    -> Property
prop_stripSuffix_mappend m1 m2 = QC.property $
    all
        (\r -> r <> m1 == m2)
        (stripSuffix m1 m2)

prop_commonPrefix_get
    :: (Ord k, Eq v, Show v, MonoidNull v, LeftGCDMonoid v)
    => MonoidMap k v
    -> MonoidMap k v
    -> k
    -> Property
prop_commonPrefix_get m1 m2 k =
    MonoidMap.get k (commonPrefix m1 m2)
    ===
    commonPrefix (MonoidMap.get k m1) (MonoidMap.get k m2)

prop_commonSuffix_get
    :: (Ord k, Eq v, Show v, MonoidNull v, RightGCDMonoid v)
    => MonoidMap k v
    -> MonoidMap k v
    -> k
    -> Property
prop_commonSuffix_get m1 m2 k =
    MonoidMap.get k (commonSuffix m1 m2)
    ===
    commonSuffix (MonoidMap.get k m1) (MonoidMap.get k m2)

--------------------------------------------------------------------------------
-- Arbitrary instances
--------------------------------------------------------------------------------

instance (Arbitrary k, Ord k, Arbitrary v, MonoidNull v) =>
    Arbitrary (MonoidMap k v)
  where
    arbitrary =
        fromList <$> scale (`mod` 16) (listOf ((,) <$> arbitrary <*> arbitrary))
    shrink =
        shrinkMapBy MonoidMap.fromMap MonoidMap.toMap shrink

--------------------------------------------------------------------------------
-- Test types
--------------------------------------------------------------------------------

newtype Key = Key Int
    deriving (Enum, Eq, Integral, Num, Ord, Real, Show)

instance Arbitrary Key where
    arbitrary = Key <$> choose (0, 15)
    shrink (Key k) = Key <$> shrink k

instance CoArbitrary Key where
    coarbitrary = coarbitraryIntegral

instance Function Key where
    function = functionIntegral