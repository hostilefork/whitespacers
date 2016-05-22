// Whitespace Interpreter v1.0 - by meth0dz
// License - http://creativecommons.org/licenses/by-sa/3.0/us/
// Source: http://www.rohitab.com/discuss/index.php?showtopic=35639
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#define STACK_MEMBERS 			1024
#define HEAP_MEMBERS 			1024
#define MAX_LABELS 			200
#define MAX_LABEL_LENGTH 		500
#define MAX_INSTRUCTIONS 		24
#define MAX_INSTRUCTION_LENGTH 	        5
#define MAX_NESTED_SUBROUTINES	        20

/* Notes
	This entire code depends heavily on the ASCII character set
	I am aware that I could have incremented instruction_index in the step through function, however it makes more sense to me to do it
		in the actual instruction.
	MAX_LABEL_LENGTH also applies to maximum length for a number (in bits or whitespace characters)
	The plan was to use dynamic memory allocation throughout the entire project, but I ran into a couple sections where I kept getting mem bugs that I couldn't fix,
		so I had to switch to static allocation in those areas
*/

struct stack_model {
	long size;
	long current;
	long long* contents;
} stack;

struct heap_model {
	long long* address;
	long long* value;
	long elements;
} heap;

struct label_model {
	char** label_id;
	int* label_location;
	int total_labels;
} label_table;

struct instruction_model {
	char** unique_id;
	void (**instruction_function)(char * parameter, int size);
	int* instruction_size;
} instruction_set;

// This is really just going to be a stack
long long instruction_index[MAX_NESTED_SUBROUTINES];
long long current_instruction_index;

// All the background/foundation functions
long read_source_file(char* path, char** buffer);
void remove_comments(char* buffer);
bool create_stack(void);
bool stack_push(long long val);
long long stack_pop(void);
long long stack_peak(int depth);
void cleanup_stack(void);
bool create_heap(void);
long long heap_get(long long addr);
bool heap_put(long long val, long long addr);
void cleanup_heap(void);
bool create_label_table(void);
void cleanup_label_table(void);
bool create_instruction_set(void);
void cleanup_instruction_set(void);
bool locate_jump_labels(char * source);
long long convert_ws_to_number(char * ws);
int retrieve_label_or_number(char* data, char** ret);
bool add_ret_addr(long long addr);
long long get_last_ret_addr(void);
void step_through_program(char * source);

// All the functions representing actual whitespace instructions
void ws_stack_push(char* parameter, int size);
void ws_stack_dup(char* parameter, int size);
void ws_stack_copy(char* parameter, int size);
void ws_stack_swap(char* parameter, int size);
void ws_stack_discard(char* parameter, int size);
void ws_stack_slide(char* parameter, int size);
void ws_math_add(char* parameter, int size);
void ws_math_sub(char* parameter, int size);
void ws_math_mult(char* parameter, int size);
void ws_math_div(char* parameter, int size);
void ws_math_mod(char* parameter, int size);
void ws_heap_store(char* parameter, int size);
void ws_heap_retrieve(char* parameter, int size);
void ws_flow_mark(char* parameter, int size);
void ws_flow_call(char* parameter, int size);
void ws_flow_jump(char* parameter, int size);
void ws_flow_jz(char* parameter, int size);
void ws_flow_jn(char* parameter, int size);
void ws_flow_ret(char* parameter, int size);
void ws_flow_exit(char* parameter, int size);
void ws_io_outc(char* parameter, int size);
void ws_io_outn(char* parameter, int size);
void ws_io_inc(char* parameter, int size);
void ws_io_inn(char* parameter, int size);

int main(int argc, char** argv)
{
	char* p, * source;
	if (argc == 2) {
		if (read_source_file(argv[1], &source)) {
			remove_comments(source);
			if (create_stack()) {
				if (create_heap()) {
					if (create_label_table()) {
						if (create_instruction_set()) {
							if (locate_jump_labels(source)) {
								step_through_program(source);

								free (source);
								cleanup_stack();
								cleanup_heap();
								cleanup_label_table();
								cleanup_instruction_set();
								return 0;
							}
							cleanup_instruction_set();
						}
						cleanup_label_table();
					}
					cleanup_heap();
				}
				cleanup_stack();
			}
		}
	}
	else
		printf("Proper Usage: %s file.ws\n", argv[0]);
	return 1;
}

