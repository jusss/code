module X where
data Color = Red | Green | Blue

class BasicEq a where
      isEqual :: a -> a -> Bool
      isEqual x y = not (isNotEqual x y)

      isNotEqual :: a -> a -> Bool
      isNotEqual x y = not (isEqual x y)

instance BasicEq Bool where
         isEqual True True = True
         isEqual False False = True
         isEqual _ _ = False

instance BasicEq Color where
         isEqual Red Red = True
         isEqual Green Green = True
         isEqual Blue Blue = True
         isEqual _ _ = False

             
t :: (BasicEq a)=> a -> a -> Bool
t x y = isEqual x y
