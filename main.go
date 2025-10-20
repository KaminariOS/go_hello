package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// Health endpoint returns a simple JSON payload for basic monitoring.
	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"message": "Gin server is running",
		})
	})

	// Root endpoint returns a friendly greeting.
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Welcome to the Gin web server!",
		})
	})

	addr := ":" + serverPort()
	if err := router.Run(addr); err != nil {
		log.Fatalf("failed to start server: %v", err)
	}
}

// serverPort obtains the port from PORT env var, defaulting to 8080.
func serverPort() string {
	if port := os.Getenv("PORT"); port != "" {
		return port
	}
	return "8080"
}
