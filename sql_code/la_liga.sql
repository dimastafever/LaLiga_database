-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler version: 1.0.0-beta1
-- PostgreSQL version: 15.0
-- Project Site: pgmodeler.io
-- Model Author: ---
-- -- object: pg_database_owner | type: ROLE --
-- -- DROP ROLE IF EXISTS pg_database_owner;
-- CREATE ROLE pg_database_owner WITH 
-- 	INHERIT
-- 	 PASSWORD '********';
-- -- ddl-end --
-- 
-- object: pdajunior | type: ROLE --
-- DROP ROLE IF EXISTS pdajunior;
CREATE ROLE pdajunior WITH 
	INHERIT
	LOGIN
	 PASSWORD '********';
-- ddl-end --

-- object: "SAB" | type: ROLE --
-- DROP ROLE IF EXISTS "SAB";
CREATE ROLE "SAB" WITH 
	SUPERUSER
	CREATEDB
	INHERIT
	LOGIN
	 PASSWORD '********';
-- ddl-end --


-- Database creation must be performed outside a multi lined SQL file. 
-- These commands were put in this file only as a convenience.
-- 
-- object: la_liga | type: DATABASE --
-- DROP DATABASE IF EXISTS la_liga;
CREATE DATABASE la_liga
	ENCODING = 'UTF8'
	LC_COLLATE = 'ru_RU.UTF-8'
	LC_CTYPE = 'ru_RU.UTF-8'
	TABLESPACE = pg_default
	OWNER = postgres;
-- ddl-end --


SET check_function_bodies = false;
-- ddl-end --

-- object: public.teams | type: TABLE --
-- DROP TABLE IF EXISTS public.teams CASCADE;
CREATE TABLE public.teams (
	team_id smallint NOT NULL,
	team_name character varying(100) NOT NULL,
	team_short_name character varying(50),
	founded_year integer NOT NULL,
	city character varying(50),
	points smallint,
	CONSTRAINT year_ch CHECK (((founded_year >= 1800) AND ((founded_year)::numeric <= EXTRACT(year FROM CURRENT_DATE)))),
	CONSTRAINT points_ch CHECK ((points >= 0)),
	CONSTRAINT teams_pk PRIMARY KEY (team_id)
);
-- ddl-end --
ALTER TABLE public.teams OWNER TO postgres;
-- ddl-end --

-- object: public.players | type: TABLE --
-- DROP TABLE IF EXISTS public.players CASCADE;
CREATE TABLE public.players (
	player_id integer NOT NULL,
	api_id integer NOT NULL,
	name character varying(100),
	"position" character varying(50),
	nationality character varying(50),
	team_id smallint,
	CONSTRAINT players_pk PRIMARY KEY (player_id)
);
-- ddl-end --
ALTER TABLE public.players OWNER TO postgres;
-- ddl-end --

-- object: public.stadiums | type: TABLE --
-- DROP TABLE IF EXISTS public.stadiums CASCADE;
CREATE TABLE public.stadiums (
	stadium_id smallint NOT NULL,
	name character varying(100) NOT NULL,
	capacity integer,
	city character varying(50),
	team_id smallint,
	CONSTRAINT capacity_ch CHECK ((capacity > 0)),
	CONSTRAINT stadiums_pk PRIMARY KEY (stadium_id)
);
-- ddl-end --
ALTER TABLE public.stadiums OWNER TO postgres;
-- ddl-end --

-- object: public.coaches | type: TABLE --
-- DROP TABLE IF EXISTS public.coaches CASCADE;
CREATE TABLE public.coaches (
	coach_id integer NOT NULL,
	coach_name character varying(100) NOT NULL,
	nationality character varying(50),
	birth_date date,
	salary money,
	team_id smallint,
	CONSTRAINT data_ch CHECK ((birth_date > '1900-01-01'::date)),
	CONSTRAINT coaches_pk PRIMARY KEY (coach_id)
);
-- ddl-end --
ALTER TABLE public.coaches OWNER TO postgres;
-- ddl-end --

-- object: public.matches | type: TABLE --
-- DROP TABLE IF EXISTS public.matches CASCADE;
CREATE TABLE public.matches (
	match_id integer NOT NULL,
	home_team_id smallint NOT NULL,
	away_team_id smallint NOT NULL,
	stadium_id smallint,
	attendance integer,
	round_number smallint,
	home_team_score integer,
	away_team_score integer,
	CONSTRAINT attendance_ch CHECK ((attendance >= 0)),
	CONSTRAINT round_number CHECK (((round_number >= 1) AND (round_number <= 38))),
	CONSTRAINT matches_pk PRIMARY KEY (match_id),
	CONSTRAINT matches_home_team_score_check CHECK ((home_team_score >= 0)),
	CONSTRAINT matches_away_team_score_check CHECK ((away_team_score >= 0))
);
-- ddl-end --
ALTER TABLE public.matches OWNER TO postgres;
-- ddl-end --

-- object: public.player_stats | type: TABLE --
-- DROP TABLE IF EXISTS public.player_stats CASCADE;
CREATE TABLE public.player_stats (
	player_id integer NOT NULL,
	matches smallint,
	goals smallint,
	assists smallint,
	red_cards smallint,
	total_points integer DEFAULT 0,
	CONSTRAINT goals_ch CHECK ((goals >= 0)),
	CONSTRAINT assists_ch CHECK ((assists >= 0)),
	CONSTRAINT player_stats_pk PRIMARY KEY (player_id)
);
-- ddl-end --
ALTER TABLE public.player_stats OWNER TO postgres;
-- ddl-end --

-- object: public.calculate_player_points | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.calculate_player_points() CASCADE;
CREATE FUNCTION public.calculate_player_points ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	PARALLEL UNSAFE
	COST 100
	AS $$
