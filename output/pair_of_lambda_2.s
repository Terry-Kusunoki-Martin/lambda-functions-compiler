
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
  sub esp, 32
  mov eax, 8
  mov [ebp-4], eax
  jmp near temp_after_temp_lambda_1_2
temp_lambda_1:
  push ebp
  mov ebp, esp
  sub esp, 4
  mov eax, [ebp+8]
  mov ecx, [eax+3]
  mov [ebp-8], ecx
  mov eax, [ebp+12]
  mov [ebp-12], eax
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, 6
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  add eax, 6
  jo near overflow_check
  mov esp, ebp
  pop ebp
  ret
temp_after_temp_lambda_1_2:
  mov DWORD [esi+0], 1
  mov DWORD [esi+4], temp_lambda_1
  mov eax, [ebp-4]
  mov [esi+8], eax
  mov eax, esi
  add eax, 5
  add esi, 16
  mov [ebp-8], eax
  mov eax, 12
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
  mov eax, [ebp-12]
  and eax, 7
  cmp eax, 1
  jne near error_non_pair
  mov eax, [ebp-12]
  mov eax, [eax+3]
  mov [ebp-20], eax
  mov eax, [ebp-20]
  and eax, 7
  cmp eax, 5
  jne near error_non_lam
  mov eax, [ebp-20]
  cmp DWORD [eax-5], 1
  jne near error_arity
  mov eax, [ebp-20]
  push DWORD 10
  push eax
  mov eax, [eax-1]
  call eax
  add esp, 8
  mov [ebp-24], eax
  mov eax, [ebp-16]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-24]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-16]
  add eax, [ebp-24]
  jo near overflow_check
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
