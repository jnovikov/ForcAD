CREATE OR REPLACE FUNCTION update_teamtasks_status(_round INTEGER, _team_id INTEGER, _task_id INTEGER, _status INTEGER,
                                                   _passed INTEGER, _public_message TEXT, _private_message TEXT,
                                                   _command TEXT)
    RETURNS SETOF teamtasks
AS
$$
BEGIN
    INSERT INTO teamtaskslog (round, task_id, team_id, status, stolen, lost, score, checks, checks_passed,
                              public_message, private_message,
                              command)
    SELECT _round,
           _task_id,
           _team_id,
           status,
           stolen,
           lost,
           score,
           checks,
           checks_passed,
           public_message,
           private_message,
           command
    FROM teamtasks
    WHERE team_id = _team_id
      AND task_id = _task_id
        FOR NO KEY UPDATE;

    RETURN QUERY UPDATE teamtasks
        SET status = _status,
            public_message = _public_message,
            private_message = _private_message,
            command = _command,
            checks_passed = checks_passed + _passed,
            checks = checks + 1
        WHERE team_id = _team_id
            AND task_id = _task_id
        RETURNING *;
END;
$$ LANGUAGE plpgsql ROWS 1;

CREATE OR REPLACE FUNCTION recalculate_rating(_attacker_id INTEGER, _victim_id INTEGER, _task_id INTEGER,
                                              _flag_id INTEGER)
    RETURNS TABLE
            (
                attacker_delta FLOAT,
                victim_delta   FLOAT
            )
AS
$$
DECLARE
    _round          INTEGER;
    hardness        FLOAT;
    inflate         BOOLEAN;
    scale           FLOAT;
    norm            FLOAT;
    attacker_score  FLOAT;
    victim_score    FLOAT;
    _attacker_delta FLOAT;
    _victim_delta   FLOAT;
BEGIN
    SELECT real_round, game_hardness, inflation FROM globalconfig WHERE id = 1 INTO _round, hardness, inflate;

--     avoid deadlocks by locking min(attacker, victim), then max(attacker, victim)
    if _attacker_id < _victim_id THEN
        SELECT score
        FROM teamtasks
        WHERE team_id = _attacker_id
          AND task_id = _task_id FOR NO KEY UPDATE
        INTO attacker_score;

        SELECT score
        FROM teamtasks
        WHERE team_id = _victim_id
          AND task_id = _task_id FOR NO KEY UPDATE
        INTO victim_score;
    ELSE
        SELECT score
        FROM teamtasks
        WHERE team_id = _victim_id
          AND task_id = _task_id FOR NO KEY UPDATE
        INTO victim_score;

        SELECT score
        FROM teamtasks
        WHERE team_id = _attacker_id
          AND task_id = _task_id FOR NO KEY UPDATE
        INTO attacker_score;
    END IF;

    scale = 50 * sqrt(hardness);
    norm = ln(ln(hardness)) / 12;
    _attacker_delta = scale / (1 + exp((sqrt(attacker_score) - sqrt(victim_score)) * norm));
    _victim_delta = -least(victim_score, _attacker_delta);

    IF inflate THEN
        _attacker_delta = least(_attacker_delta, -_victim_delta);
    END IF;

    INSERT INTO stolenflags (attacker_id, flag_id) VALUES (_attacker_id, _flag_id);

    UPDATE teamtasks
    SET stolen = stolen + 1,
        score  = score + _attacker_delta
    WHERE team_id = _attacker_id
      AND task_id = _task_id;

    UPDATE teamtasks
    SET lost  = lost + 1,
        score = score + _victim_delta
    WHERE team_id = _victim_id
      AND task_id = _task_id;

    attacker_delta := _attacker_delta;
    victim_delta := _victim_delta;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql ROWS 1;


CREATE OR REPLACE FUNCTION get_first_bloods()
    RETURNS TABLE
            (
                submit_time   TIMESTAMP WITH TIME ZONE,
                attacker_name VARCHAR(255),
                task_name     VARCHAR(255),
                attacker_id   INTEGER,
                task_id       INTEGER,
                vuln_number   INTEGER
            )
AS
$$
BEGIN
    RETURN QUERY WITH preprocess AS (SELECT DISTINCT ON (f.task_id, f.vuln_number) sf.submit_time AS submit_time,
                                                                                   sf.attacker_id AS attacker_id,
                                                                                   f.task_id      AS task_id,
                                                                                   f.vuln_number  as vuln_number
                                     FROM stolenflags sf
                                              JOIN flags f ON f.id = sf.flag_id)
                 SELECT preprocess.submit_time AS submit_time,
                        tm.name                AS attacker_name,
                        tk.name                AS task_name,
                        tm.id                  AS attacker_id,
                        tk.id                  AS task_id,
                        preprocess.vuln_number AS vuln_number
                 FROM preprocess
                          JOIN teams tm ON tm.id = preprocess.attacker_id
                          JOIN tasks tk ON tk.id = preprocess.task_id
                 ORDER BY submit_time;
END;
$$ LANGUAGE plpgsql;