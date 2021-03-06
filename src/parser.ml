exception Parse of string

let paranteses_match token_lst = 
  let rec inner lst balance =
    if balance < 0 then false else
    match lst with
    | Tokens.OpenBracket::l -> inner l (balance + 1)
    | Tokens.CloseBracket::l -> inner l (balance - 1)
    | _::l -> inner l balance
    | [] -> if balance = 0 then true else false in
  inner token_lst 0

let rec generate_ast token_lst =
  (* FIXME:
  let rec count inc dec lst = 
    if inc == dec then failwith "Fuck" else
    match lst with
    | inc::l -> let (c, rl) = (count inc dec l) in (c + 1, rl)
    | dec::l -> let (c, rl) = (count inc dec l) in (c - 1, rl)
    | _ -> (0, lst) in
  *)
  let rec count_vals lst = 
    match lst with
    | Tokens.Increase::l -> let (c, rl) = (count_vals l) in (c + 1, rl)
    | Tokens.Decrease::l -> let (c, rl) = (count_vals l) in (c - 1, rl)
    | _ -> (0, lst) in

  let rec count_shifts lst = 
    match lst with
    | Tokens.RightShift::l -> let (c, rl) = (count_shifts l) in (c + 1, rl)
    | Tokens.LeftShift::l -> let (c, rl) = (count_shifts l) in (c - 1, rl)
    | _ -> (0, lst) in

  let loop_tail lst =
    let rec inner lst c = 
      match lst with
      | Tokens.OpenBracket::l -> inner l (c + 1)
      | Tokens.CloseBracket::l -> if c = 0 then l else inner l (c - 1)
      | _::l -> inner l c
      | _ -> failwith "This cannot happen, unless its forgotten to check that paranteses match.." in
    inner lst 0 in

  match token_lst with
  | Tokens.Increase::_ | Tokens.Decrease::_ ->
    let (c, lr) = count_vals token_lst in 
    Nodes.Tuple (Nodes.ChangeVal c, generate_ast lr)
  | Tokens.RightShift::_ | Tokens.LeftShift::_ ->
    let (c, lr) = count_shifts token_lst in 
    Nodes.Tuple (Nodes.ChangePtr c, generate_ast lr)
  | Tokens.OpenBracket::l -> Nodes.Tuple (Nodes.Loop (generate_ast l), generate_ast (loop_tail l))
  | Tokens.CloseBracket::_ -> Nodes.Nop
  | Tokens.Input::l -> Nodes.Tuple (Nodes.InputValue, generate_ast l)
  | Tokens.Output::l -> Nodes.Tuple (Nodes.PrintValue, generate_ast l)
  | _ -> Nodes.Nop

let parse token_lst = 
  if not (paranteses_match token_lst) then raise (Parse "Mismatching parenteses");
  generate_ast token_lst;;