(*
MIT License

Copyright (c) 2023 by John Wickerson.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*)

(** A CSV iteration tool for Mac OS X *)

open Format

let the : 'a option -> 'a =
  function
  | Some x -> x
  | None -> failwith "Found None, expected Some!"
   
let csv_file : string option ref = ref None
let cmd : string ref = ref ""
let dry_run : bool ref = ref false
let only_first_row : bool ref = ref false
                               
let args_spec =
  [
    ("-csv", Arg.String (fun s -> csv_file := Some s),
     "CSV file containing data to be iterated through (required)");
    ("-cmd", Arg.Set_string cmd,
     "Command to be executed on each row");
    ("-dryrun", Arg.Set dry_run,
     "Print the commands to be run but don't actually execute them (default is false)");
    ("-onlyfirstrow", Arg.Set only_first_row,
     "Only process the first row of the CSV file, useful when testing (default is false)");
  ]

let usage = "Usage: csv_iterator [options]\nOptions are:"

let tryparse parse lex buf =
  try
    parse lex buf
  with
    Parsing.Parse_error | Failure _ ->
       failwith (sprintf "Parse error at character %d.\n" (Lexing.lexeme_start buf))

let replace_in_file f from into =
  let ic = open_in f in
  let out_file = f ^ ".tmp" in
  let oc = open_out out_file in
  begin try
      while true do
        let s = input_line ic in
        let s = Str.global_replace (Str.regexp_string from) into s in
        output_string oc (s ^ "\n")
      done     
    with
      End_of_file -> close_out oc
  end;
  out_file
  
          
let main () =
  Arg.parse args_spec (fun _ -> ()) usage;
  
  if !csv_file = None then (
    Arg.usage args_spec usage;
    failwith "CSV file not provided.";
  );
  let csv_file_mod =
    (* Replace two consecutive double-quotes ("") with a single 
       closing-double-quote character (”) in CSV file.
       This is because of how Apple Numbers exports CSV files. *)
    replace_in_file (the !csv_file) "\"\"" "”"
  in
  let csv_chan = open_in csv_file_mod in
  let csv_buf = Lexing.from_channel csv_chan in
  let parsed_csv = tryparse Parser.csvtext Lexer.lex_csv csv_buf in

  (* First row of CSV file is assumed to contain column headings. *)
  let headings, rows = match parsed_csv with
    | [] -> failwith "Expected at least one row in CSV file."
    | h :: t -> (h, t)
  in

  let is_digit = function '0'..'9' -> true | _ -> false in
  List.iter (fun h ->
    if is_digit (h.[0]) then
      failwith "Column names must not begin with a digit."
    ) headings;

  (* Find the entry for the column named `s` in the given `row`. *)
  let lookup s row = 
    let rec lookup s = function
      | [], _ -> failwith "Couldn't find named column."
      | _, [] -> ""
      | h :: headings, e :: row ->
         if h = s then e else lookup s (headings, row)
    in
    lookup s (headings, row)
  in


  
  let do_row _i row =

    let evalcmd = sprintf "eval '%s'\n" !cmd in

    let add_env_var s h = sprintf "%s=\"%s\" %s" h (lookup h row) s in
    
    let fullcmd = List.fold_left add_env_var evalcmd headings in
    
    (* Run the generated command. *)
    if !dry_run then
      printf "%s" fullcmd
    else
      let _ = Sys.command fullcmd in ()
  in
  
  if !only_first_row then
    do_row 0 (List.hd rows)
  else
    List.iteri do_row rows;
  
  printf "Finished.\n"

let _ =
  main ()
