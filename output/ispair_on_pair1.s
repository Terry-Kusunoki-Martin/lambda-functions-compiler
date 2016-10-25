
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
  sub esp, 4
  mov eax, 8
  mov [esi+0], eax
  mov eax, 10
  mov [esi+4], eax
  mov eax, esi
  add esi, 8
  add eax, 1
  mov [ebp-4], eax
  mov eax, [ebp-4]
  xor eax, 4294967286
  or eax, 4294967288
  cmp eax, 4294967295
  je near temp_is_pair_end_1
  mov eax, 0x7FFFFFFF
temp_is_pair_end_1:
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