// Note that if this function succeeds, it will allocate memory for buffer
long read_source_file(char* path, char** buffer)
{
	FILE * file;
	long size;
	if (file = fopen(path, "r")) {
		if (!fseek(file, 0, SEEK_END)) {
			if ((size = ftell(file)) != -1L) {
				rewind(file);
				if (*buffer = calloc(size+1, sizeof(char))) {
					if (fread(*buffer, sizeof(char), size + 1, file)) {
						fclose(file);
						return size;
					}
					free (*buffer);
				}
			}
		}
		fclose(file);
	}
	return 0;
}

void remove_comments(char* buffer)
{
	int j = 0;
	for (int i = 0; buffer[i]; i++) {
		if (buffer[i] != '\x09' && buffer[i] != '\x0A' && buffer[i] != '\x20') {
			memmove(&(buffer[i]), &(buffer[i+1]), strlen(&(buffer[i+1])));
			i--;
			j++;
		}
	}
	buffer[strlen(buffer) - j] = 0;
	return;
}

bool create_stack(void)
{
	if (stack.contents = (long long*)calloc(STACK_MEMBERS, sizeof(long long))) {
		stack.size = STACK_MEMBERS;
		stack.current = STACK_MEMBERS;
		return true;
	} 
	return false;
}

bool stack_push(long long val)
{
	if (stack.current >= 1) {
		stack.current--;
		stack.contents[stack.current] = val;
		return true;
	}
	return false;
}

long long stack_pop(void)
{
	if (stack.current < stack.size) {
		stack.current++;
		return stack.contents[stack.current - 1];
	}
	return 0;
}

long long stack_peak(int depth)
{
	if ((stack.current + depth) < stack.size) {
		return stack.contents[stack.current + depth];
	}
	return 0;
}

void cleanup_stack(void)
{
	free (stack.contents);
	return;
}

bool create_heap(void)
{
	if (heap.address = (long long*)calloc(HEAP_MEMBERS, sizeof(long long))) {
		if (heap.value = (long long*)calloc(HEAP_MEMBERS, sizeof(long long))) {
			heap.elements = 0;
			return true;
		}
		free (heap.address);
	}
	return false;
}

bool heap_put(long long val, long long addr)
{
	// First see if the address is already in use
	for (int i = 0; i < heap.elements; i++) {
		if (heap.address[i] == addr) {
			heap.value[i] = val;
			return true;
		}
	}
	
	// If not, then it needs to be added if there is room left
	if (heap.elements < HEAP_MEMBERS) {
		int i = heap.elements;
		heap.address[i] = addr;
		heap.value[i] = val;
		heap.elements++;
		return true;
	}
	
	return false;
}

// Trying to get data from an address that doesn't exist results in 0 being returned
long long heap_get(long long addr)
{
	for (int i = 0; i < HEAP_MEMBERS; i++) {
		if (heap.address[i] == addr) return heap.value[i];
	}
	return 0;
}

void cleanup_heap(void)
{
	free (heap.address);
	free (heap.value);
	return;
}

bool create_label_table(void)
{
	if (label_table.label_id = (char**)calloc(MAX_LABELS, sizeof(char*))) {
		if (label_table.label_location = (int*)calloc(MAX_LABELS, sizeof(int))) {
			return true;
		}
		free (label_table.label_id);
	}
	return false;
}

void cleanup_label_table(void)
{
	for (int i = 0; i < MAX_LABELS && label_table.label_location[i]; i++)
		free (label_table.label_id[i]);
	free (label_table.label_id);
	free (label_table.label_location);
	return;
}