BEGIN
    NEW.total_points := (NEW.goals) + (NEW.assists);
    
    IF NEW.total_points < 0 THEN
        NEW.total_points := 0;
    END IF;
    
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.calculate_player_points() OWNER TO postgres;
-- ddl-end --

-- object: idx_players_team_id | type: INDEX --
-- DROP INDEX IF EXISTS public.idx_players_team_id CASCADE;
CREATE INDEX idx_players_team_id ON public.players
USING btree
(
	team_id
)
WITH (FILLFACTOR = 90);
-- ddl-end --

-- object: idx_players_position | type: INDEX --
-- DROP INDEX IF EXISTS public.idx_players_position CASCADE;
CREATE INDEX idx_players_position ON public.players
USING btree
(
	"position"
)
WITH (FILLFACTOR = 90);
-- ddl-end --

-- object: idx_players_nationality | type: INDEX --
-- DROP INDEX IF EXISTS public.idx_players_nationality CASCADE;
CREATE INDEX idx_players_nationality ON public.players
USING btree
(
	nationality
)
WITH (FILLFACTOR = 90);
-- ddl-end --

-- object: trigger_calculate_points | type: TRIGGER --
-- DROP TRIGGER IF EXISTS trigger_calculate_points ON public.player_stats CASCADE;
CREATE TRIGGER trigger_calculate_points
	BEFORE INSERT OR UPDATE
	ON public.player_stats
	FOR EACH ROW
	EXECUTE PROCEDURE public.calculate_player_points();
-- ddl-end --

-- object: public.add_points_to_team | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS public.add_points_to_team(integer,integer) CASCADE;
CREATE PROCEDURE public.add_points_to_team (team_id_input integer, points_to_add integer)
	LANGUAGE plpgsql
	SECURITY INVOKER
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
-- ddl-end --
ALTER PROCEDURE public.add_points_to_team(integer,integer) OWNER TO postgres;
-- ddl-end --

-- object: public.count_team_players | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS public.count_team_players(integer) CASCADE;
CREATE PROCEDURE public.count_team_players (team_id_input integer)
	LANGUAGE plpgsql
	SECURITY INVOKER
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
-- ddl-end --
ALTER PROCEDURE public.count_team_players(integer) OWNER TO postgres;
-- ddl-end --

-- object: public.count_goals_in_round | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS public.count_goals_in_round(integer) CASCADE;
CREATE PROCEDURE public.count_goals_in_round (round_number_input integer)
	LANGUAGE plpgsql
	SECURITY INVOKER
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
-- ddl-end --
ALTER PROCEDURE public.count_goals_in_round(integer) OWNER TO postgres;
-- ddl-end --

-- object: public.show_team_stadium | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS public.show_team_stadium(integer) CASCADE;
CREATE PROCEDURE public.show_team_stadium (team_id_input integer)
	LANGUAGE plpgsql
	SECURITY INVOKER
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
-- ddl-end --
ALTER PROCEDURE public.show_team_stadium(integer) OWNER TO postgres;
-- ddl-end --

-- object: public.add_new_player | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS public.add_new_player(character varying,character varying,character varying,integer) CASCADE;
CREATE PROCEDURE public.add_new_player (player_name_input character varying, position_input character varying, nationality_input character varying, team_id_input integer)
	LANGUAGE plpgsql
	SECURITY INVOKER
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
-- ddl-end --
ALTER PROCEDURE public.add_new_player(character varying,character varying,character varying,integer) OWNER TO postgres;
-- ddl-end --

-- object: team_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.players DROP CONSTRAINT IF EXISTS team_id_fk CASCADE;
ALTER TABLE public.players ADD CONSTRAINT team_id_fk FOREIGN KEY (team_id)
REFERENCES public.teams (team_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: team_fk | type: CONSTRAINT --
-- ALTER TABLE public.stadiums DROP CONSTRAINT IF EXISTS team_fk CASCADE;
ALTER TABLE public.stadiums ADD CONSTRAINT team_fk FOREIGN KEY (team_id)
REFERENCES public.teams (team_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: team_id_fc_fk | type: CONSTRAINT --
-- ALTER TABLE public.coaches DROP CONSTRAINT IF EXISTS team_id_fc_fk CASCADE;
ALTER TABLE public.coaches ADD CONSTRAINT team_id_fc_fk FOREIGN KEY (team_id)
REFERENCES public.teams (team_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: stadium_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS stadium_id_fk CASCADE;
ALTER TABLE public.matches ADD CONSTRAINT stadium_id_fk FOREIGN KEY (stadium_id)
REFERENCES public.stadiums (stadium_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: home_team_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS home_team_id_fk CASCADE;
ALTER TABLE public.matches ADD CONSTRAINT home_team_id_fk FOREIGN KEY (home_team_id)
REFERENCES public.teams (team_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: away_team_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS away_team_id_fk CASCADE;
ALTER TABLE public.matches ADD CONSTRAINT away_team_id_fk FOREIGN KEY (away_team_id)
REFERENCES public.teams (team_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: player_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.player_stats DROP CONSTRAINT IF EXISTS player_id_fk CASCADE;
ALTER TABLE public.player_stats ADD CONSTRAINT player_id_fk FOREIGN KEY (player_id)
REFERENCES public.players (player_id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: "grant_CU_26541e8cda" | type: PERMISSION --
GRANT CREATE,USAGE
   ON SCHEMA public
   TO pg_database_owner;
-- ddl-end --

-- object: "grant_U_cd8e46e7b6" | type: PERMISSION --
GRANT USAGE
   ON SCHEMA public
   TO PUBLIC;
-- ddl-end --


