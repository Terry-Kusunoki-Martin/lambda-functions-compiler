
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
  sub esp, 16
  mov eax, 112
  mov [esi+0], eax
  mov eax, 54
  mov [esi+4], eax
  mov eax, esi
  add esi, 8
  add eax, 1
  mov [ebp-4], eax
  mov eax, 200
  mov [esi+0], eax
  mov eax, 1086
  mov [esi+4], eax
  mov eax, esi
  add esi, 8
  add eax, 1
  mov [ebp-8], eax
  mov eax, [ebp-4]
  mov [esi+0], eax
  mov eax, [ebp-8]
  mov [esi+4], eax
  mov eax, esi
  add esi, 8
  add eax, 1
  mov [ebp-12], eax
  mov eax, [ebp-12]
  and eax, 7
  cmp eax, 1
  jne near error_non_pair
  mov eax, [ebp-12]
  mov eax, [eax-1]
  mov [ebp-16], eax
  mov eax, [ebp-16]
  and eax, 7
  cmp eax, 1
  jne near error_non_pair
  mov eax, [ebp-16]
  mov eax, [eax+3]
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
