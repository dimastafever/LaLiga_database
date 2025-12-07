-- 1.Топ-5 бомбардиров лиги
CREATE VIEW top_scorers AS
SELECT p.name,t.team_name,ps.goals,ps.assists,(ps.goals + ps.assists) as total_contributions
FROM player_stats ps
JOIN players p ON ps.player_id = p.player_id
JOIN teams t ON p.team_id = t.team_id
ORDER BY ps.goals DESC
LIMIT 5;

-- 2.Турнирная таблица
CREATE VIEW league_standings AS
SELECT t.team_name,t.points,t.city, COUNT(DISTINCT p.player_id) as player_count
FROM teams t
LEFT JOIN players p ON t.team_id = p.team_id
GROUP BY t.team_id, t.team_name, t.points, t.city
ORDER BY t.points DESC;

-- 3.Количество игроков по странам
SELECT nationality,COUNT(*) as player_count
FROM players
GROUP BY nationality
ORDER BY player_count DESC;

-- 4.Самые посещаемые матчи
SELECT m.match_id,ht.team_name as home_team,at.team_name as away_team,m.attendance,s.name as stadium
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
LEFT JOIN stadiums s ON m.stadium_id = s.stadium_id
WHERE m.attendance > 0
ORDER BY m.attendance DESC
LIMIT 10;
-- 5. Игроки с наибольшим количеством матчей
SELECT p.name,t.team_name,ps.matches,ps.goals,ps.assists
FROM player_stats ps
JOIN players p ON ps.player_id = p.player_id
JOIN teams t ON p.team_id = t.team_id
ORDER BY ps.matches DESC
LIMIT 10;

-- 6 Матчи с наибольшей разницей в счете
SELECT m.match_id,ht.team_name as home_team,at.team_name as away_team,m.home_team_score,m.away_team_score,ABS(m.home_team_score - m.away_team_score) as score_difference
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
WHERE m.home_team_score IS NOT NULL AND m.away_team_score IS NOT NULL
ORDER BY score_difference DESC
LIMIT 10;

-- 7. Команды по году основания
SELECT team_name,founded_year,city,(EXTRACT(YEAR FROM CURRENT_DATE) - founded_year) as age_years
FROM teams
ORDER BY founded_year;

-- 8. Игроки без статистики
SELECT p.player_id,p.name,t.team_name,p.position
FROM players p
JOIN teams t ON p.team_id = t.team_id
LEFT JOIN player_stats ps ON p.player_id = ps.player_id
WHERE ps.player_id IS NULL;

-- 9. Тренеры и их команды
SELECT c.coach_name,t.team_name,c.nationality,EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) as age
FROM coaches c
JOIN teams t ON c.team_id = t.team_id
ORDER BY t.team_name;

-- 10. Стадионы по вместимости
SELECT s.name,s.capacity, s.city, t.team_name
FROM stadiums s
JOIN teams t ON s.team_id = t.team_id
ORDER BY s.capacity DESC;

-- 11. Распределение игроков по позициям
SELECT position,COUNT(*) as player_count, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM players), 2) as percentage
FROM players
GROUP BY position
ORDER BY player_count DESC;

-- 12. Матчи по турам
SELECT  m.round_number,COUNT(*) as match_count,SUM(m.attendance) as total_attendance,AVG(m.attendance) as avg_attendance
FROM matches m
GROUP BY m.round_number
ORDER BY m.round_number;

-- 13. Команды с наибольшим количеством игроков
SELECT t.team_name, COUNT(p.player_id) as player_count
FROM teams t
LEFT JOIN players p ON t.team_id = p.team_id
GROUP BY t.team_id, t.team_name
ORDER BY player_count DESC;

-- 14. Игроки с красными карточками
SELECT p.name,t.team_name,ps.red_cards,ps.matches,ROUND(ps.red_cards * 100.0 / ps.matches, 2) as cards_per_match_percent
FROM player_stats ps
JOIN players p ON ps.player_id = p.player_id
JOIN teams t ON p.team_id = t.team_id
WHERE ps.red_cards > 0
ORDER BY ps.red_cards DESC;

-- 15. Домашняя статистика команд
SELECT t.team_name,COUNT(*) as home_matches,SUM(CASE WHEN m.home_team_score > m.away_team_score THEN 1 ELSE 0 END) as wins,SUM(CASE WHEN m.home_team_score = m.away_team_score THEN 1 ELSE 0 END) as draws,SUM(CASE WHEN m.home_team_score < m.away_team_score THEN 1 ELSE 0 END) as losses,
SUM(m.home_team_score) as goals_scored,SUM(m.away_team_score) as goals_conceded
FROM matches m
JOIN teams t ON m.home_team_id = t.team_id
WHERE m.home_team_score IS NOT NULL
GROUP BY t.team_id, t.team_name;

-- 16. Голы в среднем за матч по командам
SELECT t.team_name,COUNT(DISTINCT m.match_id) as total_matches,
    SUM(CASE 
        WHEN m.home_team_id = t.team_id THEN m.home_team_score
        WHEN m.away_team_id = t.team_id THEN m.away_team_score
        ELSE 0 END) as total_goals,
    ROUND(SUM(CASE 
        WHEN m.home_team_id = t.team_id THEN m.home_team_score
        WHEN m.away_team_id = t.team_id THEN m.away_team_score
        ELSE 0 END) * 1.0 / COUNT(DISTINCT m.match_id), 2) as goals_per_match
FROM teams t
LEFT JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
WHERE m.home_team_score IS NOT NULL
GROUP BY t.team_id, t.team_name
HAVING COUNT(DISTINCT m.match_id) > 0
ORDER BY goals_per_match DESC;

