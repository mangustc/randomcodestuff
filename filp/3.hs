-- На предприятии все должности упорядочены по старшинству.
-- Например (в вузе) преподавательские должности можно упорядочить следующим образом:
-- ассистент, преподаватель, старший преподаватель, доцент, профессор, декан, ректор.
-- Информация по персоналу включает в себя: ФИО, должность, оклад.
-- Определите тип данных для представления информации по отдельным людям.
-- Определить для этого типа функции ‘<’, ‘<=’ класса Ord, сравнивая людей по старшинству должностей.
-- При равных должностях сравниваются оклады.

data Job = Ассистент | Monkey | Bigmonkey | Kingmonkey
  deriving (Eq, Ord, Show)

type Lastname = String
type Firstname = String
type Middlename = String
type Salary = Int
data Employee = Employee Lastname Firstname Middlename Job Salary
  deriving (Show)
instance Eq Employee where
  Employee _ _ _ j1 s1 == Employee _ _ _ j2 s2 = j1 == j2 && s1 == s2
instance Ord Employee where
  Employee _ _ _ j1 s1 < Employee _ _ _ j2 s2 =
    j1 < j2 || (j1 == j2 && s1 < s2)
  Employee _ _ _ j1 s1 <= Employee _ _ _ j2 s2 =
    j1 < j2 || (j1 == j2 && s1 <= s2)

main = print $ (Employee "1" "1" "1" Bigmonkey 1000) > (Employee "2" "2" "2" Monkey 1000)
