package http

import "core:fmt"
import "core:net"
import "core:thread"
import "core:os/os2"
import "core:os"
import "core:mem"
import "core:strings"
import "core:log"

URL :: struct {
	scheme: string,
	url: string,
	host: string,
	path: string,
	port: string,
	view_source: bool,
}

Content_Type :: enum {
	text_html,
	application_json
}

Headers :: struct {
	Content_Length: int,
	Content_Type: Content_Type
}

handle_msg :: proc(sock: net.TCP_Socket, request: []u8) {
	buffer: [2048]u8
	fmt.println("in thread to handle message")
	bytes_recv, err_recv := net.send_tcp(sock, request[:])
	fmt.println("send bytes", bytes_recv)
	net.close(sock)
}

open_file :: proc(path: string) {
	file, file_err := os2.read_entire_file_from_path(path, context.temp_allocator)
	if file_err != nil {
		fmt.println("Opening File Error", file_err)
	}
	file_string := transmute(string)file
	fmt.printfln("File request at path %s\nContent: %s",path ,file_string)
}

parse_response_headers :: proc(headers: []u8)  {
}

request_webpage :: proc(url: URL) {
	hostname_and_port := fmt.tprintf("%s:%s", url.host, url.port)

	socket, err_dial := net.dial_tcp_from_hostname_and_port_string(hostname_and_port)
	if err_dial != nil {
		fmt.eprintln("error: could not dial", err_dial)
		os.exit(1)
	}

	request := fmt.tprintf("GET {} HTTP/1.1\r\nHost: {}\r\nConnection: close\r\nUser-Agent: OdinHttpClient\r\nAccept: */*\r\n\r\n",url.path, url.host)
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

	msg := string(bytes_buff[:bytes_recv])
	// headers := parse_response_headers(bytes_buff[:])
	defer net.close(socket)
	fmt.println("Response Recieved:")
	if url.view_source {
		fmt.println(msg)
	} else {
		render_html(msg)
	}
}

append_strings :: proc(string1, string2: string) -> string {
	sb := strings.builder_make()
	strings.write_string(&sb, string1)
	strings.write_string(&sb, string2)
	the_string :=strings.to_string(sb)
	return the_string
}

render_html :: proc(http_response:string) {
	
	// remove headers
	http_response_lines_splitted, _ := strings.split_n(http_response, "<", 2)

	html := append_strings("<", http_response_lines_splitted[1])
	//remove body and html tags
	body_open_tag_removed, _ := strings.replace_all(html, "<body>", "")
	body_close_tag_removed, _ := strings.replace_all(body_open_tag_removed, "</body>", "")
	html_open_tag_removed, _ := strings.replace_all(body_close_tag_removed, "<html>", "")
	html_close_tag_removed, _ := strings.replace_all(html_open_tag_removed, "</html>", "")

	div_open_tag_removed, _ := strings.replace_all(html_close_tag_removed, "<div>", "")
	div_close_tag_removed, _ := strings.replace_all(div_open_tag_removed, "</div>", "")
	span_open_tag_removed, _ := strings.replace_all(div_close_tag_removed, "<span>", "")
	span_close_tag_removed, _ := strings.replace_all(span_open_tag_removed, "</span>", "")

	//entities support (&lt; == <) (&gt; == >)
	// process entities
	less_thans_replaced, _ := strings.replace_all(span_close_tag_removed, "&lt;", "<")
	greater_thans_replaced, _ := strings.replace_all(less_thans_replaced, "&gt;", ">")
	fmt.println(strings.trim_space(greater_thans_replaced))
}

browser_split_url :: proc(target_url_array: []string) -> (url_obj: URL) {
	target_url := target_url_array[0]
	fmt.println(target_url)
	target_scheme := target_url[0:4]
	switch target_scheme {
		case "file":
			path := target_url[7:]
			url_obj = URL{
			scheme="file",
			path=path,
		}
		case "http":
		 scheme, host, path, _, _ := net.split_url(target_url)
		 url_obj = URL{
			scheme="http",
			url=target_url,
			host=host,
			path=path,
		}
		case "data":
			data_string_joined := strings.join(target_url_array[:], " ")
			data_string_split := strings.split(data_string_joined, ",")
			url_obj = URL {
				scheme = "data",
				path=data_string_split[1]
			}
		case "view":
			scheme, host, path, _, _ := net.split_url(target_url[12:])
			 url_obj = URL{
				scheme="http",
				url=target_url[12:],
				host=host,
				path=path,
				view_source=true
			}

	}
	return
}

main :: proc() {
	args := os.args
	address := args[1]
	port := args[2]
	context.logger = log.create_console_logger()

	log.info("Program started")

	// Rest of program goes here,
	// it will use context.logger whenever
	// you run `log.info`, `log.error` etc.

	//TODO: convert URL into union so that I can create a new type/enum union thing per scheme
	//TODO: figure out why subsequent html requests to same resource dont return content in them, but in curl it does?
	//TODO: Connection keep-alive 1.6 exercise
	url_obj := browser_split_url(args[1:])
	fmt.println("Browser hacking!\n ", url_obj)	
	switch url_obj.scheme {
	case "file":
		fmt.println("Processing File")
		open_file(url_obj.path)
	case "http":
		fmt.println("Processing Request")
		url_obj.port = port
		request_webpage(url_obj)
	case "data":		
		fmt.println("Processing Data")
		fmt.println(url_obj.path)
	}
	log.destroy_console_logger(context.logger)
}