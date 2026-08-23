package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	DatabaseURL        string
	JWTSecret          string
	CORSAllowedOrigins []string
}

func NewConfig(envFile string) (*Config, error) {
	if envFile != "" {
		_ = godotenv.Load(envFile)
	}

	cfg := &Config{
		Port:               Getenv("PORT", "8080"),
		DatabaseURL:        Getenv("DATABASE_URL", ""),
		JWTSecret:          Getenv("JWT_SECRET", "default-secret"),
		CORSAllowedOrigins: parseCorsOrigins(Getenv("CORS_ALLOWED_ORIGINS", "")),
	}

	// If DATABASE_URL is not set, try to construct it from individual DB environment variables
	if cfg.DatabaseURL == "" {
		dbUser := Getenv("DATABASE_USER", "")
		dbPassword := Getenv("DATABASE_PASSWORD", "")
		dbHost := Getenv("DATABASE_HOST", "")
		dbPort := Getenv("DATABASE_PORT", "")
		dbName := Getenv("DATABASE_NAME", "")

		if dbUser == "" || dbHost == "" || dbPort == "" || dbName == "" {
			return nil, fmt.Errorf("DATABASE_URL is not set and individual DATABASE_USER, DATABASE_HOST, DATABASE_PORT, DATABASE_NAME environment variables are not fully provided")
		}
		cfg.DatabaseURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", dbUser, dbPassword, dbHost, dbPort, dbName)
	}

	return cfg, nil
}

// Getenv retrieves the value of the environment variable named by the key,
// or returns the provided fallback value if the variable is not set.
func Getenv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

// parseCorsOrigins takes a comma-separated string and splits it into a slice of strings.
func parseCorsOrigins(s string) []string {
	if s == "" {
		return nil // Return nil to let the CORS middleware use its default behavior
	}
	origins := strings.Split(s, ",")
	for i := range origins {
		origins[i] = strings.TrimSpace(origins[i])
	}
	return origins
}

// LoadConfig is kept for compatibility but the main entry point is NewConfig.
// It's useful for pre-loading before other packages initialize.
func LoadConfig(path string) error {
	err := godotenv.Load(path)
	if err != nil {
		return fmt.Errorf("error loading .env file from path %s: %w", path, err)
	}
	return nil
}
