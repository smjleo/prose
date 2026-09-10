open! Core

let annotation_to_short_string =
  let open Psl.Annotation in
  function
  | Type_safety -> "Safe"
  | Deadlock_freedom_lower -> "DF"
  | Deadlock_freedom_upper -> "DF-U"
  | Termination_lower -> "Term"
  | Termination_upper -> "Term-U"
  | Liveness_lower -> "Live"
  | Liveness_upper -> "Live-U"
;;

module Format = struct
  type t =
    | Plain
    | Latex
    | Markdown
end

let default_filename_col_width = 30
let default_data_col_width = 18

(* Generic table printing. Cells are pre-rendered strings; [name] is the
   first column and is left-aligned, data columns are right-aligned in
   plain and Markdown output. *)
let print_table_header ~format ~filename_col_width ~data_col_width headers =
  match (format : Format.t) with
  | Latex -> ()
  | Markdown ->
    printf "| Filename |";
    List.iter headers ~f:(printf " %s |");
    printf "\n|:---|";
    List.iter headers ~f:(fun _ -> printf "---:|");
    printf "\n"
  | Plain ->
    printf "%-*s" filename_col_width "Filename";
    List.iter headers ~f:(printf "%*s" data_col_width);
    printf "\n";
    let total_width = filename_col_width + (data_col_width * List.length headers) in
    printf "%s\n" (String.make total_width '-')
;;

let print_table_row ~format ~filename_col_width ~data_col_width filename ~cells =
  (match (format : Format.t) with
   | Latex ->
     printf "\\textsf{%s}" filename;
     List.iter cells ~f:(fun cell -> printf " & %s" (cell ~format));
     printf " \\\\"
   | Markdown ->
     printf "| %s |" filename;
     List.iter cells ~f:(fun cell -> printf " %s |" (cell ~format))
   | Plain ->
     printf "%-*s" filename_col_width filename;
     List.iter cells ~f:(fun cell -> printf "%*s" data_col_width (cell ~format)));
  printf "\n";
  Out_channel.flush stdout
;;

let print_header
      ?(filename_col_width = default_filename_col_width)
      ?(data_col_width = default_data_col_width)
      annotations
      ~format
  =
  let headers =
    "Tran (ms)"
    :: "Wals (ms)"
    :: List.map annotations ~f:(fun a -> annotation_to_short_string a ^ " (ms)")
  in
  print_table_header ~format ~filename_col_width ~data_col_width headers;
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
      ~format
  =
  let cells =
    List.map runtimes ~f:(fun column ~format ->
      let mean, sem = mean_sem column in
      match (format : Format.t) with
      | Latex -> sprintf "$%.2f \\pm %.2f$" mean sem
      | Markdown -> sprintf "%.2f ± %.2f" mean sem
      | Plain -> sprintf "%.2f (± %.2f)" mean sem)
  in
  print_table_row ~format ~filename_col_width ~data_col_width filename ~cells
;;

type model_size =
  { states : int
  ; transitions : int
  ; choices : int option
  }

let default_size_col_width = 14

let print_size_header
      ?(filename_col_width = default_filename_col_width)
      ?(data_col_width = default_size_col_width)
      ~format
      ()
  =
  print_table_header
    ~format
    ~filename_col_width
    ~data_col_width
    [ "States"; "Transitions"; "Choices" ]
;;

let print_size_row
      ?(filename_col_width = default_filename_col_width)
      ?(data_col_width = default_size_col_width)
      filename
      { states; transitions; choices }
      ~format
  =
  let choices = Option.value_map choices ~default:"-" ~f:Int.to_string in
  let cells =
    List.map
      [ Int.to_string states; Int.to_string transitions; choices ]
      ~f:(fun cell ~format:_ -> cell)
  in
  print_table_row ~format ~filename_col_width ~data_col_width filename ~cells
;;
