USE `F1`;

-- Relaciones inferidas y validadas contra los CSV de la base F1.
-- Este script es idempotente: solo crea la clave foranea si aun no existe.
-- En DBeaver ejecuta el archivo completo como script.
-- Si lo corres por bloques, primero ejecuta la definicion del procedimiento.

DROP PROCEDURE IF EXISTS add_fk_if_missing;

DELIMITER $$

CREATE PROCEDURE add_fk_if_missing(
    IN p_table_name VARCHAR(64),
    IN p_constraint_name VARCHAR(64),
    IN p_statement TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table_name
          AND CONSTRAINT_NAME = p_constraint_name
          AND CONSTRAINT_TYPE = 'FOREIGN KEY'
    ) THEN
        SET @ddl = p_statement;
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

CALL add_fk_if_missing(
    'races',
    'fk_races_seasons',
    'ALTER TABLE `races`
        ADD CONSTRAINT `fk_races_seasons`
        FOREIGN KEY (`year`) REFERENCES `seasons` (`year`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'races',
    'fk_races_circuits',
    'ALTER TABLE `races`
        ADD CONSTRAINT `fk_races_circuits`
        FOREIGN KEY (`circuitId`) REFERENCES `circuits` (`circuitId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'constructor_results',
    'fk_constructor_results_races',
    'ALTER TABLE `constructor_results`
        ADD CONSTRAINT `fk_constructor_results_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'constructor_results',
    'fk_constructor_results_constructors',
    'ALTER TABLE `constructor_results`
        ADD CONSTRAINT `fk_constructor_results_constructors`
        FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'constructor_standings',
    'fk_constructor_standings_races',
    'ALTER TABLE `constructor_standings`
        ADD CONSTRAINT `fk_constructor_standings_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'constructor_standings',
    'fk_constructor_standings_constructors',
    'ALTER TABLE `constructor_standings`
        ADD CONSTRAINT `fk_constructor_standings_constructors`
        FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'driver_standings',
    'fk_driver_standings_races',
    'ALTER TABLE `driver_standings`
        ADD CONSTRAINT `fk_driver_standings_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'driver_standings',
    'fk_driver_standings_drivers',
    'ALTER TABLE `driver_standings`
        ADD CONSTRAINT `fk_driver_standings_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'results',
    'fk_results_races',
    'ALTER TABLE `results`
        ADD CONSTRAINT `fk_results_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'results',
    'fk_results_drivers',
    'ALTER TABLE `results`
        ADD CONSTRAINT `fk_results_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'results',
    'fk_results_constructors',
    'ALTER TABLE `results`
        ADD CONSTRAINT `fk_results_constructors`
        FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'results',
    'fk_results_status',
    'ALTER TABLE `results`
        ADD CONSTRAINT `fk_results_status`
        FOREIGN KEY (`statusId`) REFERENCES `status` (`statusId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'sprint_results',
    'fk_sprint_results_races',
    'ALTER TABLE `sprint_results`
        ADD CONSTRAINT `fk_sprint_results_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'sprint_results',
    'fk_sprint_results_drivers',
    'ALTER TABLE `sprint_results`
        ADD CONSTRAINT `fk_sprint_results_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'sprint_results',
    'fk_sprint_results_constructors',
    'ALTER TABLE `sprint_results`
        ADD CONSTRAINT `fk_sprint_results_constructors`
        FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'sprint_results',
    'fk_sprint_results_status',
    'ALTER TABLE `sprint_results`
        ADD CONSTRAINT `fk_sprint_results_status`
        FOREIGN KEY (`statusId`) REFERENCES `status` (`statusId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'qualifying',
    'fk_qualifying_races',
    'ALTER TABLE `qualifying`
        ADD CONSTRAINT `fk_qualifying_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'qualifying',
    'fk_qualifying_drivers',
    'ALTER TABLE `qualifying`
        ADD CONSTRAINT `fk_qualifying_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'qualifying',
    'fk_qualifying_constructors',
    'ALTER TABLE `qualifying`
        ADD CONSTRAINT `fk_qualifying_constructors`
        FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'lap_times',
    'fk_lap_times_races',
    'ALTER TABLE `lap_times`
        ADD CONSTRAINT `fk_lap_times_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'lap_times',
    'fk_lap_times_drivers',
    'ALTER TABLE `lap_times`
        ADD CONSTRAINT `fk_lap_times_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'pit_stops',
    'fk_pit_stops_races',
    'ALTER TABLE `pit_stops`
        ADD CONSTRAINT `fk_pit_stops_races`
        FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);

CALL add_fk_if_missing(
    'pit_stops',
    'fk_pit_stops_drivers',
    'ALTER TABLE `pit_stops`
        ADD CONSTRAINT `fk_pit_stops_drivers`
        FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
        ON UPDATE CASCADE
        ON DELETE RESTRICT'
);
