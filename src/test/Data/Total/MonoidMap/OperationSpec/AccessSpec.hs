{- HLINT ignore "Redundant bracket" -}
{- HLINT ignore "Use camelCase" -}
{- HLINT ignore "Use null" -}

-- |
-- Copyright: © 2022–2023 Jonathan Knowles
-- License: Apache-2.0
--
module Data.Total.MonoidMap.OperationSpec.AccessSpec
    ( spec
    ) where

import Prelude

import Control.Monad
    ( forM_ )
import Data.Function
    ( (&) )
import Data.Proxy
    ( Proxy (..) )
import Data.Total.MonoidMap
    ( MonoidMap )
import Data.Typeable
    ( typeRep )
import Test.Common
    ( Key
    , TestConstraints
    , TestInstance (TestInstance)
    , property
    , testInstancesMonoidNull
    )
import Test.Hspec
    ( Spec, describe, it )
import Test.QuickCheck
    ( Property, cover, (===) )

import qualified Data.Set as Set
import qualified Data.Total.MonoidMap as MonoidMap

spec :: Spec
spec = describe "Accessors" $ do

    forM_ testInstancesMonoidNull $ \(TestInstance p) -> specFor (Proxy @Key) p

specFor :: forall k v. TestConstraints k v => Proxy k -> Proxy v -> Spec
specFor _k _v = describe (show $ typeRep (Proxy @(MonoidMap k v))) $ do

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

--------------------------------------------------------------------------------
-- Get
--------------------------------------------------------------------------------

prop_get_nonNullKey
    :: TestConstraints k v => MonoidMap k v -> k -> Property
prop_get_nonNullKey m k =
    MonoidMap.nonNullKey k m === (MonoidMap.get k m /= mempty)
    & cover 2
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 2
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_get_nonNullKeys
    :: TestConstraints k v => MonoidMap k v -> k -> Property
prop_get_nonNullKeys m k =
    Set.member k (MonoidMap.nonNullKeys m) === (MonoidMap.get k m /= mempty)
    & cover 2
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 2
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

--------------------------------------------------------------------------------
-- Set
--------------------------------------------------------------------------------

prop_set_get
    :: TestConstraints k v => MonoidMap k v -> k -> v -> Property
prop_set_get m k v =
    MonoidMap.get k (MonoidMap.set k v m) === v
    & cover 2
        (MonoidMap.nonNullKey k m)
        "MonoidMap.nonNullKey k m"
    & cover 2
        (not (MonoidMap.nonNullKey k m))
        "not (MonoidMap.nonNullKey k m)"

prop_set_nonNullKey
    :: TestConstraints k v => MonoidMap k v -> k -> v -> Property
prop_set_nonNullKey m k v =
    MonoidMap.nonNullKey k (MonoidMap.set k v m) ===
        (v /= mempty)
    & cover 2
        (v == mempty)
        "v == mempty"
    & cover 2
        (v /= mempty)
        "v /= mempty"

prop_set_nonNullKeys
    :: TestConstraints k v => MonoidMap k v -> k -> v -> Property
prop_set_nonNullKeys m k v =
    Set.member k (MonoidMap.nonNullKeys (MonoidMap.set k v m)) ===
        (v /= mempty)
    & cover 2
        (v == mempty)
        "v == mempty"
    & cover 2
        (v /= mempty)
        "v /= mempty"

prop_set_toList
    :: TestConstraints k v => MonoidMap k v -> k -> v -> Property
prop_set_toList m k v =
    filter ((== k) . fst) (MonoidMap.toList (MonoidMap.set k v m)) ===
        [(k, v) | v /= mempty]
    & cover 2
        (v == mempty)
        "v == mempty"
    & cover 2
        (v /= mempty)
        "v /= mempty"
