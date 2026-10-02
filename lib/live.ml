open! Core
module Tag = Action.Communication.Tag

(** Computation of the weak almost-sure livelocked region.

   We construct the context MDP explicitly. Each global state is a tuple of
   the participants' PRISM state variables [S_p], and the actions are the
   summand steps ([ct-nd]), the commitment steps ([ct-prob]) and the
   synchronisations ([ct-tau]) as emitted by [Translate]. *)

(* Micro-states of a single participant's automaton. Node ids are prose's PRISM
   state numbers, computed exactly as in [Translate.translate_type] /
   [Type_utils]. *)
type micro =
  | MEnd
  | MSum of int list
    (* Entry of a proper sum (two or more summands): a nondeterministic step to
       the entry of one of its singleton selections. *)
  | MSel of (float * int) list
    (* Entry of a singleton selection: a probabilistic step to the
       intermediary state of one of its branches. *)
  | MOffer of
      { partner : string
      ; tag : Tag.t
      ; cont : int
      }
    (* Intermediary state of a committed send [q!l], waiting to synchronise. *)
  | MBra of (string * Tag.t * int) list
(* Branching: (sender, label, continuation node id). *)

type role_machine =
  { rm_start : int
  ; rm_nodes : micro Int.Map.t
  }

type machines = (string * role_machine) list

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
      let entries =
        List.mapi choice_branches ~f:(fun branch_index branch ->
          let entry =
            Type_utils.summand_entry_state ~state ~branch_index ~choice_branches
          in
          let offers =
            List.mapi
              branch
              ~f:(fun choice_index (prob, { Ast.ch_part; ch_label; ch_sort; ch_cont }) ->
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
                prob, offer_state)
          in
          reg entry (MSel offers);
          entry)
      in
      (match choice_branches with
       | [ _ ] -> () (* a singleton sum is the selection itself: no summand step *)
       | _ -> reg state (MSum entries));
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

(** The fairness obligation an action incurs. *)
type obligation =
  | Nd of int
  | Prob of int
  | Comm of int
[@@deriving compare, hash, sexp_of]

type action =
  { kind : obligation
  ; succ : int list (** successor state ids with positive probability *)
  }

(** The explored context MDP. *)
type mdp =
  { n : int
  ; roles : string array
  ; nodes : int array array (** [nodes.(i)] is the tuple of [S_p] values *)
  ; trans : action list array
  ; pend : bool array array (** [pend.(p).(i)]: [p] is pending at state [i] *)
  }

(* Whether role [p] (at node [np]) can synchronise right now with some other
   role of the global configuration [nodes], as the sender or the receiver. *)