// Memory Management gets a bit annoyingly comlicated here
// But I would prefer to leave everything to be dynamically allocated
bool create_instruction_set(void)
{
	instruction_set.unique_id = calloc(MAX_INSTRUCTIONS, sizeof(char*));
	instruction_set.instruction_size = calloc(MAX_INSTRUCTIONS, sizeof(int));
	instruction_set.instruction_function = calloc(MAX_INSTRUCTIONS, sizeof(void(*)(char *, int)));
	// Here we put all of the instruction ids and functions

	// Stack Manipulation - [SPACE]
	instruction_set.unique_id[0] = "\x20\x20";
	instruction_set.instruction_function[0] = &ws_stack_push;
	instruction_set.instruction_size[0] = 2;

	instruction_set.unique_id[1] = "\x20\x0A\x20";
	instruction_set.instruction_function[1] = &ws_stack_dup;
	instruction_set.instruction_size[1] = 3;

	instruction_set.unique_id[2] = "\x20\x09\x20";
	instruction_set.instruction_function[2] = &ws_stack_copy;
	instruction_set.instruction_size[2] = 3;

	instruction_set.unique_id[3] = "\x20\x0A\x09";
	instruction_set.instruction_function[3] = &ws_stack_swap;
	instruction_set.instruction_size[3] = 3;

	instruction_set.unique_id[4] = "\x20\x0A\x0A";
	instruction_set.instruction_function[4] = &ws_stack_discard;
	instruction_set.instruction_size[4] = 3;

	instruction_set.unique_id[5] = "\x20\x09\x0A";
	instruction_set.instruction_function[5] = &ws_stack_slide;
	instruction_set.instruction_size[5] = 3;

	// Arithmetic - [Tab][Space]
	instruction_set.unique_id[6] = "\x09\x20\x20\x20";
	instruction_set.instruction_function[6] = &ws_math_add;
	instruction_set.instruction_size[6] = 4;

	instruction_set.unique_id[7] = "\x09\x20\x20\x09";
	instruction_set.instruction_function[7] = &ws_math_sub;
	instruction_set.instruction_size[7] = 4;

	instruction_set.unique_id[8] = "\x09\x20\x20\x0A";
	instruction_set.instruction_function[8] = &ws_math_mult;
	instruction_set.instruction_size[8] = 4;

	instruction_set.unique_id[9] = "\x09\x20\x09\x20";
	instruction_set.instruction_function[9] = &ws_math_div;
	instruction_set.instruction_size[9] = 4;

	instruction_set.unique_id[10] = "\x09\x20\x09\x09";
	instruction_set.instruction_function[10] = &ws_math_mod;
	instruction_set.instruction_size[10] = 4;

	// Heap access - [Tab][Tab]
	instruction_set.unique_id[11] = "\x09\x09\x20";
	instruction_set.instruction_function[11] = &ws_heap_store;
	instruction_set.instruction_size[11] = 3;

	instruction_set.unique_id[12] = "\x09\x09\x09";
	instruction_set.instruction_function[12] = &ws_heap_retrieve;
	instruction_set.instruction_size[12] = 3;

	// Flow Control - [LF]
	instruction_set.unique_id[13] = "\x0A\x20\x20";
	instruction_set.instruction_function[13] = &ws_flow_mark;
	instruction_set.instruction_size[13] = 3;

	instruction_set.unique_id[14] = "\x0A\x20\x09";
	instruction_set.instruction_function[14] = &ws_flow_call;
	instruction_set.instruction_size[14] = 3;

	instruction_set.unique_id[15] = "\x0A\x20\x0A";
	instruction_set.instruction_function[15] = &ws_flow_jump;
	instruction_set.instruction_size[15] = 3;

	instruction_set.unique_id[16] = "\x0A\x09\x20";
	instruction_set.instruction_function[16] = &ws_flow_jz;
	instruction_set.instruction_size[16] = 3;

	instruction_set.unique_id[17] = "\x0A\x09\x09";
	instruction_set.instruction_function[17] = &ws_flow_jn;
	instruction_set.instruction_size[17] = 3;

	instruction_set.unique_id[18] = "\x0A\x09\x0A";
	instruction_set.instruction_function[18] = &ws_flow_ret;
	instruction_set.instruction_size[18] = 3;

	instruction_set.unique_id[19] = "\x0A\x0A\x0A";
	instruction_set.instruction_function[19] = &ws_flow_exit;
	instruction_set.instruction_size[19] = 3;

	// Input/Output - [Tab][LF]
	instruction_set.unique_id[20] = "\x09\x0A\x20\x20";
	instruction_set.instruction_function[20] = &ws_io_outc;
	instruction_set.instruction_size[20] = 4;

	instruction_set.unique_id[21] = "\x09\x0A\x20\x09";
	instruction_set.instruction_function[21] = &ws_io_outn;
	instruction_set.instruction_size[21] = 4;

	instruction_set.unique_id[22] = "\x09\x0A\x09\x20";
	instruction_set.instruction_function[22] = &ws_io_inc;
	instruction_set.instruction_size[22] = 4;

	instruction_set.unique_id[23] = "\x09\x0A\x09\x09";
	instruction_set.instruction_function[23] = &ws_io_inn;
	instruction_set.instruction_size[23] = 4;
	return true;
}

void cleanup_instruction_set(void)
{
	free (instruction_set.instruction_function);
	free (instruction_set.unique_id);
	free (instruction_set.instruction_size);
	return;
}

