module Main where

import System.Random

main :: IO ()
main = do
  -- Generate a random number between 1 and 100 (inclusive)
  randomNumber <- randomRIO (1, 100) :: IO Int
  putStrLn $ "Hello " ++ show randomNumber
