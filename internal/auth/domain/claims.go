package domain

import "github.com/golang-jwt/jwt/v5"

type CustomClaims struct {
	UserID int `json:"user_id"`
	jwt.RegisteredClaims
}

type EmailClaims struct {
	Email string `json:"email"`
	jwt.RegisteredClaims
}
