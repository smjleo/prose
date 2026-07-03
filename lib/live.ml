open! Core
module Tag = Action.Communication.Tag

(* Micro-states of a single participant's automaton. Node ids are prose's PRISM
   state numbers, computed exactly as in [Translate.translate_type] /
   [Type_utils]. *)
type micro =
  | MEnd
  | MEntry of int list list
    (* Selection. Outer list is nondeterminism and inner list is probabilistic choice *)
  | MOffer of
      { partner : string
      ; tag : Tag.t
      ; cont : int
      }
    (* Intermediary state for committed send (q, l) *)
  | MBra of
      (string * Tag.t * int) list (* Branching (sender, label, continuation node id) *)

type role_machine =
  { rm_start : int
  ; rm_nodes : micro Int.Map.t
  }

type machines = (string * role_machine) list

let machine machines r =
  match List.Assoc.find machines r ~equal:String.equal with
  | Some rm -> rm
  | None -> failwithf "unknown role %s" r ()
;;

let cont_internal
      ~state
      ~branch_index
      ~choice_index
      ~choice_branches
      ~end_
      ~var_map
      ch_cont
  =
  match (ch_cont : Ast.session_type) with
  | End -> end_
  | Variable t -> Map.find_exn var_map t
  | Mu _ | Internal _ | External _ ->
    Type_utils.next_state_internal_nd ~state ~branch_index ~choice_index ~choice_branches
;;

let cont_external ~state ~choice_index ~ext_choices ~end_ ~var_map ch_cont =
  match (ch_cont : Ast.session_type) with
  | End -> end_
  | Variable t -> Map.find_exn var_map t
  | Mu _ | Internal _ | External _ ->
    Type_utils.next_state_external ~state ~choice_index ~ext_choices
;;

(* Build the per-role automaton, walking the type with the same state counter and
   var_map back-edge handling as [Translate.translate_type]. *)
let compile_role ty =
  let end_ = Type_utils.state_space ty in
  let nodes = ref (Int.Map.singleton end_ MEnd) in
  let reg n m = nodes := Map.set !nodes ~key:n ~data:m in
  let rec go ~state ~var_map ty =
    match (ty : Ast.session_type) with
    | End | Variable _ -> ()
    | Mu (var, t) -> go ~state ~var_map:(Map.set var_map ~key:var ~data:state) t
    | Internal choice_branches ->
      let summands =
        List.mapi choice_branches ~f:(fun branch_index branch ->
          List.mapi
            branch
            ~f:(fun choice_index (_prob, { Ast.ch_part; ch_label; ch_sort; ch_cont }) ->
              let offer_state =
                Type_utils.intermediate_state_internal
                  ~state
                  ~branch_index
                  ~choice_index
                  ~choice_branches
              in
              let cont =
                cont_internal
                  ~state
                  ~branch_index
                  ~choice_index
                  ~choice_branches
                  ~end_
                  ~var_map
                  ch_cont
              in
              reg
                offer_state
                (MOffer { partner = ch_part; tag = Tag.tag ch_label ch_sort; cont });
              offer_state))
      in
      reg state (MEntry summands);
      List.iteri choice_branches ~f:(fun branch_index branch ->
        List.iteri branch ~f:(fun choice_index (_prob, { Ast.ch_cont; _ }) ->
          let new_state =
            Type_utils.next_state_internal_nd
              ~state
              ~branch_index
              ~choice_index
              ~choice_branches
          in
          go ~state:new_state ~var_map ch_cont))
    | External ext_choices ->
      let branches =
        List.mapi
          ext_choices
          ~f:(fun choice_index { Ast.ch_part; ch_label; ch_sort; ch_cont } ->
            let cont =
              cont_external ~state ~choice_index ~ext_choices ~end_ ~var_map ch_cont
            in
            ch_part, Tag.tag ch_label ch_sort, cont)
      in
      reg state (MBra branches);
      List.iteri ext_choices ~f:(fun choice_index { Ast.ch_cont; _ } ->
        let new_state =
          Type_utils.next_state_external ~state ~choice_index ~ext_choices
        in
        go ~state:new_state ~var_map ch_cont)
  in
  go ~state:0 ~var_map:String.Map.empty ty;
  { rm_start = 0; rm_nodes = !nodes }
;;

let compile (context : Ast.context) : machines =
  List.map context ~f:(fun { Ast.ctx_part; ctx_type } -> ctx_part, compile_role ctx_type)
;;

(** A synchronisation. *)
type sync =
  { from_part : string
  ; offer_node : int
  ; from_cont : int
  ; to_part : string
  ; branch_node : int
  ; to_cont : int
  }

