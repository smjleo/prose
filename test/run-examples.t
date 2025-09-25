For each context file in this directory, run [prose output] to check the model and properties output, then run [prose verify] to verify the properties using PRISM.

  $ for i in ../examples/*.ctx; do echo "\n\n ======= TEST $i =======\n"; cat "$i"; echo "\n ======= PRISM output ========\n"; prose output "$i"; echo "\n ======= Property checking =======\n"; prose verify "$i"; echo "\n"; done
  
  
   ======= TEST ../examples/auth.ctx =======
  
  (* Running example from the paper *)
  
  s : b & {
        connect . c (+) {
                   0.3 : login . a & authorise . end,
                   0.2 : cancel . e (+) stop . end
                 },
        err . mu t . b & retry . t
      }
  
  c : s & {
        login . a (+) pass . end,
        cancel . a (+) quit . end
      }
  
  a : c & {
        pass . s (+) authorise . end,
        quit . end
      }
  
  b : s (+) {
        0.6 : connect . end,
        0.4 : err . mu t . s (+) retry . t
      }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [s_e] false -> 1:(closure'=false);
    [s_e_stop_unit] false -> 1:(closure'=false);
  endmodule
  
  module s
    s : [0..12] init 0;
  
    [] (s=12) & (fail=false) -> 1:(fail'=true);
    [b_s] (s=0) & (fail=false) -> 1:(s'=1);
    [b_s_connect_unit] (s=1) & (fail=false) -> 1:(s'=4);
    [b_s_err_unit] (s=1) & (fail=false) -> 1:(s'=2);
    [s_c] (s=4) & (fail=false) -> 0.5:(s'=12) + 0.3:(s'=5) + 0.2:(s'=6);
    [s_c_login_unit] (s=5) & (fail=false) -> 1:(s'=7);
    [s_c_cancel_unit] (s=6) & (fail=false) -> 1:(s'=9);
    [a_s] (s=7) & (fail=false) -> 1:(s'=8);
    [a_s_authorise_unit] (s=8) & (fail=false) -> 1:(s'=11);
    [s_e] (s=9) & (fail=false) -> 0:(s'=12) + 1:(s'=10);
    [s_e_stop_unit] (s=10) & (fail=false) -> 1:(s'=11);
    [b_s] (s=2) & (fail=false) -> 1:(s'=3);
    [b_s_retry_unit] (s=3) & (fail=false) -> 1:(s'=2);
  endmodule
  
  module c
    c : [0..7] init 0;
  
    [] (c=7) & (fail=false) -> 1:(fail'=true);
    [s_c] (c=0) & (fail=false) -> 1:(c'=1);
    [s_c_login_unit] (c=1) & (fail=false) -> 1:(c'=2);
    [s_c_cancel_unit] (c=1) & (fail=false) -> 1:(c'=4);
    [c_a] (c=2) & (fail=false) -> 0:(c'=7) + 1:(c'=3);
    [c_a_pass_unit] (c=3) & (fail=false) -> 1:(c'=6);
    [c_a] (c=4) & (fail=false) -> 0:(c'=7) + 1:(c'=5);
    [c_a_quit_unit] (c=5) & (fail=false) -> 1:(c'=6);
  endmodule
  
  module a
    a : [0..5] init 0;
  
    [] (a=5) & (fail=false) -> 1:(fail'=true);
    [c_a] (a=0) & (fail=false) -> 1:(a'=1);
    [c_a_pass_unit] (a=1) & (fail=false) -> 1:(a'=2);
    [c_a_quit_unit] (a=1) & (fail=false) -> 1:(a'=4);
    [a_s] (a=2) & (fail=false) -> 0:(a'=5) + 1:(a'=3);
    [a_s_authorise_unit] (a=3) & (fail=false) -> 1:(a'=4);
  endmodule
  
  module b
    b : [0..6] init 0;
  
    [] (b=6) & (fail=false) -> 1:(fail'=true);
    [b_s] (b=0) & (fail=false) -> 0:(b'=6) + 0.4:(b'=1) + 0.6:(b'=2);
    [b_s_err_unit] (b=1) & (fail=false) -> 1:(b'=3);
    [b_s_connect_unit] (b=2) & (fail=false) -> 1:(b'=5);
    [b_s] (b=3) & (fail=false) -> 0:(b'=6) + 1:(b'=4);
    [b_s_retry_unit] (b=4) & (fail=false) -> 1:(b'=3);
  endmodule
  
  label "end" = (s=11) & (c=6) & (a=4) & (b=5);
  label "cando_a_s_authorise_unit" = a=2;
  label "cando_a_s_authorise_unit_branch" = s=7;
  label "cando_b_s_connect_unit" = b=0;
  label "cando_b_s_connect_unit_branch" = s=0;
  label "cando_b_s_err_unit" = b=0;
  label "cando_b_s_err_unit_branch" = s=0;
  label "cando_b_s_retry_unit" = b=3;
  label "cando_b_s_retry_unit_branch" = s=2;
  label "cando_c_a_pass_unit" = c=2;
  label "cando_c_a_pass_unit_branch" = a=0;
  label "cando_c_a_quit_unit" = c=4;
  label "cando_c_a_quit_unit_branch" = a=0;
  label "cando_s_c_cancel_unit" = s=4;
  label "cando_s_c_cancel_unit_branch" = c=0;
  label "cando_s_c_login_unit" = s=4;
  label "cando_s_c_login_unit_branch" = c=0;
  label "cando_s_e_stop_unit" = s=9;
  label "cando_s_e_stop_unit_branch" = false;
  label "cando_a_s_branch" = s=7;
  label "cando_b_s_branch" = (s=0) | (s=2);
  label "cando_c_a_branch" = a=0;
  label "cando_s_c_branch" = c=0;
  label "cando_s_e_branch" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_a_s_authorise_unit" & "cando_a_s_branch") => "cando_a_s_authorise_unit_branch") & ((("cando_b_s_connect_unit" & "cando_b_s_branch") => "cando_b_s_connect_unit_branch") & ((("cando_b_s_err_unit" & "cando_b_s_branch") => "cando_b_s_err_unit_branch") & ((("cando_b_s_retry_unit" & "cando_b_s_branch") => "cando_b_s_retry_unit_branch") & ((("cando_c_a_pass_unit" & "cando_c_a_branch") => "cando_c_a_pass_unit_branch") & ((("cando_c_a_quit_unit" & "cando_c_a_branch") => "cando_c_a_quit_unit_branch") & ((("cando_s_c_cancel_unit" & "cando_s_c_branch") => "cando_s_c_cancel_unit_branch") & ((("cando_s_c_login_unit" & "cando_s_c_branch") => "cando_s_c_login_unit_branch") & (("cando_s_e_stop_unit" & "cando_s_e_branch") => "cando_s_e_stop_unit_branch")))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.5800000000000001 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.8285714285714287
  
  Probabilistic termination
  Result: 0.3 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.4285714285714286
  
  
  
  
   ======= TEST ../examples/dice.ctx =======
  
  (* Knuth & Yao's Dice Program. Refer to https://www.prismmodelchecker.org/casestudies/dice.php
  
     We represent each vertex i with two processes (pi, qi), which allows us to simulate internal
     choice sending to different participants.
  *)
  
  p0 : q0 (+) {
          0.5 : l1 . end,
          0.5 : l2 . end
       }
  
  q0 : p0 & {
          l1 . mu t .
               p1 (+) go . q3 & redo . t,
          l2 . mu t .
               p2 (+) go . q6 & redo . t
       }
  
  p1 : mu t .
       q0 & go .
       q1 (+) {
          0.5 : l3 . t,
          0.5 : l4 . t
       }
  
  q1 : mu t.
       p1 & {
          l3 . p3 (+) go . t,
          l4 . p4 (+) go . t
       }
  
  p2 : mu t.
       q0 & go .
       q2 (+) {
          0.5 : l5 . t,
          0.5 : l6 . t
       }
  
  q2 : mu t .
       p2 & {
          l5 . p5 (+) go . t,
          l6 . p6 (+) go . t
       }
  
  p3 : mu t .
       q1 & go .
       q3 (+) {
          0.5 : l1 . t,
          0.5 : d1 . end
       }
  
  q3 : mu t .
       p3 & {
          l1 . q0 (+) redo . t,
          d1 . dice1 (+) done . end
       }
  
  p4 : q1 & go .
       q4 (+) {
          0.5 : d2 . end,
          0.5 : d3 . end
       }
  
  q4 : p4 & {
          d2 . dice2 (+) done . end,
          d3 . dice3 (+) done . end
       }
  
  p5 : q2 & go .
       q5 (+) {
          0.5 : d4 . end,
          0.5 : d5 . end
       }
  
  q5 : p5 & {
          d4 . dice4 (+) done . end,
          d5 . dice5 (+) done . end
       }
  
  p6 : mu t .
       q2 & go .
       q6 (+) {
          0.5 : d6 . end,
          0.5 : l2 . end
       }
  
  q6 : mu t .
       p6 & {
          d6 . dice6 (+) done . end,
          l2 . q0 (+) redo . t
       }
  
  (* Each of these should be of 1/6 probability *)
  
  dice1 : q3 & done . mu t . dummy (+) repeat . t
  dice2 : q4 & done . end
  dice3 : q4 & done . end
  dice4 : q5 & done . end
  dice5 : q5 & done . end
  dice6 : q6 & done . end
  
  dummy : mu t . dice1 & repeat . t
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p0
    p0 : [0..4] init 0;
  
    [] (p0=4) & (fail=false) -> 1:(fail'=true);
    [p0_q0] (p0=0) & (fail=false) -> 0:(p0'=4) + 0.5:(p0'=1) + 0.5:(p0'=2);
    [p0_q0_l2_unit] (p0=1) & (fail=false) -> 1:(p0'=3);
    [p0_q0_l1_unit] (p0=2) & (fail=false) -> 1:(p0'=3);
  endmodule
  
  module q0
    q0 : [0..11] init 0;
  
    [] (q0=11) & (fail=false) -> 1:(fail'=true);
    [p0_q0] (q0=0) & (fail=false) -> 1:(q0'=1);
    [p0_q0_l1_unit] (q0=1) & (fail=false) -> 1:(q0'=6);
    [p0_q0_l2_unit] (q0=1) & (fail=false) -> 1:(q0'=2);
    [q0_p1] (q0=6) & (fail=false) -> 0:(q0'=11) + 1:(q0'=7);
    [q0_p1_go_unit] (q0=7) & (fail=false) -> 1:(q0'=8);
    [q3_q0] (q0=8) & (fail=false) -> 1:(q0'=9);
    [q3_q0_redo_unit] (q0=9) & (fail=false) -> 1:(q0'=6);
    [q0_p2] (q0=2) & (fail=false) -> 0:(q0'=11) + 1:(q0'=3);
    [q0_p2_go_unit] (q0=3) & (fail=false) -> 1:(q0'=4);
    [q6_q0] (q0=4) & (fail=false) -> 1:(q0'=5);
    [q6_q0_redo_unit] (q0=5) & (fail=false) -> 1:(q0'=2);
  endmodule
  
  module p1
    p1 : [0..6] init 0;
  
    [] (p1=6) & (fail=false) -> 1:(fail'=true);
    [q0_p1] (p1=0) & (fail=false) -> 1:(p1'=1);
    [q0_p1_go_unit] (p1=1) & (fail=false) -> 1:(p1'=2);
    [p1_q1] (p1=2) & (fail=false) -> 0:(p1'=6) + 0.5:(p1'=3) + 0.5:(p1'=4);
    [p1_q1_l4_unit] (p1=3) & (fail=false) -> 1:(p1'=0);
    [p1_q1_l3_unit] (p1=4) & (fail=false) -> 1:(p1'=0);
  endmodule
  
  module q1
    q1 : [0..7] init 0;
  
    [] (q1=7) & (fail=false) -> 1:(fail'=true);
    [p1_q1] (q1=0) & (fail=false) -> 1:(q1'=1);
    [p1_q1_l3_unit] (q1=1) & (fail=false) -> 1:(q1'=4);
    [p1_q1_l4_unit] (q1=1) & (fail=false) -> 1:(q1'=2);
    [q1_p3] (q1=4) & (fail=false) -> 0:(q1'=7) + 1:(q1'=5);
    [q1_p3_go_unit] (q1=5) & (fail=false) -> 1:(q1'=0);
    [q1_p4] (q1=2) & (fail=false) -> 0:(q1'=7) + 1:(q1'=3);
    [q1_p4_go_unit] (q1=3) & (fail=false) -> 1:(q1'=0);
  endmodule
  
  module p2
    p2 : [0..6] init 0;
  
    [] (p2=6) & (fail=false) -> 1:(fail'=true);
    [q0_p2] (p2=0) & (fail=false) -> 1:(p2'=1);
    [q0_p2_go_unit] (p2=1) & (fail=false) -> 1:(p2'=2);
    [p2_q2] (p2=2) & (fail=false) -> 0:(p2'=6) + 0.5:(p2'=3) + 0.5:(p2'=4);
    [p2_q2_l6_unit] (p2=3) & (fail=false) -> 1:(p2'=0);
    [p2_q2_l5_unit] (p2=4) & (fail=false) -> 1:(p2'=0);
  endmodule
  
  module q2
    q2 : [0..7] init 0;
  
    [] (q2=7) & (fail=false) -> 1:(fail'=true);
    [p2_q2] (q2=0) & (fail=false) -> 1:(q2'=1);
    [p2_q2_l5_unit] (q2=1) & (fail=false) -> 1:(q2'=4);
    [p2_q2_l6_unit] (q2=1) & (fail=false) -> 1:(q2'=2);
    [q2_p5] (q2=4) & (fail=false) -> 0:(q2'=7) + 1:(q2'=5);
    [q2_p5_go_unit] (q2=5) & (fail=false) -> 1:(q2'=0);
    [q2_p6] (q2=2) & (fail=false) -> 0:(q2'=7) + 1:(q2'=3);
    [q2_p6_go_unit] (q2=3) & (fail=false) -> 1:(q2'=0);
  endmodule
  
  module p3
    p3 : [0..6] init 0;
  
    [] (p3=6) & (fail=false) -> 1:(fail'=true);
    [q1_p3] (p3=0) & (fail=false) -> 1:(p3'=1);
    [q1_p3_go_unit] (p3=1) & (fail=false) -> 1:(p3'=2);
    [p3_q3] (p3=2) & (fail=false) -> 0:(p3'=6) + 0.5:(p3'=3) + 0.5:(p3'=4);
    [p3_q3_l1_unit] (p3=3) & (fail=false) -> 1:(p3'=0);
    [p3_q3_d1_unit] (p3=4) & (fail=false) -> 1:(p3'=5);
  endmodule
  
  module q3
    q3 : [0..7] init 0;
  
    [] (q3=7) & (fail=false) -> 1:(fail'=true);
    [p3_q3] (q3=0) & (fail=false) -> 1:(q3'=1);
    [p3_q3_l1_unit] (q3=1) & (fail=false) -> 1:(q3'=2);
    [p3_q3_d1_unit] (q3=1) & (fail=false) -> 1:(q3'=4);
    [q3_q0] (q3=2) & (fail=false) -> 0:(q3'=7) + 1:(q3'=3);
    [q3_q0_redo_unit] (q3=3) & (fail=false) -> 1:(q3'=0);
    [q3_dice1] (q3=4) & (fail=false) -> 0:(q3'=7) + 1:(q3'=5);
    [q3_dice1_done_unit] (q3=5) & (fail=false) -> 1:(q3'=6);
  endmodule
  
  module p4
    p4 : [0..6] init 0;
  
    [] (p4=6) & (fail=false) -> 1:(fail'=true);
    [q1_p4] (p4=0) & (fail=false) -> 1:(p4'=1);
    [q1_p4_go_unit] (p4=1) & (fail=false) -> 1:(p4'=2);
    [p4_q4] (p4=2) & (fail=false) -> 0:(p4'=6) + 0.5:(p4'=3) + 0.5:(p4'=4);
    [p4_q4_d3_unit] (p4=3) & (fail=false) -> 1:(p4'=5);
    [p4_q4_d2_unit] (p4=4) & (fail=false) -> 1:(p4'=5);
  endmodule
  
  module q4
    q4 : [0..7] init 0;
  
    [] (q4=7) & (fail=false) -> 1:(fail'=true);
    [p4_q4] (q4=0) & (fail=false) -> 1:(q4'=1);
    [p4_q4_d2_unit] (q4=1) & (fail=false) -> 1:(q4'=4);
    [p4_q4_d3_unit] (q4=1) & (fail=false) -> 1:(q4'=2);
    [q4_dice2] (q4=4) & (fail=false) -> 0:(q4'=7) + 1:(q4'=5);
    [q4_dice2_done_unit] (q4=5) & (fail=false) -> 1:(q4'=6);
    [q4_dice3] (q4=2) & (fail=false) -> 0:(q4'=7) + 1:(q4'=3);
    [q4_dice3_done_unit] (q4=3) & (fail=false) -> 1:(q4'=6);
  endmodule
  
  module p5
    p5 : [0..6] init 0;
  
    [] (p5=6) & (fail=false) -> 1:(fail'=true);
    [q2_p5] (p5=0) & (fail=false) -> 1:(p5'=1);
    [q2_p5_go_unit] (p5=1) & (fail=false) -> 1:(p5'=2);
    [p5_q5] (p5=2) & (fail=false) -> 0:(p5'=6) + 0.5:(p5'=3) + 0.5:(p5'=4);
    [p5_q5_d5_unit] (p5=3) & (fail=false) -> 1:(p5'=5);
    [p5_q5_d4_unit] (p5=4) & (fail=false) -> 1:(p5'=5);
  endmodule
  
  module q5
    q5 : [0..7] init 0;
  
    [] (q5=7) & (fail=false) -> 1:(fail'=true);
    [p5_q5] (q5=0) & (fail=false) -> 1:(q5'=1);
    [p5_q5_d4_unit] (q5=1) & (fail=false) -> 1:(q5'=4);
    [p5_q5_d5_unit] (q5=1) & (fail=false) -> 1:(q5'=2);
    [q5_dice4] (q5=4) & (fail=false) -> 0:(q5'=7) + 1:(q5'=5);
    [q5_dice4_done_unit] (q5=5) & (fail=false) -> 1:(q5'=6);
    [q5_dice5] (q5=2) & (fail=false) -> 0:(q5'=7) + 1:(q5'=3);
    [q5_dice5_done_unit] (q5=3) & (fail=false) -> 1:(q5'=6);
  endmodule
  
  module p6
    p6 : [0..6] init 0;
  
    [] (p6=6) & (fail=false) -> 1:(fail'=true);
    [q2_p6] (p6=0) & (fail=false) -> 1:(p6'=1);
    [q2_p6_go_unit] (p6=1) & (fail=false) -> 1:(p6'=2);
    [p6_q6] (p6=2) & (fail=false) -> 0:(p6'=6) + 0.5:(p6'=3) + 0.5:(p6'=4);
    [p6_q6_l2_unit] (p6=3) & (fail=false) -> 1:(p6'=5);
    [p6_q6_d6_unit] (p6=4) & (fail=false) -> 1:(p6'=5);
  endmodule
  
  module q6
    q6 : [0..7] init 0;
  
    [] (q6=7) & (fail=false) -> 1:(fail'=true);
    [p6_q6] (q6=0) & (fail=false) -> 1:(q6'=1);
    [p6_q6_d6_unit] (q6=1) & (fail=false) -> 1:(q6'=4);
    [p6_q6_l2_unit] (q6=1) & (fail=false) -> 1:(q6'=2);
    [q6_dice6] (q6=4) & (fail=false) -> 0:(q6'=7) + 1:(q6'=5);
    [q6_dice6_done_unit] (q6=5) & (fail=false) -> 1:(q6'=6);
    [q6_q0] (q6=2) & (fail=false) -> 0:(q6'=7) + 1:(q6'=3);
    [q6_q0_redo_unit] (q6=3) & (fail=false) -> 1:(q6'=0);
  endmodule
  
  module dice1
    dice1 : [0..5] init 0;
  
    [] (dice1=5) & (fail=false) -> 1:(fail'=true);
    [q3_dice1] (dice1=0) & (fail=false) -> 1:(dice1'=1);
    [q3_dice1_done_unit] (dice1=1) & (fail=false) -> 1:(dice1'=2);
    [dice1_dummy] (dice1=2) & (fail=false) -> 0:(dice1'=5) + 1:(dice1'=3);
    [dice1_dummy_repeat_unit] (dice1=3) & (fail=false) -> 1:(dice1'=2);
  endmodule
  
  module dice2
    dice2 : [0..3] init 0;
  
    [] (dice2=3) & (fail=false) -> 1:(fail'=true);
    [q4_dice2] (dice2=0) & (fail=false) -> 1:(dice2'=1);
    [q4_dice2_done_unit] (dice2=1) & (fail=false) -> 1:(dice2'=2);
  endmodule
  
  module dice3
    dice3 : [0..3] init 0;
  
    [] (dice3=3) & (fail=false) -> 1:(fail'=true);
    [q4_dice3] (dice3=0) & (fail=false) -> 1:(dice3'=1);
    [q4_dice3_done_unit] (dice3=1) & (fail=false) -> 1:(dice3'=2);
  endmodule
  
  module dice4
    dice4 : [0..3] init 0;
  
    [] (dice4=3) & (fail=false) -> 1:(fail'=true);
    [q5_dice4] (dice4=0) & (fail=false) -> 1:(dice4'=1);
    [q5_dice4_done_unit] (dice4=1) & (fail=false) -> 1:(dice4'=2);
  endmodule
  
  module dice5
    dice5 : [0..3] init 0;
  
    [] (dice5=3) & (fail=false) -> 1:(fail'=true);
    [q5_dice5] (dice5=0) & (fail=false) -> 1:(dice5'=1);
    [q5_dice5_done_unit] (dice5=1) & (fail=false) -> 1:(dice5'=2);
  endmodule
  
  module dice6
    dice6 : [0..3] init 0;
  
    [] (dice6=3) & (fail=false) -> 1:(fail'=true);
    [q6_dice6] (dice6=0) & (fail=false) -> 1:(dice6'=1);
    [q6_dice6_done_unit] (dice6=1) & (fail=false) -> 1:(dice6'=2);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [dice1_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [dice1_dummy_repeat_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (p0=3) & (q0=10) & (p1=5) & (q1=6) & (p2=5) & (q2=6) & (p3=5) & (q3=6) & (p4=5) & (q4=6) & (p5=5) & (q5=6) & (p6=5) & (q6=6) & (dice1=4) & (dice2=2) & (dice3=2) & (dice4=2) & (dice5=2) & (dice6=2) & (dummy=2);
  label "cando_dice1_dummy_repeat_unit" = dice1=2;
  label "cando_dice1_dummy_repeat_unit_branch" = dummy=0;
  label "cando_p0_q0_l1_unit" = p0=0;
  label "cando_p0_q0_l1_unit_branch" = q0=0;
  label "cando_p0_q0_l2_unit" = p0=0;
  label "cando_p0_q0_l2_unit_branch" = q0=0;
  label "cando_p1_q1_l3_unit" = p1=2;
  label "cando_p1_q1_l3_unit_branch" = q1=0;
  label "cando_p1_q1_l4_unit" = p1=2;
  label "cando_p1_q1_l4_unit_branch" = q1=0;
  label "cando_p2_q2_l5_unit" = p2=2;
  label "cando_p2_q2_l5_unit_branch" = q2=0;
  label "cando_p2_q2_l6_unit" = p2=2;
  label "cando_p2_q2_l6_unit_branch" = q2=0;
  label "cando_p3_q3_d1_unit" = p3=2;
  label "cando_p3_q3_d1_unit_branch" = q3=0;
  label "cando_p3_q3_l1_unit" = p3=2;
  label "cando_p3_q3_l1_unit_branch" = q3=0;
  label "cando_p4_q4_d2_unit" = p4=2;
  label "cando_p4_q4_d2_unit_branch" = q4=0;
  label "cando_p4_q4_d3_unit" = p4=2;
  label "cando_p4_q4_d3_unit_branch" = q4=0;
  label "cando_p5_q5_d4_unit" = p5=2;
  label "cando_p5_q5_d4_unit_branch" = q5=0;
  label "cando_p5_q5_d5_unit" = p5=2;
  label "cando_p5_q5_d5_unit_branch" = q5=0;
  label "cando_p6_q6_d6_unit" = p6=2;
  label "cando_p6_q6_d6_unit_branch" = q6=0;
  label "cando_p6_q6_l2_unit" = p6=2;
  label "cando_p6_q6_l2_unit_branch" = q6=0;
  label "cando_q0_p1_go_unit" = q0=6;
  label "cando_q0_p1_go_unit_branch" = p1=0;
  label "cando_q0_p2_go_unit" = q0=2;
  label "cando_q0_p2_go_unit_branch" = p2=0;
  label "cando_q1_p3_go_unit" = q1=4;
  label "cando_q1_p3_go_unit_branch" = p3=0;
  label "cando_q1_p4_go_unit" = q1=2;
  label "cando_q1_p4_go_unit_branch" = p4=0;
  label "cando_q2_p5_go_unit" = q2=4;
  label "cando_q2_p5_go_unit_branch" = p5=0;
  label "cando_q2_p6_go_unit" = q2=2;
  label "cando_q2_p6_go_unit_branch" = p6=0;
  label "cando_q3_dice1_done_unit" = q3=4;
  label "cando_q3_dice1_done_unit_branch" = dice1=0;
  label "cando_q3_q0_redo_unit" = q3=2;
  label "cando_q3_q0_redo_unit_branch" = q0=8;
  label "cando_q4_dice2_done_unit" = q4=4;
  label "cando_q4_dice2_done_unit_branch" = dice2=0;
  label "cando_q4_dice3_done_unit" = q4=2;
  label "cando_q4_dice3_done_unit_branch" = dice3=0;
  label "cando_q5_dice4_done_unit" = q5=4;
  label "cando_q5_dice4_done_unit_branch" = dice4=0;
  label "cando_q5_dice5_done_unit" = q5=2;
  label "cando_q5_dice5_done_unit_branch" = dice5=0;
  label "cando_q6_dice6_done_unit" = q6=4;
  label "cando_q6_dice6_done_unit_branch" = dice6=0;
  label "cando_q6_q0_redo_unit" = q6=2;
  label "cando_q6_q0_redo_unit_branch" = q0=4;
  label "cando_dice1_dummy_branch" = dummy=0;
  label "cando_p0_q0_branch" = q0=0;
  label "cando_p1_q1_branch" = q1=0;
  label "cando_p2_q2_branch" = q2=0;
  label "cando_p3_q3_branch" = q3=0;
  label "cando_p4_q4_branch" = q4=0;
  label "cando_p5_q5_branch" = q5=0;
  label "cando_p6_q6_branch" = q6=0;
  label "cando_q0_p1_branch" = p1=0;
  label "cando_q0_p2_branch" = p2=0;
  label "cando_q1_p3_branch" = p3=0;
  label "cando_q1_p4_branch" = p4=0;
  label "cando_q2_p5_branch" = p5=0;
  label "cando_q2_p6_branch" = p6=0;
  label "cando_q3_dice1_branch" = dice1=0;
  label "cando_q3_q0_branch" = q0=8;
  label "cando_q4_dice2_branch" = dice2=0;
  label "cando_q4_dice3_branch" = dice3=0;
  label "cando_q5_dice4_branch" = dice4=0;
  label "cando_q5_dice5_branch" = dice5=0;
  label "cando_q6_dice6_branch" = dice6=0;
  label "cando_q6_q0_branch" = q0=4;
  
  // Type safety
  P>=1 [ (G ((("cando_dice1_dummy_repeat_unit" & "cando_dice1_dummy_branch") => "cando_dice1_dummy_repeat_unit_branch") & ((("cando_p0_q0_l1_unit" & "cando_p0_q0_branch") => "cando_p0_q0_l1_unit_branch") & ((("cando_p0_q0_l2_unit" & "cando_p0_q0_branch") => "cando_p0_q0_l2_unit_branch") & ((("cando_p1_q1_l3_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l3_unit_branch") & ((("cando_p1_q1_l4_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l4_unit_branch") & ((("cando_p2_q2_l5_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l5_unit_branch") & ((("cando_p2_q2_l6_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l6_unit_branch") & ((("cando_p3_q3_d1_unit" & "cando_p3_q3_branch") => "cando_p3_q3_d1_unit_branch") & ((("cando_p3_q3_l1_unit" & "cando_p3_q3_branch") => "cando_p3_q3_l1_unit_branch") & ((("cando_p4_q4_d2_unit" & "cando_p4_q4_branch") => "cando_p4_q4_d2_unit_branch") & ((("cando_p4_q4_d3_unit" & "cando_p4_q4_branch") => "cando_p4_q4_d3_unit_branch") & ((("cando_p5_q5_d4_unit" & "cando_p5_q5_branch") => "cando_p5_q5_d4_unit_branch") & ((("cando_p5_q5_d5_unit" & "cando_p5_q5_branch") => "cando_p5_q5_d5_unit_branch") & ((("cando_p6_q6_d6_unit" & "cando_p6_q6_branch") => "cando_p6_q6_d6_unit_branch") & ((("cando_p6_q6_l2_unit" & "cando_p6_q6_branch") => "cando_p6_q6_l2_unit_branch") & ((("cando_q0_p1_go_unit" & "cando_q0_p1_branch") => "cando_q0_p1_go_unit_branch") & ((("cando_q0_p2_go_unit" & "cando_q0_p2_branch") => "cando_q0_p2_go_unit_branch") & ((("cando_q1_p3_go_unit" & "cando_q1_p3_branch") => "cando_q1_p3_go_unit_branch") & ((("cando_q1_p4_go_unit" & "cando_q1_p4_branch") => "cando_q1_p4_go_unit_branch") & ((("cando_q2_p5_go_unit" & "cando_q2_p5_branch") => "cando_q2_p5_go_unit_branch") & ((("cando_q2_p6_go_unit" & "cando_q2_p6_branch") => "cando_q2_p6_go_unit_branch") & ((("cando_q3_dice1_done_unit" & "cando_q3_dice1_branch") => "cando_q3_dice1_done_unit_branch") & ((("cando_q3_q0_redo_unit" & "cando_q3_q0_branch") => "cando_q3_q0_redo_unit_branch") & ((("cando_q4_dice2_done_unit" & "cando_q4_dice2_branch") => "cando_q4_dice2_done_unit_branch") & ((("cando_q4_dice3_done_unit" & "cando_q4_dice3_branch") => "cando_q4_dice3_done_unit_branch") & ((("cando_q5_dice4_done_unit" & "cando_q5_dice4_branch") => "cando_q5_dice4_done_unit_branch") & ((("cando_q5_dice5_done_unit" & "cando_q5_dice5_branch") => "cando_q5_dice5_done_unit_branch") & ((("cando_q6_dice6_done_unit" & "cando_q6_dice6_branch") => "cando_q6_dice6_done_unit_branch") & (("cando_q6_q0_redo_unit" & "cando_q6_q0_branch") => "cando_q6_q0_redo_unit_branch")))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.16666698455810547 (+/- 1.1920963061161968E-6 estimated; rel err 7.1525641942636435E-6)
  
  Normalised probabilistic deadlock freedom
  Result: 0.16666698455810547
  
  Probabilistic termination
  Result: 0.8333330154418945 (+/- 5.960467888147447E-6 estimated; rel err 7.1525641942636435E-6)
  
  Normalised probabilistic termination
  Result: 0.8333330154418945
  
  
  
  
   ======= TEST ../examples/different-sort.ctx =======
  
  (* What happens if two participants try to communicate on the same label but different sorts? *)
  
  p : q (+) l(Int) . end
  
  q : p & l(Bool) . end
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [p_q_l_bool] false -> 1:(closure'=false);
    [p_q_l_int] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..3] init 0;
  
    [] (p=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0:(p'=3) + 1:(p'=1);
    [p_q_l_int] (p=1) & (fail=false) -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [] (q=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l_bool] (q=1) & (fail=false) -> 1:(q'=2);
  endmodule
  
  label "end" = (p=2) & (q=2);
  label "cando_p_q_l_bool" = false;
  label "cando_p_q_l_bool_branch" = q=0;
  label "cando_p_q_l_int" = p=0;
  label "cando_p_q_l_int_branch" = false;
  label "cando_p_q_branch" = q=0;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l_bool" & "cando_p_q_branch") => "cando_p_q_l_bool_branch") & (("cando_p_q_l_int" & "cando_p_q_branch") => "cando_p_q_l_int_branch"))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/fact_10.ctx =======
  
  w0 : mu t .
       w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }
  
  w1 : mu t . w2 & req .
              w0 (+) req .
              w0 & {
                 res(Int) . w2 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w2 (+) err . t
              }
  
  w2 : mu t . w3 & req .
              w1 (+) req .
              w1 & {
                 res(Int) . w3 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w3 (+) err . t
              }
  
  w3 : mu t . w4 & req .
              w2 (+) req .
              w2 & {
                 res(Int) . w4 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w4 (+) err . t
              }
  
  w4 : mu t . w5 & req .
              w3 (+) req .
              w3 & {
                 res(Int) . w5 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w5 (+) err . t
              }
  
  w5 : mu t . w6 & req .
              w4 (+) req .
              w4 & {
                 res(Int) . w6 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w6 (+) err . t
              }
  
  w6 : mu t . w7 & req .
              w5 (+) req .
              w5 & {
                 res(Int) . w7 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w7 (+) err . t
              }
  
  w7 : mu t . w8 & req .
              w6 (+) req .
              w6 & {
                 res(Int) . w8 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w8 (+) err . t
              }
  
  w8 : mu t . w9 & req .
              w7 (+) req .
              w7 & {
                 res(Int) . w9 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w9 (+) err . t
              }
  
  w9 : mu t . w10 & req .
              w8 (+) req .
              w8 & {
                 res(Int) . w10 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w10 (+) err . t
              }
  
  w10 : w9 (+) req .
       w9 & {
          res(Int) . mu t . dummy (+) done . t,
          err . end
       }
  
  dummy : mu t . w10 & done . t
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..6] init 0;
  
    [] (w0=6) & (fail=false) -> 1:(fail'=true);
    [w1_w0] (w0=0) & (fail=false) -> 1:(w0'=1);
    [w1_w0_req_unit] (w0=1) & (fail=false) -> 1:(w0'=2);
    [w0_w1] (w0=2) & (fail=false) -> 0:(w0'=6) + 0.7:(w0'=3) + 0.3:(w0'=4);
    [w0_w1_res_int] (w0=3) & (fail=false) -> 1:(w0'=0);
    [w0_w1_err_unit] (w0=4) & (fail=false) -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..12] init 0;
  
    [] (w1=12) & (fail=false) -> 1:(fail'=true);
    [w2_w1] (w1=0) & (fail=false) -> 1:(w1'=1);
    [w2_w1_req_unit] (w1=1) & (fail=false) -> 1:(w1'=2);
    [w1_w0] (w1=2) & (fail=false) -> 0:(w1'=12) + 1:(w1'=3);
    [w1_w0_req_unit] (w1=3) & (fail=false) -> 1:(w1'=4);
    [w0_w1] (w1=4) & (fail=false) -> 1:(w1'=5);
    [w0_w1_res_int] (w1=5) & (fail=false) -> 1:(w1'=6);
    [w0_w1_err_unit] (w1=5) & (fail=false) -> 1:(w1'=9);
    [w1_w2] (w1=6) & (fail=false) -> 0.2:(w1'=12) + 0.5:(w1'=7) + 0.3:(w1'=8);
    [w1_w2_res_int] (w1=7) & (fail=false) -> 1:(w1'=0);
    [w1_w2_err_unit] (w1=8) & (fail=false) -> 1:(w1'=0);
    [w1_w2] (w1=9) & (fail=false) -> 0:(w1'=12) + 1:(w1'=10);
    [w1_w2_err_unit] (w1=10) & (fail=false) -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..12] init 0;
  
    [] (w2=12) & (fail=false) -> 1:(fail'=true);
    [w3_w2] (w2=0) & (fail=false) -> 1:(w2'=1);
    [w3_w2_req_unit] (w2=1) & (fail=false) -> 1:(w2'=2);
    [w2_w1] (w2=2) & (fail=false) -> 0:(w2'=12) + 1:(w2'=3);
    [w2_w1_req_unit] (w2=3) & (fail=false) -> 1:(w2'=4);
    [w1_w2] (w2=4) & (fail=false) -> 1:(w2'=5);
    [w1_w2_res_int] (w2=5) & (fail=false) -> 1:(w2'=6);
    [w1_w2_err_unit] (w2=5) & (fail=false) -> 1:(w2'=9);
    [w2_w3] (w2=6) & (fail=false) -> 0.2:(w2'=12) + 0.5:(w2'=7) + 0.3:(w2'=8);
    [w2_w3_res_int] (w2=7) & (fail=false) -> 1:(w2'=0);
    [w2_w3_err_unit] (w2=8) & (fail=false) -> 1:(w2'=0);
    [w2_w3] (w2=9) & (fail=false) -> 0:(w2'=12) + 1:(w2'=10);
    [w2_w3_err_unit] (w2=10) & (fail=false) -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..12] init 0;
  
    [] (w3=12) & (fail=false) -> 1:(fail'=true);
    [w4_w3] (w3=0) & (fail=false) -> 1:(w3'=1);
    [w4_w3_req_unit] (w3=1) & (fail=false) -> 1:(w3'=2);
    [w3_w2] (w3=2) & (fail=false) -> 0:(w3'=12) + 1:(w3'=3);
    [w3_w2_req_unit] (w3=3) & (fail=false) -> 1:(w3'=4);
    [w2_w3] (w3=4) & (fail=false) -> 1:(w3'=5);
    [w2_w3_res_int] (w3=5) & (fail=false) -> 1:(w3'=6);
    [w2_w3_err_unit] (w3=5) & (fail=false) -> 1:(w3'=9);
    [w3_w4] (w3=6) & (fail=false) -> 0.2:(w3'=12) + 0.5:(w3'=7) + 0.3:(w3'=8);
    [w3_w4_res_int] (w3=7) & (fail=false) -> 1:(w3'=0);
    [w3_w4_err_unit] (w3=8) & (fail=false) -> 1:(w3'=0);
    [w3_w4] (w3=9) & (fail=false) -> 0:(w3'=12) + 1:(w3'=10);
    [w3_w4_err_unit] (w3=10) & (fail=false) -> 1:(w3'=0);
  endmodule
  
  module w4
    w4 : [0..12] init 0;
  
    [] (w4=12) & (fail=false) -> 1:(fail'=true);
    [w5_w4] (w4=0) & (fail=false) -> 1:(w4'=1);
    [w5_w4_req_unit] (w4=1) & (fail=false) -> 1:(w4'=2);
    [w4_w3] (w4=2) & (fail=false) -> 0:(w4'=12) + 1:(w4'=3);
    [w4_w3_req_unit] (w4=3) & (fail=false) -> 1:(w4'=4);
    [w3_w4] (w4=4) & (fail=false) -> 1:(w4'=5);
    [w3_w4_res_int] (w4=5) & (fail=false) -> 1:(w4'=6);
    [w3_w4_err_unit] (w4=5) & (fail=false) -> 1:(w4'=9);
    [w4_w5] (w4=6) & (fail=false) -> 0.2:(w4'=12) + 0.5:(w4'=7) + 0.3:(w4'=8);
    [w4_w5_res_int] (w4=7) & (fail=false) -> 1:(w4'=0);
    [w4_w5_err_unit] (w4=8) & (fail=false) -> 1:(w4'=0);
    [w4_w5] (w4=9) & (fail=false) -> 0:(w4'=12) + 1:(w4'=10);
    [w4_w5_err_unit] (w4=10) & (fail=false) -> 1:(w4'=0);
  endmodule
  
  module w5
    w5 : [0..12] init 0;
  
    [] (w5=12) & (fail=false) -> 1:(fail'=true);
    [w6_w5] (w5=0) & (fail=false) -> 1:(w5'=1);
    [w6_w5_req_unit] (w5=1) & (fail=false) -> 1:(w5'=2);
    [w5_w4] (w5=2) & (fail=false) -> 0:(w5'=12) + 1:(w5'=3);
    [w5_w4_req_unit] (w5=3) & (fail=false) -> 1:(w5'=4);
    [w4_w5] (w5=4) & (fail=false) -> 1:(w5'=5);
    [w4_w5_res_int] (w5=5) & (fail=false) -> 1:(w5'=6);
    [w4_w5_err_unit] (w5=5) & (fail=false) -> 1:(w5'=9);
    [w5_w6] (w5=6) & (fail=false) -> 0.2:(w5'=12) + 0.5:(w5'=7) + 0.3:(w5'=8);
    [w5_w6_res_int] (w5=7) & (fail=false) -> 1:(w5'=0);
    [w5_w6_err_unit] (w5=8) & (fail=false) -> 1:(w5'=0);
    [w5_w6] (w5=9) & (fail=false) -> 0:(w5'=12) + 1:(w5'=10);
    [w5_w6_err_unit] (w5=10) & (fail=false) -> 1:(w5'=0);
  endmodule
  
  module w6
    w6 : [0..12] init 0;
  
    [] (w6=12) & (fail=false) -> 1:(fail'=true);
    [w7_w6] (w6=0) & (fail=false) -> 1:(w6'=1);
    [w7_w6_req_unit] (w6=1) & (fail=false) -> 1:(w6'=2);
    [w6_w5] (w6=2) & (fail=false) -> 0:(w6'=12) + 1:(w6'=3);
    [w6_w5_req_unit] (w6=3) & (fail=false) -> 1:(w6'=4);
    [w5_w6] (w6=4) & (fail=false) -> 1:(w6'=5);
    [w5_w6_res_int] (w6=5) & (fail=false) -> 1:(w6'=6);
    [w5_w6_err_unit] (w6=5) & (fail=false) -> 1:(w6'=9);
    [w6_w7] (w6=6) & (fail=false) -> 0.2:(w6'=12) + 0.5:(w6'=7) + 0.3:(w6'=8);
    [w6_w7_res_int] (w6=7) & (fail=false) -> 1:(w6'=0);
    [w6_w7_err_unit] (w6=8) & (fail=false) -> 1:(w6'=0);
    [w6_w7] (w6=9) & (fail=false) -> 0:(w6'=12) + 1:(w6'=10);
    [w6_w7_err_unit] (w6=10) & (fail=false) -> 1:(w6'=0);
  endmodule
  
  module w7
    w7 : [0..12] init 0;
  
    [] (w7=12) & (fail=false) -> 1:(fail'=true);
    [w8_w7] (w7=0) & (fail=false) -> 1:(w7'=1);
    [w8_w7_req_unit] (w7=1) & (fail=false) -> 1:(w7'=2);
    [w7_w6] (w7=2) & (fail=false) -> 0:(w7'=12) + 1:(w7'=3);
    [w7_w6_req_unit] (w7=3) & (fail=false) -> 1:(w7'=4);
    [w6_w7] (w7=4) & (fail=false) -> 1:(w7'=5);
    [w6_w7_res_int] (w7=5) & (fail=false) -> 1:(w7'=6);
    [w6_w7_err_unit] (w7=5) & (fail=false) -> 1:(w7'=9);
    [w7_w8] (w7=6) & (fail=false) -> 0.2:(w7'=12) + 0.5:(w7'=7) + 0.3:(w7'=8);
    [w7_w8_res_int] (w7=7) & (fail=false) -> 1:(w7'=0);
    [w7_w8_err_unit] (w7=8) & (fail=false) -> 1:(w7'=0);
    [w7_w8] (w7=9) & (fail=false) -> 0:(w7'=12) + 1:(w7'=10);
    [w7_w8_err_unit] (w7=10) & (fail=false) -> 1:(w7'=0);
  endmodule
  
  module w8
    w8 : [0..12] init 0;
  
    [] (w8=12) & (fail=false) -> 1:(fail'=true);
    [w9_w8] (w8=0) & (fail=false) -> 1:(w8'=1);
    [w9_w8_req_unit] (w8=1) & (fail=false) -> 1:(w8'=2);
    [w8_w7] (w8=2) & (fail=false) -> 0:(w8'=12) + 1:(w8'=3);
    [w8_w7_req_unit] (w8=3) & (fail=false) -> 1:(w8'=4);
    [w7_w8] (w8=4) & (fail=false) -> 1:(w8'=5);
    [w7_w8_res_int] (w8=5) & (fail=false) -> 1:(w8'=6);
    [w7_w8_err_unit] (w8=5) & (fail=false) -> 1:(w8'=9);
    [w8_w9] (w8=6) & (fail=false) -> 0.2:(w8'=12) + 0.5:(w8'=7) + 0.3:(w8'=8);
    [w8_w9_res_int] (w8=7) & (fail=false) -> 1:(w8'=0);
    [w8_w9_err_unit] (w8=8) & (fail=false) -> 1:(w8'=0);
    [w8_w9] (w8=9) & (fail=false) -> 0:(w8'=12) + 1:(w8'=10);
    [w8_w9_err_unit] (w8=10) & (fail=false) -> 1:(w8'=0);
  endmodule
  
  module w9
    w9 : [0..12] init 0;
  
    [] (w9=12) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w9=0) & (fail=false) -> 1:(w9'=1);
    [w10_w9_req_unit] (w9=1) & (fail=false) -> 1:(w9'=2);
    [w9_w8] (w9=2) & (fail=false) -> 0:(w9'=12) + 1:(w9'=3);
    [w9_w8_req_unit] (w9=3) & (fail=false) -> 1:(w9'=4);
    [w8_w9] (w9=4) & (fail=false) -> 1:(w9'=5);
    [w8_w9_res_int] (w9=5) & (fail=false) -> 1:(w9'=6);
    [w8_w9_err_unit] (w9=5) & (fail=false) -> 1:(w9'=9);
    [w9_w10] (w9=6) & (fail=false) -> 0.2:(w9'=12) + 0.5:(w9'=7) + 0.3:(w9'=8);
    [w9_w10_res_int] (w9=7) & (fail=false) -> 1:(w9'=0);
    [w9_w10_err_unit] (w9=8) & (fail=false) -> 1:(w9'=0);
    [w9_w10] (w9=9) & (fail=false) -> 0:(w9'=12) + 1:(w9'=10);
    [w9_w10_err_unit] (w9=10) & (fail=false) -> 1:(w9'=0);
  endmodule
  
  module w10
    w10 : [0..7] init 0;
  
    [] (w10=7) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w10=0) & (fail=false) -> 0:(w10'=7) + 1:(w10'=1);
    [w10_w9_req_unit] (w10=1) & (fail=false) -> 1:(w10'=2);
    [w9_w10] (w10=2) & (fail=false) -> 1:(w10'=3);
    [w9_w10_res_int] (w10=3) & (fail=false) -> 1:(w10'=4);
    [w9_w10_err_unit] (w10=3) & (fail=false) -> 1:(w10'=6);
    [w10_dummy] (w10=4) & (fail=false) -> 0:(w10'=7) + 1:(w10'=5);
    [w10_dummy_done_unit] (w10=5) & (fail=false) -> 1:(w10'=4);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [w10_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [w10_dummy_done_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=5) & (w1=11) & (w2=11) & (w3=11) & (w4=11) & (w5=11) & (w6=11) & (w7=11) & (w8=11) & (w9=11) & (w10=6) & (dummy=2);
  label "cando_w0_w1_err_unit" = w0=2;
  label "cando_w0_w1_err_unit_branch" = w1=4;
  label "cando_w0_w1_res_int" = w0=2;
  label "cando_w0_w1_res_int_branch" = w1=4;
  label "cando_w1_w0_req_unit" = w1=2;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=6) | (w1=9);
  label "cando_w1_w2_err_unit_branch" = w2=4;
  label "cando_w1_w2_res_int" = w1=6;
  label "cando_w1_w2_res_int_branch" = w2=4;
  label "cando_w10_dummy_done_unit" = w10=4;
  label "cando_w10_dummy_done_unit_branch" = dummy=0;
  label "cando_w10_w9_req_unit" = w10=0;
  label "cando_w10_w9_req_unit_branch" = w9=0;
  label "cando_w2_w1_req_unit" = w2=2;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=6) | (w2=9);
  label "cando_w2_w3_err_unit_branch" = w3=4;
  label "cando_w2_w3_res_int" = w2=6;
  label "cando_w2_w3_res_int_branch" = w3=4;
  label "cando_w3_w2_req_unit" = w3=2;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w3_w4_err_unit" = (w3=6) | (w3=9);
  label "cando_w3_w4_err_unit_branch" = w4=4;
  label "cando_w3_w4_res_int" = w3=6;
  label "cando_w3_w4_res_int_branch" = w4=4;
  label "cando_w4_w3_req_unit" = w4=2;
  label "cando_w4_w3_req_unit_branch" = w3=0;
  label "cando_w4_w5_err_unit" = (w4=6) | (w4=9);
  label "cando_w4_w5_err_unit_branch" = w5=4;
  label "cando_w4_w5_res_int" = w4=6;
  label "cando_w4_w5_res_int_branch" = w5=4;
  label "cando_w5_w4_req_unit" = w5=2;
  label "cando_w5_w4_req_unit_branch" = w4=0;
  label "cando_w5_w6_err_unit" = (w5=6) | (w5=9);
  label "cando_w5_w6_err_unit_branch" = w6=4;
  label "cando_w5_w6_res_int" = w5=6;
  label "cando_w5_w6_res_int_branch" = w6=4;
  label "cando_w6_w5_req_unit" = w6=2;
  label "cando_w6_w5_req_unit_branch" = w5=0;
  label "cando_w6_w7_err_unit" = (w6=6) | (w6=9);
  label "cando_w6_w7_err_unit_branch" = w7=4;
  label "cando_w6_w7_res_int" = w6=6;
  label "cando_w6_w7_res_int_branch" = w7=4;
  label "cando_w7_w6_req_unit" = w7=2;
  label "cando_w7_w6_req_unit_branch" = w6=0;
  label "cando_w7_w8_err_unit" = (w7=6) | (w7=9);
  label "cando_w7_w8_err_unit_branch" = w8=4;
  label "cando_w7_w8_res_int" = w7=6;
  label "cando_w7_w8_res_int_branch" = w8=4;
  label "cando_w8_w7_req_unit" = w8=2;
  label "cando_w8_w7_req_unit_branch" = w7=0;
  label "cando_w8_w9_err_unit" = (w8=6) | (w8=9);
  label "cando_w8_w9_err_unit_branch" = w9=4;
  label "cando_w8_w9_res_int" = w8=6;
  label "cando_w8_w9_res_int_branch" = w9=4;
  label "cando_w9_w10_err_unit" = (w9=6) | (w9=9);
  label "cando_w9_w10_err_unit_branch" = w10=2;
  label "cando_w9_w10_res_int" = w9=6;
  label "cando_w9_w10_res_int_branch" = w10=2;
  label "cando_w9_w8_req_unit" = w9=2;
  label "cando_w9_w8_req_unit_branch" = w8=0;
  label "cando_w0_w1_branch" = w1=4;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=4;
  label "cando_w10_dummy_branch" = dummy=0;
  label "cando_w10_w9_branch" = w9=0;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=4;
  label "cando_w3_w2_branch" = w2=0;
  label "cando_w3_w4_branch" = w4=4;
  label "cando_w4_w3_branch" = w3=0;
  label "cando_w4_w5_branch" = w5=4;
  label "cando_w5_w4_branch" = w4=0;
  label "cando_w5_w6_branch" = w6=4;
  label "cando_w6_w5_branch" = w5=0;
  label "cando_w6_w7_branch" = w7=4;
  label "cando_w7_w6_branch" = w6=0;
  label "cando_w7_w8_branch" = w8=4;
  label "cando_w8_w7_branch" = w7=0;
  label "cando_w8_w9_branch" = w9=4;
  label "cando_w9_w10_branch" = w10=2;
  label "cando_w9_w8_branch" = w8=0;
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w10_dummy_done_unit" & "cando_w10_dummy_branch") => "cando_w10_dummy_done_unit_branch") & ((("cando_w10_w9_req_unit" & "cando_w10_w9_branch") => "cando_w10_w9_req_unit_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch") & ((("cando_w3_w4_err_unit" & "cando_w3_w4_branch") => "cando_w3_w4_err_unit_branch") & ((("cando_w3_w4_res_int" & "cando_w3_w4_branch") => "cando_w3_w4_res_int_branch") & ((("cando_w4_w3_req_unit" & "cando_w4_w3_branch") => "cando_w4_w3_req_unit_branch") & ((("cando_w4_w5_err_unit" & "cando_w4_w5_branch") => "cando_w4_w5_err_unit_branch") & ((("cando_w4_w5_res_int" & "cando_w4_w5_branch") => "cando_w4_w5_res_int_branch") & ((("cando_w5_w4_req_unit" & "cando_w5_w4_branch") => "cando_w5_w4_req_unit_branch") & ((("cando_w5_w6_err_unit" & "cando_w5_w6_branch") => "cando_w5_w6_err_unit_branch") & ((("cando_w5_w6_res_int" & "cando_w5_w6_branch") => "cando_w5_w6_res_int_branch") & ((("cando_w6_w5_req_unit" & "cando_w6_w5_branch") => "cando_w6_w5_req_unit_branch") & ((("cando_w6_w7_err_unit" & "cando_w6_w7_branch") => "cando_w6_w7_err_unit_branch") & ((("cando_w6_w7_res_int" & "cando_w6_w7_branch") => "cando_w6_w7_res_int_branch") & ((("cando_w7_w6_req_unit" & "cando_w7_w6_branch") => "cando_w7_w6_req_unit_branch") & ((("cando_w7_w8_err_unit" & "cando_w7_w8_branch") => "cando_w7_w8_err_unit_branch") & ((("cando_w7_w8_res_int" & "cando_w7_w8_branch") => "cando_w7_w8_res_int_branch") & ((("cando_w8_w7_req_unit" & "cando_w8_w7_branch") => "cando_w8_w7_req_unit_branch") & ((("cando_w8_w9_err_unit" & "cando_w8_w9_branch") => "cando_w8_w9_err_unit_branch") & ((("cando_w8_w9_res_int" & "cando_w8_w9_branch") => "cando_w8_w9_res_int_branch") & ((("cando_w9_w10_err_unit" & "cando_w9_w10_branch") => "cando_w9_w10_err_unit_branch") & ((("cando_w9_w10_res_int" & "cando_w9_w10_branch") => "cando_w9_w10_res_int_branch") & (("cando_w9_w8_req_unit" & "cando_w9_w8_branch") => "cando_w9_w8_req_unit_branch")))))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.0013671875000000888 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.0018974303372006002
  
  Probabilistic termination
  Result: 0.7191796875 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9981025696627995
  
  
  
  
   ======= TEST ../examples/fact_11.ctx =======
  
  w0 : mu t .
       w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }
  
  w1 : mu t . w2 & req .
              w0 (+) req .
              w0 & {
                 res(Int) . w2 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w2 (+) err . t
              }
  
  w2 : mu t . w3 & req .
              w1 (+) req .
              w1 & {
                 res(Int) . w3 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w3 (+) err . t
              }
  
  w3 : mu t . w4 & req .
              w2 (+) req .
              w2 & {
                 res(Int) . w4 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w4 (+) err . t
              }
  
  w4 : mu t . w5 & req .
              w3 (+) req .
              w3 & {
                 res(Int) . w5 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w5 (+) err . t
              }
  
  w5 : mu t . w6 & req .
              w4 (+) req .
              w4 & {
                 res(Int) . w6 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w6 (+) err . t
              }
  
  w6 : mu t . w7 & req .
              w5 (+) req .
              w5 & {
                 res(Int) . w7 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w7 (+) err . t
              }
  
  w7 : mu t . w8 & req .
              w6 (+) req .
              w6 & {
                 res(Int) . w8 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w8 (+) err . t
              }
  
  w8 : mu t . w9 & req .
              w7 (+) req .
              w7 & {
                 res(Int) . w9 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w9 (+) err . t
              }
  
  w9 : mu t . w10 & req .
              w8 (+) req .
              w8 & {
                 res(Int) . w10 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w10 (+) err . t
              }
  
  w10 : mu t . w11 & req .
              w9 (+) req .
              w9 & {
                 res(Int) . w11 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w11 (+) err . t
              }
  
  w11 : w10 (+) req .
       w10 & {
          res(Int) . mu t . dummy (+) done . t,
          err . end
       }
  
  dummy : mu t . w11 & done . t
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..6] init 0;
  
    [] (w0=6) & (fail=false) -> 1:(fail'=true);
    [w1_w0] (w0=0) & (fail=false) -> 1:(w0'=1);
    [w1_w0_req_unit] (w0=1) & (fail=false) -> 1:(w0'=2);
    [w0_w1] (w0=2) & (fail=false) -> 0:(w0'=6) + 0.7:(w0'=3) + 0.3:(w0'=4);
    [w0_w1_res_int] (w0=3) & (fail=false) -> 1:(w0'=0);
    [w0_w1_err_unit] (w0=4) & (fail=false) -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..12] init 0;
  
    [] (w1=12) & (fail=false) -> 1:(fail'=true);
    [w2_w1] (w1=0) & (fail=false) -> 1:(w1'=1);
    [w2_w1_req_unit] (w1=1) & (fail=false) -> 1:(w1'=2);
    [w1_w0] (w1=2) & (fail=false) -> 0:(w1'=12) + 1:(w1'=3);
    [w1_w0_req_unit] (w1=3) & (fail=false) -> 1:(w1'=4);
    [w0_w1] (w1=4) & (fail=false) -> 1:(w1'=5);
    [w0_w1_res_int] (w1=5) & (fail=false) -> 1:(w1'=6);
    [w0_w1_err_unit] (w1=5) & (fail=false) -> 1:(w1'=9);
    [w1_w2] (w1=6) & (fail=false) -> 0.2:(w1'=12) + 0.5:(w1'=7) + 0.3:(w1'=8);
    [w1_w2_res_int] (w1=7) & (fail=false) -> 1:(w1'=0);
    [w1_w2_err_unit] (w1=8) & (fail=false) -> 1:(w1'=0);
    [w1_w2] (w1=9) & (fail=false) -> 0:(w1'=12) + 1:(w1'=10);
    [w1_w2_err_unit] (w1=10) & (fail=false) -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..12] init 0;
  
    [] (w2=12) & (fail=false) -> 1:(fail'=true);
    [w3_w2] (w2=0) & (fail=false) -> 1:(w2'=1);
    [w3_w2_req_unit] (w2=1) & (fail=false) -> 1:(w2'=2);
    [w2_w1] (w2=2) & (fail=false) -> 0:(w2'=12) + 1:(w2'=3);
    [w2_w1_req_unit] (w2=3) & (fail=false) -> 1:(w2'=4);
    [w1_w2] (w2=4) & (fail=false) -> 1:(w2'=5);
    [w1_w2_res_int] (w2=5) & (fail=false) -> 1:(w2'=6);
    [w1_w2_err_unit] (w2=5) & (fail=false) -> 1:(w2'=9);
    [w2_w3] (w2=6) & (fail=false) -> 0.2:(w2'=12) + 0.5:(w2'=7) + 0.3:(w2'=8);
    [w2_w3_res_int] (w2=7) & (fail=false) -> 1:(w2'=0);
    [w2_w3_err_unit] (w2=8) & (fail=false) -> 1:(w2'=0);
    [w2_w3] (w2=9) & (fail=false) -> 0:(w2'=12) + 1:(w2'=10);
    [w2_w3_err_unit] (w2=10) & (fail=false) -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..12] init 0;
  
    [] (w3=12) & (fail=false) -> 1:(fail'=true);
    [w4_w3] (w3=0) & (fail=false) -> 1:(w3'=1);
    [w4_w3_req_unit] (w3=1) & (fail=false) -> 1:(w3'=2);
    [w3_w2] (w3=2) & (fail=false) -> 0:(w3'=12) + 1:(w3'=3);
    [w3_w2_req_unit] (w3=3) & (fail=false) -> 1:(w3'=4);
    [w2_w3] (w3=4) & (fail=false) -> 1:(w3'=5);
    [w2_w3_res_int] (w3=5) & (fail=false) -> 1:(w3'=6);
    [w2_w3_err_unit] (w3=5) & (fail=false) -> 1:(w3'=9);
    [w3_w4] (w3=6) & (fail=false) -> 0.2:(w3'=12) + 0.5:(w3'=7) + 0.3:(w3'=8);
    [w3_w4_res_int] (w3=7) & (fail=false) -> 1:(w3'=0);
    [w3_w4_err_unit] (w3=8) & (fail=false) -> 1:(w3'=0);
    [w3_w4] (w3=9) & (fail=false) -> 0:(w3'=12) + 1:(w3'=10);
    [w3_w4_err_unit] (w3=10) & (fail=false) -> 1:(w3'=0);
  endmodule
  
  module w4
    w4 : [0..12] init 0;
  
    [] (w4=12) & (fail=false) -> 1:(fail'=true);
    [w5_w4] (w4=0) & (fail=false) -> 1:(w4'=1);
    [w5_w4_req_unit] (w4=1) & (fail=false) -> 1:(w4'=2);
    [w4_w3] (w4=2) & (fail=false) -> 0:(w4'=12) + 1:(w4'=3);
    [w4_w3_req_unit] (w4=3) & (fail=false) -> 1:(w4'=4);
    [w3_w4] (w4=4) & (fail=false) -> 1:(w4'=5);
    [w3_w4_res_int] (w4=5) & (fail=false) -> 1:(w4'=6);
    [w3_w4_err_unit] (w4=5) & (fail=false) -> 1:(w4'=9);
    [w4_w5] (w4=6) & (fail=false) -> 0.2:(w4'=12) + 0.5:(w4'=7) + 0.3:(w4'=8);
    [w4_w5_res_int] (w4=7) & (fail=false) -> 1:(w4'=0);
    [w4_w5_err_unit] (w4=8) & (fail=false) -> 1:(w4'=0);
    [w4_w5] (w4=9) & (fail=false) -> 0:(w4'=12) + 1:(w4'=10);
    [w4_w5_err_unit] (w4=10) & (fail=false) -> 1:(w4'=0);
  endmodule
  
  module w5
    w5 : [0..12] init 0;
  
    [] (w5=12) & (fail=false) -> 1:(fail'=true);
    [w6_w5] (w5=0) & (fail=false) -> 1:(w5'=1);
    [w6_w5_req_unit] (w5=1) & (fail=false) -> 1:(w5'=2);
    [w5_w4] (w5=2) & (fail=false) -> 0:(w5'=12) + 1:(w5'=3);
    [w5_w4_req_unit] (w5=3) & (fail=false) -> 1:(w5'=4);
    [w4_w5] (w5=4) & (fail=false) -> 1:(w5'=5);
    [w4_w5_res_int] (w5=5) & (fail=false) -> 1:(w5'=6);
    [w4_w5_err_unit] (w5=5) & (fail=false) -> 1:(w5'=9);
    [w5_w6] (w5=6) & (fail=false) -> 0.2:(w5'=12) + 0.5:(w5'=7) + 0.3:(w5'=8);
    [w5_w6_res_int] (w5=7) & (fail=false) -> 1:(w5'=0);
    [w5_w6_err_unit] (w5=8) & (fail=false) -> 1:(w5'=0);
    [w5_w6] (w5=9) & (fail=false) -> 0:(w5'=12) + 1:(w5'=10);
    [w5_w6_err_unit] (w5=10) & (fail=false) -> 1:(w5'=0);
  endmodule
  
  module w6
    w6 : [0..12] init 0;
  
    [] (w6=12) & (fail=false) -> 1:(fail'=true);
    [w7_w6] (w6=0) & (fail=false) -> 1:(w6'=1);
    [w7_w6_req_unit] (w6=1) & (fail=false) -> 1:(w6'=2);
    [w6_w5] (w6=2) & (fail=false) -> 0:(w6'=12) + 1:(w6'=3);
    [w6_w5_req_unit] (w6=3) & (fail=false) -> 1:(w6'=4);
    [w5_w6] (w6=4) & (fail=false) -> 1:(w6'=5);
    [w5_w6_res_int] (w6=5) & (fail=false) -> 1:(w6'=6);
    [w5_w6_err_unit] (w6=5) & (fail=false) -> 1:(w6'=9);
    [w6_w7] (w6=6) & (fail=false) -> 0.2:(w6'=12) + 0.5:(w6'=7) + 0.3:(w6'=8);
    [w6_w7_res_int] (w6=7) & (fail=false) -> 1:(w6'=0);
    [w6_w7_err_unit] (w6=8) & (fail=false) -> 1:(w6'=0);
    [w6_w7] (w6=9) & (fail=false) -> 0:(w6'=12) + 1:(w6'=10);
    [w6_w7_err_unit] (w6=10) & (fail=false) -> 1:(w6'=0);
  endmodule
  
  module w7
    w7 : [0..12] init 0;
  
    [] (w7=12) & (fail=false) -> 1:(fail'=true);
    [w8_w7] (w7=0) & (fail=false) -> 1:(w7'=1);
    [w8_w7_req_unit] (w7=1) & (fail=false) -> 1:(w7'=2);
    [w7_w6] (w7=2) & (fail=false) -> 0:(w7'=12) + 1:(w7'=3);
    [w7_w6_req_unit] (w7=3) & (fail=false) -> 1:(w7'=4);
    [w6_w7] (w7=4) & (fail=false) -> 1:(w7'=5);
    [w6_w7_res_int] (w7=5) & (fail=false) -> 1:(w7'=6);
    [w6_w7_err_unit] (w7=5) & (fail=false) -> 1:(w7'=9);
    [w7_w8] (w7=6) & (fail=false) -> 0.2:(w7'=12) + 0.5:(w7'=7) + 0.3:(w7'=8);
    [w7_w8_res_int] (w7=7) & (fail=false) -> 1:(w7'=0);
    [w7_w8_err_unit] (w7=8) & (fail=false) -> 1:(w7'=0);
    [w7_w8] (w7=9) & (fail=false) -> 0:(w7'=12) + 1:(w7'=10);
    [w7_w8_err_unit] (w7=10) & (fail=false) -> 1:(w7'=0);
  endmodule
  
  module w8
    w8 : [0..12] init 0;
  
    [] (w8=12) & (fail=false) -> 1:(fail'=true);
    [w9_w8] (w8=0) & (fail=false) -> 1:(w8'=1);
    [w9_w8_req_unit] (w8=1) & (fail=false) -> 1:(w8'=2);
    [w8_w7] (w8=2) & (fail=false) -> 0:(w8'=12) + 1:(w8'=3);
    [w8_w7_req_unit] (w8=3) & (fail=false) -> 1:(w8'=4);
    [w7_w8] (w8=4) & (fail=false) -> 1:(w8'=5);
    [w7_w8_res_int] (w8=5) & (fail=false) -> 1:(w8'=6);
    [w7_w8_err_unit] (w8=5) & (fail=false) -> 1:(w8'=9);
    [w8_w9] (w8=6) & (fail=false) -> 0.2:(w8'=12) + 0.5:(w8'=7) + 0.3:(w8'=8);
    [w8_w9_res_int] (w8=7) & (fail=false) -> 1:(w8'=0);
    [w8_w9_err_unit] (w8=8) & (fail=false) -> 1:(w8'=0);
    [w8_w9] (w8=9) & (fail=false) -> 0:(w8'=12) + 1:(w8'=10);
    [w8_w9_err_unit] (w8=10) & (fail=false) -> 1:(w8'=0);
  endmodule
  
  module w9
    w9 : [0..12] init 0;
  
    [] (w9=12) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w9=0) & (fail=false) -> 1:(w9'=1);
    [w10_w9_req_unit] (w9=1) & (fail=false) -> 1:(w9'=2);
    [w9_w8] (w9=2) & (fail=false) -> 0:(w9'=12) + 1:(w9'=3);
    [w9_w8_req_unit] (w9=3) & (fail=false) -> 1:(w9'=4);
    [w8_w9] (w9=4) & (fail=false) -> 1:(w9'=5);
    [w8_w9_res_int] (w9=5) & (fail=false) -> 1:(w9'=6);
    [w8_w9_err_unit] (w9=5) & (fail=false) -> 1:(w9'=9);
    [w9_w10] (w9=6) & (fail=false) -> 0.2:(w9'=12) + 0.5:(w9'=7) + 0.3:(w9'=8);
    [w9_w10_res_int] (w9=7) & (fail=false) -> 1:(w9'=0);
    [w9_w10_err_unit] (w9=8) & (fail=false) -> 1:(w9'=0);
    [w9_w10] (w9=9) & (fail=false) -> 0:(w9'=12) + 1:(w9'=10);
    [w9_w10_err_unit] (w9=10) & (fail=false) -> 1:(w9'=0);
  endmodule
  
  module w10
    w10 : [0..12] init 0;
  
    [] (w10=12) & (fail=false) -> 1:(fail'=true);
    [w11_w10] (w10=0) & (fail=false) -> 1:(w10'=1);
    [w11_w10_req_unit] (w10=1) & (fail=false) -> 1:(w10'=2);
    [w10_w9] (w10=2) & (fail=false) -> 0:(w10'=12) + 1:(w10'=3);
    [w10_w9_req_unit] (w10=3) & (fail=false) -> 1:(w10'=4);
    [w9_w10] (w10=4) & (fail=false) -> 1:(w10'=5);
    [w9_w10_res_int] (w10=5) & (fail=false) -> 1:(w10'=6);
    [w9_w10_err_unit] (w10=5) & (fail=false) -> 1:(w10'=9);
    [w10_w11] (w10=6) & (fail=false) -> 0.2:(w10'=12) + 0.5:(w10'=7) + 0.3:(w10'=8);
    [w10_w11_res_int] (w10=7) & (fail=false) -> 1:(w10'=0);
    [w10_w11_err_unit] (w10=8) & (fail=false) -> 1:(w10'=0);
    [w10_w11] (w10=9) & (fail=false) -> 0:(w10'=12) + 1:(w10'=10);
    [w10_w11_err_unit] (w10=10) & (fail=false) -> 1:(w10'=0);
  endmodule
  
  module w11
    w11 : [0..7] init 0;
  
    [] (w11=7) & (fail=false) -> 1:(fail'=true);
    [w11_w10] (w11=0) & (fail=false) -> 0:(w11'=7) + 1:(w11'=1);
    [w11_w10_req_unit] (w11=1) & (fail=false) -> 1:(w11'=2);
    [w10_w11] (w11=2) & (fail=false) -> 1:(w11'=3);
    [w10_w11_res_int] (w11=3) & (fail=false) -> 1:(w11'=4);
    [w10_w11_err_unit] (w11=3) & (fail=false) -> 1:(w11'=6);
    [w11_dummy] (w11=4) & (fail=false) -> 0:(w11'=7) + 1:(w11'=5);
    [w11_dummy_done_unit] (w11=5) & (fail=false) -> 1:(w11'=4);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [w11_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [w11_dummy_done_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=5) & (w1=11) & (w2=11) & (w3=11) & (w4=11) & (w5=11) & (w6=11) & (w7=11) & (w8=11) & (w9=11) & (w10=11) & (w11=6) & (dummy=2);
  label "cando_w0_w1_err_unit" = w0=2;
  label "cando_w0_w1_err_unit_branch" = w1=4;
  label "cando_w0_w1_res_int" = w0=2;
  label "cando_w0_w1_res_int_branch" = w1=4;
  label "cando_w1_w0_req_unit" = w1=2;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=6) | (w1=9);
  label "cando_w1_w2_err_unit_branch" = w2=4;
  label "cando_w1_w2_res_int" = w1=6;
  label "cando_w1_w2_res_int_branch" = w2=4;
  label "cando_w10_w11_err_unit" = (w10=6) | (w10=9);
  label "cando_w10_w11_err_unit_branch" = w11=2;
  label "cando_w10_w11_res_int" = w10=6;
  label "cando_w10_w11_res_int_branch" = w11=2;
  label "cando_w10_w9_req_unit" = w10=2;
  label "cando_w10_w9_req_unit_branch" = w9=0;
  label "cando_w11_dummy_done_unit" = w11=4;
  label "cando_w11_dummy_done_unit_branch" = dummy=0;
  label "cando_w11_w10_req_unit" = w11=0;
  label "cando_w11_w10_req_unit_branch" = w10=0;
  label "cando_w2_w1_req_unit" = w2=2;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=6) | (w2=9);
  label "cando_w2_w3_err_unit_branch" = w3=4;
  label "cando_w2_w3_res_int" = w2=6;
  label "cando_w2_w3_res_int_branch" = w3=4;
  label "cando_w3_w2_req_unit" = w3=2;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w3_w4_err_unit" = (w3=6) | (w3=9);
  label "cando_w3_w4_err_unit_branch" = w4=4;
  label "cando_w3_w4_res_int" = w3=6;
  label "cando_w3_w4_res_int_branch" = w4=4;
  label "cando_w4_w3_req_unit" = w4=2;
  label "cando_w4_w3_req_unit_branch" = w3=0;
  label "cando_w4_w5_err_unit" = (w4=6) | (w4=9);
  label "cando_w4_w5_err_unit_branch" = w5=4;
  label "cando_w4_w5_res_int" = w4=6;
  label "cando_w4_w5_res_int_branch" = w5=4;
  label "cando_w5_w4_req_unit" = w5=2;
  label "cando_w5_w4_req_unit_branch" = w4=0;
  label "cando_w5_w6_err_unit" = (w5=6) | (w5=9);
  label "cando_w5_w6_err_unit_branch" = w6=4;
  label "cando_w5_w6_res_int" = w5=6;
  label "cando_w5_w6_res_int_branch" = w6=4;
  label "cando_w6_w5_req_unit" = w6=2;
  label "cando_w6_w5_req_unit_branch" = w5=0;
  label "cando_w6_w7_err_unit" = (w6=6) | (w6=9);
  label "cando_w6_w7_err_unit_branch" = w7=4;
  label "cando_w6_w7_res_int" = w6=6;
  label "cando_w6_w7_res_int_branch" = w7=4;
  label "cando_w7_w6_req_unit" = w7=2;
  label "cando_w7_w6_req_unit_branch" = w6=0;
  label "cando_w7_w8_err_unit" = (w7=6) | (w7=9);
  label "cando_w7_w8_err_unit_branch" = w8=4;
  label "cando_w7_w8_res_int" = w7=6;
  label "cando_w7_w8_res_int_branch" = w8=4;
  label "cando_w8_w7_req_unit" = w8=2;
  label "cando_w8_w7_req_unit_branch" = w7=0;
  label "cando_w8_w9_err_unit" = (w8=6) | (w8=9);
  label "cando_w8_w9_err_unit_branch" = w9=4;
  label "cando_w8_w9_res_int" = w8=6;
  label "cando_w8_w9_res_int_branch" = w9=4;
  label "cando_w9_w10_err_unit" = (w9=6) | (w9=9);
  label "cando_w9_w10_err_unit_branch" = w10=4;
  label "cando_w9_w10_res_int" = w9=6;
  label "cando_w9_w10_res_int_branch" = w10=4;
  label "cando_w9_w8_req_unit" = w9=2;
  label "cando_w9_w8_req_unit_branch" = w8=0;
  label "cando_w0_w1_branch" = w1=4;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=4;
  label "cando_w10_w11_branch" = w11=2;
  label "cando_w10_w9_branch" = w9=0;
  label "cando_w11_dummy_branch" = dummy=0;
  label "cando_w11_w10_branch" = w10=0;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=4;
  label "cando_w3_w2_branch" = w2=0;
  label "cando_w3_w4_branch" = w4=4;
  label "cando_w4_w3_branch" = w3=0;
  label "cando_w4_w5_branch" = w5=4;
  label "cando_w5_w4_branch" = w4=0;
  label "cando_w5_w6_branch" = w6=4;
  label "cando_w6_w5_branch" = w5=0;
  label "cando_w6_w7_branch" = w7=4;
  label "cando_w7_w6_branch" = w6=0;
  label "cando_w7_w8_branch" = w8=4;
  label "cando_w8_w7_branch" = w7=0;
  label "cando_w8_w9_branch" = w9=4;
  label "cando_w9_w10_branch" = w10=4;
  label "cando_w9_w8_branch" = w8=0;
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w10_w11_err_unit" & "cando_w10_w11_branch") => "cando_w10_w11_err_unit_branch") & ((("cando_w10_w11_res_int" & "cando_w10_w11_branch") => "cando_w10_w11_res_int_branch") & ((("cando_w10_w9_req_unit" & "cando_w10_w9_branch") => "cando_w10_w9_req_unit_branch") & ((("cando_w11_dummy_done_unit" & "cando_w11_dummy_branch") => "cando_w11_dummy_done_unit_branch") & ((("cando_w11_w10_req_unit" & "cando_w11_w10_branch") => "cando_w11_w10_req_unit_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch") & ((("cando_w3_w4_err_unit" & "cando_w3_w4_branch") => "cando_w3_w4_err_unit_branch") & ((("cando_w3_w4_res_int" & "cando_w3_w4_branch") => "cando_w3_w4_res_int_branch") & ((("cando_w4_w3_req_unit" & "cando_w4_w3_branch") => "cando_w4_w3_req_unit_branch") & ((("cando_w4_w5_err_unit" & "cando_w4_w5_branch") => "cando_w4_w5_err_unit_branch") & ((("cando_w4_w5_res_int" & "cando_w4_w5_branch") => "cando_w4_w5_res_int_branch") & ((("cando_w5_w4_req_unit" & "cando_w5_w4_branch") => "cando_w5_w4_req_unit_branch") & ((("cando_w5_w6_err_unit" & "cando_w5_w6_branch") => "cando_w5_w6_err_unit_branch") & ((("cando_w5_w6_res_int" & "cando_w5_w6_branch") => "cando_w5_w6_res_int_branch") & ((("cando_w6_w5_req_unit" & "cando_w6_w5_branch") => "cando_w6_w5_req_unit_branch") & ((("cando_w6_w7_err_unit" & "cando_w6_w7_branch") => "cando_w6_w7_err_unit_branch") & ((("cando_w6_w7_res_int" & "cando_w6_w7_branch") => "cando_w6_w7_res_int_branch") & ((("cando_w7_w6_req_unit" & "cando_w7_w6_branch") => "cando_w7_w6_req_unit_branch") & ((("cando_w7_w8_err_unit" & "cando_w7_w8_branch") => "cando_w7_w8_err_unit_branch") & ((("cando_w7_w8_res_int" & "cando_w7_w8_branch") => "cando_w7_w8_res_int_branch") & ((("cando_w8_w7_req_unit" & "cando_w8_w7_branch") => "cando_w8_w7_req_unit_branch") & ((("cando_w8_w9_err_unit" & "cando_w8_w9_branch") => "cando_w8_w9_err_unit_branch") & ((("cando_w8_w9_res_int" & "cando_w8_w9_branch") => "cando_w8_w9_res_int_branch") & ((("cando_w9_w10_err_unit" & "cando_w9_w10_branch") => "cando_w9_w10_err_unit_branch") & ((("cando_w9_w10_res_int" & "cando_w9_w10_branch") => "cando_w9_w10_res_int_branch") & (("cando_w9_w8_req_unit" & "cando_w9_w8_branch") => "cando_w9_w8_req_unit_branch"))))))))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 6.835937500000444E-4 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 9.490753294647832E-4
  
  Probabilistic termination
  Result: 0.7195898437499999 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9990509246705352
  
  
  
  
   ======= TEST ../examples/fact_12.ctx =======
  
  w0 : mu t .
       w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }
  
  w1 : mu t . w2 & req .
              w0 (+) req .
              w0 & {
                 res(Int) . w2 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w2 (+) err . t
              }
  
  w2 : mu t . w3 & req .
              w1 (+) req .
              w1 & {
                 res(Int) . w3 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w3 (+) err . t
              }
  
  w3 : mu t . w4 & req .
              w2 (+) req .
              w2 & {
                 res(Int) . w4 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w4 (+) err . t
              }
  
  w4 : mu t . w5 & req .
              w3 (+) req .
              w3 & {
                 res(Int) . w5 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w5 (+) err . t
              }
  
  w5 : mu t . w6 & req .
              w4 (+) req .
              w4 & {
                 res(Int) . w6 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w6 (+) err . t
              }
  
  w6 : mu t . w7 & req .
              w5 (+) req .
              w5 & {
                 res(Int) . w7 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w7 (+) err . t
              }
  
  w7 : mu t . w8 & req .
              w6 (+) req .
              w6 & {
                 res(Int) . w8 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w8 (+) err . t
              }
  
  w8 : mu t . w9 & req .
              w7 (+) req .
              w7 & {
                 res(Int) . w9 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w9 (+) err . t
              }
  
  w9 : mu t . w10 & req .
              w8 (+) req .
              w8 & {
                 res(Int) . w10 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w10 (+) err . t
              }
  
  w10 : mu t . w11 & req .
              w9 (+) req .
              w9 & {
                 res(Int) . w11 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w11 (+) err . t
              }
  
  w11 : mu t . w12 & req .
              w10 (+) req .
              w10 & {
                 res(Int) . w12 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w12 (+) err . t
              }
  
  w12 : w11 (+) req .
       w11 & {
          res(Int) . mu t . dummy (+) done . t,
          err . end
       }
  
  dummy : mu t . w12 & done . t
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..6] init 0;
  
    [] (w0=6) & (fail=false) -> 1:(fail'=true);
    [w1_w0] (w0=0) & (fail=false) -> 1:(w0'=1);
    [w1_w0_req_unit] (w0=1) & (fail=false) -> 1:(w0'=2);
    [w0_w1] (w0=2) & (fail=false) -> 0:(w0'=6) + 0.7:(w0'=3) + 0.3:(w0'=4);
    [w0_w1_res_int] (w0=3) & (fail=false) -> 1:(w0'=0);
    [w0_w1_err_unit] (w0=4) & (fail=false) -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..12] init 0;
  
    [] (w1=12) & (fail=false) -> 1:(fail'=true);
    [w2_w1] (w1=0) & (fail=false) -> 1:(w1'=1);
    [w2_w1_req_unit] (w1=1) & (fail=false) -> 1:(w1'=2);
    [w1_w0] (w1=2) & (fail=false) -> 0:(w1'=12) + 1:(w1'=3);
    [w1_w0_req_unit] (w1=3) & (fail=false) -> 1:(w1'=4);
    [w0_w1] (w1=4) & (fail=false) -> 1:(w1'=5);
    [w0_w1_res_int] (w1=5) & (fail=false) -> 1:(w1'=6);
    [w0_w1_err_unit] (w1=5) & (fail=false) -> 1:(w1'=9);
    [w1_w2] (w1=6) & (fail=false) -> 0.2:(w1'=12) + 0.5:(w1'=7) + 0.3:(w1'=8);
    [w1_w2_res_int] (w1=7) & (fail=false) -> 1:(w1'=0);
    [w1_w2_err_unit] (w1=8) & (fail=false) -> 1:(w1'=0);
    [w1_w2] (w1=9) & (fail=false) -> 0:(w1'=12) + 1:(w1'=10);
    [w1_w2_err_unit] (w1=10) & (fail=false) -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..12] init 0;
  
    [] (w2=12) & (fail=false) -> 1:(fail'=true);
    [w3_w2] (w2=0) & (fail=false) -> 1:(w2'=1);
    [w3_w2_req_unit] (w2=1) & (fail=false) -> 1:(w2'=2);
    [w2_w1] (w2=2) & (fail=false) -> 0:(w2'=12) + 1:(w2'=3);
    [w2_w1_req_unit] (w2=3) & (fail=false) -> 1:(w2'=4);
    [w1_w2] (w2=4) & (fail=false) -> 1:(w2'=5);
    [w1_w2_res_int] (w2=5) & (fail=false) -> 1:(w2'=6);
    [w1_w2_err_unit] (w2=5) & (fail=false) -> 1:(w2'=9);
    [w2_w3] (w2=6) & (fail=false) -> 0.2:(w2'=12) + 0.5:(w2'=7) + 0.3:(w2'=8);
    [w2_w3_res_int] (w2=7) & (fail=false) -> 1:(w2'=0);
    [w2_w3_err_unit] (w2=8) & (fail=false) -> 1:(w2'=0);
    [w2_w3] (w2=9) & (fail=false) -> 0:(w2'=12) + 1:(w2'=10);
    [w2_w3_err_unit] (w2=10) & (fail=false) -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..12] init 0;
  
    [] (w3=12) & (fail=false) -> 1:(fail'=true);
    [w4_w3] (w3=0) & (fail=false) -> 1:(w3'=1);
    [w4_w3_req_unit] (w3=1) & (fail=false) -> 1:(w3'=2);
    [w3_w2] (w3=2) & (fail=false) -> 0:(w3'=12) + 1:(w3'=3);
    [w3_w2_req_unit] (w3=3) & (fail=false) -> 1:(w3'=4);
    [w2_w3] (w3=4) & (fail=false) -> 1:(w3'=5);
    [w2_w3_res_int] (w3=5) & (fail=false) -> 1:(w3'=6);
    [w2_w3_err_unit] (w3=5) & (fail=false) -> 1:(w3'=9);
    [w3_w4] (w3=6) & (fail=false) -> 0.2:(w3'=12) + 0.5:(w3'=7) + 0.3:(w3'=8);
    [w3_w4_res_int] (w3=7) & (fail=false) -> 1:(w3'=0);
    [w3_w4_err_unit] (w3=8) & (fail=false) -> 1:(w3'=0);
    [w3_w4] (w3=9) & (fail=false) -> 0:(w3'=12) + 1:(w3'=10);
    [w3_w4_err_unit] (w3=10) & (fail=false) -> 1:(w3'=0);
  endmodule
  
  module w4
    w4 : [0..12] init 0;
  
    [] (w4=12) & (fail=false) -> 1:(fail'=true);
    [w5_w4] (w4=0) & (fail=false) -> 1:(w4'=1);
    [w5_w4_req_unit] (w4=1) & (fail=false) -> 1:(w4'=2);
    [w4_w3] (w4=2) & (fail=false) -> 0:(w4'=12) + 1:(w4'=3);
    [w4_w3_req_unit] (w4=3) & (fail=false) -> 1:(w4'=4);
    [w3_w4] (w4=4) & (fail=false) -> 1:(w4'=5);
    [w3_w4_res_int] (w4=5) & (fail=false) -> 1:(w4'=6);
    [w3_w4_err_unit] (w4=5) & (fail=false) -> 1:(w4'=9);
    [w4_w5] (w4=6) & (fail=false) -> 0.2:(w4'=12) + 0.5:(w4'=7) + 0.3:(w4'=8);
    [w4_w5_res_int] (w4=7) & (fail=false) -> 1:(w4'=0);
    [w4_w5_err_unit] (w4=8) & (fail=false) -> 1:(w4'=0);
    [w4_w5] (w4=9) & (fail=false) -> 0:(w4'=12) + 1:(w4'=10);
    [w4_w5_err_unit] (w4=10) & (fail=false) -> 1:(w4'=0);
  endmodule
  
  module w5
    w5 : [0..12] init 0;
  
    [] (w5=12) & (fail=false) -> 1:(fail'=true);
    [w6_w5] (w5=0) & (fail=false) -> 1:(w5'=1);
    [w6_w5_req_unit] (w5=1) & (fail=false) -> 1:(w5'=2);
    [w5_w4] (w5=2) & (fail=false) -> 0:(w5'=12) + 1:(w5'=3);
    [w5_w4_req_unit] (w5=3) & (fail=false) -> 1:(w5'=4);
    [w4_w5] (w5=4) & (fail=false) -> 1:(w5'=5);
    [w4_w5_res_int] (w5=5) & (fail=false) -> 1:(w5'=6);
    [w4_w5_err_unit] (w5=5) & (fail=false) -> 1:(w5'=9);
    [w5_w6] (w5=6) & (fail=false) -> 0.2:(w5'=12) + 0.5:(w5'=7) + 0.3:(w5'=8);
    [w5_w6_res_int] (w5=7) & (fail=false) -> 1:(w5'=0);
    [w5_w6_err_unit] (w5=8) & (fail=false) -> 1:(w5'=0);
    [w5_w6] (w5=9) & (fail=false) -> 0:(w5'=12) + 1:(w5'=10);
    [w5_w6_err_unit] (w5=10) & (fail=false) -> 1:(w5'=0);
  endmodule
  
  module w6
    w6 : [0..12] init 0;
  
    [] (w6=12) & (fail=false) -> 1:(fail'=true);
    [w7_w6] (w6=0) & (fail=false) -> 1:(w6'=1);
    [w7_w6_req_unit] (w6=1) & (fail=false) -> 1:(w6'=2);
    [w6_w5] (w6=2) & (fail=false) -> 0:(w6'=12) + 1:(w6'=3);
    [w6_w5_req_unit] (w6=3) & (fail=false) -> 1:(w6'=4);
    [w5_w6] (w6=4) & (fail=false) -> 1:(w6'=5);
    [w5_w6_res_int] (w6=5) & (fail=false) -> 1:(w6'=6);
    [w5_w6_err_unit] (w6=5) & (fail=false) -> 1:(w6'=9);
    [w6_w7] (w6=6) & (fail=false) -> 0.2:(w6'=12) + 0.5:(w6'=7) + 0.3:(w6'=8);
    [w6_w7_res_int] (w6=7) & (fail=false) -> 1:(w6'=0);
    [w6_w7_err_unit] (w6=8) & (fail=false) -> 1:(w6'=0);
    [w6_w7] (w6=9) & (fail=false) -> 0:(w6'=12) + 1:(w6'=10);
    [w6_w7_err_unit] (w6=10) & (fail=false) -> 1:(w6'=0);
  endmodule
  
  module w7
    w7 : [0..12] init 0;
  
    [] (w7=12) & (fail=false) -> 1:(fail'=true);
    [w8_w7] (w7=0) & (fail=false) -> 1:(w7'=1);
    [w8_w7_req_unit] (w7=1) & (fail=false) -> 1:(w7'=2);
    [w7_w6] (w7=2) & (fail=false) -> 0:(w7'=12) + 1:(w7'=3);
    [w7_w6_req_unit] (w7=3) & (fail=false) -> 1:(w7'=4);
    [w6_w7] (w7=4) & (fail=false) -> 1:(w7'=5);
    [w6_w7_res_int] (w7=5) & (fail=false) -> 1:(w7'=6);
    [w6_w7_err_unit] (w7=5) & (fail=false) -> 1:(w7'=9);
    [w7_w8] (w7=6) & (fail=false) -> 0.2:(w7'=12) + 0.5:(w7'=7) + 0.3:(w7'=8);
    [w7_w8_res_int] (w7=7) & (fail=false) -> 1:(w7'=0);
    [w7_w8_err_unit] (w7=8) & (fail=false) -> 1:(w7'=0);
    [w7_w8] (w7=9) & (fail=false) -> 0:(w7'=12) + 1:(w7'=10);
    [w7_w8_err_unit] (w7=10) & (fail=false) -> 1:(w7'=0);
  endmodule
  
  module w8
    w8 : [0..12] init 0;
  
    [] (w8=12) & (fail=false) -> 1:(fail'=true);
    [w9_w8] (w8=0) & (fail=false) -> 1:(w8'=1);
    [w9_w8_req_unit] (w8=1) & (fail=false) -> 1:(w8'=2);
    [w8_w7] (w8=2) & (fail=false) -> 0:(w8'=12) + 1:(w8'=3);
    [w8_w7_req_unit] (w8=3) & (fail=false) -> 1:(w8'=4);
    [w7_w8] (w8=4) & (fail=false) -> 1:(w8'=5);
    [w7_w8_res_int] (w8=5) & (fail=false) -> 1:(w8'=6);
    [w7_w8_err_unit] (w8=5) & (fail=false) -> 1:(w8'=9);
    [w8_w9] (w8=6) & (fail=false) -> 0.2:(w8'=12) + 0.5:(w8'=7) + 0.3:(w8'=8);
    [w8_w9_res_int] (w8=7) & (fail=false) -> 1:(w8'=0);
    [w8_w9_err_unit] (w8=8) & (fail=false) -> 1:(w8'=0);
    [w8_w9] (w8=9) & (fail=false) -> 0:(w8'=12) + 1:(w8'=10);
    [w8_w9_err_unit] (w8=10) & (fail=false) -> 1:(w8'=0);
  endmodule
  
  module w9
    w9 : [0..12] init 0;
  
    [] (w9=12) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w9=0) & (fail=false) -> 1:(w9'=1);
    [w10_w9_req_unit] (w9=1) & (fail=false) -> 1:(w9'=2);
    [w9_w8] (w9=2) & (fail=false) -> 0:(w9'=12) + 1:(w9'=3);
    [w9_w8_req_unit] (w9=3) & (fail=false) -> 1:(w9'=4);
    [w8_w9] (w9=4) & (fail=false) -> 1:(w9'=5);
    [w8_w9_res_int] (w9=5) & (fail=false) -> 1:(w9'=6);
    [w8_w9_err_unit] (w9=5) & (fail=false) -> 1:(w9'=9);
    [w9_w10] (w9=6) & (fail=false) -> 0.2:(w9'=12) + 0.5:(w9'=7) + 0.3:(w9'=8);
    [w9_w10_res_int] (w9=7) & (fail=false) -> 1:(w9'=0);
    [w9_w10_err_unit] (w9=8) & (fail=false) -> 1:(w9'=0);
    [w9_w10] (w9=9) & (fail=false) -> 0:(w9'=12) + 1:(w9'=10);
    [w9_w10_err_unit] (w9=10) & (fail=false) -> 1:(w9'=0);
  endmodule
  
  module w10
    w10 : [0..12] init 0;
  
    [] (w10=12) & (fail=false) -> 1:(fail'=true);
    [w11_w10] (w10=0) & (fail=false) -> 1:(w10'=1);
    [w11_w10_req_unit] (w10=1) & (fail=false) -> 1:(w10'=2);
    [w10_w9] (w10=2) & (fail=false) -> 0:(w10'=12) + 1:(w10'=3);
    [w10_w9_req_unit] (w10=3) & (fail=false) -> 1:(w10'=4);
    [w9_w10] (w10=4) & (fail=false) -> 1:(w10'=5);
    [w9_w10_res_int] (w10=5) & (fail=false) -> 1:(w10'=6);
    [w9_w10_err_unit] (w10=5) & (fail=false) -> 1:(w10'=9);
    [w10_w11] (w10=6) & (fail=false) -> 0.2:(w10'=12) + 0.5:(w10'=7) + 0.3:(w10'=8);
    [w10_w11_res_int] (w10=7) & (fail=false) -> 1:(w10'=0);
    [w10_w11_err_unit] (w10=8) & (fail=false) -> 1:(w10'=0);
    [w10_w11] (w10=9) & (fail=false) -> 0:(w10'=12) + 1:(w10'=10);
    [w10_w11_err_unit] (w10=10) & (fail=false) -> 1:(w10'=0);
  endmodule
  
  module w11
    w11 : [0..12] init 0;
  
    [] (w11=12) & (fail=false) -> 1:(fail'=true);
    [w12_w11] (w11=0) & (fail=false) -> 1:(w11'=1);
    [w12_w11_req_unit] (w11=1) & (fail=false) -> 1:(w11'=2);
    [w11_w10] (w11=2) & (fail=false) -> 0:(w11'=12) + 1:(w11'=3);
    [w11_w10_req_unit] (w11=3) & (fail=false) -> 1:(w11'=4);
    [w10_w11] (w11=4) & (fail=false) -> 1:(w11'=5);
    [w10_w11_res_int] (w11=5) & (fail=false) -> 1:(w11'=6);
    [w10_w11_err_unit] (w11=5) & (fail=false) -> 1:(w11'=9);
    [w11_w12] (w11=6) & (fail=false) -> 0.2:(w11'=12) + 0.5:(w11'=7) + 0.3:(w11'=8);
    [w11_w12_res_int] (w11=7) & (fail=false) -> 1:(w11'=0);
    [w11_w12_err_unit] (w11=8) & (fail=false) -> 1:(w11'=0);
    [w11_w12] (w11=9) & (fail=false) -> 0:(w11'=12) + 1:(w11'=10);
    [w11_w12_err_unit] (w11=10) & (fail=false) -> 1:(w11'=0);
  endmodule
  
  module w12
    w12 : [0..7] init 0;
  
    [] (w12=7) & (fail=false) -> 1:(fail'=true);
    [w12_w11] (w12=0) & (fail=false) -> 0:(w12'=7) + 1:(w12'=1);
    [w12_w11_req_unit] (w12=1) & (fail=false) -> 1:(w12'=2);
    [w11_w12] (w12=2) & (fail=false) -> 1:(w12'=3);
    [w11_w12_res_int] (w12=3) & (fail=false) -> 1:(w12'=4);
    [w11_w12_err_unit] (w12=3) & (fail=false) -> 1:(w12'=6);
    [w12_dummy] (w12=4) & (fail=false) -> 0:(w12'=7) + 1:(w12'=5);
    [w12_dummy_done_unit] (w12=5) & (fail=false) -> 1:(w12'=4);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [w12_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [w12_dummy_done_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=5) & (w1=11) & (w2=11) & (w3=11) & (w4=11) & (w5=11) & (w6=11) & (w7=11) & (w8=11) & (w9=11) & (w10=11) & (w11=11) & (w12=6) & (dummy=2);
  label "cando_w0_w1_err_unit" = w0=2;
  label "cando_w0_w1_err_unit_branch" = w1=4;
  label "cando_w0_w1_res_int" = w0=2;
  label "cando_w0_w1_res_int_branch" = w1=4;
  label "cando_w1_w0_req_unit" = w1=2;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=6) | (w1=9);
  label "cando_w1_w2_err_unit_branch" = w2=4;
  label "cando_w1_w2_res_int" = w1=6;
  label "cando_w1_w2_res_int_branch" = w2=4;
  label "cando_w10_w11_err_unit" = (w10=6) | (w10=9);
  label "cando_w10_w11_err_unit_branch" = w11=4;
  label "cando_w10_w11_res_int" = w10=6;
  label "cando_w10_w11_res_int_branch" = w11=4;
  label "cando_w10_w9_req_unit" = w10=2;
  label "cando_w10_w9_req_unit_branch" = w9=0;
  label "cando_w11_w10_req_unit" = w11=2;
  label "cando_w11_w10_req_unit_branch" = w10=0;
  label "cando_w11_w12_err_unit" = (w11=6) | (w11=9);
  label "cando_w11_w12_err_unit_branch" = w12=2;
  label "cando_w11_w12_res_int" = w11=6;
  label "cando_w11_w12_res_int_branch" = w12=2;
  label "cando_w12_dummy_done_unit" = w12=4;
  label "cando_w12_dummy_done_unit_branch" = dummy=0;
  label "cando_w12_w11_req_unit" = w12=0;
  label "cando_w12_w11_req_unit_branch" = w11=0;
  label "cando_w2_w1_req_unit" = w2=2;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=6) | (w2=9);
  label "cando_w2_w3_err_unit_branch" = w3=4;
  label "cando_w2_w3_res_int" = w2=6;
  label "cando_w2_w3_res_int_branch" = w3=4;
  label "cando_w3_w2_req_unit" = w3=2;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w3_w4_err_unit" = (w3=6) | (w3=9);
  label "cando_w3_w4_err_unit_branch" = w4=4;
  label "cando_w3_w4_res_int" = w3=6;
  label "cando_w3_w4_res_int_branch" = w4=4;
  label "cando_w4_w3_req_unit" = w4=2;
  label "cando_w4_w3_req_unit_branch" = w3=0;
  label "cando_w4_w5_err_unit" = (w4=6) | (w4=9);
  label "cando_w4_w5_err_unit_branch" = w5=4;
  label "cando_w4_w5_res_int" = w4=6;
  label "cando_w4_w5_res_int_branch" = w5=4;
  label "cando_w5_w4_req_unit" = w5=2;
  label "cando_w5_w4_req_unit_branch" = w4=0;
  label "cando_w5_w6_err_unit" = (w5=6) | (w5=9);
  label "cando_w5_w6_err_unit_branch" = w6=4;
  label "cando_w5_w6_res_int" = w5=6;
  label "cando_w5_w6_res_int_branch" = w6=4;
  label "cando_w6_w5_req_unit" = w6=2;
  label "cando_w6_w5_req_unit_branch" = w5=0;
  label "cando_w6_w7_err_unit" = (w6=6) | (w6=9);
  label "cando_w6_w7_err_unit_branch" = w7=4;
  label "cando_w6_w7_res_int" = w6=6;
  label "cando_w6_w7_res_int_branch" = w7=4;
  label "cando_w7_w6_req_unit" = w7=2;
  label "cando_w7_w6_req_unit_branch" = w6=0;
  label "cando_w7_w8_err_unit" = (w7=6) | (w7=9);
  label "cando_w7_w8_err_unit_branch" = w8=4;
  label "cando_w7_w8_res_int" = w7=6;
  label "cando_w7_w8_res_int_branch" = w8=4;
  label "cando_w8_w7_req_unit" = w8=2;
  label "cando_w8_w7_req_unit_branch" = w7=0;
  label "cando_w8_w9_err_unit" = (w8=6) | (w8=9);
  label "cando_w8_w9_err_unit_branch" = w9=4;
  label "cando_w8_w9_res_int" = w8=6;
  label "cando_w8_w9_res_int_branch" = w9=4;
  label "cando_w9_w10_err_unit" = (w9=6) | (w9=9);
  label "cando_w9_w10_err_unit_branch" = w10=4;
  label "cando_w9_w10_res_int" = w9=6;
  label "cando_w9_w10_res_int_branch" = w10=4;
  label "cando_w9_w8_req_unit" = w9=2;
  label "cando_w9_w8_req_unit_branch" = w8=0;
  label "cando_w0_w1_branch" = w1=4;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=4;
  label "cando_w10_w11_branch" = w11=4;
  label "cando_w10_w9_branch" = w9=0;
  label "cando_w11_w10_branch" = w10=0;
  label "cando_w11_w12_branch" = w12=2;
  label "cando_w12_dummy_branch" = dummy=0;
  label "cando_w12_w11_branch" = w11=0;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=4;
  label "cando_w3_w2_branch" = w2=0;
  label "cando_w3_w4_branch" = w4=4;
  label "cando_w4_w3_branch" = w3=0;
  label "cando_w4_w5_branch" = w5=4;
  label "cando_w5_w4_branch" = w4=0;
  label "cando_w5_w6_branch" = w6=4;
  label "cando_w6_w5_branch" = w5=0;
  label "cando_w6_w7_branch" = w7=4;
  label "cando_w7_w6_branch" = w6=0;
  label "cando_w7_w8_branch" = w8=4;
  label "cando_w8_w7_branch" = w7=0;
  label "cando_w8_w9_branch" = w9=4;
  label "cando_w9_w10_branch" = w10=4;
  label "cando_w9_w8_branch" = w8=0;
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w10_w11_err_unit" & "cando_w10_w11_branch") => "cando_w10_w11_err_unit_branch") & ((("cando_w10_w11_res_int" & "cando_w10_w11_branch") => "cando_w10_w11_res_int_branch") & ((("cando_w10_w9_req_unit" & "cando_w10_w9_branch") => "cando_w10_w9_req_unit_branch") & ((("cando_w11_w10_req_unit" & "cando_w11_w10_branch") => "cando_w11_w10_req_unit_branch") & ((("cando_w11_w12_err_unit" & "cando_w11_w12_branch") => "cando_w11_w12_err_unit_branch") & ((("cando_w11_w12_res_int" & "cando_w11_w12_branch") => "cando_w11_w12_res_int_branch") & ((("cando_w12_dummy_done_unit" & "cando_w12_dummy_branch") => "cando_w12_dummy_done_unit_branch") & ((("cando_w12_w11_req_unit" & "cando_w12_w11_branch") => "cando_w12_w11_req_unit_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch") & ((("cando_w3_w4_err_unit" & "cando_w3_w4_branch") => "cando_w3_w4_err_unit_branch") & ((("cando_w3_w4_res_int" & "cando_w3_w4_branch") => "cando_w3_w4_res_int_branch") & ((("cando_w4_w3_req_unit" & "cando_w4_w3_branch") => "cando_w4_w3_req_unit_branch") & ((("cando_w4_w5_err_unit" & "cando_w4_w5_branch") => "cando_w4_w5_err_unit_branch") & ((("cando_w4_w5_res_int" & "cando_w4_w5_branch") => "cando_w4_w5_res_int_branch") & ((("cando_w5_w4_req_unit" & "cando_w5_w4_branch") => "cando_w5_w4_req_unit_branch") & ((("cando_w5_w6_err_unit" & "cando_w5_w6_branch") => "cando_w5_w6_err_unit_branch") & ((("cando_w5_w6_res_int" & "cando_w5_w6_branch") => "cando_w5_w6_res_int_branch") & ((("cando_w6_w5_req_unit" & "cando_w6_w5_branch") => "cando_w6_w5_req_unit_branch") & ((("cando_w6_w7_err_unit" & "cando_w6_w7_branch") => "cando_w6_w7_err_unit_branch") & ((("cando_w6_w7_res_int" & "cando_w6_w7_branch") => "cando_w6_w7_res_int_branch") & ((("cando_w7_w6_req_unit" & "cando_w7_w6_branch") => "cando_w7_w6_req_unit_branch") & ((("cando_w7_w8_err_unit" & "cando_w7_w8_branch") => "cando_w7_w8_err_unit_branch") & ((("cando_w7_w8_res_int" & "cando_w7_w8_branch") => "cando_w7_w8_res_int_branch") & ((("cando_w8_w7_req_unit" & "cando_w8_w7_branch") => "cando_w8_w7_req_unit_branch") & ((("cando_w8_w9_err_unit" & "cando_w8_w9_branch") => "cando_w8_w9_err_unit_branch") & ((("cando_w8_w9_res_int" & "cando_w8_w9_branch") => "cando_w8_w9_res_int_branch") & ((("cando_w9_w10_err_unit" & "cando_w9_w10_branch") => "cando_w9_w10_err_unit_branch") & ((("cando_w9_w10_res_int" & "cando_w9_w10_branch") => "cando_w9_w10_res_int_branch") & (("cando_w9_w8_req_unit" & "cando_w9_w8_branch") => "cando_w9_w8_req_unit_branch")))))))))))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 3.417968750001332E-4 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 4.7462775623136934E-4
  
  Probabilistic termination
  Result: 0.7197949218749999 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9995253722437686
  
  
  
  
   ======= TEST ../examples/fact_13.ctx =======
  
  w0 : mu t .
       w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }
  
  w1 : mu t . w2 & req .
              w0 (+) req .
              w0 & {
                 res(Int) . w2 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w2 (+) err . t
              }
  
  w2 : mu t . w3 & req .
              w1 (+) req .
              w1 & {
                 res(Int) . w3 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w3 (+) err . t
              }
  
  w3 : mu t . w4 & req .
              w2 (+) req .
              w2 & {
                 res(Int) . w4 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w4 (+) err . t
              }
  
  w4 : mu t . w5 & req .
              w3 (+) req .
              w3 & {
                 res(Int) . w5 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w5 (+) err . t
              }
  
  w5 : mu t . w6 & req .
              w4 (+) req .
              w4 & {
                 res(Int) . w6 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w6 (+) err . t
              }
  
  w6 : mu t . w7 & req .
              w5 (+) req .
              w5 & {
                 res(Int) . w7 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w7 (+) err . t
              }
  
  w7 : mu t . w8 & req .
              w6 (+) req .
              w6 & {
                 res(Int) . w8 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w8 (+) err . t
              }
  
  w8 : mu t . w9 & req .
              w7 (+) req .
              w7 & {
                 res(Int) . w9 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w9 (+) err . t
              }
  
  w9 : mu t . w10 & req .
              w8 (+) req .
              w8 & {
                 res(Int) . w10 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w10 (+) err . t
              }
  
  w10 : mu t . w11 & req .
              w9 (+) req .
              w9 & {
                 res(Int) . w11 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w11 (+) err . t
              }
  
  w11 : mu t . w12 & req .
              w10 (+) req .
              w10 & {
                 res(Int) . w12 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w12 (+) err . t
              }
  
  w12 : mu t . w13 & req .
              w11 (+) req .
              w11 & {
                 res(Int) . w13 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w13 (+) err . t
              }
  
  w13 : w12 (+) req .
       w12 & {
          res(Int) . mu t . dummy (+) done . t,
          err . end
       }
  
  dummy : mu t . w13 & done . t
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..6] init 0;
  
    [] (w0=6) & (fail=false) -> 1:(fail'=true);
    [w1_w0] (w0=0) & (fail=false) -> 1:(w0'=1);
    [w1_w0_req_unit] (w0=1) & (fail=false) -> 1:(w0'=2);
    [w0_w1] (w0=2) & (fail=false) -> 0:(w0'=6) + 0.7:(w0'=3) + 0.3:(w0'=4);
    [w0_w1_res_int] (w0=3) & (fail=false) -> 1:(w0'=0);
    [w0_w1_err_unit] (w0=4) & (fail=false) -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..12] init 0;
  
    [] (w1=12) & (fail=false) -> 1:(fail'=true);
    [w2_w1] (w1=0) & (fail=false) -> 1:(w1'=1);
    [w2_w1_req_unit] (w1=1) & (fail=false) -> 1:(w1'=2);
    [w1_w0] (w1=2) & (fail=false) -> 0:(w1'=12) + 1:(w1'=3);
    [w1_w0_req_unit] (w1=3) & (fail=false) -> 1:(w1'=4);
    [w0_w1] (w1=4) & (fail=false) -> 1:(w1'=5);
    [w0_w1_res_int] (w1=5) & (fail=false) -> 1:(w1'=6);
    [w0_w1_err_unit] (w1=5) & (fail=false) -> 1:(w1'=9);
    [w1_w2] (w1=6) & (fail=false) -> 0.2:(w1'=12) + 0.5:(w1'=7) + 0.3:(w1'=8);
    [w1_w2_res_int] (w1=7) & (fail=false) -> 1:(w1'=0);
    [w1_w2_err_unit] (w1=8) & (fail=false) -> 1:(w1'=0);
    [w1_w2] (w1=9) & (fail=false) -> 0:(w1'=12) + 1:(w1'=10);
    [w1_w2_err_unit] (w1=10) & (fail=false) -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..12] init 0;
  
    [] (w2=12) & (fail=false) -> 1:(fail'=true);
    [w3_w2] (w2=0) & (fail=false) -> 1:(w2'=1);
    [w3_w2_req_unit] (w2=1) & (fail=false) -> 1:(w2'=2);
    [w2_w1] (w2=2) & (fail=false) -> 0:(w2'=12) + 1:(w2'=3);
    [w2_w1_req_unit] (w2=3) & (fail=false) -> 1:(w2'=4);
    [w1_w2] (w2=4) & (fail=false) -> 1:(w2'=5);
    [w1_w2_res_int] (w2=5) & (fail=false) -> 1:(w2'=6);
    [w1_w2_err_unit] (w2=5) & (fail=false) -> 1:(w2'=9);
    [w2_w3] (w2=6) & (fail=false) -> 0.2:(w2'=12) + 0.5:(w2'=7) + 0.3:(w2'=8);
    [w2_w3_res_int] (w2=7) & (fail=false) -> 1:(w2'=0);
    [w2_w3_err_unit] (w2=8) & (fail=false) -> 1:(w2'=0);
    [w2_w3] (w2=9) & (fail=false) -> 0:(w2'=12) + 1:(w2'=10);
    [w2_w3_err_unit] (w2=10) & (fail=false) -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..12] init 0;
  
    [] (w3=12) & (fail=false) -> 1:(fail'=true);
    [w4_w3] (w3=0) & (fail=false) -> 1:(w3'=1);
    [w4_w3_req_unit] (w3=1) & (fail=false) -> 1:(w3'=2);
    [w3_w2] (w3=2) & (fail=false) -> 0:(w3'=12) + 1:(w3'=3);
    [w3_w2_req_unit] (w3=3) & (fail=false) -> 1:(w3'=4);
    [w2_w3] (w3=4) & (fail=false) -> 1:(w3'=5);
    [w2_w3_res_int] (w3=5) & (fail=false) -> 1:(w3'=6);
    [w2_w3_err_unit] (w3=5) & (fail=false) -> 1:(w3'=9);
    [w3_w4] (w3=6) & (fail=false) -> 0.2:(w3'=12) + 0.5:(w3'=7) + 0.3:(w3'=8);
    [w3_w4_res_int] (w3=7) & (fail=false) -> 1:(w3'=0);
    [w3_w4_err_unit] (w3=8) & (fail=false) -> 1:(w3'=0);
    [w3_w4] (w3=9) & (fail=false) -> 0:(w3'=12) + 1:(w3'=10);
    [w3_w4_err_unit] (w3=10) & (fail=false) -> 1:(w3'=0);
  endmodule
  
  module w4
    w4 : [0..12] init 0;
  
    [] (w4=12) & (fail=false) -> 1:(fail'=true);
    [w5_w4] (w4=0) & (fail=false) -> 1:(w4'=1);
    [w5_w4_req_unit] (w4=1) & (fail=false) -> 1:(w4'=2);
    [w4_w3] (w4=2) & (fail=false) -> 0:(w4'=12) + 1:(w4'=3);
    [w4_w3_req_unit] (w4=3) & (fail=false) -> 1:(w4'=4);
    [w3_w4] (w4=4) & (fail=false) -> 1:(w4'=5);
    [w3_w4_res_int] (w4=5) & (fail=false) -> 1:(w4'=6);
    [w3_w4_err_unit] (w4=5) & (fail=false) -> 1:(w4'=9);
    [w4_w5] (w4=6) & (fail=false) -> 0.2:(w4'=12) + 0.5:(w4'=7) + 0.3:(w4'=8);
    [w4_w5_res_int] (w4=7) & (fail=false) -> 1:(w4'=0);
    [w4_w5_err_unit] (w4=8) & (fail=false) -> 1:(w4'=0);
    [w4_w5] (w4=9) & (fail=false) -> 0:(w4'=12) + 1:(w4'=10);
    [w4_w5_err_unit] (w4=10) & (fail=false) -> 1:(w4'=0);
  endmodule
  
  module w5
    w5 : [0..12] init 0;
  
    [] (w5=12) & (fail=false) -> 1:(fail'=true);
    [w6_w5] (w5=0) & (fail=false) -> 1:(w5'=1);
    [w6_w5_req_unit] (w5=1) & (fail=false) -> 1:(w5'=2);
    [w5_w4] (w5=2) & (fail=false) -> 0:(w5'=12) + 1:(w5'=3);
    [w5_w4_req_unit] (w5=3) & (fail=false) -> 1:(w5'=4);
    [w4_w5] (w5=4) & (fail=false) -> 1:(w5'=5);
    [w4_w5_res_int] (w5=5) & (fail=false) -> 1:(w5'=6);
    [w4_w5_err_unit] (w5=5) & (fail=false) -> 1:(w5'=9);
    [w5_w6] (w5=6) & (fail=false) -> 0.2:(w5'=12) + 0.5:(w5'=7) + 0.3:(w5'=8);
    [w5_w6_res_int] (w5=7) & (fail=false) -> 1:(w5'=0);
    [w5_w6_err_unit] (w5=8) & (fail=false) -> 1:(w5'=0);
    [w5_w6] (w5=9) & (fail=false) -> 0:(w5'=12) + 1:(w5'=10);
    [w5_w6_err_unit] (w5=10) & (fail=false) -> 1:(w5'=0);
  endmodule
  
  module w6
    w6 : [0..12] init 0;
  
    [] (w6=12) & (fail=false) -> 1:(fail'=true);
    [w7_w6] (w6=0) & (fail=false) -> 1:(w6'=1);
    [w7_w6_req_unit] (w6=1) & (fail=false) -> 1:(w6'=2);
    [w6_w5] (w6=2) & (fail=false) -> 0:(w6'=12) + 1:(w6'=3);
    [w6_w5_req_unit] (w6=3) & (fail=false) -> 1:(w6'=4);
    [w5_w6] (w6=4) & (fail=false) -> 1:(w6'=5);
    [w5_w6_res_int] (w6=5) & (fail=false) -> 1:(w6'=6);
    [w5_w6_err_unit] (w6=5) & (fail=false) -> 1:(w6'=9);
    [w6_w7] (w6=6) & (fail=false) -> 0.2:(w6'=12) + 0.5:(w6'=7) + 0.3:(w6'=8);
    [w6_w7_res_int] (w6=7) & (fail=false) -> 1:(w6'=0);
    [w6_w7_err_unit] (w6=8) & (fail=false) -> 1:(w6'=0);
    [w6_w7] (w6=9) & (fail=false) -> 0:(w6'=12) + 1:(w6'=10);
    [w6_w7_err_unit] (w6=10) & (fail=false) -> 1:(w6'=0);
  endmodule
  
  module w7
    w7 : [0..12] init 0;
  
    [] (w7=12) & (fail=false) -> 1:(fail'=true);
    [w8_w7] (w7=0) & (fail=false) -> 1:(w7'=1);
    [w8_w7_req_unit] (w7=1) & (fail=false) -> 1:(w7'=2);
    [w7_w6] (w7=2) & (fail=false) -> 0:(w7'=12) + 1:(w7'=3);
    [w7_w6_req_unit] (w7=3) & (fail=false) -> 1:(w7'=4);
    [w6_w7] (w7=4) & (fail=false) -> 1:(w7'=5);
    [w6_w7_res_int] (w7=5) & (fail=false) -> 1:(w7'=6);
    [w6_w7_err_unit] (w7=5) & (fail=false) -> 1:(w7'=9);
    [w7_w8] (w7=6) & (fail=false) -> 0.2:(w7'=12) + 0.5:(w7'=7) + 0.3:(w7'=8);
    [w7_w8_res_int] (w7=7) & (fail=false) -> 1:(w7'=0);
    [w7_w8_err_unit] (w7=8) & (fail=false) -> 1:(w7'=0);
    [w7_w8] (w7=9) & (fail=false) -> 0:(w7'=12) + 1:(w7'=10);
    [w7_w8_err_unit] (w7=10) & (fail=false) -> 1:(w7'=0);
  endmodule
  
  module w8
    w8 : [0..12] init 0;
  
    [] (w8=12) & (fail=false) -> 1:(fail'=true);
    [w9_w8] (w8=0) & (fail=false) -> 1:(w8'=1);
    [w9_w8_req_unit] (w8=1) & (fail=false) -> 1:(w8'=2);
    [w8_w7] (w8=2) & (fail=false) -> 0:(w8'=12) + 1:(w8'=3);
    [w8_w7_req_unit] (w8=3) & (fail=false) -> 1:(w8'=4);
    [w7_w8] (w8=4) & (fail=false) -> 1:(w8'=5);
    [w7_w8_res_int] (w8=5) & (fail=false) -> 1:(w8'=6);
    [w7_w8_err_unit] (w8=5) & (fail=false) -> 1:(w8'=9);
    [w8_w9] (w8=6) & (fail=false) -> 0.2:(w8'=12) + 0.5:(w8'=7) + 0.3:(w8'=8);
    [w8_w9_res_int] (w8=7) & (fail=false) -> 1:(w8'=0);
    [w8_w9_err_unit] (w8=8) & (fail=false) -> 1:(w8'=0);
    [w8_w9] (w8=9) & (fail=false) -> 0:(w8'=12) + 1:(w8'=10);
    [w8_w9_err_unit] (w8=10) & (fail=false) -> 1:(w8'=0);
  endmodule
  
  module w9
    w9 : [0..12] init 0;
  
    [] (w9=12) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w9=0) & (fail=false) -> 1:(w9'=1);
    [w10_w9_req_unit] (w9=1) & (fail=false) -> 1:(w9'=2);
    [w9_w8] (w9=2) & (fail=false) -> 0:(w9'=12) + 1:(w9'=3);
    [w9_w8_req_unit] (w9=3) & (fail=false) -> 1:(w9'=4);
    [w8_w9] (w9=4) & (fail=false) -> 1:(w9'=5);
    [w8_w9_res_int] (w9=5) & (fail=false) -> 1:(w9'=6);
    [w8_w9_err_unit] (w9=5) & (fail=false) -> 1:(w9'=9);
    [w9_w10] (w9=6) & (fail=false) -> 0.2:(w9'=12) + 0.5:(w9'=7) + 0.3:(w9'=8);
    [w9_w10_res_int] (w9=7) & (fail=false) -> 1:(w9'=0);
    [w9_w10_err_unit] (w9=8) & (fail=false) -> 1:(w9'=0);
    [w9_w10] (w9=9) & (fail=false) -> 0:(w9'=12) + 1:(w9'=10);
    [w9_w10_err_unit] (w9=10) & (fail=false) -> 1:(w9'=0);
  endmodule
  
  module w10
    w10 : [0..12] init 0;
  
    [] (w10=12) & (fail=false) -> 1:(fail'=true);
    [w11_w10] (w10=0) & (fail=false) -> 1:(w10'=1);
    [w11_w10_req_unit] (w10=1) & (fail=false) -> 1:(w10'=2);
    [w10_w9] (w10=2) & (fail=false) -> 0:(w10'=12) + 1:(w10'=3);
    [w10_w9_req_unit] (w10=3) & (fail=false) -> 1:(w10'=4);
    [w9_w10] (w10=4) & (fail=false) -> 1:(w10'=5);
    [w9_w10_res_int] (w10=5) & (fail=false) -> 1:(w10'=6);
    [w9_w10_err_unit] (w10=5) & (fail=false) -> 1:(w10'=9);
    [w10_w11] (w10=6) & (fail=false) -> 0.2:(w10'=12) + 0.5:(w10'=7) + 0.3:(w10'=8);
    [w10_w11_res_int] (w10=7) & (fail=false) -> 1:(w10'=0);
    [w10_w11_err_unit] (w10=8) & (fail=false) -> 1:(w10'=0);
    [w10_w11] (w10=9) & (fail=false) -> 0:(w10'=12) + 1:(w10'=10);
    [w10_w11_err_unit] (w10=10) & (fail=false) -> 1:(w10'=0);
  endmodule
  
  module w11
    w11 : [0..12] init 0;
  
    [] (w11=12) & (fail=false) -> 1:(fail'=true);
    [w12_w11] (w11=0) & (fail=false) -> 1:(w11'=1);
    [w12_w11_req_unit] (w11=1) & (fail=false) -> 1:(w11'=2);
    [w11_w10] (w11=2) & (fail=false) -> 0:(w11'=12) + 1:(w11'=3);
    [w11_w10_req_unit] (w11=3) & (fail=false) -> 1:(w11'=4);
    [w10_w11] (w11=4) & (fail=false) -> 1:(w11'=5);
    [w10_w11_res_int] (w11=5) & (fail=false) -> 1:(w11'=6);
    [w10_w11_err_unit] (w11=5) & (fail=false) -> 1:(w11'=9);
    [w11_w12] (w11=6) & (fail=false) -> 0.2:(w11'=12) + 0.5:(w11'=7) + 0.3:(w11'=8);
    [w11_w12_res_int] (w11=7) & (fail=false) -> 1:(w11'=0);
    [w11_w12_err_unit] (w11=8) & (fail=false) -> 1:(w11'=0);
    [w11_w12] (w11=9) & (fail=false) -> 0:(w11'=12) + 1:(w11'=10);
    [w11_w12_err_unit] (w11=10) & (fail=false) -> 1:(w11'=0);
  endmodule
  
  module w12
    w12 : [0..12] init 0;
  
    [] (w12=12) & (fail=false) -> 1:(fail'=true);
    [w13_w12] (w12=0) & (fail=false) -> 1:(w12'=1);
    [w13_w12_req_unit] (w12=1) & (fail=false) -> 1:(w12'=2);
    [w12_w11] (w12=2) & (fail=false) -> 0:(w12'=12) + 1:(w12'=3);
    [w12_w11_req_unit] (w12=3) & (fail=false) -> 1:(w12'=4);
    [w11_w12] (w12=4) & (fail=false) -> 1:(w12'=5);
    [w11_w12_res_int] (w12=5) & (fail=false) -> 1:(w12'=6);
    [w11_w12_err_unit] (w12=5) & (fail=false) -> 1:(w12'=9);
    [w12_w13] (w12=6) & (fail=false) -> 0.2:(w12'=12) + 0.5:(w12'=7) + 0.3:(w12'=8);
    [w12_w13_res_int] (w12=7) & (fail=false) -> 1:(w12'=0);
    [w12_w13_err_unit] (w12=8) & (fail=false) -> 1:(w12'=0);
    [w12_w13] (w12=9) & (fail=false) -> 0:(w12'=12) + 1:(w12'=10);
    [w12_w13_err_unit] (w12=10) & (fail=false) -> 1:(w12'=0);
  endmodule
  
  module w13
    w13 : [0..7] init 0;
  
    [] (w13=7) & (fail=false) -> 1:(fail'=true);
    [w13_w12] (w13=0) & (fail=false) -> 0:(w13'=7) + 1:(w13'=1);
    [w13_w12_req_unit] (w13=1) & (fail=false) -> 1:(w13'=2);
    [w12_w13] (w13=2) & (fail=false) -> 1:(w13'=3);
    [w12_w13_res_int] (w13=3) & (fail=false) -> 1:(w13'=4);
    [w12_w13_err_unit] (w13=3) & (fail=false) -> 1:(w13'=6);
    [w13_dummy] (w13=4) & (fail=false) -> 0:(w13'=7) + 1:(w13'=5);
    [w13_dummy_done_unit] (w13=5) & (fail=false) -> 1:(w13'=4);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [w13_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [w13_dummy_done_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=5) & (w1=11) & (w2=11) & (w3=11) & (w4=11) & (w5=11) & (w6=11) & (w7=11) & (w8=11) & (w9=11) & (w10=11) & (w11=11) & (w12=11) & (w13=6) & (dummy=2);
  label "cando_w0_w1_err_unit" = w0=2;
  label "cando_w0_w1_err_unit_branch" = w1=4;
  label "cando_w0_w1_res_int" = w0=2;
  label "cando_w0_w1_res_int_branch" = w1=4;
  label "cando_w1_w0_req_unit" = w1=2;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=6) | (w1=9);
  label "cando_w1_w2_err_unit_branch" = w2=4;
  label "cando_w1_w2_res_int" = w1=6;
  label "cando_w1_w2_res_int_branch" = w2=4;
  label "cando_w10_w11_err_unit" = (w10=6) | (w10=9);
  label "cando_w10_w11_err_unit_branch" = w11=4;
  label "cando_w10_w11_res_int" = w10=6;
  label "cando_w10_w11_res_int_branch" = w11=4;
  label "cando_w10_w9_req_unit" = w10=2;
  label "cando_w10_w9_req_unit_branch" = w9=0;
  label "cando_w11_w10_req_unit" = w11=2;
  label "cando_w11_w10_req_unit_branch" = w10=0;
  label "cando_w11_w12_err_unit" = (w11=6) | (w11=9);
  label "cando_w11_w12_err_unit_branch" = w12=4;
  label "cando_w11_w12_res_int" = w11=6;
  label "cando_w11_w12_res_int_branch" = w12=4;
  label "cando_w12_w11_req_unit" = w12=2;
  label "cando_w12_w11_req_unit_branch" = w11=0;
  label "cando_w12_w13_err_unit" = (w12=6) | (w12=9);
  label "cando_w12_w13_err_unit_branch" = w13=2;
  label "cando_w12_w13_res_int" = w12=6;
  label "cando_w12_w13_res_int_branch" = w13=2;
  label "cando_w13_dummy_done_unit" = w13=4;
  label "cando_w13_dummy_done_unit_branch" = dummy=0;
  label "cando_w13_w12_req_unit" = w13=0;
  label "cando_w13_w12_req_unit_branch" = w12=0;
  label "cando_w2_w1_req_unit" = w2=2;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=6) | (w2=9);
  label "cando_w2_w3_err_unit_branch" = w3=4;
  label "cando_w2_w3_res_int" = w2=6;
  label "cando_w2_w3_res_int_branch" = w3=4;
  label "cando_w3_w2_req_unit" = w3=2;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w3_w4_err_unit" = (w3=6) | (w3=9);
  label "cando_w3_w4_err_unit_branch" = w4=4;
  label "cando_w3_w4_res_int" = w3=6;
  label "cando_w3_w4_res_int_branch" = w4=4;
  label "cando_w4_w3_req_unit" = w4=2;
  label "cando_w4_w3_req_unit_branch" = w3=0;
  label "cando_w4_w5_err_unit" = (w4=6) | (w4=9);
  label "cando_w4_w5_err_unit_branch" = w5=4;
  label "cando_w4_w5_res_int" = w4=6;
  label "cando_w4_w5_res_int_branch" = w5=4;
  label "cando_w5_w4_req_unit" = w5=2;
  label "cando_w5_w4_req_unit_branch" = w4=0;
  label "cando_w5_w6_err_unit" = (w5=6) | (w5=9);
  label "cando_w5_w6_err_unit_branch" = w6=4;
  label "cando_w5_w6_res_int" = w5=6;
  label "cando_w5_w6_res_int_branch" = w6=4;
  label "cando_w6_w5_req_unit" = w6=2;
  label "cando_w6_w5_req_unit_branch" = w5=0;
  label "cando_w6_w7_err_unit" = (w6=6) | (w6=9);
  label "cando_w6_w7_err_unit_branch" = w7=4;
  label "cando_w6_w7_res_int" = w6=6;
  label "cando_w6_w7_res_int_branch" = w7=4;
  label "cando_w7_w6_req_unit" = w7=2;
  label "cando_w7_w6_req_unit_branch" = w6=0;
  label "cando_w7_w8_err_unit" = (w7=6) | (w7=9);
  label "cando_w7_w8_err_unit_branch" = w8=4;
  label "cando_w7_w8_res_int" = w7=6;
  label "cando_w7_w8_res_int_branch" = w8=4;
  label "cando_w8_w7_req_unit" = w8=2;
  label "cando_w8_w7_req_unit_branch" = w7=0;
  label "cando_w8_w9_err_unit" = (w8=6) | (w8=9);
  label "cando_w8_w9_err_unit_branch" = w9=4;
  label "cando_w8_w9_res_int" = w8=6;
  label "cando_w8_w9_res_int_branch" = w9=4;
  label "cando_w9_w10_err_unit" = (w9=6) | (w9=9);
  label "cando_w9_w10_err_unit_branch" = w10=4;
  label "cando_w9_w10_res_int" = w9=6;
  label "cando_w9_w10_res_int_branch" = w10=4;
  label "cando_w9_w8_req_unit" = w9=2;
  label "cando_w9_w8_req_unit_branch" = w8=0;
  label "cando_w0_w1_branch" = w1=4;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=4;
  label "cando_w10_w11_branch" = w11=4;
  label "cando_w10_w9_branch" = w9=0;
  label "cando_w11_w10_branch" = w10=0;
  label "cando_w11_w12_branch" = w12=4;
  label "cando_w12_w11_branch" = w11=0;
  label "cando_w12_w13_branch" = w13=2;
  label "cando_w13_dummy_branch" = dummy=0;
  label "cando_w13_w12_branch" = w12=0;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=4;
  label "cando_w3_w2_branch" = w2=0;
  label "cando_w3_w4_branch" = w4=4;
  label "cando_w4_w3_branch" = w3=0;
  label "cando_w4_w5_branch" = w5=4;
  label "cando_w5_w4_branch" = w4=0;
  label "cando_w5_w6_branch" = w6=4;
  label "cando_w6_w5_branch" = w5=0;
  label "cando_w6_w7_branch" = w7=4;
  label "cando_w7_w6_branch" = w6=0;
  label "cando_w7_w8_branch" = w8=4;
  label "cando_w8_w7_branch" = w7=0;
  label "cando_w8_w9_branch" = w9=4;
  label "cando_w9_w10_branch" = w10=4;
  label "cando_w9_w8_branch" = w8=0;
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w10_w11_err_unit" & "cando_w10_w11_branch") => "cando_w10_w11_err_unit_branch") & ((("cando_w10_w11_res_int" & "cando_w10_w11_branch") => "cando_w10_w11_res_int_branch") & ((("cando_w10_w9_req_unit" & "cando_w10_w9_branch") => "cando_w10_w9_req_unit_branch") & ((("cando_w11_w10_req_unit" & "cando_w11_w10_branch") => "cando_w11_w10_req_unit_branch") & ((("cando_w11_w12_err_unit" & "cando_w11_w12_branch") => "cando_w11_w12_err_unit_branch") & ((("cando_w11_w12_res_int" & "cando_w11_w12_branch") => "cando_w11_w12_res_int_branch") & ((("cando_w12_w11_req_unit" & "cando_w12_w11_branch") => "cando_w12_w11_req_unit_branch") & ((("cando_w12_w13_err_unit" & "cando_w12_w13_branch") => "cando_w12_w13_err_unit_branch") & ((("cando_w12_w13_res_int" & "cando_w12_w13_branch") => "cando_w12_w13_res_int_branch") & ((("cando_w13_dummy_done_unit" & "cando_w13_dummy_branch") => "cando_w13_dummy_done_unit_branch") & ((("cando_w13_w12_req_unit" & "cando_w13_w12_branch") => "cando_w13_w12_req_unit_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch") & ((("cando_w3_w4_err_unit" & "cando_w3_w4_branch") => "cando_w3_w4_err_unit_branch") & ((("cando_w3_w4_res_int" & "cando_w3_w4_branch") => "cando_w3_w4_res_int_branch") & ((("cando_w4_w3_req_unit" & "cando_w4_w3_branch") => "cando_w4_w3_req_unit_branch") & ((("cando_w4_w5_err_unit" & "cando_w4_w5_branch") => "cando_w4_w5_err_unit_branch") & ((("cando_w4_w5_res_int" & "cando_w4_w5_branch") => "cando_w4_w5_res_int_branch") & ((("cando_w5_w4_req_unit" & "cando_w5_w4_branch") => "cando_w5_w4_req_unit_branch") & ((("cando_w5_w6_err_unit" & "cando_w5_w6_branch") => "cando_w5_w6_err_unit_branch") & ((("cando_w5_w6_res_int" & "cando_w5_w6_branch") => "cando_w5_w6_res_int_branch") & ((("cando_w6_w5_req_unit" & "cando_w6_w5_branch") => "cando_w6_w5_req_unit_branch") & ((("cando_w6_w7_err_unit" & "cando_w6_w7_branch") => "cando_w6_w7_err_unit_branch") & ((("cando_w6_w7_res_int" & "cando_w6_w7_branch") => "cando_w6_w7_res_int_branch") & ((("cando_w7_w6_req_unit" & "cando_w7_w6_branch") => "cando_w7_w6_req_unit_branch") & ((("cando_w7_w8_err_unit" & "cando_w7_w8_branch") => "cando_w7_w8_err_unit_branch") & ((("cando_w7_w8_res_int" & "cando_w7_w8_branch") => "cando_w7_w8_res_int_branch") & ((("cando_w8_w7_req_unit" & "cando_w8_w7_branch") => "cando_w8_w7_req_unit_branch") & ((("cando_w8_w9_err_unit" & "cando_w8_w9_branch") => "cando_w8_w9_err_unit_branch") & ((("cando_w8_w9_res_int" & "cando_w8_w9_branch") => "cando_w8_w9_res_int_branch") & ((("cando_w9_w10_err_unit" & "cando_w9_w10_branch") => "cando_w9_w10_err_unit_branch") & ((("cando_w9_w10_res_int" & "cando_w9_w10_branch") => "cando_w9_w10_res_int_branch") & (("cando_w9_w8_req_unit" & "cando_w9_w8_branch") => "cando_w9_w8_req_unit_branch"))))))))))))))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.708984374999556E-4 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 2.3733640740483423E-4
  
  Probabilistic termination
  Result: 0.7198974609375 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.999762663592595
  
  
  
  
   ======= TEST ../examples/fact_14.ctx =======
  
  w0 : mu t .
       w1 & req . w1 (+) { 0.7 : res(Int) . t, 0.3 : err . t }
  
  w1 : mu t . w2 & req .
              w0 (+) req .
              w0 & {
                 res(Int) . w2 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w2 (+) err . t
              }
  
  w2 : mu t . w3 & req .
              w1 (+) req .
              w1 & {
                 res(Int) . w3 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w3 (+) err . t
              }
  
  w3 : mu t . w4 & req .
              w2 (+) req .
              w2 & {
                 res(Int) . w4 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w4 (+) err . t
              }
  
  w4 : mu t . w5 & req .
              w3 (+) req .
              w3 & {
                 res(Int) . w5 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w5 (+) err . t
              }
  
  w5 : mu t . w6 & req .
              w4 (+) req .
              w4 & {
                 res(Int) . w6 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w6 (+) err . t
              }
  
  w6 : mu t . w7 & req .
              w5 (+) req .
              w5 & {
                 res(Int) . w7 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w7 (+) err . t
              }
  
  w7 : mu t . w8 & req .
              w6 (+) req .
              w6 & {
                 res(Int) . w8 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w8 (+) err . t
              }
  
  w8 : mu t . w9 & req .
              w7 (+) req .
              w7 & {
                 res(Int) . w9 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w9 (+) err . t
              }
  
  w9 : mu t . w10 & req .
              w8 (+) req .
              w8 & {
                 res(Int) . w10 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w10 (+) err . t
              }
  
  w10 : mu t . w11 & req .
              w9 (+) req .
              w9 & {
                 res(Int) . w11 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w11 (+) err . t
              }
  
  w11 : mu t . w12 & req .
              w10 (+) req .
              w10 & {
                 res(Int) . w12 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w12 (+) err . t
              }
  
  w12 : mu t . w13 & req .
              w11 (+) req .
              w11 & {
                 res(Int) . w13 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w13 (+) err . t
              }
  
  w13 : mu t . w14 & req .
              w12 (+) req .
              w12 & {
                 res(Int) . w14 (+) { 0.5 : res(Int) . t, 0.3 : err . t },
                 err . w14 (+) err . t
              }
  
  w14 : w13 (+) req .
       w13 & {
          res(Int) . mu t . dummy (+) done . t,
          err . end
       }
  
  dummy : mu t . w14 & done . t
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..6] init 0;
  
    [] (w0=6) & (fail=false) -> 1:(fail'=true);
    [w1_w0] (w0=0) & (fail=false) -> 1:(w0'=1);
    [w1_w0_req_unit] (w0=1) & (fail=false) -> 1:(w0'=2);
    [w0_w1] (w0=2) & (fail=false) -> 0:(w0'=6) + 0.7:(w0'=3) + 0.3:(w0'=4);
    [w0_w1_res_int] (w0=3) & (fail=false) -> 1:(w0'=0);
    [w0_w1_err_unit] (w0=4) & (fail=false) -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..12] init 0;
  
    [] (w1=12) & (fail=false) -> 1:(fail'=true);
    [w2_w1] (w1=0) & (fail=false) -> 1:(w1'=1);
    [w2_w1_req_unit] (w1=1) & (fail=false) -> 1:(w1'=2);
    [w1_w0] (w1=2) & (fail=false) -> 0:(w1'=12) + 1:(w1'=3);
    [w1_w0_req_unit] (w1=3) & (fail=false) -> 1:(w1'=4);
    [w0_w1] (w1=4) & (fail=false) -> 1:(w1'=5);
    [w0_w1_res_int] (w1=5) & (fail=false) -> 1:(w1'=6);
    [w0_w1_err_unit] (w1=5) & (fail=false) -> 1:(w1'=9);
    [w1_w2] (w1=6) & (fail=false) -> 0.2:(w1'=12) + 0.5:(w1'=7) + 0.3:(w1'=8);
    [w1_w2_res_int] (w1=7) & (fail=false) -> 1:(w1'=0);
    [w1_w2_err_unit] (w1=8) & (fail=false) -> 1:(w1'=0);
    [w1_w2] (w1=9) & (fail=false) -> 0:(w1'=12) + 1:(w1'=10);
    [w1_w2_err_unit] (w1=10) & (fail=false) -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..12] init 0;
  
    [] (w2=12) & (fail=false) -> 1:(fail'=true);
    [w3_w2] (w2=0) & (fail=false) -> 1:(w2'=1);
    [w3_w2_req_unit] (w2=1) & (fail=false) -> 1:(w2'=2);
    [w2_w1] (w2=2) & (fail=false) -> 0:(w2'=12) + 1:(w2'=3);
    [w2_w1_req_unit] (w2=3) & (fail=false) -> 1:(w2'=4);
    [w1_w2] (w2=4) & (fail=false) -> 1:(w2'=5);
    [w1_w2_res_int] (w2=5) & (fail=false) -> 1:(w2'=6);
    [w1_w2_err_unit] (w2=5) & (fail=false) -> 1:(w2'=9);
    [w2_w3] (w2=6) & (fail=false) -> 0.2:(w2'=12) + 0.5:(w2'=7) + 0.3:(w2'=8);
    [w2_w3_res_int] (w2=7) & (fail=false) -> 1:(w2'=0);
    [w2_w3_err_unit] (w2=8) & (fail=false) -> 1:(w2'=0);
    [w2_w3] (w2=9) & (fail=false) -> 0:(w2'=12) + 1:(w2'=10);
    [w2_w3_err_unit] (w2=10) & (fail=false) -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..12] init 0;
  
    [] (w3=12) & (fail=false) -> 1:(fail'=true);
    [w4_w3] (w3=0) & (fail=false) -> 1:(w3'=1);
    [w4_w3_req_unit] (w3=1) & (fail=false) -> 1:(w3'=2);
    [w3_w2] (w3=2) & (fail=false) -> 0:(w3'=12) + 1:(w3'=3);
    [w3_w2_req_unit] (w3=3) & (fail=false) -> 1:(w3'=4);
    [w2_w3] (w3=4) & (fail=false) -> 1:(w3'=5);
    [w2_w3_res_int] (w3=5) & (fail=false) -> 1:(w3'=6);
    [w2_w3_err_unit] (w3=5) & (fail=false) -> 1:(w3'=9);
    [w3_w4] (w3=6) & (fail=false) -> 0.2:(w3'=12) + 0.5:(w3'=7) + 0.3:(w3'=8);
    [w3_w4_res_int] (w3=7) & (fail=false) -> 1:(w3'=0);
    [w3_w4_err_unit] (w3=8) & (fail=false) -> 1:(w3'=0);
    [w3_w4] (w3=9) & (fail=false) -> 0:(w3'=12) + 1:(w3'=10);
    [w3_w4_err_unit] (w3=10) & (fail=false) -> 1:(w3'=0);
  endmodule
  
  module w4
    w4 : [0..12] init 0;
  
    [] (w4=12) & (fail=false) -> 1:(fail'=true);
    [w5_w4] (w4=0) & (fail=false) -> 1:(w4'=1);
    [w5_w4_req_unit] (w4=1) & (fail=false) -> 1:(w4'=2);
    [w4_w3] (w4=2) & (fail=false) -> 0:(w4'=12) + 1:(w4'=3);
    [w4_w3_req_unit] (w4=3) & (fail=false) -> 1:(w4'=4);
    [w3_w4] (w4=4) & (fail=false) -> 1:(w4'=5);
    [w3_w4_res_int] (w4=5) & (fail=false) -> 1:(w4'=6);
    [w3_w4_err_unit] (w4=5) & (fail=false) -> 1:(w4'=9);
    [w4_w5] (w4=6) & (fail=false) -> 0.2:(w4'=12) + 0.5:(w4'=7) + 0.3:(w4'=8);
    [w4_w5_res_int] (w4=7) & (fail=false) -> 1:(w4'=0);
    [w4_w5_err_unit] (w4=8) & (fail=false) -> 1:(w4'=0);
    [w4_w5] (w4=9) & (fail=false) -> 0:(w4'=12) + 1:(w4'=10);
    [w4_w5_err_unit] (w4=10) & (fail=false) -> 1:(w4'=0);
  endmodule
  
  module w5
    w5 : [0..12] init 0;
  
    [] (w5=12) & (fail=false) -> 1:(fail'=true);
    [w6_w5] (w5=0) & (fail=false) -> 1:(w5'=1);
    [w6_w5_req_unit] (w5=1) & (fail=false) -> 1:(w5'=2);
    [w5_w4] (w5=2) & (fail=false) -> 0:(w5'=12) + 1:(w5'=3);
    [w5_w4_req_unit] (w5=3) & (fail=false) -> 1:(w5'=4);
    [w4_w5] (w5=4) & (fail=false) -> 1:(w5'=5);
    [w4_w5_res_int] (w5=5) & (fail=false) -> 1:(w5'=6);
    [w4_w5_err_unit] (w5=5) & (fail=false) -> 1:(w5'=9);
    [w5_w6] (w5=6) & (fail=false) -> 0.2:(w5'=12) + 0.5:(w5'=7) + 0.3:(w5'=8);
    [w5_w6_res_int] (w5=7) & (fail=false) -> 1:(w5'=0);
    [w5_w6_err_unit] (w5=8) & (fail=false) -> 1:(w5'=0);
    [w5_w6] (w5=9) & (fail=false) -> 0:(w5'=12) + 1:(w5'=10);
    [w5_w6_err_unit] (w5=10) & (fail=false) -> 1:(w5'=0);
  endmodule
  
  module w6
    w6 : [0..12] init 0;
  
    [] (w6=12) & (fail=false) -> 1:(fail'=true);
    [w7_w6] (w6=0) & (fail=false) -> 1:(w6'=1);
    [w7_w6_req_unit] (w6=1) & (fail=false) -> 1:(w6'=2);
    [w6_w5] (w6=2) & (fail=false) -> 0:(w6'=12) + 1:(w6'=3);
    [w6_w5_req_unit] (w6=3) & (fail=false) -> 1:(w6'=4);
    [w5_w6] (w6=4) & (fail=false) -> 1:(w6'=5);
    [w5_w6_res_int] (w6=5) & (fail=false) -> 1:(w6'=6);
    [w5_w6_err_unit] (w6=5) & (fail=false) -> 1:(w6'=9);
    [w6_w7] (w6=6) & (fail=false) -> 0.2:(w6'=12) + 0.5:(w6'=7) + 0.3:(w6'=8);
    [w6_w7_res_int] (w6=7) & (fail=false) -> 1:(w6'=0);
    [w6_w7_err_unit] (w6=8) & (fail=false) -> 1:(w6'=0);
    [w6_w7] (w6=9) & (fail=false) -> 0:(w6'=12) + 1:(w6'=10);
    [w6_w7_err_unit] (w6=10) & (fail=false) -> 1:(w6'=0);
  endmodule
  
  module w7
    w7 : [0..12] init 0;
  
    [] (w7=12) & (fail=false) -> 1:(fail'=true);
    [w8_w7] (w7=0) & (fail=false) -> 1:(w7'=1);
    [w8_w7_req_unit] (w7=1) & (fail=false) -> 1:(w7'=2);
    [w7_w6] (w7=2) & (fail=false) -> 0:(w7'=12) + 1:(w7'=3);
    [w7_w6_req_unit] (w7=3) & (fail=false) -> 1:(w7'=4);
    [w6_w7] (w7=4) & (fail=false) -> 1:(w7'=5);
    [w6_w7_res_int] (w7=5) & (fail=false) -> 1:(w7'=6);
    [w6_w7_err_unit] (w7=5) & (fail=false) -> 1:(w7'=9);
    [w7_w8] (w7=6) & (fail=false) -> 0.2:(w7'=12) + 0.5:(w7'=7) + 0.3:(w7'=8);
    [w7_w8_res_int] (w7=7) & (fail=false) -> 1:(w7'=0);
    [w7_w8_err_unit] (w7=8) & (fail=false) -> 1:(w7'=0);
    [w7_w8] (w7=9) & (fail=false) -> 0:(w7'=12) + 1:(w7'=10);
    [w7_w8_err_unit] (w7=10) & (fail=false) -> 1:(w7'=0);
  endmodule
  
  module w8
    w8 : [0..12] init 0;
  
    [] (w8=12) & (fail=false) -> 1:(fail'=true);
    [w9_w8] (w8=0) & (fail=false) -> 1:(w8'=1);
    [w9_w8_req_unit] (w8=1) & (fail=false) -> 1:(w8'=2);
    [w8_w7] (w8=2) & (fail=false) -> 0:(w8'=12) + 1:(w8'=3);
    [w8_w7_req_unit] (w8=3) & (fail=false) -> 1:(w8'=4);
    [w7_w8] (w8=4) & (fail=false) -> 1:(w8'=5);
    [w7_w8_res_int] (w8=5) & (fail=false) -> 1:(w8'=6);
    [w7_w8_err_unit] (w8=5) & (fail=false) -> 1:(w8'=9);
    [w8_w9] (w8=6) & (fail=false) -> 0.2:(w8'=12) + 0.5:(w8'=7) + 0.3:(w8'=8);
    [w8_w9_res_int] (w8=7) & (fail=false) -> 1:(w8'=0);
    [w8_w9_err_unit] (w8=8) & (fail=false) -> 1:(w8'=0);
    [w8_w9] (w8=9) & (fail=false) -> 0:(w8'=12) + 1:(w8'=10);
    [w8_w9_err_unit] (w8=10) & (fail=false) -> 1:(w8'=0);
  endmodule
  
  module w9
    w9 : [0..12] init 0;
  
    [] (w9=12) & (fail=false) -> 1:(fail'=true);
    [w10_w9] (w9=0) & (fail=false) -> 1:(w9'=1);
    [w10_w9_req_unit] (w9=1) & (fail=false) -> 1:(w9'=2);
    [w9_w8] (w9=2) & (fail=false) -> 0:(w9'=12) + 1:(w9'=3);
    [w9_w8_req_unit] (w9=3) & (fail=false) -> 1:(w9'=4);
    [w8_w9] (w9=4) & (fail=false) -> 1:(w9'=5);
    [w8_w9_res_int] (w9=5) & (fail=false) -> 1:(w9'=6);
    [w8_w9_err_unit] (w9=5) & (fail=false) -> 1:(w9'=9);
    [w9_w10] (w9=6) & (fail=false) -> 0.2:(w9'=12) + 0.5:(w9'=7) + 0.3:(w9'=8);
    [w9_w10_res_int] (w9=7) & (fail=false) -> 1:(w9'=0);
    [w9_w10_err_unit] (w9=8) & (fail=false) -> 1:(w9'=0);
    [w9_w10] (w9=9) & (fail=false) -> 0:(w9'=12) + 1:(w9'=10);
    [w9_w10_err_unit] (w9=10) & (fail=false) -> 1:(w9'=0);
  endmodule
  
  module w10
    w10 : [0..12] init 0;
  
    [] (w10=12) & (fail=false) -> 1:(fail'=true);
    [w11_w10] (w10=0) & (fail=false) -> 1:(w10'=1);
    [w11_w10_req_unit] (w10=1) & (fail=false) -> 1:(w10'=2);
    [w10_w9] (w10=2) & (fail=false) -> 0:(w10'=12) + 1:(w10'=3);
    [w10_w9_req_unit] (w10=3) & (fail=false) -> 1:(w10'=4);
    [w9_w10] (w10=4) & (fail=false) -> 1:(w10'=5);
    [w9_w10_res_int] (w10=5) & (fail=false) -> 1:(w10'=6);
    [w9_w10_err_unit] (w10=5) & (fail=false) -> 1:(w10'=9);
    [w10_w11] (w10=6) & (fail=false) -> 0.2:(w10'=12) + 0.5:(w10'=7) + 0.3:(w10'=8);
    [w10_w11_res_int] (w10=7) & (fail=false) -> 1:(w10'=0);
    [w10_w11_err_unit] (w10=8) & (fail=false) -> 1:(w10'=0);
    [w10_w11] (w10=9) & (fail=false) -> 0:(w10'=12) + 1:(w10'=10);
    [w10_w11_err_unit] (w10=10) & (fail=false) -> 1:(w10'=0);
  endmodule
  
  module w11
    w11 : [0..12] init 0;
  
    [] (w11=12) & (fail=false) -> 1:(fail'=true);
    [w12_w11] (w11=0) & (fail=false) -> 1:(w11'=1);
    [w12_w11_req_unit] (w11=1) & (fail=false) -> 1:(w11'=2);
    [w11_w10] (w11=2) & (fail=false) -> 0:(w11'=12) + 1:(w11'=3);
    [w11_w10_req_unit] (w11=3) & (fail=false) -> 1:(w11'=4);
    [w10_w11] (w11=4) & (fail=false) -> 1:(w11'=5);
    [w10_w11_res_int] (w11=5) & (fail=false) -> 1:(w11'=6);
    [w10_w11_err_unit] (w11=5) & (fail=false) -> 1:(w11'=9);
    [w11_w12] (w11=6) & (fail=false) -> 0.2:(w11'=12) + 0.5:(w11'=7) + 0.3:(w11'=8);
    [w11_w12_res_int] (w11=7) & (fail=false) -> 1:(w11'=0);
    [w11_w12_err_unit] (w11=8) & (fail=false) -> 1:(w11'=0);
    [w11_w12] (w11=9) & (fail=false) -> 0:(w11'=12) + 1:(w11'=10);
    [w11_w12_err_unit] (w11=10) & (fail=false) -> 1:(w11'=0);
  endmodule
  
  module w12
    w12 : [0..12] init 0;
  
    [] (w12=12) & (fail=false) -> 1:(fail'=true);
    [w13_w12] (w12=0) & (fail=false) -> 1:(w12'=1);
    [w13_w12_req_unit] (w12=1) & (fail=false) -> 1:(w12'=2);
    [w12_w11] (w12=2) & (fail=false) -> 0:(w12'=12) + 1:(w12'=3);
    [w12_w11_req_unit] (w12=3) & (fail=false) -> 1:(w12'=4);
    [w11_w12] (w12=4) & (fail=false) -> 1:(w12'=5);
    [w11_w12_res_int] (w12=5) & (fail=false) -> 1:(w12'=6);
    [w11_w12_err_unit] (w12=5) & (fail=false) -> 1:(w12'=9);
    [w12_w13] (w12=6) & (fail=false) -> 0.2:(w12'=12) + 0.5:(w12'=7) + 0.3:(w12'=8);
    [w12_w13_res_int] (w12=7) & (fail=false) -> 1:(w12'=0);
    [w12_w13_err_unit] (w12=8) & (fail=false) -> 1:(w12'=0);
    [w12_w13] (w12=9) & (fail=false) -> 0:(w12'=12) + 1:(w12'=10);
    [w12_w13_err_unit] (w12=10) & (fail=false) -> 1:(w12'=0);
  endmodule
  
  module w13
    w13 : [0..12] init 0;
  
    [] (w13=12) & (fail=false) -> 1:(fail'=true);
    [w14_w13] (w13=0) & (fail=false) -> 1:(w13'=1);
    [w14_w13_req_unit] (w13=1) & (fail=false) -> 1:(w13'=2);
    [w13_w12] (w13=2) & (fail=false) -> 0:(w13'=12) + 1:(w13'=3);
    [w13_w12_req_unit] (w13=3) & (fail=false) -> 1:(w13'=4);
    [w12_w13] (w13=4) & (fail=false) -> 1:(w13'=5);
    [w12_w13_res_int] (w13=5) & (fail=false) -> 1:(w13'=6);
    [w12_w13_err_unit] (w13=5) & (fail=false) -> 1:(w13'=9);
    [w13_w14] (w13=6) & (fail=false) -> 0.2:(w13'=12) + 0.5:(w13'=7) + 0.3:(w13'=8);
    [w13_w14_res_int] (w13=7) & (fail=false) -> 1:(w13'=0);
    [w13_w14_err_unit] (w13=8) & (fail=false) -> 1:(w13'=0);
    [w13_w14] (w13=9) & (fail=false) -> 0:(w13'=12) + 1:(w13'=10);
    [w13_w14_err_unit] (w13=10) & (fail=false) -> 1:(w13'=0);
  endmodule
  
  module w14
    w14 : [0..7] init 0;
  
    [] (w14=7) & (fail=false) -> 1:(fail'=true);
    [w14_w13] (w14=0) & (fail=false) -> 0:(w14'=7) + 1:(w14'=1);
    [w14_w13_req_unit] (w14=1) & (fail=false) -> 1:(w14'=2);
    [w13_w14] (w14=2) & (fail=false) -> 1:(w14'=3);
    [w13_w14_res_int] (w14=3) & (fail=false) -> 1:(w14'=4);
    [w13_w14_err_unit] (w14=3) & (fail=false) -> 1:(w14'=6);
    [w14_dummy] (w14=4) & (fail=false) -> 0:(w14'=7) + 1:(w14'=5);
    [w14_dummy_done_unit] (w14=5) & (fail=false) -> 1:(w14'=4);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] (dummy=3) & (fail=false) -> 1:(fail'=true);
    [w14_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [w14_dummy_done_unit] (dummy=1) & (fail=false) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=5) & (w1=11) & (w2=11) & (w3=11) & (w4=11) & (w5=11) & (w6=11) & (w7=11) & (w8=11) & (w9=11) & (w10=11) & (w11=11) & (w12=11) & (w13=11) & (w14=6) & (dummy=2);
  label "cando_w0_w1_err_unit" = w0=2;
  label "cando_w0_w1_err_unit_branch" = w1=4;
  label "cando_w0_w1_res_int" = w0=2;
  label "cando_w0_w1_res_int_branch" = w1=4;
  label "cando_w1_w0_req_unit" = w1=2;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=6) | (w1=9);
  label "cando_w1_w2_err_unit_branch" = w2=4;
  label "cando_w1_w2_res_int" = w1=6;
  label "cando_w1_w2_res_int_branch" = w2=4;
  label "cando_w10_w11_err_unit" = (w10=6) | (w10=9);
  label "cando_w10_w11_err_unit_branch" = w11=4;
  label "cando_w10_w11_res_int" = w10=6;
  label "cando_w10_w11_res_int_branch" = w11=4;
  label "cando_w10_w9_req_unit" = w10=2;
  label "cando_w10_w9_req_unit_branch" = w9=0;
  label "cando_w11_w10_req_unit" = w11=2;
  label "cando_w11_w10_req_unit_branch" = w10=0;
  label "cando_w11_w12_err_unit" = (w11=6) | (w11=9);
  label "cando_w11_w12_err_unit_branch" = w12=4;
  label "cando_w11_w12_res_int" = w11=6;
  label "cando_w11_w12_res_int_branch" = w12=4;
  label "cando_w12_w11_req_unit" = w12=2;
  label "cando_w12_w11_req_unit_branch" = w11=0;
  label "cando_w12_w13_err_unit" = (w12=6) | (w12=9);
  label "cando_w12_w13_err_unit_branch" = w13=4;
  label "cando_w12_w13_res_int" = w12=6;
  label "cando_w12_w13_res_int_branch" = w13=4;
  label "cando_w13_w12_req_unit" = w13=2;
  label "cando_w13_w12_req_unit_branch" = w12=0;
  label "cando_w13_w14_err_unit" = (w13=6) | (w13=9);
  label "cando_w13_w14_err_unit_branch" = w14=2;
  label "cando_w13_w14_res_int" = w13=6;
  label "cando_w13_w14_res_int_branch" = w14=2;
  label "cando_w14_dummy_done_unit" = w14=4;
  label "cando_w14_dummy_done_unit_branch" = dummy=0;
  label "cando_w14_w13_req_unit" = w14=0;
  label "cando_w14_w13_req_unit_branch" = w13=0;
  label "cando_w2_w1_req_unit" = w2=2;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=6) | (w2=9);
  label "cando_w2_w3_err_unit_branch" = w3=4;
  label "cando_w2_w3_res_int" = w2=6;
  label "cando_w2_w3_res_int_branch" = w3=4;
  label "cando_w3_w2_req_unit" = w3=2;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w3_w4_err_unit" = (w3=6) | (w3=9);
  label "cando_w3_w4_err_unit_branch" = w4=4;
  label "cando_w3_w4_res_int" = w3=6;
  label "cando_w3_w4_res_int_branch" = w4=4;
  label "cando_w4_w3_req_unit" = w4=2;
  label "cando_w4_w3_req_unit_branch" = w3=0;
  label "cando_w4_w5_err_unit" = (w4=6) | (w4=9);
  label "cando_w4_w5_err_unit_branch" = w5=4;
  label "cando_w4_w5_res_int" = w4=6;
  label "cando_w4_w5_res_int_branch" = w5=4;
  label "cando_w5_w4_req_unit" = w5=2;
  label "cando_w5_w4_req_unit_branch" = w4=0;
  label "cando_w5_w6_err_unit" = (w5=6) | (w5=9);
  label "cando_w5_w6_err_unit_branch" = w6=4;
  label "cando_w5_w6_res_int" = w5=6;
  label "cando_w5_w6_res_int_branch" = w6=4;
  label "cando_w6_w5_req_unit" = w6=2;
  label "cando_w6_w5_req_unit_branch" = w5=0;
  label "cando_w6_w7_err_unit" = (w6=6) | (w6=9);
  label "cando_w6_w7_err_unit_branch" = w7=4;
  label "cando_w6_w7_res_int" = w6=6;
  label "cando_w6_w7_res_int_branch" = w7=4;
  label "cando_w7_w6_req_unit" = w7=2;
  label "cando_w7_w6_req_unit_branch" = w6=0;
  label "cando_w7_w8_err_unit" = (w7=6) | (w7=9);
  label "cando_w7_w8_err_unit_branch" = w8=4;
  label "cando_w7_w8_res_int" = w7=6;
  label "cando_w7_w8_res_int_branch" = w8=4;
  label "cando_w8_w7_req_unit" = w8=2;
  label "cando_w8_w7_req_unit_branch" = w7=0;
  label "cando_w8_w9_err_unit" = (w8=6) | (w8=9);
  label "cando_w8_w9_err_unit_branch" = w9=4;
  label "cando_w8_w9_res_int" = w8=6;
  label "cando_w8_w9_res_int_branch" = w9=4;
  label "cando_w9_w10_err_unit" = (w9=6) | (w9=9);
  label "cando_w9_w10_err_unit_branch" = w10=4;
  label "cando_w9_w10_res_int" = w9=6;
  label "cando_w9_w10_res_int_branch" = w10=4;
  label "cando_w9_w8_req_unit" = w9=2;
  label "cando_w9_w8_req_unit_branch" = w8=0;
  label "cando_w0_w1_branch" = w1=4;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=4;
  label "cando_w10_w11_branch" = w11=4;
  label "cando_w10_w9_branch" = w9=0;
  label "cando_w11_w10_branch" = w10=0;
  label "cando_w11_w12_branch" = w12=4;
  label "cando_w12_w11_branch" = w11=0;
  label "cando_w12_w13_branch" = w13=4;
  label "cando_w13_w12_branch" = w12=0;
  label "cando_w13_w14_branch" = w14=2;
  label "cando_w14_dummy_branch" = dummy=0;
  label "cando_w14_w13_branch" = w13=0;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=4;
  label "cando_w3_w2_branch" = w2=0;
  label "cando_w3_w4_branch" = w4=4;
  label "cando_w4_w3_branch" = w3=0;
  label "cando_w4_w5_branch" = w5=4;
  label "cando_w5_w4_branch" = w4=0;
  label "cando_w5_w6_branch" = w6=4;
  label "cando_w6_w5_branch" = w5=0;
  label "cando_w6_w7_branch" = w7=4;
  label "cando_w7_w6_branch" = w6=0;
  label "cando_w7_w8_branch" = w8=4;
  label "cando_w8_w7_branch" = w7=0;
  label "cando_w8_w9_branch" = w9=4;
  label "cando_w9_w10_branch" = w10=4;
  label "cando_w9_w8_branch" = w8=0;
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w10_w11_err_unit" & "cando_w10_w11_branch") => "cando_w10_w11_err_unit_branch") & ((("cando_w10_w11_res_int" & "cando_w10_w11_branch") => "cando_w10_w11_res_int_branch") & ((("cando_w10_w9_req_unit" & "cando_w10_w9_branch") => "cando_w10_w9_req_unit_branch") & ((("cando_w11_w10_req_unit" & "cando_w11_w10_branch") => "cando_w11_w10_req_unit_branch") & ((("cando_w11_w12_err_unit" & "cando_w11_w12_branch") => "cando_w11_w12_err_unit_branch") & ((("cando_w11_w12_res_int" & "cando_w11_w12_branch") => "cando_w11_w12_res_int_branch") & ((("cando_w12_w11_req_unit" & "cando_w12_w11_branch") => "cando_w12_w11_req_unit_branch") & ((("cando_w12_w13_err_unit" & "cando_w12_w13_branch") => "cando_w12_w13_err_unit_branch") & ((("cando_w12_w13_res_int" & "cando_w12_w13_branch") => "cando_w12_w13_res_int_branch") & ((("cando_w13_w12_req_unit" & "cando_w13_w12_branch") => "cando_w13_w12_req_unit_branch") & ((("cando_w13_w14_err_unit" & "cando_w13_w14_branch") => "cando_w13_w14_err_unit_branch") & ((("cando_w13_w14_res_int" & "cando_w13_w14_branch") => "cando_w13_w14_res_int_branch") & ((("cando_w14_dummy_done_unit" & "cando_w14_dummy_branch") => "cando_w14_dummy_done_unit_branch") & ((("cando_w14_w13_req_unit" & "cando_w14_w13_branch") => "cando_w14_w13_req_unit_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch") & ((("cando_w3_w4_err_unit" & "cando_w3_w4_branch") => "cando_w3_w4_err_unit_branch") & ((("cando_w3_w4_res_int" & "cando_w3_w4_branch") => "cando_w3_w4_res_int_branch") & ((("cando_w4_w3_req_unit" & "cando_w4_w3_branch") => "cando_w4_w3_req_unit_branch") & ((("cando_w4_w5_err_unit" & "cando_w4_w5_branch") => "cando_w4_w5_err_unit_branch") & ((("cando_w4_w5_res_int" & "cando_w4_w5_branch") => "cando_w4_w5_res_int_branch") & ((("cando_w5_w4_req_unit" & "cando_w5_w4_branch") => "cando_w5_w4_req_unit_branch") & ((("cando_w5_w6_err_unit" & "cando_w5_w6_branch") => "cando_w5_w6_err_unit_branch") & ((("cando_w5_w6_res_int" & "cando_w5_w6_branch") => "cando_w5_w6_res_int_branch") & ((("cando_w6_w5_req_unit" & "cando_w6_w5_branch") => "cando_w6_w5_req_unit_branch") & ((("cando_w6_w7_err_unit" & "cando_w6_w7_branch") => "cando_w6_w7_err_unit_branch") & ((("cando_w6_w7_res_int" & "cando_w6_w7_branch") => "cando_w6_w7_res_int_branch") & ((("cando_w7_w6_req_unit" & "cando_w7_w6_branch") => "cando_w7_w6_req_unit_branch") & ((("cando_w7_w8_err_unit" & "cando_w7_w8_branch") => "cando_w7_w8_err_unit_branch") & ((("cando_w7_w8_res_int" & "cando_w7_w8_branch") => "cando_w7_w8_res_int_branch") & ((("cando_w8_w7_req_unit" & "cando_w8_w7_branch") => "cando_w8_w7_req_unit_branch") & ((("cando_w8_w9_err_unit" & "cando_w8_w9_branch") => "cando_w8_w9_err_unit_branch") & ((("cando_w8_w9_res_int" & "cando_w8_w9_branch") => "cando_w8_w9_res_int_branch") & ((("cando_w9_w10_err_unit" & "cando_w9_w10_branch") => "cando_w9_w10_err_unit_branch") & ((("cando_w9_w10_res_int" & "cando_w9_w10_branch") => "cando_w9_w10_res_int_branch") & (("cando_w9_w8_req_unit" & "cando_w9_w8_branch") => "cando_w9_w8_req_unit_branch")))))))))))))))))))))))))))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 8.544921875008882E-5 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.186738368269884E-4
  
  Probabilistic termination
  Result: 0.71994873046875 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.999881326163173
  
  
  
  
   ======= TEST ../examples/mdp.ctx =======
  
  a : b (+) { 0.3 : l1 . end, 0.4 : l2 . mu t . b (+) { 0.9 : l2 . t } }
  
  b : a & { l1 . end, l2 . mu t . a & l2 . t }
  
  c : d (+) l3 . end
  
  d : c & l3 . end
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..6] init 0;
  
    [] (a=6) & (fail=false) -> 1:(fail'=true);
    [a_b] (a=0) & (fail=false) -> 0.3:(a'=6) + 0.4:(a'=1) + 0.3:(a'=2);
    [a_b_l2_unit] (a=1) & (fail=false) -> 1:(a'=3);
    [a_b_l1_unit] (a=2) & (fail=false) -> 1:(a'=5);
    [a_b] (a=3) & (fail=false) -> 0.1:(a'=6) + 0.9:(a'=4);
    [a_b_l2_unit] (a=4) & (fail=false) -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..5] init 0;
  
    [] (b=5) & (fail=false) -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_l1_unit] (b=1) & (fail=false) -> 1:(b'=4);
    [a_b_l2_unit] (b=1) & (fail=false) -> 1:(b'=2);
    [a_b] (b=2) & (fail=false) -> 1:(b'=3);
    [a_b_l2_unit] (b=3) & (fail=false) -> 1:(b'=2);
  endmodule
  
  module c
    c : [0..3] init 0;
  
    [] (c=3) & (fail=false) -> 1:(fail'=true);
    [c_d] (c=0) & (fail=false) -> 0:(c'=3) + 1:(c'=1);
    [c_d_l3_unit] (c=1) & (fail=false) -> 1:(c'=2);
  endmodule
  
  module d
    d : [0..3] init 0;
  
    [] (d=3) & (fail=false) -> 1:(fail'=true);
    [c_d] (d=0) & (fail=false) -> 1:(d'=1);
    [c_d_l3_unit] (d=1) & (fail=false) -> 1:(d'=2);
  endmodule
  
  label "end" = (a=5) & (b=4) & (c=2) & (d=2);
  label "cando_a_b_l1_unit" = a=0;
  label "cando_a_b_l1_unit_branch" = b=0;
  label "cando_a_b_l2_unit" = (a=0) | (a=3);
  label "cando_a_b_l2_unit_branch" = (b=0) | (b=2);
  label "cando_c_d_l3_unit" = c=0;
  label "cando_c_d_l3_unit_branch" = d=0;
  label "cando_a_b_branch" = (b=0) | (b=2);
  label "cando_c_d_branch" = d=0;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & ((("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch") & (("cando_c_d_l3_unit" & "cando_c_d_branch") => "cando_c_d_l3_unit_branch")))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.3 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9999999999999998
  
  
  
  
   ======= TEST ../examples/monty-hall-change.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always switches doors
     to either 2 or 3, depending on whichever door the host opens.
  
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-stay.ctx]. *)
  
  car : host (+) {
          0.3 : l1 . end,
          0.3 : l2 . end,
          0.3 : l3 . end
        }
  
  host : car & {
           l1 . player (+) {
             0.5 : l2 . player & l1 . end,
             0.5 : l3 . player & l1 . end
           },
           l2 . player (+) l3 . player & l2 . end,
           l3 . player (+) l2 . player & l3 . end
        }
  
  player : host & {
             l2 . host (+) l3 . end,
             l3 . host (+) l2 . end
           }
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [player_host_l1_unit] false -> 1:(closure'=false);
  endmodule
  
  module car
    car : [0..5] init 0;
  
    [] (car=5) & (fail=false) -> 1:(fail'=true);
    [car_host] (car=0) & (fail=false) -> 0.1:(car'=5) + 0.3:(car'=1) + 0.3:(car'=2) + 0.3:(car'=3);
    [car_host_l3_unit] (car=1) & (fail=false) -> 1:(car'=4);
    [car_host_l2_unit] (car=2) & (fail=false) -> 1:(car'=4);
    [car_host_l1_unit] (car=3) & (fail=false) -> 1:(car'=4);
  endmodule
  
  module host
    host : [0..18] init 0;
  
    [] (host=18) & (fail=false) -> 1:(fail'=true);
    [car_host] (host=0) & (fail=false) -> 1:(host'=1);
    [car_host_l1_unit] (host=1) & (fail=false) -> 1:(host'=10);
    [car_host_l2_unit] (host=1) & (fail=false) -> 1:(host'=6);
    [car_host_l3_unit] (host=1) & (fail=false) -> 1:(host'=2);
    [host_player] (host=10) & (fail=false) -> 0:(host'=18) + 0.5:(host'=11) + 0.5:(host'=12);
    [host_player_l3_unit] (host=11) & (fail=false) -> 1:(host'=13);
    [host_player_l2_unit] (host=12) & (fail=false) -> 1:(host'=15);
    [player_host] (host=13) & (fail=false) -> 1:(host'=14);
    [player_host_l1_unit] (host=14) & (fail=false) -> 1:(host'=17);
    [player_host] (host=15) & (fail=false) -> 1:(host'=16);
    [player_host_l1_unit] (host=16) & (fail=false) -> 1:(host'=17);
    [host_player] (host=6) & (fail=false) -> 0:(host'=18) + 1:(host'=7);
    [host_player_l3_unit] (host=7) & (fail=false) -> 1:(host'=8);
    [player_host] (host=8) & (fail=false) -> 1:(host'=9);
    [player_host_l2_unit] (host=9) & (fail=false) -> 1:(host'=17);
    [host_player] (host=2) & (fail=false) -> 0:(host'=18) + 1:(host'=3);
    [host_player_l2_unit] (host=3) & (fail=false) -> 1:(host'=4);
    [player_host] (host=4) & (fail=false) -> 1:(host'=5);
    [player_host_l3_unit] (host=5) & (fail=false) -> 1:(host'=17);
  endmodule
  
  module player
    player : [0..7] init 0;
  
    [] (player=7) & (fail=false) -> 1:(fail'=true);
    [host_player] (player=0) & (fail=false) -> 1:(player'=1);
    [host_player_l2_unit] (player=1) & (fail=false) -> 1:(player'=4);
    [host_player_l3_unit] (player=1) & (fail=false) -> 1:(player'=2);
    [player_host] (player=4) & (fail=false) -> 0:(player'=7) + 1:(player'=5);
    [player_host_l3_unit] (player=5) & (fail=false) -> 1:(player'=6);
    [player_host] (player=2) & (fail=false) -> 0:(player'=7) + 1:(player'=3);
    [player_host_l2_unit] (player=3) & (fail=false) -> 1:(player'=6);
  endmodule
  
  label "end" = (car=4) & (host=17) & (player=6);
  label "cando_car_host_l1_unit" = car=0;
  label "cando_car_host_l1_unit_branch" = host=0;
  label "cando_car_host_l2_unit" = car=0;
  label "cando_car_host_l2_unit_branch" = host=0;
  label "cando_car_host_l3_unit" = car=0;
  label "cando_car_host_l3_unit_branch" = host=0;
  label "cando_host_player_l2_unit" = (host=2) | (host=10);
  label "cando_host_player_l2_unit_branch" = player=0;
  label "cando_host_player_l3_unit" = (host=6) | (host=10);
  label "cando_host_player_l3_unit_branch" = player=0;
  label "cando_player_host_l1_unit" = false;
  label "cando_player_host_l1_unit_branch" = (host=13) | (host=15);
  label "cando_player_host_l2_unit" = player=2;
  label "cando_player_host_l2_unit_branch" = host=8;
  label "cando_player_host_l3_unit" = player=4;
  label "cando_player_host_l3_unit_branch" = host=4;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=8) | (host=13) | (host=15);
  
  // Type safety
  P>=1 [ (G ((("cando_car_host_l1_unit" & "cando_car_host_branch") => "cando_car_host_l1_unit_branch") & ((("cando_car_host_l2_unit" & "cando_car_host_branch") => "cando_car_host_l2_unit_branch") & ((("cando_car_host_l3_unit" & "cando_car_host_branch") => "cando_car_host_l3_unit_branch") & ((("cando_host_player_l2_unit" & "cando_host_player_branch") => "cando_host_player_l2_unit_branch") & ((("cando_host_player_l3_unit" & "cando_host_player_branch") => "cando_host_player_l3_unit_branch") & ((("cando_player_host_l1_unit" & "cando_player_host_branch") => "cando_player_host_l1_unit_branch") & ((("cando_player_host_l2_unit" & "cando_player_host_branch") => "cando_player_host_l2_unit_branch") & (("cando_player_host_l3_unit" & "cando_player_host_branch") => "cando_player_host_l3_unit_branch"))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.6 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.6666666666666666
  
  Probabilistic termination
  Result: 0.8999999999999999 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9999999999999999
  
  
  
  
   ======= TEST ../examples/monty-hall-stay.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always picks Door 1.
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-change.ctx]. *)
  
  car : host (+) {
          0.3 : l1 . end,
          0.3 : l2 . end,
          0.3 : l3 . end
        }
  
  host : car & {
           l1 . player (+) {
             0.5 : l2 . player & l1 . end,
             0.5 : l3 . player & l1 . end
           },
           l2 . player (+) l3 . player & l2 . end,
           l3 . player (+) l2 . player & l3 . end
        }
  
  player : host & {
             l2 . host (+) l1 . end,
             l3 . host (+) l1 . end
           }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [player_host_l2_unit] false -> 1:(closure'=false);
    [player_host_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module car
    car : [0..5] init 0;
  
    [] (car=5) & (fail=false) -> 1:(fail'=true);
    [car_host] (car=0) & (fail=false) -> 0.1:(car'=5) + 0.3:(car'=1) + 0.3:(car'=2) + 0.3:(car'=3);
    [car_host_l3_unit] (car=1) & (fail=false) -> 1:(car'=4);
    [car_host_l2_unit] (car=2) & (fail=false) -> 1:(car'=4);
    [car_host_l1_unit] (car=3) & (fail=false) -> 1:(car'=4);
  endmodule
  
  module host
    host : [0..18] init 0;
  
    [] (host=18) & (fail=false) -> 1:(fail'=true);
    [car_host] (host=0) & (fail=false) -> 1:(host'=1);
    [car_host_l1_unit] (host=1) & (fail=false) -> 1:(host'=10);
    [car_host_l2_unit] (host=1) & (fail=false) -> 1:(host'=6);
    [car_host_l3_unit] (host=1) & (fail=false) -> 1:(host'=2);
    [host_player] (host=10) & (fail=false) -> 0:(host'=18) + 0.5:(host'=11) + 0.5:(host'=12);
    [host_player_l3_unit] (host=11) & (fail=false) -> 1:(host'=13);
    [host_player_l2_unit] (host=12) & (fail=false) -> 1:(host'=15);
    [player_host] (host=13) & (fail=false) -> 1:(host'=14);
    [player_host_l1_unit] (host=14) & (fail=false) -> 1:(host'=17);
    [player_host] (host=15) & (fail=false) -> 1:(host'=16);
    [player_host_l1_unit] (host=16) & (fail=false) -> 1:(host'=17);
    [host_player] (host=6) & (fail=false) -> 0:(host'=18) + 1:(host'=7);
    [host_player_l3_unit] (host=7) & (fail=false) -> 1:(host'=8);
    [player_host] (host=8) & (fail=false) -> 1:(host'=9);
    [player_host_l2_unit] (host=9) & (fail=false) -> 1:(host'=17);
    [host_player] (host=2) & (fail=false) -> 0:(host'=18) + 1:(host'=3);
    [host_player_l2_unit] (host=3) & (fail=false) -> 1:(host'=4);
    [player_host] (host=4) & (fail=false) -> 1:(host'=5);
    [player_host_l3_unit] (host=5) & (fail=false) -> 1:(host'=17);
  endmodule
  
  module player
    player : [0..7] init 0;
  
    [] (player=7) & (fail=false) -> 1:(fail'=true);
    [host_player] (player=0) & (fail=false) -> 1:(player'=1);
    [host_player_l2_unit] (player=1) & (fail=false) -> 1:(player'=4);
    [host_player_l3_unit] (player=1) & (fail=false) -> 1:(player'=2);
    [player_host] (player=4) & (fail=false) -> 0:(player'=7) + 1:(player'=5);
    [player_host_l1_unit] (player=5) & (fail=false) -> 1:(player'=6);
    [player_host] (player=2) & (fail=false) -> 0:(player'=7) + 1:(player'=3);
    [player_host_l1_unit] (player=3) & (fail=false) -> 1:(player'=6);
  endmodule
  
  label "end" = (car=4) & (host=17) & (player=6);
  label "cando_car_host_l1_unit" = car=0;
  label "cando_car_host_l1_unit_branch" = host=0;
  label "cando_car_host_l2_unit" = car=0;
  label "cando_car_host_l2_unit_branch" = host=0;
  label "cando_car_host_l3_unit" = car=0;
  label "cando_car_host_l3_unit_branch" = host=0;
  label "cando_host_player_l2_unit" = (host=2) | (host=10);
  label "cando_host_player_l2_unit_branch" = player=0;
  label "cando_host_player_l3_unit" = (host=6) | (host=10);
  label "cando_host_player_l3_unit_branch" = player=0;
  label "cando_player_host_l1_unit" = (player=2) | (player=4);
  label "cando_player_host_l1_unit_branch" = (host=13) | (host=15);
  label "cando_player_host_l2_unit" = false;
  label "cando_player_host_l2_unit_branch" = host=8;
  label "cando_player_host_l3_unit" = false;
  label "cando_player_host_l3_unit_branch" = host=4;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=8) | (host=13) | (host=15);
  
  // Type safety
  P>=1 [ (G ((("cando_car_host_l1_unit" & "cando_car_host_branch") => "cando_car_host_l1_unit_branch") & ((("cando_car_host_l2_unit" & "cando_car_host_branch") => "cando_car_host_l2_unit_branch") & ((("cando_car_host_l3_unit" & "cando_car_host_branch") => "cando_car_host_l3_unit_branch") & ((("cando_host_player_l2_unit" & "cando_host_player_branch") => "cando_host_player_l2_unit_branch") & ((("cando_host_player_l3_unit" & "cando_host_player_branch") => "cando_host_player_l3_unit_branch") & ((("cando_player_host_l1_unit" & "cando_player_host_branch") => "cando_player_host_l1_unit_branch") & ((("cando_player_host_l2_unit" & "cando_player_host_branch") => "cando_player_host_l2_unit_branch") & (("cando_player_host_l3_unit" & "cando_player_host_branch") => "cando_player_host_l3_unit_branch"))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.33333333333333337
  
  Probabilistic termination
  Result: 0.8999999999999999 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.9999999999999999
  
  
  
  
   ======= TEST ../examples/more-choices.ctx =======
  
  p : q (+) l1 . end
  
  q : mu t . p & {
               l1 . end,
               l2 . t
             }
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [p_q_l2_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..3] init 0;
  
    [] (p=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0:(p'=3) + 1:(p'=1);
    [p_q_l1_unit] (p=1) & (fail=false) -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [] (q=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=2);
    [p_q_l2_unit] (q=1) & (fail=false) -> 1:(q'=0);
  endmodule
  
  label "end" = (p=2) & (q=2);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = false;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p_q_branch" = q=0;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & (("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch"))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/multiparty-workers.ctx =======
  
  starter : workerA1 (+) datum(Int) .
            workerA2 (+) datum(Int) .
            workerA3 (+) datum(Int) .
            end
  
  workerA1 : starter & datum(Int) .
             mu t .
               workerB1 (+) {
                 0.5 : datum(Int) . workerC1 & result(Int) . t,
                 0.5 : stop . end
               }
  
  workerB1 : mu t . 
               workerA1 & {
                 datum(Int) . workerC1 (+) datum(Int) . t,
                 stop . workerC1 (+) stop . end
               }
  
  workerC1 : mu t .
               workerB1 & {
                 datum(Int) . workerA1 (+) result(Int) . t,
                 stop . end
               }
  
  
  workerA2 : starter & datum(Int) .
             mu t .
               workerB2 (+) {
                 0.5 : datum(Int) . workerC2 & result(Int) . t,
                 0.5 : stop . end
               }
  
  workerB2 : mu t . 
               workerA2 & {
                 datum(Int) . workerC2 (+) datum(Int) . t,
                 stop . workerC2 (+) stop . end
               }
  
  workerC2 : mu t .
               workerB2 & {
                 datum(Int) . workerA2 (+) result(Int) . t,
                 stop . end
               }
  
  
  workerA3 : starter & datum(Int) .
             mu t .
               workerB3 (+) {
                 0.5 : datum(Int) . workerC3 & result(Int) . t,
                 0.5 : stop . end
               }
  
  workerB3 : mu t . 
               workerA3 & {
                 datum(Int) . workerC3 (+) datum(Int) . t,
                 stop . workerC3 (+) stop . end
               }
  
  workerC3 : mu t .
               workerB3 & {
                 datum(Int) . workerA3 (+) result(Int) . t,
                 stop . end
               }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module starter
    starter : [0..7] init 0;
  
    [] (starter=7) & (fail=false) -> 1:(fail'=true);
    [starter_workerA1] (starter=0) & (fail=false) -> 0:(starter'=7) + 1:(starter'=1);
    [starter_workerA1_datum_int] (starter=1) & (fail=false) -> 1:(starter'=2);
    [starter_workerA2] (starter=2) & (fail=false) -> 0:(starter'=7) + 1:(starter'=3);
    [starter_workerA2_datum_int] (starter=3) & (fail=false) -> 1:(starter'=4);
    [starter_workerA3] (starter=4) & (fail=false) -> 0:(starter'=7) + 1:(starter'=5);
    [starter_workerA3_datum_int] (starter=5) & (fail=false) -> 1:(starter'=6);
  endmodule
  
  module workerA1
    workerA1 : [0..8] init 0;
  
    [] (workerA1=8) & (fail=false) -> 1:(fail'=true);
    [starter_workerA1] (workerA1=0) & (fail=false) -> 1:(workerA1'=1);
    [starter_workerA1_datum_int] (workerA1=1) & (fail=false) -> 1:(workerA1'=2);
    [workerA1_workerB1] (workerA1=2) & (fail=false) -> 0:(workerA1'=8) + 0.5:(workerA1'=3) + 0.5:(workerA1'=4);
    [workerA1_workerB1_stop_unit] (workerA1=3) & (fail=false) -> 1:(workerA1'=7);
    [workerA1_workerB1_datum_int] (workerA1=4) & (fail=false) -> 1:(workerA1'=5);
    [workerC1_workerA1] (workerA1=5) & (fail=false) -> 1:(workerA1'=6);
    [workerC1_workerA1_result_int] (workerA1=6) & (fail=false) -> 1:(workerA1'=2);
  endmodule
  
  module workerB1
    workerB1 : [0..7] init 0;
  
    [] (workerB1=7) & (fail=false) -> 1:(fail'=true);
    [workerA1_workerB1] (workerB1=0) & (fail=false) -> 1:(workerB1'=1);
    [workerA1_workerB1_datum_int] (workerB1=1) & (fail=false) -> 1:(workerB1'=4);
    [workerA1_workerB1_stop_unit] (workerB1=1) & (fail=false) -> 1:(workerB1'=2);
    [workerB1_workerC1] (workerB1=4) & (fail=false) -> 0:(workerB1'=7) + 1:(workerB1'=5);
    [workerB1_workerC1_datum_int] (workerB1=5) & (fail=false) -> 1:(workerB1'=0);
    [workerB1_workerC1] (workerB1=2) & (fail=false) -> 0:(workerB1'=7) + 1:(workerB1'=3);
    [workerB1_workerC1_stop_unit] (workerB1=3) & (fail=false) -> 1:(workerB1'=6);
  endmodule
  
  module workerC1
    workerC1 : [0..5] init 0;
  
    [] (workerC1=5) & (fail=false) -> 1:(fail'=true);
    [workerB1_workerC1] (workerC1=0) & (fail=false) -> 1:(workerC1'=1);
    [workerB1_workerC1_datum_int] (workerC1=1) & (fail=false) -> 1:(workerC1'=2);
    [workerB1_workerC1_stop_unit] (workerC1=1) & (fail=false) -> 1:(workerC1'=4);
    [workerC1_workerA1] (workerC1=2) & (fail=false) -> 0:(workerC1'=5) + 1:(workerC1'=3);
    [workerC1_workerA1_result_int] (workerC1=3) & (fail=false) -> 1:(workerC1'=0);
  endmodule
  
  module workerA2
    workerA2 : [0..8] init 0;
  
    [] (workerA2=8) & (fail=false) -> 1:(fail'=true);
    [starter_workerA2] (workerA2=0) & (fail=false) -> 1:(workerA2'=1);
    [starter_workerA2_datum_int] (workerA2=1) & (fail=false) -> 1:(workerA2'=2);
    [workerA2_workerB2] (workerA2=2) & (fail=false) -> 0:(workerA2'=8) + 0.5:(workerA2'=3) + 0.5:(workerA2'=4);
    [workerA2_workerB2_stop_unit] (workerA2=3) & (fail=false) -> 1:(workerA2'=7);
    [workerA2_workerB2_datum_int] (workerA2=4) & (fail=false) -> 1:(workerA2'=5);
    [workerC2_workerA2] (workerA2=5) & (fail=false) -> 1:(workerA2'=6);
    [workerC2_workerA2_result_int] (workerA2=6) & (fail=false) -> 1:(workerA2'=2);
  endmodule
  
  module workerB2
    workerB2 : [0..7] init 0;
  
    [] (workerB2=7) & (fail=false) -> 1:(fail'=true);
    [workerA2_workerB2] (workerB2=0) & (fail=false) -> 1:(workerB2'=1);
    [workerA2_workerB2_datum_int] (workerB2=1) & (fail=false) -> 1:(workerB2'=4);
    [workerA2_workerB2_stop_unit] (workerB2=1) & (fail=false) -> 1:(workerB2'=2);
    [workerB2_workerC2] (workerB2=4) & (fail=false) -> 0:(workerB2'=7) + 1:(workerB2'=5);
    [workerB2_workerC2_datum_int] (workerB2=5) & (fail=false) -> 1:(workerB2'=0);
    [workerB2_workerC2] (workerB2=2) & (fail=false) -> 0:(workerB2'=7) + 1:(workerB2'=3);
    [workerB2_workerC2_stop_unit] (workerB2=3) & (fail=false) -> 1:(workerB2'=6);
  endmodule
  
  module workerC2
    workerC2 : [0..5] init 0;
  
    [] (workerC2=5) & (fail=false) -> 1:(fail'=true);
    [workerB2_workerC2] (workerC2=0) & (fail=false) -> 1:(workerC2'=1);
    [workerB2_workerC2_datum_int] (workerC2=1) & (fail=false) -> 1:(workerC2'=2);
    [workerB2_workerC2_stop_unit] (workerC2=1) & (fail=false) -> 1:(workerC2'=4);
    [workerC2_workerA2] (workerC2=2) & (fail=false) -> 0:(workerC2'=5) + 1:(workerC2'=3);
    [workerC2_workerA2_result_int] (workerC2=3) & (fail=false) -> 1:(workerC2'=0);
  endmodule
  
  module workerA3
    workerA3 : [0..8] init 0;
  
    [] (workerA3=8) & (fail=false) -> 1:(fail'=true);
    [starter_workerA3] (workerA3=0) & (fail=false) -> 1:(workerA3'=1);
    [starter_workerA3_datum_int] (workerA3=1) & (fail=false) -> 1:(workerA3'=2);
    [workerA3_workerB3] (workerA3=2) & (fail=false) -> 0:(workerA3'=8) + 0.5:(workerA3'=3) + 0.5:(workerA3'=4);
    [workerA3_workerB3_stop_unit] (workerA3=3) & (fail=false) -> 1:(workerA3'=7);
    [workerA3_workerB3_datum_int] (workerA3=4) & (fail=false) -> 1:(workerA3'=5);
    [workerC3_workerA3] (workerA3=5) & (fail=false) -> 1:(workerA3'=6);
    [workerC3_workerA3_result_int] (workerA3=6) & (fail=false) -> 1:(workerA3'=2);
  endmodule
  
  module workerB3
    workerB3 : [0..7] init 0;
  
    [] (workerB3=7) & (fail=false) -> 1:(fail'=true);
    [workerA3_workerB3] (workerB3=0) & (fail=false) -> 1:(workerB3'=1);
    [workerA3_workerB3_datum_int] (workerB3=1) & (fail=false) -> 1:(workerB3'=4);
    [workerA3_workerB3_stop_unit] (workerB3=1) & (fail=false) -> 1:(workerB3'=2);
    [workerB3_workerC3] (workerB3=4) & (fail=false) -> 0:(workerB3'=7) + 1:(workerB3'=5);
    [workerB3_workerC3_datum_int] (workerB3=5) & (fail=false) -> 1:(workerB3'=0);
    [workerB3_workerC3] (workerB3=2) & (fail=false) -> 0:(workerB3'=7) + 1:(workerB3'=3);
    [workerB3_workerC3_stop_unit] (workerB3=3) & (fail=false) -> 1:(workerB3'=6);
  endmodule
  
  module workerC3
    workerC3 : [0..5] init 0;
  
    [] (workerC3=5) & (fail=false) -> 1:(fail'=true);
    [workerB3_workerC3] (workerC3=0) & (fail=false) -> 1:(workerC3'=1);
    [workerB3_workerC3_datum_int] (workerC3=1) & (fail=false) -> 1:(workerC3'=2);
    [workerB3_workerC3_stop_unit] (workerC3=1) & (fail=false) -> 1:(workerC3'=4);
    [workerC3_workerA3] (workerC3=2) & (fail=false) -> 0:(workerC3'=5) + 1:(workerC3'=3);
    [workerC3_workerA3_result_int] (workerC3=3) & (fail=false) -> 1:(workerC3'=0);
  endmodule
  
  label "end" = (starter=6) & (workerA1=7) & (workerB1=6) & (workerC1=4) & (workerA2=7) & (workerB2=6) & (workerC2=4) & (workerA3=7) & (workerB3=6) & (workerC3=4);
  label "cando_starter_workerA1_datum_int" = starter=0;
  label "cando_starter_workerA1_datum_int_branch" = workerA1=0;
  label "cando_starter_workerA2_datum_int" = starter=2;
  label "cando_starter_workerA2_datum_int_branch" = workerA2=0;
  label "cando_starter_workerA3_datum_int" = starter=4;
  label "cando_starter_workerA3_datum_int_branch" = workerA3=0;
  label "cando_workerA1_workerB1_datum_int" = workerA1=2;
  label "cando_workerA1_workerB1_datum_int_branch" = workerB1=0;
  label "cando_workerA1_workerB1_stop_unit" = workerA1=2;
  label "cando_workerA1_workerB1_stop_unit_branch" = workerB1=0;
  label "cando_workerA2_workerB2_datum_int" = workerA2=2;
  label "cando_workerA2_workerB2_datum_int_branch" = workerB2=0;
  label "cando_workerA2_workerB2_stop_unit" = workerA2=2;
  label "cando_workerA2_workerB2_stop_unit_branch" = workerB2=0;
  label "cando_workerA3_workerB3_datum_int" = workerA3=2;
  label "cando_workerA3_workerB3_datum_int_branch" = workerB3=0;
  label "cando_workerA3_workerB3_stop_unit" = workerA3=2;
  label "cando_workerA3_workerB3_stop_unit_branch" = workerB3=0;
  label "cando_workerB1_workerC1_datum_int" = workerB1=4;
  label "cando_workerB1_workerC1_datum_int_branch" = workerC1=0;
  label "cando_workerB1_workerC1_stop_unit" = workerB1=2;
  label "cando_workerB1_workerC1_stop_unit_branch" = workerC1=0;
  label "cando_workerB2_workerC2_datum_int" = workerB2=4;
  label "cando_workerB2_workerC2_datum_int_branch" = workerC2=0;
  label "cando_workerB2_workerC2_stop_unit" = workerB2=2;
  label "cando_workerB2_workerC2_stop_unit_branch" = workerC2=0;
  label "cando_workerB3_workerC3_datum_int" = workerB3=4;
  label "cando_workerB3_workerC3_datum_int_branch" = workerC3=0;
  label "cando_workerB3_workerC3_stop_unit" = workerB3=2;
  label "cando_workerB3_workerC3_stop_unit_branch" = workerC3=0;
  label "cando_workerC1_workerA1_result_int" = workerC1=2;
  label "cando_workerC1_workerA1_result_int_branch" = workerA1=5;
  label "cando_workerC2_workerA2_result_int" = workerC2=2;
  label "cando_workerC2_workerA2_result_int_branch" = workerA2=5;
  label "cando_workerC3_workerA3_result_int" = workerC3=2;
  label "cando_workerC3_workerA3_result_int_branch" = workerA3=5;
  label "cando_starter_workerA1_branch" = workerA1=0;
  label "cando_starter_workerA2_branch" = workerA2=0;
  label "cando_starter_workerA3_branch" = workerA3=0;
  label "cando_workerA1_workerB1_branch" = workerB1=0;
  label "cando_workerA2_workerB2_branch" = workerB2=0;
  label "cando_workerA3_workerB3_branch" = workerB3=0;
  label "cando_workerB1_workerC1_branch" = workerC1=0;
  label "cando_workerB2_workerC2_branch" = workerC2=0;
  label "cando_workerB3_workerC3_branch" = workerC3=0;
  label "cando_workerC1_workerA1_branch" = workerA1=5;
  label "cando_workerC2_workerA2_branch" = workerA2=5;
  label "cando_workerC3_workerA3_branch" = workerA3=5;
  
  // Type safety
  P>=1 [ (G ((("cando_starter_workerA1_datum_int" & "cando_starter_workerA1_branch") => "cando_starter_workerA1_datum_int_branch") & ((("cando_starter_workerA2_datum_int" & "cando_starter_workerA2_branch") => "cando_starter_workerA2_datum_int_branch") & ((("cando_starter_workerA3_datum_int" & "cando_starter_workerA3_branch") => "cando_starter_workerA3_datum_int_branch") & ((("cando_workerA1_workerB1_datum_int" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_datum_int_branch") & ((("cando_workerA1_workerB1_stop_unit" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_stop_unit_branch") & ((("cando_workerA2_workerB2_datum_int" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_datum_int_branch") & ((("cando_workerA2_workerB2_stop_unit" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_stop_unit_branch") & ((("cando_workerA3_workerB3_datum_int" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_datum_int_branch") & ((("cando_workerA3_workerB3_stop_unit" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_stop_unit_branch") & ((("cando_workerB1_workerC1_datum_int" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_datum_int_branch") & ((("cando_workerB1_workerC1_stop_unit" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_stop_unit_branch") & ((("cando_workerB2_workerC2_datum_int" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_datum_int_branch") & ((("cando_workerB2_workerC2_stop_unit" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_stop_unit_branch") & ((("cando_workerB3_workerC3_datum_int" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_datum_int_branch") & ((("cando_workerB3_workerC3_stop_unit" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_stop_unit_branch") & ((("cando_workerC1_workerA1_result_int" & "cando_workerC1_workerA1_branch") => "cando_workerC1_workerA1_result_int_branch") & ((("cando_workerC2_workerA2_result_int" & "cando_workerC2_workerA2_branch") => "cando_workerC2_workerA2_result_int_branch") & (("cando_workerC3_workerA3_result_int" & "cando_workerC3_workerA3_branch") => "cando_workerC3_workerA3_result_int_branch"))))))))))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/non-terminating.ctx =======
  
  a : b (+) {
        0.5 : l1 . end,
        0.5 : l2 . mu t . b (+) l2 . t
      }
  
  b : mu t .
      a & {
        l1 . end,
        l2 . t
      }
      
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..6] init 0;
  
    [] (a=6) & (fail=false) -> 1:(fail'=true);
    [a_b] (a=0) & (fail=false) -> 0:(a'=6) + 0.5:(a'=1) + 0.5:(a'=2);
    [a_b_l2_unit] (a=1) & (fail=false) -> 1:(a'=3);
    [a_b_l1_unit] (a=2) & (fail=false) -> 1:(a'=5);
    [a_b] (a=3) & (fail=false) -> 0:(a'=6) + 1:(a'=4);
    [a_b_l2_unit] (a=4) & (fail=false) -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] (b=3) & (fail=false) -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_l1_unit] (b=1) & (fail=false) -> 1:(b'=2);
    [a_b_l2_unit] (b=1) & (fail=false) -> 1:(b'=0);
  endmodule
  
  label "end" = (a=5) & (b=2);
  label "cando_a_b_l1_unit" = a=0;
  label "cando_a_b_l1_unit_branch" = b=0;
  label "cando_a_b_l2_unit" = (a=0) | (a=3);
  label "cando_a_b_l2_unit_branch" = b=0;
  label "cando_a_b_branch" = b=0;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & (("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch"))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.5 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.5
  
  
  
  
   ======= TEST ../examples/open.ctx =======
  
  alice : bob (+) { 0.33 : a.end, 0.33 : b . carol(+) c . end, 0.34 : c . end }
  bob : alice & { a.end, b.end, c.end }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [alice_carol] false -> 1:(closure'=false);
    [alice_carol_c_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..7] init 0;
  
    [] (alice=7) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=7) + 0.34:(alice'=1) + 0.33:(alice'=2) + 0.33:(alice'=3);
    [alice_bob_c_unit] (alice=1) & (fail=false) -> 1:(alice'=6);
    [alice_bob_b_unit] (alice=2) & (fail=false) -> 1:(alice'=4);
    [alice_bob_a_unit] (alice=3) & (fail=false) -> 1:(alice'=6);
    [alice_carol] (alice=4) & (fail=false) -> 0:(alice'=7) + 1:(alice'=5);
    [alice_carol_c_unit] (alice=5) & (fail=false) -> 1:(alice'=6);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] (bob=3) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_a_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
    [alice_bob_b_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
    [alice_bob_c_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
  endmodule
  
  label "end" = (alice=6) & (bob=2);
  label "cando_alice_bob_a_unit" = alice=0;
  label "cando_alice_bob_a_unit_branch" = bob=0;
  label "cando_alice_bob_b_unit" = alice=0;
  label "cando_alice_bob_b_unit_branch" = bob=0;
  label "cando_alice_bob_c_unit" = alice=0;
  label "cando_alice_bob_c_unit_branch" = bob=0;
  label "cando_alice_carol_c_unit" = alice=4;
  label "cando_alice_carol_c_unit_branch" = false;
  label "cando_alice_bob_branch" = bob=0;
  label "cando_alice_carol_branch" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_a_unit" & "cando_alice_bob_branch") => "cando_alice_bob_a_unit_branch") & ((("cando_alice_bob_b_unit" & "cando_alice_bob_branch") => "cando_alice_bob_b_unit_branch") & ((("cando_alice_bob_c_unit" & "cando_alice_bob_branch") => "cando_alice_bob_c_unit_branch") & (("cando_alice_carol_c_unit" & "cando_alice_carol_branch") => "cando_alice_carol_c_unit_branch"))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.6699999999999999 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.6699999999999999
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/prob-deadlock.ctx =======
  
  commander : a (+) {
                0.7 : deadlock . end,
                0.3 : nodeadlock . end
              }
  
  a : commander & {
        deadlock . b & msg . end,
        nodeadlock . b (+) msg . end
      }
  
  b : a & msg . end
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [b_a] false -> 1:(closure'=false);
    [b_a_msg_unit] false -> 1:(closure'=false);
  endmodule
  
  module commander
    commander : [0..4] init 0;
  
    [] (commander=4) & (fail=false) -> 1:(fail'=true);
    [commander_a] (commander=0) & (fail=false) -> 0:(commander'=4) + 0.3:(commander'=1) + 0.7:(commander'=2);
    [commander_a_nodeadlock_unit] (commander=1) & (fail=false) -> 1:(commander'=3);
    [commander_a_deadlock_unit] (commander=2) & (fail=false) -> 1:(commander'=3);
  endmodule
  
  module a
    a : [0..7] init 0;
  
    [] (a=7) & (fail=false) -> 1:(fail'=true);
    [commander_a] (a=0) & (fail=false) -> 1:(a'=1);
    [commander_a_deadlock_unit] (a=1) & (fail=false) -> 1:(a'=4);
    [commander_a_nodeadlock_unit] (a=1) & (fail=false) -> 1:(a'=2);
    [b_a] (a=4) & (fail=false) -> 1:(a'=5);
    [b_a_msg_unit] (a=5) & (fail=false) -> 1:(a'=6);
    [a_b] (a=2) & (fail=false) -> 0:(a'=7) + 1:(a'=3);
    [a_b_msg_unit] (a=3) & (fail=false) -> 1:(a'=6);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] (b=3) & (fail=false) -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_msg_unit] (b=1) & (fail=false) -> 1:(b'=2);
  endmodule
  
  label "end" = (commander=3) & (a=6) & (b=2);
  label "cando_a_b_msg_unit" = a=2;
  label "cando_a_b_msg_unit_branch" = b=0;
  label "cando_b_a_msg_unit" = false;
  label "cando_b_a_msg_unit_branch" = a=4;
  label "cando_commander_a_deadlock_unit" = commander=0;
  label "cando_commander_a_deadlock_unit_branch" = a=0;
  label "cando_commander_a_nodeadlock_unit" = commander=0;
  label "cando_commander_a_nodeadlock_unit_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=4;
  label "cando_commander_a_branch" = a=0;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_msg_unit" & "cando_a_b_branch") => "cando_a_b_msg_unit_branch") & ((("cando_b_a_msg_unit" & "cando_b_a_branch") => "cando_b_a_msg_unit_branch") & ((("cando_commander_a_deadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_deadlock_unit_branch") & (("cando_commander_a_nodeadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_unit_branch"))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.30000000000000004
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/prob-over-one.ctx =======
  
  a : b (+) { 0.4 : l1 . end, 0.7 : l2 . end }
  
  b : a & { l1 . end, l2 . end } 
   ======= PRISM output ========
  
  Typing context is not well-formed: probabilities sum to greater than one. Found 1.100000
  
  
   ======= Property checking =======
  
  Typing context is not well-formed: probabilities sum to greater than one. Found 1.100000
  
  
  
  
  
   ======= TEST ../examples/rec-map-reduce.ctx =======
  
  mapper : mu t .
             worker1 (+) datum(Int) .
             worker2 (+) datum(Int) .
             worker3 (+) datum(Int) .
             reducer & {
               continue(Int) . t,
               stop . 
                 worker1 (+) stop .
                 worker2 (+) stop .
                 worker3 (+) stop .
                 end
             }
  
  worker1 : mapper & datum(Int) .
            mu t .
              reducer (+) result(Int) .
              mapper & {
                datum(Int) . t,
                stop . end
              }
  
  worker2 : mapper & datum(Int) .
            mu t .
              reducer (+) result(Int) .
              mapper & {
                datum(Int) . t,
                stop . end
              }
  
  worker3 : mapper & datum(Int) .
            mu t .
              reducer (+) result(Int) .
              mapper & {
                datum(Int) . t,
                stop . end
              }
  
  reducer : mu t .
              worker1 & result(Int) .
              worker2 & result(Int) .
              worker3 & result(Int) .
              mapper (+) {
                0.4 : continue(Int) . t,
                0.6 : stop.end
              }
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module mapper
    mapper : [0..15] init 0;
  
    [] (mapper=15) & (fail=false) -> 1:(fail'=true);
    [mapper_worker1] (mapper=0) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=1);
    [mapper_worker1_datum_int] (mapper=1) & (fail=false) -> 1:(mapper'=2);
    [mapper_worker2] (mapper=2) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=3);
    [mapper_worker2_datum_int] (mapper=3) & (fail=false) -> 1:(mapper'=4);
    [mapper_worker3] (mapper=4) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=5);
    [mapper_worker3_datum_int] (mapper=5) & (fail=false) -> 1:(mapper'=6);
    [reducer_mapper] (mapper=6) & (fail=false) -> 1:(mapper'=7);
    [reducer_mapper_continue_int] (mapper=7) & (fail=false) -> 1:(mapper'=0);
    [reducer_mapper_stop_unit] (mapper=7) & (fail=false) -> 1:(mapper'=8);
    [mapper_worker1] (mapper=8) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=9);
    [mapper_worker1_stop_unit] (mapper=9) & (fail=false) -> 1:(mapper'=10);
    [mapper_worker2] (mapper=10) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=11);
    [mapper_worker2_stop_unit] (mapper=11) & (fail=false) -> 1:(mapper'=12);
    [mapper_worker3] (mapper=12) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=13);
    [mapper_worker3_stop_unit] (mapper=13) & (fail=false) -> 1:(mapper'=14);
  endmodule
  
  module worker1
    worker1 : [0..7] init 0;
  
    [] (worker1=7) & (fail=false) -> 1:(fail'=true);
    [mapper_worker1] (worker1=0) & (fail=false) -> 1:(worker1'=1);
    [mapper_worker1_datum_int] (worker1=1) & (fail=false) -> 1:(worker1'=2);
    [worker1_reducer] (worker1=2) & (fail=false) -> 0:(worker1'=7) + 1:(worker1'=3);
    [worker1_reducer_result_int] (worker1=3) & (fail=false) -> 1:(worker1'=4);
    [mapper_worker1] (worker1=4) & (fail=false) -> 1:(worker1'=5);
    [mapper_worker1_datum_int] (worker1=5) & (fail=false) -> 1:(worker1'=2);
    [mapper_worker1_stop_unit] (worker1=5) & (fail=false) -> 1:(worker1'=6);
  endmodule
  
  module worker2
    worker2 : [0..7] init 0;
  
    [] (worker2=7) & (fail=false) -> 1:(fail'=true);
    [mapper_worker2] (worker2=0) & (fail=false) -> 1:(worker2'=1);
    [mapper_worker2_datum_int] (worker2=1) & (fail=false) -> 1:(worker2'=2);
    [worker2_reducer] (worker2=2) & (fail=false) -> 0:(worker2'=7) + 1:(worker2'=3);
    [worker2_reducer_result_int] (worker2=3) & (fail=false) -> 1:(worker2'=4);
    [mapper_worker2] (worker2=4) & (fail=false) -> 1:(worker2'=5);
    [mapper_worker2_datum_int] (worker2=5) & (fail=false) -> 1:(worker2'=2);
    [mapper_worker2_stop_unit] (worker2=5) & (fail=false) -> 1:(worker2'=6);
  endmodule
  
  module worker3
    worker3 : [0..7] init 0;
  
    [] (worker3=7) & (fail=false) -> 1:(fail'=true);
    [mapper_worker3] (worker3=0) & (fail=false) -> 1:(worker3'=1);
    [mapper_worker3_datum_int] (worker3=1) & (fail=false) -> 1:(worker3'=2);
    [worker3_reducer] (worker3=2) & (fail=false) -> 0:(worker3'=7) + 1:(worker3'=3);
    [worker3_reducer_result_int] (worker3=3) & (fail=false) -> 1:(worker3'=4);
    [mapper_worker3] (worker3=4) & (fail=false) -> 1:(worker3'=5);
    [mapper_worker3_datum_int] (worker3=5) & (fail=false) -> 1:(worker3'=2);
    [mapper_worker3_stop_unit] (worker3=5) & (fail=false) -> 1:(worker3'=6);
  endmodule
  
  module reducer
    reducer : [0..10] init 0;
  
    [] (reducer=10) & (fail=false) -> 1:(fail'=true);
    [worker1_reducer] (reducer=0) & (fail=false) -> 1:(reducer'=1);
    [worker1_reducer_result_int] (reducer=1) & (fail=false) -> 1:(reducer'=2);
    [worker2_reducer] (reducer=2) & (fail=false) -> 1:(reducer'=3);
    [worker2_reducer_result_int] (reducer=3) & (fail=false) -> 1:(reducer'=4);
    [worker3_reducer] (reducer=4) & (fail=false) -> 1:(reducer'=5);
    [worker3_reducer_result_int] (reducer=5) & (fail=false) -> 1:(reducer'=6);
    [reducer_mapper] (reducer=6) & (fail=false) -> 0:(reducer'=10) + 0.6:(reducer'=7) + 0.4:(reducer'=8);
    [reducer_mapper_stop_unit] (reducer=7) & (fail=false) -> 1:(reducer'=9);
    [reducer_mapper_continue_int] (reducer=8) & (fail=false) -> 1:(reducer'=0);
  endmodule
  
  label "end" = (mapper=14) & (worker1=6) & (worker2=6) & (worker3=6) & (reducer=9);
  label "cando_mapper_worker1_datum_int" = mapper=0;
  label "cando_mapper_worker1_datum_int_branch" = (worker1=0) | (worker1=4);
  label "cando_mapper_worker1_stop_unit" = mapper=8;
  label "cando_mapper_worker1_stop_unit_branch" = worker1=4;
  label "cando_mapper_worker2_datum_int" = mapper=2;
  label "cando_mapper_worker2_datum_int_branch" = (worker2=0) | (worker2=4);
  label "cando_mapper_worker2_stop_unit" = mapper=10;
  label "cando_mapper_worker2_stop_unit_branch" = worker2=4;
  label "cando_mapper_worker3_datum_int" = mapper=4;
  label "cando_mapper_worker3_datum_int_branch" = (worker3=0) | (worker3=4);
  label "cando_mapper_worker3_stop_unit" = mapper=12;
  label "cando_mapper_worker3_stop_unit_branch" = worker3=4;
  label "cando_reducer_mapper_continue_int" = reducer=6;
  label "cando_reducer_mapper_continue_int_branch" = mapper=6;
  label "cando_reducer_mapper_stop_unit" = reducer=6;
  label "cando_reducer_mapper_stop_unit_branch" = mapper=6;
  label "cando_worker1_reducer_result_int" = worker1=2;
  label "cando_worker1_reducer_result_int_branch" = reducer=0;
  label "cando_worker2_reducer_result_int" = worker2=2;
  label "cando_worker2_reducer_result_int_branch" = reducer=2;
  label "cando_worker3_reducer_result_int" = worker3=2;
  label "cando_worker3_reducer_result_int_branch" = reducer=4;
  label "cando_mapper_worker1_branch" = (worker1=0) | (worker1=4);
  label "cando_mapper_worker2_branch" = (worker2=0) | (worker2=4);
  label "cando_mapper_worker3_branch" = (worker3=0) | (worker3=4);
  label "cando_reducer_mapper_branch" = mapper=6;
  label "cando_worker1_reducer_branch" = reducer=0;
  label "cando_worker2_reducer_branch" = reducer=2;
  label "cando_worker3_reducer_branch" = reducer=4;
  
  // Type safety
  P>=1 [ (G ((("cando_mapper_worker1_datum_int" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_datum_int_branch") & ((("cando_mapper_worker1_stop_unit" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_stop_unit_branch") & ((("cando_mapper_worker2_datum_int" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_datum_int_branch") & ((("cando_mapper_worker2_stop_unit" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_stop_unit_branch") & ((("cando_mapper_worker3_datum_int" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_datum_int_branch") & ((("cando_mapper_worker3_stop_unit" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_stop_unit_branch") & ((("cando_reducer_mapper_continue_int" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_continue_int_branch") & ((("cando_reducer_mapper_stop_unit" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_stop_unit_branch") & ((("cando_worker1_reducer_result_int" & "cando_worker1_reducer_branch") => "cando_worker1_reducer_result_int_branch") & ((("cando_worker2_reducer_result_int" & "cando_worker2_reducer_branch") => "cando_worker2_reducer_result_int_branch") & (("cando_worker3_reducer_result_int" & "cando_worker3_reducer_branch") => "cando_worker3_reducer_result_int_branch")))))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/rec-two-buyers.ctx =======
  
  alice: shop(+)query(Str) .
         shop&price(Int) .
         mu t .
            bob (+) {
                0.5 : split(Int) . bob & {yes . shop (+) buy . end, no . t},
                0.5 : cancel . shop (+) no . end
            }
  
  shop: alice&query(Str) . alice(+)price(Int) . alice&{buy.end, no.end}
  
  bob: mu t .
         alice & {
           split(Int) . alice (+) {0.5 : yes.end, 0.5 : no.t},
           cancel . end
         }
                
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module alice
    alice : [0..14] init 0;
  
    [] (alice=14) & (fail=false) -> 1:(fail'=true);
    [alice_shop] (alice=0) & (fail=false) -> 0:(alice'=14) + 1:(alice'=1);
    [alice_shop_query_str] (alice=1) & (fail=false) -> 1:(alice'=2);
    [shop_alice] (alice=2) & (fail=false) -> 1:(alice'=3);
    [shop_alice_price_int] (alice=3) & (fail=false) -> 1:(alice'=4);
    [alice_bob] (alice=4) & (fail=false) -> 0:(alice'=14) + 0.5:(alice'=5) + 0.5:(alice'=6);
    [alice_bob_split_int] (alice=5) & (fail=false) -> 1:(alice'=7);
    [alice_bob_cancel_unit] (alice=6) & (fail=false) -> 1:(alice'=11);
    [bob_alice] (alice=7) & (fail=false) -> 1:(alice'=8);
    [bob_alice_yes_unit] (alice=8) & (fail=false) -> 1:(alice'=9);
    [bob_alice_no_unit] (alice=8) & (fail=false) -> 1:(alice'=4);
    [alice_shop] (alice=9) & (fail=false) -> 0:(alice'=14) + 1:(alice'=10);
    [alice_shop_buy_unit] (alice=10) & (fail=false) -> 1:(alice'=13);
    [alice_shop] (alice=11) & (fail=false) -> 0:(alice'=14) + 1:(alice'=12);
    [alice_shop_no_unit] (alice=12) & (fail=false) -> 1:(alice'=13);
  endmodule
  
  module shop
    shop : [0..7] init 0;
  
    [] (shop=7) & (fail=false) -> 1:(fail'=true);
    [alice_shop] (shop=0) & (fail=false) -> 1:(shop'=1);
    [alice_shop_query_str] (shop=1) & (fail=false) -> 1:(shop'=2);
    [shop_alice] (shop=2) & (fail=false) -> 0:(shop'=7) + 1:(shop'=3);
    [shop_alice_price_int] (shop=3) & (fail=false) -> 1:(shop'=4);
    [alice_shop] (shop=4) & (fail=false) -> 1:(shop'=5);
    [alice_shop_buy_unit] (shop=5) & (fail=false) -> 1:(shop'=6);
    [alice_shop_no_unit] (shop=5) & (fail=false) -> 1:(shop'=6);
  endmodule
  
  module bob
    bob : [0..6] init 0;
  
    [] (bob=6) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_split_int] (bob=1) & (fail=false) -> 1:(bob'=2);
    [alice_bob_cancel_unit] (bob=1) & (fail=false) -> 1:(bob'=5);
    [bob_alice] (bob=2) & (fail=false) -> 0:(bob'=6) + 0.5:(bob'=3) + 0.5:(bob'=4);
    [bob_alice_yes_unit] (bob=3) & (fail=false) -> 1:(bob'=5);
    [bob_alice_no_unit] (bob=4) & (fail=false) -> 1:(bob'=0);
  endmodule
  
  label "end" = (alice=13) & (shop=6) & (bob=5);
  label "cando_alice_bob_cancel_unit" = alice=4;
  label "cando_alice_bob_cancel_unit_branch" = bob=0;
  label "cando_alice_bob_split_int" = alice=4;
  label "cando_alice_bob_split_int_branch" = bob=0;
  label "cando_alice_shop_buy_unit" = alice=9;
  label "cando_alice_shop_buy_unit_branch" = shop=4;
  label "cando_alice_shop_no_unit" = alice=11;
  label "cando_alice_shop_no_unit_branch" = shop=4;
  label "cando_alice_shop_query_str" = alice=0;
  label "cando_alice_shop_query_str_branch" = shop=0;
  label "cando_bob_alice_no_unit" = bob=2;
  label "cando_bob_alice_no_unit_branch" = alice=7;
  label "cando_bob_alice_yes_unit" = bob=2;
  label "cando_bob_alice_yes_unit_branch" = alice=7;
  label "cando_shop_alice_price_int" = shop=2;
  label "cando_shop_alice_price_int_branch" = alice=2;
  label "cando_alice_bob_branch" = bob=0;
  label "cando_alice_shop_branch" = (shop=0) | (shop=4);
  label "cando_bob_alice_branch" = alice=7;
  label "cando_shop_alice_branch" = alice=2;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_cancel_unit" & "cando_alice_bob_branch") => "cando_alice_bob_cancel_unit_branch") & ((("cando_alice_bob_split_int" & "cando_alice_bob_branch") => "cando_alice_bob_split_int_branch") & ((("cando_alice_shop_buy_unit" & "cando_alice_shop_branch") => "cando_alice_shop_buy_unit_branch") & ((("cando_alice_shop_no_unit" & "cando_alice_shop_branch") => "cando_alice_shop_no_unit_branch") & ((("cando_alice_shop_query_str" & "cando_alice_shop_branch") => "cando_alice_shop_query_str_branch") & ((("cando_bob_alice_no_unit" & "cando_bob_alice_branch") => "cando_bob_alice_no_unit_branch") & ((("cando_bob_alice_yes_unit" & "cando_bob_alice_branch") => "cando_bob_alice_yes_unit_branch") & (("cando_shop_alice_price_int" & "cando_shop_alice_branch") => "cando_shop_alice_price_int_branch"))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/same-labels.ctx =======
  
  (* Previous iterations of the translation used ID(-) to work out the next state.
     This causes a problem in the following case.
  
     Suppose p::q::l1 is assigned ID 2 and p::q::l2 is assigned ID 1, and the state
     after q (+) l2 to be n. Then, the second q (+) l1 will first do an initial
     translation to n + 1, then skip by two to n + 3. This will exceed the state
     space of p.
  
     This test checks for this case.
  *)
  
  p : q (+) {
        0.5 : l1 . end,
        0.5 : l2 . q (+) l1 . end
      }
  
  q : p & {
        l1 . end,
        l2 . p & l1 . end
      }
  
  
  (* Try the symmetric case for if the ID ordering changes *)
  
  p1 : q1 (+) {
        0.5 : l1 . q1 (+) l2 . end,
        0.5 : l2 . end
      }
  
  q1 : p1 & {
        l1 . p1 & l2 . end,
        l2 . end
      }
  
  
  (* Shuffle the ordering of the two branches *)
  
  q2 : p2 & {
        l1 . end,
        l2 . p2 & l1 . end
      }
  
  p2 : q2 (+) {
        0.5 : l2 . q2 (+) l1 . end,
        0.5 : l1 . end
      }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p
    p : [0..6] init 0;
  
    [] (p=6) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0:(p'=6) + 0.5:(p'=1) + 0.5:(p'=2);
    [p_q_l2_unit] (p=1) & (fail=false) -> 1:(p'=3);
    [p_q_l1_unit] (p=2) & (fail=false) -> 1:(p'=5);
    [p_q] (p=3) & (fail=false) -> 0:(p'=6) + 1:(p'=4);
    [p_q_l1_unit] (p=4) & (fail=false) -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..5] init 0;
  
    [] (q=5) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=4);
    [p_q_l2_unit] (q=1) & (fail=false) -> 1:(q'=2);
    [p_q] (q=2) & (fail=false) -> 1:(q'=3);
    [p_q_l1_unit] (q=3) & (fail=false) -> 1:(q'=4);
  endmodule
  
  module p1
    p1 : [0..6] init 0;
  
    [] (p1=6) & (fail=false) -> 1:(fail'=true);
    [p1_q1] (p1=0) & (fail=false) -> 0:(p1'=6) + 0.5:(p1'=1) + 0.5:(p1'=2);
    [p1_q1_l2_unit] (p1=1) & (fail=false) -> 1:(p1'=5);
    [p1_q1_l1_unit] (p1=2) & (fail=false) -> 1:(p1'=3);
    [p1_q1] (p1=3) & (fail=false) -> 0:(p1'=6) + 1:(p1'=4);
    [p1_q1_l2_unit] (p1=4) & (fail=false) -> 1:(p1'=5);
  endmodule
  
  module q1
    q1 : [0..5] init 0;
  
    [] (q1=5) & (fail=false) -> 1:(fail'=true);
    [p1_q1] (q1=0) & (fail=false) -> 1:(q1'=1);
    [p1_q1_l1_unit] (q1=1) & (fail=false) -> 1:(q1'=2);
    [p1_q1_l2_unit] (q1=1) & (fail=false) -> 1:(q1'=4);
    [p1_q1] (q1=2) & (fail=false) -> 1:(q1'=3);
    [p1_q1_l2_unit] (q1=3) & (fail=false) -> 1:(q1'=4);
  endmodule
  
  module q2
    q2 : [0..5] init 0;
  
    [] (q2=5) & (fail=false) -> 1:(fail'=true);
    [p2_q2] (q2=0) & (fail=false) -> 1:(q2'=1);
    [p2_q2_l1_unit] (q2=1) & (fail=false) -> 1:(q2'=4);
    [p2_q2_l2_unit] (q2=1) & (fail=false) -> 1:(q2'=2);
    [p2_q2] (q2=2) & (fail=false) -> 1:(q2'=3);
    [p2_q2_l1_unit] (q2=3) & (fail=false) -> 1:(q2'=4);
  endmodule
  
  module p2
    p2 : [0..6] init 0;
  
    [] (p2=6) & (fail=false) -> 1:(fail'=true);
    [p2_q2] (p2=0) & (fail=false) -> 0:(p2'=6) + 0.5:(p2'=1) + 0.5:(p2'=2);
    [p2_q2_l2_unit] (p2=1) & (fail=false) -> 1:(p2'=3);
    [p2_q2_l1_unit] (p2=2) & (fail=false) -> 1:(p2'=5);
    [p2_q2] (p2=3) & (fail=false) -> 0:(p2'=6) + 1:(p2'=4);
    [p2_q2_l1_unit] (p2=4) & (fail=false) -> 1:(p2'=5);
  endmodule
  
  label "end" = (p=5) & (q=4) & (p1=5) & (q1=4) & (q2=4) & (p2=5);
  label "cando_p_q_l1_unit" = (p=0) | (p=3);
  label "cando_p_q_l1_unit_branch" = (q=0) | (q=2);
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p1_q1_l1_unit" = p1=0;
  label "cando_p1_q1_l1_unit_branch" = q1=0;
  label "cando_p1_q1_l2_unit" = (p1=0) | (p1=3);
  label "cando_p1_q1_l2_unit_branch" = (q1=0) | (q1=2);
  label "cando_p2_q2_l1_unit" = (p2=0) | (p2=3);
  label "cando_p2_q2_l1_unit_branch" = (q2=0) | (q2=2);
  label "cando_p2_q2_l2_unit" = p2=0;
  label "cando_p2_q2_l2_unit_branch" = q2=0;
  label "cando_p_q_branch" = (q=0) | (q=2);
  label "cando_p1_q1_branch" = (q1=0) | (q1=2);
  label "cando_p2_q2_branch" = (q2=0) | (q2=2);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & ((("cando_p1_q1_l1_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l1_unit_branch") & ((("cando_p1_q1_l2_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l2_unit_branch") & ((("cando_p2_q2_l1_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l1_unit_branch") & (("cando_p2_q2_l2_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l2_unit_branch"))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/simple.ctx =======
  
  alice : bob (+) { 0.33 : a.end, 0.67 : b(Int).end }
  bob : alice & { a.end, b(Int).end }
  
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module alice
    alice : [0..4] init 0;
  
    [] (alice=4) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=4) + 0.67:(alice'=1) + 0.33:(alice'=2);
    [alice_bob_b_int] (alice=1) & (fail=false) -> 1:(alice'=3);
    [alice_bob_a_unit] (alice=2) & (fail=false) -> 1:(alice'=3);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] (bob=3) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_a_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
    [alice_bob_b_int] (bob=1) & (fail=false) -> 1:(bob'=2);
  endmodule
  
  label "end" = (alice=3) & (bob=2);
  label "cando_alice_bob_a_unit" = alice=0;
  label "cando_alice_bob_a_unit_branch" = bob=0;
  label "cando_alice_bob_b_int" = alice=0;
  label "cando_alice_bob_b_int_branch" = bob=0;
  label "cando_alice_bob_branch" = bob=0;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_a_unit" & "cando_alice_bob_branch") => "cando_alice_bob_a_unit_branch") & (("cando_alice_bob_b_int" & "cando_alice_bob_branch") => "cando_alice_bob_b_int_branch"))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/subprob.ctx =======
  
  (* Case where PDF is different from NPDF, due to unknown behaviour *)
  
  commander : a (+) {
                0.5 : deadlock . end,
                0.3 : nodeadlock . end
              }
  
  a : commander & {
        deadlock . b & msg . end,
        nodeadlock . b (+) msg . end
      }
  
  b : a & msg . end
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [b_a] false -> 1:(closure'=false);
    [b_a_msg_unit] false -> 1:(closure'=false);
  endmodule
  
  module commander
    commander : [0..4] init 0;
  
    [] (commander=4) & (fail=false) -> 1:(fail'=true);
    [commander_a] (commander=0) & (fail=false) -> 0.2:(commander'=4) + 0.3:(commander'=1) + 0.5:(commander'=2);
    [commander_a_nodeadlock_unit] (commander=1) & (fail=false) -> 1:(commander'=3);
    [commander_a_deadlock_unit] (commander=2) & (fail=false) -> 1:(commander'=3);
  endmodule
  
  module a
    a : [0..7] init 0;
  
    [] (a=7) & (fail=false) -> 1:(fail'=true);
    [commander_a] (a=0) & (fail=false) -> 1:(a'=1);
    [commander_a_deadlock_unit] (a=1) & (fail=false) -> 1:(a'=4);
    [commander_a_nodeadlock_unit] (a=1) & (fail=false) -> 1:(a'=2);
    [b_a] (a=4) & (fail=false) -> 1:(a'=5);
    [b_a_msg_unit] (a=5) & (fail=false) -> 1:(a'=6);
    [a_b] (a=2) & (fail=false) -> 0:(a'=7) + 1:(a'=3);
    [a_b_msg_unit] (a=3) & (fail=false) -> 1:(a'=6);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] (b=3) & (fail=false) -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_msg_unit] (b=1) & (fail=false) -> 1:(b'=2);
  endmodule
  
  label "end" = (commander=3) & (a=6) & (b=2);
  label "cando_a_b_msg_unit" = a=2;
  label "cando_a_b_msg_unit_branch" = b=0;
  label "cando_b_a_msg_unit" = false;
  label "cando_b_a_msg_unit_branch" = a=4;
  label "cando_commander_a_deadlock_unit" = commander=0;
  label "cando_commander_a_deadlock_unit_branch" = a=0;
  label "cando_commander_a_nodeadlock_unit" = commander=0;
  label "cando_commander_a_nodeadlock_unit_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=4;
  label "cando_commander_a_branch" = a=0;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_msg_unit" & "cando_a_b_branch") => "cando_a_b_msg_unit_branch") & ((("cando_b_a_msg_unit" & "cando_b_a_branch") => "cando_b_a_msg_unit_branch") & ((("cando_commander_a_deadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_deadlock_unit_branch") & (("cando_commander_a_nodeadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_unit_branch"))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.37500000000000006
  
  Probabilistic termination
  Result: 0.8 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/sync-alone.ctx =======
  
  (* What happens if we send to a recipient who does not ever expect to receive? *)
  
  alice : bob (+) {
  	        0.4 : l1 . end,
  	        0.6 : l2 . end
          }
  
  bob : charlie & {
  	      l1 . end,
  	      l2 . end
        }
  
  charlie : bob (+) {
  	          0.5 : l1 . end,
  	          0.5 : l2 . end
            }
  
  (* What about the other way? *)
  
  a : b & {
        l1 . end,
        l2 . end
      }
  
  b : c (+) {
        0.7 : l1 . end,
        0.3 : l2 . end
      }
  
  c : b & {
        l1 . end,
        l2 . end
      }
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [alice_bob] false -> 1:(closure'=false);
    [alice_bob_l1_unit] false -> 1:(closure'=false);
    [alice_bob_l2_unit] false -> 1:(closure'=false);
    [b_a] false -> 1:(closure'=false);
    [b_a_l1_unit] false -> 1:(closure'=false);
    [b_a_l2_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..4] init 0;
  
    [] (alice=4) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=4) + 0.6:(alice'=1) + 0.4:(alice'=2);
    [alice_bob_l2_unit] (alice=1) & (fail=false) -> 1:(alice'=3);
    [alice_bob_l1_unit] (alice=2) & (fail=false) -> 1:(alice'=3);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] (bob=3) & (fail=false) -> 1:(fail'=true);
    [charlie_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [charlie_bob_l1_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
    [charlie_bob_l2_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
  endmodule
  
  module charlie
    charlie : [0..4] init 0;
  
    [] (charlie=4) & (fail=false) -> 1:(fail'=true);
    [charlie_bob] (charlie=0) & (fail=false) -> 0:(charlie'=4) + 0.5:(charlie'=1) + 0.5:(charlie'=2);
    [charlie_bob_l2_unit] (charlie=1) & (fail=false) -> 1:(charlie'=3);
    [charlie_bob_l1_unit] (charlie=2) & (fail=false) -> 1:(charlie'=3);
  endmodule
  
  module a
    a : [0..3] init 0;
  
    [] (a=3) & (fail=false) -> 1:(fail'=true);
    [b_a] (a=0) & (fail=false) -> 1:(a'=1);
    [b_a_l1_unit] (a=1) & (fail=false) -> 1:(a'=2);
    [b_a_l2_unit] (a=1) & (fail=false) -> 1:(a'=2);
  endmodule
  
  module b
    b : [0..4] init 0;
  
    [] (b=4) & (fail=false) -> 1:(fail'=true);
    [b_c] (b=0) & (fail=false) -> 0:(b'=4) + 0.3:(b'=1) + 0.7:(b'=2);
    [b_c_l2_unit] (b=1) & (fail=false) -> 1:(b'=3);
    [b_c_l1_unit] (b=2) & (fail=false) -> 1:(b'=3);
  endmodule
  
  module c
    c : [0..3] init 0;
  
    [] (c=3) & (fail=false) -> 1:(fail'=true);
    [b_c] (c=0) & (fail=false) -> 1:(c'=1);
    [b_c_l1_unit] (c=1) & (fail=false) -> 1:(c'=2);
    [b_c_l2_unit] (c=1) & (fail=false) -> 1:(c'=2);
  endmodule
  
  label "end" = (alice=3) & (bob=2) & (charlie=3) & (a=2) & (b=3) & (c=2);
  label "cando_alice_bob_l1_unit" = alice=0;
  label "cando_alice_bob_l1_unit_branch" = false;
  label "cando_alice_bob_l2_unit" = alice=0;
  label "cando_alice_bob_l2_unit_branch" = false;
  label "cando_b_a_l1_unit" = false;
  label "cando_b_a_l1_unit_branch" = a=0;
  label "cando_b_a_l2_unit" = false;
  label "cando_b_a_l2_unit_branch" = a=0;
  label "cando_b_c_l1_unit" = b=0;
  label "cando_b_c_l1_unit_branch" = c=0;
  label "cando_b_c_l2_unit" = b=0;
  label "cando_b_c_l2_unit_branch" = c=0;
  label "cando_charlie_bob_l1_unit" = charlie=0;
  label "cando_charlie_bob_l1_unit_branch" = bob=0;
  label "cando_charlie_bob_l2_unit" = charlie=0;
  label "cando_charlie_bob_l2_unit_branch" = bob=0;
  label "cando_alice_bob_branch" = false;
  label "cando_b_a_branch" = a=0;
  label "cando_b_c_branch" = c=0;
  label "cando_charlie_bob_branch" = bob=0;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_l1_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l1_unit_branch") & ((("cando_alice_bob_l2_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l2_unit_branch") & ((("cando_b_a_l1_unit" & "cando_b_a_branch") => "cando_b_a_l1_unit_branch") & ((("cando_b_a_l2_unit" & "cando_b_a_branch") => "cando_b_a_l2_unit_branch") & ((("cando_b_c_l1_unit" & "cando_b_c_branch") => "cando_b_c_l1_unit_branch") & ((("cando_b_c_l2_unit" & "cando_b_c_branch") => "cando_b_c_l2_unit_branch") & ((("cando_charlie_bob_l1_unit" & "cando_charlie_bob_branch") => "cando_charlie_bob_l1_unit_branch") & (("cando_charlie_bob_l2_unit" & "cando_charlie_bob_branch") => "cando_charlie_bob_l2_unit_branch"))))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/translation-example.ctx =======
  
  (* Translation example *)
  
  p : q (+) {
        0.2 : l1 . mu t . q (+) l1 . t,
        0.3 : l2 . q (+) l2 . end,
        0.4 : l3 . end
  }
  
  q : p & {
        l1 . mu t. p & l1 . t,
        l2 . p & l2 . end,
        l3 . end
  }
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p
    p : [0..9] init 0;
  
    [] (p=9) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0.1:(p'=9) + 0.4:(p'=1) + 0.3:(p'=2) + 0.2:(p'=3);
    [p_q_l3_unit] (p=1) & (fail=false) -> 1:(p'=8);
    [p_q_l2_unit] (p=2) & (fail=false) -> 1:(p'=4);
    [p_q_l1_unit] (p=3) & (fail=false) -> 1:(p'=6);
    [p_q] (p=4) & (fail=false) -> 0:(p'=9) + 1:(p'=5);
    [p_q_l2_unit] (p=5) & (fail=false) -> 1:(p'=8);
    [p_q] (p=6) & (fail=false) -> 0:(p'=9) + 1:(p'=7);
    [p_q_l1_unit] (p=7) & (fail=false) -> 1:(p'=6);
  endmodule
  
  module q
    q : [0..7] init 0;
  
    [] (q=7) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=4);
    [p_q_l2_unit] (q=1) & (fail=false) -> 1:(q'=2);
    [p_q_l3_unit] (q=1) & (fail=false) -> 1:(q'=6);
    [p_q] (q=4) & (fail=false) -> 1:(q'=5);
    [p_q_l1_unit] (q=5) & (fail=false) -> 1:(q'=4);
    [p_q] (q=2) & (fail=false) -> 1:(q'=3);
    [p_q_l2_unit] (q=3) & (fail=false) -> 1:(q'=6);
  endmodule
  
  label "end" = (p=8) & (q=6);
  label "cando_p_q_l1_unit" = (p=0) | (p=6);
  label "cando_p_q_l1_unit_branch" = (q=0) | (q=4);
  label "cando_p_q_l2_unit" = (p=0) | (p=4);
  label "cando_p_q_l2_unit_branch" = (q=0) | (q=2);
  label "cando_p_q_l3_unit" = p=0;
  label "cando_p_q_l3_unit_branch" = q=0;
  label "cando_p_q_branch" = (q=0) | (q=2) | (q=4);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.9 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.7 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.7777777777777777
  
  
  
  
   ======= TEST ../examples/unbound-variable.ctx =======
  
  a : mu t . b (+) { 0.5 : l1 . t1, 0.5 : l2 . end }
  
  b : mu t . a & { l1 . end, l2 . end }
   ======= PRISM output ========
  
  Typing context is not well-formed: unbound variable t1
  
  
   ======= Property checking =======
  
  Typing context is not well-formed: unbound variable t1
  
  
  
  
  
   ======= TEST ../examples/unsafe-2.ctx =======
  
  (* Two pairs being unsafe in parallel *)
  
  a : b (+) {
        0.4 : l1 . end,
        0.6 : l2 . end
      }
  
  b : a & {
        l2 . end,
        l3 . end
      }
  
  c : d (+) {
        0.3 : l1 . end,
        0.7 : l2 . end
      }
  
  d : c & {
        l2 . end,
        l3 . end
      }
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [a_b_l1_unit] false -> 1:(closure'=false);
    [a_b_l3_unit] false -> 1:(closure'=false);
    [c_d_l1_unit] false -> 1:(closure'=false);
    [c_d_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module a
    a : [0..4] init 0;
  
    [] (a=4) & (fail=false) -> 1:(fail'=true);
    [a_b] (a=0) & (fail=false) -> 0:(a'=4) + 0.6:(a'=1) + 0.4:(a'=2);
    [a_b_l2_unit] (a=1) & (fail=false) -> 1:(a'=3);
    [a_b_l1_unit] (a=2) & (fail=false) -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] (b=3) & (fail=false) -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_l2_unit] (b=1) & (fail=false) -> 1:(b'=2);
    [a_b_l3_unit] (b=1) & (fail=false) -> 1:(b'=2);
  endmodule
  
  module c
    c : [0..4] init 0;
  
    [] (c=4) & (fail=false) -> 1:(fail'=true);
    [c_d] (c=0) & (fail=false) -> 0:(c'=4) + 0.7:(c'=1) + 0.3:(c'=2);
    [c_d_l2_unit] (c=1) & (fail=false) -> 1:(c'=3);
    [c_d_l1_unit] (c=2) & (fail=false) -> 1:(c'=3);
  endmodule
  
  module d
    d : [0..3] init 0;
  
    [] (d=3) & (fail=false) -> 1:(fail'=true);
    [c_d] (d=0) & (fail=false) -> 1:(d'=1);
    [c_d_l2_unit] (d=1) & (fail=false) -> 1:(d'=2);
    [c_d_l3_unit] (d=1) & (fail=false) -> 1:(d'=2);
  endmodule
  
  label "end" = (a=3) & (b=2) & (c=3) & (d=2);
  label "cando_a_b_l1_unit" = a=0;
  label "cando_a_b_l1_unit_branch" = false;
  label "cando_a_b_l2_unit" = a=0;
  label "cando_a_b_l2_unit_branch" = b=0;
  label "cando_a_b_l3_unit" = false;
  label "cando_a_b_l3_unit_branch" = b=0;
  label "cando_c_d_l1_unit" = c=0;
  label "cando_c_d_l1_unit_branch" = false;
  label "cando_c_d_l2_unit" = c=0;
  label "cando_c_d_l2_unit_branch" = d=0;
  label "cando_c_d_l3_unit" = false;
  label "cando_c_d_l3_unit_branch" = d=0;
  label "cando_a_b_branch" = b=0;
  label "cando_c_d_branch" = d=0;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & ((("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch") & ((("cando_a_b_l3_unit" & "cando_a_b_branch") => "cando_a_b_l3_unit_branch") & ((("cando_c_d_l1_unit" & "cando_c_d_branch") => "cando_c_d_l1_unit_branch") & ((("cando_c_d_l2_unit" & "cando_c_d_branch") => "cando_c_d_l2_unit_branch") & (("cando_c_d_l3_unit" & "cando_c_d_branch") => "cando_c_d_l3_unit_branch"))))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.41999999999999993 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.41999999999999993
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/unsafe.ctx =======
  
  alice : bob (+) {
            0.6 : l1 . end,
            0.3 : l2 .
                  bob (+) {
                    0.9 : l3 . end,
                    0.1 : l4 . end
                  },
            0.1 : l5 . end
          }
  
  bob : alice & {
          l1 . end,
          l2 . alice & l3 . end
        }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [alice_bob_l4_unit] false -> 1:(closure'=false);
    [alice_bob_l5_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..8] init 0;
  
    [] (alice=8) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=8) + 0.1:(alice'=1) + 0.3:(alice'=2) + 0.6:(alice'=3);
    [alice_bob_l5_unit] (alice=1) & (fail=false) -> 1:(alice'=7);
    [alice_bob_l2_unit] (alice=2) & (fail=false) -> 1:(alice'=4);
    [alice_bob_l1_unit] (alice=3) & (fail=false) -> 1:(alice'=7);
    [alice_bob] (alice=4) & (fail=false) -> 0:(alice'=8) + 0.1:(alice'=5) + 0.9:(alice'=6);
    [alice_bob_l4_unit] (alice=5) & (fail=false) -> 1:(alice'=7);
    [alice_bob_l3_unit] (alice=6) & (fail=false) -> 1:(alice'=7);
  endmodule
  
  module bob
    bob : [0..5] init 0;
  
    [] (bob=5) & (fail=false) -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_l1_unit] (bob=1) & (fail=false) -> 1:(bob'=4);
    [alice_bob_l2_unit] (bob=1) & (fail=false) -> 1:(bob'=2);
    [alice_bob] (bob=2) & (fail=false) -> 1:(bob'=3);
    [alice_bob_l3_unit] (bob=3) & (fail=false) -> 1:(bob'=4);
  endmodule
  
  label "end" = (alice=7) & (bob=4);
  label "cando_alice_bob_l1_unit" = alice=0;
  label "cando_alice_bob_l1_unit_branch" = bob=0;
  label "cando_alice_bob_l2_unit" = alice=0;
  label "cando_alice_bob_l2_unit_branch" = bob=0;
  label "cando_alice_bob_l3_unit" = alice=4;
  label "cando_alice_bob_l3_unit_branch" = bob=2;
  label "cando_alice_bob_l4_unit" = alice=4;
  label "cando_alice_bob_l4_unit_branch" = false;
  label "cando_alice_bob_l5_unit" = alice=0;
  label "cando_alice_bob_l5_unit_branch" = false;
  label "cando_alice_bob_branch" = (bob=0) | (bob=2);
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_l1_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l1_unit_branch") & ((("cando_alice_bob_l2_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l2_unit_branch") & ((("cando_alice_bob_l3_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l3_unit_branch") & ((("cando_alice_bob_l4_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l4_unit_branch") & (("cando_alice_bob_l5_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l5_unit_branch")))))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.87 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.87
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/zero-probability-df.ctx =======
  
  (* This context has a zero-probability reduction into a deadlocked context. *)
  
  p : q (+) { 0.5 : l1 . end, 0 : l2 . q (+) l3 . end }
  q : p & { l1 . end, l2 . end }
   ======= PRISM output ========
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [p_q_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..6] init 0;
  
    [] (p=6) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0.5:(p'=6) + 0:(p'=1) + 0.5:(p'=2);
    [p_q_l2_unit] (p=1) & (fail=false) -> 1:(p'=3);
    [p_q_l1_unit] (p=2) & (fail=false) -> 1:(p'=5);
    [p_q] (p=3) & (fail=false) -> 0:(p'=6) + 1:(p'=4);
    [p_q_l3_unit] (p=4) & (fail=false) -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [] (q=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=2);
    [p_q_l2_unit] (q=1) & (fail=false) -> 1:(q'=2);
  endmodule
  
  label "end" = (p=5) & (q=2);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p_q_l3_unit" = p=3;
  label "cando_p_q_l3_unit_branch" = false;
  label "cando_p_q_branch" = q=0;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.5 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.5 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  
  
  
   ======= TEST ../examples/zero-probability-only.ctx =======
  
  (* This context has only zero-probability reductions, making normalised properties undefined. *)
  
  p : q (+) { 0 : l1 . end }
  q : p & l1 . end
   ======= PRISM output ========
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p
    p : [0..3] init 0;
  
    [] (p=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 1:(p'=3) + 0:(p'=1);
    [p_q_l1_unit] (p=1) & (fail=false) -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [] (q=3) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=2);
  endmodule
  
  label "end" = (p=2) & (q=2);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_branch" = q=0;
  
  // Type safety
  P>=1 [ (G (("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch")) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.0
  
  Probabilistic termination
  Result: 0.0 (exact floating point)
  
  Normalised probabilistic termination
  Result: 0.0
  
  
  
  
   ======= TEST ../examples/zero-probability-unsafe.ctx =======
  
  (* This context has a zero-probability reduction into an unsafe context. *)
  
  p : q (+) { 0.5 : l1 . end, 0 : l2 . q (+) l3 . end }
  q : p & { l1 . end, l2 . p & l2 . end }
  
   ======= PRISM output ========
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [p_q_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..6] init 0;
  
    [] (p=6) & (fail=false) -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0.5:(p'=6) + 0:(p'=1) + 0.5:(p'=2);
    [p_q_l2_unit] (p=1) & (fail=false) -> 1:(p'=3);
    [p_q_l1_unit] (p=2) & (fail=false) -> 1:(p'=5);
    [p_q] (p=3) & (fail=false) -> 0:(p'=6) + 1:(p'=4);
    [p_q_l3_unit] (p=4) & (fail=false) -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..5] init 0;
  
    [] (q=5) & (fail=false) -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l1_unit] (q=1) & (fail=false) -> 1:(q'=4);
    [p_q_l2_unit] (q=1) & (fail=false) -> 1:(q'=2);
    [p_q] (q=2) & (fail=false) -> 1:(q'=3);
    [p_q_l2_unit] (q=3) & (fail=false) -> 1:(q'=4);
  endmodule
  
  label "end" = (p=5) & (q=4);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = (q=0) | (q=2);
  label "cando_p_q_l3_unit" = p=3;
  label "cando_p_q_l3_unit_branch" = false;
  label "cando_p_q_branch" = (q=0) | (q=2);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Probabilistic deadlock freedom
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Normalised probabilistic deadlock freedom
  (Pmin=? [ (G ("deadlock" => "end")) ] / Pmin=? [ (G (!fail)) ])
  
  // Probabilistic termination
  Pmin=? [ (F ("deadlock" & (!fail))) ]
  
  // Normalised probabilistic termination
  (Pmin=? [ (F ("deadlock" & (!fail))) ] / Pmin=? [ (G (!fail)) ])
  
   ======= Property checking =======
  
  Warning: found zero-probability in context. Non-probabilistic properties (e.g. safety) may be inaccurate, and normalised probabilities may be undefined. If you are not already, use flag [-balance] to check non-probabilistic properties. See help options for [verify]/[output] for more details on [-balance].
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.5 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.5 (exact floating point)
  
  Normalised probabilistic termination
  Result: 1.0
  
  

