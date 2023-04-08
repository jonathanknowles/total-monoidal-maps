-- |
-- Copyright: © 2022–2023 Jonathan Knowles
-- License: Apache-2.0
--
-- A lawful implementation of 'MultiMap', implemented in terms of 'MonoidMap'
-- and 'Set'.
--
module Examples.MultiMap.MultiMap4 where

import Prelude hiding
    ( gcd, lcm, lookup )

import Data.Monoid.GCD
    ( GCDMonoid (gcd) )
import Data.Monoid.LCM
    ( LCMMonoid (lcm) )
import Data.Monoid.Monus
    ( Monus ((<\>)) )
import Data.Set
    ( Set )
import Data.Total.MonoidMap
    ( MonoidMap )
import Examples.MultiMap
    ( MultiMap (..) )

import qualified Data.Total.MonoidMap as MonoidMap

newtype MultiMap4 k v = MultiMap (MonoidMap k (Set v))
    deriving stock (Eq, Show)

instance (Ord k, Ord v) => MultiMap MultiMap4 k v where

    empty = MultiMap MonoidMap.empty

    fromList = MultiMap . MonoidMap.fromListWith (<>)

    toList (MultiMap m) = MonoidMap.toList m

    null (MultiMap m) = MonoidMap.null m

    nonNullKey k (MultiMap m) = MonoidMap.nonNullKey k m

    nonNullKeys (MultiMap m) = MonoidMap.nonNullKeys m

    nonNullCount (MultiMap m) = MonoidMap.nonNullCount m

    lookup k (MultiMap m) = MonoidMap.get k m

    update k vs (MultiMap m) = MultiMap (MonoidMap.set k vs m)

    insert k vs (MultiMap m) = MultiMap (MonoidMap.adjust (<> vs) k m)

    remove k vs (MultiMap m) = MultiMap (MonoidMap.adjust (<\> vs) k m)

    union (MultiMap m1) (MultiMap m2) = MultiMap (lcm m1 m2)

    intersection (MultiMap m1) (MultiMap m2) = MultiMap (gcd m1 m2)

    isSubMultiMapOf (MultiMap m1) (MultiMap m2) = m1 `MonoidMap.isPrefixOf` m2
