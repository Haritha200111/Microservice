package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

// TestMain is a simple test to ensure the main function works as expected.
// hhh
func TestMain(t *testing.T) {
	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		c.String(200, "Hello, World!")
	})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/", nil)
	router.ServeHTTP(w, req)
	if w.Code != 200 || w.Body.String() != "Hello, World!" {
		t.Errorf("Expected status 200 and body 'Hello, World!', got %d and '%s'", w.Code, w.Body.String())
	}
}
