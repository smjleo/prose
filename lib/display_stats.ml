open! Core

let annotation_to_short_string =
  let open Psl.Annotation in
  function
  | Type_safety -> "Safe"
  | Probabilistic_deadlock_freedom -> "PDF"
  | Normalised_probabilistic_deadlock_freedom -> "NPDF"
  | Probabilisic_termination -> "PTerm"
  | Normalised_probabilistic_termination -> "NTerm"
;;

let default_filename_col_width = 30
let default_data_col_width = 18

let print_header
      ?(filename_col_width = default_filename_col_width)
      ?(data_col_width = default_data_col_width)
      annotations
  =
  printf "%-*s" filename_col_width "Filename";
  printf "%-*s" data_col_width "Tran (ms)";
  List.iter annotations ~f:(fun annotation ->
    printf "%-*s" data_col_width (annotation_to_short_string annotation ^ " (ms)"));
  printf "\n";
  let total_width =
    filename_col_width + (data_col_width * (List.length annotations + 1))
  in
  let divider = String.make total_width '-' in
  printf "%s\n" divider;
  Out_channel.flush stdout
;;

let mean_sem xs =
  let xs = List.map xs ~f:(fun x -> Time_float.Span.to_ms x) in
  let n = List.length xs |> Float.of_int in
  let mean = List.sum (module Float) xs ~f:Fn.id /. n in
  let var =
    List.sum
      (module Float)
      xs
      ~f:(fun x ->
        let y = x -. mean in
        y *. y)
    /. n
  in
  let std = Float.sqrt var in
  let sem = std /. Float.sqrt n in
  mean, sem
;;

let print_row
      ?(filename_col_width = default_filename_col_width)
      ?(data_col_width = default_data_col_width)
      filename
      runtimes
  =
  printf "%-*s" filename_col_width filename;
  List.iter runtimes ~f:(fun column ->
    let mean, sem = mean_sem column in
    let cell = sprintf "%.2f (± %.2f)" mean sem in
    printf "%-*s " data_col_width cell);
  printf "\n";
  Out_channel.flush stdout
;;
