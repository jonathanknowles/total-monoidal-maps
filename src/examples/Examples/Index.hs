-- |
-- Copyright: © 2022–2023 Jonathan Knowles
-- License: Apache-2.0
--
-- An example index class.
--
module Examples.Index where

import Prelude hiding
    ( lookup )

import Data.Set
    ( Set )

-- | Specifies an index from unique keys to sets of values.
--
-- Talk about what an index is here.
--
class (Eq (i k v), Ord k, Ord v) => Index i k v where

    -- | Constructs an empty index.
    --
    -- @
    -- ∀ k. lookup k empty == Set.empty
    -- @
    --
    empty :: i k v

    -- | Constructs an index from a list.
    --
    -- @
    -- fromList (toList i) == i
    -- @
    --
    fromList :: [(k, v)] -> i k v

    -- | Converts an index to a list.
    --
    -- @
    -- fromList (toList i) == i
    -- @
    --
    toList :: i k v -> [(k, Set v)]

    -- | Returns the set of values associated with a given key.
    --
    -- @
    -- lookup k (fromList [(k, vs)]) == vs
    -- @
    --
    lookup :: k -> i k v -> Set v

    -- | Updates the set of values associated with a given key.
    --
    -- @
    -- lookup k (update k vs i) == vs
    -- @
    --
    update :: k -> Set v -> i k v -> i k v

    -- | Returns 'True' iff. the given key is not associated with the empty set.
    --
    -- @
    -- nonNullKey k i ==> (lookup k i /= Set.empty)
    -- @
    --
    nonNullKey :: k -> i k v -> Bool

    -- | Returns the set of keys that are not associated with empty sets.
    --
    -- @
    -- all (\k -> lookup k i /= Set.empty) (nonNullKeys i)
    -- @
    --
    nonNullKeys :: i k v -> Set k

    -- | Indicates how many keys are associated with non-empty sets.
    --
    -- @
    -- nonNullKeyCount i == Set.size (nonNullKeys i)
    -- @
    --
    nonNullKeyCount :: i k v -> Int

    -- | Indicates whether or not an index is empty.
    --
    -- @
    -- null i ==> (∀ k. lookup k i == Set.empty)
    -- @
    --
    null :: i k v -> Bool

    -- | Inserts values into the set of values associated with a given key.
    --
    -- @
    -- lookup k (insert k vs i) == lookup k i `Set.union` vs
    -- @
    --
    insert :: k -> Set v -> i k v -> i k v

    -- | Removes values from the set of values associated with a given key.
    --
    -- @
    -- lookup k (remove k vs i) == lookup k i `Set.difference` vs
    -- @
    --
    remove :: k -> Set v -> i k v -> i k v

    -- | Computes the union of two indices.
    --
    -- @
    -- lookup k (i1 `union` i2)
    -- ==
    -- lookup k i1 `Set.union` lookup k i2
    -- @
    --
    union :: i k v -> i k v -> i k v

    -- | Computes the intersection of two indices.
    --
    -- @
    -- lookup k (i1 `intersection` i2)
    -- ==
    -- lookup k i1 `Set.intersection` lookup k i2
    -- @
    --
    intersection :: i k v -> i k v -> i k v

    -- | Indicates whether or not the first index is a sub-index of the second.
    --
    -- @
    -- i1 `isSubIndexOf` i2 ==> lookup k i1 `Set.isSubsetOf` lookup k i2
    -- @
    --
    isSubIndexOf :: i k v -> i k v -> Bool
