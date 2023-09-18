package gc

import "core:fmt"
import "core:mem"

MAP_FAILED :: rawptr(~uintptr(0))

word :: rawptr

Block :: struct {
	size: int,
	used: bool,
	next: ^Block,
	data: word,
}

heapStart: ^Block = nil
top: ^Block = heapStart

align :: proc(n: int) -> int {
	return (n + size_of(word) - 1) & ~int(size_of(word) - 1)
}

allocSize :: proc(size: int) -> int {
	return size + size_of(Block) - size_of(word)
}

requestFromOs :: proc(size: int) -> (b: []byte, err: mem.Allocator_Error) {
	ptr := mem.alloc_bytes(int(allocSize(size))) or_return
	return ptr, nil
}

firstFit :: proc(size: int) -> ^Block {
	block := heapStart

	for block != nil {
		// O(n) search.
		fmt.println("searching...\ncurrent:", block)
		if block.used || block.size < size {
			fmt.println("get next block")
			block = block.next
			continue
		}

		fmt.println("unused and correct size")
		// Found the block:
		return block
	}

	return nil
}

findBlock :: proc(size: int) -> ^Block {
	return firstFit(size)
}

alloc :: proc(size: int) -> (data: ^Block, err: mem.Allocator_Error) {
	total_size := align(size)

	data = findBlock(size);if data != nil {
		return
	}

	bytes := requestFromOs(total_size) or_return
	data = (^Block)(raw_data(bytes))

	data.size = size
	data.used = true

	// Init heap.
	if (heapStart == nil) {
		heapStart = data
	}

	// Chain the blocks.
	if (top != nil) {
		top.next = data
	}

	top = data

	return
}

free :: proc(data: ^Block) {
	data.used = false
}

main :: proc() {
	fmt.println("BEFORE BLOCK")
	block1, _ := alloc(3)
	block2, _ := alloc(4)
	block3, _ := alloc(5)
	fmt.println("BLOCK", block1.size == 3)
	fmt.println("BLOCK", block2.size == 4)
	fmt.println("BLOCK", block3.size == 5)
	free(block2)
	fmt.println("BLOCK", block2.used == false)
	block4, _ := alloc(9)
	fmt.println("BLOCK", block4.size == 9)
	fmt.println("BLOCK", block2^)
	fmt.println("BLOCK", block4^)

}
