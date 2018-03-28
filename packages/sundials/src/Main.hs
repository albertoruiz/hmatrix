{-# OPTIONS_GHC -Wall #-}

import qualified Data.Vector.Storable as V
import           Numeric.Sundials.Arkode.ODE
import           Numeric.LinearAlgebra

import           Plots as P
import qualified Diagrams.Prelude as D
import           Diagrams.Backend.Rasterific

import           Control.Lens
import           Data.List (zip4)

import           Text.PrettyPrint.HughesPJClass
import           Data.List (intercalate)


brusselator _t x = [ a - (w + 1) * u + v * u^2
                   , w * u - v * u^2
                   , (b - w) / eps - w * u
                   ]
  where
    a = 1.0
    b = 3.5
    eps = 5.0e-6
    u = x !! 0
    v = x !! 1
    w = x !! 2

stiffish t v = [ lamda * u + 1.0 / (1.0 + t * t) - lamda * atan t ]
  where
    lamda = -100.0
    u = v !! 0

lSaxis :: [[Double]] -> P.Axis B D.V2 Double
lSaxis xs = P.r2Axis &~ do
  let ts = xs!!0
      us = xs!!1
      vs = xs!!2
      ws = xs!!3
  P.linePlot' $ zip ts us
  P.linePlot' $ zip ts vs
  P.linePlot' $ zip ts ws

kSaxis :: [(Double, Double)] -> P.Axis B D.V2 Double
kSaxis xs = P.r2Axis &~ do
  P.linePlot' xs

butcherTableauTex :: (Show a, Element a) => Matrix a -> String
butcherTableauTex m = render $
                    vcat [ text ("\n\\begin{array}{c|" ++ (concat $ replicate n "c") ++ "}")
                         , us
                         , text "\\end{array}"
                         ]
  where
    n = rows m
    rs = toLists m
    ss = map (\r -> intercalate " & " $ map show r) rs
    ts = zipWith (\n r -> "c_" ++ show n ++ " & " ++ r) [1..n] ss
    us = vcat $ map (\r -> text r <+> text "\\\\") ts

main :: IO ()
main = do
  -- $$
  -- \begin{array}{c|cccc}
  -- c_1    & a_{11} & a_{12}& \dots & a_{1s}\\
  -- c_2    & a_{21} & a_{22}& \dots & a_{2s}\\
  -- \vdots & \vdots & \vdots& \ddots& \vdots\\
  -- c_s    & a_{s1} & a_{s2}& \dots & a_{ss} \\
  -- \hline
  --        & b_1    & b_2   & \dots & b_s\\
  --        & b^*_1  & b^*_2 & \dots & b^*_s\\
  -- \end{array}
  -- $$

  let res = btGet
  putStrLn $ show res
  putStrLn $ butcherTableauTex res

  let res = odeSolve brusselator [1.2, 3.1, 3.0] (fromList [0.0, 0.1 .. 10.0])
  putStrLn $ show res
  renderRasterific "diagrams/brusselator.png"
                   (D.dims2D 500.0 500.0)
                   (renderAxis $ lSaxis $ [0.0, 0.1 .. 10.0]:(toLists $ tr res))

  let res = odeSolve stiffish [0.0] (fromList [0.0, 0.1 .. 10.0])
  putStrLn $ show res
  renderRasterific "diagrams/stiffish.png"
                   (D.dims2D 500.0 500.0)
                   (renderAxis $ kSaxis $ zip [0.0, 0.1 .. 10.0] (concat $ toLists res))