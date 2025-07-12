package http

import "core:fmt"
import "core:net"
import "core:thread"
import "core:os/os2"
import "core:os"
import "core:mem"

URL :: struct {
	scheme: string,
	url: string,
	host: string,
	path: string,
	port: string
}

handle_msg :: proc(sock: net.TCP_Socket, request: []u8) {
	buffer: [2048]u8
	fmt.println("in thread to handle message")
	bytes_recv, err_recv := net.send_tcp(sock, request[:])
	fmt.println("send bytes", bytes_recv)
	net.close(sock)
}

open_file :: proc(path: string) {
	fmt.println("opening file?")
	file, file_err := os2.read_entire_file_from_path(path, context.temp_allocator)
	if file_err != nil {
		fmt.println("Opening File Error", file_err)
	}
	file_string := transmute(string)file
	fmt.printfln("File request at path %s\nContent: %s",path ,file_string)
}

request_webpage :: proc(url: URL) {
	hostname_and_port := fmt.tprintf("%s:%s", url.host, url.port)
	fmt.println("hostname_and_port: ", hostname_and_port)

	socket, err_dial := net.dial_tcp_from_hostname_and_port_string(hostname_and_port)
	if err_dial != nil {
		fmt.eprintln("error: could not dial", err_dial)
		os.exit(1)
	}
	defer net.close(socket)

	request := fmt.tprintf("GET {} HTTP/1.0\r\nHost: {}\r\nConnection: keep-alive\r\nCache-Control: no-cache, no-store, max-age=0, must-revalidate\r\n\r\n",url.path, url.host)
	fmt.printf("Sending Request: \n%s", request)
	bytes := transmute([]u8)request

	send_bytes, err_send := net.send_tcp(socket, bytes[:])
	if err_send != nil{
		fmt.println("failed to send on tcp", err_send)
		os.exit(1)
	}

	bytes_buff: [32 * mem.Kilobyte]byte
	bytes_recv, err_recv := net.recv_tcp(socket, bytes_buff[:])
	if err_recv != nil {
		fmt.eprintln("error: failed during recv from with error", err_recv)
		os.exit(1)
	}

	msg := bytes_buff[:bytes_recv]
	fmt.println("Response Recieved: ")
	fmt.print(transmute(string)msg)
}



main :: proc() {
	args := os.args
	if len(args) != 3 {
		fmt.println("Usage: ", args[0], "<address> <port>")
		os.exit(1)
	}

	address := args[1]
	port := args[2]
	scheme, host, path, _, _ := net.split_url(address)
	my_url_obj : URL;
	fmt.println("Browser hacking!\n ", my_url_obj)	
	switch scheme {
	case "file":
		my_url_obj = URL{
			scheme=scheme,
			path=host,
			port="",
			url=""
		}
		fmt.println(my_url_obj)
		open_file(my_url_obj.path)
	case "http":
		my_url_obj = URL{
			scheme=scheme,
			url=address,
			host=host,
			path=path,
			port=port
		}
		request_webpage(my_url_obj)
	}
		
	
}

