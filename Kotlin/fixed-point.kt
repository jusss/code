sealed class Fix<F>
data class MkFix<F: Fix<F>> (val x: F): Fix<F>()

newtype Fix f = MkFix (f (Fix f))
MkFix (Just (MkFix (Just (MkFix Nothing)))) :: Fix Maybe
MkFix Nothing :: Fix Maybe
MkFix (Just (MkFix Nothing)) :: Fix Maybe
MkFix :: f (Fix f) -> Fix f