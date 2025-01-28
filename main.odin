package http

import "core:fmt"
import "core:mem"

hello_world :: proc(request: Http_Request, response: ^Http_Response) -> ^Http_Response{
	response.status = "HAHA"
	return response
}

main :: proc() {
	server := http_server_builder()

	register_route("GET /hello", hello_world, &server)

	create_http_server("127.0.0.1", 8080, &server)
}