let collect_syncs machines =
  List.concat_map machines ~f:(fun (p, rm_p) ->
    Map.to_alist rm_p.rm_nodes
    |> List.concat_map ~f:(fun (o, micro) ->
      match micro with
      | MOffer { partner = q; tag = l; cont = cont_p } ->
        (* [q] may not be in the context (e.g. a dangling output to a
           participant with no matching branch, as auth.ctx sends to [e]): then
           there is simply no discharging sync, leaving the sender pending. *)
        (match List.Assoc.find machines q ~equal:String.equal with
         | None -> []
         | Some rm_q ->
           Map.to_alist rm_q.rm_nodes
           |> List.concat_map ~f:(fun (w, micq) ->
             match micq with
             | MBra brs ->
               List.filter_map brs ~f:(fun (sender, l2, cont_q) ->
                 if String.equal sender p && Tag.equal l2 l
                 then
                   Some
                     { from_part = p
                     ; offer_node = o
                     ; from_cont = cont_p
                     ; to_part = q
                     ; branch_node = w
                     ; to_cont = cont_q
                     }
                 else None)
             | _ -> []))
      | _ -> []))
;;

type obl_kind =
  | OSel
  | OBra

type obl =
  { ob_role : string
  ; ob_node : int
  ; ob_kind : obl_kind
  }

let collect_obls machines =
  List.concat_map machines ~f:(fun (role, rm) ->
    Map.to_alist rm.rm_nodes
    |> List.filter_map ~f:(fun (n, micro) ->
      match micro with
      | MEntry _ -> Some { ob_role = role; ob_node = n; ob_kind = OSel }
      | MBra _ -> Some { ob_role = role; ob_node = n; ob_kind = OBra }
      | MEnd | MOffer _ -> None))
;;

let offers_of machines o =
  let nodes = (machine machines o.ob_role).rm_nodes in
  match Map.find_exn nodes o.ob_node with
  | MEntry summands -> List.concat summands
  | _ -> []
;;

let dischargers machines syncs o =
  match o.ob_kind with
  | OSel ->
    let offs = offers_of machines o in
    List.filter syncs ~f:(fun s ->
      String.equal s.from_part o.ob_role && List.mem offs s.offer_node ~equal:Int.equal)
  | OBra ->
    List.filter syncs ~f:(fun s ->
      String.equal s.to_part o.ob_role && Int.equal s.branch_node o.ob_node)
;;

type gstate =
  { ctl : [ `Resolve | `Schedule ]
  ; nodes : int array (* indexed by role index *)
  }

