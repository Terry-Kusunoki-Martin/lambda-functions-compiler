
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
  jmp near temp_after_temp_lambda_1_2
temp_lambda_1:
  push ebp
  mov ebp, esp
  sub esp, 12
  mov eax, [ebp+8]
  mov eax, [ebp+12]
  mov [ebp-8], eax
  jmp near temp_after_temp_lambda_3_4
temp_lambda_3:
  push ebp
  mov ebp, esp
  sub esp, 8
  mov eax, [ebp+8]
  mov eax, [ebp+12]
  mov [ebp-8], eax
  mov eax, 6
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, 6
  shr eax, 1
  imul eax, [ebp-8]
  jo near overflow_check
  mov [ebp-8], eax
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  and eax, 1
  cmp eax, 0
  jne near error_non_int
  mov eax, [ebp-8]
  sub eax, [ebp-8]
  sub eax, 1
  and eax, 0x80000000
  xor eax, 0xFFFFFFFF
  mov esp, ebp
  pop ebp
  ret
temp_after_temp_lambda_3_4:
  mov DWORD [esi+0], 1
  mov DWORD [esi+4], temp_lambda_3
  mov eax, esi
  add eax, 5
  add esi, 8
  mov esp, ebp
  pop ebp
  ret
temp_after_temp_lambda_1_2:
  mov DWORD [esi+0], 1
  mov DWORD [esi+4], temp_lambda_1
  mov eax, esi
  add eax, 5
  add esi, 8
  mov [ebp-4], eax
  mov eax, [ebp-4]
  and eax, 7
  cmp eax, 5
  jne near error_non_lam
  mov eax, [ebp-4]
  cmp DWORD [eax-5], 1
  jne near error_arity
  mov eax, [ebp-4]
  push DWORD 6
  push eax
  mov eax, [eax-1]
  call eax
  add esp, 8
  mov [ebp-8], eax
  mov eax, [ebp-8]
  and eax, 7
  cmp eax, 5
  jne near error_non_lam
  mov eax, [ebp-8]
  cmp DWORD [eax-5], 1
  jne near error_arity
  mov eax, [ebp-8]
  push DWORD 20
  push eax
  mov eax, [eax-1]
  call eax
  add esp, 8
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