let can_sync machines ~r_ix ~nodes ~p ~np =
  match np with
  | MOffer { partner = q; tag; cont = _ } ->
    (match Map.find r_ix q with
     | None -> false
     | Some qi ->
       (match Map.find_exn (snd machines.(qi)).rm_nodes nodes.(qi) with
        | MBra brs ->
          List.exists brs ~f:(fun (sender, tag', _) ->
            String.equal sender p && Tag.equal tag tag')
        | _ -> false))
  | MBra brs ->
    List.exists brs ~f:(fun (sender, tag, _) ->
      match Map.find r_ix sender with
      | None -> false
      | Some si ->
        (match Map.find_exn (snd machines.(si)).rm_nodes nodes.(si) with
         | MOffer { partner; tag = tag'; cont = _ } ->
           String.equal partner p && Tag.equal tag tag'
         | _ -> false))
  | MEnd | MSum _ | MSel _ -> false
;;

let explore (context : Ast.context) : mdp =
  let machines = Array.of_list (compile context) in
  let roles = Array.map machines ~f:fst in
  let k = Array.length roles in
  let r_ix =
    String.Map.of_alist_exn (Array.to_list (Array.mapi roles ~f:(fun i r -> r, i)))
  in
  let micro_at nodes i = Map.find_exn (snd machines.(i)).rm_nodes nodes.(i) in
  let set nodes i v =
    let a = Array.copy nodes in
    a.(i) <- v;
    a
  in
  (* Scheduler-available actions at a configuration, as successor
     configurations. *)
  let successors nodes =
    List.concat_mapi (Array.to_list nodes) ~f:(fun i _ ->
      match micro_at nodes i with
      | MEnd | MBra _ -> []
      | MSum entries -> List.map entries ~f:(fun e -> Nd i, [ set nodes i e ])
      | MSel offers ->
        let outs =
          List.filter_map offers ~f:(fun (prob, o) ->
            if Float.( > ) prob 0.0 then Some (set nodes i o) else None)
        in
        if List.is_empty outs then [] else [ Prob i, outs ]
      | MOffer { partner = q; tag; cont } ->
        (* [q] may not be in the context (a dangling output, as auth.ctx sends
           to [e]): then there is no synchronisation, leaving [i] pending. *)
        (match Map.find r_ix q with
         | None -> []
         | Some qi ->
           (match micro_at nodes qi with
            | MBra brs ->
              List.filter_map brs ~f:(fun (sender, tag', cont_q) ->
                if String.equal sender roles.(i) && Tag.equal tag tag'
                then (
                  let a = Array.copy nodes in
                  a.(i) <- cont;
                  a.(qi) <- cont_q;
                  Some (Comm i, [ a ]))
                else None)
            | _ -> [])))
  in
  let intern = Hashtbl.Poly.create () in
  let states = ref [] in
  let count = ref 0 in
  let rec id_of nodes =
    let key = Array.to_list nodes in
    match Hashtbl.find intern key with
    | Some i -> i
    | None ->
      let i = !count in
      incr count;
      Hashtbl.set intern ~key ~data:i;
      let acts =
        List.map (successors nodes) ~f:(fun (kind, outs) ->
          { kind
          ; succ = List.map outs ~f:id_of |> List.dedup_and_sort ~compare:Int.compare
          })
      in
      states := (i, nodes, acts) :: !states;
      i
  in
  let init = Array.map machines ~f:(fun (_, rm) -> rm.rm_start) in
  ignore (id_of init : int);
  let n = !count in
  let nodes_arr = Array.create ~len:n init in
  let trans = Array.create ~len:n [] in
  List.iter !states ~f:(fun (i, nodes, acts) ->
    nodes_arr.(i) <- nodes;
    trans.(i) <- acts);
  let pend =
    Array.init k ~f:(fun p ->
      Array.init n ~f:(fun i ->
        let nodes = nodes_arr.(i) in
        match micro_at nodes p with
        | MEnd -> false
        | np -> not (can_sync machines ~r_ix ~nodes ~p:roles.(p) ~np)))
  in
  { n; roles; nodes = nodes_arr; trans; pend }
;;

(* Stage 1 (closure): the largest subset [S*] of [pend] whose every state is
   either action-less or has an action fully supported in [S*]. Computed as a
   greatest fixpoint by iterated removal with a worklist. *)
let closure (m : mdp) ~(pend : bool array) : bool array =
  let n = m.n in
  let in_s = Array.copy pend in
  (* Global action indexing, so that per-action counters can be kept. *)
  let act_off = Array.create ~len:(n + 1) 0 in
  for i = 0 to n - 1 do
    act_off.(i + 1) <- act_off.(i) + List.length m.trans.(i)
  done;
  let tot = act_off.(n) in
  let out_cnt = Array.create ~len:(max 1 tot) 0 in
  let stay_cnt = Array.create ~len:n 0 in
  let preds = Array.create ~len:n [] in
  for i = 0 to n - 1 do
    List.iteri m.trans.(i) ~f:(fun a { succ; _ } ->
      let fa = act_off.(i) + a in
      List.iter succ ~f:(fun j ->
        preds.(j) <- (i, fa) :: preds.(j);
        if not in_s.(j) then out_cnt.(fa) <- out_cnt.(fa) + 1);
      if out_cnt.(fa) = 0 then stay_cnt.(i) <- stay_cnt.(i) + 1)
  done;
  let work = Stack.create () in
  let remove i =
    if in_s.(i)
    then (
      in_s.(i) <- false;
      Stack.push work i)
  in
  for i = 0 to n - 1 do
    if in_s.(i) && (not (List.is_empty m.trans.(i))) && stay_cnt.(i) = 0 then remove i
  done;
  let rec loop () =
    match Stack.pop work with
    | None -> ()
    | Some j ->
      List.iter preds.(j) ~f:(fun (i, fa) ->
        if out_cnt.(fa) = 0
        then (
          stay_cnt.(i) <- stay_cnt.(i) - 1;
          if in_s.(i) && stay_cnt.(i) = 0 && not (List.is_empty m.trans.(i)) then remove i);
        out_cnt.(fa) <- out_cnt.(fa) + 1);
      loop ()
  in
  loop ();
  in_s
;;

(* Scratch space for Tarjan's algorithm. *)
type scratch =
  { index : int array
  ; low : int array
  ; onstack : bool array
  }

let scratch (m : mdp) =
  { index = Array.create ~len:m.n (-1)
  ; low = Array.create ~len:m.n 0
  ; onstack = Array.create ~len:m.n false
  }
;;

(* Tarjan's strongly connected components of the graph on [nodes] with
   successor function [succ] (which must only yield members of [nodes]). *)
let tarjan { index; low; onstack } ~nodes ~succ =
  List.iter nodes ~f:(fun v -> index.(v) <- -1);
  let stack = Stack.create () in
  let counter = ref 0 in
  let sccs = ref [] in
  let rec dfs v =
    index.(v) <- !counter;
    low.(v) <- !counter;
    incr counter;
    Stack.push stack v;
    onstack.(v) <- true;
    List.iter (succ v) ~f:(fun w ->
      if index.(w) = -1
      then (
        dfs w;
        low.(v) <- min low.(v) low.(w))
      else if onstack.(w)
      then low.(v) <- min low.(v) index.(w));
    if low.(v) = index.(v)
    then (
      let comp = ref [] in
      let continue = ref true in
      while !continue do
        let w = Stack.pop_exn stack in
        onstack.(w) <- false;
        comp := w :: !comp;
        if w = v then continue := false
      done;
      sccs := !comp :: !sccs)
  in
  List.iter nodes ~f:(fun v -> if index.(v) = -1 then dfs v);
  !sccs
;;

(* The actions of state [i] whose support lies inside [inset]. *)
let staying_actions (m : mdp) ~inset i =
  List.filter m.trans.(i) ~f:(fun { succ; _ } ->
    List.for_all succ ~f:(Hash_set.mem inset))
;;

(* Maximal end components of the sub-MDP induced on [states]. *)
let mecs (m : mdp) (sc : scratch) (states : int list) : int list list =
  let result = ref [] in
  let rec process states =
    let inset = Int.Hash_set.of_list states in
    let succ i =
      List.concat_map (staying_actions m ~inset i) ~f:(fun { succ; _ } -> succ)
    in
    List.iter (tarjan sc ~nodes:states ~succ) ~f:(fun scc ->
      let sset = Int.Hash_set.of_list scc in
      let bad =
        List.filter scc ~f:(fun i -> List.is_empty (staying_actions m ~inset:sset i))
      in
      if List.is_empty bad
      then result := scc :: !result
      else (
        let badset = Int.Hash_set.of_list bad in
        let remainder = List.filter scc ~f:(fun i -> not (Hash_set.mem badset i)) in
        if not (List.is_empty remainder) then process remainder))
  in
  process states;
  !result
;;

(* Stage 2 (pruning). *)
let rec prune (m : mdp) (sc : scratch) (states : int list) : int list =
  let inset = Int.Hash_set.of_list states in
  let incurred = Hash_set.Poly.create () in
  let discharged = Hash_set.Poly.create () in
  List.iter states ~f:(fun i ->
    List.iter m.trans.(i) ~f:(fun { kind; _ } -> Hash_set.add incurred kind);
    List.iter (staying_actions m ~inset i) ~f:(fun { kind; _ } ->
      Hash_set.add discharged kind));
  let unpaid kind = Hash_set.mem incurred kind && not (Hash_set.mem discharged kind) in
  let d =
    List.filter states ~f:(fun i ->
      List.exists m.trans.(i) ~f:(fun { kind; _ } -> unpaid kind))
  in
  if List.is_empty d
  then states
  else (
    let dset = Int.Hash_set.of_list d in
    let rest = List.filter states ~f:(fun i -> not (Hash_set.mem dset i)) in
    List.concat_map (mecs m sc rest) ~f:(prune m sc))
;;

let settle (m : mdp) ~p : int list =
  let sc = scratch m in
  let s_star = closure m ~pend:m.pend.(p) in
  let deadlocked, live =
    List.partition_tf
      (List.filter (List.range 0 m.n) ~f:(fun i -> s_star.(i)))
      ~f:(fun i -> List.is_empty m.trans.(i))
  in
  deadlocked @ List.concat_map (mecs m sc live) ~f:(prune m sc)
;;

let livelock_configs (context : Ast.context) : (string * int) list list =
  let m = explore context in
  let region = Hash_set.Poly.create () in
  Array.iteri m.roles ~f:(fun p _ -> List.iter (settle m ~p) ~f:(Hash_set.add region));
  Hash_set.to_list region
  |> List.map ~f:(fun i -> Array.to_list m.nodes.(i))
  |> List.sort ~compare:[%compare: int list]
  |> List.map ~f:(fun nodes ->
    List.map2_exn (Array.to_list m.roles) nodes ~f:(fun r n -> r, n))
;;