let succs machines syncs ~r_ix (gs : gstate) : gstate list list =
  let node_of_role role = (machine machines role).rm_nodes in
  let micro_at role =
    Map.find_exn (node_of_role role) gs.nodes.(Map.find_exn r_ix role)
  in
  let roles = List.map machines ~f:fst in
  let set role v =
    let a = Array.copy gs.nodes in
    a.(Map.find_exn r_ix role) <- v;
    a
  in
  match gs.ctl with
  | `Resolve ->
    let transient =
      List.filter_map roles ~f:(fun role ->
        match micro_at role with
        | MEntry summands -> Some (role, summands)
        | _ -> None)
    in
    (match transient with
     | [] -> [ [ { ctl = `Schedule; nodes = gs.nodes } ] ]
     | _ ->
       List.concat_map transient ~f:(fun (role, summands) ->
         List.map summands ~f:(fun summand ->
           List.map summand ~f:(fun offer -> { ctl = `Resolve; nodes = set role offer }))))
  | `Schedule ->
    let sync_acts =
      List.filter_map syncs ~f:(fun s ->
        if
          gs.nodes.(Map.find_exn r_ix s.from_part) = s.offer_node
          && gs.nodes.(Map.find_exn r_ix s.to_part) = s.branch_node
        then (
          let a = Array.copy gs.nodes in
          a.(Map.find_exn r_ix s.from_part) <- s.from_cont;
          a.(Map.find_exn r_ix s.to_part) <- s.to_cont;
          Some [ { ctl = `Resolve; nodes = a } ])
        else None)
    in
    (match sync_acts with
     | [] -> [ [ { ctl = `Schedule; nodes = gs.nodes } ] ]
     | _ -> sync_acts)
;;

type explored =
  { n : int
  ; st : gstate array
  ; trans :
      int list list array (* per state: list of actions; each action = successor ids *)
  }

let explore machines syncs ~r_ix =
  let roles = List.map machines ~f:fst in
  let init =
    { ctl = `Resolve
    ; nodes = Array.of_list (List.map roles ~f:(fun r -> (machine machines r).rm_start))
    }
  in
  let key (gs : gstate) = gs.ctl, Array.to_list gs.nodes in
  let intern = Hashtbl.Poly.create () in
  let st = ref [] in
  let trans = ref [] in
  let count = ref 0 in
  let rec id_of gs =
    match Hashtbl.find intern (key gs) with
    | Some i -> i
    | None ->
      let i = !count in
      incr count;
      Hashtbl.set intern ~key:(key gs) ~data:i;
      let acts = succs machines syncs ~r_ix gs in
      let acts_ids = List.map acts ~f:(fun outs -> List.map outs ~f:id_of) in
      st := (i, gs) :: !st;
      trans := (i, acts_ids) :: !trans;
      i
  in
  ignore (id_of init : int);
  let n = !count in
  let st_arr = Array.create ~len:n init in
  List.iter !st ~f:(fun (i, gs) -> st_arr.(i) <- gs);
  let trans_arr = Array.create ~len:n [] in
  List.iter !trans ~f:(fun (i, a) -> trans_arr.(i) <- a);
  { n; st = st_arr; trans = trans_arr }
;;

let attractor (ex : explored) ~target =
  let n = ex.n in
  let n_acts = Array.map ex.trans ~f:List.length in
  let act_off = Array.create ~len:(n + 1) 0 in
  for i = 0 to n - 1 do
    act_off.(i + 1) <- act_off.(i) + n_acts.(i)
  done;
  let tot_acts = act_off.(n) in
  (* predecessors: for state j, list of (i, global action index) *)
  let preds = Array.create ~len:n [] in
  for i = 0 to n - 1 do
    List.iteri ex.trans.(i) ~f:(fun k outs ->
      let fa = act_off.(i) + k in
      List.iter outs ~f:(fun j -> preds.(j) <- (i, fa) :: preds.(j)))
  done;
  let in_x = Array.create ~len:n false in
  let hit_a = Array.create ~len:(max 1 tot_acts) false in
  let cnt = Array.copy n_acts in
  let work = Stack.create () in
  let push i =
    if not in_x.(i)
    then (
      in_x.(i) <- true;
      Stack.push work i)
  in
  List.iter target ~f:push;
  let rec loop () =
    match Stack.pop work with
    | None -> ()
    | Some j ->
      List.iter preds.(j) ~f:(fun (i, fa) ->
        if not in_x.(i)
        then (
          match ex.st.(i).ctl with
          | `Schedule -> push i
          | `Resolve ->
            if not hit_a.(fa)
            then (
              hit_a.(fa) <- true;
              cnt.(i) <- cnt.(i) - 1;
              if cnt.(i) = 0 && n_acts.(i) > 0 then push i)));
      loop ()
  in
  loop ();
  in_x
;;

(* A global config is "stable" when no role is at a selection entry (MEntry). *)
let is_stable machines ~r_ix (gs : gstate) =
  List.for_all machines ~f:(fun (role, rm) ->
    match Map.find_exn rm.rm_nodes gs.nodes.(Map.find_exn r_ix role) with
    | MEntry _ -> false
    | _ -> true)
;;

let bad_configs (context : Ast.context) : (string * int) list list =
  let machines = compile context in
  let roles = List.map machines ~f:fst in
  let r_ix = String.Map.of_alist_exn (List.mapi roles ~f:(fun i r -> r, i)) in
  let syncs = collect_syncs machines in
  let obls = collect_obls machines in
  let ex = explore machines syncs ~r_ix in
  let bad = Hash_set.Poly.create () in
  List.iter obls ~f:(fun o ->
    let dis = dischargers machines syncs o in
    let enabled i =
      let nodes = ex.st.(i).nodes in
      List.exists dis ~f:(fun s ->
        nodes.(Map.find_exn r_ix s.from_part) = s.offer_node
        && nodes.(Map.find_exn r_ix s.to_part) = s.branch_node)
    in
    let offs = offers_of machines o in
    let pending i =
      let nodes = ex.st.(i).nodes in
      let v = nodes.(Map.find_exn r_ix o.ob_role) in
      match o.ob_kind with
      | OSel -> List.mem offs v ~equal:Int.equal
      | OBra -> Int.equal v o.ob_node
    in
    let target =
      List.filter (List.range 0 ex.n) ~f:(fun s -> enabled s || not (pending s))
    in
    let esc = attractor ex ~target in
    for i = 0 to ex.n - 1 do
      if (not esc.(i)) && is_stable machines ~r_ix ex.st.(i)
      then Hash_set.add bad (Array.to_list ex.st.(i).nodes)
    done);
  Hash_set.to_list bad
  |> List.sort ~compare:[%compare: int list]
  |> List.map ~f:(fun nodes -> List.map2_exn roles nodes ~f:(fun r n -> r, n))
;;
