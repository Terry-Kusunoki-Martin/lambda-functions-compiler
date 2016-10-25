#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

extern int our_code_starts_here() asm("our_code_starts_here");
extern void error(int err_code) asm("error");
extern int print(int val) asm("print");

void print_rec(int val) {
  if(val & 0x00000001 ^ 0x00000001) {
    printf("%d", val >> 1);
  }
  else if((val & 0x00000007) == 5) {
    printf("<function>");
  }
  else if(val == 0xFFFFFFFF) {
    printf("true");
  }
  else if(val == 0x7FFFFFFF) {
    printf("false");
  }
  else if((val & 0x00000007) == 1) {
    int* valp = (int*) (val - 1);
    printf("(");
    print_rec(*valp);
    printf(", ");
    print_rec(*(valp + 1));
    printf(")");
  }
  else {
    printf("Unknown value: %#010x", val);
  }
}

int print(int val) {
  print_rec(val);
  printf("\n");
  return val;
}

void error(int i) {
  if (i == 0) {
    fprintf(stderr, "Error: comparison operator got non-number");
  }
  else if (i == 1) {
    fprintf(stderr, "Error: arithmetic operator got non-number");
  }
  else if (i == 2) {
    fprintf(stderr, "Error: if condition got non-boolean");
  }
  else if (i == 3) {
    fprintf(stderr, "Error: Integer overflow");
  }
  else if (i == 4) {
    fprintf(stderr, "Error: Operation expected pair");    
  }
  else if (i == 5) {
    fprintf(stderr, "Error: Index out of bounds");
  }
  else if (i == 6) {
    fprintf(stderr, "Error: Operation expected function");
  }
  else if (i == 7) {
    fprintf(stderr, "Error: arity mismatch");
  }
  else {
    fprintf(stderr, "Error: Unknown error code: %d\n", i);
  }
  exit(i);
}

int main(int argc, char** argv) {
  int* HEAP = calloc(100000, sizeof (int));

  int result = our_code_starts_here(HEAP);
  print(result);
  free(HEAP);
  return 0;
}

