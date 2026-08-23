package main

import (
	"log"
	"os"

	"github.com/TonyGLL/cloud-erp/internal/shared/config"
	"github.com/TonyGLL/cloud-erp/internal/shared/infra/db"
	"github.com/TonyGLL/cloud-erp/internal/shared/infra/http"
	"github.com/TonyGLL/cloud-erp/internal/shared/infra/services"
	"github.com/go-playground/validator/v10"
)

func main() {
	log.Println("Starting server...")

	// --- Configuration ---
	cfg, err := config.NewConfig(os.Getenv("CONFIG_FILE"))
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// --- Shared dependecies ---
	validate := validator.New()

	database, err := db.NewDBPool(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Cloud not initilize database connection: %s", err)
	}
	defer database.Close()

	store := db.NewSQLStore(database)

	jwtService, err := services.NewJWTService(cfg.JWTSecret)
	if err != nil {
		log.Fatalf("Failed to create JWT service: %v", err)
	}

	// --- Repositories ---

	// --- Server ---
	server := http.NewServer(cfg)

	// --- Module Registration ---

	// --- Start server ---
	server.Run()
}
