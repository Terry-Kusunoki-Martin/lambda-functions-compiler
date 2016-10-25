
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
  sub esp, 24
  mov eax, 2
  push DWORD eax
  call print
  pop eax
  mov [ebp-4], eax
  mov eax, [ebp-4]
  push DWORD eax
  call print
  pop eax
  mov [ebp-8], eax
  mov eax, 4
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, 4
  add eax, [ebp-8]
  jo near overflow_check
  mov [ebp-12], eax
  mov eax, [ebp-12]
  push DWORD eax
  call print
  pop eax
  mov [ebp-16], eax
  mov eax, 10
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-16]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, 10
  add eax, [ebp-16]
  jo near overflow_check
  mov [ebp-20], eax
  mov eax, [ebp-20]
  push DWORD eax
  call print
  pop eax
  mov [ebp-24], eax
  mov eax, [ebp-24]
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