/*
	How to find labels.
	1) A label is marked by [LF][SPACE][SPACE]
	2) The character before the label can't be a [TAB]
	3) Make sure you haven't found the representation of a label in a label
*/
bool locate_jump_labels(char* source)
{
	int label_index = 0, j, leap;
	char* label_marker = "\x0A\x20\x20", * temp;
	for (int i = 0; source[i]; i++) {
		if (!strncmp(&(source[i]), label_marker, 3) && (source[i-1] != '\x09')) {
			if (label_table.label_id[label_index] = (char*)calloc(MAX_LABEL_LENGTH, sizeof(char))) {
				// Would look better if it used retrieve_label_or_number,
				// but I'm having a hell of a time getting it to work
				i += 3; // This gets us to the actual label
				for (j = 0; source[i + j] != '\x0A'; j++) label_table.label_id[label_index][j] = source[i + j];
				i += j;
				label_table.label_location[label_index] = i + 1; // The 1 puts it past the final \x0A
				label_index++;
				continue;
				
			}
			// If memory allocation breaks, then we need to report an error
			return false;
		}
	}
	label_table.total_labels = label_index;
	return true;
}

bool add_ret_addr(long long addr)
{
	int i;
	for (i = 0; i < MAX_NESTED_SUBROUTINES && instruction_index[i]; i++);
	if (i < MAX_NESTED_SUBROUTINES) {
		instruction_index[i] = addr;
		return true;
	}
	else 
		return false;
}

long long get_last_ret_addr(void)
{
	int i;
	long long temp;
	for (i = MAX_NESTED_SUBROUTINES - 1; !instruction_index[i] && i; i--);
	temp = instruction_index[i];
	instruction_index[i] = 0;
	return temp;
}

void step_through_program(char* source)
{
	int i;
	while (current_instruction_index != -1 && source[current_instruction_index]) {
		for (i = 0; i < MAX_INSTRUCTIONS; i++) {
			if (!strncmp(&(source[current_instruction_index]), instruction_set.unique_id[i], instruction_set.instruction_size[i])) {
				instruction_set.instruction_function[i](&(source[current_instruction_index]), instruction_set.instruction_size[i]);
				break;
			}
		}
		if (i == MAX_INSTRUCTIONS) {
			current_instruction_index++;
			getchar();
		}
	}
	return;
}

// [SPACE] = bin(0), [TAB] = bin(1)
// First 'space' represents signage, [SPACE] = positive, [TAB] = negative
long long convert_ws_to_number(char* ws)
{
	long long amt = 0;
	if (ws) {
		int len = strlen(ws) - 1;
		for (int i = 0; len > 0; len--, i++) {
			if (ws[len] == '\x09') amt += (1 << i);
		}
		if (ws[0] == '\x09') amt = -amt;
	}
	return amt;
}

// This function returns the length of ret, which is the label or number
int retrieve_label_or_number(char* data, char** ret)
{
	char* loc;
	if (*ret = (char*)calloc(MAX_LABEL_LENGTH + 1, sizeof(char))) {
		strncpy(*ret, data, MAX_LABEL_LENGTH);
		if (loc = strchr(*ret, '\x0A')) {
			*loc = 0;
			return strlen(*ret);
		}
		free (*ret);
	}
	
	return 0;
}


void ws_stack_push(char* parameter, int size)
{
	char* label_number = NULL;
	int leap = 0;
	if (leap = retrieve_label_or_number(&(parameter[size]), &label_number)) {
		stack_push(convert_ws_to_number(label_number));
		current_instruction_index += size + leap + 1;
		free (label_number);
	}
	return;
}

void ws_stack_dup(char* parameter, int size)
{
	stack_push(stack_peak(0));
	current_instruction_index += size;
	return;
}

void ws_stack_copy(char* parameter, int size)
{
	char* label_number = NULL;
	int leap = 0;
	if (leap = retrieve_label_or_number(&(parameter[size]), &label_number)) {
		stack_push(stack_peak(convert_ws_to_number(label_number)));
		current_instruction_index += size + leap + 1;
		free (label_number);
	}
	else
		current_instruction_index += size;
	return;
}

void ws_stack_swap(char* parameter, int size)
{
	long long first_off = stack_pop();
	long long second_off = stack_pop();
	stack_push(first_off);
	stack_push(second_off);
	current_instruction_index += size;
	return;
}

void ws_stack_discard(char* parameter, int size)
{
	stack_pop();
	current_instruction_index += size;
	return;
}

