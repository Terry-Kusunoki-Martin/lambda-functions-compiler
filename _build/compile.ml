open Printf
open Expr
open Instruction
open ExtLib

type 'a envt = (string * 'a) list

let count = ref 0
let gen_temp base =
  count := !count + 1;
  sprintf "temp_%s_%d" base !count

type hole =
  | CHole of (cexpr -> aexpr)
  | ImmHole of (immexpr -> aexpr)

let fill_imm (h : hole) (v : immexpr) : aexpr =
  match h with
    | CHole(k) -> (k (CImmExpr(v)))
    | ImmHole(k) -> (k v)

let fill_c (h : hole) (c : cexpr) : aexpr =
  match h with
    | CHole(k) -> (k c)
    | ImmHole(k) ->
      let tmp = gen_temp "" in
      ALet(tmp, c, k (ImmId(tmp)))

let throw_err code = 
  [
    IPush(Sized(DWORD_PTR, Const(code)));
    ICall(Label("error"));
  ]

let check_overflow = IJo("overflow_check")
let error_non_int = "error_non_int"
let error_non_bool = "error_non_bool"
let error_oob = "error_out_of_bounds"
let error_non_lam = "error_non_lam"
let error_arity = "error_arity"
let error_non_pair = "error_non_pair"

let check_num =
  [
    IAnd(Reg(EAX), Const(0x00000001));
    ICmp(Reg(EAX), Const(0x00000000));
    IJne(error_non_int)
  ]

let check_lam arg arity=
  [
    IAnd(Reg(EAX), Const(0x00000007));
    ICmp(Reg(EAX), Const(0x00000005));
    IJne(error_non_lam);
    IMov(Reg(EAX), arg);
    ICmp(Sized(DWORD_PTR, RegOffset(-5, EAX)), Const(arity));
    IJne(error_arity);
    IMov(Reg(EAX), arg)
  ]

let check_nums arg1 arg2 =
  [
    IMov(Reg(EAX), arg1) 
  ] @ check_num @ [
    IMov(Reg(EAX), arg2);
  ] @ check_num

let check_pair arg =
  [
    IAnd(Reg(EAX), Const(0x00000007));
    ICmp(Reg(EAX), Const(0x00000001));
    IJne(error_non_pair);
    IMov(Reg(EAX), arg)
  ]

let max n m = if n > m then n else m
let rec count_c_vars (ce : cexpr) : int =
  match ce with
    | CIf(_, thn, els) ->
      max (count_vars thn) (count_vars els)
    | CLambda(args, body) ->
      (List.length args) + (count_vars body)
    | CApp(fname, args) -> 1 + (List.length args)
    | _ -> 0

and count_vars (ae : aexpr) : int =
  match ae with
    | ALet(x, bind, body) -> 
      1 + (max (count_c_vars bind) (count_vars body))
    | ACExpr(ce) -> count_c_vars ce

let return_hole = CHole(fun ce -> ACExpr(ce))

let rec anf_list (es : expr list) (k : immexpr list -> aexpr) : aexpr =
  match es with
    | [] -> k []
    | e::rest ->
      anf e (ImmHole(fun imm ->
        anf_list rest (fun imms -> k (imm::imms))))

