module X where
data Struct = Empty | NonEmpty StructType a
data StructType a = Exec1 a | Exec2 a

apply :: Struct -> String
apply (Empty) = "matched Empty"
apply (NonEmpty Exec1 Int ) = "matched Exec1 or Exec2"