void ws_stack_slide(char* parameter, int size)
{
	long long first = stack_pop();
	int leap = 0;
	char* label_number = NULL;
	if (leap = retrieve_label_or_number(&(parameter[size]), &label_number)) {
		for (int slide_amt = convert_ws_to_number(label_number); slide_amt > 0; slide_amt--)
			stack_pop();
		stack_push(first);
		current_instruction_index += size + leap + 1;
		free (label_number);
	}
	else
		current_instruction_index += size;
	return;
}

void ws_math_add(char* parameter, int size)
{
	long long right = stack_pop();
	long long left = stack_pop();
	stack_push(left + right);
	current_instruction_index += size;
	return;
}

void ws_math_sub(char* parameter, int size)
{
	long long right = stack_pop();
	long long left = stack_pop();
	stack_push(left - right);
	current_instruction_index += size;
	return;
}

void ws_math_mult(char* parameter, int size)
{
	long long right = stack_pop();
	long long left = stack_pop();
	stack_push(left * right);
	current_instruction_index += size;
	return;
}

void ws_math_div(char* parameter, int size)
{
	long long right = stack_pop();
	long long left = stack_pop();
	stack_push(left / right);
	current_instruction_index += size;
	return;
}

void ws_math_mod(char* parameter, int size)
{
	long long right = stack_pop();
	long long left = stack_pop();
	stack_push(left % right);
	current_instruction_index += size;
	return;
}

void ws_heap_store(char* parameter, int size)
{
	long long value = stack_pop();
	long long addr = stack_pop();
	heap_put(value, addr);
	current_instruction_index += size;
	return;
}

void ws_heap_retrieve(char* parameter, int size)
{
	stack_push(heap_get(stack_pop()));
	current_instruction_index += size;
	return;
}

void ws_flow_mark(char* parameter, int size)
{
	// For loop will stop once it gets to the second line feed
	// Therefore we need one more increment after the fact
	int i;
	for (i = 1; parameter[i] != '\x0A'; i++);
	current_instruction_index += i + 1;
	return;
}

void ws_flow_call(char* parameter, int size)
{
	char* label;
	int leap = 0;
	if (leap = retrieve_label_or_number(&(parameter[size]), &label)) {
		if (add_ret_addr(current_instruction_index + size + leap + 1)) {
			ws_flow_jump(parameter, size);
		}
		free (label);
	}
	else {
		// This is a very bad place
		add_ret_addr(current_instruction_index + size);
	}
	return;
}

void ws_flow_jump(char* parameter, int size)
{
	char* label_number;
	int i;
	if (retrieve_label_or_number(&(parameter[size]), &label_number)) {
		for (i = 0; i < label_table.total_labels; i++) {
			if (!strcmp(label_table.label_id[i], label_number)) {
				current_instruction_index = label_table.label_location[i];
				break;
			}
		}
		free (label_number);
	}
	else {
		// This would be very bad
		current_instruction_index += size;
	}
	return;
}

void ws_flow_jz(char* parameter, int size)
{
	int leap;
	char * label;
	if (stack_pop() == 0LL) {
		ws_flow_jump(parameter, size);
	}
	else {
		if (leap = retrieve_label_or_number(&(parameter[size]), &label)) {
			current_instruction_index += size + leap + 1;
			free (label);
		}
		else 
			current_instruction_index += size;
	}
	return;
}

void ws_flow_jn(char* parameter, int size)
{
	int leap;
	char * label;
	if (stack_pop() < 0LL) {
		ws_flow_jump(parameter, size);
	}
	else {
		if (leap = retrieve_label_or_number(&(parameter[size]), &label)) {
			current_instruction_index += size + leap + 1;
			free (label);
		}
		else 
			current_instruction_index += size;
	}
	return;
}

void ws_flow_ret(char* parameter, int size)
{
	current_instruction_index = get_last_ret_addr();
	return;
}

void ws_flow_exit(char* parameter, int size)
{
	current_instruction_index = -1;
	return;
}

void ws_io_outc(char* parameter, int size)
{
	putchar((int)stack_pop());
	current_instruction_index += size;
	return;
}

void ws_io_outn(char* parameter, int size)
{
	printf("%lld", stack_pop());
	fflush(stdout);
	current_instruction_index += size;
	return;
}

void ws_io_inc(char* parameter, int size)
{
	int c = getchar();
	heap_put((long long)c, stack_pop());
	current_instruction_index += size;
	return;
}

void ws_io_inn(char* parameter, int size)
{
	char s[19], * e;
	scanf("%18s", s);
	heap_put(strtoll(s, &e, 10), stack_pop());
	current_instruction_index += size;
	return;
	
}
