(.) on unary
f . g = \x -> f (g x)

(.) on one binary, one unary
(sort .) . (<>)

(.) on two binary
(fmap . const) x a == fmap (const x) a

wait a sec, (.) is fmap? so (.).(.).(.)

<joel135> :t (.).(.).(.)                                                [16:55]
<lambdabot> (b -> c) -> (a1 -> a2 -> a3 -> b) -> a1 -> a2 -> a3 -> c

<guest1216> wait a sec, is . fmap?                                      [16:56]
<guest1216> fmap f g == f . g?
<joel135> not really
<joel135> but it is related to the hom functor, so yes
<joel135> :t fmap :: (b -> c) -> (a -> b) -> (a -> c)
<lambdabot> (b -> c) -> (a -> b) -> a -> c
<guest1216> "<joel135> :t (.).(.).(.)" Total Recall 1990?
<joel135> > ((\x -> x^2) <$> (\x -> x + 1)) 5
<lambdabot>  36
