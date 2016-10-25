
section .text
extern print
extern error
global our_code_starts_here
our_code_starts_here:
  mov esi, [esp+4]
  add esi, 8
  and esi, 0xFFFFFFF8
  push ebp
  mov ebp, esp
  sub esp, 8
  mov eax, 0xFFFFFFFF
  mov [ebp-4], eax
  mov eax, [ebp-4]
  push DWORD eax
  call print
  pop eax
  mov [ebp-8], eax
  mov eax, [ebp-8]
  cmp eax, 0xFFFFFFFF
  je near temp_then_1
  cmp eax, 0x7FFFFFFF
  je near temp_else_2
  jmp near error_non_bool
temp_then_1:
  mov eax, 10
  push DWORD eax
  call print
  pop eax
  jmp near temp_end_3
temp_else_2:
  mov eax, 10
temp_end_3:
  mov esp, ebp
  pop ebp
  ret
overflow_check:
  push DWORD 3
  call error
error_non_int:
  push DWORD 1
  call error
error_non_bool:
  push DWORD 2
  call error
error_non_pair:
  push DWORD 4
  call error
error_out_of_bounds:
  push DWORD 5
  call error
error_non_lam:
  push DWORD 6
  call error
error_arity:
  push DWORD 7
  call error
