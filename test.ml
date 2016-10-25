open Compile
open Runner
open Printf
open OUnit2
open ExtLib

let t name program expected = name>::test_run program name expected;;
let tvg name program expected = name>::test_run_valgrind program name expected;;
let terr name program expected = name>::test_err program name expected;;

let tfvs name program expected = name>::
  (fun _ ->
    let ast = parse_string name program in
    let anfed = anf ast return_hole in
    let vars = freevars anfed in
    let c = Pervasives.compare in
    assert_equal (List.sort ~cmp:c vars) (List.sort ~cmp:c expected) ~printer:dump)
;;

let program = [
  t "fortytwo" "42" "42";
  t "simple_app" "let f = (lambda x: x + 6) in f(33)" "39";
  t "no_args" "let f = (lambda: 4) in f()" "4";
  t "no_free_vars" "let y = 30 in
                      let f = (lambda x: x + 40) in f(50)" "90";
  t "free_vars" "let y = 30 in
                      let f = (lambda x: x + y) in f(50)" "80";
  t "function_value_lambda" "let f = (lambda x: x + 50) in let g = (lambda h: h(40)) in g(f)" "90";
  t "nested_lambda1" "let gtx = (lambda x: (lambda: 11 > (3 * x))) in gtx(3)()" "true";
  t "nested_lambda2" "let gtx = (lambda x: (lambda: print(x))) in gtx(50)()" "50\n50";
  t "nested_lambda5" "let gtx = (lambda x: (lambda: print(x + 11))) in gtx(4)()" "15\n15";
  t "nested_lambda3" "let gtx = (lambda x: (lambda: print(3 * x))) in gtx(4)()" "12\n12";
  t "nested_lambda4" "let gtx = (lambda x: (lambda y: y > (3 * x))) in gtx(3)(11)" "true";
  t "nested_lambda6" "let gtx = (lambda x: (lambda y: y + (3 * x))) in gtx(12)(50)" "86";
  t "multi_arg1" "let gtxy = (lambda x, y: x - y) in gtxy(4, 5)"  "-1";
  t "pair_lambda1" "let gtxy = (lambda x: fst(x)) in gtxy((-12, 14))" "-12";
  t "pair_lambda2" "let gtxy = (lambda x: snd(x)) in gtxy((-12, 14))" "14";
  t "pair_of_lambda" "let x = ((lambda x: x + 3), (lambda y: y - 3)) in fst(x)(19)" "22";
  t "pair_of_lambda_2" "let p = (6, let x = 4 in (lambda y: x + 3)) in fst(p) + snd(p)(5)" "13";
  t "pair_of_lambda_3" "let x = 6 in let y = ((lambda z: x + z), (lambda z: x - 3)) in fst(y)(1)" "7";
  t "freevars_ordering" "let x = 5 in 
                         let y = 4 in
                         let z = (lambda m: x + 3) in
                         let f = (lambda n: (z(200) - x) - n) in
                         f(10)" "-7";
  terr "unbound_in_lam" "(lambda y: let x = 10 in x + y + z)" "Unbound";
]


let frees = [
  tfvs "fvs1" "(lambda x: x + y)" ["y"];
  tfvs "fvs2" "let g_t_m = (lambda m : (lambda n : n > m)) in
               let g_t_5 = g_t_m(5) in
               g_t_5(4)" [];
  tfvs "fvs3" "(lambda y: let x = 10 in (x + y) + z)" ["z"];
  tfvs "fvs4" "let f = (lambda x: x + 1) in f(33)" [];
  tfvs "fvs5" "(lambda x: (lambda: print(x)))" [];
  tfvs "fvs6" "(lambda x: (lambda: print(x + 11)))" [];
  tfvs "fvs7" "(lambda: print(x))" ["x"];
  tfvs "fvs8" "(lambda: print(x + 11))" ["x"];
  tfvs "fvs9" "(lambda y: y > (3 * x))" ["x"];
  tfvs "fvs10" "(lambda y: 3 * x)" ["x"];
]

