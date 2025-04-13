For each context file in this directory, run [prose output] to check the model and properties output, then run [prose verify] to verify the properties using PRISM.

  $ for i in ../examples/*.ctx; do echo "\n\n ======= TEST $i =======\n"; cat "$i"; echo "\n ======= PRISM output ========\n"; prose output "$i"; echo "\n ======= Property checking =======\n"; prose verify "$i"; echo "\n"; done
  
  
   ======= TEST ../examples/auth.ctx =======
  
  (* Running example from the paper *)
  
  s : b & {
        connect . c (+) {
                   0.1 : login . a & authorise . end,
                   0.3 : cancel . e (+) terminate . end
                 },
        networkerror . mu t . b & retry . t
      }
  
  c : s & {
        login . a (+) pass . end,
        cancel . a (+) quit . end
      }
  
  a : c & {
        pass . a (+) authorise . end,
        quit . end
      }
  
  b : s (+) {
        0.6 : connect . end,
        0.4 : networkerror . mu t . s (+) retry . t
      }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [a_e] false -> 1:(closure'=false);
    [e_a] false -> 1:(closure'=false);
    [b_e] false -> 1:(closure'=false);
    [e_b] false -> 1:(closure'=false);
    [c_e] false -> 1:(closure'=false);
    [e_c] false -> 1:(closure'=false);
    [s_e] false -> 1:(closure'=false);
    [e_s] false -> 1:(closure'=false);
    [s_a] false -> 1:(closure'=false);
    [a_s] false -> 1:(closure'=false);
  endmodule
  
  module s
    s : [0..12] init 0;
    s_c_label : [0..2] init 0;
    s_e_label : [0..1] init 0;
  
    [] s=12 -> 1:(fail'=true);
    [b_s] (s=0) & (fail=false) -> 1:(s'=1);
    [b_s_retry] false -> 1:(s'=1);
    [b_s_networkerror] (s=1) & (b_s_label=2) -> 1:(s'=2);
    [b_s_connect] (s=1) & (b_s_label=3) -> 1:(s'=4);
    [s_c] (s=4) & (fail=false) -> 0.6:(s'=12) + 0.1:(s'=5)&(s_c_label'=1) + 0.3:(s'=6)&(s_c_label'=2);
    [s_c_login] s=5 -> 1:(s'=7)&(s_c_label'=0);
    [s_c_cancel] s=6 -> 1:(s'=9)&(s_c_label'=0);
    [a_s] (s=7) & (fail=false) -> 1:(s'=8);
    [a_s_authorise] (s=8) & (a_s_label=1) -> 1:(s'=11);
    [s_e] (s=9) & (fail=false) -> 0:(s'=12) + 1:(s'=10)&(s_e_label'=1);
    [s_e_terminate] s=10 -> 1:(s'=11)&(s_e_label'=0);
    [b_s] (s=2) & (fail=false) -> 1:(s'=3);
    [b_s_retry] (s=3) & (b_s_label=1) -> 1:(s'=2);
    [b_s_networkerror] false -> 1:(s'=3);
    [b_s_connect] false -> 1:(s'=3);
  endmodule
  
  module c
    c : [0..7] init 0;
    c_a_label : [0..2] init 0;
  
    [] c=7 -> 1:(fail'=true);
    [s_c] (c=0) & (fail=false) -> 1:(c'=1);
    [s_c_login] (c=1) & (s_c_label=1) -> 1:(c'=2);
    [s_c_cancel] (c=1) & (s_c_label=2) -> 1:(c'=4);
    [c_a] (c=2) & (fail=false) -> 0:(c'=7) + 1:(c'=3)&(c_a_label'=2);
    [c_a_pass] c=3 -> 1:(c'=6)&(c_a_label'=0);
    [c_a] (c=4) & (fail=false) -> 0:(c'=7) + 1:(c'=5)&(c_a_label'=1);
    [c_a_quit] c=5 -> 1:(c'=6)&(c_a_label'=0);
  endmodule
  
  module a
    a : [0..5] init 0;
    a_a_label : [0..1] init 0;
    a_s_label : [0..1] init 0;
  
    [] a=5 -> 1:(fail'=true);
    [c_a] (a=0) & (fail=false) -> 1:(a'=1);
    [c_a_quit] (a=1) & (c_a_label=1) -> 1:(a'=4);
    [c_a_pass] (a=1) & (c_a_label=2) -> 1:(a'=2);
    [a_a] (a=2) & (fail=false) -> 0:(a'=5) + 1:(a'=3)&(a_a_label'=1);
    [a_a_authorise] a=3 -> 1:(a'=4)&(a_a_label'=0);
  endmodule
  
  module b
    b : [0..6] init 0;
    b_s_label : [0..3] init 0;
  
    [] b=6 -> 1:(fail'=true);
    [b_s] (b=0) & (fail=false) -> 0:(b'=6) + 0.4:(b'=1)&(b_s_label'=2) + 0.6:(b'=2)&(b_s_label'=3);
    [b_s_networkerror] b=1 -> 1:(b'=3)&(b_s_label'=0);
    [b_s_connect] b=2 -> 1:(b'=5)&(b_s_label'=0);
    [b_s] (b=3) & (fail=false) -> 0:(b'=6) + 1:(b'=4)&(b_s_label'=1);
    [b_s_retry] b=4 -> 1:(b'=3)&(b_s_label'=0);
  endmodule
  
  label "end" = (s=11) & (c=6) & (a=4) & (b=5);
  label "cando_a_a_authorise" = a=2;
  label "cando_a_a_authorise_branch" = false;
  label "cando_a_s_authorise" = false;
  label "cando_a_s_authorise_branch" = s=7;
  label "cando_b_s_connect" = b=0;
  label "cando_b_s_connect_branch" = s=0;
  label "cando_b_s_networkerror" = b=0;
  label "cando_b_s_networkerror_branch" = s=0;
  label "cando_b_s_retry" = b=3;
  label "cando_b_s_retry_branch" = s=2;
  label "cando_c_a_pass" = c=2;
  label "cando_c_a_pass_branch" = a=0;
  label "cando_c_a_quit" = c=4;
  label "cando_c_a_quit_branch" = a=0;
  label "cando_s_c_cancel" = s=4;
  label "cando_s_c_cancel_branch" = c=0;
  label "cando_s_c_login" = s=4;
  label "cando_s_c_login_branch" = c=0;
  label "cando_s_e_terminate" = s=9;
  label "cando_s_e_terminate_branch" = false;
  label "cando_a_a_branch" = false;
  label "cando_a_s_branch" = s=7;
  label "cando_b_s_branch" = (s=0) | (s=2);
  label "cando_c_a_branch" = a=0;
  label "cando_s_c_branch" = c=0;
  label "cando_s_e_branch" = false;
  P>=1 [ (G ((("cando_a_a_authorise" & "cando_a_a_branch") => "cando_a_a_authorise_branch") & ((("cando_a_s_authorise" & "cando_a_s_branch") => "cando_a_s_authorise_branch") & ((("cando_b_s_connect" & "cando_b_s_branch") => "cando_b_s_connect_branch") & ((("cando_b_s_networkerror" & "cando_b_s_branch") => "cando_b_s_networkerror_branch") & ((("cando_b_s_retry" & "cando_b_s_branch") => "cando_b_s_retry_branch") & ((("cando_c_a_pass" & "cando_c_a_branch") => "cando_c_a_pass_branch") & ((("cando_c_a_quit" & "cando_c_a_branch") => "cando_c_a_quit_branch") & ((("cando_s_c_cancel" & "cando_s_c_branch") => "cando_s_c_cancel_branch") & ((("cando_s_c_login" & "cando_s_c_branch") => "cando_s_c_login_branch") & (("cando_s_e_terminate" & "cando_s_e_branch") => "cando_s_e_terminate_branch"))))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.4 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.625
  
  Probabilistic termination
  Result: 0.6 (exact floating point)
  
  
  
  
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
    p0_q0_label : [0..2] init 0;
  
    [] p0=4 -> 1:(fail'=true);
    [p0_q0] (p0=0) & (fail=false) -> 0:(p0'=4) + 0.5:(p0'=1)&(p0_q0_label'=1) + 0.5:(p0'=2)&(p0_q0_label'=2);
    [p0_q0_l2] p0=1 -> 1:(p0'=3)&(p0_q0_label'=0);
    [p0_q0_l1] p0=2 -> 1:(p0'=3)&(p0_q0_label'=0);
  endmodule
  
  module q0
    q0 : [0..11] init 0;
    q0_p1_label : [0..1] init 0;
    q0_p2_label : [0..1] init 0;
  
    [] q0=11 -> 1:(fail'=true);
    [p0_q0] (q0=0) & (fail=false) -> 1:(q0'=1);
    [p0_q0_l2] (q0=1) & (p0_q0_label=1) -> 1:(q0'=2);
    [p0_q0_l1] (q0=1) & (p0_q0_label=2) -> 1:(q0'=6);
    [q0_p1] (q0=6) & (fail=false) -> 0:(q0'=11) + 1:(q0'=7)&(q0_p1_label'=1);
    [q0_p1_go] q0=7 -> 1:(q0'=8)&(q0_p1_label'=0);
    [q3_q0] (q0=8) & (fail=false) -> 1:(q0'=9);
    [q3_q0_redo] (q0=9) & (q3_q0_label=1) -> 1:(q0'=6);
    [q0_p2] (q0=2) & (fail=false) -> 0:(q0'=11) + 1:(q0'=3)&(q0_p2_label'=1);
    [q0_p2_go] q0=3 -> 1:(q0'=4)&(q0_p2_label'=0);
    [q6_q0] (q0=4) & (fail=false) -> 1:(q0'=5);
    [q6_q0_redo] (q0=5) & (q6_q0_label=1) -> 1:(q0'=2);
  endmodule
  
  module p1
    p1 : [0..6] init 0;
    p1_q1_label : [0..2] init 0;
  
    [] p1=6 -> 1:(fail'=true);
    [q0_p1] (p1=0) & (fail=false) -> 1:(p1'=1);
    [q0_p1_go] (p1=1) & (q0_p1_label=1) -> 1:(p1'=2);
    [p1_q1] (p1=2) & (fail=false) -> 0:(p1'=6) + 0.5:(p1'=3)&(p1_q1_label'=1) + 0.5:(p1'=4)&(p1_q1_label'=2);
    [p1_q1_l4] p1=3 -> 1:(p1'=0)&(p1_q1_label'=0);
    [p1_q1_l3] p1=4 -> 1:(p1'=0)&(p1_q1_label'=0);
  endmodule
  
  module q1
    q1 : [0..7] init 0;
    q1_p3_label : [0..1] init 0;
    q1_p4_label : [0..1] init 0;
  
    [] q1=7 -> 1:(fail'=true);
    [p1_q1] (q1=0) & (fail=false) -> 1:(q1'=1);
    [p1_q1_l4] (q1=1) & (p1_q1_label=1) -> 1:(q1'=2);
    [p1_q1_l3] (q1=1) & (p1_q1_label=2) -> 1:(q1'=4);
    [q1_p3] (q1=4) & (fail=false) -> 0:(q1'=7) + 1:(q1'=5)&(q1_p3_label'=1);
    [q1_p3_go] q1=5 -> 1:(q1'=0)&(q1_p3_label'=0);
    [q1_p4] (q1=2) & (fail=false) -> 0:(q1'=7) + 1:(q1'=3)&(q1_p4_label'=1);
    [q1_p4_go] q1=3 -> 1:(q1'=0)&(q1_p4_label'=0);
  endmodule
  
  module p2
    p2 : [0..6] init 0;
    p2_q2_label : [0..2] init 0;
  
    [] p2=6 -> 1:(fail'=true);
    [q0_p2] (p2=0) & (fail=false) -> 1:(p2'=1);
    [q0_p2_go] (p2=1) & (q0_p2_label=1) -> 1:(p2'=2);
    [p2_q2] (p2=2) & (fail=false) -> 0:(p2'=6) + 0.5:(p2'=3)&(p2_q2_label'=1) + 0.5:(p2'=4)&(p2_q2_label'=2);
    [p2_q2_l6] p2=3 -> 1:(p2'=0)&(p2_q2_label'=0);
    [p2_q2_l5] p2=4 -> 1:(p2'=0)&(p2_q2_label'=0);
  endmodule
  
  module q2
    q2 : [0..7] init 0;
    q2_p5_label : [0..1] init 0;
    q2_p6_label : [0..1] init 0;
  
    [] q2=7 -> 1:(fail'=true);
    [p2_q2] (q2=0) & (fail=false) -> 1:(q2'=1);
    [p2_q2_l6] (q2=1) & (p2_q2_label=1) -> 1:(q2'=2);
    [p2_q2_l5] (q2=1) & (p2_q2_label=2) -> 1:(q2'=4);
    [q2_p5] (q2=4) & (fail=false) -> 0:(q2'=7) + 1:(q2'=5)&(q2_p5_label'=1);
    [q2_p5_go] q2=5 -> 1:(q2'=0)&(q2_p5_label'=0);
    [q2_p6] (q2=2) & (fail=false) -> 0:(q2'=7) + 1:(q2'=3)&(q2_p6_label'=1);
    [q2_p6_go] q2=3 -> 1:(q2'=0)&(q2_p6_label'=0);
  endmodule
  
  module p3
    p3 : [0..6] init 0;
    p3_q3_label : [0..2] init 0;
  
    [] p3=6 -> 1:(fail'=true);
    [q1_p3] (p3=0) & (fail=false) -> 1:(p3'=1);
    [q1_p3_go] (p3=1) & (q1_p3_label=1) -> 1:(p3'=2);
    [p3_q3] (p3=2) & (fail=false) -> 0:(p3'=6) + 0.5:(p3'=3)&(p3_q3_label'=1) + 0.5:(p3'=4)&(p3_q3_label'=2);
    [p3_q3_l1] p3=3 -> 1:(p3'=0)&(p3_q3_label'=0);
    [p3_q3_d1] p3=4 -> 1:(p3'=5)&(p3_q3_label'=0);
  endmodule
  
  module q3
    q3 : [0..7] init 0;
    q3_dice1_label : [0..1] init 0;
    q3_q0_label : [0..1] init 0;
  
    [] q3=7 -> 1:(fail'=true);
    [p3_q3] (q3=0) & (fail=false) -> 1:(q3'=1);
    [p3_q3_l1] (q3=1) & (p3_q3_label=1) -> 1:(q3'=2);
    [p3_q3_d1] (q3=1) & (p3_q3_label=2) -> 1:(q3'=4);
    [q3_q0] (q3=2) & (fail=false) -> 0:(q3'=7) + 1:(q3'=3)&(q3_q0_label'=1);
    [q3_q0_redo] q3=3 -> 1:(q3'=0)&(q3_q0_label'=0);
    [q3_dice1] (q3=4) & (fail=false) -> 0:(q3'=7) + 1:(q3'=5)&(q3_dice1_label'=1);
    [q3_dice1_done] q3=5 -> 1:(q3'=6)&(q3_dice1_label'=0);
  endmodule
  
  module p4
    p4 : [0..6] init 0;
    p4_q4_label : [0..2] init 0;
  
    [] p4=6 -> 1:(fail'=true);
    [q1_p4] (p4=0) & (fail=false) -> 1:(p4'=1);
    [q1_p4_go] (p4=1) & (q1_p4_label=1) -> 1:(p4'=2);
    [p4_q4] (p4=2) & (fail=false) -> 0:(p4'=6) + 0.5:(p4'=3)&(p4_q4_label'=1) + 0.5:(p4'=4)&(p4_q4_label'=2);
    [p4_q4_d3] p4=3 -> 1:(p4'=5)&(p4_q4_label'=0);
    [p4_q4_d2] p4=4 -> 1:(p4'=5)&(p4_q4_label'=0);
  endmodule
  
  module q4
    q4 : [0..7] init 0;
    q4_dice2_label : [0..1] init 0;
    q4_dice3_label : [0..1] init 0;
  
    [] q4=7 -> 1:(fail'=true);
    [p4_q4] (q4=0) & (fail=false) -> 1:(q4'=1);
    [p4_q4_d3] (q4=1) & (p4_q4_label=1) -> 1:(q4'=2);
    [p4_q4_d2] (q4=1) & (p4_q4_label=2) -> 1:(q4'=4);
    [q4_dice2] (q4=4) & (fail=false) -> 0:(q4'=7) + 1:(q4'=5)&(q4_dice2_label'=1);
    [q4_dice2_done] q4=5 -> 1:(q4'=6)&(q4_dice2_label'=0);
    [q4_dice3] (q4=2) & (fail=false) -> 0:(q4'=7) + 1:(q4'=3)&(q4_dice3_label'=1);
    [q4_dice3_done] q4=3 -> 1:(q4'=6)&(q4_dice3_label'=0);
  endmodule
  
  module p5
    p5 : [0..6] init 0;
    p5_q5_label : [0..2] init 0;
  
    [] p5=6 -> 1:(fail'=true);
    [q2_p5] (p5=0) & (fail=false) -> 1:(p5'=1);
    [q2_p5_go] (p5=1) & (q2_p5_label=1) -> 1:(p5'=2);
    [p5_q5] (p5=2) & (fail=false) -> 0:(p5'=6) + 0.5:(p5'=3)&(p5_q5_label'=1) + 0.5:(p5'=4)&(p5_q5_label'=2);
    [p5_q5_d5] p5=3 -> 1:(p5'=5)&(p5_q5_label'=0);
    [p5_q5_d4] p5=4 -> 1:(p5'=5)&(p5_q5_label'=0);
  endmodule
  
  module q5
    q5 : [0..7] init 0;
    q5_dice4_label : [0..1] init 0;
    q5_dice5_label : [0..1] init 0;
  
    [] q5=7 -> 1:(fail'=true);
    [p5_q5] (q5=0) & (fail=false) -> 1:(q5'=1);
    [p5_q5_d5] (q5=1) & (p5_q5_label=1) -> 1:(q5'=2);
    [p5_q5_d4] (q5=1) & (p5_q5_label=2) -> 1:(q5'=4);
    [q5_dice4] (q5=4) & (fail=false) -> 0:(q5'=7) + 1:(q5'=5)&(q5_dice4_label'=1);
    [q5_dice4_done] q5=5 -> 1:(q5'=6)&(q5_dice4_label'=0);
    [q5_dice5] (q5=2) & (fail=false) -> 0:(q5'=7) + 1:(q5'=3)&(q5_dice5_label'=1);
    [q5_dice5_done] q5=3 -> 1:(q5'=6)&(q5_dice5_label'=0);
  endmodule
  
  module p6
    p6 : [0..6] init 0;
    p6_q6_label : [0..2] init 0;
  
    [] p6=6 -> 1:(fail'=true);
    [q2_p6] (p6=0) & (fail=false) -> 1:(p6'=1);
    [q2_p6_go] (p6=1) & (q2_p6_label=1) -> 1:(p6'=2);
    [p6_q6] (p6=2) & (fail=false) -> 0:(p6'=6) + 0.5:(p6'=3)&(p6_q6_label'=1) + 0.5:(p6'=4)&(p6_q6_label'=2);
    [p6_q6_l2] p6=3 -> 1:(p6'=5)&(p6_q6_label'=0);
    [p6_q6_d6] p6=4 -> 1:(p6'=5)&(p6_q6_label'=0);
  endmodule
  
  module q6
    q6 : [0..7] init 0;
    q6_dice6_label : [0..1] init 0;
    q6_q0_label : [0..1] init 0;
  
    [] q6=7 -> 1:(fail'=true);
    [p6_q6] (q6=0) & (fail=false) -> 1:(q6'=1);
    [p6_q6_l2] (q6=1) & (p6_q6_label=1) -> 1:(q6'=2);
    [p6_q6_d6] (q6=1) & (p6_q6_label=2) -> 1:(q6'=4);
    [q6_dice6] (q6=4) & (fail=false) -> 0:(q6'=7) + 1:(q6'=5)&(q6_dice6_label'=1);
    [q6_dice6_done] q6=5 -> 1:(q6'=6)&(q6_dice6_label'=0);
    [q6_q0] (q6=2) & (fail=false) -> 0:(q6'=7) + 1:(q6'=3)&(q6_q0_label'=1);
    [q6_q0_redo] q6=3 -> 1:(q6'=0)&(q6_q0_label'=0);
  endmodule
  
  module dice1
    dice1 : [0..5] init 0;
    dice1_dummy_label : [0..1] init 0;
  
    [] dice1=5 -> 1:(fail'=true);
    [q3_dice1] (dice1=0) & (fail=false) -> 1:(dice1'=1);
    [q3_dice1_done] (dice1=1) & (q3_dice1_label=1) -> 1:(dice1'=2);
    [dice1_dummy] (dice1=2) & (fail=false) -> 0:(dice1'=5) + 1:(dice1'=3)&(dice1_dummy_label'=1);
    [dice1_dummy_repeat] dice1=3 -> 1:(dice1'=2)&(dice1_dummy_label'=0);
  endmodule
  
  module dice2
    dice2 : [0..3] init 0;
  
    [] dice2=3 -> 1:(fail'=true);
    [q4_dice2] (dice2=0) & (fail=false) -> 1:(dice2'=1);
    [q4_dice2_done] (dice2=1) & (q4_dice2_label=1) -> 1:(dice2'=2);
  endmodule
  
  module dice3
    dice3 : [0..3] init 0;
  
    [] dice3=3 -> 1:(fail'=true);
    [q4_dice3] (dice3=0) & (fail=false) -> 1:(dice3'=1);
    [q4_dice3_done] (dice3=1) & (q4_dice3_label=1) -> 1:(dice3'=2);
  endmodule
  
  module dice4
    dice4 : [0..3] init 0;
  
    [] dice4=3 -> 1:(fail'=true);
    [q5_dice4] (dice4=0) & (fail=false) -> 1:(dice4'=1);
    [q5_dice4_done] (dice4=1) & (q5_dice4_label=1) -> 1:(dice4'=2);
  endmodule
  
  module dice5
    dice5 : [0..3] init 0;
  
    [] dice5=3 -> 1:(fail'=true);
    [q5_dice5] (dice5=0) & (fail=false) -> 1:(dice5'=1);
    [q5_dice5_done] (dice5=1) & (q5_dice5_label=1) -> 1:(dice5'=2);
  endmodule
  
  module dice6
    dice6 : [0..3] init 0;
  
    [] dice6=3 -> 1:(fail'=true);
    [q6_dice6] (dice6=0) & (fail=false) -> 1:(dice6'=1);
    [q6_dice6_done] (dice6=1) & (q6_dice6_label=1) -> 1:(dice6'=2);
  endmodule
  
  module dummy
    dummy : [0..3] init 0;
  
    [] dummy=3 -> 1:(fail'=true);
    [dice1_dummy] (dummy=0) & (fail=false) -> 1:(dummy'=1);
    [dice1_dummy_repeat] (dummy=1) & (dice1_dummy_label=1) -> 1:(dummy'=0);
  endmodule
  
  label "end" = (p0=3) & (q0=10) & (p1=5) & (q1=6) & (p2=5) & (q2=6) & (p3=5) & (q3=6) & (p4=5) & (q4=6) & (p5=5) & (q5=6) & (p6=5) & (q6=6) & (dice1=4) & (dice2=2) & (dice3=2) & (dice4=2) & (dice5=2) & (dice6=2) & (dummy=2);
  label "cando_dice1_dummy_repeat" = dice1=2;
  label "cando_dice1_dummy_repeat_branch" = dummy=0;
  label "cando_p0_q0_l1" = p0=0;
  label "cando_p0_q0_l1_branch" = q0=0;
  label "cando_p0_q0_l2" = p0=0;
  label "cando_p0_q0_l2_branch" = q0=0;
  label "cando_p1_q1_l3" = p1=2;
  label "cando_p1_q1_l3_branch" = q1=0;
  label "cando_p1_q1_l4" = p1=2;
  label "cando_p1_q1_l4_branch" = q1=0;
  label "cando_p2_q2_l5" = p2=2;
  label "cando_p2_q2_l5_branch" = q2=0;
  label "cando_p2_q2_l6" = p2=2;
  label "cando_p2_q2_l6_branch" = q2=0;
  label "cando_p3_q3_d1" = p3=2;
  label "cando_p3_q3_d1_branch" = q3=0;
  label "cando_p3_q3_l1" = p3=2;
  label "cando_p3_q3_l1_branch" = q3=0;
  label "cando_p4_q4_d2" = p4=2;
  label "cando_p4_q4_d2_branch" = q4=0;
  label "cando_p4_q4_d3" = p4=2;
  label "cando_p4_q4_d3_branch" = q4=0;
  label "cando_p5_q5_d4" = p5=2;
  label "cando_p5_q5_d4_branch" = q5=0;
  label "cando_p5_q5_d5" = p5=2;
  label "cando_p5_q5_d5_branch" = q5=0;
  label "cando_p6_q6_d6" = p6=2;
  label "cando_p6_q6_d6_branch" = q6=0;
  label "cando_p6_q6_l2" = p6=2;
  label "cando_p6_q6_l2_branch" = q6=0;
  label "cando_q0_p1_go" = q0=6;
  label "cando_q0_p1_go_branch" = p1=0;
  label "cando_q0_p2_go" = q0=2;
  label "cando_q0_p2_go_branch" = p2=0;
  label "cando_q1_p3_go" = q1=4;
  label "cando_q1_p3_go_branch" = p3=0;
  label "cando_q1_p4_go" = q1=2;
  label "cando_q1_p4_go_branch" = p4=0;
  label "cando_q2_p5_go" = q2=4;
  label "cando_q2_p5_go_branch" = p5=0;
  label "cando_q2_p6_go" = q2=2;
  label "cando_q2_p6_go_branch" = p6=0;
  label "cando_q3_dice1_done" = q3=4;
  label "cando_q3_dice1_done_branch" = dice1=0;
  label "cando_q3_q0_redo" = q3=2;
  label "cando_q3_q0_redo_branch" = q0=8;
  label "cando_q4_dice2_done" = q4=4;
  label "cando_q4_dice2_done_branch" = dice2=0;
  label "cando_q4_dice3_done" = q4=2;
  label "cando_q4_dice3_done_branch" = dice3=0;
  label "cando_q5_dice4_done" = q5=4;
  label "cando_q5_dice4_done_branch" = dice4=0;
  label "cando_q5_dice5_done" = q5=2;
  label "cando_q5_dice5_done_branch" = dice5=0;
  label "cando_q6_dice6_done" = q6=4;
  label "cando_q6_dice6_done_branch" = dice6=0;
  label "cando_q6_q0_redo" = q6=2;
  label "cando_q6_q0_redo_branch" = q0=4;
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
  P>=1 [ (G ((("cando_dice1_dummy_repeat" & "cando_dice1_dummy_branch") => "cando_dice1_dummy_repeat_branch") & ((("cando_p0_q0_l1" & "cando_p0_q0_branch") => "cando_p0_q0_l1_branch") & ((("cando_p0_q0_l2" & "cando_p0_q0_branch") => "cando_p0_q0_l2_branch") & ((("cando_p1_q1_l3" & "cando_p1_q1_branch") => "cando_p1_q1_l3_branch") & ((("cando_p1_q1_l4" & "cando_p1_q1_branch") => "cando_p1_q1_l4_branch") & ((("cando_p2_q2_l5" & "cando_p2_q2_branch") => "cando_p2_q2_l5_branch") & ((("cando_p2_q2_l6" & "cando_p2_q2_branch") => "cando_p2_q2_l6_branch") & ((("cando_p3_q3_d1" & "cando_p3_q3_branch") => "cando_p3_q3_d1_branch") & ((("cando_p3_q3_l1" & "cando_p3_q3_branch") => "cando_p3_q3_l1_branch") & ((("cando_p4_q4_d2" & "cando_p4_q4_branch") => "cando_p4_q4_d2_branch") & ((("cando_p4_q4_d3" & "cando_p4_q4_branch") => "cando_p4_q4_d3_branch") & ((("cando_p5_q5_d4" & "cando_p5_q5_branch") => "cando_p5_q5_d4_branch") & ((("cando_p5_q5_d5" & "cando_p5_q5_branch") => "cando_p5_q5_d5_branch") & ((("cando_p6_q6_d6" & "cando_p6_q6_branch") => "cando_p6_q6_d6_branch") & ((("cando_p6_q6_l2" & "cando_p6_q6_branch") => "cando_p6_q6_l2_branch") & ((("cando_q0_p1_go" & "cando_q0_p1_branch") => "cando_q0_p1_go_branch") & ((("cando_q0_p2_go" & "cando_q0_p2_branch") => "cando_q0_p2_go_branch") & ((("cando_q1_p3_go" & "cando_q1_p3_branch") => "cando_q1_p3_go_branch") & ((("cando_q1_p4_go" & "cando_q1_p4_branch") => "cando_q1_p4_go_branch") & ((("cando_q2_p5_go" & "cando_q2_p5_branch") => "cando_q2_p5_go_branch") & ((("cando_q2_p6_go" & "cando_q2_p6_branch") => "cando_q2_p6_go_branch") & ((("cando_q3_dice1_done" & "cando_q3_dice1_branch") => "cando_q3_dice1_done_branch") & ((("cando_q3_q0_redo" & "cando_q3_q0_branch") => "cando_q3_q0_redo_branch") & ((("cando_q4_dice2_done" & "cando_q4_dice2_branch") => "cando_q4_dice2_done_branch") & ((("cando_q4_dice3_done" & "cando_q4_dice3_branch") => "cando_q4_dice3_done_branch") & ((("cando_q5_dice4_done" & "cando_q5_dice4_branch") => "cando_q5_dice4_done_branch") & ((("cando_q5_dice5_done" & "cando_q5_dice5_branch") => "cando_q5_dice5_done_branch") & ((("cando_q6_dice6_done" & "cando_q6_dice6_branch") => "cando_q6_dice6_done_branch") & (("cando_q6_q0_redo" & "cando_q6_q0_branch") => "cando_q6_q0_redo_branch")))))))))))))))))))))))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.16666698455810547 (+/- 1.1920963061161968E-6 estimated; rel err 7.1525641942636435E-6)
  
  Normalised probabilistic deadlock freedom
  Result: 0.16666698455810547
  
  Probabilistic termination
  Result: 0.8333330154418945 (+/- 5.960467888147447E-6 estimated; rel err 7.1525641942636435E-6)
  
  
  
  
   ======= TEST ../examples/monty-hall-change.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always switches doors
     to either 2 or 3, depending on whichever door the host opens.
  
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-stay.ctx]. *)
  
  car : host (+) {
          0.333333 : l1 . end,
          0.333333 : l2 . end,
          0.333333 : l3 . end
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
  
  endmodule
  
  module car
    car : [0..5] init 0;
    car_host_label : [0..3] init 0;
  
    [] car=5 -> 1:(fail'=true);
    [car_host] (car=0) & (fail=false) -> 1e-06:(car'=5) + 0.333333:(car'=1)&(car_host_label'=1) + 0.333333:(car'=2)&(car_host_label'=2) + 0.333333:(car'=3)&(car_host_label'=3);
    [car_host_l3] car=1 -> 1:(car'=4)&(car_host_label'=0);
    [car_host_l2] car=2 -> 1:(car'=4)&(car_host_label'=0);
    [car_host_l1] car=3 -> 1:(car'=4)&(car_host_label'=0);
  endmodule
  
  module host
    host : [0..18] init 0;
    host_player_label : [0..2] init 0;
  
    [] host=18 -> 1:(fail'=true);
    [car_host] (host=0) & (fail=false) -> 1:(host'=1);
    [car_host_l3] (host=1) & (car_host_label=1) -> 1:(host'=2);
    [car_host_l2] (host=1) & (car_host_label=2) -> 1:(host'=6);
    [car_host_l1] (host=1) & (car_host_label=3) -> 1:(host'=10);
    [host_player] (host=10) & (fail=false) -> 0:(host'=18) + 0.5:(host'=11)&(host_player_label'=1) + 0.5:(host'=12)&(host_player_label'=2);
    [host_player_l3] host=11 -> 1:(host'=13)&(host_player_label'=0);
    [host_player_l2] host=12 -> 1:(host'=15)&(host_player_label'=0);
    [player_host] (host=13) & (fail=false) -> 1:(host'=14);
    [player_host_l3] false -> 1:(host'=14);
    [player_host_l2] false -> 1:(host'=14);
    [player_host_l1] (host=14) & (player_host_label=3) -> 1:(host'=17);
    [player_host] (host=15) & (fail=false) -> 1:(host'=16);
    [player_host_l3] false -> 1:(host'=16);
    [player_host_l2] false -> 1:(host'=16);
    [player_host_l1] (host=16) & (player_host_label=3) -> 1:(host'=17);
    [host_player] (host=6) & (fail=false) -> 0:(host'=18) + 1:(host'=7)&(host_player_label'=1);
    [host_player_l3] host=7 -> 1:(host'=8)&(host_player_label'=0);
    [player_host] (host=8) & (fail=false) -> 1:(host'=9);
    [player_host_l3] false -> 1:(host'=9);
    [player_host_l2] (host=9) & (player_host_label=2) -> 1:(host'=17);
    [player_host_l1] false -> 1:(host'=9);
    [host_player] (host=2) & (fail=false) -> 0:(host'=18) + 1:(host'=3)&(host_player_label'=2);
    [host_player_l2] host=3 -> 1:(host'=4)&(host_player_label'=0);
    [player_host] (host=4) & (fail=false) -> 1:(host'=5);
    [player_host_l3] (host=5) & (player_host_label=1) -> 1:(host'=17);
    [player_host_l2] false -> 1:(host'=5);
    [player_host_l1] false -> 1:(host'=5);
  endmodule
  
  module player
    player : [0..7] init 0;
    player_host_label : [0..3] init 0;
  
    [] player=7 -> 1:(fail'=true);
    [host_player] (player=0) & (fail=false) -> 1:(player'=1);
    [host_player_l3] (player=1) & (host_player_label=1) -> 1:(player'=2);
    [host_player_l2] (player=1) & (host_player_label=2) -> 1:(player'=4);
    [player_host] (player=4) & (fail=false) -> 0:(player'=7) + 1:(player'=5)&(player_host_label'=1);
    [player_host_l3] player=5 -> 1:(player'=6)&(player_host_label'=0);
    [player_host] (player=2) & (fail=false) -> 0:(player'=7) + 1:(player'=3)&(player_host_label'=2);
    [player_host_l2] player=3 -> 1:(player'=6)&(player_host_label'=0);
  endmodule
  
  label "end" = (car=4) & (host=17) & (player=6);
  label "cando_car_host_l1" = car=0;
  label "cando_car_host_l1_branch" = host=0;
  label "cando_car_host_l2" = car=0;
  label "cando_car_host_l2_branch" = host=0;
  label "cando_car_host_l3" = car=0;
  label "cando_car_host_l3_branch" = host=0;
  label "cando_host_player_l2" = (host=2) | (host=10);
  label "cando_host_player_l2_branch" = player=0;
  label "cando_host_player_l3" = (host=6) | (host=10);
  label "cando_host_player_l3_branch" = player=0;
  label "cando_player_host_l1" = false;
  label "cando_player_host_l1_branch" = (host=13) | (host=15);
  label "cando_player_host_l2" = player=2;
  label "cando_player_host_l2_branch" = host=8;
  label "cando_player_host_l3" = player=4;
  label "cando_player_host_l3_branch" = host=4;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=8) | (host=13) | (host=15);
  P>=1 [ (G ((("cando_car_host_l1" & "cando_car_host_branch") => "cando_car_host_l1_branch") & ((("cando_car_host_l2" & "cando_car_host_branch") => "cando_car_host_l2_branch") & ((("cando_car_host_l3" & "cando_car_host_branch") => "cando_car_host_l3_branch") & ((("cando_host_player_l2" & "cando_host_player_branch") => "cando_host_player_l2_branch") & ((("cando_host_player_l3" & "cando_host_player_branch") => "cando_host_player_l3_branch") & ((("cando_player_host_l1" & "cando_player_host_branch") => "cando_player_host_l1_branch") & ((("cando_player_host_l2" & "cando_player_host_branch") => "cando_player_host_l2_branch") & (("cando_player_host_l3" & "cando_player_host_branch") => "cando_player_host_l3_branch"))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.666666 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.6666666666666666
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/monty-hall-stay.ctx =======
  
  (* Monty Hall problem. In this variant, the contestant always picks Door 1.
     The probability of deadlock freedom corresponds with the probability of
     picking the door with the car.
  
     Compare with [monty-hall-change.ctx]. *)
  
  car : host (+) {
          0.333333 : l1 . end,
          0.333333 : l2 . end,
          0.333333 : l3 . end
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
  
  endmodule
  
  module car
    car : [0..5] init 0;
    car_host_label : [0..3] init 0;
  
    [] car=5 -> 1:(fail'=true);
    [car_host] (car=0) & (fail=false) -> 1e-06:(car'=5) + 0.333333:(car'=1)&(car_host_label'=1) + 0.333333:(car'=2)&(car_host_label'=2) + 0.333333:(car'=3)&(car_host_label'=3);
    [car_host_l3] car=1 -> 1:(car'=4)&(car_host_label'=0);
    [car_host_l2] car=2 -> 1:(car'=4)&(car_host_label'=0);
    [car_host_l1] car=3 -> 1:(car'=4)&(car_host_label'=0);
  endmodule
  
  module host
    host : [0..18] init 0;
    host_player_label : [0..2] init 0;
  
    [] host=18 -> 1:(fail'=true);
    [car_host] (host=0) & (fail=false) -> 1:(host'=1);
    [car_host_l3] (host=1) & (car_host_label=1) -> 1:(host'=2);
    [car_host_l2] (host=1) & (car_host_label=2) -> 1:(host'=6);
    [car_host_l1] (host=1) & (car_host_label=3) -> 1:(host'=10);
    [host_player] (host=10) & (fail=false) -> 0:(host'=18) + 0.5:(host'=11)&(host_player_label'=1) + 0.5:(host'=12)&(host_player_label'=2);
    [host_player_l3] host=11 -> 1:(host'=13)&(host_player_label'=0);
    [host_player_l2] host=12 -> 1:(host'=15)&(host_player_label'=0);
    [player_host] (host=13) & (fail=false) -> 1:(host'=14);
    [player_host_l3] false -> 1:(host'=14);
    [player_host_l2] false -> 1:(host'=14);
    [player_host_l1] (host=14) & (player_host_label=3) -> 1:(host'=17);
    [player_host] (host=15) & (fail=false) -> 1:(host'=16);
    [player_host_l3] false -> 1:(host'=16);
    [player_host_l2] false -> 1:(host'=16);
    [player_host_l1] (host=16) & (player_host_label=3) -> 1:(host'=17);
    [host_player] (host=6) & (fail=false) -> 0:(host'=18) + 1:(host'=7)&(host_player_label'=1);
    [host_player_l3] host=7 -> 1:(host'=8)&(host_player_label'=0);
    [player_host] (host=8) & (fail=false) -> 1:(host'=9);
    [player_host_l3] false -> 1:(host'=9);
    [player_host_l2] (host=9) & (player_host_label=2) -> 1:(host'=17);
    [player_host_l1] false -> 1:(host'=9);
    [host_player] (host=2) & (fail=false) -> 0:(host'=18) + 1:(host'=3)&(host_player_label'=2);
    [host_player_l2] host=3 -> 1:(host'=4)&(host_player_label'=0);
    [player_host] (host=4) & (fail=false) -> 1:(host'=5);
    [player_host_l3] (host=5) & (player_host_label=1) -> 1:(host'=17);
    [player_host_l2] false -> 1:(host'=5);
    [player_host_l1] false -> 1:(host'=5);
  endmodule
  
  module player
    player : [0..7] init 0;
    player_host_label : [0..3] init 0;
  
    [] player=7 -> 1:(fail'=true);
    [host_player] (player=0) & (fail=false) -> 1:(player'=1);
    [host_player_l3] (player=1) & (host_player_label=1) -> 1:(player'=2);
    [host_player_l2] (player=1) & (host_player_label=2) -> 1:(player'=4);
    [player_host] (player=4) & (fail=false) -> 0:(player'=7) + 1:(player'=5)&(player_host_label'=3);
    [player_host_l1] player=5 -> 1:(player'=6)&(player_host_label'=0);
    [player_host] (player=2) & (fail=false) -> 0:(player'=7) + 1:(player'=3)&(player_host_label'=3);
    [player_host_l1] player=3 -> 1:(player'=6)&(player_host_label'=0);
  endmodule
  
  label "end" = (car=4) & (host=17) & (player=6);
  label "cando_car_host_l1" = car=0;
  label "cando_car_host_l1_branch" = host=0;
  label "cando_car_host_l2" = car=0;
  label "cando_car_host_l2_branch" = host=0;
  label "cando_car_host_l3" = car=0;
  label "cando_car_host_l3_branch" = host=0;
  label "cando_host_player_l2" = (host=2) | (host=10);
  label "cando_host_player_l2_branch" = player=0;
  label "cando_host_player_l3" = (host=6) | (host=10);
  label "cando_host_player_l3_branch" = player=0;
  label "cando_player_host_l1" = (player=2) | (player=4);
  label "cando_player_host_l1_branch" = (host=13) | (host=15);
  label "cando_player_host_l2" = false;
  label "cando_player_host_l2_branch" = host=8;
  label "cando_player_host_l3" = false;
  label "cando_player_host_l3_branch" = host=4;
  label "cando_car_host_branch" = host=0;
  label "cando_host_player_branch" = player=0;
  label "cando_player_host_branch" = (host=4) | (host=8) | (host=13) | (host=15);
  P>=1 [ (G ((("cando_car_host_l1" & "cando_car_host_branch") => "cando_car_host_l1_branch") & ((("cando_car_host_l2" & "cando_car_host_branch") => "cando_car_host_l2_branch") & ((("cando_car_host_l3" & "cando_car_host_branch") => "cando_car_host_l3_branch") & ((("cando_host_player_l2" & "cando_host_player_branch") => "cando_host_player_l2_branch") & ((("cando_host_player_l3" & "cando_host_player_branch") => "cando_host_player_l3_branch") & ((("cando_player_host_l1" & "cando_player_host_branch") => "cando_player_host_l1_branch") & ((("cando_player_host_l2" & "cando_player_host_branch") => "cando_player_host_l2_branch") & (("cando_player_host_l3" & "cando_player_host_branch") => "cando_player_host_l3_branch"))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.333333 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.3333333333333333
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
  
  endmodule
  
  module p
    p : [0..3] init 0;
    p_q_label : [0..2] init 0;
  
    [] p=3 -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0:(p'=3) + 1:(p'=1)&(p_q_label'=2);
    [p_q_l1] p=1 -> 1:(p'=2)&(p_q_label'=0);
  endmodule
  
  module q
    q : [0..3] init 0;
  
    [] q=3 -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l2] (q=1) & (p_q_label=1) -> 1:(q'=0);
    [p_q_l1] (q=1) & (p_q_label=2) -> 1:(q'=2);
  endmodule
  
  label "end" = (p=2) & (q=2);
  label "cando_p_q_l1" = p=0;
  label "cando_p_q_l1_branch" = q=0;
  label "cando_p_q_l2" = false;
  label "cando_p_q_l2_branch" = q=0;
  label "cando_p_q_branch" = q=0;
  P>=1 [ (G ((("cando_p_q_l1" & "cando_p_q_branch") => "cando_p_q_l1_branch") & (("cando_p_q_l2" & "cando_p_q_branch") => "cando_p_q_l2_branch"))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
                 datum(Int) . workerA1 (+) result . t,
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
                 datum(Int) . workerA2 (+) result . t,
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
                 datum(Int) . workerA3 (+) result . t,
                 stop . end
               }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
  endmodule
  
  module starter
    starter : [0..7] init 0;
    starter_workerA1_label : [0..1] init 0;
    starter_workerA2_label : [0..1] init 0;
    starter_workerA3_label : [0..1] init 0;
  
    [] starter=7 -> 1:(fail'=true);
    [starter_workerA1] (starter=0) & (fail=false) -> 0:(starter'=7) + 1:(starter'=1)&(starter_workerA1_label'=1);
    [starter_workerA1_datum] starter=1 -> 1:(starter'=2)&(starter_workerA1_label'=0);
    [starter_workerA2] (starter=2) & (fail=false) -> 0:(starter'=7) + 1:(starter'=3)&(starter_workerA2_label'=1);
    [starter_workerA2_datum] starter=3 -> 1:(starter'=4)&(starter_workerA2_label'=0);
    [starter_workerA3] (starter=4) & (fail=false) -> 0:(starter'=7) + 1:(starter'=5)&(starter_workerA3_label'=1);
    [starter_workerA3_datum] starter=5 -> 1:(starter'=6)&(starter_workerA3_label'=0);
  endmodule
  
  module workerA1
    workerA1 : [0..8] init 0;
    workerA1_workerB1_label : [0..2] init 0;
  
    [] workerA1=8 -> 1:(fail'=true);
    [starter_workerA1] (workerA1=0) & (fail=false) -> 1:(workerA1'=1);
    [starter_workerA1_datum] (workerA1=1) & (starter_workerA1_label=1) -> 1:(workerA1'=2);
    [workerA1_workerB1] (workerA1=2) & (fail=false) -> 0:(workerA1'=8) + 0.5:(workerA1'=3)&(workerA1_workerB1_label'=1) + 0.5:(workerA1'=4)&(workerA1_workerB1_label'=2);
    [workerA1_workerB1_stop] workerA1=3 -> 1:(workerA1'=7)&(workerA1_workerB1_label'=0);
    [workerA1_workerB1_datum] workerA1=4 -> 1:(workerA1'=5)&(workerA1_workerB1_label'=0);
    [workerC1_workerA1] (workerA1=5) & (fail=false) -> 1:(workerA1'=6);
    [workerC1_workerA1_result] (workerA1=6) & (workerC1_workerA1_label=1) -> 1:(workerA1'=2);
  endmodule
  
  module workerB1
    workerB1 : [0..7] init 0;
    workerB1_workerC1_label : [0..2] init 0;
  
    [] workerB1=7 -> 1:(fail'=true);
    [workerA1_workerB1] (workerB1=0) & (fail=false) -> 1:(workerB1'=1);
    [workerA1_workerB1_stop] (workerB1=1) & (workerA1_workerB1_label=1) -> 1:(workerB1'=2);
    [workerA1_workerB1_datum] (workerB1=1) & (workerA1_workerB1_label=2) -> 1:(workerB1'=4);
    [workerB1_workerC1] (workerB1=4) & (fail=false) -> 0:(workerB1'=7) + 1:(workerB1'=5)&(workerB1_workerC1_label'=2);
    [workerB1_workerC1_datum] workerB1=5 -> 1:(workerB1'=0)&(workerB1_workerC1_label'=0);
    [workerB1_workerC1] (workerB1=2) & (fail=false) -> 0:(workerB1'=7) + 1:(workerB1'=3)&(workerB1_workerC1_label'=1);
    [workerB1_workerC1_stop] workerB1=3 -> 1:(workerB1'=6)&(workerB1_workerC1_label'=0);
  endmodule
  
  module workerC1
    workerC1 : [0..5] init 0;
    workerC1_workerA1_label : [0..1] init 0;
  
    [] workerC1=5 -> 1:(fail'=true);
    [workerB1_workerC1] (workerC1=0) & (fail=false) -> 1:(workerC1'=1);
    [workerB1_workerC1_stop] (workerC1=1) & (workerB1_workerC1_label=1) -> 1:(workerC1'=4);
    [workerB1_workerC1_datum] (workerC1=1) & (workerB1_workerC1_label=2) -> 1:(workerC1'=2);
    [workerC1_workerA1] (workerC1=2) & (fail=false) -> 0:(workerC1'=5) + 1:(workerC1'=3)&(workerC1_workerA1_label'=1);
    [workerC1_workerA1_result] workerC1=3 -> 1:(workerC1'=0)&(workerC1_workerA1_label'=0);
  endmodule
  
  module workerA2
    workerA2 : [0..8] init 0;
    workerA2_workerB2_label : [0..2] init 0;
  
    [] workerA2=8 -> 1:(fail'=true);
    [starter_workerA2] (workerA2=0) & (fail=false) -> 1:(workerA2'=1);
    [starter_workerA2_datum] (workerA2=1) & (starter_workerA2_label=1) -> 1:(workerA2'=2);
    [workerA2_workerB2] (workerA2=2) & (fail=false) -> 0:(workerA2'=8) + 0.5:(workerA2'=3)&(workerA2_workerB2_label'=1) + 0.5:(workerA2'=4)&(workerA2_workerB2_label'=2);
    [workerA2_workerB2_stop] workerA2=3 -> 1:(workerA2'=7)&(workerA2_workerB2_label'=0);
    [workerA2_workerB2_datum] workerA2=4 -> 1:(workerA2'=5)&(workerA2_workerB2_label'=0);
    [workerC2_workerA2] (workerA2=5) & (fail=false) -> 1:(workerA2'=6);
    [workerC2_workerA2_result] (workerA2=6) & (workerC2_workerA2_label=1) -> 1:(workerA2'=2);
  endmodule
  
  module workerB2
    workerB2 : [0..7] init 0;
    workerB2_workerC2_label : [0..2] init 0;
  
    [] workerB2=7 -> 1:(fail'=true);
    [workerA2_workerB2] (workerB2=0) & (fail=false) -> 1:(workerB2'=1);
    [workerA2_workerB2_stop] (workerB2=1) & (workerA2_workerB2_label=1) -> 1:(workerB2'=2);
    [workerA2_workerB2_datum] (workerB2=1) & (workerA2_workerB2_label=2) -> 1:(workerB2'=4);
    [workerB2_workerC2] (workerB2=4) & (fail=false) -> 0:(workerB2'=7) + 1:(workerB2'=5)&(workerB2_workerC2_label'=2);
    [workerB2_workerC2_datum] workerB2=5 -> 1:(workerB2'=0)&(workerB2_workerC2_label'=0);
    [workerB2_workerC2] (workerB2=2) & (fail=false) -> 0:(workerB2'=7) + 1:(workerB2'=3)&(workerB2_workerC2_label'=1);
    [workerB2_workerC2_stop] workerB2=3 -> 1:(workerB2'=6)&(workerB2_workerC2_label'=0);
  endmodule
  
  module workerC2
    workerC2 : [0..5] init 0;
    workerC2_workerA2_label : [0..1] init 0;
  
    [] workerC2=5 -> 1:(fail'=true);
    [workerB2_workerC2] (workerC2=0) & (fail=false) -> 1:(workerC2'=1);
    [workerB2_workerC2_stop] (workerC2=1) & (workerB2_workerC2_label=1) -> 1:(workerC2'=4);
    [workerB2_workerC2_datum] (workerC2=1) & (workerB2_workerC2_label=2) -> 1:(workerC2'=2);
    [workerC2_workerA2] (workerC2=2) & (fail=false) -> 0:(workerC2'=5) + 1:(workerC2'=3)&(workerC2_workerA2_label'=1);
    [workerC2_workerA2_result] workerC2=3 -> 1:(workerC2'=0)&(workerC2_workerA2_label'=0);
  endmodule
  
  module workerA3
    workerA3 : [0..8] init 0;
    workerA3_workerB3_label : [0..2] init 0;
  
    [] workerA3=8 -> 1:(fail'=true);
    [starter_workerA3] (workerA3=0) & (fail=false) -> 1:(workerA3'=1);
    [starter_workerA3_datum] (workerA3=1) & (starter_workerA3_label=1) -> 1:(workerA3'=2);
    [workerA3_workerB3] (workerA3=2) & (fail=false) -> 0:(workerA3'=8) + 0.5:(workerA3'=3)&(workerA3_workerB3_label'=1) + 0.5:(workerA3'=4)&(workerA3_workerB3_label'=2);
    [workerA3_workerB3_stop] workerA3=3 -> 1:(workerA3'=7)&(workerA3_workerB3_label'=0);
    [workerA3_workerB3_datum] workerA3=4 -> 1:(workerA3'=5)&(workerA3_workerB3_label'=0);
    [workerC3_workerA3] (workerA3=5) & (fail=false) -> 1:(workerA3'=6);
    [workerC3_workerA3_result] (workerA3=6) & (workerC3_workerA3_label=1) -> 1:(workerA3'=2);
  endmodule
  
  module workerB3
    workerB3 : [0..7] init 0;
    workerB3_workerC3_label : [0..2] init 0;
  
    [] workerB3=7 -> 1:(fail'=true);
    [workerA3_workerB3] (workerB3=0) & (fail=false) -> 1:(workerB3'=1);
    [workerA3_workerB3_stop] (workerB3=1) & (workerA3_workerB3_label=1) -> 1:(workerB3'=2);
    [workerA3_workerB3_datum] (workerB3=1) & (workerA3_workerB3_label=2) -> 1:(workerB3'=4);
    [workerB3_workerC3] (workerB3=4) & (fail=false) -> 0:(workerB3'=7) + 1:(workerB3'=5)&(workerB3_workerC3_label'=2);
    [workerB3_workerC3_datum] workerB3=5 -> 1:(workerB3'=0)&(workerB3_workerC3_label'=0);
    [workerB3_workerC3] (workerB3=2) & (fail=false) -> 0:(workerB3'=7) + 1:(workerB3'=3)&(workerB3_workerC3_label'=1);
    [workerB3_workerC3_stop] workerB3=3 -> 1:(workerB3'=6)&(workerB3_workerC3_label'=0);
  endmodule
  
  module workerC3
    workerC3 : [0..5] init 0;
    workerC3_workerA3_label : [0..1] init 0;
  
    [] workerC3=5 -> 1:(fail'=true);
    [workerB3_workerC3] (workerC3=0) & (fail=false) -> 1:(workerC3'=1);
    [workerB3_workerC3_stop] (workerC3=1) & (workerB3_workerC3_label=1) -> 1:(workerC3'=4);
    [workerB3_workerC3_datum] (workerC3=1) & (workerB3_workerC3_label=2) -> 1:(workerC3'=2);
    [workerC3_workerA3] (workerC3=2) & (fail=false) -> 0:(workerC3'=5) + 1:(workerC3'=3)&(workerC3_workerA3_label'=1);
    [workerC3_workerA3_result] workerC3=3 -> 1:(workerC3'=0)&(workerC3_workerA3_label'=0);
  endmodule
  
  label "end" = (starter=6) & (workerA1=7) & (workerB1=6) & (workerC1=4) & (workerA2=7) & (workerB2=6) & (workerC2=4) & (workerA3=7) & (workerB3=6) & (workerC3=4);
  label "cando_starter_workerA1_datum" = starter=0;
  label "cando_starter_workerA1_datum_branch" = workerA1=0;
  label "cando_starter_workerA2_datum" = starter=2;
  label "cando_starter_workerA2_datum_branch" = workerA2=0;
  label "cando_starter_workerA3_datum" = starter=4;
  label "cando_starter_workerA3_datum_branch" = workerA3=0;
  label "cando_workerA1_workerB1_datum" = workerA1=2;
  label "cando_workerA1_workerB1_datum_branch" = workerB1=0;
  label "cando_workerA1_workerB1_stop" = workerA1=2;
  label "cando_workerA1_workerB1_stop_branch" = workerB1=0;
  label "cando_workerA2_workerB2_datum" = workerA2=2;
  label "cando_workerA2_workerB2_datum_branch" = workerB2=0;
  label "cando_workerA2_workerB2_stop" = workerA2=2;
  label "cando_workerA2_workerB2_stop_branch" = workerB2=0;
  label "cando_workerA3_workerB3_datum" = workerA3=2;
  label "cando_workerA3_workerB3_datum_branch" = workerB3=0;
  label "cando_workerA3_workerB3_stop" = workerA3=2;
  label "cando_workerA3_workerB3_stop_branch" = workerB3=0;
  label "cando_workerB1_workerC1_datum" = workerB1=4;
  label "cando_workerB1_workerC1_datum_branch" = workerC1=0;
  label "cando_workerB1_workerC1_stop" = workerB1=2;
  label "cando_workerB1_workerC1_stop_branch" = workerC1=0;
  label "cando_workerB2_workerC2_datum" = workerB2=4;
  label "cando_workerB2_workerC2_datum_branch" = workerC2=0;
  label "cando_workerB2_workerC2_stop" = workerB2=2;
  label "cando_workerB2_workerC2_stop_branch" = workerC2=0;
  label "cando_workerB3_workerC3_datum" = workerB3=4;
  label "cando_workerB3_workerC3_datum_branch" = workerC3=0;
  label "cando_workerB3_workerC3_stop" = workerB3=2;
  label "cando_workerB3_workerC3_stop_branch" = workerC3=0;
  label "cando_workerC1_workerA1_result" = workerC1=2;
  label "cando_workerC1_workerA1_result_branch" = workerA1=5;
  label "cando_workerC2_workerA2_result" = workerC2=2;
  label "cando_workerC2_workerA2_result_branch" = workerA2=5;
  label "cando_workerC3_workerA3_result" = workerC3=2;
  label "cando_workerC3_workerA3_result_branch" = workerA3=5;
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
  P>=1 [ (G ((("cando_starter_workerA1_datum" & "cando_starter_workerA1_branch") => "cando_starter_workerA1_datum_branch") & ((("cando_starter_workerA2_datum" & "cando_starter_workerA2_branch") => "cando_starter_workerA2_datum_branch") & ((("cando_starter_workerA3_datum" & "cando_starter_workerA3_branch") => "cando_starter_workerA3_datum_branch") & ((("cando_workerA1_workerB1_datum" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_datum_branch") & ((("cando_workerA1_workerB1_stop" & "cando_workerA1_workerB1_branch") => "cando_workerA1_workerB1_stop_branch") & ((("cando_workerA2_workerB2_datum" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_datum_branch") & ((("cando_workerA2_workerB2_stop" & "cando_workerA2_workerB2_branch") => "cando_workerA2_workerB2_stop_branch") & ((("cando_workerA3_workerB3_datum" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_datum_branch") & ((("cando_workerA3_workerB3_stop" & "cando_workerA3_workerB3_branch") => "cando_workerA3_workerB3_stop_branch") & ((("cando_workerB1_workerC1_datum" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_datum_branch") & ((("cando_workerB1_workerC1_stop" & "cando_workerB1_workerC1_branch") => "cando_workerB1_workerC1_stop_branch") & ((("cando_workerB2_workerC2_datum" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_datum_branch") & ((("cando_workerB2_workerC2_stop" & "cando_workerB2_workerC2_branch") => "cando_workerB2_workerC2_stop_branch") & ((("cando_workerB3_workerC3_datum" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_datum_branch") & ((("cando_workerB3_workerC3_stop" & "cando_workerB3_workerC3_branch") => "cando_workerB3_workerC3_stop_branch") & ((("cando_workerC1_workerA1_result" & "cando_workerC1_workerA1_branch") => "cando_workerC1_workerA1_result_branch") & ((("cando_workerC2_workerA2_result" & "cando_workerC2_workerA2_branch") => "cando_workerC2_workerA2_result_branch") & (("cando_workerC3_workerA3_result" & "cando_workerC3_workerA3_branch") => "cando_workerC3_workerA3_result_branch"))))))))))))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
    a_b_label : [0..2] init 0;
  
    [] a=6 -> 1:(fail'=true);
    [a_b] (a=0) & (fail=false) -> 0:(a'=6) + 0.5:(a'=1)&(a_b_label'=1) + 0.5:(a'=2)&(a_b_label'=2);
    [a_b_l2] a=1 -> 1:(a'=3)&(a_b_label'=0);
    [a_b_l1] a=2 -> 1:(a'=5)&(a_b_label'=0);
    [a_b] (a=3) & (fail=false) -> 0:(a'=6) + 1:(a'=4)&(a_b_label'=1);
    [a_b_l2] a=4 -> 1:(a'=3)&(a_b_label'=0);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] b=3 -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_l2] (b=1) & (a_b_label=1) -> 1:(b'=0);
    [a_b_l1] (b=1) & (a_b_label=2) -> 1:(b'=2);
  endmodule
  
  label "end" = (a=5) & (b=2);
  label "cando_a_b_l1" = a=0;
  label "cando_a_b_l1_branch" = b=0;
  label "cando_a_b_l2" = (a=0) | (a=3);
  label "cando_a_b_l2_branch" = b=0;
  label "cando_a_b_branch" = b=0;
  P>=1 [ (G ((("cando_a_b_l1" & "cando_a_b_branch") => "cando_a_b_l1_branch") & (("cando_a_b_l2" & "cando_a_b_branch") => "cando_a_b_l2_branch"))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 0.5 (exact floating point)
  
  
  
  
   ======= TEST ../examples/open.ctx =======
  
  alice : bob (+) { 0.33 : a.end, 0.33 : b . carol(+) c . end, 0.34 : c . end }
  bob : alice & { a.end, b.end, c.end }
  
  
   ======= PRISM output ========
  
  global fail : bool init false;
  
  module closure
    closure : bool init false;
  
    [alice_carol] false -> 1:(closure'=false);
    [carol_alice] false -> 1:(closure'=false);
    [bob_carol] false -> 1:(closure'=false);
    [carol_bob] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..7] init 0;
    alice_bob_label : [0..3] init 0;
    alice_carol_label : [0..1] init 0;
  
    [] alice=7 -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=7) + 0.34:(alice'=1)&(alice_bob_label'=1) + 0.33:(alice'=2)&(alice_bob_label'=2) + 0.33:(alice'=3)&(alice_bob_label'=3);
    [alice_bob_c] alice=1 -> 1:(alice'=6)&(alice_bob_label'=0);
    [alice_bob_b] alice=2 -> 1:(alice'=4)&(alice_bob_label'=0);
    [alice_bob_a] alice=3 -> 1:(alice'=6)&(alice_bob_label'=0);
    [alice_carol] (alice=4) & (fail=false) -> 0:(alice'=7) + 1:(alice'=5)&(alice_carol_label'=1);
    [alice_carol_c] alice=5 -> 1:(alice'=6)&(alice_carol_label'=0);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] bob=3 -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_c] (bob=1) & (alice_bob_label=1) -> 1:(bob'=2);
    [alice_bob_b] (bob=1) & (alice_bob_label=2) -> 1:(bob'=2);
    [alice_bob_a] (bob=1) & (alice_bob_label=3) -> 1:(bob'=2);
  endmodule
  
  label "end" = (alice=6) & (bob=2);
  label "cando_alice_bob_a" = alice=0;
  label "cando_alice_bob_a_branch" = bob=0;
  label "cando_alice_bob_b" = alice=0;
  label "cando_alice_bob_b_branch" = bob=0;
  label "cando_alice_bob_c" = alice=0;
  label "cando_alice_bob_c_branch" = bob=0;
  label "cando_alice_carol_c" = alice=4;
  label "cando_alice_carol_c_branch" = false;
  label "cando_alice_bob_branch" = bob=0;
  label "cando_alice_carol_branch" = false;
  P>=1 [ (G ((("cando_alice_bob_a" & "cando_alice_bob_branch") => "cando_alice_bob_a_branch") & ((("cando_alice_bob_b" & "cando_alice_bob_branch") => "cando_alice_bob_b_branch") & ((("cando_alice_bob_c" & "cando_alice_bob_branch") => "cando_alice_bob_c_branch") & (("cando_alice_carol_c" & "cando_alice_carol_branch") => "cando_alice_carol_c_branch"))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.6699999999999999 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.6699999999999999
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
  
  endmodule
  
  module commander
    commander : [0..4] init 0;
    commander_a_label : [0..2] init 0;
  
    [] commander=4 -> 1:(fail'=true);
    [commander_a] (commander=0) & (fail=false) -> 0:(commander'=4) + 0.3:(commander'=1)&(commander_a_label'=1) + 0.7:(commander'=2)&(commander_a_label'=2);
    [commander_a_nodeadlock] commander=1 -> 1:(commander'=3)&(commander_a_label'=0);
    [commander_a_deadlock] commander=2 -> 1:(commander'=3)&(commander_a_label'=0);
  endmodule
  
  module a
    a : [0..7] init 0;
    a_b_label : [0..1] init 0;
  
    [] a=7 -> 1:(fail'=true);
    [commander_a] (a=0) & (fail=false) -> 1:(a'=1);
    [commander_a_nodeadlock] (a=1) & (commander_a_label=1) -> 1:(a'=2);
    [commander_a_deadlock] (a=1) & (commander_a_label=2) -> 1:(a'=4);
    [b_a] (a=4) & (fail=false) -> 1:(a'=5);
    [b_a_msg] (a=5) & (b_a_label=1) -> 1:(a'=6);
    [a_b] (a=2) & (fail=false) -> 0:(a'=7) + 1:(a'=3)&(a_b_label'=1);
    [a_b_msg] a=3 -> 1:(a'=6)&(a_b_label'=0);
  endmodule
  
  module b
    b : [0..3] init 0;
    b_a_label : [0..1] init 0;
  
    [] b=3 -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_msg] (b=1) & (a_b_label=1) -> 1:(b'=2);
  endmodule
  
  label "end" = (commander=3) & (a=6) & (b=2);
  label "cando_a_b_msg" = a=2;
  label "cando_a_b_msg_branch" = b=0;
  label "cando_b_a_msg" = false;
  label "cando_b_a_msg_branch" = a=4;
  label "cando_commander_a_deadlock" = commander=0;
  label "cando_commander_a_deadlock_branch" = a=0;
  label "cando_commander_a_nodeadlock" = commander=0;
  label "cando_commander_a_nodeadlock_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=4;
  label "cando_commander_a_branch" = a=0;
  P>=1 [ (G ((("cando_a_b_msg" & "cando_a_b_branch") => "cando_a_b_msg_branch") & ((("cando_b_a_msg" & "cando_b_a_branch") => "cando_b_a_msg_branch") & ((("cando_commander_a_deadlock" & "cando_commander_a_branch") => "cando_commander_a_deadlock_branch") & (("cando_commander_a_nodeadlock" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_branch"))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.30000000000000004
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
    mapper_worker1_label : [0..2] init 0;
    mapper_worker2_label : [0..2] init 0;
    mapper_worker3_label : [0..2] init 0;
  
    [] mapper=15 -> 1:(fail'=true);
    [mapper_worker1] (mapper=0) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=1)&(mapper_worker1_label'=2);
    [mapper_worker1_datum] mapper=1 -> 1:(mapper'=2)&(mapper_worker1_label'=0);
    [mapper_worker2] (mapper=2) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=3)&(mapper_worker2_label'=2);
    [mapper_worker2_datum] mapper=3 -> 1:(mapper'=4)&(mapper_worker2_label'=0);
    [mapper_worker3] (mapper=4) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=5)&(mapper_worker3_label'=2);
    [mapper_worker3_datum] mapper=5 -> 1:(mapper'=6)&(mapper_worker3_label'=0);
    [reducer_mapper] (mapper=6) & (fail=false) -> 1:(mapper'=7);
    [reducer_mapper_stop] (mapper=7) & (reducer_mapper_label=1) -> 1:(mapper'=8);
    [reducer_mapper_continue] (mapper=7) & (reducer_mapper_label=2) -> 1:(mapper'=0);
    [mapper_worker1] (mapper=8) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=9)&(mapper_worker1_label'=1);
    [mapper_worker1_stop] mapper=9 -> 1:(mapper'=10)&(mapper_worker1_label'=0);
    [mapper_worker2] (mapper=10) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=11)&(mapper_worker2_label'=1);
    [mapper_worker2_stop] mapper=11 -> 1:(mapper'=12)&(mapper_worker2_label'=0);
    [mapper_worker3] (mapper=12) & (fail=false) -> 0:(mapper'=15) + 1:(mapper'=13)&(mapper_worker3_label'=1);
    [mapper_worker3_stop] mapper=13 -> 1:(mapper'=14)&(mapper_worker3_label'=0);
  endmodule
  
  module worker1
    worker1 : [0..7] init 0;
    worker1_reducer_label : [0..1] init 0;
  
    [] worker1=7 -> 1:(fail'=true);
    [mapper_worker1] (worker1=0) & (fail=false) -> 1:(worker1'=1);
    [mapper_worker1_stop] false -> 1:(worker1'=1);
    [mapper_worker1_datum] (worker1=1) & (mapper_worker1_label=2) -> 1:(worker1'=2);
    [worker1_reducer] (worker1=2) & (fail=false) -> 0:(worker1'=7) + 1:(worker1'=3)&(worker1_reducer_label'=1);
    [worker1_reducer_result] worker1=3 -> 1:(worker1'=4)&(worker1_reducer_label'=0);
    [mapper_worker1] (worker1=4) & (fail=false) -> 1:(worker1'=5);
    [mapper_worker1_stop] (worker1=5) & (mapper_worker1_label=1) -> 1:(worker1'=6);
    [mapper_worker1_datum] (worker1=5) & (mapper_worker1_label=2) -> 1:(worker1'=2);
  endmodule
  
  module worker2
    worker2 : [0..7] init 0;
    worker2_reducer_label : [0..1] init 0;
  
    [] worker2=7 -> 1:(fail'=true);
    [mapper_worker2] (worker2=0) & (fail=false) -> 1:(worker2'=1);
    [mapper_worker2_stop] false -> 1:(worker2'=1);
    [mapper_worker2_datum] (worker2=1) & (mapper_worker2_label=2) -> 1:(worker2'=2);
    [worker2_reducer] (worker2=2) & (fail=false) -> 0:(worker2'=7) + 1:(worker2'=3)&(worker2_reducer_label'=1);
    [worker2_reducer_result] worker2=3 -> 1:(worker2'=4)&(worker2_reducer_label'=0);
    [mapper_worker2] (worker2=4) & (fail=false) -> 1:(worker2'=5);
    [mapper_worker2_stop] (worker2=5) & (mapper_worker2_label=1) -> 1:(worker2'=6);
    [mapper_worker2_datum] (worker2=5) & (mapper_worker2_label=2) -> 1:(worker2'=2);
  endmodule
  
  module worker3
    worker3 : [0..7] init 0;
    worker3_reducer_label : [0..1] init 0;
  
    [] worker3=7 -> 1:(fail'=true);
    [mapper_worker3] (worker3=0) & (fail=false) -> 1:(worker3'=1);
    [mapper_worker3_stop] false -> 1:(worker3'=1);
    [mapper_worker3_datum] (worker3=1) & (mapper_worker3_label=2) -> 1:(worker3'=2);
    [worker3_reducer] (worker3=2) & (fail=false) -> 0:(worker3'=7) + 1:(worker3'=3)&(worker3_reducer_label'=1);
    [worker3_reducer_result] worker3=3 -> 1:(worker3'=4)&(worker3_reducer_label'=0);
    [mapper_worker3] (worker3=4) & (fail=false) -> 1:(worker3'=5);
    [mapper_worker3_stop] (worker3=5) & (mapper_worker3_label=1) -> 1:(worker3'=6);
    [mapper_worker3_datum] (worker3=5) & (mapper_worker3_label=2) -> 1:(worker3'=2);
  endmodule
  
  module reducer
    reducer : [0..10] init 0;
    reducer_mapper_label : [0..2] init 0;
  
    [] reducer=10 -> 1:(fail'=true);
    [worker1_reducer] (reducer=0) & (fail=false) -> 1:(reducer'=1);
    [worker1_reducer_result] (reducer=1) & (worker1_reducer_label=1) -> 1:(reducer'=2);
    [worker2_reducer] (reducer=2) & (fail=false) -> 1:(reducer'=3);
    [worker2_reducer_result] (reducer=3) & (worker2_reducer_label=1) -> 1:(reducer'=4);
    [worker3_reducer] (reducer=4) & (fail=false) -> 1:(reducer'=5);
    [worker3_reducer_result] (reducer=5) & (worker3_reducer_label=1) -> 1:(reducer'=6);
    [reducer_mapper] (reducer=6) & (fail=false) -> 0:(reducer'=10) + 0.6:(reducer'=7)&(reducer_mapper_label'=1) + 0.4:(reducer'=8)&(reducer_mapper_label'=2);
    [reducer_mapper_stop] reducer=7 -> 1:(reducer'=9)&(reducer_mapper_label'=0);
    [reducer_mapper_continue] reducer=8 -> 1:(reducer'=0)&(reducer_mapper_label'=0);
  endmodule
  
  label "end" = (mapper=14) & (worker1=6) & (worker2=6) & (worker3=6) & (reducer=9);
  label "cando_mapper_worker1_datum" = mapper=0;
  label "cando_mapper_worker1_datum_branch" = (worker1=0) | (worker1=4);
  label "cando_mapper_worker1_stop" = mapper=8;
  label "cando_mapper_worker1_stop_branch" = worker1=4;
  label "cando_mapper_worker2_datum" = mapper=2;
  label "cando_mapper_worker2_datum_branch" = (worker2=0) | (worker2=4);
  label "cando_mapper_worker2_stop" = mapper=10;
  label "cando_mapper_worker2_stop_branch" = worker2=4;
  label "cando_mapper_worker3_datum" = mapper=4;
  label "cando_mapper_worker3_datum_branch" = (worker3=0) | (worker3=4);
  label "cando_mapper_worker3_stop" = mapper=12;
  label "cando_mapper_worker3_stop_branch" = worker3=4;
  label "cando_reducer_mapper_continue" = reducer=6;
  label "cando_reducer_mapper_continue_branch" = mapper=6;
  label "cando_reducer_mapper_stop" = reducer=6;
  label "cando_reducer_mapper_stop_branch" = mapper=6;
  label "cando_worker1_reducer_result" = worker1=2;
  label "cando_worker1_reducer_result_branch" = reducer=0;
  label "cando_worker2_reducer_result" = worker2=2;
  label "cando_worker2_reducer_result_branch" = reducer=2;
  label "cando_worker3_reducer_result" = worker3=2;
  label "cando_worker3_reducer_result_branch" = reducer=4;
  label "cando_mapper_worker1_branch" = (worker1=0) | (worker1=4);
  label "cando_mapper_worker2_branch" = (worker2=0) | (worker2=4);
  label "cando_mapper_worker3_branch" = (worker3=0) | (worker3=4);
  label "cando_reducer_mapper_branch" = mapper=6;
  label "cando_worker1_reducer_branch" = reducer=0;
  label "cando_worker2_reducer_branch" = reducer=2;
  label "cando_worker3_reducer_branch" = reducer=4;
  P>=1 [ (G ((("cando_mapper_worker1_datum" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_datum_branch") & ((("cando_mapper_worker1_stop" & "cando_mapper_worker1_branch") => "cando_mapper_worker1_stop_branch") & ((("cando_mapper_worker2_datum" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_datum_branch") & ((("cando_mapper_worker2_stop" & "cando_mapper_worker2_branch") => "cando_mapper_worker2_stop_branch") & ((("cando_mapper_worker3_datum" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_datum_branch") & ((("cando_mapper_worker3_stop" & "cando_mapper_worker3_branch") => "cando_mapper_worker3_stop_branch") & ((("cando_reducer_mapper_continue" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_continue_branch") & ((("cando_reducer_mapper_stop" & "cando_reducer_mapper_branch") => "cando_reducer_mapper_stop_branch") & ((("cando_worker1_reducer_result" & "cando_worker1_reducer_branch") => "cando_worker1_reducer_result_branch") & ((("cando_worker2_reducer_result" & "cando_worker2_reducer_branch") => "cando_worker2_reducer_result_branch") & (("cando_worker3_reducer_result" & "cando_worker3_reducer_branch") => "cando_worker3_reducer_result_branch")))))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
    alice_bob_label : [0..2] init 0;
    alice_shop_label : [0..3] init 0;
  
    [] alice=14 -> 1:(fail'=true);
    [alice_shop] (alice=0) & (fail=false) -> 0:(alice'=14) + 1:(alice'=1)&(alice_shop_label'=1);
    [alice_shop_query] alice=1 -> 1:(alice'=2)&(alice_shop_label'=0);
    [shop_alice] (alice=2) & (fail=false) -> 1:(alice'=3);
    [shop_alice_price] (alice=3) & (shop_alice_label=1) -> 1:(alice'=4);
    [alice_bob] (alice=4) & (fail=false) -> 0:(alice'=14) + 0.5:(alice'=5)&(alice_bob_label'=1) + 0.5:(alice'=6)&(alice_bob_label'=2);
    [alice_bob_split] alice=5 -> 1:(alice'=7)&(alice_bob_label'=0);
    [alice_bob_cancel] alice=6 -> 1:(alice'=11)&(alice_bob_label'=0);
    [bob_alice] (alice=7) & (fail=false) -> 1:(alice'=8);
    [bob_alice_yes] (alice=8) & (bob_alice_label=1) -> 1:(alice'=9);
    [bob_alice_no] (alice=8) & (bob_alice_label=2) -> 1:(alice'=4);
    [alice_shop] (alice=9) & (fail=false) -> 0:(alice'=14) + 1:(alice'=10)&(alice_shop_label'=3);
    [alice_shop_buy] alice=10 -> 1:(alice'=13)&(alice_shop_label'=0);
    [alice_shop] (alice=11) & (fail=false) -> 0:(alice'=14) + 1:(alice'=12)&(alice_shop_label'=2);
    [alice_shop_no] alice=12 -> 1:(alice'=13)&(alice_shop_label'=0);
  endmodule
  
  module shop
    shop : [0..7] init 0;
    shop_alice_label : [0..1] init 0;
  
    [] shop=7 -> 1:(fail'=true);
    [alice_shop] (shop=0) & (fail=false) -> 1:(shop'=1);
    [alice_shop_query] (shop=1) & (alice_shop_label=1) -> 1:(shop'=2);
    [alice_shop_no] false -> 1:(shop'=1);
    [alice_shop_buy] false -> 1:(shop'=1);
    [shop_alice] (shop=2) & (fail=false) -> 0:(shop'=7) + 1:(shop'=3)&(shop_alice_label'=1);
    [shop_alice_price] shop=3 -> 1:(shop'=4)&(shop_alice_label'=0);
    [alice_shop] (shop=4) & (fail=false) -> 1:(shop'=5);
    [alice_shop_query] false -> 1:(shop'=5);
    [alice_shop_no] (shop=5) & (alice_shop_label=2) -> 1:(shop'=6);
    [alice_shop_buy] (shop=5) & (alice_shop_label=3) -> 1:(shop'=6);
  endmodule
  
  module bob
    bob : [0..6] init 0;
    bob_alice_label : [0..2] init 0;
  
    [] bob=6 -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_split] (bob=1) & (alice_bob_label=1) -> 1:(bob'=2);
    [alice_bob_cancel] (bob=1) & (alice_bob_label=2) -> 1:(bob'=5);
    [bob_alice] (bob=2) & (fail=false) -> 0:(bob'=6) + 0.5:(bob'=3)&(bob_alice_label'=1) + 0.5:(bob'=4)&(bob_alice_label'=2);
    [bob_alice_yes] bob=3 -> 1:(bob'=5)&(bob_alice_label'=0);
    [bob_alice_no] bob=4 -> 1:(bob'=0)&(bob_alice_label'=0);
  endmodule
  
  label "end" = (alice=13) & (shop=6) & (bob=5);
  label "cando_alice_bob_cancel" = alice=4;
  label "cando_alice_bob_cancel_branch" = bob=0;
  label "cando_alice_bob_split" = alice=4;
  label "cando_alice_bob_split_branch" = bob=0;
  label "cando_alice_shop_buy" = alice=9;
  label "cando_alice_shop_buy_branch" = shop=4;
  label "cando_alice_shop_no" = alice=11;
  label "cando_alice_shop_no_branch" = shop=4;
  label "cando_alice_shop_query" = alice=0;
  label "cando_alice_shop_query_branch" = shop=0;
  label "cando_bob_alice_no" = bob=2;
  label "cando_bob_alice_no_branch" = alice=7;
  label "cando_bob_alice_yes" = bob=2;
  label "cando_bob_alice_yes_branch" = alice=7;
  label "cando_shop_alice_price" = shop=2;
  label "cando_shop_alice_price_branch" = alice=2;
  label "cando_alice_bob_branch" = bob=0;
  label "cando_alice_shop_branch" = (shop=0) | (shop=4);
  label "cando_bob_alice_branch" = alice=7;
  label "cando_shop_alice_branch" = alice=2;
  P>=1 [ (G ((("cando_alice_bob_cancel" & "cando_alice_bob_branch") => "cando_alice_bob_cancel_branch") & ((("cando_alice_bob_split" & "cando_alice_bob_branch") => "cando_alice_bob_split_branch") & ((("cando_alice_shop_buy" & "cando_alice_shop_branch") => "cando_alice_shop_buy_branch") & ((("cando_alice_shop_no" & "cando_alice_shop_branch") => "cando_alice_shop_no_branch") & ((("cando_alice_shop_query" & "cando_alice_shop_branch") => "cando_alice_shop_query_branch") & ((("cando_bob_alice_no" & "cando_bob_alice_branch") => "cando_bob_alice_no_branch") & ((("cando_bob_alice_yes" & "cando_bob_alice_branch") => "cando_bob_alice_yes_branch") & (("cando_shop_alice_price" & "cando_shop_alice_branch") => "cando_shop_alice_price_branch"))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
    p_q_label : [0..2] init 0;
  
    [] p=6 -> 1:(fail'=true);
    [p_q] (p=0) & (fail=false) -> 0:(p'=6) + 0.5:(p'=1)&(p_q_label'=1) + 0.5:(p'=2)&(p_q_label'=2);
    [p_q_l2] p=1 -> 1:(p'=3)&(p_q_label'=0);
    [p_q_l1] p=2 -> 1:(p'=5)&(p_q_label'=0);
    [p_q] (p=3) & (fail=false) -> 0:(p'=6) + 1:(p'=4)&(p_q_label'=2);
    [p_q_l1] p=4 -> 1:(p'=5)&(p_q_label'=0);
  endmodule
  
  module q
    q : [0..5] init 0;
  
    [] q=5 -> 1:(fail'=true);
    [p_q] (q=0) & (fail=false) -> 1:(q'=1);
    [p_q_l2] (q=1) & (p_q_label=1) -> 1:(q'=2);
    [p_q_l1] (q=1) & (p_q_label=2) -> 1:(q'=4);
    [p_q] (q=2) & (fail=false) -> 1:(q'=3);
    [p_q_l2] false -> 1:(q'=3);
    [p_q_l1] (q=3) & (p_q_label=2) -> 1:(q'=4);
  endmodule
  
  module p1
    p1 : [0..6] init 0;
    p1_q1_label : [0..2] init 0;
  
    [] p1=6 -> 1:(fail'=true);
    [p1_q1] (p1=0) & (fail=false) -> 0:(p1'=6) + 0.5:(p1'=1)&(p1_q1_label'=1) + 0.5:(p1'=2)&(p1_q1_label'=2);
    [p1_q1_l2] p1=1 -> 1:(p1'=5)&(p1_q1_label'=0);
    [p1_q1_l1] p1=2 -> 1:(p1'=3)&(p1_q1_label'=0);
    [p1_q1] (p1=3) & (fail=false) -> 0:(p1'=6) + 1:(p1'=4)&(p1_q1_label'=1);
    [p1_q1_l2] p1=4 -> 1:(p1'=5)&(p1_q1_label'=0);
  endmodule
  
  module q1
    q1 : [0..5] init 0;
  
    [] q1=5 -> 1:(fail'=true);
    [p1_q1] (q1=0) & (fail=false) -> 1:(q1'=1);
    [p1_q1_l2] (q1=1) & (p1_q1_label=1) -> 1:(q1'=4);
    [p1_q1_l1] (q1=1) & (p1_q1_label=2) -> 1:(q1'=2);
    [p1_q1] (q1=2) & (fail=false) -> 1:(q1'=3);
    [p1_q1_l2] (q1=3) & (p1_q1_label=1) -> 1:(q1'=4);
    [p1_q1_l1] false -> 1:(q1'=3);
  endmodule
  
  module q2
    q2 : [0..5] init 0;
  
    [] q2=5 -> 1:(fail'=true);
    [p2_q2] (q2=0) & (fail=false) -> 1:(q2'=1);
    [p2_q2_l2] (q2=1) & (p2_q2_label=1) -> 1:(q2'=2);
    [p2_q2_l1] (q2=1) & (p2_q2_label=2) -> 1:(q2'=4);
    [p2_q2] (q2=2) & (fail=false) -> 1:(q2'=3);
    [p2_q2_l2] false -> 1:(q2'=3);
    [p2_q2_l1] (q2=3) & (p2_q2_label=2) -> 1:(q2'=4);
  endmodule
  
  module p2
    p2 : [0..6] init 0;
    p2_q2_label : [0..2] init 0;
  
    [] p2=6 -> 1:(fail'=true);
    [p2_q2] (p2=0) & (fail=false) -> 0:(p2'=6) + 0.5:(p2'=1)&(p2_q2_label'=1) + 0.5:(p2'=2)&(p2_q2_label'=2);
    [p2_q2_l2] p2=1 -> 1:(p2'=3)&(p2_q2_label'=0);
    [p2_q2_l1] p2=2 -> 1:(p2'=5)&(p2_q2_label'=0);
    [p2_q2] (p2=3) & (fail=false) -> 0:(p2'=6) + 1:(p2'=4)&(p2_q2_label'=2);
    [p2_q2_l1] p2=4 -> 1:(p2'=5)&(p2_q2_label'=0);
  endmodule
  
  label "end" = (p=5) & (q=4) & (p1=5) & (q1=4) & (q2=4) & (p2=5);
  label "cando_p_q_l1" = (p=0) | (p=3);
  label "cando_p_q_l1_branch" = (q=0) | (q=2);
  label "cando_p_q_l2" = p=0;
  label "cando_p_q_l2_branch" = q=0;
  label "cando_p1_q1_l1" = p1=0;
  label "cando_p1_q1_l1_branch" = q1=0;
  label "cando_p1_q1_l2" = (p1=0) | (p1=3);
  label "cando_p1_q1_l2_branch" = (q1=0) | (q1=2);
  label "cando_p2_q2_l1" = (p2=0) | (p2=3);
  label "cando_p2_q2_l1_branch" = (q2=0) | (q2=2);
  label "cando_p2_q2_l2" = p2=0;
  label "cando_p2_q2_l2_branch" = q2=0;
  label "cando_p_q_branch" = (q=0) | (q=2);
  label "cando_p1_q1_branch" = (q1=0) | (q1=2);
  label "cando_p2_q2_branch" = (q2=0) | (q2=2);
  P>=1 [ (G ((("cando_p_q_l1" & "cando_p_q_branch") => "cando_p_q_l1_branch") & ((("cando_p_q_l2" & "cando_p_q_branch") => "cando_p_q_l2_branch") & ((("cando_p1_q1_l1" & "cando_p1_q1_branch") => "cando_p1_q1_l1_branch") & ((("cando_p1_q1_l2" & "cando_p1_q1_branch") => "cando_p1_q1_l2_branch") & ((("cando_p2_q2_l1" & "cando_p2_q2_branch") => "cando_p2_q2_l1_branch") & (("cando_p2_q2_l2" & "cando_p2_q2_branch") => "cando_p2_q2_l2_branch"))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
    alice_bob_label : [0..2] init 0;
  
    [] alice=4 -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=4) + 0.67:(alice'=1)&(alice_bob_label'=1) + 0.33:(alice'=2)&(alice_bob_label'=2);
    [alice_bob_b] alice=1 -> 1:(alice'=3)&(alice_bob_label'=0);
    [alice_bob_a] alice=2 -> 1:(alice'=3)&(alice_bob_label'=0);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] bob=3 -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_b] (bob=1) & (alice_bob_label=1) -> 1:(bob'=2);
    [alice_bob_a] (bob=1) & (alice_bob_label=2) -> 1:(bob'=2);
  endmodule
  
  label "end" = (alice=3) & (bob=2);
  label "cando_alice_bob_a" = alice=0;
  label "cando_alice_bob_a_branch" = bob=0;
  label "cando_alice_bob_b" = alice=0;
  label "cando_alice_bob_b_branch" = bob=0;
  label "cando_alice_bob_branch" = bob=0;
  P>=1 [ (G ((("cando_alice_bob_a" & "cando_alice_bob_branch") => "cando_alice_bob_a_branch") & (("cando_alice_bob_b" & "cando_alice_bob_branch") => "cando_alice_bob_b_branch"))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 1.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 1.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
  
  endmodule
  
  module commander
    commander : [0..4] init 0;
    commander_a_label : [0..2] init 0;
  
    [] commander=4 -> 1:(fail'=true);
    [commander_a] (commander=0) & (fail=false) -> 0.2:(commander'=4) + 0.3:(commander'=1)&(commander_a_label'=1) + 0.5:(commander'=2)&(commander_a_label'=2);
    [commander_a_nodeadlock] commander=1 -> 1:(commander'=3)&(commander_a_label'=0);
    [commander_a_deadlock] commander=2 -> 1:(commander'=3)&(commander_a_label'=0);
  endmodule
  
  module a
    a : [0..7] init 0;
    a_b_label : [0..1] init 0;
  
    [] a=7 -> 1:(fail'=true);
    [commander_a] (a=0) & (fail=false) -> 1:(a'=1);
    [commander_a_nodeadlock] (a=1) & (commander_a_label=1) -> 1:(a'=2);
    [commander_a_deadlock] (a=1) & (commander_a_label=2) -> 1:(a'=4);
    [b_a] (a=4) & (fail=false) -> 1:(a'=5);
    [b_a_msg] (a=5) & (b_a_label=1) -> 1:(a'=6);
    [a_b] (a=2) & (fail=false) -> 0:(a'=7) + 1:(a'=3)&(a_b_label'=1);
    [a_b_msg] a=3 -> 1:(a'=6)&(a_b_label'=0);
  endmodule
  
  module b
    b : [0..3] init 0;
    b_a_label : [0..1] init 0;
  
    [] b=3 -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_msg] (b=1) & (a_b_label=1) -> 1:(b'=2);
  endmodule
  
  label "end" = (commander=3) & (a=6) & (b=2);
  label "cando_a_b_msg" = a=2;
  label "cando_a_b_msg_branch" = b=0;
  label "cando_b_a_msg" = false;
  label "cando_b_a_msg_branch" = a=4;
  label "cando_commander_a_deadlock" = commander=0;
  label "cando_commander_a_deadlock_branch" = a=0;
  label "cando_commander_a_nodeadlock" = commander=0;
  label "cando_commander_a_nodeadlock_branch" = a=0;
  label "cando_a_b_branch" = b=0;
  label "cando_b_a_branch" = a=4;
  label "cando_commander_a_branch" = a=0;
  P>=1 [ (G ((("cando_a_b_msg" & "cando_a_b_branch") => "cando_a_b_msg_branch") & ((("cando_b_a_msg" & "cando_b_a_branch") => "cando_b_a_msg_branch") & ((("cando_commander_a_deadlock" & "cando_commander_a_branch") => "cando_commander_a_deadlock_branch") & (("cando_commander_a_nodeadlock" & "cando_commander_a_branch") => "cando_commander_a_nodeadlock_branch"))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.30000000000000004 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.37500000000000006
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
   ======= TEST ../examples/sync_alone.ctx =======
  
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
  
    [a_b] false -> 1:(closure'=false);
    [b_a] false -> 1:(closure'=false);
    [alice_bob] false -> 1:(closure'=false);
    [bob_alice] false -> 1:(closure'=false);
  endmodule
  
  module alice
    alice : [0..4] init 0;
    alice_bob_label : [0..2] init 0;
  
    [] alice=4 -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=4) + 0.6:(alice'=1)&(alice_bob_label'=1) + 0.4:(alice'=2)&(alice_bob_label'=2);
    [alice_bob_l2] alice=1 -> 1:(alice'=3)&(alice_bob_label'=0);
    [alice_bob_l1] alice=2 -> 1:(alice'=3)&(alice_bob_label'=0);
  endmodule
  
  module bob
    bob : [0..3] init 0;
  
    [] bob=3 -> 1:(fail'=true);
    [charlie_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [charlie_bob_l2] (bob=1) & (charlie_bob_label=1) -> 1:(bob'=2);
    [charlie_bob_l1] (bob=1) & (charlie_bob_label=2) -> 1:(bob'=2);
  endmodule
  
  module charlie
    charlie : [0..4] init 0;
    charlie_bob_label : [0..2] init 0;
  
    [] charlie=4 -> 1:(fail'=true);
    [charlie_bob] (charlie=0) & (fail=false) -> 0:(charlie'=4) + 0.5:(charlie'=1)&(charlie_bob_label'=1) + 0.5:(charlie'=2)&(charlie_bob_label'=2);
    [charlie_bob_l2] charlie=1 -> 1:(charlie'=3)&(charlie_bob_label'=0);
    [charlie_bob_l1] charlie=2 -> 1:(charlie'=3)&(charlie_bob_label'=0);
  endmodule
  
  module a
    a : [0..3] init 0;
  
    [] a=3 -> 1:(fail'=true);
    [b_a] (a=0) & (fail=false) -> 1:(a'=1);
    [b_a_l2] (a=1) & (b_a_label=1) -> 1:(a'=2);
    [b_a_l1] (a=1) & (b_a_label=2) -> 1:(a'=2);
  endmodule
  
  module b
    b : [0..4] init 0;
    b_a_label : [0..2] init 0;
    b_c_label : [0..2] init 0;
  
    [] b=4 -> 1:(fail'=true);
    [b_c] (b=0) & (fail=false) -> 0:(b'=4) + 0.3:(b'=1)&(b_c_label'=1) + 0.7:(b'=2)&(b_c_label'=2);
    [b_c_l2] b=1 -> 1:(b'=3)&(b_c_label'=0);
    [b_c_l1] b=2 -> 1:(b'=3)&(b_c_label'=0);
  endmodule
  
  module c
    c : [0..3] init 0;
  
    [] c=3 -> 1:(fail'=true);
    [b_c] (c=0) & (fail=false) -> 1:(c'=1);
    [b_c_l2] (c=1) & (b_c_label=1) -> 1:(c'=2);
    [b_c_l1] (c=1) & (b_c_label=2) -> 1:(c'=2);
  endmodule
  
  label "end" = (alice=3) & (bob=2) & (charlie=3) & (a=2) & (b=3) & (c=2);
  label "cando_alice_bob_l1" = alice=0;
  label "cando_alice_bob_l1_branch" = false;
  label "cando_alice_bob_l2" = alice=0;
  label "cando_alice_bob_l2_branch" = false;
  label "cando_b_a_l1" = false;
  label "cando_b_a_l1_branch" = a=0;
  label "cando_b_a_l2" = false;
  label "cando_b_a_l2_branch" = a=0;
  label "cando_b_c_l1" = b=0;
  label "cando_b_c_l1_branch" = c=0;
  label "cando_b_c_l2" = b=0;
  label "cando_b_c_l2_branch" = c=0;
  label "cando_charlie_bob_l1" = charlie=0;
  label "cando_charlie_bob_l1_branch" = bob=0;
  label "cando_charlie_bob_l2" = charlie=0;
  label "cando_charlie_bob_l2_branch" = bob=0;
  label "cando_alice_bob_branch" = false;
  label "cando_b_a_branch" = a=0;
  label "cando_b_c_branch" = c=0;
  label "cando_charlie_bob_branch" = bob=0;
  P>=1 [ (G ((("cando_alice_bob_l1" & "cando_alice_bob_branch") => "cando_alice_bob_l1_branch") & ((("cando_alice_bob_l2" & "cando_alice_bob_branch") => "cando_alice_bob_l2_branch") & ((("cando_b_a_l1" & "cando_b_a_branch") => "cando_b_a_l1_branch") & ((("cando_b_a_l2" & "cando_b_a_branch") => "cando_b_a_l2_branch") & ((("cando_b_c_l1" & "cando_b_c_branch") => "cando_b_c_l1_branch") & ((("cando_b_c_l2" & "cando_b_c_branch") => "cando_b_c_l2_branch") & ((("cando_charlie_bob_l1" & "cando_charlie_bob_branch") => "cando_charlie_bob_l1_branch") & (("cando_charlie_bob_l2" & "cando_charlie_bob_branch") => "cando_charlie_bob_l2_branch"))))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: true
  
  Probabilistic deadlock freedom
  Result: 0.0 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.0
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
  
  endmodule
  
  module a
    a : [0..4] init 0;
    a_b_label : [0..3] init 0;
  
    [] a=4 -> 1:(fail'=true);
    [a_b] (a=0) & (fail=false) -> 0:(a'=4) + 0.6:(a'=1)&(a_b_label'=2) + 0.4:(a'=2)&(a_b_label'=3);
    [a_b_l2] a=1 -> 1:(a'=3)&(a_b_label'=0);
    [a_b_l1] a=2 -> 1:(a'=3)&(a_b_label'=0);
  endmodule
  
  module b
    b : [0..3] init 0;
  
    [] b=3 -> 1:(fail'=true);
    [a_b] (b=0) & (fail=false) -> 1:(b'=1);
    [a_b_l3] (b=1) & (a_b_label=1) -> 1:(b'=2);
    [a_b_l2] (b=1) & (a_b_label=2) -> 1:(b'=2);
    [a_b_l1] false -> 1:(b'=1);
  endmodule
  
  module c
    c : [0..4] init 0;
    c_d_label : [0..3] init 0;
  
    [] c=4 -> 1:(fail'=true);
    [c_d] (c=0) & (fail=false) -> 0:(c'=4) + 0.7:(c'=1)&(c_d_label'=2) + 0.3:(c'=2)&(c_d_label'=3);
    [c_d_l2] c=1 -> 1:(c'=3)&(c_d_label'=0);
    [c_d_l1] c=2 -> 1:(c'=3)&(c_d_label'=0);
  endmodule
  
  module d
    d : [0..3] init 0;
  
    [] d=3 -> 1:(fail'=true);
    [c_d] (d=0) & (fail=false) -> 1:(d'=1);
    [c_d_l3] (d=1) & (c_d_label=1) -> 1:(d'=2);
    [c_d_l2] (d=1) & (c_d_label=2) -> 1:(d'=2);
    [c_d_l1] false -> 1:(d'=1);
  endmodule
  
  label "end" = (a=3) & (b=2) & (c=3) & (d=2);
  label "cando_a_b_l1" = a=0;
  label "cando_a_b_l1_branch" = false;
  label "cando_a_b_l2" = a=0;
  label "cando_a_b_l2_branch" = b=0;
  label "cando_a_b_l3" = false;
  label "cando_a_b_l3_branch" = b=0;
  label "cando_c_d_l1" = c=0;
  label "cando_c_d_l1_branch" = false;
  label "cando_c_d_l2" = c=0;
  label "cando_c_d_l2_branch" = d=0;
  label "cando_c_d_l3" = false;
  label "cando_c_d_l3_branch" = d=0;
  label "cando_a_b_branch" = b=0;
  label "cando_c_d_branch" = d=0;
  P>=1 [ (G ((("cando_a_b_l1" & "cando_a_b_branch") => "cando_a_b_l1_branch") & ((("cando_a_b_l2" & "cando_a_b_branch") => "cando_a_b_l2_branch") & ((("cando_a_b_l3" & "cando_a_b_branch") => "cando_a_b_l3_branch") & ((("cando_c_d_l1" & "cando_c_d_branch") => "cando_c_d_l1_branch") & ((("cando_c_d_l2" & "cando_c_d_branch") => "cando_c_d_l2_branch") & (("cando_c_d_l3" & "cando_c_d_branch") => "cando_c_d_l3_branch"))))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.41999999999999993 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.41999999999999993
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  
  
  
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
  
  endmodule
  
  module alice
    alice : [0..8] init 0;
    alice_bob_label : [0..5] init 0;
  
    [] alice=8 -> 1:(fail'=true);
    [alice_bob] (alice=0) & (fail=false) -> 0:(alice'=8) + 0.1:(alice'=1)&(alice_bob_label'=1) + 0.3:(alice'=2)&(alice_bob_label'=4) + 0.6:(alice'=3)&(alice_bob_label'=5);
    [alice_bob_l5] alice=1 -> 1:(alice'=7)&(alice_bob_label'=0);
    [alice_bob_l2] alice=2 -> 1:(alice'=4)&(alice_bob_label'=0);
    [alice_bob_l1] alice=3 -> 1:(alice'=7)&(alice_bob_label'=0);
    [alice_bob] (alice=4) & (fail=false) -> 0:(alice'=8) + 0.1:(alice'=5)&(alice_bob_label'=2) + 0.9:(alice'=6)&(alice_bob_label'=3);
    [alice_bob_l4] alice=5 -> 1:(alice'=7)&(alice_bob_label'=0);
    [alice_bob_l3] alice=6 -> 1:(alice'=7)&(alice_bob_label'=0);
  endmodule
  
  module bob
    bob : [0..5] init 0;
  
    [] bob=5 -> 1:(fail'=true);
    [alice_bob] (bob=0) & (fail=false) -> 1:(bob'=1);
    [alice_bob_l5] false -> 1:(bob'=1);
    [alice_bob_l4] false -> 1:(bob'=1);
    [alice_bob_l3] false -> 1:(bob'=1);
    [alice_bob_l2] (bob=1) & (alice_bob_label=4) -> 1:(bob'=2);
    [alice_bob_l1] (bob=1) & (alice_bob_label=5) -> 1:(bob'=4);
    [alice_bob] (bob=2) & (fail=false) -> 1:(bob'=3);
    [alice_bob_l5] false -> 1:(bob'=3);
    [alice_bob_l4] false -> 1:(bob'=3);
    [alice_bob_l3] (bob=3) & (alice_bob_label=3) -> 1:(bob'=4);
    [alice_bob_l2] false -> 1:(bob'=3);
    [alice_bob_l1] false -> 1:(bob'=3);
  endmodule
  
  label "end" = (alice=7) & (bob=4);
  label "cando_alice_bob_l1" = alice=0;
  label "cando_alice_bob_l1_branch" = bob=0;
  label "cando_alice_bob_l2" = alice=0;
  label "cando_alice_bob_l2_branch" = bob=0;
  label "cando_alice_bob_l3" = alice=4;
  label "cando_alice_bob_l3_branch" = bob=2;
  label "cando_alice_bob_l4" = alice=4;
  label "cando_alice_bob_l4_branch" = false;
  label "cando_alice_bob_l5" = alice=0;
  label "cando_alice_bob_l5_branch" = false;
  label "cando_alice_bob_branch" = (bob=0) | (bob=2);
  P>=1 [ (G ((("cando_alice_bob_l1" & "cando_alice_bob_branch") => "cando_alice_bob_l1_branch") & ((("cando_alice_bob_l2" & "cando_alice_bob_branch") => "cando_alice_bob_l2_branch") & ((("cando_alice_bob_l3" & "cando_alice_bob_branch") => "cando_alice_bob_l3_branch") & ((("cando_alice_bob_l4" & "cando_alice_bob_branch") => "cando_alice_bob_l4_branch") & (("cando_alice_bob_l5" & "cando_alice_bob_branch") => "cando_alice_bob_l5_branch")))))) ]
  Pmin=? [ (G (("deadlock" | fail) => "end")) ]
  (Pmin=? [ (G (("deadlock" | fail) => "end")) ] / Pmin=? [ (G (!fail)) ])
  Pmin=? [ (F ("deadlock" | fail)) ]
  
   ======= Property checking =======
  
  Type safety
  Result: false
  
  Probabilistic deadlock freedom
  Result: 0.87 (exact floating point)
  
  Normalised probabilistic deadlock freedom
  Result: 0.87
  
  Probabilistic termination
  Result: 1.0 (exact floating point)
  
  

