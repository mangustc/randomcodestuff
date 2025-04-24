-- напишите функцию,  производящую взаимную замену y на х  и х на y:  x -> y,  y -> x

f :: Int -> Int -> [Int] -> [Int]
f _ _ [] = []
f x y (lh:lt)
  | lh == x = (y:next)
  | lh == y = (x:next)
  | otherwise = (lh:next)
  where next = f x y lt

main = print $ f 2 0 [0, 3, 2, 2, 5, 8, 0]
