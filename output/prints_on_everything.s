
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
  sub esp, 48
  mov eax, 10
  push DWORD eax
  call print
  pop eax
  mov [ebp-4], eax
  mov eax, 12
  push DWORD eax
  call print
  pop eax
  mov [ebp-8], eax
  mov eax, [ebp-4]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-4]
  sub eax, [ebp-8]
  jo near overflow_check
  mov [ebp-12], eax
  mov eax, [ebp-12]
  push DWORD eax
  call print
  pop eax
  mov [ebp-16], eax
  mov eax, 6
  push DWORD eax
  call print
  pop eax
  mov [ebp-20], eax
  mov eax, 24
  push DWORD eax
  call print
  pop eax
  mov [ebp-24], eax
  mov eax, [ebp-20]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-24]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-20]
  shr eax, 1
  imul eax, [ebp-24]
  jo near overflow_check
  mov [ebp-28], eax
  mov eax, [ebp-28]
  push DWORD eax
  call print
  pop eax
  mov [ebp-32], eax
  mov eax, [ebp-16]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-32]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-16]
  add eax, [ebp-32]
  jo near overflow_check
  mov [ebp-36], eax
  mov eax, [ebp-36]
  push DWORD eax
  call print
  pop eax
  mov [ebp-40], eax
  mov eax, [ebp-40]
  cmp eax, 70
  mov eax, 0x7FFFFFFF
  jne near temp_equals_1
  mov eax, 0xFFFFFFFF
temp_equals_1:
  mov [ebp-44], eax
  mov eax, [ebp-44]
  xor eax, 4294967288
  or eax, 4294967288
  cmp eax, 4294967295
  je near temp_is_bool_end_2
  mov eax, 0x7FFFFFFF
temp_is_bool_end_2:
  mov [ebp-48], eax
  mov eax, [ebp-48]
  push DWORD eax
  call print
  pop eax
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