let old_tests = [
t "simple_pair_print" "let x = (4, 5) in (print(x), 6)" "(4, 5)\n((4, 5), 6)";
t "pair_of_pair_print" "let x = ((56, 27), (100, 543)) in print(x)" "((56, 27), (100, 543))\n((56, 27), (100, 543))";

t "isnum_on_pair" "let x = (4, 5) in isnum(x)" "false";

t "isbool_on_pair1" "let x = (4, 5) in isbool(x)" "false";
t "isbool_on_pair2" "let x = (true, true) in isbool(x)" "false";
t "isbool_on_bool" "let x = (true, true) in isbool(fst(x))" "true";
t "isbool_on_num" "let x = (1, true) in isbool(fst(x))" "false";

t "ispair_on_pair1" "let x = (4, 5) in ispair(x)" "true";
t "ispair_on_pair2" "let x = (true, true) in ispair(x)" "true";
t "ispair_on_bool" "ispair(true)" "false";
t "isbool_on_num" "ispair(4)" "false";

t "pair_of_pair" "let x = ((56, 27), (100, 543)) in snd(fst(x))" "27";

terr "add1_bool" "let x = true in add1(x)" "arithmetic operator got non-number";
terr "add1_pair" "let x = (4, 5) in add1(x)" "arithmetic operator got non-number";

terr "add_pair" "let x = (4, 5), y = (6, 7) in x + y" "arithmetic operator got non-number";
terr "sub_pair" "let x = (4, 5), y = (6, 7) in x - y" "arithmetic operator got non-number";
terr "mult_pair" "let x = (4, 5), y = (6, 7) in x * y" "arithmetic operator got non-number";
terr "less_pair" "let x = (4, 5), y = (6, 7) in x < y" "arithmetic operator got non-number";
terr "greater_pair" "let x = (4, 5), y = (6, 7) in x > y" "arithmetic operator got non-number";
t "equal_pair1" "let x = (4, 5), y = (6, 7) in x == y" "false";
t "equal_pair2" "let x = (4, 5), y = (6, 7) in x == x" "true";
t "equal_pair3" "(4, 5) == (4, 5)" "false";


(* old *)


terr "nonexistent_function"
	 "f()"
	 "Unbound identifier";


(*Old Tests*)
  t "forty" "let x = 40 in x" "40";
  t "fals" "let x = false in x" "false";
  tvg "tru" "let x = true in x" "true";

  t "isnum1" "let x = 40 in isnum(x)" "true";
  t "isnum1.1" "let x = true in isnum(x)" "false";
  t "isnum2" "let x = 40 in let y = true in isnum(y)" "false";
  t "isnum3" "let x = 40 in let y = true in isnum(x)" "true";
  tvg "isbool1" "let x = 40 in isbool(x)" "false";
  t "isbool1.1" "let x = true in isbool(x)" "true";
  t "isbool2" "let x = 40 in let y = true in isbool(y)" "true";
  t "isbool3" "let x = 40 in let y = true in isbool(x)" "false";


  t "print1" "print(1)" "1\n1";
  t "printjoe" "let x = 1 in
        let y = print(x + 1) in
				print(y + 2)" "2\n4\n4";
  (* old *)
  t "single_let" "let x = 10 in add1(x)" "11";
  t "nested_let" "let x = 5 in let y = sub1(x) in sub1(y)" "3";
  t "multiple_let" "let x = 5, y = sub1(x) in sub1(y)" "3";
  t "altered_binding" "let y = 5 in let z = sub1(y) in y" "5";
  t "let_after_equal" "let x = let y = 10 in add1(y) in add1(x)" "12";
  tvg "add_on_let" "add1(let x = 10 in x)" "11";
  t "multiple_x1" "let x = add1(let x = 10, y = 10 in add1(x)), y = 12 in x" "12";
  t "multiple_x2" "let x = let x = 5 in x in x" "5";

  t "plus_joe"  "(5 + 4) + (3 + 2)" "14";

  t "if1" "if true: 4 else: 2" "4";
  t "if2" "if false: 4 else: 2" "2";

  t "let0" "let x = 1 in x" "1";
  t "let1" "let x = 1 in x + 5" "6";
  tvg "let2" "let x = 3, y = 2 in y - x" "-1";

  t "forty_one" "41" "41";

  terr "simple_unbound" "z" "Unbound";

  t "ten" "let x = 10 in x" "10";

  t "multiple_binds" "let x = 2 in let y = add1(x) in add1(y)" "4";
  
  terr "shadowing" "let y = let x = 7 in sub1(x) in add1(x)" "Unbound";

  t "in_lab" "let x = add1(let x = 10 in x) in x" "11";

  t "nested_let" "let x = let x = 6 in add1(1) in add1(x)" "3";

  t "multiple_binds_err" "let x = 5 in let x = 6 in add1(x)" "7";

  terr "unbound_test" "let x = let y = sub1(x) in x in add1(2)" "Unbound";

  tvg "nested_prim" "sub1(add1(sub1(sub1(9))))" "7";

  t "let_in_prim" "sub1(let x = 5 in sub1(x))" "3";

  t "comma_separated_binds" "let x = 4, y = sub1(x) in sub1(y)" "2";

  t "sub_one" "sub1(add1(sub1(5)))" "4";

  terr "unbound_in_nested_let" "let y = sub1(x) in let x = 5 in x" "Unbound";
  terr "unbound_in_multiple_let" "let y = sub1(x), x = 5 in x" "Unbound";
  terr "unbound_in_body" "let x = 5 in sub1(z)" "Unbound";
  terr "let_after_equal_unbound" "let x = let y = 10 in add1(y) in sub1(sub1(y))" "Unbound";
  terr "unbound_let1" "let x = add1(x) in x" "Unbound";
  terr "unbound_let2" "let x = x in x" "Unbound";

  t "shadowing_nested" "let x = 10 in let x = 5 in add1(x)" "6";
  terr "shadowing_multiple" "let x = 10, x = 5 in add1(x)" "Duplicate name";


  t "if4" "if true: if false: 7 else: 8 else: 9" "8";
  terr "if5" "if (let x = 3 in isbool(isnum(x))): 5 else: x" "Unbound";
  
  terr "if6" "let y = if y : 5 else: 3 in y + 5" "Unbound";
  terr "if8" "let y = if false : 5 else: y in y + 5" "Unbound";
  
  terr "error1" "5 * x" "Unbound";
  terr "error2" "x * x" "Unbound";
  terr "error4" "x - 5" "Unbound";
  terr "error4" "5 - x" "Unbound";
  terr "error3" "x - x" "Unbound";
  terr "error3" "x + 5" "Unbound";
  terr "error3" "x + x" "Unbound";

  t "tiemaas" "4 - 2 + 5 * 3" "21";
  t "parens1" "4 - 2 + (5 * 3)" "17";

  t "negative" "-5 + 2" "-3";

  t "cprim_in_let" "let y = 5 * 2 in y == 10" "true";
  terr "bool_expected" "if (let y = 8 in y): 33 else: 66" "got non-bool";  
  terr "num_expected_1" "true + 2" "got non-number";
  terr "num_expected_2" "true - 2" "got non-number";
  terr "num_expected_3" "true * 2" "got non-number";
  t "equality" "true == 2" "false";

  t "lt1" "1 < 5" "true";
  tvg "lt2" "5 < 1" "false";
  t "lt3" "5 < 5" "false";
  terr "lt4" "5 < true" "got non-number";
  terr "lt5" "let x = true in 5 < x" "got non-number";
  terr "lt6" "let x = true in x < 5" "got non-number";
  terr "lt7" "let x = true in x < 5" "got non-number";
  terr "lt8" "let x = 5 in x < true" "got non-number";
  terr "lt9" "let x = 5 in true < x" "got non-number";
  t "lt10" "let x = 5 in 3 < x" "true";
  t "lt11" "let x = 5 in x < 3" "false";


  t "gt1" "1 > 5" "false";
  tvg "gt2" "5 > 1" "true";
  t "gt3" "5 > 5" "false";
  terr "gt4" "5 > true" "got non-number";
  terr "gt5" "let x = true in 5 > x" "got non-number";
  terr "gt6" "let x = true in x > 5" "got non-number";
  terr "gt7" "let x = true in x > 5" "got non-number";
  terr "gt8" "let x = 5 in x > true" "got non-number";
  terr "gt9" "let x = 5 in true > x" "got non-number";
  t "gt10" "let x = 5 in 3 > x" "false";
  t "gt11" "let x = 5 in x > 3" "true";

  t "eq1" "1 == 1" "true";
  t "eq2" "1 == true" "false";
  t "eq3" "false == 1" "false";
  tvg "eq4" "false == true" "false";
  t "eq5" "false == false" "true";
  t "nested_eq" "if 18 == true: true else: let x = 4 in x == 8" "false";
  
  terr "compiletime_overflow1" "1073741824" "num too large";
  terr "compiletime_overflow2" "-1073741825" "num too large";
  terr "runtime_overflow1" "1073741823 + 1" "overflow";
  terr "runtime_overflow2" "-1073741824 - 1" "overflow";
  terr "runtime_overflow3" "add1(1073741823)" "overflow";
  terr "runtime_overflow4" "sub1(-1073741824)" "overflow";

  t "print2" "let y = print(2) in print(print(y) + 4)" "2\n2\n6\n6";
  tvg "print3" "let x = true in if print(x): print(5) else: 5" "true\n5\n5";

  t "expr_in_print" "print(let y = let y = 3 in sub1(y) in isbool(y))" "false\nfalse";
  t "nested_prints" "print(let y = 5 + print(2 + print(print(1))) in print(y))" "1\n1\n3\n8\n8\n8";
  tvg "prints_on_everything" "print(isbool(print(print(print(5) - print(6)) + print(print(3) * print(12))) == 35))" "5\n6\n-1\n3\n12\n36\n35\ntrue\ntrue"
]

let suite =
"suite">:::
program @ frees @ old_tests



let () =
  run_test_tt_main suite
;;

