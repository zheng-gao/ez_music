-- noinspection SqlNoDataSourceInspectionForFile
-- noinspection SqlDialectInspectionForFile

CREATE TABLE IF NOT EXISTS users (
    id SERIAL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);