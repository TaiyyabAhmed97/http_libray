package http

import "core:fmt"
import "core:mem"

main :: proc() {
	config := Config {
		hostname="127.0.0.1",
		port=8080
	}
	create_http_client(&config)

	GET("/")
}