-- 17. Полная статистика матчей
SELECT m.match_id,ht.team_name as home_team,at.team_name as away_team,m.home_team_score,m.away_team_score,s.name as stadium,m.attendance,m.round_number,
    CASE 
        WHEN m.home_team_score > m.away_team_score THEN ht.team_name
        WHEN m.home_team_score < m.away_team_score THEN at.team_name
        ELSE 'Draw'
    END as winner
FROM matches m
JOIN teams ht ON m.home_team_id = ht.team_id
JOIN teams at ON m.away_team_id = at.team_id
LEFT JOIN stadiums s ON m.stadium_id = s.stadium_id
WHERE m.home_team_score IS NOT NULL
ORDER BY m.match_id;

-- 18. Эффективность игроков (голы+пас)
SELECT p.name,t.team_name,ps.goals,ps.assists,ps.matches,(ps.goals + ps.assists) as total_contributions,ROUND((ps.goals + ps.assists) * 1.0 / ps.matches, 2) as contributions_per_match
FROM player_stats ps
JOIN players p ON ps.player_id = p.player_id
JOIN teams t ON p.team_id = t.team_id
WHERE ps.matches > 0
ORDER BY contributions_per_match DESC
LIMIT 10;

-- 19. Все наши слоняры
SELECT name,position,nationality
FROM public.players
WHERE nationality= 'Russia'

-- 20. Все игроки Барселоны и Реал Мадрида
SELECT name,position,nationality
FROM public.players
WHERE team_id = 81 OR team_id = 86

-- 21. Тренеры по национальностям
SELECT nationality,COUNT(*) as coach_count,STRING_AGG(coach_name, ', ') as coaches_list
FROM coaches
GROUP BY nationality
ORDER BY coach_count DESC;

-- 22. Команды из определённого города
SELECT team_name, founded_year, points
FROM teams
WHERE city = 'Madrid'
ORDER BY points DESC;

CREATE INDEX idx_players_team_id ON players(team_id);

CREATE INDEX idx_players_position ON players(position);

CREATE INDEX idx_players_nationality ON players(nationality);


ALTER TABLE player_stats 
ADD COLUMN total_points INTEGER DEFAULT 0;

CREATE OR REPLACE FUNCTION calculate_player_points()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_points := (NEW.goals) + (NEW.assists);
    
    IF NEW.total_points < 0 THEN
        NEW.total_points := 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_points
    BEFORE INSERT OR UPDATE ON player_stats
    FOR EACH ROW
    EXECUTE FUNCTION calculate_player_points();

UPDATE player_stats SET total_points = (goals ) + assists
WHERE total_points = 0 OR total_points IS NULL;

-- 1Добавить очки команде
CREATE OR REPLACE PROCEDURE add_points_to_team(
    team_id_input INTEGER,
    points_to_add INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE teams 
    SET points = points + points_to_add
    WHERE team_id = team_id_input;
    
    IF FOUND THEN
        RAISE NOTICE 'Добавлено % очков команде ID %', points_to_add, team_id_input;
    ELSE
        RAISE NOTICE 'Команда с ID % не найдена', team_id_input;
    END IF;
END;
$$;
-- 2. Посчитать игроков команды
CREATE OR REPLACE PROCEDURE count_team_players(team_id_input INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    player_count INTEGER;
    team_name_var VARCHAR;
BEGIN
    SELECT team_name INTO team_name_var FROM teams WHERE team_id = team_id_input;
    
    IF FOUND THEN
        SELECT COUNT(*) INTO player_count 
        FROM players 
        WHERE team_id = team_id_input;
        
        RAISE NOTICE 'В команде "%" % игроков', team_name_var, player_count;
    ELSE
        RAISE NOTICE 'Команда с ID % не найдена', team_id_input;
    END IF;
END;
$$;

-- 3 Посчитать голы в туре
CREATE OR REPLACE PROCEDURE count_goals_in_round(round_number_input INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    total_goals INTEGER;
BEGIN
    SELECT SUM(home_team_score + away_team_score) INTO total_goals
    FROM matches
    WHERE round_number = round_number_input
      AND home_team_score IS NOT NULL;
    
    IF total_goals IS NOT NULL THEN
        RAISE NOTICE 'В % туре забито % голов', round_number_input, total_goals;
    ELSE
        RAISE NOTICE 'В % туре ещё нет результатов', round_number_input;
    END IF;
END;
$$;

-- 4  Показать стадион команды
CREATE OR REPLACE PROCEDURE show_team_stadium(team_id_input INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    stadium_name VARCHAR;
    stadium_capacity INTEGER;
    stadium_city VARCHAR;
BEGIN
    SELECT s.name, s.capacity, s.city 
    INTO stadium_name, stadium_capacity, stadium_city
    FROM stadiums s
    WHERE s.team_id = team_id_input;
    
    IF FOUND THEN
        RAISE NOTICE 'Стадион: %, Вместимость: %, Город: %',
                     stadium_name, stadium_capacity, stadium_city;
    ELSE
        RAISE NOTICE 'Стадион не найден для команды ID %', team_id_input;
    END IF;
END;
$$;

-- 5.Добавить нового игрока
CREATE OR REPLACE PROCEDURE add_new_player(
    player_name_input VARCHAR,
    position_input VARCHAR,
    nationality_input VARCHAR,
    team_id_input INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_player_id INTEGER;
BEGIN
    SELECT COALESCE(MAX(player_id), 0) + 1 INTO new_player_id FROM players;
    
    INSERT INTO players (player_id, api_id, name, position, nationality, team_id)
    VALUES (new_player_id, new_player_id + 1000, player_name_input, 
            position_input, nationality_input, team_id_input);
    
    RAISE NOTICE 'Новый игрок добавлен: ID %, Имя: %', 
                 new_player_id, player_name_input;
END;
$$;