and anf (e : expr) (h : hole) : aexpr =
  match e with
    | ENumber(n) -> fill_imm h (ImmNumber(n)) 
    | EPair(left, right) ->
      anf left (ImmHole(fun limm ->
        anf right (ImmHole(fun rimm ->
          (fill_c h (CPair(limm, rimm)))))))
    | EBool(b) -> fill_imm h (ImmBool(b)) 
    | ELambda(ids, body) ->
      (* ACExpr(CLambda(ids, (anf body h))) *)
      fill_c h (CLambda(ids, anf body return_hole))
      (* anf body (ImmHole(fun imm -> (fill_c h (CLambda(ids, imm))))) *)
    | EId(x) -> fill_imm h (ImmId(x))
    | EPrim1(op, e) ->
      anf e (ImmHole(fun imm -> (fill_c h (CPrim1(op, imm)))))
    | EPrim2(op, left, right) ->
      anf left (ImmHole(fun limm ->
        anf right (ImmHole(fun rimm ->
          (fill_c h (CPrim2(op, limm, rimm)))))))
    | EApp(f, args) ->
      anf f (ImmHole(fun fimm ->
        anf_list args (fun aimms -> fill_c h (CApp(fimm, aimms)))))
    | EPair(left, right) -> 
      anf left (ImmHole(fun limm ->
        anf right (ImmHole(fun rimm ->
          (fill_c h (CPair(limm, rimm)))))))
    | EIf(cond, thn, els) ->
      anf cond (ImmHole(fun cimm ->
        (fill_c h (CIf(cimm, (anf thn return_hole), (anf els return_hole))))))
    | ELet([], body) -> anf body h
    | ELet((name, value)::rest, body) ->
      anf value (CHole(fun ce ->
        ALet(name, ce, anf (ELet(rest, body)) h)))

let rec find ls x =
  match ls with
    | [] -> None
    | (y,v)::rest ->
      if y = x then Some(v) else find rest x

let const_true = HexConst(0xffffffff)
let const_false = HexConst(0x7fffffff)

let acompile_imm_arg (i : immexpr) _ (env : int envt) : arg =
  match i with
    | ImmNumber(n) ->
      Const((n lsl 1))
    | ImmBool(b) ->
      if b then const_true else const_false
    | ImmId(name) ->
      begin match find env name with
        | Some(stackloc) -> RegOffset(-4 * stackloc, EBP)
        | None -> failwith ("Unbound identifier in compile: " ^ name)
      end

let acompile_imm (i : immexpr) (si : int) (env : int envt) : instruction list =
  [ IMov(Reg(EAX), acompile_imm_arg i si env) ]

let rec contains x ids =
  match ids with
    | [] -> false
    | elt::xs -> (x = elt) || (contains x xs)

let add_set x ids =
  if contains x ids then ids
  else x::ids

let rec freevars (ae : aexpr) : string list =
  freevars_a ae []

and freevars_a (ae : aexpr) (env : string list) : string list =
  match ae with
    | ACExpr(ce) -> freevars_c ce env
    | ALet(id, bind, body) -> 
      let new_env = add_set id env in
      (List.fold_left (fun acc x -> add_set x acc) (freevars_a body new_env) (freevars_c bind env))

and freevars_i (ie : immexpr) (env : string list) : string list =
  match ie with
    | ImmId(x) ->
      begin match contains x env with
        | false -> [x]
        | true -> []
      end 
    | _ -> []

and freevars_c (ce : cexpr) (env : string list) : string list =
  match ce with
    | CPrim1(op, e) -> freevars_i e env
    | CPrim2(op, l, r) -> (List.fold_left (fun acc x -> add_set x acc) (freevars_i l env) (freevars_i r env))
    | CApp(fname, args) -> List.flatten (List.map (fun arg -> freevars_i arg env) ([fname] @ args))  
    | CPair(l, r) -> (List.fold_left (fun acc x -> add_set x acc) (freevars_i l env) (freevars_i r env))
    | CLambda(args, body) -> (freevars_a body (List.fold_left (fun acc x -> add_set x acc) env args))
    | CIf(cond, thn, els) -> (List.fold_left (fun acc x -> add_set x acc) (List.fold_left (fun acc x -> add_set x acc) (freevars_i cond env) (freevars_a thn env)) (freevars_a els env))
    | CImmExpr(ie) -> freevars_i ie env



