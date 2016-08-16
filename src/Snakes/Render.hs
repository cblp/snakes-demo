{-# LANGUAGE RecordWildCards #-}
module Snakes.Render where

import Control.Arrow (first)
import Data.Function ((&))
import qualified Data.Map as Map
import Data.Monoid
import Graphics.Gloss
import Graphics.Gloss.Data.Vector
import Snakes.Config
import Snakes.Model

renderUniverse :: Universe -> Picture
renderUniverse Universe{..}
    = foldMap renderDeadLink uDeadLinks
   <> renderItem (head uItems)
   <> foldMap (uncurry renderSnake) snakesWithEffects
  where
    getEffects name = map effectType (Map.findWithDefault [] name uEffects)
    snakesWithEffects = map (first getEffects) (Map.toList uSnakes)

renderSnake :: [EffectType] -> Snake -> Picture
renderSnake effects Snake{..}
  = foldMap renderLink snakeLinks
  & color c
  where
    c | EffectPhantom `elem` effects = withAlpha 0.5 snakeColor
      | otherwise = snakeColor

renderLink :: Link -> Picture
renderLink (x, y)
  = thickCircle r r
  & translate x y
  where
    r = snakeLinkSize * 2/3

renderDeadLink :: DeadLink -> Picture
renderDeadLink DeadLink{..}
  = renderLink linkLocation
  & color (withAlpha (linkTimeout / deadLinkDuration) deadLinkColor)

renderItem :: Item -> Picture
renderItem Item{..}
  = (core <> ring)
  & translate x y
  & color (effectColor itemEffect)
  where
    (x, y) = itemLocation
    ring = renderTimeout (itemTimeout / effectItemDuration itemEffect) (effectItemSize itemEffect)
    core
      = renderCore (effectItemSize itemEffect) 5  -- FIXME: magic constant
      & rotate (degrees itemTurnRate * itemTimeout)

renderCore :: Float -> Int -> Picture
renderCore size n
  = polygon (take n (iterate (rotateV (2 * pi / fromIntegral n)) (0, r)))
  where
    r = 0.5 * size

renderTimeout :: Float -> Float -> Picture
renderTimeout x size
  = arc 0 (360 * x) size
  & rotate (-90)

-- | Convert radians to degrees.
degrees :: Float -> Float
degrees x = 180 * x / pi

