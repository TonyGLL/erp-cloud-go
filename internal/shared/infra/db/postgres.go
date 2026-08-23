package db

import (
	"database/sql"
	"fmt"
)

func NewDBPool(connString string) (*sql.DB, error) {
	if connString == "" {
		return nil, fmt.Errorf("Database connection string is empty")
	}

	db, err := sql.Open("postgres", connString)
	if err != nil {
		return nil, fmt.Errorf("Unable to open database connection: %w", err)
	}

	// Pint the database to verify the connection is alive
	err = db.Ping()
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("Unable to connect to database: %w", err)
	}

	return db, nil
}