let rec acompile_step (s : cexpr) (si : int) (env : int envt) : instruction list =
  match s with
    | CPair(left, right) ->
      let la = acompile_imm left si env in
      let ra = acompile_imm right si env in
      la @
      [
        IMov(RegOffset(0, ESI), Reg(EAX));
      ] @
      ra @
      [
        IMov(RegOffset(4, ESI), Reg(EAX));
        IMov(Reg(EAX), Reg(ESI));
        IAdd(Reg(ESI), Const(8));
        IAdd(Reg(EAX), Const(1));
      ]
    | CLambda(args, body) ->
      let lambda_name = gen_temp "lambda" in
      let after_label = (gen_temp ("after_" ^ lambda_name)) in
      let free_vars = freevars (ACExpr(s)) in
      let restore_vars = [IMov(Reg(EAX), RegOffset(8, EBP))] @ (* move the function pointer into eax, and begin to move saved free variables from heap onto the stack*)
                         List.flatten (List.mapi (fun i x -> 
                                    [IMov(Reg(ECX), RegOffset((4 * i + 3), EAX));
                                     IMov(RegOffset((-4 * (2 + i)), EBP), Reg(ECX))]) free_vars) in
      
      let push_args = (List.flatten (List.mapi (fun i x -> 
                                    [IMov(Reg(EAX), RegOffset((4 * (3 + i)), EBP));
                                    IMov(RegOffset((-4 * (2 + (List.length free_vars) + i)), EBP), Reg(EAX))])
                                     args)) in(* take the args from below ebp and push them onto the stack, after the free variables *)

      let new_env = (List.mapi (fun i x -> (x, (2 + i))) free_vars)
                        @ (List.mapi (fun i x -> (x, (2 + (List.length free_vars) + i))) args) in
                        (* construct a new environment for the compilation of the body of the lambda, with the proper locations of the free vars and the arguments *)

      let varcount = count_c_vars s in
      let lambda_body = [
        IJmp(Label(after_label));
        ILabel(lambda_name);
        IPush(Reg(EBP));
        IMov(Reg(EBP), Reg(ESP));
        ISub(Reg(ESP), Const(varcount * 4));
        ] @ restore_vars @ push_args @ (acompile_expr body si new_env) @ 

        [IMov(Reg(ESP), Reg(EBP));
        IPop(Reg(EBP));
        IRet;
        ILabel(after_label)] in
      
      let store_vars_tup =
          (List.fold_left (fun acc x -> ((fst acc) + 4, (snd acc) @ 
                                                     (acompile_imm (ImmId(x)) si env) @
                                                      [IMov(RegOffset((fst acc), ESI), Reg(EAX))])) (8, []) free_vars) in (* store lambda's free variables in the heap *)
      let store_vars = snd store_vars_tup in
      
      let increment_esi =
        if (List.length free_vars) mod 2 = 0 then 
          [IAdd(Reg(ESI), Const(fst store_vars_tup))]
        else
          [IAdd(Reg(ESI), Const((fst store_vars_tup) + 4))] in (* increase esi since we dumped a lambda onto the heap *)

      lambda_body @ [IMov(Sized(DWORD_PTR, RegOffset(0, ESI)), Const(List.length args));
        IMov(Sized(DWORD_PTR, RegOffset(4, ESI)), Label(lambda_name))] @ store_vars @ [IMov(Reg(EAX), Reg(ESI)); IAdd(Reg(EAX), Const(5))] @ increment_esi

    | CApp(f, iargs) ->  
      let argpushes = List.rev_map (fun a -> IPush(Sized(DWORD_PTR, acompile_imm_arg a si env))) iargs in
      let esp_dist = (4 * (List.length iargs)) + 4 in
      (acompile_imm f si env) @ (* compile the function id, check arity and that it is indeed a lambda *)
      (check_lam (acompile_imm_arg f si env) (List.length iargs)) @
      argpushes @  (* push lambda's arguments onto the stack *)
      [IPush(Reg(EAX)); (* push the function pointer *)
      IMov(Reg(EAX), RegOffset(-1, EAX)); 
      ICall(Reg(EAX)); (* untag and call the function *)
      IAdd(Reg(ESP), Const(esp_dist))
      ]

    | CPrim1(op, e) ->
      let e_as_arg = acompile_imm_arg e si env in
      let prelude = [IMov(Reg(EAX), e_as_arg)] in
      begin match op with
        | Add1 ->
          prelude @ check_num @ prelude @ [
            IAdd(Reg(EAX), Const(2));
            IJo("overflow_check")
          ]
        | Sub1 ->
          prelude @ check_num @ prelude @ [
            IAdd(Reg(EAX), Const(-2));
            IJo("overflow_check")
          ]
        | IsNum -> (* TODO adjust for pairs, functions *)
          prelude @ [
            IAnd(Reg(EAX), Const(0x00000001));
            IShl(Reg(EAX), Const(31));
            IXor(Reg(EAX), Const(0xFFFFFFFF));
          ]
        | IsBool -> (* TODO adjust for pairs, functions *)
            let is_bool_end = gen_temp "is_bool_end" in
            prelude @ [IXor(Reg(EAX), Const(0xFFFFFFF8));
            IOr(Reg(EAX), Const(0xFFFFFFF8));
            ICmp(Reg(EAX), Const(0xFFFFFFFF));
            IJe(is_bool_end);
            IMov(Reg(EAX), const_false);
            ILabel(is_bool_end)]
        | IsPair ->             
            let is_pair_end = gen_temp "is_pair_end" in
            prelude @ [IXor(Reg(EAX), Const(0xFFFFFFF6));
            IOr(Reg(EAX), Const(0xFFFFFFF8));
            ICmp(Reg(EAX), Const(0xFFFFFFFF));
            IJe(is_pair_end);
            IMov(Reg(EAX), const_false);
            ILabel(is_pair_end)]
        | Fst -> prelude @ (check_pair e_as_arg) @
            [IMov(Reg(EAX), RegOffset(-1, EAX))]
        | Snd -> prelude @ (check_pair e_as_arg) @
            [IMov(Reg(EAX), RegOffset(3, EAX))]
        | Print ->
          prelude @ [
            IPush(Sized(DWORD_PTR, Reg(EAX)));
            ICall(Label("print"));
            IPop(Reg(EAX));
          ]
      end
    | CPrim2(op, left, right) ->
      let left_as_arg = acompile_imm_arg left si env in
      let right_as_arg = acompile_imm_arg right si env in
      let checked = check_nums left_as_arg right_as_arg in
      begin match op with
        | Plus ->
          checked @
          [
            IMov(Reg(EAX), left_as_arg);
            IAdd(Reg(EAX), right_as_arg);
            check_overflow
          ]
        | Minus ->
          checked @
          [
            IMov(Reg(EAX), left_as_arg);
            ISub(Reg(EAX), right_as_arg);
            check_overflow
          ]
        | Times ->
          checked @
          [
            IMov(Reg(EAX), left_as_arg);
            IShr(Reg(EAX), Const(1));
            IMul(Reg(EAX), right_as_arg);
            check_overflow;
          ]
        | Less ->
          checked @
          [
            IMov(Reg(EAX), left_as_arg);
            ISub(Reg(EAX), right_as_arg);
            IAnd(Reg(EAX), HexConst(0x80000000));
            IOr( Reg(EAX), HexConst(0x7FFFFFFF));
          ]
        | Greater ->
          checked @
          [
            IMov(Reg(EAX), left_as_arg);
            ISub(Reg(EAX), right_as_arg);
            ISub(Reg(EAX), Const(1));
            IAnd(Reg(EAX), HexConst(0x80000000));
            IXor(Reg(EAX), HexConst(0xFFFFFFFF));
          ]
        | Equal ->
          let leave_false = gen_temp "equals" in
          [
            IMov(Reg(EAX), left_as_arg);
            ICmp(Reg(EAX), right_as_arg);
            IMov(Reg(EAX), const_false);
            IJne(leave_false);
            IMov(Reg(EAX), const_true);
            ILabel(leave_false);
          ]
       end
    | CImmExpr(i) -> acompile_imm i si env
    | CIf(cond, thn, els) ->
      let prelude = acompile_imm cond si env in
      let thn = acompile_expr thn si env in
      let els = acompile_expr els si env in
      let label_then = gen_temp "then" in
      let label_else = gen_temp "else" in
      let label_end = gen_temp "end" in
      prelude @ [
        ICmp(Reg(EAX), const_true);
        IJe(label_then);
        ICmp(Reg(EAX), const_false);
        IJe(label_else);
        IJmp(Label(error_non_bool));
        ILabel(label_then)
      ] @
      thn @
      [ IJmp(Label(label_end)); ILabel(label_else) ] @
      els @
      [ ILabel(label_end) ]

and acompile_expr (e : aexpr) (si : int) (env : int envt) : instruction list =
  match e with
    | ALet(id, e, body) ->
      let prelude = acompile_step e (si + 1) env in
      let postlude = acompile_expr body (si + 1) ((id, si)::env) in
      prelude @ [
        IMov(RegOffset(-4 * si, EBP), Reg(EAX))
      ] @ postlude
    | ACExpr(s) -> acompile_step s si env

let rec find_one (l : 'a list) (elt : 'a) : bool =
  match l with
    | [] -> false
    | x::xs -> (elt = x) || (find_one xs elt)

let rec find_dup (l : 'a list) : 'a option =
  match l with
    | [] -> None
    | [x] -> None
    | x::xs ->
      if find_one xs x then Some(x) else find_dup xs

let rec well_formed_e (e : expr) (env : bool envt) =
  match e with
    | ENumber(n) -> if n > 1073741823 || n < -1073741824 then ["num too large"] else []
    | EBool(_) -> []
    | ELambda(args, body) ->
      let from_body = well_formed_e body (env @ (List.map (fun x -> (x, true)) args))  in
      begin match find_dup args with
        | None -> from_body
        | Some(name) -> ("Duplicate name in args: " ^ name)::from_body
      end
    | EPair(first, second) ->
      (well_formed_e first env) @ (well_formed_e second env)
    | EId(x) ->
      begin match find env x with
        | None -> ["Unbound identifier: " ^ x]
        | Some(_) -> []
      end
    | EPrim1(op, e) ->
      well_formed_e e env
    | EPrim2(op, left, right) ->
      (well_formed_e left env) @ (well_formed_e right env)
    | EIf(cond, thn, els) ->
      (well_formed_e cond env) @
      (well_formed_e thn env) @
      (well_formed_e els env)
    | EApp(name, args) ->
      List.flatten (List.map (fun a -> well_formed_e a env) args)
    | ELet(binds, body) ->
      let names = List.map fst binds in
      let env_from_binds = List.map (fun a -> (a, true)) names in
      let from_body = well_formed_e body (env_from_binds @ env) in
      begin match find_dup names with
        | None -> from_body
        | Some(name) -> ("Duplicate name in let: " ^ name)::from_body
      end

let compile_to_string (prog : expr) =
  match well_formed_e prog [] with
    | x::rest ->
      let errstr = (List.fold_left (fun x y -> x ^ "\n" ^ y) "" (x::rest)) in
      failwith errstr
    | [] ->
      let anfed = (anf prog return_hole) in
      count := 0;
      let compiled_main = (acompile_expr anfed 1 []) in
      let varcount = count_vars anfed in
      let stackjump = 4 * varcount in
      let prelude = "
section .text
extern print
extern error
global our_code_starts_here" in
          let main_start = [
            ILabel("our_code_starts_here");
            (* heap start *)
            IMov(Reg(ESI), RegOffset(4, ESP));
            IAdd(Reg(ESI), Const(8));
            IAnd(Reg(ESI), HexConst(0xFFFFFFF8));
            IPush(Reg(EBP));
            IMov(Reg(EBP), Reg(ESP));
            ISub(Reg(ESP), Const(stackjump))
          ] in
          let postlude = [
            IMov(Reg(ESP), Reg(EBP));
            IPop(Reg(EBP));
            IRet;
            ILabel("overflow_check")
          ]
          @ (throw_err 3)
          @ [ILabel(error_non_int)] @ (throw_err 1)
          @ [ILabel(error_non_bool)] @ (throw_err 2)
          @ [ILabel(error_non_pair)] @ (throw_err 4)
          @ [ILabel(error_oob)] @ (throw_err 5)
          @ [ILabel(error_non_lam)] @ (throw_err 6)
          @ [ILabel(error_arity)] @ (throw_err 7) in
          let as_assembly_string = (to_asm (
            main_start @
            compiled_main @
            postlude)) in
          sprintf "%s%s\n" prelude as_assembly_string