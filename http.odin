package http

import "core:fmt"
import "core:net"
import "core:thread"
import "core:bytes"
import "core:strings"

Http_Request :: struct {
	method: string,
	path: string,
	host: string,
	user_agent: string,
	accept: string
}

Http_Request :: struct {
	headers: map[string]string,
	body: string
}

parse_request :: proc (request: []u8) -> Http_Request {
	bytes_split_by_line := bytes.split(request, []u8{10})
	first_line_split_by_space := bytes.split(bytes_split_by_line[0], []u8{32})
	method := transmute(string)first_line_split_by_space[0]	
	path := transmute(string)first_line_split_by_space[1]	
	
	second_line_split_by_space := bytes.split(bytes_split_by_line[1], []u8{32})
	host := transmute(string)second_line_split_by_space[1]

	third_line_split_by_space := bytes.split(bytes_split_by_line[2], []u8{32})
	user_agent := transmute(string)third_line_split_by_space[1]

	fourth_line_split_by_space := bytes.split(bytes_split_by_line[3], []u8{32})
	accept := transmute(string)fourth_line_split_by_space[1]

	return Http_Request{method, path, host, user_agent, accept}
}

parse_message :: proc(message: []u8) {
	req := parse_request(message)
	using req
	fmt.printfln(" method: %s\n path: %s\n host: %s\n user_agent: %s\n accept: %s", method, path, host, user_agent, accept)
}

is_end_of_message :: proc(bytes: []u8) -> bool {
	return(
		(bytes[len(bytes)-1] == 10 && bytes[len(bytes)-2] == 13)
	)
}


handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [2048]u8
	for {
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data")
		}
		received := buffer[:bytes_recv]
		bytes_to_str := transmute(string)received
		fmt.println(len(received))
		fmt.println(received)
		fmt.println(bytes_to_str)
		fmt.println(received[len(received)-1])
		if is_end_of_message(received) {
			parse_message(received)
			// send_reply()
			fmt.println("Disconnecting client")
			break
		}
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
