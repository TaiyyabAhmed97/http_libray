package utils

import "core:os"

exit :: proc(code: int) {
	os.exit(code)
}