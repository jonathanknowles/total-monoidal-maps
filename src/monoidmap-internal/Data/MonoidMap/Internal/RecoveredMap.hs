{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Data.MonoidMap.Internal.RecoveredMap where

import Control.DeepSeq
    ( NFData )
import Data.Maybe
    ( mapMaybe )
import Data.Monoid
    ( First (..) )
import Data.MonoidMap.Internal
    ( MonoidMap )
import Data.Set
    ( Set )

import qualified Data.MonoidMap.Internal as MonoidMap

newtype Map k v = Map
    {unMap :: MonoidMap k (First v)}
    deriving stock Eq
    deriving newtype (NFData, Semigroup, Monoid)

instance (Show k, Show v) => Show (Map k v) where
    show = ("fromList " <>) . show . toList

empty :: Map k v
empty = Map MonoidMap.empty

singleton :: Ord k => k -> v -> Map k v
singleton k = Map . MonoidMap.singleton k . pure

fromList :: Ord k => [(k, v)] -> Map k v
fromList = Map . MonoidMap.fromListWith const . fmap (fmap pure)

toList :: Map k v -> [(k, v)]
toList = mapMaybe (getFirst . sequenceA) . MonoidMap.toList . unMap

insert :: Ord k => k -> v -> Map k v -> Map k v
insert k v m = Map $ MonoidMap.set (unMap m) k (pure v)

keysSet :: Map k v -> Set k
keysSet = MonoidMap.nonNullKeys . unMap

lookup :: Ord k => k -> Map k v -> Maybe v
lookup k = getFirst . (`MonoidMap.get` k) . unMap

member :: Ord k => k -> Map k v -> Bool
member k m = MonoidMap.nonNullKey (unMap m) k