open! Core

let measure ~iterations ?(batch_size = 1) ~f () =
  (* Should be optimised automatically by compiler, but just in case *)
  let batch_size_minus_one = batch_size - 1 in
  List.init iterations ~f:(fun _i ->
    (* We trigger GC so that it avoids triggering during benchmarking *)
    Gc.compact ();
    let t0 = Time_float.now () in
    (* [Sys.opaque_identity] prevents computations from being optimised away. *)
    for _ = batch_size_minus_one downto 0 do
      f () |> Sys.opaque_identity |> ignore
    done;
    let t1 = Time_float.now () in
    Time_float.diff t1 t0)
;;
