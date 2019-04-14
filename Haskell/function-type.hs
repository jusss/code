module Test where
data Struct val =
                Empty
                | NonEmpty StructType val
data StructType =
                Exec1
                | Exec2
apply::Struct a -> String
apply (Empty) = "empty"
apply (NonEmpty exec struct) = "exec1 or exec2"                

                               
--apply Empty
--apply (NonEmpty Exec1 undefined)
--apply (NonEmpty Exec1 "aha")
--apply (NonEmpty Exec2 3)
--apply (NonEmpty Exec2 (\x -> 3 +x))
--apply (NonEmpty Exec2 ())
                
apply2::(Show a)=> Struct a -> String
apply2 (NonEmpty exec struct) = "exec1 or exec2"

--apply2 (NonEmpty Exec1 "a")                                
                                
apply3::(Show a)=> Struct a -> String
apply3 (NonEmpty exec _) = "exec1 or exec2"


<jusss> data Struct val = Empty | NonEmpty StrucType val;   data SturctType =
        Exec1 | Exec2;   apply::Struct a-> String;    apply (NonEmpty exec
        struct) ="exec1 or exec2"
<jusss> how I can use an expression to call it?  [13:35]
<jusss> apply NonEmpty ? ?   will get "exec1 or exec2"/
<jusss> apply NonEmpty Exec1 ?
 <slack1256> jusss: Can you use a paste service for that code?  [13:43]
<slack1256> jusss: apply (NonEmpty Exec1 undefined) should work  [13:44]
<jusss> slack1256 https://paste.ubuntu.com/p/RS7FtkHfFG/
<slack1256> jusss: I don't understand what you want to do
<jusss> slack1256 just an example from stackoverflow help me understand Value
        Constructor
<dmwit> jusss: Here are two examples of calls: `apply Empty` or `apply
        (NonEmpty Exec1 ())`  [14:09]
<dmwit> Just for fun, here's a third that may look a bit weirder to initiates
        of other languages: `apply (NonEmpty Exec2 (\x -> 3 + x))`  [14:10]
<jusss> dmwit: the question is how to handle that undefined type variable when
        it is called
<jusss> https://paste.ubuntu.com/p/s84KjsTtjH/
<dmwit> The caller of `apply` may choose any specific type they like to
        substitute for `a`.  [14:11]
<jusss> dmwit: wait a second, but function don't have a type I think,   [14:12]
<dmwit> In my three examples above, I left it unspecified (`Empty`), chose the
        unit type `()` (`NonEmpty Exec1 ()`), and chose a function type
        `Integer -> Integer` (`\x -> 3 + x`).
<jusss> dmwit: normal function has a type?
<dmwit> Certainly.
<dmwit> :t \x -> 3 + x  [14:13]
<lambdabot> Num a => a -> a
<dmwit> :t \name -> "Hello, " ++ name ++ "!"
<lambdabot> [Char] -> [Char]
<jusss> dmwit: so normal function can be used in pattern match?
<jusss> dmwit: value constructor is totally same with normal functions?
<dmwit> There are no interesting patterns which match functions.  [14:14]
<ggole> Variable patterns!
<dmwit> Yes, data constructors may be applied to functions.
<dmwit> ggole: Right. Variables and underscore. I consider these not
        interesting, because they can be used for *any* type.
<dmwit> There are no patterns which match functions but do not match every
        type.  [14:15]
<dmwit> (Hm. Maybe some view patterns, hey? Anyway that's an advanced topic
        for another time...)
<c_wraith> yeah, view patterns could, but that's a totally different thing,
           really  [14:16]
<ggole> Hmm, isn't there a pattern ascription extension?  [14:17]
<ggole> It might be better to think of functions not having any constructors
        with which to destructure function values, rather than talking about
        types.
<dmwit> You're right. I hereby steal that much better phrasing as my new
        definition of "interesting".  [14:20]
<jusss> this is really make me confused! so functions do have types? and they
        have types but can not be used in patter match?  [14:21]
<jusss> value constructor and normal function are same thing or not?  [14:22]
<jusss> can I call value constructor as function?
<slack1256> jusss: yep in the sense that they have types, but they are not of
            the same "kind"
<jusss> (Num a => a -> a) is one function's type? right?  [14:24]
<slack1256> % :t Just
<yahb> slack1256: a -> Maybe a
<c_wraith> jusss: functions don't actually have constructors.  But that's not
           conceptually any different from any other type that has
           constructors, but keeps them hidden someplace you can't import.
<slack1256> Just is a value constructor for Maybe and also a function that
            returns a Maybe  [14:25]                              
