-- Результаты соревнований хранятся в виде базы фактов: матч(<команда1>,N1,<команда2>,N2),
-- где Ni – количество голов, забитых командой i.
-- Необходимо сформировать рейтинговую таблицу команд,
-- если победа приносит команде 3 очка, а ничья – 1 очко.
-- В случае одинакового количества очков, рейтинг выше у той команды, которая забила больше голов.

{-# OPTIONS_GHC -Wno-missing-methods #-}

import System.IO
import Data.List

type Team = String
type Goals = Int
data Match = Match Team Goals Team Goals
    deriving(Show, Read)

type Points = Int
data TeamStanding = TeamStanding Team Goals Points
    deriving(Read)
instance Num TeamStanding where
    (TeamStanding tn1 tg1 tp1) + (TeamStanding _ tg2 tp2) = TeamStanding tn1 (tg1 + tg2) (tp1 + tp2)
instance Eq TeamStanding where
    TeamStanding _ tg1 tp1  == TeamStanding _ tg2 tp2 = tg1 == tg2 && tp1 == tp2
instance Ord TeamStanding where
    TeamStanding _ tg1 tp1 < TeamStanding _ tg2 tp2 =
        tp1 < tp2 || (tp1 == tp2 && tg1 < tg2)
    TeamStanding _ tg1 tp1 <= TeamStanding _ tg2 tp2 =
        tp1 < tp2 || (tp1 == tp2 && tg1 <= tg2)
instance Show TeamStanding where
    show (TeamStanding tn tg tp) = "Команда " ++ tn ++ " забила голов: " ++ (show tg) ++ ", очков: " ++ (show tp)


getTeamStanding :: Team -> [Match] -> TeamStanding
getTeamStanding tn [] = TeamStanding tn 0 0
getTeamStanding tn ((Match mht1 mhg1 mht2 mhg2):mt)
    -- Win
    | isTeam1 && hasTeam1Won = nextTeamStanding + TeamStanding tn mhg1 3
    | isTeam2 && hasTeam2Won = nextTeamStanding + TeamStanding tn mhg2 3
    -- Loss
    | isTeam1 && hasTeam2Won = nextTeamStanding + TeamStanding tn mhg1 0
    | isTeam2 && hasTeam1Won = nextTeamStanding + TeamStanding tn mhg2 0
    -- Tie
    | (isTeam1 || isTeam2) && ((not hasTeam1Won) && (not hasTeam2Won)) = nextTeamStanding + TeamStanding tn mhg1 1
    -- No team tn in match
    | otherwise = nextTeamStanding
    where 
        nextTeamStanding = getTeamStanding tn mt
        isTeam1 = mht1 == tn
        isTeam2 = mht2 == tn
        hasTeam1Won = mhg1 > mhg2
        hasTeam2Won = mhg2 > mhg1

getTeamStandings :: [Team] -> [Match] -> [TeamStanding]
getTeamStandings [th] m = [getTeamStanding th m]
getTeamStandings (th:tt) m = (getTeamStanding th m:getTeamStandings tt m)

main = do 
    contents <- readFile "test.txt"
    let flines = lines contents
    let matches = map (\ line -> read line::Match) flines
    let teams = nub ((map (\ (Match t1 _ _ _) -> t1) matches) ++ (map (\ (Match _ _ t2 _) -> t2) matches))
    let teamStandings = reverse (sort (getTeamStandings teams matches))
    putStrLn "Рейтинговая таблица команд (от лучшей к худшей):\n"
    mapM_ print teamStandings
