{-# LANGUAGE GADTs #-}
module Elb.InvFun (
  InvFun(Pure, Compose, Subcall, Undo, Flip, RandInt),
  sample
) where

import Control.Monad.Error ()

import Elb.PureInvFun (PureInvFun)
import qualified Elb.PureInvFun as Pure
import Elb.Sampler (Sampler, flipCoin, unflipCoin)

data (Eq a, Eq b) => InvFun a b where
  Pure :: PureInvFun a b -> InvFun a b
  Compose :: Eq b => InvFun a b -> InvFun b c -> InvFun a c
  Subcall :: (Eq b, Eq c) => (a -> InvFun b c) -> InvFun (a, b) (a, c)
  Undo :: InvFun a b -> InvFun b a
  Flip :: Double -> InvFun () Bool
  -- TODO(mario) Make a function to get a random Int

sample :: (Eq a, Eq b) => InvFun a b -> a -> Sampler b
sample (Pure f) x = case Pure.call f x of
  Left err -> fail err
  Right res -> return res
sample (Compose f g) x = sample f x >>= sample g
sample (Subcall f) (a, b) = do
  c <- sample (f a) b
  return (a, c)
sample (Undo f) x = unsample f x
sample (Flip prob) () = flipCoin prob

unsample :: (Eq a, Eq b) => InvFun a b -> b -> Sampler a
unsample (Pure f) x = sample (Pure (Pure.invert f)) x
unsample (Compose f g) x = unsample g x >>= unsample f
unsample (Subcall f) x = sample (Subcall (Undo . f)) x
unsample (Undo f) x = sample f x
unsample (Flip prob) heads = unflipCoin prob heads

