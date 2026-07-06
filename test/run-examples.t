For each context file in this directory, run [prose output] to check the model and properties output, then run [prose verify] to verify the properties using PRISM.

  $ for i in ../examples/*.ctx; do echo "\n\n ======= TEST $i =======\n"; cat "$i"; echo "\n ======= PRISM output ========\n"; prose output "$i"; echo "\n ======= Property checking =======\n"; prose verify "$i"; echo "\n"; done
  
  
   ======= TEST ../examples/auth.ctx =======
  
  (* Running example from the paper *)
  
  s : & {
        b ? connect . (+) {
                   c ! 0.6 : login . & { a ? authorise . end },
                   c ! 0.4 : cancel . (+) { e ! 1.0 : stop . end }
                 },
        b ? err . mu t . & { b ? retry . t }
      }
  
  c : & {
        s ? login . (+) { a ! 1.0 : pass . end },
        s ? cancel . (+) { a ! 1.0 : quit . end }
      }
  
  a : & {
        c ? pass . (+) { s ! 1.0 : authorise . end },
        c ? quit . end
      }
  
  b : (+) {
        s ! 0.6 : connect . end,
        s ! 0.4 : err . mu t . (+) { s ! 1.0 : retry . t }
      }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [s_e_stop_unit] false -> 1:(closure'=false);
  endmodule
  
  module s
    s : [0..8] init 0;
  
    [b_s_connect_unit] s=0 -> 1:(s'=1);
    [b_s_err_unit] s=0 -> 1:(s'=7);
    [] s=1 -> 0.6:(s'=2) + 0.4:(s'=3);
    [s_c_login_unit] s=2 -> 1:(s'=4);
    [s_c_cancel_unit] s=3 -> 1:(s'=5);
    [a_s_authorise_unit] s=4 -> 1:(s'=8);
    [] s=5 -> 1:(s'=6);
    [s_e_stop_unit] s=6 -> 1:(s'=8);
    [b_s_retry_unit] s=7 -> 1:(s'=7);
  endmodule
  
  module c
    c : [0..5] init 0;
  
    [s_c_login_unit] c=0 -> 1:(c'=1);
    [s_c_cancel_unit] c=0 -> 1:(c'=3);
    [] c=1 -> 1:(c'=2);
    [c_a_pass_unit] c=2 -> 1:(c'=5);
    [] c=3 -> 1:(c'=4);
    [c_a_quit_unit] c=4 -> 1:(c'=5);
  endmodule
  
  module a
    a : [0..3] init 0;
  
    [c_a_pass_unit] a=0 -> 1:(a'=1);
    [c_a_quit_unit] a=0 -> 1:(a'=3);
    [] a=1 -> 1:(a'=2);
    [a_s_authorise_unit] a=2 -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..5] init 0;
  
    [] b=0 -> 0.6:(b'=1) + 0.4:(b'=2);
    [b_s_connect_unit] b=1 -> 1:(b'=5);
    [b_s_err_unit] b=2 -> 1:(b'=3);
    [] b=3 -> 1:(b'=4);
    [b_s_retry_unit] b=4 -> 1:(b'=3);
  endmodule
  
  label "end" = (s=8) & (c=5) & (a=3) & (b=5);
  label "cando_a_s_authorise_unit" = a=1;
  label "cando_a_s_authorise_unit_branch" = s=4;
  label "cando_b_s_connect_unit" = b=0;
  label "cando_b_s_connect_unit_branch" = s=0;
  label "cando_b_s_err_unit" = b=0;
  label "cando_b_s_err_unit_branch" = s=0;
  label "cando_b_s_retry_unit" = b=3;
  label "cando_b_s_retry_unit_branch" = s=7;
  label "cando_c_a_pass_unit" = c=1;
  label "cando_c_a_pass_unit_branch" = a=0;
  label "cando_c_a_quit_unit" = c=3;
  label "cando_c_a_quit_unit_branch" = a=0;
  label "cando_s_c_cancel_unit" = s=1;
  label "cando_s_c_cancel_unit_branch" = c=0;
  label "cando_s_c_login_unit" = s=1;
  label "cando_s_c_login_unit_branch" = c=0;
  label "cando_s_e_stop_unit" = s=5;
  label "cando_s_e_stop_unit_branch" = false;
  label "cando_a_s_branch" = s=4;
  label "cando_b_s_branch" = (s=0) | (s=7);
  label "cando_c_a_branch" = a=0;
  label "cando_s_c_branch" = c=0;
  label "cando_s_e_branch" = false;
  label "wals" = ((s=0) & (c=0) & (a=0) & (b=2)) | ((s=6) & (c=4) & (a=0) & (b=5)) | ((s=6) & (c=5) & (a=3) & (b=5)) | ((s=7) & (c=0) & (a=0) & (b=4));
  
  // Type safety
  P>=1 [ (G ((("cando_a_s_authorise_unit" & "cando_a_s_branch") => "cando_a_s_authorise_unit_branch") & ((("cando_b_s_connect_unit" & "cando_b_s_branch") => "cando_b_s_connect_unit_branch") & ((("cando_b_s_err_unit" & "cando_b_s_branch") => "cando_b_s_err_unit_branch") & ((("cando_b_s_retry_unit" & "cando_b_s_branch") => "cando_b_s_retry_unit_branch") & ((("cando_c_a_pass_unit" & "cando_c_a_branch") => "cando_c_a_pass_unit_branch") & ((("cando_c_a_quit_unit" & "cando_c_a_branch") => "cando_c_a_quit_unit_branch") & ((("cando_s_c_cancel_unit" & "cando_s_c_branch") => "cando_s_c_cancel_unit_branch") & ((("cando_s_c_login_unit" & "cando_s_c_branch") => "cando_s_c_login_unit_branch") & (("cando_s_e_stop_unit" & "cando_s_e_branch") => "cando_s_e_stop_unit_branch")))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.76 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.36 (exact floating point)
  
  
  
  
   ======= TEST ../examples/dice.ctx =======
  
  (* Knuth & Yao's Dice Program. Refer to https://www.prismmodelchecker.org/casestudies/dice.php
  
     We represent each vertex i with two processes (pi, qi), which allows us to simulate internal
     choice sending to different participants.
  *)
  
  p0 : (+) {
          q0 ! 0.5 : l1 . end,
          q0 ! 0.5 : l2 . end
       }
  
  q0 : & {
          p0 ? l1 . mu t .
               (+) { p1 ! 1.0 : go . & { q3 ? redo . t } },
          p0 ? l2 . mu t .
               (+) { p2 ! 1.0 : go . & { q6 ? redo . t } }
       }
  
  p1 : mu t .
       & { q0 ? go .
       (+) {
          q1 ! 0.5 : l3 . t,
          q1 ! 0.5 : l4 . t
       } }
  
  q1 : mu t.
       & {
          p1 ? l3 . (+) { p3 ! 1.0 : go . t },
          p1 ? l4 . (+) { p4 ! 1.0 : go . t }
       }
  
  p2 : mu t.
       & { q0 ? go .
       (+) {
          q2 ! 0.5 : l5 . t,
          q2 ! 0.5 : l6 . t
       } }
  
  q2 : mu t .
       & {
          p2 ? l5 . (+) { p5 ! 1.0 : go . t },
          p2 ? l6 . (+) { p6 ! 1.0 : go . t }
       }
  
  p3 : mu t .
       & { q1 ? go .
       (+) {
          q3 ! 0.5 : l1 . t,
          q3 ! 0.5 : d1 . end
       } }
  
  q3 : mu t .
       & {
          p3 ? l1 . (+) { q0 ! 1.0 : redo . t },
          p3 ? d1 . (+) { dice1 ! 1.0 : done . end }
       }
  
  p4 : & { q1 ? go .
       (+) {
          q4 ! 0.5 : d2 . end,
          q4 ! 0.5 : d3 . end
       } }
  
  q4 : & {
          p4 ? d2 . (+) { dice2 ! 1.0 : done . end },
          p4 ? d3 . (+) { dice3 ! 1.0 : done . end }
       }
  
  p5 : & { q2 ? go .
       (+) {
          q5 ! 0.5 : d4 . end,
          q5 ! 0.5 : d5 . end
       } }
  
  q5 : & {
          p5 ? d4 . (+) { dice4 ! 1.0 : done . end },
          p5 ? d5 . (+) { dice5 ! 1.0 : done . end }
       }
  
  p6 : mu t .
       & { q2 ? go .
       (+) {
          q6 ! 0.5 : d6 . end,
          q6 ! 0.5 : l2 . end
       } }
  
  q6 : mu t .
       & {
          p6 ? d6 . (+) { dice6 ! 1.0 : done . end },
          p6 ? l2 . (+) { q0 ! 1.0 : redo . t }
       }
  
  (* Each of these should be of 1/6 probability *)
  
  dice1 : & { q3 ? done . mu t . (+) { dummy ! 1.0 : repeat . t } }
  dice2 : & { q4 ? done . end }
  dice3 : & { q4 ? done . end }
  dice4 : & { q5 ? done . end }
  dice5 : & { q5 ? done . end }
  dice6 : & { q6 ? done . end }
  
  dummy : mu t . & { dice1 ? repeat . t }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p0
    p0 : [0..3] init 0;
  
    [] p0=0 -> 0.5:(p0'=1) + 0.5:(p0'=2);
    [p0_q0_l1_unit] p0=1 -> 1:(p0'=3);
    [p0_q0_l2_unit] p0=2 -> 1:(p0'=3);
  endmodule
  
  module q0
    q0 : [0..7] init 0;
  
    [p0_q0_l1_unit] q0=0 -> 1:(q0'=1);
    [p0_q0_l2_unit] q0=0 -> 1:(q0'=4);
    [] q0=1 -> 1:(q0'=2);
    [q0_p1_go_unit] q0=2 -> 1:(q0'=3);
    [q3_q0_redo_unit] q0=3 -> 1:(q0'=1);
    [] q0=4 -> 1:(q0'=5);
    [q0_p2_go_unit] q0=5 -> 1:(q0'=6);
    [q6_q0_redo_unit] q0=6 -> 1:(q0'=4);
  endmodule
  
  module p1
    p1 : [0..4] init 0;
  
    [q0_p1_go_unit] p1=0 -> 1:(p1'=1);
    [] p1=1 -> 0.5:(p1'=2) + 0.5:(p1'=3);
    [p1_q1_l3_unit] p1=2 -> 1:(p1'=0);
    [p1_q1_l4_unit] p1=3 -> 1:(p1'=0);
  endmodule
  
  module q1
    q1 : [0..5] init 0;
  
    [p1_q1_l3_unit] q1=0 -> 1:(q1'=1);
    [p1_q1_l4_unit] q1=0 -> 1:(q1'=3);
    [] q1=1 -> 1:(q1'=2);
    [q1_p3_go_unit] q1=2 -> 1:(q1'=0);
    [] q1=3 -> 1:(q1'=4);
    [q1_p4_go_unit] q1=4 -> 1:(q1'=0);
  endmodule
  
  module p2
    p2 : [0..4] init 0;
  
    [q0_p2_go_unit] p2=0 -> 1:(p2'=1);
    [] p2=1 -> 0.5:(p2'=2) + 0.5:(p2'=3);
    [p2_q2_l5_unit] p2=2 -> 1:(p2'=0);
    [p2_q2_l6_unit] p2=3 -> 1:(p2'=0);
  endmodule
  
  module q2
    q2 : [0..5] init 0;
  
    [p2_q2_l5_unit] q2=0 -> 1:(q2'=1);
    [p2_q2_l6_unit] q2=0 -> 1:(q2'=3);
    [] q2=1 -> 1:(q2'=2);
    [q2_p5_go_unit] q2=2 -> 1:(q2'=0);
    [] q2=3 -> 1:(q2'=4);
    [q2_p6_go_unit] q2=4 -> 1:(q2'=0);
  endmodule
  
  module p3
    p3 : [0..4] init 0;
  
    [q1_p3_go_unit] p3=0 -> 1:(p3'=1);
    [] p3=1 -> 0.5:(p3'=2) + 0.5:(p3'=3);
    [p3_q3_l1_unit] p3=2 -> 1:(p3'=0);
    [p3_q3_d1_unit] p3=3 -> 1:(p3'=4);
  endmodule
  
  module q3
    q3 : [0..5] init 0;
  
    [p3_q3_l1_unit] q3=0 -> 1:(q3'=1);
    [p3_q3_d1_unit] q3=0 -> 1:(q3'=3);
    [] q3=1 -> 1:(q3'=2);
    [q3_q0_redo_unit] q3=2 -> 1:(q3'=0);
    [] q3=3 -> 1:(q3'=4);
    [q3_dice1_done_unit] q3=4 -> 1:(q3'=5);
  endmodule
  
  module p4
    p4 : [0..4] init 0;
  
    [q1_p4_go_unit] p4=0 -> 1:(p4'=1);
    [] p4=1 -> 0.5:(p4'=2) + 0.5:(p4'=3);
    [p4_q4_d2_unit] p4=2 -> 1:(p4'=4);
    [p4_q4_d3_unit] p4=3 -> 1:(p4'=4);
  endmodule
  
  module q4
    q4 : [0..5] init 0;
  
    [p4_q4_d2_unit] q4=0 -> 1:(q4'=1);
    [p4_q4_d3_unit] q4=0 -> 1:(q4'=3);
    [] q4=1 -> 1:(q4'=2);
    [q4_dice2_done_unit] q4=2 -> 1:(q4'=5);
    [] q4=3 -> 1:(q4'=4);
    [q4_dice3_done_unit] q4=4 -> 1:(q4'=5);
  endmodule
  
  module p5
    p5 : [0..4] init 0;
  
    [q2_p5_go_unit] p5=0 -> 1:(p5'=1);
    [] p5=1 -> 0.5:(p5'=2) + 0.5:(p5'=3);
    [p5_q5_d4_unit] p5=2 -> 1:(p5'=4);
    [p5_q5_d5_unit] p5=3 -> 1:(p5'=4);
  endmodule
  
  module q5
    q5 : [0..5] init 0;
  
    [p5_q5_d4_unit] q5=0 -> 1:(q5'=1);
    [p5_q5_d5_unit] q5=0 -> 1:(q5'=3);
    [] q5=1 -> 1:(q5'=2);
    [q5_dice4_done_unit] q5=2 -> 1:(q5'=5);
    [] q5=3 -> 1:(q5'=4);
    [q5_dice5_done_unit] q5=4 -> 1:(q5'=5);
  endmodule
  
  module p6
    p6 : [0..4] init 0;
  
    [q2_p6_go_unit] p6=0 -> 1:(p6'=1);
    [] p6=1 -> 0.5:(p6'=2) + 0.5:(p6'=3);
    [p6_q6_d6_unit] p6=2 -> 1:(p6'=4);
    [p6_q6_l2_unit] p6=3 -> 1:(p6'=4);
  endmodule
  
  module q6
    q6 : [0..5] init 0;
  
    [p6_q6_d6_unit] q6=0 -> 1:(q6'=1);
    [p6_q6_l2_unit] q6=0 -> 1:(q6'=3);
    [] q6=1 -> 1:(q6'=2);
    [q6_dice6_done_unit] q6=2 -> 1:(q6'=5);
    [] q6=3 -> 1:(q6'=4);
    [q6_q0_redo_unit] q6=4 -> 1:(q6'=0);
  endmodule
  
  module dice1
    dice1 : [0..3] init 0;
  
    [q3_dice1_done_unit] dice1=0 -> 1:(dice1'=1);
    [] dice1=1 -> 1:(dice1'=2);
    [dice1_dummy_repeat_unit] dice1=2 -> 1:(dice1'=1);
  endmodule
  
  module dice2
    dice2 : [0..1] init 0;
  
    [q4_dice2_done_unit] dice2=0 -> 1:(dice2'=1);
  endmodule
  
  module dice3
    dice3 : [0..1] init 0;
  
    [q4_dice3_done_unit] dice3=0 -> 1:(dice3'=1);
  endmodule
  
  module dice4
    dice4 : [0..1] init 0;
  
    [q5_dice4_done_unit] dice4=0 -> 1:(dice4'=1);
  endmodule
  
  module dice5
    dice5 : [0..1] init 0;
  
    [q5_dice5_done_unit] dice5=0 -> 1:(dice5'=1);
  endmodule
  
  module dice6
    dice6 : [0..1] init 0;
  
    [q6_dice6_done_unit] dice6=0 -> 1:(dice6'=1);
  endmodule
  
  module dummy
    dummy : [0..1] init 0;
  
    [dice1_dummy_repeat_unit] dummy=0 -> 1:(dummy'=0);
  endmodule
  
  label "end" = (p0=3) & (q0=7) & (p1=4) & (q1=5) & (p2=4) & (q2=5) & (p3=4) & (q3=5) & (p4=4) & (q4=5) & (p5=4) & (q5=5) & (p6=4) & (q6=5) & (dice1=3) & (dice2=1) & (dice3=1) & (dice4=1) & (dice5=1) & (dice6=1) & (dummy=1);
  label "cando_dice1_dummy_repeat_unit" = dice1=1;
  label "cando_dice1_dummy_repeat_unit_branch" = dummy=0;
  label "cando_p0_q0_l1_unit" = p0=0;
  label "cando_p0_q0_l1_unit_branch" = q0=0;
  label "cando_p0_q0_l2_unit" = p0=0;
  label "cando_p0_q0_l2_unit_branch" = q0=0;
  label "cando_p1_q1_l3_unit" = p1=1;
  label "cando_p1_q1_l3_unit_branch" = q1=0;
  label "cando_p1_q1_l4_unit" = p1=1;
  label "cando_p1_q1_l4_unit_branch" = q1=0;
  label "cando_p2_q2_l5_unit" = p2=1;
  label "cando_p2_q2_l5_unit_branch" = q2=0;
  label "cando_p2_q2_l6_unit" = p2=1;
  label "cando_p2_q2_l6_unit_branch" = q2=0;
  label "cando_p3_q3_d1_unit" = p3=1;
  label "cando_p3_q3_d1_unit_branch" = q3=0;
  label "cando_p3_q3_l1_unit" = p3=1;
  label "cando_p3_q3_l1_unit_branch" = q3=0;
  label "cando_p4_q4_d2_unit" = p4=1;
  label "cando_p4_q4_d2_unit_branch" = q4=0;
  label "cando_p4_q4_d3_unit" = p4=1;
  label "cando_p4_q4_d3_unit_branch" = q4=0;
  label "cando_p5_q5_d4_unit" = p5=1;
  label "cando_p5_q5_d4_unit_branch" = q5=0;
  label "cando_p5_q5_d5_unit" = p5=1;
  label "cando_p5_q5_d5_unit_branch" = q5=0;
  label "cando_p6_q6_d6_unit" = p6=1;
  label "cando_p6_q6_d6_unit_branch" = q6=0;
  label "cando_p6_q6_l2_unit" = p6=1;
  label "cando_p6_q6_l2_unit_branch" = q6=0;
  label "cando_q0_p1_go_unit" = q0=1;
  label "cando_q0_p1_go_unit_branch" = p1=0;
  label "cando_q0_p2_go_unit" = q0=4;
  label "cando_q0_p2_go_unit_branch" = p2=0;
  label "cando_q1_p3_go_unit" = q1=1;
  label "cando_q1_p3_go_unit_branch" = p3=0;
  label "cando_q1_p4_go_unit" = q1=3;
  label "cando_q1_p4_go_unit_branch" = p4=0;
  label "cando_q2_p5_go_unit" = q2=1;
  label "cando_q2_p5_go_unit_branch" = p5=0;
  label "cando_q2_p6_go_unit" = q2=3;
  label "cando_q2_p6_go_unit_branch" = p6=0;
  label "cando_q3_dice1_done_unit" = q3=3;
  label "cando_q3_dice1_done_unit_branch" = dice1=0;
  label "cando_q3_q0_redo_unit" = q3=1;
  label "cando_q3_q0_redo_unit_branch" = q0=3;
  label "cando_q4_dice2_done_unit" = q4=1;
  label "cando_q4_dice2_done_unit_branch" = dice2=0;
  label "cando_q4_dice3_done_unit" = q4=3;
  label "cando_q4_dice3_done_unit_branch" = dice3=0;
  label "cando_q5_dice4_done_unit" = q5=1;
  label "cando_q5_dice4_done_unit_branch" = dice4=0;
  label "cando_q5_dice5_done_unit" = q5=3;
  label "cando_q5_dice5_done_unit_branch" = dice5=0;
  label "cando_q6_dice6_done_unit" = q6=1;
  label "cando_q6_dice6_done_unit_branch" = dice6=0;
  label "cando_q6_q0_redo_unit" = q6=3;
  label "cando_q6_q0_redo_unit_branch" = q0=6;
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
  label "cando_q3_q0_branch" = q0=3;
  label "cando_q4_dice2_branch" = dice2=0;
  label "cando_q4_dice3_branch" = dice3=0;
  label "cando_q5_dice4_branch" = dice4=0;
  label "cando_q5_dice5_branch" = dice5=0;
  label "cando_q6_dice6_branch" = dice6=0;
  label "cando_q6_q0_branch" = q0=6;
  label "wals" = ((p0=1) & (q0=0) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=2) & (q0=0) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=2) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=2) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=3) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=4) & (q4=2) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=4) & (q4=4) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=4) & (q4=5) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=1) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=4) & (q4=5) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=1) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=2) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=2) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=3) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=4) & (q3=4) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=4) & (q3=5) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=2) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=2) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=0) & (q1=4) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=2) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=3) & (p1=3) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=5) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=5) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=2) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=3) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=2) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=4) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=5) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=1) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=2) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=2) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=3) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=3) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=2) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=2) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=4) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=4) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=5) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=1) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=5) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=1) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=5) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=1) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=4) & (q5=5) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=1) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=2) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=2) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=4) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=0) & (q2=4) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=2) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=2) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=3) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=0) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0)) | ((p0=3) & (q0=6) & (p1=0) & (q1=0) & (p2=3) & (q2=0) & (p3=0) & (q3=0) & (p4=0) & (q4=0) & (p5=0) & (q5=0) & (p6=4) & (q6=0) & (dice1=0) & (dice2=0) & (dice3=0) & (dice4=0) & (dice5=0) & (dice6=0) & (dummy=0));
  
  // Type safety
  P>=1 [ (G ((("cando_dice1_dummy_repeat_unit" & "cando_dice1_dummy_branch") => "cando_dice1_dummy_repeat_unit_branch") & ((("cando_p0_q0_l1_unit" & "cando_p0_q0_branch") => "cando_p0_q0_l1_unit_branch") & ((("cando_p0_q0_l2_unit" & "cando_p0_q0_branch") => "cando_p0_q0_l2_unit_branch") & ((("cando_p1_q1_l3_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l3_unit_branch") & ((("cando_p1_q1_l4_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l4_unit_branch") & ((("cando_p2_q2_l5_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l5_unit_branch") & ((("cando_p2_q2_l6_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l6_unit_branch") & ((("cando_p3_q3_d1_unit" & "cando_p3_q3_branch") => "cando_p3_q3_d1_unit_branch") & ((("cando_p3_q3_l1_unit" & "cando_p3_q3_branch") => "cando_p3_q3_l1_unit_branch") & ((("cando_p4_q4_d2_unit" & "cando_p4_q4_branch") => "cando_p4_q4_d2_unit_branch") & ((("cando_p4_q4_d3_unit" & "cando_p4_q4_branch") => "cando_p4_q4_d3_unit_branch") & ((("cando_p5_q5_d4_unit" & "cando_p5_q5_branch") => "cando_p5_q5_d4_unit_branch") & ((("cando_p5_q5_d5_unit" & "cando_p5_q5_branch") => "cando_p5_q5_d5_unit_branch") & ((("cando_p6_q6_d6_unit" & "cando_p6_q6_branch") => "cando_p6_q6_d6_unit_branch") & ((("cando_p6_q6_l2_unit" & "cando_p6_q6_branch") => "cando_p6_q6_l2_unit_branch") & ((("cando_q0_p1_go_unit" & "cando_q0_p1_branch") => "cando_q0_p1_go_unit_branch") & ((("cando_q0_p2_go_unit" & "cando_q0_p2_branch") => "cando_q0_p2_go_unit_branch") & ((("cando_q1_p3_go_unit" & "cando_q1_p3_branch") => "cando_q1_p3_go_unit_branch") & ((("cando_q1_p4_go_unit" & "cando_q1_p4_branch") => "cando_q1_p4_go_unit_branch") & ((("cando_q2_p5_go_unit" & "cando_q2_p5_branch") => "cando_q2_p5_go_unit_branch") & ((("cando_q2_p6_go_unit" & "cando_q2_p6_branch") => "cando_q2_p6_go_unit_branch") & ((("cando_q3_dice1_done_unit" & "cando_q3_dice1_branch") => "cando_q3_dice1_done_unit_branch") & ((("cando_q3_q0_redo_unit" & "cando_q3_q0_branch") => "cando_q3_q0_redo_unit_branch") & ((("cando_q4_dice2_done_unit" & "cando_q4_dice2_branch") => "cando_q4_dice2_done_unit_branch") & ((("cando_q4_dice3_done_unit" & "cando_q4_dice3_branch") => "cando_q4_dice3_done_unit_branch") & ((("cando_q5_dice4_done_unit" & "cando_q5_dice4_branch") => "cando_q5_dice4_done_unit_branch") & ((("cando_q5_dice5_done_unit" & "cando_q5_dice5_branch") => "cando_q5_dice5_done_unit_branch") & ((("cando_q6_dice6_done_unit" & "cando_q6_dice6_branch") => "cando_q6_dice6_done_unit_branch") & (("cando_q6_q0_redo_unit" & "cando_q6_q0_branch") => "cando_q6_q0_redo_unit_branch")))))))))))))))))))))))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.16666698455810547 (+/- 1.1920963061161968E-6 estimated; rel err 7.1525641942636435E-6)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/different-sort.ctx =======
  
  (* What happens if two participants try to communicate on the same label but different sorts? *)
  
  p : (+) { q ! 1.0 : l<Int> . end }
  
  q : & { p ? l(Bool) . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [p_q_l_bool] false -> 1:(closure'=false);
    [p_q_l_int] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..2] init 0;
  
    [] p=0 -> 1:(p'=1);
    [p_q_l_int] p=1 -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..1] init 0;
  
    [p_q_l_bool] q=0 -> 1:(q'=1);
  endmodule
  
  label "end" = (p=2) & (q=1);
  label "cando_p_q_l_bool" = false;
  label "cando_p_q_l_bool_branch" = q=0;
  label "cando_p_q_l_int" = p=0;
  label "cando_p_q_l_int_branch" = false;
  label "cando_p_q_branch" = q=0;
  label "wals" = (p=1) & (q=0);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l_bool" & "cando_p_q_branch") => "cando_p_q_l_bool_branch") & (("cando_p_q_l_int" & "cando_p_q_branch") => "cando_p_q_l_int_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Deadlock freedom (lower bound)
  Result: 0.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/dining.ctx =======
  
  f0 : mu t. & {
    p0 ? pick . (+) { p0 ! 1.0 : free .
      mu s. & {
        p0 ? drop . t,
        p2 ? pick . (+) { p2 ! 1.0 : notFree . s }
      }},
    p2 ? pick . (+) { p2 ! 1.0 : free .
      mu s. & {
        p2 ? drop . t,
        p0 ? pick . (+) { p0 ! 1.0 : notFree . s }
      }}
  }
  
  f1 : mu t. & {
    p1 ? pick . (+) { p1 ! 1.0 : free .
      mu s. & {
        p1 ? drop . t,
        p0 ? pick . (+) { p0 ! 1.0 : notFree . s }
      }},
    p0 ? pick . (+) { p0 ! 1.0 : free .
      mu s. & {
        p0 ? drop . t,
        p1 ? pick . (+) { p1 ! 1.0 : notFree . s }
      }}
  }
  
  f2 : mu t. & {
    p2 ? pick . (+) { p2 ! 1.0 : free .
      mu s. & {
        p2 ? drop . t,
        p1 ? pick . (+) { p1 ! 1.0 : notFree . s }
      }},
    p1 ? pick . (+) { p1 ! 1.0 : free .
      mu s. & {
        p1 ? drop . t,
        p2 ? pick . (+) { p2 ! 1.0 : notFree . s }
      }}
  }
  
  p0 : mu t. (+) {
    f0 ! 0.5 : pick . & {
      f0 ? free .
        (+) { f1 ! 1.0 : pick . & {
          f1 ? free .
            (+) { q ! 1.0 : eat . (+) { f1 ! 1.0 : drop . (+) { f0 ! 1.0 : drop . t }}},
          f1 ? notFree .
            (+) { f0 ! 1.0 : drop . t }
        }},
      f0 ? notFree .
        mu s. (+) { f0 ! 1.0 : pick . & {
          f0 ? free .
            (+) { f1 ! 1.0 : pick . & {
              f1 ? free .
                (+) { q ! 1.0 : eat . (+) { f1 ! 1.0 : drop . (+) { f0 ! 1.0 : drop . t }}},
              f1 ? notFree .
                (+) { f0 ! 1.0 : drop . t }
            }},
          f0 ? notFree . s
        }}
    },
    f1 ! 0.5 : pick . & {
      f1 ? free .
        (+) { f0 ! 1.0 : pick . & {
          f0 ? free .
            (+) { q ! 1.0 : eat . (+) { f0 ! 1.0 : drop . (+) { f1 ! 1.0 : drop . t }}},
          f0 ? notFree .
            (+) { f1 ! 1.0 : drop . t }
        }},
      f1 ? notFree .
        mu s. (+) { f1 ! 1.0 : pick . & {
          f1 ? free .
            (+) { f0 ! 1.0 : pick . & {
              f0 ? free .
                (+) { q ! 1.0 : eat . (+) { f0 ! 1.0 : drop . (+) { f1 ! 1.0 : drop . t }}},
              f0 ? notFree .
                (+) { f1 ! 1.0 : drop . t }
            }},
          f1 ? notFree . s
        }}
    }
  }
  
  p1 : mu t. (+) {
    f1 ! 0.5 : pick . & {
      f1 ? free .
        (+) { f2 ! 1.0 : pick . & {
          f2 ? free .
            (+) { q ! 1.0 : eat . (+) { f2 ! 1.0 : drop . (+) { f1 ! 1.0 : drop . t }}},
          f2 ? notFree .
            (+) { f1 ! 1.0 : drop . t }
        }},
      f1 ? notFree .
        mu s. (+) { f1 ! 1.0 : pick . & {
          f1 ? free .
            (+) { f2 ! 1.0 : pick . & {
              f2 ? free .
                (+) { q ! 1.0 : eat . (+) { f2 ! 1.0 : drop . (+) { f1 ! 1.0 : drop . t }}},
              f2 ? notFree .
                (+) { f1 ! 1.0 : drop . t }
            }},
          f1 ? notFree . s
        }}
    },
    f2 ! 0.5 : pick . & {
      f2 ? free .
        (+) { f1 ! 1.0 : pick . & {
          f1 ? free .
            (+) { q ! 1.0 : eat . (+) { f1 ! 1.0 : drop . (+) { f2 ! 1.0 : drop . t }}},
          f1 ? notFree .
            (+) { f2 ! 1.0 : drop . t }
        }},
      f2 ? notFree .
        mu s. (+) { f2 ! 1.0 : pick . & {
          f2 ? free .
            (+) { f1 ! 1.0 : pick . & {
              f1 ? free .
                (+) { q ! 1.0 : eat . (+) { f1 ! 1.0 : drop . (+) { f2 ! 1.0 : drop . t }}},
              f1 ? notFree .
                (+) { f2 ! 1.0 : drop . t }
            }},
          f2 ? notFree . s
        }}
    }
  }
  
  p2 : mu t. (+) {
    f2 ! 0.5 : pick . & {
      f2 ? free .
        (+) { f0 ! 1.0 : pick . & {
          f0 ? free .
            (+) { q ! 1.0 : eat . (+) { f0 ! 1.0 : drop . (+) { f2 ! 1.0 : drop . t }}},
          f0 ? notFree .
            (+) { f2 ! 1.0 : drop . t }
        }},
      f2 ? notFree .
        mu s. (+) { f2 ! 1.0 : pick . & {
          f2 ? free .
            (+) { f0 ! 1.0 : pick . & {
              f0 ? free .
                (+) { q ! 1.0 : eat . (+) { f0 ! 1.0 : drop . (+) { f2 ! 1.0 : drop . t }}},
              f0 ? notFree .
                (+) { f2 ! 1.0 : drop . t }
            }},
          f2 ? notFree . s
        }}
    },
    f0 ! 0.5 : pick . & {
      f0 ? free .
        (+) { f2 ! 1.0 : pick . & {
          f2 ? free .
            (+) { q ! 1.0 : eat . (+) { f2 ! 1.0 : drop . (+) { f0 ! 1.0 : drop . t }}},
          f2 ? notFree .
            (+) { f0 ! 1.0 : drop . t }
        }},
      f0 ? notFree .
        mu s. (+) { f0 ! 1.0 : pick . & {
          f0 ? free .
            (+) { f2 ! 1.0 : pick . & {
              f2 ? free .
                (+) { q ! 1.0 : eat . (+) { f2 ! 1.0 : drop . (+) { f0 ! 1.0 : drop . t }}},
              f2 ? notFree .
                (+) { f0 ! 1.0 : drop . t }
            }},
          f0 ? notFree . s
        }}
    }
  }
  
  q : mu t. & {
    p0 ? eat . t,
    p1 ? eat . t,
    p2 ? eat . t
  }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module f0
    f0 : [0..11] init 0;
  
    [p0_f0_pick_unit] f0=0 -> 1:(f0'=1);
    [p2_f0_pick_unit] f0=0 -> 1:(f0'=6);
    [] f0=1 -> 1:(f0'=2);
    [f0_p0_free_unit] f0=2 -> 1:(f0'=3);
    [p0_f0_drop_unit] f0=3 -> 1:(f0'=0);
    [p2_f0_pick_unit] f0=3 -> 1:(f0'=4);
    [] f0=4 -> 1:(f0'=5);
    [f0_p2_notFree_unit] f0=5 -> 1:(f0'=3);
    [] f0=6 -> 1:(f0'=7);
    [f0_p2_free_unit] f0=7 -> 1:(f0'=8);
    [p2_f0_drop_unit] f0=8 -> 1:(f0'=0);
    [p0_f0_pick_unit] f0=8 -> 1:(f0'=9);
    [] f0=9 -> 1:(f0'=10);
    [f0_p0_notFree_unit] f0=10 -> 1:(f0'=8);
  endmodule
  
  module f1
    f1 : [0..11] init 0;
  
    [p1_f1_pick_unit] f1=0 -> 1:(f1'=1);
    [p0_f1_pick_unit] f1=0 -> 1:(f1'=6);
    [] f1=1 -> 1:(f1'=2);
    [f1_p1_free_unit] f1=2 -> 1:(f1'=3);
    [p1_f1_drop_unit] f1=3 -> 1:(f1'=0);
    [p0_f1_pick_unit] f1=3 -> 1:(f1'=4);
    [] f1=4 -> 1:(f1'=5);
    [f1_p0_notFree_unit] f1=5 -> 1:(f1'=3);
    [] f1=6 -> 1:(f1'=7);
    [f1_p0_free_unit] f1=7 -> 1:(f1'=8);
    [p0_f1_drop_unit] f1=8 -> 1:(f1'=0);
    [p1_f1_pick_unit] f1=8 -> 1:(f1'=9);
    [] f1=9 -> 1:(f1'=10);
    [f1_p1_notFree_unit] f1=10 -> 1:(f1'=8);
  endmodule
  
  module f2
    f2 : [0..11] init 0;
  
    [p2_f2_pick_unit] f2=0 -> 1:(f2'=1);
    [p1_f2_pick_unit] f2=0 -> 1:(f2'=6);
    [] f2=1 -> 1:(f2'=2);
    [f2_p2_free_unit] f2=2 -> 1:(f2'=3);
    [p2_f2_drop_unit] f2=3 -> 1:(f2'=0);
    [p1_f2_pick_unit] f2=3 -> 1:(f2'=4);
    [] f2=4 -> 1:(f2'=5);
    [f2_p1_notFree_unit] f2=5 -> 1:(f2'=3);
    [] f2=6 -> 1:(f2'=7);
    [f2_p1_free_unit] f2=7 -> 1:(f2'=8);
    [p1_f2_drop_unit] f2=8 -> 1:(f2'=0);
    [p2_f2_pick_unit] f2=8 -> 1:(f2'=9);
    [] f2=9 -> 1:(f2'=10);
    [f2_p2_notFree_unit] f2=10 -> 1:(f2'=8);
  endmodule
  
  module p0
    p0 : [0..55] init 0;
  
    [] p0=0 -> 0.5:(p0'=1) + 0.5:(p0'=2);
    [p0_f0_pick_unit] p0=1 -> 1:(p0'=3);
    [p0_f1_pick_unit] p0=2 -> 1:(p0'=29);
    [f0_p0_free_unit] p0=3 -> 1:(p0'=4);
    [f0_p0_notFree_unit] p0=3 -> 1:(p0'=15);
    [] p0=4 -> 1:(p0'=5);
    [p0_f1_pick_unit] p0=5 -> 1:(p0'=6);
    [f1_p0_free_unit] p0=6 -> 1:(p0'=7);
    [f1_p0_notFree_unit] p0=6 -> 1:(p0'=13);
    [] p0=7 -> 1:(p0'=8);
    [p0_q_eat_unit] p0=8 -> 1:(p0'=9);
    [] p0=9 -> 1:(p0'=10);
    [p0_f1_drop_unit] p0=10 -> 1:(p0'=11);
    [] p0=11 -> 1:(p0'=12);
    [p0_f0_drop_unit] p0=12 -> 1:(p0'=0);
    [] p0=13 -> 1:(p0'=14);
    [p0_f0_drop_unit] p0=14 -> 1:(p0'=0);
    [] p0=15 -> 1:(p0'=16);
    [p0_f0_pick_unit] p0=16 -> 1:(p0'=17);
    [f0_p0_free_unit] p0=17 -> 1:(p0'=18);
    [f0_p0_notFree_unit] p0=17 -> 1:(p0'=15);
    [] p0=18 -> 1:(p0'=19);
    [p0_f1_pick_unit] p0=19 -> 1:(p0'=20);
    [f1_p0_free_unit] p0=20 -> 1:(p0'=21);
    [f1_p0_notFree_unit] p0=20 -> 1:(p0'=27);
    [] p0=21 -> 1:(p0'=22);
    [p0_q_eat_unit] p0=22 -> 1:(p0'=23);
    [] p0=23 -> 1:(p0'=24);
    [p0_f1_drop_unit] p0=24 -> 1:(p0'=25);
    [] p0=25 -> 1:(p0'=26);
    [p0_f0_drop_unit] p0=26 -> 1:(p0'=0);
    [] p0=27 -> 1:(p0'=28);
    [p0_f0_drop_unit] p0=28 -> 1:(p0'=0);
    [f1_p0_free_unit] p0=29 -> 1:(p0'=30);
    [f1_p0_notFree_unit] p0=29 -> 1:(p0'=41);
    [] p0=30 -> 1:(p0'=31);
    [p0_f0_pick_unit] p0=31 -> 1:(p0'=32);
    [f0_p0_free_unit] p0=32 -> 1:(p0'=33);
    [f0_p0_notFree_unit] p0=32 -> 1:(p0'=39);
    [] p0=33 -> 1:(p0'=34);
    [p0_q_eat_unit] p0=34 -> 1:(p0'=35);
    [] p0=35 -> 1:(p0'=36);
    [p0_f0_drop_unit] p0=36 -> 1:(p0'=37);
    [] p0=37 -> 1:(p0'=38);
    [p0_f1_drop_unit] p0=38 -> 1:(p0'=0);
    [] p0=39 -> 1:(p0'=40);
    [p0_f1_drop_unit] p0=40 -> 1:(p0'=0);
    [] p0=41 -> 1:(p0'=42);
    [p0_f1_pick_unit] p0=42 -> 1:(p0'=43);
    [f1_p0_free_unit] p0=43 -> 1:(p0'=44);
    [f1_p0_notFree_unit] p0=43 -> 1:(p0'=41);
    [] p0=44 -> 1:(p0'=45);
    [p0_f0_pick_unit] p0=45 -> 1:(p0'=46);
    [f0_p0_free_unit] p0=46 -> 1:(p0'=47);
    [f0_p0_notFree_unit] p0=46 -> 1:(p0'=53);
    [] p0=47 -> 1:(p0'=48);
    [p0_q_eat_unit] p0=48 -> 1:(p0'=49);
    [] p0=49 -> 1:(p0'=50);
    [p0_f0_drop_unit] p0=50 -> 1:(p0'=51);
    [] p0=51 -> 1:(p0'=52);
    [p0_f1_drop_unit] p0=52 -> 1:(p0'=0);
    [] p0=53 -> 1:(p0'=54);
    [p0_f1_drop_unit] p0=54 -> 1:(p0'=0);
  endmodule
  
  module p1
    p1 : [0..55] init 0;
  
    [] p1=0 -> 0.5:(p1'=1) + 0.5:(p1'=2);
    [p1_f1_pick_unit] p1=1 -> 1:(p1'=3);
    [p1_f2_pick_unit] p1=2 -> 1:(p1'=29);
    [f1_p1_free_unit] p1=3 -> 1:(p1'=4);
    [f1_p1_notFree_unit] p1=3 -> 1:(p1'=15);
    [] p1=4 -> 1:(p1'=5);
    [p1_f2_pick_unit] p1=5 -> 1:(p1'=6);
    [f2_p1_free_unit] p1=6 -> 1:(p1'=7);
    [f2_p1_notFree_unit] p1=6 -> 1:(p1'=13);
    [] p1=7 -> 1:(p1'=8);
    [p1_q_eat_unit] p1=8 -> 1:(p1'=9);
    [] p1=9 -> 1:(p1'=10);
    [p1_f2_drop_unit] p1=10 -> 1:(p1'=11);
    [] p1=11 -> 1:(p1'=12);
    [p1_f1_drop_unit] p1=12 -> 1:(p1'=0);
    [] p1=13 -> 1:(p1'=14);
    [p1_f1_drop_unit] p1=14 -> 1:(p1'=0);
    [] p1=15 -> 1:(p1'=16);
    [p1_f1_pick_unit] p1=16 -> 1:(p1'=17);
    [f1_p1_free_unit] p1=17 -> 1:(p1'=18);
    [f1_p1_notFree_unit] p1=17 -> 1:(p1'=15);
    [] p1=18 -> 1:(p1'=19);
    [p1_f2_pick_unit] p1=19 -> 1:(p1'=20);
    [f2_p1_free_unit] p1=20 -> 1:(p1'=21);
    [f2_p1_notFree_unit] p1=20 -> 1:(p1'=27);
    [] p1=21 -> 1:(p1'=22);
    [p1_q_eat_unit] p1=22 -> 1:(p1'=23);
    [] p1=23 -> 1:(p1'=24);
    [p1_f2_drop_unit] p1=24 -> 1:(p1'=25);
    [] p1=25 -> 1:(p1'=26);
    [p1_f1_drop_unit] p1=26 -> 1:(p1'=0);
    [] p1=27 -> 1:(p1'=28);
    [p1_f1_drop_unit] p1=28 -> 1:(p1'=0);
    [f2_p1_free_unit] p1=29 -> 1:(p1'=30);
    [f2_p1_notFree_unit] p1=29 -> 1:(p1'=41);
    [] p1=30 -> 1:(p1'=31);
    [p1_f1_pick_unit] p1=31 -> 1:(p1'=32);
    [f1_p1_free_unit] p1=32 -> 1:(p1'=33);
    [f1_p1_notFree_unit] p1=32 -> 1:(p1'=39);
    [] p1=33 -> 1:(p1'=34);
    [p1_q_eat_unit] p1=34 -> 1:(p1'=35);
    [] p1=35 -> 1:(p1'=36);
    [p1_f1_drop_unit] p1=36 -> 1:(p1'=37);
    [] p1=37 -> 1:(p1'=38);
    [p1_f2_drop_unit] p1=38 -> 1:(p1'=0);
    [] p1=39 -> 1:(p1'=40);
    [p1_f2_drop_unit] p1=40 -> 1:(p1'=0);
    [] p1=41 -> 1:(p1'=42);
    [p1_f2_pick_unit] p1=42 -> 1:(p1'=43);
    [f2_p1_free_unit] p1=43 -> 1:(p1'=44);
    [f2_p1_notFree_unit] p1=43 -> 1:(p1'=41);
    [] p1=44 -> 1:(p1'=45);
    [p1_f1_pick_unit] p1=45 -> 1:(p1'=46);
    [f1_p1_free_unit] p1=46 -> 1:(p1'=47);
    [f1_p1_notFree_unit] p1=46 -> 1:(p1'=53);
    [] p1=47 -> 1:(p1'=48);
    [p1_q_eat_unit] p1=48 -> 1:(p1'=49);
    [] p1=49 -> 1:(p1'=50);
    [p1_f1_drop_unit] p1=50 -> 1:(p1'=51);
    [] p1=51 -> 1:(p1'=52);
    [p1_f2_drop_unit] p1=52 -> 1:(p1'=0);
    [] p1=53 -> 1:(p1'=54);
    [p1_f2_drop_unit] p1=54 -> 1:(p1'=0);
  endmodule
  
  module p2
    p2 : [0..55] init 0;
  
    [] p2=0 -> 0.5:(p2'=1) + 0.5:(p2'=2);
    [p2_f2_pick_unit] p2=1 -> 1:(p2'=3);
    [p2_f0_pick_unit] p2=2 -> 1:(p2'=29);
    [f2_p2_free_unit] p2=3 -> 1:(p2'=4);
    [f2_p2_notFree_unit] p2=3 -> 1:(p2'=15);
    [] p2=4 -> 1:(p2'=5);
    [p2_f0_pick_unit] p2=5 -> 1:(p2'=6);
    [f0_p2_free_unit] p2=6 -> 1:(p2'=7);
    [f0_p2_notFree_unit] p2=6 -> 1:(p2'=13);
    [] p2=7 -> 1:(p2'=8);
    [p2_q_eat_unit] p2=8 -> 1:(p2'=9);
    [] p2=9 -> 1:(p2'=10);
    [p2_f0_drop_unit] p2=10 -> 1:(p2'=11);
    [] p2=11 -> 1:(p2'=12);
    [p2_f2_drop_unit] p2=12 -> 1:(p2'=0);
    [] p2=13 -> 1:(p2'=14);
    [p2_f2_drop_unit] p2=14 -> 1:(p2'=0);
    [] p2=15 -> 1:(p2'=16);
    [p2_f2_pick_unit] p2=16 -> 1:(p2'=17);
    [f2_p2_free_unit] p2=17 -> 1:(p2'=18);
    [f2_p2_notFree_unit] p2=17 -> 1:(p2'=15);
    [] p2=18 -> 1:(p2'=19);
    [p2_f0_pick_unit] p2=19 -> 1:(p2'=20);
    [f0_p2_free_unit] p2=20 -> 1:(p2'=21);
    [f0_p2_notFree_unit] p2=20 -> 1:(p2'=27);
    [] p2=21 -> 1:(p2'=22);
    [p2_q_eat_unit] p2=22 -> 1:(p2'=23);
    [] p2=23 -> 1:(p2'=24);
    [p2_f0_drop_unit] p2=24 -> 1:(p2'=25);
    [] p2=25 -> 1:(p2'=26);
    [p2_f2_drop_unit] p2=26 -> 1:(p2'=0);
    [] p2=27 -> 1:(p2'=28);
    [p2_f2_drop_unit] p2=28 -> 1:(p2'=0);
    [f0_p2_free_unit] p2=29 -> 1:(p2'=30);
    [f0_p2_notFree_unit] p2=29 -> 1:(p2'=41);
    [] p2=30 -> 1:(p2'=31);
    [p2_f2_pick_unit] p2=31 -> 1:(p2'=32);
    [f2_p2_free_unit] p2=32 -> 1:(p2'=33);
    [f2_p2_notFree_unit] p2=32 -> 1:(p2'=39);
    [] p2=33 -> 1:(p2'=34);
    [p2_q_eat_unit] p2=34 -> 1:(p2'=35);
    [] p2=35 -> 1:(p2'=36);
    [p2_f2_drop_unit] p2=36 -> 1:(p2'=37);
    [] p2=37 -> 1:(p2'=38);
    [p2_f0_drop_unit] p2=38 -> 1:(p2'=0);
    [] p2=39 -> 1:(p2'=40);
    [p2_f0_drop_unit] p2=40 -> 1:(p2'=0);
    [] p2=41 -> 1:(p2'=42);
    [p2_f0_pick_unit] p2=42 -> 1:(p2'=43);
    [f0_p2_free_unit] p2=43 -> 1:(p2'=44);
    [f0_p2_notFree_unit] p2=43 -> 1:(p2'=41);
    [] p2=44 -> 1:(p2'=45);
    [p2_f2_pick_unit] p2=45 -> 1:(p2'=46);
    [f2_p2_free_unit] p2=46 -> 1:(p2'=47);
    [f2_p2_notFree_unit] p2=46 -> 1:(p2'=53);
    [] p2=47 -> 1:(p2'=48);
    [p2_q_eat_unit] p2=48 -> 1:(p2'=49);
    [] p2=49 -> 1:(p2'=50);
    [p2_f2_drop_unit] p2=50 -> 1:(p2'=51);
    [] p2=51 -> 1:(p2'=52);
    [p2_f0_drop_unit] p2=52 -> 1:(p2'=0);
    [] p2=53 -> 1:(p2'=54);
    [p2_f0_drop_unit] p2=54 -> 1:(p2'=0);
  endmodule
  
  module q
    q : [0..1] init 0;
  
    [p0_q_eat_unit] q=0 -> 1:(q'=0);
    [p1_q_eat_unit] q=0 -> 1:(q'=0);
    [p2_q_eat_unit] q=0 -> 1:(q'=0);
  endmodule
  
  label "end" = (f0=11) & (f1=11) & (f2=11) & (p0=55) & (p1=55) & (p2=55) & (q=1);
  label "cando_f0_p0_free_unit" = f0=1;
  label "cando_f0_p0_free_unit_branch" = (p0=3) | (p0=17) | (p0=32) | (p0=46);
  label "cando_f0_p0_notFree_unit" = f0=9;
  label "cando_f0_p0_notFree_unit_branch" = (p0=3) | (p0=17) | (p0=32) | (p0=46);
  label "cando_f0_p2_free_unit" = f0=6;
  label "cando_f0_p2_free_unit_branch" = (p2=6) | (p2=20) | (p2=29) | (p2=43);
  label "cando_f0_p2_notFree_unit" = f0=4;
  label "cando_f0_p2_notFree_unit_branch" = (p2=6) | (p2=20) | (p2=29) | (p2=43);
  label "cando_f1_p0_free_unit" = f1=6;
  label "cando_f1_p0_free_unit_branch" = (p0=6) | (p0=20) | (p0=29) | (p0=43);
  label "cando_f1_p0_notFree_unit" = f1=4;
  label "cando_f1_p0_notFree_unit_branch" = (p0=6) | (p0=20) | (p0=29) | (p0=43);
  label "cando_f1_p1_free_unit" = f1=1;
  label "cando_f1_p1_free_unit_branch" = (p1=3) | (p1=17) | (p1=32) | (p1=46);
  label "cando_f1_p1_notFree_unit" = f1=9;
  label "cando_f1_p1_notFree_unit_branch" = (p1=3) | (p1=17) | (p1=32) | (p1=46);
  label "cando_f2_p1_free_unit" = f2=6;
  label "cando_f2_p1_free_unit_branch" = (p1=6) | (p1=20) | (p1=29) | (p1=43);
  label "cando_f2_p1_notFree_unit" = f2=4;
  label "cando_f2_p1_notFree_unit_branch" = (p1=6) | (p1=20) | (p1=29) | (p1=43);
  label "cando_f2_p2_free_unit" = f2=1;
  label "cando_f2_p2_free_unit_branch" = (p2=3) | (p2=17) | (p2=32) | (p2=46);
  label "cando_f2_p2_notFree_unit" = f2=9;
  label "cando_f2_p2_notFree_unit_branch" = (p2=3) | (p2=17) | (p2=32) | (p2=46);
  label "cando_p0_f0_drop_unit" = (p0=11) | (p0=13) | (p0=25) | (p0=27) | (p0=35) | (p0=49);
  label "cando_p0_f0_drop_unit_branch" = f0=3;
  label "cando_p0_f0_pick_unit" = (p0=0) | (p0=15) | (p0=30) | (p0=44);
  label "cando_p0_f0_pick_unit_branch" = (f0=0) | (f0=8);
  label "cando_p0_f1_drop_unit" = (p0=9) | (p0=23) | (p0=37) | (p0=39) | (p0=51) | (p0=53);
  label "cando_p0_f1_drop_unit_branch" = f1=8;
  label "cando_p0_f1_pick_unit" = (p0=0) | (p0=4) | (p0=18) | (p0=41);
  label "cando_p0_f1_pick_unit_branch" = (f1=0) | (f1=3);
  label "cando_p0_q_eat_unit" = (p0=7) | (p0=21) | (p0=33) | (p0=47);
  label "cando_p0_q_eat_unit_branch" = q=0;
  label "cando_p1_f1_drop_unit" = (p1=11) | (p1=13) | (p1=25) | (p1=27) | (p1=35) | (p1=49);
  label "cando_p1_f1_drop_unit_branch" = f1=3;
  label "cando_p1_f1_pick_unit" = (p1=0) | (p1=15) | (p1=30) | (p1=44);
  label "cando_p1_f1_pick_unit_branch" = (f1=0) | (f1=8);
  label "cando_p1_f2_drop_unit" = (p1=9) | (p1=23) | (p1=37) | (p1=39) | (p1=51) | (p1=53);
  label "cando_p1_f2_drop_unit_branch" = f2=8;
  label "cando_p1_f2_pick_unit" = (p1=0) | (p1=4) | (p1=18) | (p1=41);
  label "cando_p1_f2_pick_unit_branch" = (f2=0) | (f2=3);
  label "cando_p1_q_eat_unit" = (p1=7) | (p1=21) | (p1=33) | (p1=47);
  label "cando_p1_q_eat_unit_branch" = q=0;
  label "cando_p2_f0_drop_unit" = (p2=9) | (p2=23) | (p2=37) | (p2=39) | (p2=51) | (p2=53);
  label "cando_p2_f0_drop_unit_branch" = f0=8;
  label "cando_p2_f0_pick_unit" = (p2=0) | (p2=4) | (p2=18) | (p2=41);
  label "cando_p2_f0_pick_unit_branch" = (f0=0) | (f0=3);
  label "cando_p2_f2_drop_unit" = (p2=11) | (p2=13) | (p2=25) | (p2=27) | (p2=35) | (p2=49);
  label "cando_p2_f2_drop_unit_branch" = f2=3;
  label "cando_p2_f2_pick_unit" = (p2=0) | (p2=15) | (p2=30) | (p2=44);
  label "cando_p2_f2_pick_unit_branch" = (f2=0) | (f2=8);
  label "cando_p2_q_eat_unit" = (p2=7) | (p2=21) | (p2=33) | (p2=47);
  label "cando_p2_q_eat_unit_branch" = q=0;
  label "cando_f0_p0_branch" = (p0=3) | (p0=17) | (p0=32) | (p0=46);
  label "cando_f0_p2_branch" = (p2=6) | (p2=20) | (p2=29) | (p2=43);
  label "cando_f1_p0_branch" = (p0=6) | (p0=20) | (p0=29) | (p0=43);
  label "cando_f1_p1_branch" = (p1=3) | (p1=17) | (p1=32) | (p1=46);
  label "cando_f2_p1_branch" = (p1=6) | (p1=20) | (p1=29) | (p1=43);
  label "cando_f2_p2_branch" = (p2=3) | (p2=17) | (p2=32) | (p2=46);
  label "cando_p0_f0_branch" = (f0=0) | (f0=3) | (f0=8);
  label "cando_p0_f1_branch" = (f1=0) | (f1=3) | (f1=8);
  label "cando_p0_q_branch" = q=0;
  label "cando_p1_f1_branch" = (f1=0) | (f1=3) | (f1=8);
  label "cando_p1_f2_branch" = (f2=0) | (f2=3) | (f2=8);
  label "cando_p1_q_branch" = q=0;
  label "cando_p2_f0_branch" = (f0=0) | (f0=3) | (f0=8);
  label "cando_p2_f2_branch" = (f2=0) | (f2=3) | (f2=8);
  label "cando_p2_q_branch" = q=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_f0_p0_free_unit" & "cando_f0_p0_branch") => "cando_f0_p0_free_unit_branch") & ((("cando_f0_p0_notFree_unit" & "cando_f0_p0_branch") => "cando_f0_p0_notFree_unit_branch") & ((("cando_f0_p2_free_unit" & "cando_f0_p2_branch") => "cando_f0_p2_free_unit_branch") & ((("cando_f0_p2_notFree_unit" & "cando_f0_p2_branch") => "cando_f0_p2_notFree_unit_branch") & ((("cando_f1_p0_free_unit" & "cando_f1_p0_branch") => "cando_f1_p0_free_unit_branch") & ((("cando_f1_p0_notFree_unit" & "cando_f1_p0_branch") => "cando_f1_p0_notFree_unit_branch") & ((("cando_f1_p1_free_unit" & "cando_f1_p1_branch") => "cando_f1_p1_free_unit_branch") & ((("cando_f1_p1_notFree_unit" & "cando_f1_p1_branch") => "cando_f1_p1_notFree_unit_branch") & ((("cando_f2_p1_free_unit" & "cando_f2_p1_branch") => "cando_f2_p1_free_unit_branch") & ((("cando_f2_p1_notFree_unit" & "cando_f2_p1_branch") => "cando_f2_p1_notFree_unit_branch") & ((("cando_f2_p2_free_unit" & "cando_f2_p2_branch") => "cando_f2_p2_free_unit_branch") & ((("cando_f2_p2_notFree_unit" & "cando_f2_p2_branch") => "cando_f2_p2_notFree_unit_branch") & ((("cando_p0_f0_drop_unit" & "cando_p0_f0_branch") => "cando_p0_f0_drop_unit_branch") & ((("cando_p0_f0_pick_unit" & "cando_p0_f0_branch") => "cando_p0_f0_pick_unit_branch") & ((("cando_p0_f1_drop_unit" & "cando_p0_f1_branch") => "cando_p0_f1_drop_unit_branch") & ((("cando_p0_f1_pick_unit" & "cando_p0_f1_branch") => "cando_p0_f1_pick_unit_branch") & ((("cando_p0_q_eat_unit" & "cando_p0_q_branch") => "cando_p0_q_eat_unit_branch") & ((("cando_p1_f1_drop_unit" & "cando_p1_f1_branch") => "cando_p1_f1_drop_unit_branch") & ((("cando_p1_f1_pick_unit" & "cando_p1_f1_branch") => "cando_p1_f1_pick_unit_branch") & ((("cando_p1_f2_drop_unit" & "cando_p1_f2_branch") => "cando_p1_f2_drop_unit_branch") & ((("cando_p1_f2_pick_unit" & "cando_p1_f2_branch") => "cando_p1_f2_pick_unit_branch") & ((("cando_p1_q_eat_unit" & "cando_p1_q_branch") => "cando_p1_q_eat_unit_branch") & ((("cando_p2_f0_drop_unit" & "cando_p2_f0_branch") => "cando_p2_f0_drop_unit_branch") & ((("cando_p2_f0_pick_unit" & "cando_p2_f0_branch") => "cando_p2_f0_pick_unit_branch") & ((("cando_p2_f2_drop_unit" & "cando_p2_f2_branch") => "cando_p2_f2_drop_unit_branch") & ((("cando_p2_f2_pick_unit" & "cando_p2_f2_branch") => "cando_p2_f2_pick_unit_branch") & (("cando_p2_q_eat_unit" & "cando_p2_q_branch") => "cando_p2_q_eat_unit_branch")))))))))))))))))))))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/fact_3.ctx =======
  
  w0 : mu t .
       & { w1 ? req . (+) { w1 ! 0.7 : res<Int> . t, w1 ! 0.3 : err . t } }
  
  w1 : mu t . & { w2 ? req .
              (+) { w0 ! 1.0 : req .
              & {
                 w0 ? res(Int) . (+) { w2 ! 0.6 : res<Int> . t, w2 ! 0.4 : err . t },
                 w0 ? err . (+) { w2 ! 1.0 : err . t }
              } } }
  
  w2 : mu t . & { w3 ? req .
              (+) { w1 ! 1.0 : req .
              & {
                 w1 ? res(Int) . (+) { w3 ! 0.6 : res<Int> . t, w3 ! 0.4 : err . t },
                 w1 ? err . (+) { w3 ! 1.0 : err . t }
              } } }
  
  w3 : (+) { w2 ! 1.0 : req .
       & {
          w2 ? res(Int) . mu t . (+) { dummy ! 1.0 : done . t },
          w2 ? err . end
       } }
  
  dummy : mu t . & { w3 ? done . t }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module w0
    w0 : [0..4] init 0;
  
    [w1_w0_req_unit] w0=0 -> 1:(w0'=1);
    [] w0=1 -> 0.7:(w0'=2) + 0.3:(w0'=3);
    [w0_w1_res_int] w0=2 -> 1:(w0'=0);
    [w0_w1_err_unit] w0=3 -> 1:(w0'=0);
  endmodule
  
  module w1
    w1 : [0..9] init 0;
  
    [w2_w1_req_unit] w1=0 -> 1:(w1'=1);
    [] w1=1 -> 1:(w1'=2);
    [w1_w0_req_unit] w1=2 -> 1:(w1'=3);
    [w0_w1_res_int] w1=3 -> 1:(w1'=4);
    [w0_w1_err_unit] w1=3 -> 1:(w1'=7);
    [] w1=4 -> 0.6:(w1'=5) + 0.4:(w1'=6);
    [w1_w2_res_int] w1=5 -> 1:(w1'=0);
    [w1_w2_err_unit] w1=6 -> 1:(w1'=0);
    [] w1=7 -> 1:(w1'=8);
    [w1_w2_err_unit] w1=8 -> 1:(w1'=0);
  endmodule
  
  module w2
    w2 : [0..9] init 0;
  
    [w3_w2_req_unit] w2=0 -> 1:(w2'=1);
    [] w2=1 -> 1:(w2'=2);
    [w2_w1_req_unit] w2=2 -> 1:(w2'=3);
    [w1_w2_res_int] w2=3 -> 1:(w2'=4);
    [w1_w2_err_unit] w2=3 -> 1:(w2'=7);
    [] w2=4 -> 0.6:(w2'=5) + 0.4:(w2'=6);
    [w2_w3_res_int] w2=5 -> 1:(w2'=0);
    [w2_w3_err_unit] w2=6 -> 1:(w2'=0);
    [] w2=7 -> 1:(w2'=8);
    [w2_w3_err_unit] w2=8 -> 1:(w2'=0);
  endmodule
  
  module w3
    w3 : [0..5] init 0;
  
    [] w3=0 -> 1:(w3'=1);
    [w3_w2_req_unit] w3=1 -> 1:(w3'=2);
    [w2_w3_res_int] w3=2 -> 1:(w3'=3);
    [w2_w3_err_unit] w3=2 -> 1:(w3'=5);
    [] w3=3 -> 1:(w3'=4);
    [w3_dummy_done_unit] w3=4 -> 1:(w3'=3);
  endmodule
  
  module dummy
    dummy : [0..1] init 0;
  
    [w3_dummy_done_unit] dummy=0 -> 1:(dummy'=0);
  endmodule
  
  label "end" = (w0=4) & (w1=9) & (w2=9) & (w3=5) & (dummy=1);
  label "cando_w0_w1_err_unit" = w0=1;
  label "cando_w0_w1_err_unit_branch" = w1=3;
  label "cando_w0_w1_res_int" = w0=1;
  label "cando_w0_w1_res_int_branch" = w1=3;
  label "cando_w1_w0_req_unit" = w1=1;
  label "cando_w1_w0_req_unit_branch" = w0=0;
  label "cando_w1_w2_err_unit" = (w1=4) | (w1=7);
  label "cando_w1_w2_err_unit_branch" = w2=3;
  label "cando_w1_w2_res_int" = w1=4;
  label "cando_w1_w2_res_int_branch" = w2=3;
  label "cando_w2_w1_req_unit" = w2=1;
  label "cando_w2_w1_req_unit_branch" = w1=0;
  label "cando_w2_w3_err_unit" = (w2=4) | (w2=7);
  label "cando_w2_w3_err_unit_branch" = w3=2;
  label "cando_w2_w3_res_int" = w2=4;
  label "cando_w2_w3_res_int_branch" = w3=2;
  label "cando_w3_dummy_done_unit" = w3=3;
  label "cando_w3_dummy_done_unit_branch" = dummy=0;
  label "cando_w3_w2_req_unit" = w3=0;
  label "cando_w3_w2_req_unit_branch" = w2=0;
  label "cando_w0_w1_branch" = w1=3;
  label "cando_w1_w0_branch" = w0=0;
  label "cando_w1_w2_branch" = w2=3;
  label "cando_w2_w1_branch" = w1=0;
  label "cando_w2_w3_branch" = w3=2;
  label "cando_w3_dummy_branch" = dummy=0;
  label "cando_w3_w2_branch" = w2=0;
  label "wals" = ((w0=0) & (w1=0) & (w2=0) & (w3=4) & (dummy=0)) | ((w0=0) & (w1=0) & (w2=0) & (w3=5) & (dummy=0)) | ((w0=0) & (w1=0) & (w2=5) & (w3=2) & (dummy=0)) | ((w0=0) & (w1=0) & (w2=6) & (w3=2) & (dummy=0)) | ((w0=0) & (w1=0) & (w2=8) & (w3=2) & (dummy=0)) | ((w0=0) & (w1=5) & (w2=3) & (w3=2) & (dummy=0)) | ((w0=0) & (w1=6) & (w2=3) & (w3=2) & (dummy=0)) | ((w0=0) & (w1=8) & (w2=3) & (w3=2) & (dummy=0)) | ((w0=3) & (w1=3) & (w2=3) & (w3=2) & (dummy=0));
  
  // Type safety
  P>=1 [ (G ((("cando_w0_w1_err_unit" & "cando_w0_w1_branch") => "cando_w0_w1_err_unit_branch") & ((("cando_w0_w1_res_int" & "cando_w0_w1_branch") => "cando_w0_w1_res_int_branch") & ((("cando_w1_w0_req_unit" & "cando_w1_w0_branch") => "cando_w1_w0_req_unit_branch") & ((("cando_w1_w2_err_unit" & "cando_w1_w2_branch") => "cando_w1_w2_err_unit_branch") & ((("cando_w1_w2_res_int" & "cando_w1_w2_branch") => "cando_w1_w2_res_int_branch") & ((("cando_w2_w1_req_unit" & "cando_w2_w1_branch") => "cando_w2_w1_req_unit_branch") & ((("cando_w2_w3_err_unit" & "cando_w2_w3_branch") => "cando_w2_w3_err_unit_branch") & ((("cando_w2_w3_res_int" & "cando_w2_w3_branch") => "cando_w2_w3_res_int_branch") & ((("cando_w3_dummy_done_unit" & "cando_w3_dummy_branch") => "cando_w3_dummy_done_unit_branch") & (("cando_w3_w2_req_unit" & "cando_w3_w2_branch") => "cando_w3_w2_req_unit_branch"))))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.252 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/fair-deadlock.ctx =======
  
  a : mu t . (+) { b ! 1.0 : rec . t }
  
  b : mu t . & {
                a ? rec . end,
                c ? rec . & { a ? rec . t }
              }
  
  c : mu t . (+) { b ! 1.0 : rec . t }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..2] init 0;
  
    [] a=0 -> 1:(a'=1);
    [a_b_rec_unit] a=1 -> 1:(a'=0);
  endmodule
  
  module b
    b : [0..2] init 0;
  
    [a_b_rec_unit] b=0 -> 1:(b'=2);
    [c_b_rec_unit] b=0 -> 1:(b'=1);
    [a_b_rec_unit] b=1 -> 1:(b'=0);
  endmodule
  
  module c
    c : [0..2] init 0;
  
    [] c=0 -> 1:(c'=1);
    [c_b_rec_unit] c=1 -> 1:(c'=0);
  endmodule
  
  label "end" = (a=2) & (b=2) & (c=2);
  label "cando_a_b_rec_unit" = a=0;
  label "cando_a_b_rec_unit_branch" = (b=0) | (b=1);
  label "cando_c_b_rec_unit" = c=0;
  label "cando_c_b_rec_unit_branch" = b=0;
  label "cando_a_b_branch" = (b=0) | (b=1);
  label "cando_c_b_branch" = b=0;
  label "wals" = (a=1) & (b=2) & (c=1);
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_rec_unit" & "cando_a_b_branch") => "cando_a_b_rec_unit_branch") & (("cando_c_b_rec_unit" & "cando_c_b_branch") => "cando_c_b_rec_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/fair-merge.ctx =======
  
  a : mu t . (+) { c ! 1.0 : msg . t }
  
  b : mu t . (+) { c ! 1.0 : msg . t }
  
  c : mu t . & {
                a ? msg . t,
                b ? msg . t
              }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..2] init 0;
  
    [] a=0 -> 1:(a'=1);
    [a_c_msg_unit] a=1 -> 1:(a'=0);
  endmodule
  
  module b
    b : [0..2] init 0;
  
    [] b=0 -> 1:(b'=1);
    [b_c_msg_unit] b=1 -> 1:(b'=0);
  endmodule
  
  module c
    c : [0..1] init 0;
  
    [a_c_msg_unit] c=0 -> 1:(c'=0);
    [b_c_msg_unit] c=0 -> 1:(c'=0);
  endmodule
  
  label "end" = (a=2) & (b=2) & (c=1);
  label "cando_a_c_msg_unit" = a=0;
  label "cando_a_c_msg_unit_branch" = c=0;
  label "cando_b_c_msg_unit" = b=0;
  label "cando_b_c_msg_unit_branch" = c=0;
  label "cando_a_c_branch" = c=0;
  label "cando_b_c_branch" = c=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_a_c_msg_unit" & "cando_a_c_branch") => "cando_a_c_msg_unit_branch") & (("cando_b_c_msg_unit" & "cando_b_c_branch") => "cando_b_c_msg_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/jake.ctx =======
  
  a : mu t . (+) { b ! 1.0 : rec . t }
  
  b : mu t . & { a ? rec . end, c ? rec . & { a ? rec . t } }
  
  c : mu t . (+) { b ! 1.0 : rec . t }
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..2] init 0;
  
    [] a=0 -> 1:(a'=1);
    [a_b_rec_unit] a=1 -> 1:(a'=0);
  endmodule
  
  module b
    b : [0..2] init 0;
  
    [a_b_rec_unit] b=0 -> 1:(b'=2);
    [c_b_rec_unit] b=0 -> 1:(b'=1);
    [a_b_rec_unit] b=1 -> 1:(b'=0);
  endmodule
  
  module c
    c : [0..2] init 0;
  
    [] c=0 -> 1:(c'=1);
    [c_b_rec_unit] c=1 -> 1:(c'=0);
  endmodule
  
  label "end" = (a=2) & (b=2) & (c=2);
  label "cando_a_b_rec_unit" = a=0;
  label "cando_a_b_rec_unit_branch" = (b=0) | (b=1);
  label "cando_c_b_rec_unit" = c=0;
  label "cando_c_b_rec_unit_branch" = b=0;
  label "cando_a_b_branch" = (b=0) | (b=1);
  label "cando_c_b_branch" = b=0;
  label "wals" = (a=1) & (b=2) & (c=1);
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_rec_unit" & "cando_a_b_branch") => "cando_a_b_rec_unit_branch") & (("cando_c_b_rec_unit" & "cando_c_b_branch") => "cando_c_b_rec_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/leader-election.ctx =======
  
  (* Randomised leader election.
     Refer to https://www.prismmodelchecker.org/casestudies/synchronous_leader.php *)
  
  n0 : mu t . (+) {
         n1 ! 0.5 : zero . & {
           n1 ? zero . t,
           n1 ? one . end
         },
         n1 ! 0.5 : one . & {
           n1 ? zero . (+) { o ! 1.0 : leader0 . end },
           n1 ? one . t
         }
       }
  
  n1 : mu t . & {
         n0 ? zero . (+) {
           n0 ! 0.5 : zero . t,
           n0 ! 0.5 : one . (+) { o ! 1.0 : leader1 . end }
         },
         n0 ? one . (+) {
           n0 ! 0.5 : zero . end,
           n0 ! 0.5 : one . t
         }
       }
  
  o : & {
        n0 ? leader0 . end,
        n1 ? leader1 . end
      }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module n0
    n0 : [0..7] init 0;
  
    [] n0=0 -> 0.5:(n0'=1) + 0.5:(n0'=2);
    [n0_n1_zero_unit] n0=1 -> 1:(n0'=3);
    [n0_n1_one_unit] n0=2 -> 1:(n0'=4);
    [n1_n0_zero_unit] n0=3 -> 1:(n0'=0);
    [n1_n0_one_unit] n0=3 -> 1:(n0'=7);
    [n1_n0_zero_unit] n0=4 -> 1:(n0'=5);
    [n1_n0_one_unit] n0=4 -> 1:(n0'=0);
    [] n0=5 -> 1:(n0'=6);
    [n0_o_leader0_unit] n0=6 -> 1:(n0'=7);
  endmodule
  
  module n1
    n1 : [0..9] init 0;
  
    [n0_n1_zero_unit] n1=0 -> 1:(n1'=1);
    [n0_n1_one_unit] n1=0 -> 1:(n1'=6);
    [] n1=1 -> 0.5:(n1'=2) + 0.5:(n1'=3);
    [n1_n0_zero_unit] n1=2 -> 1:(n1'=0);
    [n1_n0_one_unit] n1=3 -> 1:(n1'=4);
    [] n1=4 -> 1:(n1'=5);
    [n1_o_leader1_unit] n1=5 -> 1:(n1'=9);
    [] n1=6 -> 0.5:(n1'=7) + 0.5:(n1'=8);
    [n1_n0_zero_unit] n1=7 -> 1:(n1'=9);
    [n1_n0_one_unit] n1=8 -> 1:(n1'=0);
  endmodule
  
  module o
    o : [0..1] init 0;
  
    [n0_o_leader0_unit] o=0 -> 1:(o'=1);
    [n1_o_leader1_unit] o=0 -> 1:(o'=1);
  endmodule
  
  label "end" = (n0=7) & (n1=9) & (o=1);
  label "cando_n0_n1_one_unit" = n0=0;
  label "cando_n0_n1_one_unit_branch" = n1=0;
  label "cando_n0_n1_zero_unit" = n0=0;
  label "cando_n0_n1_zero_unit_branch" = n1=0;
  label "cando_n0_o_leader0_unit" = n0=5;
  label "cando_n0_o_leader0_unit_branch" = o=0;
  label "cando_n1_n0_one_unit" = (n1=1) | (n1=6);
  label "cando_n1_n0_one_unit_branch" = (n0=3) | (n0=4);
  label "cando_n1_n0_zero_unit" = (n1=1) | (n1=6);
  label "cando_n1_n0_zero_unit_branch" = (n0=3) | (n0=4);
  label "cando_n1_o_leader1_unit" = n1=4;
  label "cando_n1_o_leader1_unit_branch" = o=0;
  label "cando_n0_n1_branch" = n1=0;
  label "cando_n0_o_branch" = o=0;
  label "cando_n1_n0_branch" = (n0=3) | (n0=4);
  label "cando_n1_o_branch" = o=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_n0_n1_one_unit" & "cando_n0_n1_branch") => "cando_n0_n1_one_unit_branch") & ((("cando_n0_n1_zero_unit" & "cando_n0_n1_branch") => "cando_n0_n1_zero_unit_branch") & ((("cando_n0_o_leader0_unit" & "cando_n0_o_branch") => "cando_n0_o_leader0_unit_branch") & ((("cando_n1_n0_one_unit" & "cando_n1_n0_branch") => "cando_n1_n0_one_unit_branch") & ((("cando_n1_n0_zero_unit" & "cando_n1_n0_branch") => "cando_n1_n0_zero_unit_branch") & (("cando_n1_o_leader1_unit" & "cando_n1_o_branch") => "cando_n1_o_leader1_unit_branch"))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/livelock.ctx =======
  
  (* Weak almost-sure livelock: a and b loop forever exchanging [ping], while c
     waits for a [done] message from a that is never sent. The system never
     deadlocks (a and b always progress), but c is starved forever, so the
     context is not almost-surely live. *)
  
  a : mu t . (+) { b ! 1.0 : ping . t }
  
  b : mu t . & { a ? ping . t }
  
  c : & { a ? done . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [a_c_done_unit] false -> 1:(closure'=false);
  endmodule
  
  module a
    a : [0..2] init 0;
  
    [] a=0 -> 1:(a'=1);
    [a_b_ping_unit] a=1 -> 1:(a'=0);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_ping_unit] b=0 -> 1:(b'=0);
  endmodule
  
  module c
    c : [0..1] init 0;
  
    [a_c_done_unit] c=0 -> 1:(c'=1);
  endmodule
  
  label "end" = (a=2) & (b=1) & (c=1);
  label "cando_a_b_ping_unit" = a=0;
  label "cando_a_b_ping_unit_branch" = b=0;
  label "cando_a_c_done_unit" = false;
  label "cando_a_c_done_unit_branch" = c=0;
  label "cando_a_b_branch" = b=0;
  label "cando_a_c_branch" = c=0;
  label "wals" = (a=1) & (b=0) & (c=0);
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_ping_unit" & "cando_a_b_branch") => "cando_a_b_ping_unit_branch") & (("cando_a_c_done_unit" & "cando_a_c_branch") => "cando_a_c_done_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/lossy-channel.ctx =======
  
  (* Bounded retransmission over a lossy channel.
     Refer to https://www.prismmodelchecker.org/casestudies/brp.php *)
  
  s : (+) { c ! 1.0 : msg . & {
        c ? ack . end,
        c ? lost . (+) { c ! 1.0 : msg . & {
          c ? ack . end,
          c ? lost . (+) { c ! 1.0 : msg . & {
            c ? ack . end,
            c ? lost . end
          } }
        } }
      } }
  
  c : mu t . & { s ? msg . (+) {
        s ! 0.8 : ack . (+) { r ! 1.0 : deliver . end },
        s ! 0.2 : lost . t
      } }
  
  r : & { c ? deliver . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module s
    s : [0..9] init 0;
  
    [] s=0 -> 1:(s'=1);
    [s_c_msg_unit] s=1 -> 1:(s'=2);
    [c_s_ack_unit] s=2 -> 1:(s'=9);
    [c_s_lost_unit] s=2 -> 1:(s'=3);
    [] s=3 -> 1:(s'=4);
    [s_c_msg_unit] s=4 -> 1:(s'=5);
    [c_s_ack_unit] s=5 -> 1:(s'=9);
    [c_s_lost_unit] s=5 -> 1:(s'=6);
    [] s=6 -> 1:(s'=7);
    [s_c_msg_unit] s=7 -> 1:(s'=8);
    [c_s_ack_unit] s=8 -> 1:(s'=9);
    [c_s_lost_unit] s=8 -> 1:(s'=9);
  endmodule
  
  module c
    c : [0..6] init 0;
  
    [s_c_msg_unit] c=0 -> 1:(c'=1);
    [] c=1 -> 0.8:(c'=2) + 0.2:(c'=3);
    [c_s_ack_unit] c=2 -> 1:(c'=4);
    [c_s_lost_unit] c=3 -> 1:(c'=0);
    [] c=4 -> 1:(c'=5);
    [c_r_deliver_unit] c=5 -> 1:(c'=6);
  endmodule
  
  module r
    r : [0..1] init 0;
  
    [c_r_deliver_unit] r=0 -> 1:(r'=1);
  endmodule
  
  label "end" = (s=9) & (c=6) & (r=1);
  label "cando_c_r_deliver_unit" = c=4;
  label "cando_c_r_deliver_unit_branch" = r=0;
  label "cando_c_s_ack_unit" = c=1;
  label "cando_c_s_ack_unit_branch" = (s=2) | (s=5) | (s=8);
  label "cando_c_s_lost_unit" = c=1;
  label "cando_c_s_lost_unit_branch" = (s=2) | (s=5) | (s=8);
  label "cando_s_c_msg_unit" = (s=0) | (s=3) | (s=6);
  label "cando_s_c_msg_unit_branch" = c=0;
  label "cando_c_r_branch" = r=0;
  label "cando_c_s_branch" = (s=2) | (s=5) | (s=8);
  label "cando_s_c_branch" = c=0;
  label "wals" = ((s=8) & (c=3) & (r=0)) | ((s=9) & (c=0) & (r=0));
  
  // Type safety
  P>=1 [ (G ((("cando_c_r_deliver_unit" & "cando_c_r_branch") => "cando_c_r_deliver_unit_branch") & ((("cando_c_s_ack_unit" & "cando_c_s_branch") => "cando_c_s_ack_unit_branch") & ((("cando_c_s_lost_unit" & "cando_c_s_branch") => "cando_c_s_lost_unit_branch") & (("cando_s_c_msg_unit" & "cando_s_c_branch") => "cando_s_c_msg_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.992 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.992 (exact floating point)
  
  
  
  
   ======= TEST ../examples/mdp.ctx =======
  
  a : (+) { b ! 0.4 : l1 . end, b ! 0.6 : l2 . mu t . (+) { b ! 1.0 : l2 . t } }
  
  b : & { a ? l1 . end, a ? l2 . mu t . & { a ? l2 . t } }
  
  c : (+) { d ! 1.0 : l3 . end }
  
  d : & { c ? l3 . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module a
    a : [0..5] init 0;
  
    [] a=0 -> 0.4:(a'=1) + 0.6:(a'=2);
    [a_b_l1_unit] a=1 -> 1:(a'=5);
    [a_b_l2_unit] a=2 -> 1:(a'=3);
    [] a=3 -> 1:(a'=4);
    [a_b_l2_unit] a=4 -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..2] init 0;
  
    [a_b_l1_unit] b=0 -> 1:(b'=2);
    [a_b_l2_unit] b=0 -> 1:(b'=1);
    [a_b_l2_unit] b=1 -> 1:(b'=1);
  endmodule
  
  module c
    c : [0..2] init 0;
  
    [] c=0 -> 1:(c'=1);
    [c_d_l3_unit] c=1 -> 1:(c'=2);
  endmodule
  
  module d
    d : [0..1] init 0;
  
    [c_d_l3_unit] d=0 -> 1:(d'=1);
  endmodule
  
  label "end" = (a=5) & (b=2) & (c=2) & (d=1);
  label "cando_a_b_l1_unit" = a=0;
  label "cando_a_b_l1_unit_branch" = b=0;
  label "cando_a_b_l2_unit" = (a=0) | (a=3);
  label "cando_a_b_l2_unit_branch" = (b=0) | (b=1);
  label "cando_c_d_l3_unit" = c=0;
  label "cando_c_d_l3_unit_branch" = d=0;
  label "cando_a_b_branch" = (b=0) | (b=1);
  label "cando_c_d_branch" = d=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & ((("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch") & (("cando_c_d_l3_unit" & "cando_c_d_branch") => "cando_c_d_l3_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/monty-hall-change.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always switches doors
     to either 2 or 3, depending on whichever door the host opens.
  
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-stay.ctx]. *)
  
  car : (+) {
          host ! 0.34 : l1 . end,
          host ! 0.33 : l2 . end,
          host ! 0.33 : l3 . end
        }
  
  host : & {
           car ? l1 . (+) {
             player ! 0.5 : l2 . & { player ? l1 . end },
             player ! 0.5 : l3 . & { player ? l1 . end }
           },
           car ? l2 . (+) { player ! 1.0 : l3 . & { player ? l2 . end } },
           car ? l3 . (+) { player ! 1.0 : l2 . & { player ? l3 . end } }
        }
  
  player : & {
             host ? l2 . (+) { host ! 1.0 : l3 . end },
             host ? l3 . (+) { host ! 1.0 : l2 . end }
           }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [player_host_l1_unit] false -> 1:(closure'=false);
  endmodule
  
  module car
    car : [0..4] init 0;
  
    [] car=0 -> 0.34:(car'=1) + 0.33:(car'=2) + 0.33:(car'=3);
    [car_host_l1_unit] car=1 -> 1:(car'=4);
    [car_host_l2_unit] car=2 -> 1:(car'=4);
    [car_host_l3_unit] car=3 -> 1:(car'=4);
  endmodule
  
  module host
    host : [0..12] init 0;
  
    [car_host_l1_unit] host=0 -> 1:(host'=1);
    [car_host_l2_unit] host=0 -> 1:(host'=6);
    [car_host_l3_unit] host=0 -> 1:(host'=9);
    [] host=1 -> 0.5:(host'=2) + 0.5:(host'=3);
    [host_player_l2_unit] host=2 -> 1:(host'=4);
    [host_player_l3_unit] host=3 -> 1:(host'=5);
    [player_host_l1_unit] host=4 -> 1:(host'=12);
    [player_host_l1_unit] host=5 -> 1:(host'=12);
    [] host=6 -> 1:(host'=7);
    [host_player_l3_unit] host=7 -> 1:(host'=8);
    [player_host_l2_unit] host=8 -> 1:(host'=12);
    [] host=9 -> 1:(host'=10);
    [host_player_l2_unit] host=10 -> 1:(host'=11);
    [player_host_l3_unit] host=11 -> 1:(host'=12);
  endmodule
  
  module player
    player : [0..5] init 0;
  
    [host_player_l2_unit] player=0 -> 1:(player'=1);
    [host_player_l3_unit] player=0 -> 1:(player'=3);
    [] player=1 -> 1:(player'=2);
    [player_host_l3_unit] player=2 -> 1:(player'=5);
    [] player=3 -> 1:(player'=4);
    [player_host_l2_unit] player=4 -> 1:(player'=5);
  endmodule
  
  label "end" = (car=4) & (host=12) & (player=5);
  label "cando_car_host_l1_unit" = car=0;
  label "cando_car_host_l1_unit_branch" = host=0;
  label "cando_car_host_l2_unit" = car=0;
  label "cando_car_host_l2_unit_branch" = host=0;
  label "cando_car_host_l3_unit" = car=0;
  label "cando_car_host_l3_unit_branch" = host=0;
  label "cando_host_player_l2_unit" = (host=1) | (host=9);
  label "cando_host_player_l2_unit_branch" = player=0;
  label "cando_host_player_l3_unit" = (host=1) | (host=6);
  label "cando_host_player_l3_unit_branch" = player=0;
  label "cando_player_host_l1_unit" = false;
  label "cando_player_host_l1_unit_branch" = (host=4) | (host=5);
  label "cando_player_host_l2_unit" = player=3;
  label "cando_player_host_l2_unit_branch" = host=8;
  label "cando_player_host_l3_unit" = player=1;
  label "cando_player_host_l3_unit_branch" = host=11;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=5) | (host=8) | (host=11);
  label "wals" = ((car=4) & (host=4) & (player=2)) | ((car=4) & (host=5) & (player=4));
  
  // Type safety
  P>=1 [ (G ((("cando_car_host_l1_unit" & "cando_car_host_branch") => "cando_car_host_l1_unit_branch") & ((("cando_car_host_l2_unit" & "cando_car_host_branch") => "cando_car_host_l2_unit_branch") & ((("cando_car_host_l3_unit" & "cando_car_host_branch") => "cando_car_host_l3_unit_branch") & ((("cando_host_player_l2_unit" & "cando_host_player_branch") => "cando_host_player_l2_unit_branch") & ((("cando_host_player_l3_unit" & "cando_host_player_branch") => "cando_host_player_l3_unit_branch") & ((("cando_player_host_l1_unit" & "cando_player_host_branch") => "cando_player_host_l1_unit_branch") & ((("cando_player_host_l2_unit" & "cando_player_host_branch") => "cando_player_host_l2_unit_branch") & (("cando_player_host_l3_unit" & "cando_player_host_branch") => "cando_player_host_l3_unit_branch"))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Deadlock freedom (lower bound)
  Result: 0.6599999999999999 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.6599999999999999 (exact floating point)
  
  
  
  
   ======= TEST ../examples/monty-hall-stay.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always picks Door 1.
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-change.ctx]. *)
  
  car : (+) {
          host ! 0.34 : l1 . end,
          host ! 0.33 : l2 . end,
          host ! 0.33 : l3 . end
        }
  
  host : & {
           car ? l1 . (+) {
             player ! 0.5 : l2 . & { player ? l1 . end },
             player ! 0.5 : l3 . & { player ? l1 . end }
           },
           car ? l2 . (+) { player ! 1.0 : l3 . & { player ? l2 . end } },
           car ? l3 . (+) { player ! 1.0 : l2 . & { player ? l3 . end } }
        }
  
  player : & {
             host ? l2 . (+) { host ! 1.0 : l1 . end },
             host ? l3 . (+) { host ! 1.0 : l1 . end }
           }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [player_host_l2_unit] false -> 1:(closure'=false);
    [player_host_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module car
    car : [0..4] init 0;
  
    [] car=0 -> 0.34:(car'=1) + 0.33:(car'=2) + 0.33:(car'=3);
    [car_host_l1_unit] car=1 -> 1:(car'=4);
    [car_host_l2_unit] car=2 -> 1:(car'=4);
    [car_host_l3_unit] car=3 -> 1:(car'=4);
  endmodule
  
  module host
    host : [0..12] init 0;
  
    [car_host_l1_unit] host=0 -> 1:(host'=1);
    [car_host_l2_unit] host=0 -> 1:(host'=6);
    [car_host_l3_unit] host=0 -> 1:(host'=9);
    [] host=1 -> 0.5:(host'=2) + 0.5:(host'=3);
    [host_player_l2_unit] host=2 -> 1:(host'=4);
    [host_player_l3_unit] host=3 -> 1:(host'=5);
    [player_host_l1_unit] host=4 -> 1:(host'=12);
    [player_host_l1_unit] host=5 -> 1:(host'=12);
    [] host=6 -> 1:(host'=7);
    [host_player_l3_unit] host=7 -> 1:(host'=8);
    [player_host_l2_unit] host=8 -> 1:(host'=12);
    [] host=9 -> 1:(host'=10);
    [host_player_l2_unit] host=10 -> 1:(host'=11);
    [player_host_l3_unit] host=11 -> 1:(host'=12);
  endmodule
  
  module player
    player : [0..5] init 0;
  
    [host_player_l2_unit] player=0 -> 1:(player'=1);
    [host_player_l3_unit] player=0 -> 1:(player'=3);
    [] player=1 -> 1:(player'=2);
    [player_host_l1_unit] player=2 -> 1:(player'=5);
    [] player=3 -> 1:(player'=4);
    [player_host_l1_unit] player=4 -> 1:(player'=5);
  endmodule
  
  label "end" = (car=4) & (host=12) & (player=5);
  label "cando_car_host_l1_unit" = car=0;
  label "cando_car_host_l1_unit_branch" = host=0;
  label "cando_car_host_l2_unit" = car=0;
  label "cando_car_host_l2_unit_branch" = host=0;
  label "cando_car_host_l3_unit" = car=0;
  label "cando_car_host_l3_unit_branch" = host=0;
  label "cando_host_player_l2_unit" = (host=1) | (host=9);
  label "cando_host_player_l2_unit_branch" = player=0;
  label "cando_host_player_l3_unit" = (host=1) | (host=6);
  label "cando_host_player_l3_unit_branch" = player=0;
  label "cando_player_host_l1_unit" = (player=1) | (player=3);
  label "cando_player_host_l1_unit_branch" = (host=4) | (host=5);
  label "cando_player_host_l2_unit" = false;
  label "cando_player_host_l2_unit_branch" = host=8;
  label "cando_player_host_l3_unit" = false;
  label "cando_player_host_l3_unit_branch" = host=11;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=5) | (host=8) | (host=11);
  label "wals" = ((car=4) & (host=8) & (player=4)) | ((car=4) & (host=11) & (player=2));
  
  // Type safety
  P>=1 [ (G ((("cando_car_host_l1_unit" & "cando_car_host_branch") => "cando_car_host_l1_unit_branch") & ((("cando_car_host_l2_unit" & "cando_car_host_branch") => "cando_car_host_l2_unit_branch") & ((("cando_car_host_l3_unit" & "cando_car_host_branch") => "cando_car_host_l3_unit_branch") & ((("cando_host_player_l2_unit" & "cando_host_player_branch") => "cando_host_player_l2_unit_branch") & ((("cando_host_player_l3_unit" & "cando_host_player_branch") => "cando_host_player_l3_unit_branch") & ((("cando_player_host_l1_unit" & "cando_player_host_branch") => "cando_player_host_l1_unit_branch") & ((("cando_player_host_l2_unit" & "cando_player_host_branch") => "cando_player_host_l2_unit_branch") & (("cando_player_host_l3_unit" & "cando_player_host_branch") => "cando_player_host_l3_unit_branch"))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Deadlock freedom (lower bound)
  Result: 0.33999999999999997 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.33999999999999997 (exact floating point)
  
  
  
  
   ======= TEST ../examples/more-choices.ctx =======
  
  p : (+) { q ! 1.0 : l1 . end }
  
  q : mu t . & {
               p ? l1 . end,
               p ? l2 . t
             }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [p_q_l2_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..2] init 0;
  
    [] p=0 -> 1:(p'=1);
    [p_q_l1_unit] p=1 -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..1] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=1);
    [p_q_l2_unit] q=0 -> 1:(q'=0);
  endmodule
  
  label "end" = (p=2) & (q=1);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = false;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p_q_branch" = q=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & (("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/multiparty-workers.ctx =======
  
  starter : (+) { workerA1 ! 1.0 : datum<Int> .
            (+) { workerA2 ! 1.0 : datum<Int> .
            (+) { workerA3 ! 1.0 : datum<Int> .
            end } } }
  
  workerA1 : & { starter ? datum(Int) .
             mu t .
               (+) {
                 workerB1 ! 0.5 : datum<Int> . & { workerC1 ? result(Int) . t },
                 workerB1 ! 0.5 : stop . end
               } }
  
  workerB1 : mu t .
               & {
                 workerA1 ? datum(Int) . (+) { workerC1 ! 1.0 : datum<Int> . t },
                 workerA1 ? stop . (+) { workerC1 ! 1.0 : stop . end }
               }
  
  workerC1 : mu t .
               & {
                 workerB1 ? datum(Int) . (+) { workerA1 ! 1.0 : result<Int> . t },
                 workerB1 ? stop . end
               }
  
  
  workerA2 : & { starter ? datum(Int) .
             mu t .
               (+) {
                 workerB2 ! 0.5 : datum<Int> . & { workerC2 ? result(Int) . t },
                 workerB2 ! 0.5 : stop . end
               } }
  
  workerB2 : mu t .
               & {
                 workerA2 ? datum(Int) . (+) { workerC2 ! 1.0 : datum<Int> . t },
                 workerA2 ? stop . (+) { workerC2 ! 1.0 : stop . end }
               }
  
  workerC2 : mu t .
               & {
                 workerB2 ? datum(Int) . (+) { workerA2 ! 1.0 : result<Int> . t },
                 workerB2 ? stop . end
               }
  
  
  workerA3 : & { starter ? datum(Int) .
             mu t .
               (+) {
                 workerB3 ! 0.5 : datum<Int> . & { workerC3 ? result(Int) . t },
                 workerB3 ! 0.5 : stop . end
               } }
  
  workerB3 : mu t .
               & {
                 workerA3 ? datum(Int) . (+) { workerC3 ! 1.0 : datum<Int> . t },
                 workerA3 ? stop . (+) { workerC3 ! 1.0 : stop . end }
               }
  
  workerC3 : mu t .
               & {
                 workerB3 ? datum(Int) . (+) { workerA3 ! 1.0 : result<Int> . t },
                 workerB3 ? stop . end
               }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module starter
    starter : [0..6] init 0;
  
    [] starter=0 -> 1:(starter'=1);
    [starter_workerA1_datum_int] starter=1 -> 1:(starter'=2);
    [] starter=2 -> 1:(starter'=3);
    [starter_workerA2_datum_int] starter=3 -> 1:(starter'=4);
    [] starter=4 -> 1:(starter'=5);
    [starter_workerA3_datum_int] starter=5 -> 1:(starter'=6);
  endmodule
  
  module workerA1
    workerA1 : [0..5] init 0;
  
    [starter_workerA1_datum_int] workerA1=0 -> 1:(workerA1'=1);
    [] workerA1=1 -> 0.5:(workerA1'=2) + 0.5:(workerA1'=3);
    [workerA1_workerB1_datum_int] workerA1=2 -> 1:(workerA1'=4);
    [workerA1_workerB1_stop_unit] workerA1=3 -> 1:(workerA1'=5);
    [workerC1_workerA1_result_int] workerA1=4 -> 1:(workerA1'=1);
  endmodule
  
  module workerB1
    workerB1 : [0..5] init 0;
  
    [workerA1_workerB1_datum_int] workerB1=0 -> 1:(workerB1'=1);
    [workerA1_workerB1_stop_unit] workerB1=0 -> 1:(workerB1'=3);
    [] workerB1=1 -> 1:(workerB1'=2);
    [workerB1_workerC1_datum_int] workerB1=2 -> 1:(workerB1'=0);
    [] workerB1=3 -> 1:(workerB1'=4);
    [workerB1_workerC1_stop_unit] workerB1=4 -> 1:(workerB1'=5);
  endmodule
  
  module workerC1
    workerC1 : [0..3] init 0;
  
    [workerB1_workerC1_datum_int] workerC1=0 -> 1:(workerC1'=1);
    [workerB1_workerC1_stop_unit] workerC1=0 -> 1:(workerC1'=3);
    [] workerC1=1 -> 1:(workerC1'=2);
    [workerC1_workerA1_result_int] workerC1=2 -> 1:(workerC1'=0);
  endmodule
  
  module workerA2
    workerA2 : [0..5] init 0;
  
    [starter_workerA2_datum_int] workerA2=0 -> 1:(workerA2'=1);
    [] workerA2=1 -> 0.5:(workerA2'=2) + 0.5:(workerA2'=3);
    [workerA2_workerB2_datum_int] workerA2=2 -> 1:(workerA2'=4);
    [workerA2_workerB2_stop_unit] workerA2=3 -> 1:(workerA2'=5);
    [workerC2_workerA2_result_int] workerA2=4 -> 1:(workerA2'=1);
  endmodule
  
  module workerB2
    workerB2 : [0..5] init 0;
  
    [workerA2_workerB2_datum_int] workerB2=0 -> 1:(workerB2'=1);
    [workerA2_workerB2_stop_unit] workerB2=0 -> 1:(workerB2'=3);
    [] workerB2=1 -> 1:(workerB2'=2);
    [workerB2_workerC2_datum_int] workerB2=2 -> 1:(workerB2'=0);
    [] workerB2=3 -> 1:(workerB2'=4);
    [workerB2_workerC2_stop_unit] workerB2=4 -> 1:(workerB2'=5);
  endmodule
  
  module workerC2
    workerC2 : [0..3] init 0;
  
    [workerB2_workerC2_datum_int] workerC2=0 -> 1:(workerC2'=1);
    [workerB2_workerC2_stop_unit] workerC2=0 -> 1:(workerC2'=3);
    [] workerC2=1 -> 1:(workerC2'=2);
    [workerC2_workerA2_result_int] workerC2=2 -> 1:(workerC2'=0);
  endmodule
  
  module workerA3
    workerA3 : [0..5] init 0;
  
    [starter_workerA3_datum_int] workerA3=0 -> 1:(workerA3'=1);
    [] workerA3=1 -> 0.5:(workerA3'=2) + 0.5:(workerA3'=3);
    [workerA3_workerB3_datum_int] workerA3=2 -> 1:(workerA3'=4);
    [workerA3_workerB3_stop_unit] workerA3=3 -> 1:(workerA3'=5);
    [workerC3_workerA3_result_int] workerA3=4 -> 1:(workerA3'=1);
  endmodule
  
  module workerB3
    workerB3 : [0..5] init 0;
  
    [workerA3_workerB3_datum_int] workerB3=0 -> 1:(workerB3'=1);
    [workerA3_workerB3_stop_unit] workerB3=0 -> 1:(workerB3'=3);
    [] workerB3=1 -> 1:(workerB3'=2);
    [workerB3_workerC3_datum_int] workerB3=2 -> 1:(workerB3'=0);
    [] workerB3=3 -> 1:(workerB3'=4);
    [workerB3_workerC3_stop_unit] workerB3=4 -> 1:(workerB3'=5);
  endmodule
  
  module workerC3
    workerC3 : [0..3] init 0;
  
    [workerB3_workerC3_datum_int] workerC3=0 -> 1:(workerC3'=1);
    [workerB3_workerC3_stop_unit] workerC3=0 -> 1:(workerC3'=3);
    [] workerC3=1 -> 1:(workerC3'=2);
    [workerC3_workerA3_result_int] workerC3=2 -> 1:(workerC3'=0);
  endmodule
  
  label "end" = (starter=6) & (workerA1=5) & (workerB1=5) & (workerC1=3) & (workerA2=5) & (workerB2=5) & (workerC2=3) & (workerA3=5) & (workerB3=5) & (workerC3=3);
  label "cando_starter_workerA1_datum_int" = starter=0;
  label "cando_starter_workerA1_datum_int_branch" = workerA1=0;
  label "cando_starter_workerA2_datum_int" = starter=2;
  label "cando_starter_workerA2_datum_int_branch" = workerA2=0;
  label "cando_starter_workerA3_datum_int" = starter=4;
  label "cando_starter_workerA3_datum_int_branch" = workerA3=0;
  label "cando_workerA1_workerB1_datum_int" = workerA1=1;
  label "cando_workerA1_workerB1_datum_int_branch" = workerB1=0;
  label "cando_workerA1_workerB1_stop_unit" = workerA1=1;
  label "cando_workerA1_workerB1_stop_unit_branch" = workerB1=0;
  label "cando_workerA2_workerB2_datum_int" = workerA2=1;
  label "cando_workerA2_workerB2_datum_int_branch" = workerB2=0;
  label "cando_workerA2_workerB2_stop_unit" = workerA2=1;
  label "cando_workerA2_workerB2_stop_unit_branch" = workerB2=0;
  label "cando_workerA3_workerB3_datum_int" = workerA3=1;
  label "cando_workerA3_workerB3_datum_int_branch" = workerB3=0;
  label "cando_workerA3_workerB3_stop_unit" = workerA3=1;
  label "cando_workerA3_workerB3_stop_unit_branch" = workerB3=0;
  label "cando_workerB1_workerC1_datum_int" = workerB1=1;
  label "cando_workerB1_workerC1_datum_int_branch" = workerC1=0;
  label "cando_workerB1_workerC1_stop_unit" = workerB1=3;
  label "cando_workerB1_workerC1_stop_unit_branch" = workerC1=0;
  label "cando_workerB2_workerC2_datum_int" = workerB2=1;
  label "cando_workerB2_workerC2_datum_int_branch" = workerC2=0;
  label "cando_workerB2_workerC2_stop_unit" = workerB2=3;
  label "cando_workerB2_workerC2_stop_unit_branch" = workerC2=0;
  label "cando_workerB3_workerC3_datum_int" = workerB3=1;
  label "cando_workerB3_workerC3_datum_int_branch" = workerC3=0;
  label "cando_workerB3_workerC3_stop_unit" = workerB3=3;
  label "cando_workerB3_workerC3_stop_unit_branch" = workerC3=0;
  label "cando_workerC1_workerA1_result_int" = workerC1=1;
  label "cando_workerC1_workerA1_result_int_branch" = workerA1=4;
  label "cando_workerC2_workerA2_result_int" = workerC2=1;
  label "cando_workerC2_workerA2_result_int_branch" = workerA2=4;
  label "cando_workerC3_workerA3_result_int" = workerC3=1;
  label "cando_workerC3_workerA3_result_int_branch" = workerA3=4;
  label "cando_starter_workerA1_branch" = workerA1=0;
  label "cando_starter_workerA2_branch" = workerA2=0;
  label "cando_starter_workerA3_branch" = workerA3=0;
  label "cando_workerA1_workerB1_branch" = workerB1=0;
  label "cando_workerA2_workerB2_branch" = workerB2=0;
  label "cando_workerA3_workerB3_branch" = workerB3=0;
  label "cando_workerB1_workerC1_branch" = workerC1=0;
  label "cando_workerB2_workerC2_branch" = workerC2=0;
  label "cando_workerB3_workerC3_branch" = workerC3=0;
  label "cando_workerC1_workerA1_branch" = workerA1=4;
  label "cando_workerC2_workerA2_branch" = workerA2=4;
  label "cando_workerC3_workerA3_branch" = workerA3=4;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_starter_workerA1_datum_int" & "cando_starter_workerA1_branch") => "cando_starter_workerA1_datum_int_branch") & ((("cando_starter_workerA2_datum_int" & "cando_starter_workerA2_branch") => "cando_starter_workerA2_datum_int_branch") & ((("cando_starter_workerA3_datum_int" & "cando_starter_workerA3_branch") => "cando_starter_workerA3_datum_int_branch") & ((("cando_workerA1_workerB1_datum_int" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_datum_int_branch") & ((("cando_workerA1_workerB1_stop_unit" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_stop_unit_branch") & ((("cando_workerA2_workerB2_datum_int" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_datum_int_branch") & ((("cando_workerA2_workerB2_stop_unit" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_stop_unit_branch") & ((("cando_workerA3_workerB3_datum_int" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_datum_int_branch") & ((("cando_workerA3_workerB3_stop_unit" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_stop_unit_branch") & ((("cando_workerB1_workerC1_datum_int" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_datum_int_branch") & ((("cando_workerB1_workerC1_stop_unit" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_stop_unit_branch") & ((("cando_workerB2_workerC2_datum_int" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_datum_int_branch") & ((("cando_workerB2_workerC2_stop_unit" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_stop_unit_branch") & ((("cando_workerB3_workerC3_datum_int" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_datum_int_branch") & ((("cando_workerB3_workerC3_stop_unit" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_stop_unit_branch") & ((("cando_workerC1_workerA1_result_int" & "cando_workerC1_workerA1_branch") => "cando_workerC1_workerA1_result_int_branch") & ((("cando_workerC2_workerA2_result_int" & "cando_workerC2_workerA2_branch") => "cando_workerC2_workerA2_result_int_branch") & (("cando_workerC3_workerA3_result_int" & "cando_workerC3_workerA3_branch") => "cando_workerC3_workerA3_result_int_branch"))))))))))))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/non-terminating.ctx =======
  
  a : (+) {
        b ! 0.5 : l1 . end,
        b ! 0.5 : l2 . mu t . (+) { b ! 1.0 : l2 . t }
      }
  
  b : mu t .
      & {
        a ? l1 . end,
        a ? l2 . t
      }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module a
    a : [0..5] init 0;
  
    [] a=0 -> 0.5:(a'=1) + 0.5:(a'=2);
    [a_b_l1_unit] a=1 -> 1:(a'=5);
    [a_b_l2_unit] a=2 -> 1:(a'=3);
    [] a=3 -> 1:(a'=4);
    [a_b_l2_unit] a=4 -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_l1_unit] b=0 -> 1:(b'=1);
    [a_b_l2_unit] b=0 -> 1:(b'=0);
  endmodule
  
  label "end" = (a=5) & (b=1);
  label "cando_a_b_l1_unit" = a=0;
  label "cando_a_b_l1_unit_branch" = b=0;
  label "cando_a_b_l2_unit" = (a=0) | (a=3);
  label "cando_a_b_l2_unit_branch" = b=0;
  label "cando_a_b_branch" = b=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & (("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/nondet-liveness.ctx =======
  
  p : (+) { q ! 1.0 : ok . (+) { r ! 1.0 : notify . end } }
    + (+) { q ! 1.0 : go . mu t . (+) { q ! 1.0 : go . t } }
  
  q : & {
          p ? ok . end,
          p ? go . mu t . & { p ? go . t }
        }
  
  r : & { p ? notify . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..9] init 0;
  
    [] p=0 -> 1:(p'=1);
    [] p=0 -> 1:(p'=5);
    [] p=1 -> 1:(p'=2);
    [] p=5 -> 1:(p'=6);
    [p_q_ok_unit] p=2 -> 1:(p'=3);
    [p_q_go_unit] p=6 -> 1:(p'=7);
    [] p=3 -> 1:(p'=4);
    [p_r_notify_unit] p=4 -> 1:(p'=9);
    [] p=7 -> 1:(p'=8);
    [p_q_go_unit] p=8 -> 1:(p'=7);
  endmodule
  
  module q
    q : [0..2] init 0;
  
    [p_q_ok_unit] q=0 -> 1:(q'=2);
    [p_q_go_unit] q=0 -> 1:(q'=1);
    [p_q_go_unit] q=1 -> 1:(q'=1);
  endmodule
  
  module r
    r : [0..1] init 0;
  
    [p_r_notify_unit] r=0 -> 1:(r'=1);
  endmodule
  
  label "end" = (p=9) & (q=2) & (r=1);
  label "cando_p_q_go_unit" = (p=0) | (p=7);
  label "cando_p_q_go_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_ok_unit" = p=0;
  label "cando_p_q_ok_unit_branch" = q=0;
  label "cando_p_r_notify_unit" = p=3;
  label "cando_p_r_notify_unit_branch" = r=0;
  label "cando_p_q_branch" = (q=0) | (q=1);
  label "cando_p_r_branch" = r=0;
  label "wals" = ((p=6) & (q=0) & (r=0)) | ((p=8) & (q=1) & (r=0));
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_go_unit" & "cando_p_q_branch") => "cando_p_q_go_unit_branch") & ((("cando_p_q_ok_unit" & "cando_p_q_branch") => "cando_p_q_ok_unit_branch") & (("cando_p_r_notify_unit" & "cando_p_r_branch") => "cando_p_r_notify_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/nondeterminism.ctx =======
  
  (* Nondeterminism example: two branches with different termination probabilities *)
  
  p : (+) { q ! 0.6 : l1 . end, q ! 0.4 : l2 . mu t . (+) { q ! 1.0 : l2 . t } }
    + (+) { q ! 0.4 : l1 . end, q ! 0.6 : l2 . mu t . (+) { q ! 1.0 : l2 . t } }
  
  q : & { p ? l1 . end, p ? l2 . mu t . & { p ? l2 . t } }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..11] init 0;
  
    [] p=0 -> 1:(p'=1);
    [] p=0 -> 1:(p'=6);
    [] p=1 -> 0.6:(p'=2) + 0.4:(p'=3);
    [] p=6 -> 0.4:(p'=7) + 0.6:(p'=8);
    [p_q_l1_unit] p=2 -> 1:(p'=11);
    [p_q_l2_unit] p=3 -> 1:(p'=4);
    [p_q_l1_unit] p=7 -> 1:(p'=11);
    [p_q_l2_unit] p=8 -> 1:(p'=9);
    [] p=4 -> 1:(p'=5);
    [p_q_l2_unit] p=5 -> 1:(p'=4);
    [] p=9 -> 1:(p'=10);
    [p_q_l2_unit] p=10 -> 1:(p'=9);
  endmodule
  
  module q
    q : [0..2] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=2);
    [p_q_l2_unit] q=0 -> 1:(q'=1);
    [p_q_l2_unit] q=1 -> 1:(q'=1);
  endmodule
  
  label "end" = (p=11) & (q=2);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = (p=0) | (p=4) | (p=9);
  label "cando_p_q_l2_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_branch" = (q=0) | (q=1);
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & (("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/open.ctx =======
  
  alice : (+) { bob ! 0.33 : a.end, bob ! 0.33 : b . (+) { carol ! 1.0 : c . end }, bob ! 0.34 : c . end }
  bob : & { alice ? a.end, alice ? b.end, alice ? c.end }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [alice_carol_c_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..6] init 0;
  
    [] alice=0 -> 0.33:(alice'=1) + 0.33:(alice'=2) + 0.34:(alice'=3);
    [alice_bob_a_unit] alice=1 -> 1:(alice'=6);
    [alice_bob_b_unit] alice=2 -> 1:(alice'=4);
    [alice_bob_c_unit] alice=3 -> 1:(alice'=6);
    [] alice=4 -> 1:(alice'=5);
    [alice_carol_c_unit] alice=5 -> 1:(alice'=6);
  endmodule
  
  module bob
    bob : [0..1] init 0;
  
    [alice_bob_a_unit] bob=0 -> 1:(bob'=1);
    [alice_bob_b_unit] bob=0 -> 1:(bob'=1);
    [alice_bob_c_unit] bob=0 -> 1:(bob'=1);
  endmodule
  
  label "end" = (alice=6) & (bob=1);
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
  label "wals" = (alice=5) & (bob=1);
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_a_unit" & "cando_alice_bob_branch") => "cando_alice_bob_a_unit_branch") & ((("cando_alice_bob_b_unit" & "cando_alice_bob_branch") => "cando_alice_bob_b_unit_branch") & ((("cando_alice_bob_c_unit" & "cando_alice_bob_branch") => "cando_alice_bob_c_unit_branch") & (("cando_alice_carol_c_unit" & "cando_alice_carol_branch") => "cando_alice_carol_c_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.6699999999999999 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.6699999999999999 (exact floating point)
  
  
  
  
   ======= TEST ../examples/partial-livelock.ctx =======
  
  p : (+) {
          q ! 0.7 : ok . (+) { r ! 1.0 : notify . end },
          q ! 0.3 : go . mu t . (+) { q ! 1.0 : go . t }
        }
  
  q : & {
          p ? ok . end,
          p ? go . mu t . & { p ? go . t }
        }
  
  r : & { p ? notify . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..7] init 0;
  
    [] p=0 -> 0.7:(p'=1) + 0.3:(p'=2);
    [p_q_ok_unit] p=1 -> 1:(p'=3);
    [p_q_go_unit] p=2 -> 1:(p'=5);
    [] p=3 -> 1:(p'=4);
    [p_r_notify_unit] p=4 -> 1:(p'=7);
    [] p=5 -> 1:(p'=6);
    [p_q_go_unit] p=6 -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..2] init 0;
  
    [p_q_ok_unit] q=0 -> 1:(q'=2);
    [p_q_go_unit] q=0 -> 1:(q'=1);
    [p_q_go_unit] q=1 -> 1:(q'=1);
  endmodule
  
  module r
    r : [0..1] init 0;
  
    [p_r_notify_unit] r=0 -> 1:(r'=1);
  endmodule
  
  label "end" = (p=7) & (q=2) & (r=1);
  label "cando_p_q_go_unit" = (p=0) | (p=5);
  label "cando_p_q_go_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_ok_unit" = p=0;
  label "cando_p_q_ok_unit_branch" = q=0;
  label "cando_p_r_notify_unit" = p=3;
  label "cando_p_r_notify_unit_branch" = r=0;
  label "cando_p_q_branch" = (q=0) | (q=1);
  label "cando_p_r_branch" = r=0;
  label "wals" = ((p=2) & (q=0) & (r=0)) | ((p=6) & (q=1) & (r=0));
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_go_unit" & "cando_p_q_branch") => "cando_p_q_go_unit_branch") & ((("cando_p_q_ok_unit" & "cando_p_q_branch") => "cando_p_q_ok_unit_branch") & (("cando_p_r_notify_unit" & "cando_p_r_branch") => "cando_p_r_notify_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.7 (exact floating point)
  
  
  
  
   ======= TEST ../examples/prob-deadlock.ctx =======
  
  commander : (+) {
                a ! 0.7 : deadlock . end,
                a ! 0.3 : nodeadlock . end
              }
  
  a : & {
        commander ? deadlock . & { b ? msg . end },
        commander ? nodeadlock . (+) { b ! 1.0 : msg . end }
      }
  
  b : & { a ? msg . end }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [b_a_msg_unit] false -> 1:(closure'=false);
  endmodule
  
  module commander
    commander : [0..3] init 0;
  
    [] commander=0 -> 0.7:(commander'=1) + 0.3:(commander'=2);
    [commander_a_deadlock_unit] commander=1 -> 1:(commander'=3);
    [commander_a_nodeadlock_unit] commander=2 -> 1:(commander'=3);
  endmodule
  
  module a
    a : [0..4] init 0;
  
    [commander_a_deadlock_unit] a=0 -> 1:(a'=1);
    [commander_a_nodeadlock_unit] a=0 -> 1:(a'=2);
    [b_a_msg_unit] a=1 -> 1:(a'=4);
    [] a=2 -> 1:(a'=3);
    [a_b_msg_unit] a=3 -> 1:(a'=4);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_msg_unit] b=0 -> 1:(b'=1);
  endmodule
  
  label "end" = (commander=3) & (a=4) & (b=1);
  label "cando_a_b_msg_unit" = a=2;
  label "cando_a_b_msg_unit_branch" = b=0;
  label "cando_b_a_msg_unit" = false;
  label "cando_b_a_msg_unit_branch" = a=1;
  label "cando_commander_a_deadlock_unit" = commander=0;
  label "cando_commander_a_deadlock_unit_branch" = a=0;
  label "cando_commander_a_nodeadlock_unit" = commander=0;
  label "cando_commander_a_nodeadlock_unit_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=1;
  label "cando_commander_a_branch" = a=0;
  label "wals" = ((commander=1) & (a=0) & (b=0)) | ((commander=3) & (a=1) & (b=0));
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_msg_unit" & "cando_a_b_branch") => "cando_a_b_msg_unit_branch") & ((("cando_b_a_msg_unit" & "cando_b_a_branch") => "cando_b_a_msg_unit_branch") & ((("cando_commander_a_deadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_deadlock_unit_branch") & (("cando_commander_a_nodeadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.30000000000000004 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.30000000000000004 (exact floating point)
  
  
  
  
   ======= TEST ../examples/prob-over-one.ctx =======
  
  a : (+) { b ! 0.4 : l1 . end, b ! 0.7 : l2 . end }
  
  b : & { a ? l1 . end, a ? l2 . end }
  
   ======= PRISM output ========
  
  Typing context is not well-formed: probabilities must sum to 1.0. Found 1.100000
  
  
   ======= Property checking =======
  
  Typing context is not well-formed: probabilities must sum to 1.0. Found 1.100000
  
  
  
  
  
   ======= TEST ../examples/random-walk.ctx =======
  
  (* Gambler's ruin on positions 0..4, starting at 2, moving up with
     probability 0.6. Termination probability equals the ruin probability,
     4/13 ~ 0.3077. *)
  
  w : mu t . (+) {
        q ! 0.4 : down . (+) {
          q ! 0.4 : down . (+) { o ! 1.0 : ruined . end },
          q ! 0.6 : up . t
        },
        q ! 0.6 : up . (+) {
          q ! 0.6 : up . mu s . (+) { o ! 1.0 : won . s },
          q ! 0.4 : down . t
        }
      }
  
  q : mu t . & {
        w ? down . & {
          w ? down . end,
          w ? up . t
        },
        w ? up . & {
          w ? up . end,
          w ? down . t
        }
      }
  
  o : & {
        w ? ruined . end,
        w ? won . mu t . & { w ? won . t }
      }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module w
    w : [0..13] init 0;
  
    [] w=0 -> 0.4:(w'=1) + 0.6:(w'=2);
    [w_q_down_unit] w=1 -> 1:(w'=3);
    [w_q_up_unit] w=2 -> 1:(w'=8);
    [] w=3 -> 0.4:(w'=4) + 0.6:(w'=5);
    [w_q_down_unit] w=4 -> 1:(w'=6);
    [w_q_up_unit] w=5 -> 1:(w'=0);
    [] w=6 -> 1:(w'=7);
    [w_o_ruined_unit] w=7 -> 1:(w'=13);
    [] w=8 -> 0.6:(w'=9) + 0.4:(w'=10);
    [w_q_up_unit] w=9 -> 1:(w'=11);
    [w_q_down_unit] w=10 -> 1:(w'=0);
    [] w=11 -> 1:(w'=12);
    [w_o_won_unit] w=12 -> 1:(w'=11);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [w_q_down_unit] q=0 -> 1:(q'=1);
    [w_q_up_unit] q=0 -> 1:(q'=2);
    [w_q_down_unit] q=1 -> 1:(q'=3);
    [w_q_up_unit] q=1 -> 1:(q'=0);
    [w_q_up_unit] q=2 -> 1:(q'=3);
    [w_q_down_unit] q=2 -> 1:(q'=0);
  endmodule
  
  module o
    o : [0..2] init 0;
  
    [w_o_ruined_unit] o=0 -> 1:(o'=2);
    [w_o_won_unit] o=0 -> 1:(o'=1);
    [w_o_won_unit] o=1 -> 1:(o'=1);
  endmodule
  
  label "end" = (w=13) & (q=3) & (o=2);
  label "cando_w_o_ruined_unit" = w=6;
  label "cando_w_o_ruined_unit_branch" = o=0;
  label "cando_w_o_won_unit" = w=11;
  label "cando_w_o_won_unit_branch" = (o=0) | (o=1);
  label "cando_w_q_down_unit" = (w=0) | (w=3) | (w=8);
  label "cando_w_q_down_unit_branch" = (q=0) | (q=1) | (q=2);
  label "cando_w_q_up_unit" = (w=0) | (w=3) | (w=8);
  label "cando_w_q_up_unit_branch" = (q=0) | (q=1) | (q=2);
  label "cando_w_o_branch" = (o=0) | (o=1);
  label "cando_w_q_branch" = (q=0) | (q=1) | (q=2);
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_w_o_ruined_unit" & "cando_w_o_branch") => "cando_w_o_ruined_unit_branch") & ((("cando_w_o_won_unit" & "cando_w_o_branch") => "cando_w_o_won_unit_branch") & ((("cando_w_q_down_unit" & "cando_w_q_branch") => "cando_w_q_down_unit_branch") & (("cando_w_q_up_unit" & "cando_w_q_branch") => "cando_w_q_up_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/rec-map-reduce.ctx =======
  
  mapper : mu t .
             (+) { worker1 ! 1.0 : datum<Int> .
             (+) { worker2 ! 1.0 : datum<Int> .
             (+) { worker3 ! 1.0 : datum<Int> .
             & {
               reducer ? continue(Int) . t,
               reducer ? stop .
                 (+) { worker1 ! 1.0 : stop .
                 (+) { worker2 ! 1.0 : stop .
                 (+) { worker3 ! 1.0 : stop .
                 end } } }
             } } } }
  
  worker1 : & { mapper ? datum(Int) .
            mu t .
              (+) { reducer ! 1.0 : result<Int> .
              & {
                mapper ? datum(Int) . t,
                mapper ? stop . end
              } } }
  
  worker2 : & { mapper ? datum(Int) .
            mu t .
              (+) { reducer ! 1.0 : result<Int> .
              & {
                mapper ? datum(Int) . t,
                mapper ? stop . end
              } } }
  
  worker3 : & { mapper ? datum(Int) .
            mu t .
              (+) { reducer ! 1.0 : result<Int> .
              & {
                mapper ? datum(Int) . t,
                mapper ? stop . end
              } } }
  
  reducer : mu t .
              & { worker1 ? result(Int) .
              & { worker2 ? result(Int) .
              & { worker3 ? result(Int) .
              (+) {
                mapper ! 0.4 : continue<Int> . t,
                mapper ! 0.6 : stop.end
              } } } }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module mapper
    mapper : [0..13] init 0;
  
    [] mapper=0 -> 1:(mapper'=1);
    [mapper_worker1_datum_int] mapper=1 -> 1:(mapper'=2);
    [] mapper=2 -> 1:(mapper'=3);
    [mapper_worker2_datum_int] mapper=3 -> 1:(mapper'=4);
    [] mapper=4 -> 1:(mapper'=5);
    [mapper_worker3_datum_int] mapper=5 -> 1:(mapper'=6);
    [reducer_mapper_continue_int] mapper=6 -> 1:(mapper'=0);
    [reducer_mapper_stop_unit] mapper=6 -> 1:(mapper'=7);
    [] mapper=7 -> 1:(mapper'=8);
    [mapper_worker1_stop_unit] mapper=8 -> 1:(mapper'=9);
    [] mapper=9 -> 1:(mapper'=10);
    [mapper_worker2_stop_unit] mapper=10 -> 1:(mapper'=11);
    [] mapper=11 -> 1:(mapper'=12);
    [mapper_worker3_stop_unit] mapper=12 -> 1:(mapper'=13);
  endmodule
  
  module worker1
    worker1 : [0..4] init 0;
  
    [mapper_worker1_datum_int] worker1=0 -> 1:(worker1'=1);
    [] worker1=1 -> 1:(worker1'=2);
    [worker1_reducer_result_int] worker1=2 -> 1:(worker1'=3);
    [mapper_worker1_datum_int] worker1=3 -> 1:(worker1'=1);
    [mapper_worker1_stop_unit] worker1=3 -> 1:(worker1'=4);
  endmodule
  
  module worker2
    worker2 : [0..4] init 0;
  
    [mapper_worker2_datum_int] worker2=0 -> 1:(worker2'=1);
    [] worker2=1 -> 1:(worker2'=2);
    [worker2_reducer_result_int] worker2=2 -> 1:(worker2'=3);
    [mapper_worker2_datum_int] worker2=3 -> 1:(worker2'=1);
    [mapper_worker2_stop_unit] worker2=3 -> 1:(worker2'=4);
  endmodule
  
  module worker3
    worker3 : [0..4] init 0;
  
    [mapper_worker3_datum_int] worker3=0 -> 1:(worker3'=1);
    [] worker3=1 -> 1:(worker3'=2);
    [worker3_reducer_result_int] worker3=2 -> 1:(worker3'=3);
    [mapper_worker3_datum_int] worker3=3 -> 1:(worker3'=1);
    [mapper_worker3_stop_unit] worker3=3 -> 1:(worker3'=4);
  endmodule
  
  module reducer
    reducer : [0..6] init 0;
  
    [worker1_reducer_result_int] reducer=0 -> 1:(reducer'=1);
    [worker2_reducer_result_int] reducer=1 -> 1:(reducer'=2);
    [worker3_reducer_result_int] reducer=2 -> 1:(reducer'=3);
    [] reducer=3 -> 0.4:(reducer'=4) + 0.6:(reducer'=5);
    [reducer_mapper_continue_int] reducer=4 -> 1:(reducer'=0);
    [reducer_mapper_stop_unit] reducer=5 -> 1:(reducer'=6);
  endmodule
  
  label "end" = (mapper=13) & (worker1=4) & (worker2=4) & (worker3=4) & (reducer=6);
  label "cando_mapper_worker1_datum_int" = mapper=0;
  label "cando_mapper_worker1_datum_int_branch" = (worker1=0) | (worker1=3);
  label "cando_mapper_worker1_stop_unit" = mapper=7;
  label "cando_mapper_worker1_stop_unit_branch" = worker1=3;
  label "cando_mapper_worker2_datum_int" = mapper=2;
  label "cando_mapper_worker2_datum_int_branch" = (worker2=0) | (worker2=3);
  label "cando_mapper_worker2_stop_unit" = mapper=9;
  label "cando_mapper_worker2_stop_unit_branch" = worker2=3;
  label "cando_mapper_worker3_datum_int" = mapper=4;
  label "cando_mapper_worker3_datum_int_branch" = (worker3=0) | (worker3=3);
  label "cando_mapper_worker3_stop_unit" = mapper=11;
  label "cando_mapper_worker3_stop_unit_branch" = worker3=3;
  label "cando_reducer_mapper_continue_int" = reducer=3;
  label "cando_reducer_mapper_continue_int_branch" = mapper=6;
  label "cando_reducer_mapper_stop_unit" = reducer=3;
  label "cando_reducer_mapper_stop_unit_branch" = mapper=6;
  label "cando_worker1_reducer_result_int" = worker1=1;
  label "cando_worker1_reducer_result_int_branch" = reducer=0;
  label "cando_worker2_reducer_result_int" = worker2=1;
  label "cando_worker2_reducer_result_int_branch" = reducer=1;
  label "cando_worker3_reducer_result_int" = worker3=1;
  label "cando_worker3_reducer_result_int_branch" = reducer=2;
  label "cando_mapper_worker1_branch" = (worker1=0) | (worker1=3);
  label "cando_mapper_worker2_branch" = (worker2=0) | (worker2=3);
  label "cando_mapper_worker3_branch" = (worker3=0) | (worker3=3);
  label "cando_reducer_mapper_branch" = mapper=6;
  label "cando_worker1_reducer_branch" = reducer=0;
  label "cando_worker2_reducer_branch" = reducer=1;
  label "cando_worker3_reducer_branch" = reducer=2;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_mapper_worker1_datum_int" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_datum_int_branch") & ((("cando_mapper_worker1_stop_unit" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_stop_unit_branch") & ((("cando_mapper_worker2_datum_int" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_datum_int_branch") & ((("cando_mapper_worker2_stop_unit" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_stop_unit_branch") & ((("cando_mapper_worker3_datum_int" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_datum_int_branch") & ((("cando_mapper_worker3_stop_unit" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_stop_unit_branch") & ((("cando_reducer_mapper_continue_int" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_continue_int_branch") & ((("cando_reducer_mapper_stop_unit" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_stop_unit_branch") & ((("cando_worker1_reducer_result_int" & "cando_worker1_reducer_branch") => "cando_worker1_reducer_result_int_branch") & ((("cando_worker2_reducer_result_int" & "cando_worker2_reducer_branch") => "cando_worker2_reducer_result_int_branch") & (("cando_worker3_reducer_result_int" & "cando_worker3_reducer_branch") => "cando_worker3_reducer_result_int_branch")))))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/rec-two-buyers.ctx =======
  
  alice: (+) { shop ! 1.0 : query<Str> .
         & { shop ? price(Int) .
         mu t .
            (+) {
                bob ! 0.5 : split<Int> . & { bob ? yes . (+) { shop ! 1.0 : buy . end }, bob ? no . t },
                bob ! 0.5 : cancel . (+) { shop ! 1.0 : no . end }
            } } }
  
  shop: & { alice ? query(Str) . (+) { alice ! 1.0 : price<Int> . & { alice ? buy.end, alice ? no.end } } }
  
  bob: mu t .
         & {
           alice ? split(Int) . (+) { alice ! 0.5 : yes.end, alice ! 0.5 : no.t },
           alice ? cancel . end
         }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module alice
    alice : [0..11] init 0;
  
    [] alice=0 -> 1:(alice'=1);
    [alice_shop_query_str] alice=1 -> 1:(alice'=2);
    [shop_alice_price_int] alice=2 -> 1:(alice'=3);
    [] alice=3 -> 0.5:(alice'=4) + 0.5:(alice'=5);
    [alice_bob_split_int] alice=4 -> 1:(alice'=6);
    [alice_bob_cancel_unit] alice=5 -> 1:(alice'=9);
    [bob_alice_yes_unit] alice=6 -> 1:(alice'=7);
    [bob_alice_no_unit] alice=6 -> 1:(alice'=3);
    [] alice=7 -> 1:(alice'=8);
    [alice_shop_buy_unit] alice=8 -> 1:(alice'=11);
    [] alice=9 -> 1:(alice'=10);
    [alice_shop_no_unit] alice=10 -> 1:(alice'=11);
  endmodule
  
  module shop
    shop : [0..4] init 0;
  
    [alice_shop_query_str] shop=0 -> 1:(shop'=1);
    [] shop=1 -> 1:(shop'=2);
    [shop_alice_price_int] shop=2 -> 1:(shop'=3);
    [alice_shop_buy_unit] shop=3 -> 1:(shop'=4);
    [alice_shop_no_unit] shop=3 -> 1:(shop'=4);
  endmodule
  
  module bob
    bob : [0..4] init 0;
  
    [alice_bob_split_int] bob=0 -> 1:(bob'=1);
    [alice_bob_cancel_unit] bob=0 -> 1:(bob'=4);
    [] bob=1 -> 0.5:(bob'=2) + 0.5:(bob'=3);
    [bob_alice_yes_unit] bob=2 -> 1:(bob'=4);
    [bob_alice_no_unit] bob=3 -> 1:(bob'=0);
  endmodule
  
  label "end" = (alice=11) & (shop=4) & (bob=4);
  label "cando_alice_bob_cancel_unit" = alice=3;
  label "cando_alice_bob_cancel_unit_branch" = bob=0;
  label "cando_alice_bob_split_int" = alice=3;
  label "cando_alice_bob_split_int_branch" = bob=0;
  label "cando_alice_shop_buy_unit" = alice=7;
  label "cando_alice_shop_buy_unit_branch" = shop=3;
  label "cando_alice_shop_no_unit" = alice=9;
  label "cando_alice_shop_no_unit_branch" = shop=3;
  label "cando_alice_shop_query_str" = alice=0;
  label "cando_alice_shop_query_str_branch" = shop=0;
  label "cando_bob_alice_no_unit" = bob=1;
  label "cando_bob_alice_no_unit_branch" = alice=6;
  label "cando_bob_alice_yes_unit" = bob=1;
  label "cando_bob_alice_yes_unit_branch" = alice=6;
  label "cando_shop_alice_price_int" = shop=1;
  label "cando_shop_alice_price_int_branch" = alice=2;
  label "cando_alice_bob_branch" = bob=0;
  label "cando_alice_shop_branch" = (shop=0) | (shop=3);
  label "cando_bob_alice_branch" = alice=6;
  label "cando_shop_alice_branch" = alice=2;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_cancel_unit" & "cando_alice_bob_branch") => "cando_alice_bob_cancel_unit_branch") & ((("cando_alice_bob_split_int" & "cando_alice_bob_branch") => "cando_alice_bob_split_int_branch") & ((("cando_alice_shop_buy_unit" & "cando_alice_shop_branch") => "cando_alice_shop_buy_unit_branch") & ((("cando_alice_shop_no_unit" & "cando_alice_shop_branch") => "cando_alice_shop_no_unit_branch") & ((("cando_alice_shop_query_str" & "cando_alice_shop_branch") => "cando_alice_shop_query_str_branch") & ((("cando_bob_alice_no_unit" & "cando_bob_alice_branch") => "cando_bob_alice_no_unit_branch") & ((("cando_bob_alice_yes_unit" & "cando_bob_alice_branch") => "cando_bob_alice_yes_unit_branch") & (("cando_shop_alice_price_int" & "cando_shop_alice_branch") => "cando_shop_alice_price_int_branch"))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/running.ctx =======
  
  u : (+) { s ! 1.0 : incr<Int> .
        mu t . & { c ? res(Int) . (+) { s ! 1.0 : incr<Int> . t } } }
  
  s : mu t . & {
    c ? crit . end,
    c ? disconn . mu r .
        (+) { c ! 1.0 : retry . r }
      + (+) { c ! 1.0 : conn .
          (+) {
            c ! 0.9 : incr<Int> . t,
            c ! 0.1 : upgrade . mu u2 . (+) { c ! 1.0 : incr<Int> . & { u ? incr(Int) . u2 } }
          } },
    c ? err(Int) .
      (+) {
        c ! 0.9 : incr<Int> . t,
        c ! 0.1 : upgrade . mu u2 . (+) { c ! 1.0 : incr<Int> . & { u ? incr(Int) . u2 } }
      },
    u ? incr(Int) .
      (+) {
        c ! 0.9 : incr<Int> . t,
        c ! 0.1 : upgrade . mu u2 . (+) { c ! 1.0 : incr<Int> . & { u ? incr(Int) . u2 } }
      }
  }
  
  c : mu t . & {
    s ? upgrade . mu u2 . & { s ? incr(Int) . (+) { u ! 1.0 : res<Int> . u2 } },
    s ? incr(Int) .
        (+) {
          u ! 0.8 : res<Int> . t,
          s ! 0.1 : err<Int> . t,
          s ! 0.05 : crit . end,
          s ! 0.05 : disconn . mu r . & { s ? retry . r, s ? conn . t }
        }
      + (+) { u ! 1.0 : res<Int> . t }
  }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module u
    u : [0..5] init 0;
  
    [] u=0 -> 1:(u'=1);
    [u_s_incr_int] u=1 -> 1:(u'=2);
    [c_u_res_int] u=2 -> 1:(u'=3);
    [] u=3 -> 1:(u'=4);
    [u_s_incr_int] u=4 -> 1:(u'=2);
  endmodule
  
  module s
    s : [0..24] init 0;
  
    [c_s_crit_unit] s=0 -> 1:(s'=24);
    [c_s_disconn_unit] s=0 -> 1:(s'=1);
    [c_s_err_int] s=0 -> 1:(s'=12);
    [u_s_incr_int] s=0 -> 1:(s'=18);
    [] s=1 -> 1:(s'=2);
    [] s=1 -> 1:(s'=4);
    [] s=2 -> 1:(s'=3);
    [] s=4 -> 1:(s'=5);
    [s_c_retry_unit] s=3 -> 1:(s'=1);
    [s_c_conn_unit] s=5 -> 1:(s'=6);
    [] s=6 -> 0.9:(s'=7) + 0.1:(s'=8);
    [s_c_incr_int] s=7 -> 1:(s'=0);
    [s_c_upgrade_unit] s=8 -> 1:(s'=9);
    [] s=9 -> 1:(s'=10);
    [s_c_incr_int] s=10 -> 1:(s'=11);
    [u_s_incr_int] s=11 -> 1:(s'=9);
    [] s=12 -> 0.9:(s'=13) + 0.1:(s'=14);
    [s_c_incr_int] s=13 -> 1:(s'=0);
    [s_c_upgrade_unit] s=14 -> 1:(s'=15);
    [] s=15 -> 1:(s'=16);
    [s_c_incr_int] s=16 -> 1:(s'=17);
    [u_s_incr_int] s=17 -> 1:(s'=15);
    [] s=18 -> 0.9:(s'=19) + 0.1:(s'=20);
    [s_c_incr_int] s=19 -> 1:(s'=0);
    [s_c_upgrade_unit] s=20 -> 1:(s'=21);
    [] s=21 -> 1:(s'=22);
    [s_c_incr_int] s=22 -> 1:(s'=23);
    [u_s_incr_int] s=23 -> 1:(s'=21);
  endmodule
  
  module c
    c : [0..13] init 0;
  
    [s_c_upgrade_unit] c=0 -> 1:(c'=1);
    [s_c_incr_int] c=0 -> 1:(c'=4);
    [s_c_incr_int] c=1 -> 1:(c'=2);
    [] c=2 -> 1:(c'=3);
    [c_u_res_int] c=3 -> 1:(c'=1);
    [] c=4 -> 1:(c'=5);
    [] c=4 -> 1:(c'=11);
    [] c=5 -> 0.8:(c'=6) + 0.1:(c'=7) + 0.05:(c'=8) + 0.05:(c'=9);
    [] c=11 -> 1:(c'=12);
    [c_u_res_int] c=6 -> 1:(c'=0);
    [c_s_err_int] c=7 -> 1:(c'=0);
    [c_s_crit_unit] c=8 -> 1:(c'=13);
    [c_s_disconn_unit] c=9 -> 1:(c'=10);
    [c_u_res_int] c=12 -> 1:(c'=0);
    [s_c_retry_unit] c=10 -> 1:(c'=10);
    [s_c_conn_unit] c=10 -> 1:(c'=0);
  endmodule
  
  label "end" = (u=5) & (s=24) & (c=13);
  label "cando_c_s_crit_unit" = c=4;
  label "cando_c_s_crit_unit_branch" = s=0;
  label "cando_c_s_disconn_unit" = c=4;
  label "cando_c_s_disconn_unit_branch" = s=0;
  label "cando_c_s_err_int" = c=4;
  label "cando_c_s_err_int_branch" = s=0;
  label "cando_c_u_res_int" = (c=2) | (c=4);
  label "cando_c_u_res_int_branch" = u=2;
  label "cando_s_c_conn_unit" = s=1;
  label "cando_s_c_conn_unit_branch" = c=10;
  label "cando_s_c_incr_int" = (s=6) | (s=9) | (s=12) | (s=15) | (s=18) | (s=21);
  label "cando_s_c_incr_int_branch" = (c=0) | (c=1);
  label "cando_s_c_retry_unit" = s=1;
  label "cando_s_c_retry_unit_branch" = c=10;
  label "cando_s_c_upgrade_unit" = (s=6) | (s=12) | (s=18);
  label "cando_s_c_upgrade_unit_branch" = c=0;
  label "cando_u_s_incr_int" = (u=0) | (u=3);
  label "cando_u_s_incr_int_branch" = (s=0) | (s=11) | (s=17) | (s=23);
  label "cando_c_s_branch" = s=0;
  label "cando_c_u_branch" = u=2;
  label "cando_s_c_branch" = (c=0) | (c=1) | (c=10);
  label "cando_u_s_branch" = (s=0) | (s=11) | (s=17) | (s=23);
  label "wals" = ((u=2) & (s=0) & (c=8)) | ((u=2) & (s=0) & (c=9)) | ((u=2) & (s=3) & (c=10)) | ((u=2) & (s=24) & (c=13));
  
  // Type safety
  P>=1 [ (G ((("cando_c_s_crit_unit" & "cando_c_s_branch") => "cando_c_s_crit_unit_branch") & ((("cando_c_s_disconn_unit" & "cando_c_s_branch") => "cando_c_s_disconn_unit_branch") & ((("cando_c_s_err_int" & "cando_c_s_branch") => "cando_c_s_err_int_branch") & ((("cando_c_u_res_int" & "cando_c_u_branch") => "cando_c_u_res_int_branch") & ((("cando_s_c_conn_unit" & "cando_s_c_branch") => "cando_s_c_conn_unit_branch") & ((("cando_s_c_incr_int" & "cando_s_c_branch") => "cando_s_c_incr_int_branch") & ((("cando_s_c_retry_unit" & "cando_s_c_branch") => "cando_s_c_retry_unit_branch") & ((("cando_s_c_upgrade_unit" & "cando_s_c_branch") => "cando_s_c_upgrade_unit_branch") & (("cando_u_s_incr_int" & "cando_u_s_branch") => "cando_u_s_incr_int_branch")))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.6896675050354955 (+/- 6.79348995065338E-6 estimated; rel err 9.85038428090611E-6)
  
  Liveness (lower bound)
  Result: 0.5263273372547235 (+/- 4.870928780374453E-6 estimated; rel err 9.254561630373948E-6)
  
  
  
  
   ======= TEST ../examples/same-labels.ctx =======
  
  (* Previous iterations of the translation used ID(-) to work out the next state.
     This causes a problem in the following case.
  
     Suppose p::q::l1 is assigned ID 2 and p::q::l2 is assigned ID 1, and the state
     after q (+) l2 to be n. Then, the second q (+) l1 will first do an initial
     translation to n + 1, then skip by two to n + 3. This will exceed the state
     space of p.
  
     This test checks for this case.
  *)
  
  p : (+) {
        q ! 0.5 : l1 . end,
        q ! 0.5 : l2 . (+) { q ! 1.0 : l1 . end }
      }
  
  q : & {
        p ? l1 . end,
        p ? l2 . & { p ? l1 . end }
      }
  
  
  (* Try the symmetric case for if the ID ordering changes *)
  
  p1 : (+) {
        q1 ! 0.5 : l1 . (+) { q1 ! 1.0 : l2 . end },
        q1 ! 0.5 : l2 . end
      }
  
  q1 : & {
        p1 ? l1 . & { p1 ? l2 . end },
        p1 ? l2 . end
      }
  
  
  (* Shuffle the ordering of the two branches *)
  
  q2 : & {
        p2 ? l1 . end,
        p2 ? l2 . & { p2 ? l1 . end }
      }
  
  p2 : (+) {
        q2 ! 0.5 : l2 . (+) { q2 ! 1.0 : l1 . end },
        q2 ! 0.5 : l1 . end
      }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module p
    p : [0..5] init 0;
  
    [] p=0 -> 0.5:(p'=1) + 0.5:(p'=2);
    [p_q_l1_unit] p=1 -> 1:(p'=5);
    [p_q_l2_unit] p=2 -> 1:(p'=3);
    [] p=3 -> 1:(p'=4);
    [p_q_l1_unit] p=4 -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..2] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=2);
    [p_q_l2_unit] q=0 -> 1:(q'=1);
    [p_q_l1_unit] q=1 -> 1:(q'=2);
  endmodule
  
  module p1
    p1 : [0..5] init 0;
  
    [] p1=0 -> 0.5:(p1'=1) + 0.5:(p1'=2);
    [p1_q1_l1_unit] p1=1 -> 1:(p1'=3);
    [p1_q1_l2_unit] p1=2 -> 1:(p1'=5);
    [] p1=3 -> 1:(p1'=4);
    [p1_q1_l2_unit] p1=4 -> 1:(p1'=5);
  endmodule
  
  module q1
    q1 : [0..2] init 0;
  
    [p1_q1_l1_unit] q1=0 -> 1:(q1'=1);
    [p1_q1_l2_unit] q1=0 -> 1:(q1'=2);
    [p1_q1_l2_unit] q1=1 -> 1:(q1'=2);
  endmodule
  
  module q2
    q2 : [0..2] init 0;
  
    [p2_q2_l1_unit] q2=0 -> 1:(q2'=2);
    [p2_q2_l2_unit] q2=0 -> 1:(q2'=1);
    [p2_q2_l1_unit] q2=1 -> 1:(q2'=2);
  endmodule
  
  module p2
    p2 : [0..5] init 0;
  
    [] p2=0 -> 0.5:(p2'=1) + 0.5:(p2'=2);
    [p2_q2_l2_unit] p2=1 -> 1:(p2'=3);
    [p2_q2_l1_unit] p2=2 -> 1:(p2'=5);
    [] p2=3 -> 1:(p2'=4);
    [p2_q2_l1_unit] p2=4 -> 1:(p2'=5);
  endmodule
  
  label "end" = (p=5) & (q=2) & (p1=5) & (q1=2) & (q2=2) & (p2=5);
  label "cando_p_q_l1_unit" = (p=0) | (p=3);
  label "cando_p_q_l1_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p1_q1_l1_unit" = p1=0;
  label "cando_p1_q1_l1_unit_branch" = q1=0;
  label "cando_p1_q1_l2_unit" = (p1=0) | (p1=3);
  label "cando_p1_q1_l2_unit_branch" = (q1=0) | (q1=1);
  label "cando_p2_q2_l1_unit" = (p2=0) | (p2=3);
  label "cando_p2_q2_l1_unit_branch" = (q2=0) | (q2=1);
  label "cando_p2_q2_l2_unit" = p2=0;
  label "cando_p2_q2_l2_unit_branch" = q2=0;
  label "cando_p_q_branch" = (q=0) | (q=1);
  label "cando_p1_q1_branch" = (q1=0) | (q1=1);
  label "cando_p2_q2_branch" = (q2=0) | (q2=1);
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & ((("cando_p1_q1_l1_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l1_unit_branch") & ((("cando_p1_q1_l2_unit" & "cando_p1_q1_branch") => "cando_p1_q1_l2_unit_branch") & ((("cando_p2_q2_l1_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l1_unit_branch") & (("cando_p2_q2_l2_unit" & "cando_p2_q2_branch") => "cando_p2_q2_l2_unit_branch"))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/simple.ctx =======
  
  alice : (+) { bob ! 0.33 : a.end, bob ! 0.67 : b<Int>.end }
  bob : & { alice ? a.end, alice ? b(Int).end }
  
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..3] init 0;
  
    [] alice=0 -> 0.33:(alice'=1) + 0.67:(alice'=2);
    [alice_bob_a_unit] alice=1 -> 1:(alice'=3);
    [alice_bob_b_int] alice=2 -> 1:(alice'=3);
  endmodule
  
  module bob
    bob : [0..1] init 0;
  
    [alice_bob_a_unit] bob=0 -> 1:(bob'=1);
    [alice_bob_b_int] bob=0 -> 1:(bob'=1);
  endmodule
  
  label "end" = (alice=3) & (bob=1);
  label "cando_alice_bob_a_unit" = alice=0;
  label "cando_alice_bob_a_unit_branch" = bob=0;
  label "cando_alice_bob_b_int" = alice=0;
  label "cando_alice_bob_b_int_branch" = bob=0;
  label "cando_alice_bob_branch" = bob=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_a_unit" & "cando_alice_bob_branch") => "cando_alice_bob_a_unit_branch") & (("cando_alice_bob_b_int" & "cando_alice_bob_branch") => "cando_alice_bob_b_int_branch"))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/subprob.ctx =======
  
  (* Case where PDF is different from NPDF, due to unknown behaviour *)
  
  commander : (+) {
                a ! 0.6 : deadlock . end,
                a ! 0.4 : nodeadlock . end
              }
  
  a : & {
        commander ? deadlock . & { b ? msg . end },
        commander ? nodeadlock . (+) { b ! 1.0 : msg . end }
      }
  
  b : & { a ? msg . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [b_a_msg_unit] false -> 1:(closure'=false);
  endmodule
  
  module commander
    commander : [0..3] init 0;
  
    [] commander=0 -> 0.6:(commander'=1) + 0.4:(commander'=2);
    [commander_a_deadlock_unit] commander=1 -> 1:(commander'=3);
    [commander_a_nodeadlock_unit] commander=2 -> 1:(commander'=3);
  endmodule
  
  module a
    a : [0..4] init 0;
  
    [commander_a_deadlock_unit] a=0 -> 1:(a'=1);
    [commander_a_nodeadlock_unit] a=0 -> 1:(a'=2);
    [b_a_msg_unit] a=1 -> 1:(a'=4);
    [] a=2 -> 1:(a'=3);
    [a_b_msg_unit] a=3 -> 1:(a'=4);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_msg_unit] b=0 -> 1:(b'=1);
  endmodule
  
  label "end" = (commander=3) & (a=4) & (b=1);
  label "cando_a_b_msg_unit" = a=2;
  label "cando_a_b_msg_unit_branch" = b=0;
  label "cando_b_a_msg_unit" = false;
  label "cando_b_a_msg_unit_branch" = a=1;
  label "cando_commander_a_deadlock_unit" = commander=0;
  label "cando_commander_a_deadlock_unit_branch" = a=0;
  label "cando_commander_a_nodeadlock_unit" = commander=0;
  label "cando_commander_a_nodeadlock_unit_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=1;
  label "cando_commander_a_branch" = a=0;
  label "wals" = ((commander=1) & (a=0) & (b=0)) | ((commander=3) & (a=1) & (b=0));
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_msg_unit" & "cando_a_b_branch") => "cando_a_b_msg_unit_branch") & ((("cando_b_a_msg_unit" & "cando_b_a_branch") => "cando_b_a_msg_unit_branch") & ((("cando_commander_a_deadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_deadlock_unit_branch") & (("cando_commander_a_nodeadlock_unit" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.4 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.4 (exact floating point)
  
  
  
  
   ======= TEST ../examples/sync-alone.ctx =======
  
  (* What happens if we send to a recipient who does not ever expect to receive? *)
  
  alice : (+) {
  	        bob ! 0.4 : l1 . end,
  	        bob ! 0.6 : l2 . end
          }
  
  bob : & {
  	      charlie ? l1 . end,
  	      charlie ? l2 . end
        }
  
  charlie : (+) {
  	          bob ! 0.5 : l1 . end,
  	          bob ! 0.5 : l2 . end
            }
  
  (* What about the other way? *)
  
  a : & {
        b ? l1 . end,
        b ? l2 . end
      }
  
  b : (+) {
        c ! 0.7 : l1 . end,
        c ! 0.3 : l2 . end
      }
  
  c : & {
        b ? l1 . end,
        b ? l2 . end
      }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [alice_bob_l1_unit] false -> 1:(closure'=false);
    [alice_bob_l2_unit] false -> 1:(closure'=false);
    [b_a_l1_unit] false -> 1:(closure'=false);
    [b_a_l2_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..3] init 0;
  
    [] alice=0 -> 0.4:(alice'=1) + 0.6:(alice'=2);
    [alice_bob_l1_unit] alice=1 -> 1:(alice'=3);
    [alice_bob_l2_unit] alice=2 -> 1:(alice'=3);
  endmodule
  
  module bob
    bob : [0..1] init 0;
  
    [charlie_bob_l1_unit] bob=0 -> 1:(bob'=1);
    [charlie_bob_l2_unit] bob=0 -> 1:(bob'=1);
  endmodule
  
  module charlie
    charlie : [0..3] init 0;
  
    [] charlie=0 -> 0.5:(charlie'=1) + 0.5:(charlie'=2);
    [charlie_bob_l1_unit] charlie=1 -> 1:(charlie'=3);
    [charlie_bob_l2_unit] charlie=2 -> 1:(charlie'=3);
  endmodule
  
  module a
    a : [0..1] init 0;
  
    [b_a_l1_unit] a=0 -> 1:(a'=1);
    [b_a_l2_unit] a=0 -> 1:(a'=1);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] b=0 -> 0.7:(b'=1) + 0.3:(b'=2);
    [b_c_l1_unit] b=1 -> 1:(b'=3);
    [b_c_l2_unit] b=2 -> 1:(b'=3);
  endmodule
  
  module c
    c : [0..1] init 0;
  
    [b_c_l1_unit] c=0 -> 1:(c'=1);
    [b_c_l2_unit] c=0 -> 1:(c'=1);
  endmodule
  
  label "end" = (alice=3) & (bob=1) & (charlie=3) & (a=1) & (b=3) & (c=1);
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
  label "wals" = ((alice=1) & (bob=0) & (charlie=1) & (a=0) & (b=1) & (c=0)) | ((alice=1) & (bob=0) & (charlie=1) & (a=0) & (b=2) & (c=0)) | ((alice=1) & (bob=0) & (charlie=1) & (a=0) & (b=3) & (c=1)) | ((alice=1) & (bob=0) & (charlie=2) & (a=0) & (b=1) & (c=0)) | ((alice=1) & (bob=0) & (charlie=2) & (a=0) & (b=2) & (c=0)) | ((alice=1) & (bob=0) & (charlie=2) & (a=0) & (b=3) & (c=1)) | ((alice=1) & (bob=1) & (charlie=3) & (a=0) & (b=1) & (c=0)) | ((alice=1) & (bob=1) & (charlie=3) & (a=0) & (b=2) & (c=0)) | ((alice=1) & (bob=1) & (charlie=3) & (a=0) & (b=3) & (c=1)) | ((alice=2) & (bob=0) & (charlie=1) & (a=0) & (b=1) & (c=0)) | ((alice=2) & (bob=0) & (charlie=1) & (a=0) & (b=2) & (c=0)) | ((alice=2) & (bob=0) & (charlie=1) & (a=0) & (b=3) & (c=1)) | ((alice=2) & (bob=0) & (charlie=2) & (a=0) & (b=1) & (c=0)) | ((alice=2) & (bob=0) & (charlie=2) & (a=0) & (b=2) & (c=0)) | ((alice=2) & (bob=0) & (charlie=2) & (a=0) & (b=3) & (c=1)) | ((alice=2) & (bob=1) & (charlie=3) & (a=0) & (b=1) & (c=0)) | ((alice=2) & (bob=1) & (charlie=3) & (a=0) & (b=2) & (c=0)) | ((alice=2) & (bob=1) & (charlie=3) & (a=0) & (b=3) & (c=1));
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_l1_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l1_unit_branch") & ((("cando_alice_bob_l2_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l2_unit_branch") & ((("cando_b_a_l1_unit" & "cando_b_a_branch") => "cando_b_a_l1_unit_branch") & ((("cando_b_a_l2_unit" & "cando_b_a_branch") => "cando_b_a_l2_unit_branch") & ((("cando_b_c_l1_unit" & "cando_b_c_branch") => "cando_b_c_l1_unit_branch") & ((("cando_b_c_l2_unit" & "cando_b_c_branch") => "cando_b_c_l2_unit_branch") & ((("cando_charlie_bob_l1_unit" & "cando_charlie_bob_branch") => "cando_charlie_bob_l1_unit_branch") & (("cando_charlie_bob_l2_unit" & "cando_charlie_bob_branch") => "cando_charlie_bob_l2_unit_branch"))))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 0.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/translation-example.ctx =======
  
  (* Translation example *)
  
  p : (+) {
        q ! 0.2 : l1 . mu t . (+) { q ! 1.0 : l1 . t },
        q ! 0.3 : l2 . (+) { q ! 1.0 : l2 . end },
        q ! 0.5 : l3 . end
  }
  
  q : & {
        p ? l1 . mu t. & { p ? l1 . t },
        p ? l2 . & { p ? l2 . end },
        p ? l3 . end
  }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..8] init 0;
  
    [] p=0 -> 0.2:(p'=1) + 0.3:(p'=2) + 0.5:(p'=3);
    [p_q_l1_unit] p=1 -> 1:(p'=4);
    [p_q_l2_unit] p=2 -> 1:(p'=6);
    [p_q_l3_unit] p=3 -> 1:(p'=8);
    [] p=4 -> 1:(p'=5);
    [p_q_l1_unit] p=5 -> 1:(p'=4);
    [] p=6 -> 1:(p'=7);
    [p_q_l2_unit] p=7 -> 1:(p'=8);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=1);
    [p_q_l2_unit] q=0 -> 1:(q'=2);
    [p_q_l3_unit] q=0 -> 1:(q'=3);
    [p_q_l1_unit] q=1 -> 1:(q'=1);
    [p_q_l2_unit] q=2 -> 1:(q'=3);
  endmodule
  
  label "end" = (p=8) & (q=3);
  label "cando_p_q_l1_unit" = (p=0) | (p=4);
  label "cando_p_q_l1_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_l2_unit" = (p=0) | (p=6);
  label "cando_p_q_l2_unit_branch" = (q=0) | (q=2);
  label "cando_p_q_l3_unit" = p=0;
  label "cando_p_q_l3_unit_branch" = q=0;
  label "cando_p_q_branch" = (q=0) | (q=1) | (q=2);
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/two-independent.ctx =======
  
  a : mu t . (+) { b ! 1 : l . t }
  b : mu t . & { a ? l . t }
  
  c : (+) { d ! 1 : l . end }
  d : & { c ? l . & { c ? l2 . end } }
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [c_d_l2_unit] false -> 1:(closure'=false);
  endmodule
  
  module a
    a : [0..2] init 0;
  
    [] a=0 -> 1:(a'=1);
    [a_b_l_unit] a=1 -> 1:(a'=0);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_l_unit] b=0 -> 1:(b'=0);
  endmodule
  
  module c
    c : [0..2] init 0;
  
    [] c=0 -> 1:(c'=1);
    [c_d_l_unit] c=1 -> 1:(c'=2);
  endmodule
  
  module d
    d : [0..2] init 0;
  
    [c_d_l_unit] d=0 -> 1:(d'=1);
    [c_d_l2_unit] d=1 -> 1:(d'=2);
  endmodule
  
  label "end" = (a=2) & (b=1) & (c=2) & (d=2);
  label "cando_a_b_l_unit" = a=0;
  label "cando_a_b_l_unit_branch" = b=0;
  label "cando_c_d_l_unit" = c=0;
  label "cando_c_d_l_unit_branch" = d=0;
  label "cando_c_d_l2_unit" = false;
  label "cando_c_d_l2_unit_branch" = d=1;
  label "cando_a_b_branch" = b=0;
  label "cando_c_d_branch" = (d=0) | (d=1);
  label "wals" = (a=1) & (b=0) & (c=2) & (d=1);
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l_unit" & "cando_a_b_branch") => "cando_a_b_l_unit_branch") & ((("cando_c_d_l_unit" & "cando_c_d_branch") => "cando_c_d_l_unit_branch") & (("cando_c_d_l2_unit" & "cando_c_d_branch") => "cando_c_d_l2_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/unbound-variable.ctx =======
  
  a : mu t . (+) { b ! 0.5 : l1 . t1, b ! 0.5 : l2 . end }
  
  b : mu t . & { a ? l1 . end, a ? l2 . end }
  
   ======= PRISM output ========
  
  Typing context is not well-formed: unbound variable t1
  
  
   ======= Property checking =======
  
  Typing context is not well-formed: unbound variable t1
  
  
  
  
  
   ======= TEST ../examples/unsafe-2.ctx =======
  
  (* Two pairs being unsafe in parallel *)
  
  a : (+) {
        b ! 0.4 : l1 . end,
        b ! 0.6 : l2 . end
      }
  
  b : & {
        a ? l2 . end,
        a ? l3 . end
      }
  
  c : (+) {
        d ! 0.3 : l1 . end,
        d ! 0.7 : l2 . end
      }
  
  d : & {
        c ? l2 . end,
        c ? l3 . end
      }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [a_b_l1_unit] false -> 1:(closure'=false);
    [a_b_l3_unit] false -> 1:(closure'=false);
    [c_d_l1_unit] false -> 1:(closure'=false);
    [c_d_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module a
    a : [0..3] init 0;
  
    [] a=0 -> 0.4:(a'=1) + 0.6:(a'=2);
    [a_b_l1_unit] a=1 -> 1:(a'=3);
    [a_b_l2_unit] a=2 -> 1:(a'=3);
  endmodule
  
  module b
    b : [0..1] init 0;
  
    [a_b_l2_unit] b=0 -> 1:(b'=1);
    [a_b_l3_unit] b=0 -> 1:(b'=1);
  endmodule
  
  module c
    c : [0..3] init 0;
  
    [] c=0 -> 0.3:(c'=1) + 0.7:(c'=2);
    [c_d_l1_unit] c=1 -> 1:(c'=3);
    [c_d_l2_unit] c=2 -> 1:(c'=3);
  endmodule
  
  module d
    d : [0..1] init 0;
  
    [c_d_l2_unit] d=0 -> 1:(d'=1);
    [c_d_l3_unit] d=0 -> 1:(d'=1);
  endmodule
  
  label "end" = (a=3) & (b=1) & (c=3) & (d=1);
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
  label "wals" = ((a=1) & (b=0) & (c=1) & (d=0)) | ((a=1) & (b=0) & (c=2) & (d=0)) | ((a=1) & (b=0) & (c=3) & (d=1)) | ((a=2) & (b=0) & (c=1) & (d=0)) | ((a=3) & (b=1) & (c=1) & (d=0));
  
  // Type safety
  P>=1 [ (G ((("cando_a_b_l1_unit" & "cando_a_b_branch") => "cando_a_b_l1_unit_branch") & ((("cando_a_b_l2_unit" & "cando_a_b_branch") => "cando_a_b_l2_unit_branch") & ((("cando_a_b_l3_unit" & "cando_a_b_branch") => "cando_a_b_l3_unit_branch") & ((("cando_c_d_l1_unit" & "cando_c_d_branch") => "cando_c_d_l1_unit_branch") & ((("cando_c_d_l2_unit" & "cando_c_d_branch") => "cando_c_d_l2_unit_branch") & (("cando_c_d_l3_unit" & "cando_c_d_branch") => "cando_c_d_l3_unit_branch"))))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Deadlock freedom (lower bound)
  Result: 0.41999999999999993 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.41999999999999993 (exact floating point)
  
  
  
  
   ======= TEST ../examples/unsafe.ctx =======
  
  alice : (+) {
            bob ! 0.6 : l1 . end,
            bob ! 0.3 : l2 .
                  (+) {
                    bob ! 0.9 : l3 . end,
                    bob ! 0.1 : l4 . end
                  },
            bob ! 0.1 : l5 . end
          }
  
  bob : & {
          alice ? l1 . end,
          alice ? l2 . & { alice ? l3 . end }
        }
  
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [alice_bob_l4_unit] false -> 1:(closure'=false);
    [alice_bob_l5_unit] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..7] init 0;
  
    [] alice=0 -> 0.6:(alice'=1) + 0.3:(alice'=2) + 0.1:(alice'=3);
    [alice_bob_l1_unit] alice=1 -> 1:(alice'=7);
    [alice_bob_l2_unit] alice=2 -> 1:(alice'=4);
    [alice_bob_l5_unit] alice=3 -> 1:(alice'=7);
    [] alice=4 -> 0.9:(alice'=5) + 0.1:(alice'=6);
    [alice_bob_l3_unit] alice=5 -> 1:(alice'=7);
    [alice_bob_l4_unit] alice=6 -> 1:(alice'=7);
  endmodule
  
  module bob
    bob : [0..2] init 0;
  
    [alice_bob_l1_unit] bob=0 -> 1:(bob'=2);
    [alice_bob_l2_unit] bob=0 -> 1:(bob'=1);
    [alice_bob_l3_unit] bob=1 -> 1:(bob'=2);
  endmodule
  
  label "end" = (alice=7) & (bob=2);
  label "cando_alice_bob_l1_unit" = alice=0;
  label "cando_alice_bob_l1_unit_branch" = bob=0;
  label "cando_alice_bob_l2_unit" = alice=0;
  label "cando_alice_bob_l2_unit_branch" = bob=0;
  label "cando_alice_bob_l3_unit" = alice=4;
  label "cando_alice_bob_l3_unit_branch" = bob=1;
  label "cando_alice_bob_l4_unit" = alice=4;
  label "cando_alice_bob_l4_unit_branch" = false;
  label "cando_alice_bob_l5_unit" = alice=0;
  label "cando_alice_bob_l5_unit_branch" = false;
  label "cando_alice_bob_branch" = (bob=0) | (bob=1);
  label "wals" = ((alice=3) & (bob=0)) | ((alice=6) & (bob=1));
  
  // Type safety
  P>=1 [ (G ((("cando_alice_bob_l1_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l1_unit_branch") & ((("cando_alice_bob_l2_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l2_unit_branch") & ((("cando_alice_bob_l3_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l3_unit_branch") & ((("cando_alice_bob_l4_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l4_unit_branch") & (("cando_alice_bob_l5_unit" & "cando_alice_bob_branch") => "cando_alice_bob_l5_unit_branch")))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Deadlock freedom (lower bound)
  Result: 0.87 (exact floating point)
  
  Liveness (lower bound)
  Result: 0.87 (exact floating point)
  
  
  
  
   ======= TEST ../examples/von-neumann-coin.ctx =======
  
  (* Coin debiasing *)
  
  f : mu t . (+) {
        c ! 0.9 : heads . (+) {
          c ! 0.9 : heads . t,
          c ! 0.1 : tails . mu s . (+) { o ! 1.0 : heads . s }
        },
        c ! 0.1 : tails . (+) {
          c ! 0.9 : heads . (+) { o ! 1.0 : tails . end },
          c ! 0.1 : tails . t
        }
      }
  
  c : mu t . & {
        f ? heads . & {
          f ? heads . t,
          f ? tails . end
        },
        f ? tails . & {
          f ? heads . end,
          f ? tails . t
        }
      }
  
  o : & {
        f ? heads . mu t . & { f ? heads . t },
        f ? tails . end
      }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module f
    f : [0..13] init 0;
  
    [] f=0 -> 0.9:(f'=1) + 0.1:(f'=2);
    [f_c_heads_unit] f=1 -> 1:(f'=3);
    [f_c_tails_unit] f=2 -> 1:(f'=8);
    [] f=3 -> 0.9:(f'=4) + 0.1:(f'=5);
    [f_c_heads_unit] f=4 -> 1:(f'=0);
    [f_c_tails_unit] f=5 -> 1:(f'=6);
    [] f=6 -> 1:(f'=7);
    [f_o_heads_unit] f=7 -> 1:(f'=6);
    [] f=8 -> 0.9:(f'=9) + 0.1:(f'=10);
    [f_c_heads_unit] f=9 -> 1:(f'=11);
    [f_c_tails_unit] f=10 -> 1:(f'=0);
    [] f=11 -> 1:(f'=12);
    [f_o_tails_unit] f=12 -> 1:(f'=13);
  endmodule
  
  module c
    c : [0..3] init 0;
  
    [f_c_heads_unit] c=0 -> 1:(c'=1);
    [f_c_tails_unit] c=0 -> 1:(c'=2);
    [f_c_heads_unit] c=1 -> 1:(c'=0);
    [f_c_tails_unit] c=1 -> 1:(c'=3);
    [f_c_heads_unit] c=2 -> 1:(c'=3);
    [f_c_tails_unit] c=2 -> 1:(c'=0);
  endmodule
  
  module o
    o : [0..2] init 0;
  
    [f_o_heads_unit] o=0 -> 1:(o'=1);
    [f_o_tails_unit] o=0 -> 1:(o'=2);
    [f_o_heads_unit] o=1 -> 1:(o'=1);
  endmodule
  
  label "end" = (f=13) & (c=3) & (o=2);
  label "cando_f_c_heads_unit" = (f=0) | (f=3) | (f=8);
  label "cando_f_c_heads_unit_branch" = (c=0) | (c=1) | (c=2);
  label "cando_f_c_tails_unit" = (f=0) | (f=3) | (f=8);
  label "cando_f_c_tails_unit_branch" = (c=0) | (c=1) | (c=2);
  label "cando_f_o_heads_unit" = f=6;
  label "cando_f_o_heads_unit_branch" = (o=0) | (o=1);
  label "cando_f_o_tails_unit" = f=11;
  label "cando_f_o_tails_unit_branch" = o=0;
  label "cando_f_c_branch" = (c=0) | (c=1) | (c=2);
  label "cando_f_o_branch" = (o=0) | (o=1);
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G ((("cando_f_c_heads_unit" & "cando_f_c_branch") => "cando_f_c_heads_unit_branch") & ((("cando_f_c_tails_unit" & "cando_f_c_branch") => "cando_f_c_tails_unit_branch") & ((("cando_f_o_heads_unit" & "cando_f_o_branch") => "cando_f_o_heads_unit_branch") & (("cando_f_o_tails_unit" & "cando_f_o_branch") => "cando_f_o_tails_unit_branch"))))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/zero-probability-df.ctx =======
  
  (* This context has a zero-probability reduction into a deadlocked context. *)
  
  p : (+) { q ! 1.0 : l1 . end, q ! 0 : l2 . (+) { q ! 1.0 : l3 . end } }
  q : & { p ? l1 . end, p ? l2 . end }
  
   ======= PRISM output ========
  
  Warning: found zero-probability in context.
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [p_q_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..5] init 0;
  
    [] p=0 -> 1:(p'=1) + 0:(p'=2);
    [p_q_l1_unit] p=1 -> 1:(p'=5);
    [p_q_l2_unit] p=2 -> 1:(p'=3);
    [] p=3 -> 1:(p'=4);
    [p_q_l3_unit] p=4 -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..1] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=1);
    [p_q_l2_unit] q=0 -> 1:(q'=1);
  endmodule
  
  label "end" = (p=5) & (q=1);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = q=0;
  label "cando_p_q_l3_unit" = p=3;
  label "cando_p_q_l3_unit_branch" = false;
  label "cando_p_q_branch" = q=0;
  label "wals" = (p=4) & (q=1);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Warning: found zero-probability in context.
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/zero-probability-only.ctx =======
  
  (* Simple test context *)
  
  p : (+) { q ! 1.0 : l1 . end }
  q : & { p ? l1 . end }
  
   ======= PRISM output ========
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..2] init 0;
  
    [] p=0 -> 1:(p'=1);
    [p_q_l1_unit] p=1 -> 1:(p'=2);
  endmodule
  
  module q
    q : [0..1] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=1);
  endmodule
  
  label "end" = (p=2) & (q=1);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_branch" = q=0;
  label "wals" = false;
  
  // Type safety
  P>=1 [ (G (("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch")) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/zero-probability-unsafe.ctx =======
  
  (* This context has a zero-probability reduction into an unsafe context. *)
  
  p : (+) { q ! 1.0 : l1 . end, q ! 0 : l2 . (+) { q ! 1.0 : l3 . end } }
  q : & { p ? l1 . end, p ? l2 . & { p ? l2 . end } }
  
   ======= PRISM output ========
  
  Warning: found zero-probability in context.
  
  
  module closure
    closure : bool init false;
  
    [] false -> 1:(closure'=false);
    [p_q_l3_unit] false -> 1:(closure'=false);
  endmodule
  
  module p
    p : [0..5] init 0;
  
    [] p=0 -> 1:(p'=1) + 0:(p'=2);
    [p_q_l1_unit] p=1 -> 1:(p'=5);
    [p_q_l2_unit] p=2 -> 1:(p'=3);
    [] p=3 -> 1:(p'=4);
    [p_q_l3_unit] p=4 -> 1:(p'=5);
  endmodule
  
  module q
    q : [0..2] init 0;
  
    [p_q_l1_unit] q=0 -> 1:(q'=2);
    [p_q_l2_unit] q=0 -> 1:(q'=1);
    [p_q_l2_unit] q=1 -> 1:(q'=2);
  endmodule
  
  label "end" = (p=5) & (q=2);
  label "cando_p_q_l1_unit" = p=0;
  label "cando_p_q_l1_unit_branch" = q=0;
  label "cando_p_q_l2_unit" = p=0;
  label "cando_p_q_l2_unit_branch" = (q=0) | (q=1);
  label "cando_p_q_l3_unit" = p=3;
  label "cando_p_q_l3_unit_branch" = false;
  label "cando_p_q_branch" = (q=0) | (q=1);
  label "wals" = (p=4) & (q=1);
  
  // Type safety
  P>=1 [ (G ((("cando_p_q_l1_unit" & "cando_p_q_branch") => "cando_p_q_l1_unit_branch") & ((("cando_p_q_l2_unit" & "cando_p_q_branch") => "cando_p_q_l2_unit_branch") & (("cando_p_q_l3_unit" & "cando_p_q_branch") => "cando_p_q_l3_unit_branch")))) ]
  
  // Deadlock freedom (lower bound)
  Pmin=? [ (G ("deadlock" => "end")) ]
  
  // Liveness (lower bound)
  Pmin=? [ (G (!"wals")) ]
  
   ======= Property checking =======
  
  Warning: found zero-probability in context.
  
  Type safety
  Result: true
  
  Deadlock freedom (lower bound)
  Result: 1.0 (exact floating point)
  
  Liveness (lower bound)
  Result: 1.0 (exact floating point)
  
  

