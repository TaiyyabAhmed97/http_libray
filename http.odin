package http

import "core:fmt"
import "core:net"
import "core:thread"
import "core:bytes"
import "core:time/datetime"

Request_headers :: struct {
	method: string,
	path: string,
	host: string,
	user_agent: string,
	accept: string
}

Http_Request :: struct {
	headers: ^map[string]string,
	body: string
}

Http_Response :: struct {
	response_code: int,
	response_status: string,
	date: datetime.DateTime,
	content_type: string,
	content_length: int,
	connection: string,
	accept_ranges: string
}

parse_first_line_of_request :: proc(request_line: []u8) -> (string, string) {
	line_split_by_space := bytes.split(request_line, []u8{32})
	method := transmute(string)line_split_by_space[0]	
	path := transmute(string)line_split_by_space[1]

	return method, path
}

bytes_to_str :: proc(bytes: []u8) -> string {
	return transmute(string)bytes
}
str_to_bytes :: proc(str: string) -> []u8 {
	return transmute([]u8)str
}

parse_request :: proc (request: []u8) -> Http_Request {
	bytes_split_by_line := bytes.split(request, []u8{10})
	headers := new(map[string]string)
	method, path := parse_first_line_of_request(bytes_split_by_line[0])
	headers["method"] = method
	headers["path"] = path
	body_idx: int
	for line, index in bytes_split_by_line[1:] {
			if (len(line) == 1 && line[0] == 13) {
				body_idx = (index + 2)
				break
			}
			line_split_by_space := bytes.split(line, []u8{32})
			headers[bytes_to_str(line_split_by_space[0])] = bytes_to_str(line_split_by_space[1])
	}
	body := bytes_to_str(bytes_split_by_line[body_idx])

	return Http_Request{headers, body}
}

parse_message :: proc(message: []u8) -> Http_Request {
	req := parse_request(message)
	return req
}

send_response :: proc(socket: net.TCP_Socket) {
	// TODO: write rules:
	//		1. check if path exists, return 200 || 404 based on value
	//		2. create cahcing for last-modified field
	//		3. other things like, Date, Connection, Content-length seem to be straighforward
	response_str := "HTTP/1.1 200 OK\nServer: nginx/1.22.1\nDate: Sat, 25 Jan 2025 20:02:07 GMT\nContent-Type: text/html\nContent-Length: 0\nLast-Modified: Sun, 19 Jan 2025 22:13:37 GMT\nConnection: keep-alive\nETag: 678d7911-479\nAccept-Ranges: bytes\n\r"
	bytes_from_str := str_to_bytes(response_str)
	net.send_tcp(socket, bytes_from_str)
}

is_end_of_message :: proc(bytes: []u8) -> bool {
	return(
		(bytes[len(bytes)-1] == 10 && bytes[len(bytes)-2] == 13)
	)
}


handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [2048]u8
	for {
		// TODO: handle case when incoming message is greater that 2048 bytes
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data")
		}
		received := buffer[:bytes_recv]
		bytes_to_str := transmute(string)received
		fmt.println(received)
		fmt.println(bytes_to_str)

		request := parse_message(received)
		send_response(sock)
		break
	}	
	net.close(sock)
}

tcp_server :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = port,
	}
	sock, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.println("Failed to listen on TCP")
		return
	}
	fmt.printfln("Listening on TCP: %s", net.endpoint_to_string(endpoint))
	for {
		cli, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			fmt.println("Failed to accept TCP connection")
		}
		thread.create_and_start_with_poly_data(cli, handle_msg)
	}
	net.close(sock)
	fmt.println("Closed socket")
}

create_http_server :: proc(ip: string, port: int) {
	tcp_server(ip, port)
}
