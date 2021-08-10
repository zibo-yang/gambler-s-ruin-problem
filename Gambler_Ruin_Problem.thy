theory Gambler_Ruin_Problem
  imports DiscretePricing.Infinite_Coin_Toss_Space

begin
section\<open>Gambler's ruin problem\<close>

text\<open>In Gamblerruin.thy, we will construct the formalization of a specific random walk model coordinated with gambler's ruin problem.\<close>

subsection\<open>Theory Infinite{\_}Coin{\_}Toss{\_}Space\<close>
text\<open>In order to construct the formal method in gambler's ruin problem, we start with the existing 
formalization in the Theory Infinite{\_}Coin{\_}Toss{\_}Space which constructed the probability space 
on infinite sequences of independent coin.
tosses.\<close>



text\<open>The only concept need to be elaborated is bernoulli. 'a stream is a type of infinite sequence with all 
element of type 'a. The bernoulli stream is a stream measure which has the space composed of all the 
elements of type bool stream, measurable sets filled with all the subset of its space. under this 
specific measure, all the possibility of occurrence of elements in a specific set A can be described 
as the measure value of A if and only if A is in the measurable sets of this bernoulli stream. In fact, 
it was set up by producting countable measure of boolean space with measuring \{True\} to p and \{False\} 
to $1-p$.\<close>


subsection\<open>Gambler model\<close>
fun (in infinite_coin_toss_space) gambler_rand_walk_pre:: "int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> (nat \<Rightarrow> bool stream \<Rightarrow> int)" where
  base: "gambler_rand_walk_pre u d v 0 w = v"|
  step1: "gambler_rand_walk_pre u d v (Suc n) w = ((\<lambda>True \<Rightarrow> u | False \<Rightarrow> d) (snth w n)) + gambler_rand_walk_pre u d v n w"

fun (in infinite_coin_toss_space) gambler_rand_walk:: "int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> (enat \<Rightarrow> bool stream \<Rightarrow> int)" where
"gambler_rand_walk u d v n w = (case n of enat n \<Rightarrow> (gambler_rand_walk_pre u d v n w)|\<infinity> \<Rightarrow> -1)"

text\<open>The function $gambler\_ran\_walk$ extends the fourth parameter by adding $\infty$ as new input.
The reason why we define it is that we found it very tough to describe the position where the specific
random walk stops, for the first time, by reaching the threshold if natural number is the only allowed 
input as what $gambler\_ran\_walk\_pre$ defines. Since some infinite random walks will never stop, 
we must allocate $\infty$ as the output coordinated with that non-stop case and extend the type of 
steps from \isa{nat} to \isa{enat}. But if someone wants to base their further analysis on our endeavor here, 
please be cautious of or even avoid discussing the case that initial number and target number is 
negative since we map $\infty$ to -1. The lemma $exist$ demonstrates that non-stop random walk will
never succeed in reaching the target, which is the best explanation why we allocates $-1$ as the output
of $\infty$ in $gambler\_ran\_walk$.\<close>

locale gambler_model = infinite_coin_toss_space +
  fixes geom_proc::"int \<Rightarrow> bool stream \<Rightarrow> enat \<Rightarrow> int"
assumes geometric_process:"geom_proc init x step = gambler_rand_walk 1 (-1) init step x"

begin

subsection \<open>Basic functions\<close>
text\<open>Here we define the all basic functions which will play an invisible role in the further probability analysis.
you can just focus on the lemmas and functions where we comment\<close>
(*The first goal for us is to the conditional probability equation based on the specific identical
sets structure*)
definition reach_steps::"int \<Rightarrow> bool stream \<Rightarrow> int \<Rightarrow> nat set"where
"reach_steps init x target = {step::nat. geom_proc init x step \<in> {0,target}}"

text\<open>$reach\_steps$ describes all the steps where the input random walk reaches the threshold {0, target}\<close>

fun infm::"nat set \<Rightarrow> enat" where
"infm A = (if A = {} then \<infinity> else \<Sqinter> A)"

text\<open>infm A = {} iff A = {}\<close>
lemma only_inf_infm:
  assumes"A \<noteq> {}"
  shows"infm A \<noteq> \<infinity>"
proof
  assume "infm A = \<infinity>"
  then have l:"\<forall>a\<in>A. \<infinity> \<le> a"
    using infm.simps[of A] assms
    by auto
  then have r:"\<forall>a\<in>A. a < \<infinity>"
    using not_enat_eq enat_ord_simps not_infinity_eq
    by auto
  from l r show False
    using not_enat_eq enat_ord_simps not_infinity_eq
          assms equals0I 
    by fastforce
qed


fun stop_at::"int \<Rightarrow> bool stream \<Rightarrow> int \<Rightarrow> enat" where
"stop_at init x target = (infm (reach_steps init x target))"

text\<open>$stop\_at$ describes the first step in the $reach\_steps$ sets, which means exactly the stopping point in
gambler's ruin problem. Be careful, Here the type of output has been extended to \isa{enat}, which means
stopping point will be $\infty$(equivalent to non-existence)\<close>



fun success::"int \<Rightarrow> bool stream \<Rightarrow> int \<Rightarrow> bool"where
"success init x target = (geom_proc init x (stop_at init x target) = target)"

text\<open>success describes the random walk reaching the target number rather than ruining at stopping point\<close>


subsection\<open>Important intermediate conclusions\<close>

subsubsection\<open>Successful random walks never stop at $\infty$\<close>
text\<open>Once we set target to be positive, the weird situation where random walk succeeds at $\infty$ will disappear\<close>
lemma exist:
  fixes init::int and x and target::int 
  assumes "0 \<le> init" "init \<le> target""success init x target"
  shows "stop_at init x target \<noteq> \<infinity>"
proof
  assume "stop_at init x target = \<infinity>"
  from this have "geom_proc init x (stop_at init x target) = -1"
    using geometric_process by auto
  from this show "False"
    using assms by force
qed

subsubsection\<open>The way we count never change the amount got through specific random walk\<close>
lemma pre1:"\<And>x n. snth x (n+1) = snth (stl x) n "
  using snth.simps[of x] by auto

text\<open>lemma additional1 states that the reaching number doesn't change if we want to calculate from the second step\<close>
lemma additional1:"let init' = geom_proc init x 1 in 
geom_proc init' (stl x) n = geom_proc init x (Suc n)"
proof (induction n)
  show "let init' = geom_proc init x 1
    in geom_proc init' (stl x) (enat 0) = geom_proc init x (enat (Suc 0))"
  proof-
    have "let init' = geom_proc init x 1 in 
         geom_proc init' (stl x) (enat 0) = init'"
      using geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps
      by auto
    from this show "let init' = geom_proc init x 1
    in geom_proc init' (stl x) (enat 0) = geom_proc init x (enat (Suc 0))"
      by (metis One_nat_def one_enat_def)
  qed
next
  fix n
  assume ams:"let init' = geom_proc init x 1
         in geom_proc init' (stl x) (enat n) =
            geom_proc init x (enat (Suc n))"
  have ppp1:"\<And> init1 x1 n. geom_proc init1 x1 (Suc n) = geom_proc init1 x1 n + 
(case snth x1 n of True \<Rightarrow> 1| False \<Rightarrow> -1)"
    using geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps
    by auto
  from ams show "let init' = geom_proc init x 1
         in geom_proc init' (stl x) (enat (Suc n)) =
            geom_proc init x (enat (Suc (Suc n)))"
     using ppp1[of init x "Suc n"] 
           ppp1[of "geom_proc init x 1" "stl x" n]
           pre1[of x "Suc n"]
     by auto
 qed

 subsubsection\<open>The way we count never change whether the random walk succeeds\<close>
lemma set_up_Inf:
  fixes A and a::nat
  assumes "\<And>b::nat. b \<in> A \<Longrightarrow> a \<le> b" "a \<in> A"
  shows "a = Inf A"
  using assms(1) assms(2) cInf_eq_minimum 
  by blast

lemma Inf_property:
  fixes a and A
  assumes "a = Inf A"
  shows "\<And>b::nat. b \<in> A \<Longrightarrow> a \<le> b"
proof-
  have"bdd_below A"
    using bdd_below_def[of A]
    by auto
  then show "\<And>b. b \<in> A \<Longrightarrow> a \<le> b"
    using cInf_lower[of _ A] assms 
    by auto
qed
  
 
  text\<open>$conditional2\_pre$ states that stopping point doesn't change if we calculate from second step\<close>
lemma conditional2_pre:
  fixes init' and Ar and Al
  assumes "init' = geom_proc init x 1"
          "Ar = reach_steps init x target"
          "Al = reach_steps init' (stl x) target"
          "0 < init" 
          "init < target"
        shows" stop_at init' (stl x) target + 1 = stop_at init x target"

  proof (cases "Ar= {}")
    assume ar_empty:"Ar = {}"
    then have "\<not> (\<exists>n::nat. geom_proc init x n \<in> {0,target})"
      using assms(2) reach_steps_def[of init x target]
      by auto
    then have "\<not> (\<exists>m::nat. geom_proc init' (stl x) m \<in> {0,target})"
      using additional1[of init x] assms(1)
      by auto
    then have al_empty:"Al = {}"
      using assms(3) reach_steps_def[of init' "stl x"] 
      by auto
    from al_empty have al_inf:"stop_at init' (stl x) target = \<infinity>"
      using stop_at.simps assms
      by auto
    from ar_empty have ar_inf:"stop_at init x target = \<infinity>"
      using assms stop_at.simps
      by auto
    from al_inf ar_inf have"stop_at init' (stl x) target + 1 = stop_at init x target"
      using plus_enat_simps
      by auto
    then show ?thesis by auto
  next 
    assume ar_nonempty:"Ar \<noteq> {}"
    obtain a::nat where a_def:"a = stop_at init x target"
      unfolding stop_at.simps 
      using only_inf_infm[of Ar] ar_nonempty assms(2) not_infinity_eq[of "infm Ar"]
      by (auto simp add: not_infinity_eq)
    have "a \<noteq> 0" 
    proof
      assume "a = 0"
      then have "0 \<in> reach_steps init x target"
        using a_def stop_at.simps[of init x target]
              infm.simps[of "reach_steps init x target"]
              ar_nonempty
              assms(2)
              enat_0_iff[of a]
              enat.inject[of a "\<Sqinter> reach_steps init x target"]
              Inf_nat_def1[of Ar]
        by auto
      then have "geom_proc init x 0 \<in> {0,target}"
        using reach_steps_def[of init x target]
        by (simp add: zero_enat_def)
      then have "init \<in> {0,target}"
        using geometric_process[of init x 0] 
              gambler_rand_walk.simps[of 1 "-1" init 0 x]
        by (simp add: zero_enat_def)
      then have False
        using assms by auto
      then show False
        by auto
    qed
    obtain a'::nat where "a' + 1 = a "
        using \<open>a \<noteq> 0\<close> 
        by (metis (no_types) add.commute add.left_neutral add_Suc_right assms less_imp_Suc_add less_one not_less_eq not_less_less_Suc_eq)
    then have "a' \<in> reach_steps init' (stl x) target"
    proof(unfold reach_steps_def)
      assume "a' + 1 = a"
      then have "geom_proc init' (stl x) a' \<in> {0, target}"
        using additional1[of init x a'] 
              a_def 
              stop_at.simps[of init x target] 
              infm.simps[of "reach_steps init x target"]
              Inf_nat_def1[of "reach_steps init x target"]
              assms(2)
              ar_nonempty
              enat.inject[of a "\<Sqinter> reach_steps init x target"]
              reach_steps_def[of init x target]
        by (metis (no_types, lifting) add.commute assms(1) mem_Collect_eq plus_1_eq_Suc)
      then show "a' \<in> {xa. geom_proc init' (stl x) (enat xa) \<in> {0, target}}"
        using \<open>a' + 1 = a\<close> by force
    qed 
    then have "reach_steps init' (stl x) target \<noteq> {}"
      by auto
    have"\<And>a b A::nat set. b \<in> A \<Longrightarrow> a = Inf A \<Longrightarrow> a \<le> b"
    proof-
      fix a::nat and b::nat and A
      assume "b \<in> A" and "a = Inf A"
      have "bdd_below A"
        using bdd_below_def[of A]
        by auto
      then show "a \<le> b"
        using cInf_lower[of b A] \<open>a = Inf A\<close> \<open>b \<in> A\<close>
        by auto
      qed
    have "\<And>b. b \<in> reach_steps init' (stl x) target \<Longrightarrow> a' \<le> b"
    proof(unfold reach_steps_def)
      fix b
      assume "b \<in> {xa. geom_proc init' (stl x) (enat xa) \<in> {0, target}}"
      then have "geom_proc init' (stl x) b \<in> {0,target}"
        by auto
      then have "geom_proc init x (b+1) \<in> {0,target}"
        using additional1[of init x b] assms(1) 
        by auto
      then have "(b + 1) \<in> reach_steps init x target"
        using reach_steps_def[of init x target] 
        by auto
      then have "a \<le> (b + 1)"
        using a_def 
              stop_at.simps[of init x target] 
              infm.simps[of "reach_steps init x target"]
              \<open>Ar \<noteq> {}\<close>
              assms(2)
              enat.inject[of a "\<Sqinter> reach_steps init x target"]
              \<open>\<And>a b A::nat set. b \<in> A \<Longrightarrow> a = Inf A \<Longrightarrow> a \<le> b\<close>
        by auto
      then show "a' \<le> b"
        using \<open>a' + 1 = a\<close> 
        by force
    qed
    then have "a' = \<Sqinter> (reach_steps init' (stl x) target)"
      unfolding reach_steps_def
      using cInf_eq_minimum[of a' "{xa. geom_proc init' (stl x) (enat xa) \<in> {0, target}}"]
            \<open>a' \<in> reach_steps init' (stl x) target\<close>
            reach_steps_def[of init' "stl x" target]
      by auto
    then have "a' = stop_at init' (stl x) target"
      unfolding stop_at.simps
      using \<open>reach_steps init' (stl x) target \<noteq> {}\<close>
      by auto
    then show "stop_at init' (stl x) target + 1 = stop_at init x target"
      using \<open>a = stop_at init x target\<close>
            \<open>a' + 1 = a\<close>
      by (metis one_enat_def plus_enat_simps(1)) 
  qed


text\<open>conditional2 states that whether a random walk succeeds or not doesn't change if we calculate from second step\<close>

lemma conditional2:
  fixes init x target
  assumes "init' = geom_proc init x 1"
          "0 < init" 
          "init < target"
  shows "success init' (stl x) target \<longleftrightarrow> success init x target"
proof
  obtain ar where "ar = reach_steps init x target"
    by blast
  obtain al where "al = reach_steps init' (stl x) target"
    by blast
  assume lhs:"success init' (stl x) target"
  then have lhs1:"geom_proc init' (stl x) (stop_at init' (stl x) target) = target"
    using success.simps 
    by auto
  then have "stop_at init' (stl x) target \<noteq> \<infinity>"
    using exist[of init' target "stl x"] 
          success.simps[of init' "stl x" target]
          assms
          geometric_process[of init x 1]
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
          gambler_rand_walk_pre.simps
    using geometric_process by auto
  then obtain a::nat where "a = stop_at init' (stl x) target"
    using not_infinity_eq
    by auto
  with lhs1 have "geom_proc init x (stop_at init x target) = target"
    using conditional2_pre[of init' init x ar target al]
          assms
          \<open>ar = reach_steps init x target\<close>
          \<open>al = reach_steps init' (stl x) target\<close>
          additional1[of init x a]
    by (metis Suc_eq_plus1 one_enat_def plus_enat_simps(1))
  then show "success init x target"
    using success.simps 
    by auto
next 
  obtain ar where "ar = reach_steps init x target"
    by blast
  obtain al where "al = reach_steps init' (stl x) target"
    by blast
  assume rhs:"success init x target"
  then have rhs1:"geom_proc init x (stop_at init x target) = target"
    using success.simps
    by auto
  then have "stop_at init x target \<noteq> \<infinity>"
    using exist[of init target x] 
          success.simps[of init x target]
          assms
          geometric_process[of init x 1]
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
          gambler_rand_walk_pre.simps
    using geometric_process 
    by auto
  then obtain a'::nat where "a' = stop_at init x target"
    using not_infinity_eq
    by auto
  have "a' \<noteq> 0"
  proof 
    assume "a' = 0"
    then have "geom_proc init x a' = init"
      by (metis \<open>enat a' = stop_at init x target\<close> add.commute add.right_neutral assms(2) assms(3) conditional2_pre enat_add_left_cancel_less gr_implies_not_zero zero_enat_def zero_less_one)
    then show False
      using rhs1 
            assms
            \<open>a' = stop_at init x target\<close>
      by auto
  qed
  then obtain a::nat where "a + 1 = a'"
    by (metis Suc_eq_plus1 old.nat.exhaust)
  with rhs1 have "geom_proc init' (stl x) (stop_at init' (stl x) target) = target"
  proof-
    have "stop_at init' (stl x) target + 1 = stop_at init x target"
      using conditional2_pre[of init' init x ar target al]
            assms
            \<open>ar = reach_steps init x target\<close>
            \<open>al = reach_steps init' (stl x) target\<close>
      by auto
    then have "a = stop_at init' (stl x) target"
      using \<open>a' = stop_at init x target\<close>
            \<open>a + 1 = a'\<close>
            eSuc_enat[of a]
      by (metis Suc_eq_plus1 eSuc_inject plus_1_eSuc(2)) 
    then have "geom_proc init' (stl x) (stop_at init' (stl x) target) = geom_proc init x (stop_at init x target)"
      using additional1[of init x a]
      by (metis Suc_eq_plus1 \<open>a + 1 = a'\<close> \<open>enat a' = stop_at init x target\<close> assms(1))    
    with rhs1 show "geom_proc init' (stl x) (stop_at init' (stl x) target) = target"
      by auto
  qed
  then show "success init' (stl x) target"
    using success.simps 
    by auto
qed

subsubsection\<open>The change of initial number\<close>
text\<open>if first step is true, then we add 1 to initial number\<close>
lemma fst_true_plus_one:
  fixes init x target
  assumes "init' = geom_proc init x 1""shd x = True"
  shows "init' = init + 1"
proof-
  have int1:"gambler_rand_walk 1 (- 1) init 1 x = 1 + gambler_rand_walk_pre 1 (- 1) init 0 x"
    using snth.simps(1)[of x]
          gambler_rand_walk_pre.simps(1)[of 1 "-1" init x]
          gambler_rand_walk_pre.simps(2)[of 1 "-1" init 0 x]
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
          one_enat_def zero_enat_def
          gambler_rand_walk.simps[of 1 "-1" init 0 x]
          assms
    by (simp add: one_enat_def)
  have int2:"gambler_rand_walk_pre 1 (- 1) init 0 x = init"
    using gambler_rand_walk_pre.simps(1)[of 1 "-1" init x]
    by auto
  have int3:"gambler_rand_walk 1 (- 1) init 1 x = init'"
    using geometric_process[of init x 1]
          assms(1)
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
    by auto
  show "init' = init + 1"
    using int1 int2 int3
    by auto
qed

text\<open>if first step is False, then we reduce 1 to initial number\<close>
lemma fst_true_plus_one_false:
  fixes init x target
  assumes "init' = geom_proc init x 1""shd x = False"
  shows "init' = init - 1"
proof-
  have int1:"gambler_rand_walk 1 (- 1) init 1 x = (gambler_rand_walk_pre 1 (- 1) init 0 x) - 1"
    using snth.simps(1)[of x]
          gambler_rand_walk_pre.simps(1)[of 1 "-1" init x]
          gambler_rand_walk_pre.simps(2)[of 1 "-1" init 0 x]
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
          one_enat_def zero_enat_def
          gambler_rand_walk.simps[of 1 "-1" init 0 x]
          assms
    by (simp add: one_enat_def)
  have int2:"gambler_rand_walk_pre 1 (- 1) init 0 x = init"
    using gambler_rand_walk_pre.simps(1)[of 1 "-1" init x]
    by auto
  have int3:"gambler_rand_walk 1 (- 1) init 1 x = init'"
    using geometric_process[of init x 1]
          assms(1)
          gambler_rand_walk.simps[of 1 "-1" init 1 x]
    by auto
  show "init' = init - 1"
    using int1 int2 int3
    by auto
qed

subsubsection\<open>The way we count never change the successful random walk set\<close> 
text\<open>the set where all random walks in it succeeds and their first step are True doesn't change if 
we calculate from second step\<close>
lemma conditional_set_equation:
  fixes init  target
  assumes 
          "0 < init" 
          "init < target"
  shows
"{x::bool stream. success init x target \<and> shd x = True} = 
 {x::bool stream. success (init+1) (stl x) target \<and> shd x = True}"
proof
  show "{x. success init x target \<and> shd x = True}
    \<subseteq> {x. success (init + 1) (stl x) target \<and> shd x = True}"
  proof
    fix x
    assume "x \<in> {x. success init x target \<and> shd x = True}" 
    then have "success init x target"" shd x = True"
      by auto
    obtain init' where "init' = geom_proc init x 1"
      by blast
    with \<open>shd x = True\<close> have "init' = init + 1"
      using fst_true_plus_one[of init' init x]
            assms(1)
      by auto
    then have "success (init + 1) (stl x) target \<and> shd x = True"
      using conditional2[of init' init x target] 
            assms
            \<open>init' = geom_proc init x 1\<close>
            \<open>shd x = True\<close>
            \<open>success init x target\<close>
      by auto
    then show "x \<in> {x. success (init + 1) (stl x) target \<and> shd x = True}"
      by auto
  qed
next 
  show "{x. success (init + 1) (stl x) target \<and> shd x = True}
    \<subseteq> {x. success init x target \<and> shd x = True}"
  proof
    fix x
    assume "x \<in> {x. success (init + 1) (stl x) target \<and> shd x = True}"
    then have "success (init + 1) (stl x) target""shd x = True"
      by auto
    obtain init' where "init' = geom_proc init x 1"
      by blast
    with \<open>shd x = True\<close> have "init' = init + 1"
      using fst_true_plus_one[of init' init x]
            assms(1)
      by auto
    then have "success init x target \<and> shd x = True"
      using conditional2[of init' init x target] 
            assms
            \<open>init' = geom_proc init x 1\<close>
            \<open>shd x = True\<close>
            \<open>success (init + 1) (stl x) target\<close>
      by auto
    then show "x \<in> {x. success init x target \<and> shd x = True}"
      by auto
  qed
qed

text\<open>the set where all random walks in it succeeds and their first step are False doesn't change if 
we calculate from second step\<close>
lemma conditional_set_equation_false:
  fixes init  target
  assumes 
          "0 < init" 
          "init < target"
  shows
"{x::bool stream. success init x target \<and> shd x = False} = 
 {x::bool stream. success (init-1) (stl x) target \<and> shd x = False}"
proof
  show "{x. success init x target \<and> shd x = False}
    \<subseteq> {x. success (init - 1) (stl x) target \<and> shd x = False}"
  proof
    fix x
    assume "x \<in> {x. success init x target \<and> shd x = False}" 
    then have "success init x target"" shd x = False"
      by auto
    obtain init' where "init' = geom_proc init x 1"
      by blast
    with \<open>shd x = False\<close> have "init' = init - 1"
      using fst_true_plus_one_false[of init' init x]
            assms(1)
      by auto
    then have "success (init - 1) (stl x) target \<and> shd x =  False"
      using conditional2[of init' init x target] 
            assms
            \<open>init' = geom_proc init x 1\<close>
            \<open>shd x = False\<close>
            \<open>success init x target\<close>
      by auto
    then show "x \<in> {x. success (init - 1) (stl x) target \<and> shd x = False}"
      by auto
  qed
next 
  show "{x. success (init - 1) (stl x) target \<and> shd x = False}
    \<subseteq> {x. success init x target \<and> shd x = False}"
  proof
    fix x
    assume "x \<in> {x. success (init - 1) (stl x) target \<and> shd x = False}"
    then have "success (init - 1) (stl x) target""shd x = False"
      by auto
    obtain init' where "init' = geom_proc init x 1"
      by blast
    with \<open>shd x = False\<close> have "init' = init - 1"
      using fst_true_plus_one_false[of init' init x]
            assms(1)
      by auto
    then have "success init x target \<and> shd x = False"
      using conditional2[of init' init x target] 
            assms
            \<open>init' = geom_proc init x 1\<close>
            \<open>shd x = False\<close>
            \<open>success (init - 1) (stl x) target\<close>
      by auto
    then show "x \<in> {x. success init x target \<and> shd x = False}"
      by auto
  qed
qed

subsection \<open>Probability equation\<close>

text\<open>Here we start to analyse the probability of successful random walk. To better understand this
part please have a look the elaboration in front of lemma $success\_measurable$\<close>

text\<open>$probability\_of\_win$ is the function describing possibility of successful random walks with 
initial number and target number as inputs\<close>

fun probability_of_win::"int \<Rightarrow> int \<Rightarrow> ennreal"where
"probability_of_win init target = emeasure M {x\<in> space M. success init x target}"

subsubsection\<open>Successful random walk set is measurable\<close>


text\<open>Preimage of function snth is measurable\<close>
lemma snth_measurable:
  fixes n::nat
  shows"\<And>k. (\<lambda>w. snth w n) -` {k} \<in> sets M"
proof-
  fix k
  have "(\<lambda>w. snth w n) \<in> measurable M (measure_pmf (bernoulli_pmf p))" 
    using bernoulli  p_gt_0  p_lt_1
    by (simp add: bernoulli_stream_def)
  moreover have "{k} \<in> sets (measure_pmf (bernoulli_pmf p))" 
    by simp
  ultimately show "(\<lambda>w. snth w n) -` {k} \<in> sets M" 
    using measurable_sets[of "\<lambda>w. snth w n" M "measure_pmf (bernoulli_pmf p)" "{k}"]
          bernoulli_stream_preimage[of M p "\<lambda>w. snth w n" "{k}"]
          bernoulli
    by force
qed


lemma stake_measurable_pre1:
  fixes n w k
  assumes "length k > n"
  shows "stake (Suc n) w = take (Suc n) k \<longleftrightarrow> stake n w = take n k \<and> snth w n = nth k n"
proof
  assume "stake (Suc n) w = take (Suc n) k"
  then show "stake n w = take n k \<and> w !! n = k ! n"
    using take_hd_drop[of n k]
          stake_Suc[of n w]
          assms
          append_eq_append_conv[of "stake n w" "take n k""[snth w n]""[nth k n]" ]
          length_take[of n k]
          length_stake[of n w]
          Lattices.linorder_class.min.absorb_iff2[of n "length k"]
    by (metis append1_eq_conv hd_drop_conv_nth)
next
  assume "stake n w = take n k \<and> snth w n = nth k n"
  then show "stake (Suc n) w = take (Suc n) k"
    using take_hd_drop[of n k]
          stake_Suc[of n w]
          assms
          append_eq_append_conv[of "stake n w" "take n k""[snth w n]""[nth k n]" ]
          length_take[of n k]
          length_stake[of n w]
          Lattices.linorder_class.min.absorb_iff2[of n "length k"]
    by (metis take_Suc_conv_app_nth)
qed



lemma stake_measurable_pre:
  fixes n
  shows"\<And>k. length k \<ge> n \<Longrightarrow> (stake n -` {k}) \<in> sets M"
proof(induction n)
  fix k
  show "(stake 0 -` {k}) \<in> sets M"
    proof (cases k)
      assume "k = []"
      have "\<forall>w. stake 0 w = []"
        by auto
      then have "(stake 0 -` {k}) = space M"
        using bernoulli_stream_space[of M p]
              bernoulli
              \<open>k = []\<close> 
        by fastforce
      then show "(stake 0 -` {k}) \<in> sets M"
        by auto
    next 
      fix a list
      assume" k = a # list"
      then have "k \<noteq> []"
        by auto
      have "\<forall>w. stake 0 w = []"
        by auto
      then have "(stake 0 -` {k}) = {}"
        using \<open>k \<noteq> []\<close>
        by force
      then show "(stake 0 -` {k}) \<in> sets M"
        by auto
    qed
next 
  fix n k
  assume "\<And>k1. n \<le> length k1 \<Longrightarrow> (stake n -` {k1}) \<in> sets M" 
  thus "Suc n \<le> length k \<Longrightarrow> stake (Suc n) -` {k} \<in> events"
  proof(cases "Suc n = length k")
    assume "Suc n \<le> length k""Suc n = length k"
    have "(stake (Suc n) -` {take (Suc n) k}) = (stake n -` {take n k}) \<inter> ((\<lambda>w. snth w n) -` {nth k n})"
    proof
        show "stake (Suc n) -` {take (Suc n) k}
      \<subseteq> stake n -` {take n k} \<inter> (\<lambda>w. w !! n) -` {k ! n}"
        proof
          fix w
          assume "w \<in> stake (Suc n) -` {take (Suc n) k}"
          then have "stake (Suc n) w = take (Suc n) k"
            by auto
          then have "stake n w = take n k"
            using stake_measurable_pre1[of n k w]
                  \<open>Suc n \<le> length k\<close>
            by auto
          have "snth w n = nth k n"
            using stake_measurable_pre1[of n k w]
                  \<open>Suc n \<le> length k\<close>
                  \<open>stake (Suc n) w = take (Suc n) k\<close>
            by auto
          show "w \<in> (stake n -` {take n k}) \<inter> ((\<lambda>w. snth w n) -` {nth k n})"
            using \<open>snth w n = nth k n\<close>
                  \<open>stake n w = take n k\<close>
            by auto
        qed
      next 
        show "stake n -` {take n k} \<inter> (\<lambda>w. w !! n) -` {k ! n}
      \<subseteq> stake (Suc n) -` {take (Suc n) k}"
        proof 
          fix w
          assume "w \<in> (stake n -` {take n k}) \<inter> ((\<lambda>w. snth w n) -` {nth k n})"
          then have "snth w n = nth k n""stake n w = take n k"
            by auto
          then have "stake (Suc n) w = take (Suc n) k"
            using stake_measurable_pre1[of n k w]
                  \<open>Suc n \<le> length k\<close>
            by auto
          then show "w \<in> stake (Suc n) -` {take (Suc n) k}"
            by auto
        qed
      qed
      moreover have "take (Suc n) k = k"
        using take_all[of k "Suc n"]
             \<open>Suc n = length k\<close>
        by auto
      moreover have "stake n -` {take n k} \<in> sets M"
        using \<open>\<And>k1. n \<le> length k1 \<Longrightarrow> (stake n -` {k1}) \<in> sets M\<close>
              \<open>Suc n = length k\<close>
        by auto
      moreover have "((\<lambda>w. snth w n) -` {nth k n}) \<in> sets M "
        using snth_measurable
        by auto
      ultimately show "stake (Suc n) -` {k} \<in> events"
        by simp
    next
      assume "Suc n \<le> length k""Suc n \<noteq> length k"
      then have "Suc n < length k"
        by auto
      then have "stake (Suc n) -` {k} = {}"
      proof-
        have "\<And>k1 . length k1 < length k \<Longrightarrow> k1 \<noteq> k"
          by auto
        then have "\<And>w. stake (Suc n) w \<noteq> k"
          using length_stake[of "Suc n" w]
                \<open>Suc n < length k\<close>
          by auto
        then show "stake (Suc n) -` {k} = {}"
          by force
      qed
      then show "stake (Suc n) -` {k} \<in> events"
        by auto
    qed
  qed


text\<open>The preimage of any list over function stake is measurable\<close>
lemma stake_measurable:
  fixes n k
  shows"(stake n -` {k}) \<in> sets M"
proof (cases "length k \<ge> n")
  assume "length k \<ge> n"
  then show "(stake n -` {k}) \<in> sets M"
    using stake_measurable_pre[of n k]
    by auto
next 
  assume "\<not> n \<le> length k"
  then have "length k < n"
    by auto
  then have "stake n -` {k} = {}"
    proof-
      have "\<And>k1 . length k1 > length k \<Longrightarrow> k1 \<noteq> k"
        by auto
      then have "\<And>w. stake n w \<noteq> k"
        using length_stake[of n  w]
              \<open>length k < n\<close>
        by auto
      then show "stake n -` {k} = {}"
        by force
    qed
    then show "(stake n -` {k}) \<in> sets M"
      using UN_empty2[of l]
      by auto
  qed

  text\<open>The preimage of any list set over function stake is measurable once the set is finite\<close>
lemma finite_stake_measurable:
  fixes A and n::nat
  assumes"finite A"
  shows"(stake n -` A) \<in> sets M"
proof-
  have "(\<Union>x\<in>A. (stake n -` {x})) = (stake n -` A)"
    by auto
  then show "(stake n -` A) \<in> sets M"
    using stake_measurable
          assms
    by (metis sets.finite_UN)
qed

text\<open>The new $geom\_proc$ function for list\<close>
fun geom_proc_list::"int \<Rightarrow> bool list \<Rightarrow> int"where
"geom_proc_list init [] = init"|
"geom_proc_list init (x # xs) = (case x of True\<Rightarrow>1|False \<Rightarrow> -1) + geom_proc_list init xs"


lemma reverse_construct_pre:
  fixes init lengthx y
  shows "\<And>x::bool list. lengthx = length x \<Longrightarrow>  geom_proc_list init (x @ [y]) = geom_proc_list init x + (case y of True\<Rightarrow>1|False\<Rightarrow> -1)"
proof(induction "lengthx")
  show "\<And>x. 0 = length x \<Longrightarrow>
         geom_proc_list init (x @ [y]) =
         geom_proc_list init x +
         (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)"
    by force
next
  fix lengthx x
  assume" (\<And>x1. lengthx = length x1 \<Longrightarrow>
           geom_proc_list init (x1 @ [y]) =
           geom_proc_list init x1 +
           (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1))"
  then show "Suc lengthx = length x \<Longrightarrow>
          geom_proc_list init (x @ [y]) =
          geom_proc_list init x +
          (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)"
  proof-
    assume"Suc lengthx = length x"
"\<And>x1. lengthx = length x1 \<Longrightarrow>
           geom_proc_list init (x1 @ [y]) =
           geom_proc_list init x1 +
           (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)"
    have "geom_proc_list init (x @ [y]) = geom_proc_list init (hd x # (tl x @ [y]))"
      by (smt (verit, del_insts) Nil_is_append_conv \<open>Suc lengthx = length x\<close> hd_Cons_tl hd_append2 length_Suc_conv list.discI tl_append2)
    moreover have "geom_proc_list init (hd x # (tl x @ [y])) = (case hd x of True\<Rightarrow>1|False\<Rightarrow> -1) + geom_proc_list init (tl x @ [y])"
      using geom_proc_list.simps
      by auto
    moreover have "geom_proc_list init (tl x @ [y]) = geom_proc_list init (tl x) +
           (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)"
      using \<open>Suc lengthx = length x\<close> \<open>\<And>x1. lengthx = length x1 \<Longrightarrow> geom_proc_list init (x1 @ [y]) = geom_proc_list init x1 + (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)\<close> 
      by fastforce
    moreover have "geom_proc_list init (tl x) + (case hd x of True\<Rightarrow>1|False\<Rightarrow> -1) = geom_proc_list init x"
      by (metis \<open>Suc lengthx = length x\<close> add.commute geom_proc_list.simps(2) hd_Cons_tl length_Suc_conv list.discI)
    ultimately show "geom_proc_list init (x @ [y]) =
          geom_proc_list init x +
          (case y of True \<Rightarrow> 1 | False \<Rightarrow> - 1)"
      by auto
  qed
qed

lemma reverse_construct:
  fixes init x y
  shows "geom_proc_list init (x @ [y]) = geom_proc_list init x + (case y of True\<Rightarrow>1|False\<Rightarrow> -1)"
  using reverse_construct_pre[of "length x" x init y]
  by auto

lemma success_pre:
  fixes init x target i
  assumes "0 < init""init < target" 
  shows "geom_proc_list init (stake i x) = geom_proc init x i"
proof(induction i)
  show "geom_proc_list init (stake 0 x) = geom_proc init x (enat 0)"
    using stake.simps(1)[of x]
          geom_proc_list.simps(1)[of init]
          geometric_process[of init x "enat 0"]
          gambler_rand_walk.simps(1)[of 1 "-1" init "enat 0" x]
          gambler_rand_walk_pre.simps(1)[of 1 "-1" init x]
          enat_0
          enat.simps(4)[of "\<lambda>n. gambler_rand_walk_pre 1 (- 1) init n x" "-1" 0]
    by auto
next
  fix i
  assume "geom_proc_list init (stake i x) = geom_proc init x i"
  have "geom_proc_list init (stake (Suc i) x) = geom_proc_list init (stake i x @ [x !! i ])"
    using stake_Suc[of i x]
    by auto
  moreover have "geom_proc_list init (stake i x @ [x !! i ]) = geom_proc_list init (stake i x) + (case x !! i of True\<Rightarrow>1|False\<Rightarrow> -1)"
    using reverse_construct[of init "stake i x" "x !! i"]
    by auto
  moreover have "geom_proc_list init (stake i x) = geom_proc init x i"
    using \<open>geom_proc_list init (stake i x) = geom_proc init x i\<close>
    by auto
  moreover have " geom_proc init x (Suc i) = geom_proc init x i + (case x !! i of True\<Rightarrow>1|False\<Rightarrow> -1)"
    using geometric_process
    by auto
  ultimately show "geom_proc_list init (stake (Suc i) x) = geom_proc init x (Suc i)"
    by auto
qed

text\<open>Any natural number smaller than Inf A doesn't belong to A\<close>
lemma not_belong:
  fixes A and a::nat
  assumes "\<Sqinter> A > a"
  shows "a \<notin> A"
proof
  assume "a \<in> A"
  then have "a \<ge> \<Sqinter> A"
    using Inf_property[of _ A a]
    by auto
  then show False
    using assms
    by auto
qed
    
text\<open>This is the most important intermediate lemma prepared for lemma $success\_measurable. It clarifies
that any list in the image of successful random walk over function stake will never contain another 
shorter list corresponding to another successful random walk$\<close>
lemma success_measurable2:
  fixes init target and i::nat
  assumes "0 < init""init < target" "0 \<le> i"
  shows"{x\<in> space M. success init x target \<and> stop_at init x target = i}
= stake i -` {c::bool list. (\<forall>k<i. (geom_proc_list init (take k c)) \<notin> {0,target})\<and> length c = i \<and> geom_proc_list init c = target}"
proof
  show " {x \<in> space M. success (init) x (target) \<and> stop_at (init) x (target) = enat i}
    \<subseteq> stake i -` {c. (\<forall>k<i. geom_proc_list (init) (take k c) \<notin> {0, target}) \<and> length c = i \<and> geom_proc_list (init) c = target}"
  proof
    fix x
    assume "x \<in> {x \<in> space M. success (init) x (target) \<and> stop_at (init) x (target) = enat i}"
    then have lhs1:"success (init) x (target)"and lhs2:"stop_at (init) x (target) = enat i"
      by auto
    then have "geom_proc init x i = target"
      by auto
    then have "geom_proc_list init (stake i x) = target"
      using success_pre[of init target i x]
            assms
      by auto
    with lhs2 have "\<forall>k<i. geom_proc_list (init) (take k (stake i x)) \<notin> {0, target}" 
    proof-
      have"\<forall>k<i. take k (stake i x) = stake k x"
        using take_stake
        by (simp add: take_stake min.strict_order_iff)
      then have "\<forall>k<i. geom_proc_list (init) (take k (stake i x)) = geom_proc_list init (stake k x)"
        by auto
      then have "\<forall>k<i. geom_proc_list (init) (take k (stake i x)) = geom_proc init x k"
      using success_pre[of init target _ x]
            assms 
      by auto
    have nonempty:"reach_steps (init) x
       (target) \<noteq> {}"
      using \<open>geom_proc init x i = target\<close>
            reach_steps_def[of init x target]
      by auto
    then have "\<forall>k<i. geom_proc init x k \<notin> {0, target}"
      using lhs2 stop_at.simps[of init x target]
            infm.simps[of "reach_steps init x target"]
            not_belong[of _ "reach_steps init x target"]
            reach_steps_def[of init x target]
      by (metis enat.inject mem_Collect_eq)
    then show "\<forall>k<i. geom_proc_list (init) (take k (stake i x)) \<notin> {0, target}"
      using \<open>\<forall>k<i. geom_proc init x k \<notin> {0, target}\<close>
            \<open>\<forall>k<i. geom_proc_list (init) (take k (stake i x)) = geom_proc init x k\<close>
      by auto
  qed
  have "length (stake i x) = i"
    by (simp add:length_stake)
  then show "x \<in> stake i -` {c. (\<forall>k<i. geom_proc_list (init) (take k c) \<notin> {0,target}) \<and> length c = i \<and> geom_proc_list (init) c = target}"
    using \<open>\<forall>k<i. geom_proc_list (init) (take k (stake i x)) \<notin> {0, target}\<close>
          \<open>geom_proc_list init (stake i x) = target\<close>
    by auto
qed
  next
    show "stake i -` {c. (\<forall>k<i. geom_proc_list (init) (take k c) \<notin> {0,target}) \<and> length c = i \<and> geom_proc_list (init) c = target}
    \<subseteq> {x \<in> space M. success (init) x (target) \<and> stop_at (init) x (target) = enat i}"
    proof 
      fix x 
      assume "x \<in> stake i -` {c. (\<forall>k<i. geom_proc_list (init) (take k c) \<notin> {0, target}) \<and> length c = i \<and> geom_proc_list (init) c = target}"
      then have rhs1:"\<forall>k<i. geom_proc_list (init) (take k (stake i x)) \<notin> {0, target}"and 
                rhs2:"length (stake i x) = i" and 
                rhs3:"geom_proc_list (init) (stake i x) = target" 
        by auto
      from rhs3 have "geom_proc init x i = target"
        using success_pre[of init target i x] assms
        by auto
      then have "reach_steps init x target \<noteq> {}"
        unfolding reach_steps_def
        by auto
      from rhs1 have "\<forall>k<i. geom_proc init x k \<notin> {0, target}"
        using success_pre[of init target _ x] 
              assms
              take_stake[of _ i x]
              min.strict_order_iff[of _ i]
        by force
      then have "stop_at (init) x (target) = enat i"
      proof 
        have "stop_at (init) x (target) = Inf (reach_steps init x target) "
          using \<open>reach_steps init x target \<noteq> {}\<close>
                stop_at.simps[of init x target]
                infm.simps[of "reach_steps init x target"]
          by auto
        moreover have "i \<in> reach_steps init x target"
          using \<open>geom_proc init x i = target\<close>
                reach_steps_def[of init x target]
          by auto
        moreover have "\<forall>k<i. k \<notin> reach_steps init x target"
          using \<open>\<forall>k<i. geom_proc init x k \<notin> {0, target}\<close>
                reach_steps_def[of init x target]
          by auto
        moreover have "Inf (reach_steps init x target) = i"
          using  
                \<open>i \<in> reach_steps init x target\<close>
                \<open>\<forall>k<i. k \<notin> reach_steps init x target\<close>
          by (metis le_refl nat_less_le nat_neq_iff set_up_Inf)
        ultimately show "stop_at (init) x ( target) = enat i"
          by auto
      qed
      then have "success init x target"
        unfolding success.simps
        using \<open>geom_proc init x i = target\<close>
        by auto
      then have "\<forall>x::bool stream. x \<in> space M"
        using bernoulli_stream_space[of M p]
              bernoulli 
        by auto       
      then show"x \<in> {x \<in> space M. success (init) x (target) \<and> stop_at (init) x (target) = enat i}"
        using \<open>stop_at (init) x (target) = enat i\<close>
              \<open>success init x target\<close>
        by auto
    qed
  qed

lemma stake_space:"stake n ` space M = {c::bool list. length c = n}"
proof
  show" stake n ` space M \<subseteq> {c::bool list. length c = n}"
  proof 
    fix x
    assume " x \<in> stake n ` space M"
    then show "x \<in> {c::bool list. length c = n}"
      using length_stake
      by force
  qed
next
  show"{c::bool list. length c = n} \<subseteq> stake n ` space M "
  proof 
    fix x
    assume"x \<in> {c::bool list. length c = n}"
    then have "length x = n"
      by auto
    obtain k where "shd k = True"
      by (metis stream.sel(1))
    then obtain k1 where"k1 = x @- k"
      by blast
    then have "stake n k1 = x"
      using stake_shift[of n x k]
      \<open>length x = n\<close>
      take_all[of x n]
      stake.simps(1)[of k]
      by auto
    then obtain k2 where "stake n k2 = x"
      using length_stake[of n _]
      by auto
    then have "k2 \<in> space M"
      using bernoulli
            bernoulli_stream_space[of M p]
      by auto
    then show " x \<in> (stake n ` space M)"
      using \<open>stake n k2 = x\<close>
      by auto
  qed
qed


text\<open>Set of all the lists with specific length is finite\<close>
lemma finite_length:"finite {c::bool list. length c = n}"
proof-
  let ?U = "UNIV::bool set"
  have "?U = {True, False}" 
    by auto
  hence "finite ?U" 
    by simp
  moreover have "?U \<noteq> {}"
    by auto
  ultimately have fi: "finite (stake n `streams ?U)" 
    using stake_finite_universe_finite[of ?U]
    by simp
  have "stake n ` streams ?U = stake n ` space M"
    using bernoulli
          bernoulli_stream_space[of M p]
    by auto
  then have "stake n ` streams ?U = {c::bool list. length c = n}"
    using stake_space[of n]
    by auto
  then show ?thesis
    using \<open>finite (stake n `streams ?U)\<close>
    by auto
qed
    
lemma finite_image:"finite {c::bool list. (\<forall>k<i. (geom_proc_list init (take k c)) \<notin> {0,target})\<and> length c = i \<and> geom_proc_list init c = target}"
  using finite_length[of i]
  by auto

text\<open>Sets of all successful random walk with specific stop is measurable\<close>
lemma success_measurable3:
  fixes init and  target and  i::nat
  assumes "0<init""init<target""0 \<le> i"
  shows"{x\<in> space M. success init x target \<and> stop_at init x target = enat i} \<in> sets M"
  using finite_image[of i]
success_measurable2[of init target i]
finite_stake_measurable[of "{c. (\<forall>k<i.
             geom_proc_list init (take k c)
             \<notin> {0, target}) \<and>
         length c = i \<and> geom_proc_list init c = target}"]
assms
  by presburger

text\<open>Any successful random walk must stop at specific position described by natural number\<close>
lemma success_measurable1:
  fixes init target 
  assumes "0 < init""init < target"
  shows "{x\<in> space M. success init x target} 
= (\<Union>i::nat. {x\<in> space M. success init x target \<and> stop_at init x target = i})"
proof
  show"{x \<in> space M. success init x target} \<subseteq> (\<Union>x. {xa \<in> space M. success init xa target \<and> stop_at init xa target = enat x})"
  proof
    fix x
    assume "x \<in> {x \<in> space M. success init x target}"
    then have "success init x target"
      by auto
    then have "stop_at init x target \<noteq> \<infinity>"
      unfolding success.simps
      using assms(1) assms(2) exist 
      by force
    then obtain i where "stop_at init x target = enat i"
      by auto
    then have "x \<in> {xa \<in> space M. success init xa target \<and> stop_at init xa target = enat i}"
      using \<open>success init x target\<close>
            bernoulli
            bernoulli_stream_space[of M p]
      by auto
    then show "x \<in> (\<Union>x. {xa \<in> space M.
           success init xa target \<and> stop_at init xa target = enat x})"
      by auto
  qed
next 
  show"(\<Union>x. {xa \<in> space M. success init xa target \<and> stop_at init xa target = enat x}) \<subseteq> {x \<in> space M. success init x target}"
  proof
    fix x
    assume "x \<in> (\<Union>x. {xa \<in> space M.
                    success init xa target \<and>
                    stop_at init xa target = enat x})"
    then have "success init x target"
      by auto
    then show "x \<in> {x \<in> space M. success init x target}"
      using bernoulli
            bernoulli_stream_space[of M p]
      by auto
  qed
qed


text\<open>Here we need to elaborate about this most difficult lemma we've met during this model 
formalization. lemma $success\_measurable$ asserts that successful random walks set under assumption
"$0 \leq initial number \leq target number$" is measurable set for measure M. On the one hand, since the 
probability theory has been set up based on the measure theory, every specific set must be proved to
be measurable with respect to fixed measure before we calculate the probability of the set, which
severely hinders most of scholars and experts from formalizing the security analysis related to the 
probability since it's extremely difficult to prove why your set is measurable. That is exactly why 
our endeavor matters to provide the first example to overcome the difficulty. On the other hand, we 
are willing to briefly explain the way we prove this lemma since it's nontrivial even for pen-and-paper
proof. lemma $finite\_stake\_measurable$ states that for the function ($\lambda$w. stake n w) taking the first n 
steps of random walk, the preimage of a finite sets is measurable for measure M. lemma $finite\_image$ 
states that sets filled with all bool list of fixed length n is finite. lemma $success\_measurable2$ sets
up the bijection between successful random walks stopping at fixed step and preimage of successful bool
list with identical length. lemma $success\_measurable1$ demonstrates that set of successful random
walks is countable union of sets of successful random walks stopping at some step. Combining theses 4 
lemmas together proves the set of successful random walk is measurable. If you take a closed look at 
the proofs of these 4 lemmas patiently, you will find it's very hard to finish. Honestly, we will 
never be able to finish such difficult proofs within one month without the current stochastic process
theory library established just in 2021 by Mnacho Echenim, the author of theory $infinite\_coin\_toss\_space$.\<close>
lemma success_measurable:
  fixes init target
  assumes "0 \<le> init""init \<le> target"
  shows "{x\<in> space M. success init x target} \<in> sets M"
proof(cases "init = target")
  assume equ:"init = target"
  then have "\<And>x. gambler_rand_walk_pre 1 (-1) init 0 x = target"
    using enat_0 gambler_rand_walk_pre.simps(1)[of 1 "-1" init _]
    by force
  then have "\<And>x. geom_proc init x 0 = target"
    unfolding geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps
    using enat_0 gambler_rand_walk_pre.simps(1)[of 1 "-1" init _] 
          enat.simps(4)[of "\<lambda>n. gambler_rand_walk_pre 1 (-1) init n _" " -1" 0]
    by auto
  then have belong_0:"\<forall>x. 0 \<in> reach_steps init x target"
    unfolding reach_steps_def geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps(1)
    using equ 
    by auto
  then have "\<forall>x. \<Sqinter> reach_steps init x target = 0"
    using not_belong 
    by auto
  then have "\<forall>x. stop_at init x target = 0"
    unfolding stop_at.simps infm.simps
    using belong_0 enat_0
    by auto
  then have "\<forall>x\<in> space M. stop_at init x target = 0"
    using bernoulli_stream_space[of M p] bernoulli
    by blast
  then have "\<forall>x\<in> space M. success init x target"
    unfolding success.simps
    using \<open>\<And>x. geom_proc init x 0 = target\<close>
    by auto 
    then show ?thesis
      by (smt (verit, best) Collect_cong Collect_mem_eq sets.top)
  next
    assume "init \<noteq> target"
    show ?thesis
    proof(cases "init = 0")
      assume equ1:"init = 0"
      then have "\<And>x. gambler_rand_walk_pre 1 (-1) init 0 x = 0"
        using enat_0 gambler_rand_walk_pre.simps(1)[of 1 "-1" init _]
        by force
      then have "\<And>x. geom_proc init x 0 = 0"
        unfolding geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps
        using enat_0 gambler_rand_walk_pre.simps(1)[of 1 "-1" init _] 
              enat.simps(4)[of "\<lambda>n. gambler_rand_walk_pre 1 (-1) init n _" " -1" 0]
        by auto
      then have belong_0:"\<forall>x. 0 \<in> reach_steps init x target"
        unfolding reach_steps_def geometric_process gambler_rand_walk.simps gambler_rand_walk_pre.simps(1)
        using equ1
        by auto
      then have "\<forall>x. \<Sqinter> reach_steps init x target = 0"
        using not_belong 
        by auto
      then have "\<forall>x. stop_at init x target = 0"
        unfolding stop_at.simps infm.simps
        using belong_0 enat_0
        by auto
      then have stop:"\<forall>x\<in> space M. stop_at init x target = 0"
        using bernoulli_stream_space[of M p] bernoulli
        by blast
      then have "\<forall>x\<in> space M. \<not> success init x target"if "target \<noteq> 0"
        unfolding success.simps
        using \<open>\<And>x. geom_proc init x 0 = 0\<close>
             that
        by auto
      then have "\<forall>x\<in> space M. success init x target"if "target = 0"
        unfolding success.simps
        using \<open>\<And>x. geom_proc init x 0 = 0\<close>
             that
             stop
        by auto
      then show ?thesis
        using \<open>target \<noteq> 0 \<Longrightarrow> \<forall>x\<in>space M. \<not> success init x target\<close>
        by (metis (no_types, lifting) Collect_empty_eq \<open>init \<noteq> target\<close> equ1 sets.empty_sets)
    next
      assume"init\<noteq>0"
      then have "0<init""init<target"
        using assms \<open>init \<noteq> target\<close>
        by auto
      then show ?thesis
        using success_measurable1[of init target ]
              success_measurable3[of init target _]
              assms
        by auto
    qed
  qed


  text\<open>The set of all the random walk with first step True is measurable\<close>
lemma success_measurable_shd:
"{x \<in> space M. shd x} \<in> sets M"
  using snth_measurable[of 0 True]
        snth.simps(1)
        bernoulli
        bernoulli_stream_space[of M p]
  by (simp add: insert_compr streams_UNIV)


  text\<open>The set of all the random walk with first step False is measurable\<close>
lemma success_measurable_shd_false:
"{x \<in> space M. \<not> shd x} \<in> sets M"
  using success_measurable_shd 
  by auto



lemma success_measurable_final:
  fixes init target
  assumes "0 < init" "init < target"
  shows"{x \<in> space M. success (init+1) (stl x) target \<and> shd x} \<in> sets M"
proof-
  have "{x \<in> space M. success init x target \<and> shd x = True} = {x \<in> space M. success (init + 1) (stl x) target \<and> shd x = True}"
    using conditional_set_equation[of init target]
          assms
          bernoulli
          bernoulli_stream_space[of M p]
    by auto
  moreover have "{x \<in> space M. success init x target \<and> shd x = True} \<in> sets M"
    using Sigma_Algebra.sets.Int[of "{x \<in> space M. shd x}" M "{x \<in> space M. success init x target}"]
          success_measurable_shd
          success_measurable[of init target]
          assms
    by auto
  ultimately show ?thesis
    by auto
qed

subsubsection\<open>Probability of successful random walk with its first step True\<close>

lemma semi_goal1:
  fixes init target P
  assumes "0 < init""init \<le> target""\<And>x. P x = success (init+1) (stl x) target \<and> shd x"
  shows "emeasure M {x. P (t ## x)} 
= (case t of True \<Rightarrow> 1|False \<Rightarrow> 0) * emeasure M {x. success (init+1) x target}"
proof (cases t)
  assume "t"
  then have "t = True"
    by auto
  then have "\<forall>x. shd (t ## x)"
    by auto
  then have "\<forall>x. P (t ## x) \<longleftrightarrow> success (init+1) x target"
    using assms(3) stream.sel(2)[of t _] \<open>\<forall>x. shd (t ## x)\<close>
    by force
  then have "emeasure M {x. P (t ## x)} = emeasure M {x. success (init+1) x target}"
    by auto
  then show ?thesis
    using \<open>t = True\<close>
    by auto
next
  assume "\<not>t"
  then have "t = False"
    by auto
  then have "\<forall>x. \<not>shd (t ## x)"
    by auto
  then have "{x. P (t ## x)} = {}"
    using assms(3)
    by auto
  then have "emeasure M {x. P (t ## x)} = 0"
    by auto
  then show ?thesis 
    using \<open>t = False\<close>
    by auto
qed


lemma semi_goal21:
  fixes p1 e::real and f
  assumes "m = measure_pmf (bernoulli_pmf p1)""\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
  shows "simple_function m f"
  unfolding simple_function_def
proof
  show "finite (f ` space m)"
  proof-
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then show "finite (f ` space m)"
      by auto
  qed
next 
  show "\<forall>x\<in>f ` space m. f -` {x} \<inter> space m \<in> sets m"
  proof (cases "e = 0")
    assume "e = 0"
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then have "f -` {0} \<inter> space m = {True,False}"
      using assms \<open>space m = {True, False}\<close> \<open>e = 0\<close>
      by force
    then show ?thesis
      using \<open>f ` space m = {0, e}\<close>\<open>e = 0\<close>
      by (metis \<open>space m = {True, False}\<close> ennreal_0 insert_absorb2 sets.top singletonD)
  next 
    assume "e \<noteq> 0"
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then show ?thesis
      using assms \<open>e \<noteq> 0\<close>  \<open>space m = {True, False}\<close>
      by simp
  qed
qed


lemma semi_goal21_false:
  fixes p1 e::real and f
  assumes "m = measure_pmf (bernoulli_pmf p1)""\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
  shows "simple_function m f"
  unfolding simple_function_def
proof
  show "finite (f ` space m)"
  proof-
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then show "finite (f ` space m)"
      by auto
  qed
next 
  show "\<forall>x\<in>f ` space m. f -` {x} \<inter> space m \<in> sets m"
  proof (cases "e = 0")
    assume "e = 0"
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then have "f -` {0} \<inter> space m = {True,False}"
      using assms \<open>space m = {True, False}\<close> \<open>e = 0\<close>
      by force
    then show ?thesis
      using \<open>f ` space m = {0, e}\<close>\<open>e = 0\<close>
      by (metis \<open>space m = {True, False}\<close> ennreal_0 insert_absorb2 sets.top singletonD)
  next 
    assume "e \<noteq> 0"
    have "space m = {True, False}"
      using assms(1)
      by auto
    then have "f ` space m = {0, e}"
      using assms(2)
      by auto
    then show ?thesis
      using assms \<open>e \<noteq> 0\<close>  \<open>space m = {True, False}\<close>
      by simp
  qed
qed


lemma sum_rephrase:
  fixes f::"ennreal \<Rightarrow> ennreal" and e
  assumes "0 \<noteq> e"
  shows "sum f {0,e} = f 0 + f (e)"
  using assms finite.insertI insert_absorb insert_not_empty singleton_insert_inj_eq' sum_clauses(1) 
  by auto


lemma semi_goal22:
  fixes p1 e::real
  assumes "m = measure_pmf (bernoulli_pmf p1)""0\<le>p1""p1\<le>1"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
"e > 0"
  shows "integral\<^sup>S m f = p1 * e"
  unfolding simple_integral_def
proof-
  show"(\<Sum>x\<in>f ` space m. x * emeasure m (f -` {x} \<inter> space m)) = ennreal (p1 * e)"
  proof-
    have "space m = {True, False}"
      using assms(1)
      by auto
    have "f -` {0}  = {False}"
    proof 
      show"f -` {0} \<subseteq> {False}"
      proof
        fix x
        assume "x \<in> f -` {0}"
        then have "f x = 0"
          by auto
        then have "x = False"
          using assms(4)[of x] 
               \<open>e > 0\<close>
                ennreal_eq_0_iff
          by auto
        then show "x \<in> {False}"
          by auto
      qed
    next
      show "{False} \<subseteq> f -` {0}"
      proof
        fix x
        assume "x \<in> {False}"
        then have "x = False"
          by auto
        then have "f x = 0"
          using assms
          by auto
        then show "x \<in> f -` {0}"
          by auto
      qed
    qed
    have "emeasure m ({False}) = 1 - p1"
      unfolding assms(1) emeasure_pmf_single ennreal_cong
      using pmf_bernoulli_False[of p1]
            assms(2) 
            assms(3) 
            ennreal_cong[of "pmf (bernoulli_pmf p1) False" "1 - p1"]
      by auto
    then have "emeasure m (f -` {0} \<inter> space m) = 1 - p1"
      using \<open>f -` {0} = {False}\<close> \<open>space m = {True, False}\<close> 
      by auto 
    have "f -` {ennreal e} = {True}"
    proof
      show"f -` {ennreal e} \<subseteq> {True}"
      proof
        fix x 
        assume "x \<in> f -` {ennreal e}"
        then have "f x = e"
          by auto
        then have "x = True"
          using assms(4)[of x] 
                 \<open>e > 0\<close>
                  ennreal_eq_0_iff
          by (smt (verit, best) mult_zero_right)
        then show "x \<in> {True}"
          by auto
      qed
    next 
      show "{True} \<subseteq> f -` {ennreal e}"
        using assms(4)
        by auto
    qed
    have "emeasure m ({True}) =  p1"
      unfolding assms(1) emeasure_pmf_single ennreal_cong
      using pmf_bernoulli_False[of p1]
            assms(2) 
            assms(3) 
            ennreal_cong[of "pmf (bernoulli_pmf p1) False" "1 - p1"]
      by auto
    then have "emeasure m (f -` {ennreal e} \<inter> space m) = p1"
      using \<open>f -` {ennreal e} = {True}\<close> \<open>space m = {True, False}\<close> 
      by auto
    have "f ` space m = {0, ennreal e}"
      using \<open>space m = {True,False}\<close> assms(4)
      by auto
    then have "(\<Sum>x\<in>f ` space m. x * emeasure m (f -` {x} \<inter> space m))
= 0 * emeasure m (f -` {0} \<inter> space m) + ennreal e * emeasure m (f -` {ennreal e} \<inter> space m)"
      using sum_rephrase[of "ennreal e" "\<lambda>x. x * emeasure m (f -` {x} \<inter> space m)"] 
            ennreal_eq_0_iff
            \<open>e > 0\<close>
      by force
    then show ?thesis
      using 
        \<open>space m = {True,False}\<close>
        \<open>emeasure m (f -` {ennreal e} \<inter> space m) = p1\<close>
        \<open>emeasure m (f -` {0} \<inter> space m) = 1 - p1\<close>
      by (metis add.left_neutral assms(2) ennreal_mult'' mult.commute mult_zero_left)
  qed
qed


lemma semi_goal22_false:
  fixes p1 e::real
  assumes "m = measure_pmf (bernoulli_pmf p1)""0\<le>p1""p1\<le>1"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
"e > 0"
  shows "integral\<^sup>S m f = (1-p1) * e"
  unfolding simple_integral_def
proof-
  show"(\<Sum>x\<in>f ` space m. x * emeasure m (f -` {x} \<inter> space m)) = ennreal ((1-p1) * e)"
  proof-
    have "space m = {True, False}"
      using assms(1)
      by auto
    have "f -` {0}  = {True}"
    proof 
      show"f -` {0} \<subseteq> {True}"
      proof
        fix x
        assume "x \<in> f -` {0}"
        then have "f x = 0"
          by auto
        then have "x = True"
          using assms(4)[of x] 
               \<open>e > 0\<close>
                ennreal_eq_0_iff[of e]
          by (smt (verit, best) mult.right_neutral)       
        then show "x \<in> {True}"
          by auto
      qed
    next
      show "{True} \<subseteq> f -` {0}"
      proof
        fix x
        assume "x \<in> {True}"
        then have "x = True"
          by auto
        then have "f x = 0"
          using assms
          by auto
        then show "x \<in> f -` {0}"
          by auto
      qed
    qed
    have "emeasure m ({True}) =  p1"
      unfolding assms(1) emeasure_pmf_single ennreal_cong
      using pmf_bernoulli_False[of p1]
            assms(2) 
            assms(3) 
            ennreal_cong[of "pmf (bernoulli_pmf p1) False" "1 - p1"]
      by auto
    then have "emeasure m (f -` {0} \<inter> space m) = p1"
      using \<open>f -` {0} = {True}\<close> \<open>space m = {True, False}\<close> 
      by auto 
    have "f -` {ennreal e} = {False}"
    proof
      show"f -` {ennreal e} \<subseteq> {False}"
      proof
        fix x 
        assume "x \<in> f -` {ennreal e}"
        then have "f x = e"
          by auto
        then have "x = False"
          using assms(4)[of x] 
                 \<open>e > 0\<close>
                  ennreal_eq_0_iff
          by (smt (verit, best) mult_zero_right)
        then show "x \<in> {False}"
          by auto
      qed
    next 
      show "{False} \<subseteq> f -` {ennreal e}"
        using assms(4)
        by auto
    qed
    have "emeasure m ({False}) =  1-p1"
      unfolding assms(1) emeasure_pmf_single ennreal_cong
      using pmf_bernoulli_False[of p1]
            assms(2) 
            assms(3) 
            ennreal_cong[of "pmf (bernoulli_pmf p1) False" "1 - p1"]
      by auto
    then have "emeasure m (f -` {ennreal e} \<inter> space m) = 1- p1"
      using \<open>f -` {ennreal e} = {False}\<close> \<open>space m = {True, False}\<close> 
      by auto
    have "f ` space m = {0, ennreal e}"
      using \<open>space m = {True,False}\<close> assms(4)
      by auto
    then have "(\<Sum>x\<in>f ` space m. x * emeasure m (f -` {x} \<inter> space m))
= 0 * emeasure m (f -` {0} \<inter> space m) + ennreal e * emeasure m (f -` {ennreal e} \<inter> space m)"
      using sum_rephrase[of "ennreal e" "\<lambda>x. x * emeasure m (f -` {x} \<inter> space m)"] 
            ennreal_eq_0_iff
            \<open>e > 0\<close>
      by force
    moreover have "ennreal e * ennreal (1-p1) + 0 * ennreal p1 = ennreal ((1-p1)*e)"
      using assms(3) ennreal_mult' mult.commute by auto
    ultimately  show ?thesis
      using 
        \<open>space m = {True,False}\<close>
        \<open>emeasure m (f -` {ennreal e} \<inter> space m) = 1 - p1\<close>
        \<open>emeasure m (f -` {0} \<inter> space m) = p1\<close>
      by auto
  qed
qed

 lemma semi_goal23:
  fixes p1 e::real and f
  assumes "0 \<le> p1"
          "p1 \<le> 1"
          "e > 0"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m = integral\<^sup>S m f"
  using nn_integral_eq_simple_integral semi_goal21[of m p1] assms
  by blast

lemma semi_goal23_false:
  fixes p1 e::real and f
  assumes "0 \<le> p1"
          "p1 \<le> 1"
          "e > 0"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m = integral\<^sup>S m f"
  using nn_integral_eq_simple_integral semi_goal21_false[of m p1] assms
  by blast


lemma semi_goal2:
  fixes p1 e::real and f
  assumes  "0 \<le> p1"
          "p1 \<le> 1"
          "e \<ge> 0"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m = p1 * e"
proof(cases "e = 0")
  assume "e = 0"
  then have "\<And>t. f t = 0"
    using assms
    by force
  then show ?thesis
    unfolding assms(4) \<open>e = 0\<close>
    using nn_integral_const[of m 0]
    by force
next 
  assume "e \<noteq> 0"
  then have "e > 0"
    using assms
    by auto
  then show ?thesis
  using semi_goal22[of m p1 f e] semi_goal23[of p1 e m f] assms
  by auto          
qed

lemma semi_goal2_false:
  fixes p1 e::real and f
  assumes  "0 \<le> p1"
          "p1 \<le> 1"
          "e \<ge> 0"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = ennreal e * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m = (1-p1) * e"
proof(cases "e = 0")
  assume "e = 0"
  then have "\<And>t. f t = 0"
    using assms
    by force
  then show ?thesis
    unfolding assms(4) \<open>e = 0\<close>
    using nn_integral_const[of m 0]
    by force
next 
  assume "e \<noteq> 0"
  then have "e > 0"
    using assms
    by auto
  then show ?thesis
  using semi_goal22_false[of m p1 f e] semi_goal23_false[of p1 e m f] assms
  by auto          
qed


lemma semi_goal2_final:
  fixes p1::real and e::ennreal and f
  assumes  "0 \<le> p1"
          "p1 \<le> 1"
          "e \<noteq> top"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = e * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m = p1 * e"
proof-
  obtain e1 where "e1\<ge>0"and "ennreal e1 = e"
    using ennreal_cases[of e] assms(3)
    by auto
  obtain f1 where "\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)"
    by auto
  then have "\<And>t. ennreal (f1 t) = f t"
    unfolding assms(5) \<open>ennreal e1 = e\<close> \<open>\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)\<close>
    using \<open>ennreal e1 = e\<close>
    by (smt (z3) ennreal_0 mult.right_neutral mult_cancel_left1 mult_cancel_right1 mult_zero_right)
  then have "(\<integral>\<^sup>+ t. (f1 t) \<partial>m) = \<integral>\<^sup>+ t. (f t) \<partial>m"
    by force
  then show ?thesis
    using assms semi_goal2[of p1 e1 m f1] \<open>e1\<ge>0\<close> \<open>\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 1| False \<Rightarrow> 0)\<close>
         \<open>\<And>t. ennreal (f1 t) = f t\<close> \<open>ennreal e1 = e\<close> ennreal_mult'' 
    by force
qed


lemma semi_goal2_final_false:
  fixes p1::real and e::ennreal and f
  assumes  "0 \<le> p1"
          "p1 \<le> 1"
          "e \<noteq> top"
"m = measure_pmf (bernoulli_pmf p1)"
"\<And>t. f t = e * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
shows "\<integral>\<^sup>+ t. (f t) \<partial>m =(1 - p1) * e"
proof-
  obtain e1 where "e1\<ge>0"and "ennreal e1 = e"
    using ennreal_cases[of e] assms(3)
    by auto
  obtain f1 where "\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)"
    by auto
  then have "\<And>t. ennreal (f1 t) = f t"
    unfolding assms(5) \<open>ennreal e1 = e\<close> \<open>\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)\<close>
    using \<open>ennreal e1 = e\<close>
    by (smt (z3) ennreal_0 mult.right_neutral mult_cancel_left1 mult_cancel_right1 mult_zero_right)
  then have "(\<integral>\<^sup>+ t. (f1 t) \<partial>m) = \<integral>\<^sup>+ t. (f t) \<partial>m"
    by force
  then show ?thesis
    using assms semi_goal2_false[of p1 e1 m f1] \<open>e1\<ge>0\<close> \<open>\<And>t. f1 t = e1 * (case t of True \<Rightarrow> 0| False \<Rightarrow> 1)\<close>
         \<open>\<And>t. ennreal (f1 t) = f t\<close> \<open>ennreal e1 = e\<close> ennreal_mult'' 
    by force
qed



lemma fun_description_pre:
  fixes init target t
  assumes "0 < init""init < target"
  shows
"emeasure M {x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}} 
= (case t of True \<Rightarrow> 1|False \<Rightarrow> 0) * (emeasure M {x\<in> space M. success (init+1) (x) target})"
proof(cases t)
  assume "t"
  then have "t = True"
    by auto
   have "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}} = {x\<in> space M. success (init+1) (x) target}"
        if  "t = True"
      proof
        show "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}} \<subseteq> {x \<in> space M. success (init + 1) x target}"
        proof
          fix x
          assume "x \<in> {x \<in> space M. (t ## x) \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}} "
          then have "(t ## x) \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}"
            by blast
          then have "success (init+1) (stl (t ## x)) target \<and> shd (t ## x)"
            by blast
          then have "success (init+1) (x) target"
            using that
                  stream.sel(2)
            by force
          then show "x \<in> {x \<in> space M. success (init + 1) x target}"
            using bernoulli_stream_space[of M p]
                  bernoulli
            by auto
        qed
      next 
        show "{x \<in> space M. success (init + 1) x target} \<subseteq> {x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}}"
        proof 
          fix x
          assume "x \<in> {x \<in> space M. success (init + 1) x target}"
          then have "x \<in> space M""success (init + 1) x target"
            by auto
          then have "(t ## x) \<in> space M"
            using stream_space_Stream
          proof-
            have "t \<in> space (measure_pmf (bernoulli_pmf p))"
              by fastforce
            then have "(t ## x) \<in> space M"
              using \<open>x \<in> space M\<close>
                    stream_space_Stream[of  t x]
                    bernoulli
                    bernoulli_stream_def[of p]
              by auto
            then show ?thesis
              using bernoulli
                      bernoulli_stream_def[of p]
                      that
              by auto
          qed
          then have "success (init+1) (stl (t ## x)) target""shd (t ## x)""(t ## x) \<in> space M"
            using stream.sel(2) stream.sel(1) that
                  \<open>x \<in> space M\<close>
                  \<open>success (init + 1) x target\<close>
            by auto
          then have "t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}"
            unfolding that
            by force
          then show "x \<in> {x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}}"
            using bernoulli_stream_space[of M p]
                  bernoulli
                  \<open>x \<in> space M\<close>
            by force
        qed
      qed 
      then have "{x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}} = {x \<in> space M. success (init + 1) x target}"
        using \<open>t = True\<close>
        by auto
      then have "emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}} = emeasure M {x \<in> space M. success (init + 1) x target}"
        using \<open>t = True\<close>
        by auto
      then show ?thesis
        using \<open>t = True\<close>
        by auto
    next
      assume "\<not> t"
      then have "t = False"
        by auto
      moreover have "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}} = {}"
        if  "t = False"
      proof-
        have "\<forall>x \<in> space M. t ## x \<notin> {x\<in> space M. success (init+1) (stl x) target \<and> shd x}"
          using stream.sel(1) that
          by auto
        then show ?thesis
          by blast
      qed
      ultimately have "emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}} = 0"
        by force
      then show ?thesis
        using \<open>t = False\<close>
        by auto
    qed

lemma fun_description_pre_false:
  fixes init target t
  assumes "0 < init""init < target"
  shows
"emeasure M {x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}} 
= (case t of True \<Rightarrow> 0|False \<Rightarrow> 1) * (emeasure M {x\<in> space M. success (init-1) (x) target})"
proof(cases t)
  assume "\<not>t"
  then have "t = False"
    by auto
   have "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}} = {x\<in> space M. success (init-1) (x) target}"
        if  "t = False"
      proof
        show "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}} \<subseteq> {x \<in> space M. success (init - 1) x target}"
        proof
          fix x
          assume "x \<in> {x \<in> space M. (t ## x) \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}} "
          then have "(t ## x) \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}"
            by blast
          then have "success (init-1) (stl (t ## x)) target \<and> \<not> shd (t ## x)"
            by blast
          then have "success (init-1) (x) target"
            using that
                  stream.sel(2)
            by force
          then show "x \<in> {x \<in> space M. success (init - 1) x target}"
            using bernoulli_stream_space[of M p]
                  bernoulli
            by auto
        qed
      next 
        show "{x \<in> space M. success (init - 1) x target} \<subseteq> {x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}}"
        proof 
          fix x
          assume "x \<in> {x \<in> space M. success (init - 1) x target}"
          then have "x \<in> space M""success (init - 1) x target"
            by auto
          then have "(t ## x) \<in> space M"
            using stream_space_Stream
          proof-
            have "t \<in> space (measure_pmf (bernoulli_pmf p))"
              by fastforce
            then have "(t ## x) \<in> space M"
              using \<open>x \<in> space M\<close>
                    stream_space_Stream[of  t x]
                    bernoulli
                    bernoulli_stream_def[of p]
              by auto
            then show ?thesis
              using bernoulli
                      bernoulli_stream_def[of p]
                      that
              by auto
          qed
          then have "success (init-1) (stl (t ## x)) target""\<not> shd (t ## x)""(t ## x) \<in> space M"
            using stream.sel(2) stream.sel(1) that
                  \<open>x \<in> space M\<close>
                  \<open>success (init - 1) x target\<close>
            by auto
          then have "t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}"
            unfolding that
            by force
          then show "x \<in> {x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}}"
            using bernoulli_stream_space[of M p]
                  bernoulli
                  \<open>x \<in> space M\<close>
            by force
        qed
      qed 
      then have "{x \<in> space M. t ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}} = {x \<in> space M. success (init - 1) x target}"
        using \<open>t = False\<close>
        by auto
      then have "emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}} = emeasure M {x \<in> space M. success (init - 1) x target}"
        using \<open>t = False\<close>
        by auto
      then show ?thesis
        using \<open>t = False\<close>
        by auto
    next
      assume "t"
      then have "t = True"
        by auto
      moreover have "{x \<in> space M. t ## x \<in> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}} = {}"
        if  "t = True"
      proof-
        have "\<forall>x \<in> space M. t ## x \<notin> {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x}"
          using stream.sel(1) that
          by auto
        then show ?thesis
          by blast
      qed
      ultimately have "emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}} = 0"
        by force
      then show ?thesis
        using \<open>t = True\<close>
        by auto
    qed

    term"emeasure_stream_space"
text\<open>The lemma $semi\_goal\_true$ is the second difficulty we've overcome during the model formalization.
It asserts that probability of sets of successful random walk with first step True is equal to 
probability of sets of random walk times probability of sets of successful random walk with initial
number plus 1. Thanks to the lemma $emeasure\_stream\_space$ provided by Mnacho Echenim, the author of 
$infinite\_coin\_toss\_space$, we could finally use the integral rather than tediously break down the 
countable product to calculate the probability\<close>
lemma semi_goal_true:
  fixes init target
  assumes "0 < init""init < target"
  shows "emeasure M {x\<in> space M. success (init+1) (stl x) target \<and> shd x} 
= emeasure M {x \<in> space M. shd x} * emeasure M {x\<in> space M. success (init+1) (x) target}"
proof-
  let ?M = "measure_pmf (bernoulli_pmf p)"
  have "\<And>X. X \<in> sets (stream_space ?M) \<Longrightarrow>
  emeasure (stream_space ?M) X = \<integral>\<^sup>+ t. emeasure (stream_space ?M) {x \<in> space (stream_space ?M). t ## x \<in> X} \<partial>?M"
    using emeasure_stream_space
    by (smt (verit, best) Collect_cong nn_integral_cong prob_space.emeasure_stream_space prob_space_measure_pmf)
  moreover have "{x\<in> space M. success (init+1) (stl x) target \<and> shd x} \<in> sets (stream_space ?M)"
    using success_measurable_final[of init target] assms
          bernoulli
    by (metis bernoulli_stream_def)    
  moreover have "\<integral>\<^sup>+ t. emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}}
       \<partial>measure_pmf (bernoulli_pmf p) =
    ennreal p * emeasure (stream_space (measure_pmf (bernoulli_pmf p))) {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init + 1) x target}"
    proof-
      have "emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
            {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init + 1) x target} \<noteq> top"
        using emeasure_finite[of "{x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))).
              success (init + 1) x target}"]
              bernoulli
              bernoulli_stream_def[of p]
        by force
      moreover have "(\<And>t. emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}} =
          emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
           {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init + 1) x target} *
          (case t of True \<Rightarrow> 1 | False \<Rightarrow> 0))"
        using fun_description_pre[of init target _] assms
              bernoulli
              bernoulli_stream_def[of p]
              mult.commute 
        by fastforce
      ultimately show ?thesis
        using semi_goal2_final[of p 
"emeasure (stream_space ?M) {x \<in> space (stream_space ?M). success (init+1) (x) target}" 
"measure_pmf (bernoulli_pmf p)"
"\<lambda>t. emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init + 1) (stl x) target \<and> shd x}}"]   
            p_gt_0 p_lt_1
            bernoulli
            bernoulli_stream_def[of p]
        by force
    qed
    ultimately have "emeasure (stream_space ?M) {x\<in> space M. success (init+1) (stl x) target \<and> shd x} 
= ennreal p *
    emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
     {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init + 1) x target}"
      using  bernoulli
            bernoulli_stream_def[of p]
      by force
    moreover have "emeasure M {x \<in> space M. shd x} = p"
    proof-
      have "\<forall>n. emeasure M {w \<in> space M. w !! n} = ennreal p"
      using bernoulli_stream_component_probability[of M p]
            bernoulli
            p_gt_0
            p_lt_1
            snth.simps(1)
      by auto
      then show ?thesis
        using snth.simps(1)
        by (metis (no_types, lifting) Collect_cong)
    qed
  ultimately show ?thesis
      using  bernoulli
            bernoulli_stream_def[of p]
      by force
  qed


lemma semi_goal_false:
  fixes init target
  assumes "0 < init""init < target"
  shows "emeasure M {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x} 
= emeasure M {x \<in> space M. \<not> shd x} * emeasure M {x\<in> space M. success (init-1) (x) target}"
proof-
  let ?M = "measure_pmf (bernoulli_pmf p)"
  have "\<And>X. X \<in> sets (stream_space ?M) \<Longrightarrow>
  emeasure (stream_space ?M) X = \<integral>\<^sup>+ t. emeasure (stream_space ?M) {x \<in> space (stream_space ?M). t ## x \<in> X} \<partial>?M"
    using emeasure_stream_space
    by (smt (verit, best) Collect_cong nn_integral_cong prob_space.emeasure_stream_space prob_space_measure_pmf)
  moreover have "{x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x} \<in> sets (stream_space ?M)"
  proof-
    have "{x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x} = {x\<in> space M. success init x target \<and> \<not> shd x}"
      using  conditional_set_equation_false[of init target]
            assms
            bernoulli_stream_space[of M p]
            bernoulli
      by auto
    moreover have "{x\<in> space M. success init x target \<and> \<not> shd x} \<in> sets M "
      using success_measurable_shd_false
            success_measurable[of init target]
            assms
      by auto
    ultimately show ?thesis
      using  bernoulli
             bernoulli_stream_def[of p]
      by force
  qed
  moreover have "\<integral>\<^sup>+ t. emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}}
       \<partial>measure_pmf (bernoulli_pmf p) =
    ennreal (1-p) * emeasure (stream_space (measure_pmf (bernoulli_pmf p))) {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init - 1) x target}"
    proof-
      have "emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
            {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init - 1) x target} \<noteq> top"
        using emeasure_finite[of "{x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))).
              success (init - 1) x target}"]
              bernoulli
              bernoulli_stream_def[of p]
        by force
      moreover have "(\<And>t. emeasure M {x \<in> space M. t ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}} =
          emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
           {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init - 1) x target} *
          (case t of True \<Rightarrow> 0 | False \<Rightarrow> 1))"
        using fun_description_pre_false[of init target _] assms
              bernoulli
              bernoulli_stream_def[of p]
              mult.commute 
        by fastforce
      ultimately show ?thesis
        using semi_goal2_final_false[of p
"emeasure (stream_space ?M) {x \<in> space (stream_space ?M). success (init-1) (x) target}" 
"measure_pmf (bernoulli_pmf p)"
"\<lambda>t. emeasure M {x \<in> space M. (t) ## x \<in> {x \<in> space M. success (init - 1) (stl x) target \<and> \<not> shd x}}"]   
            p_gt_0 p_lt_1
            bernoulli
            bernoulli_stream_def[of p]
        by force

    qed
    ultimately have "emeasure (stream_space ?M) {x\<in> space M. success (init-1) (stl x) target \<and> \<not> shd x} 
= ennreal (1-p) *
    emeasure (stream_space (measure_pmf (bernoulli_pmf p)))
     {x \<in> space (stream_space (measure_pmf (bernoulli_pmf p))). success (init - 1) x target}"
      using  bernoulli
            bernoulli_stream_def[of p]
      by force
    moreover have "emeasure M {x \<in> space M. \<not> shd x} = 1-p"
    proof-
      have "\<forall>n. emeasure M {w \<in> space M. \<not> w !! n} = ennreal (1-p)"
        using bernoulli_stream_component_probability_compl[of M p]
            bernoulli
            p_gt_0
            p_lt_1
            snth.simps(1)
      by auto
      then show ?thesis
        using snth.simps(1)
        by (metis (no_types, lifting) Collect_cong)
    qed
  ultimately show ?thesis
      using  bernoulli
            bernoulli_stream_def[of p]
      by force
  qed

  subsubsection\<open>Final goal: establish the recursive probability equation\<close>


  text\<open>The final probability equation we want to formalize: $$P_n = pP_{n+1} + (1-p)P_{n-1}$$\<close>
lemma Recursive_probability_equation:
  fixes init target
  assumes "0 < init" "init < target"
  shows"probability_of_win init target = p * (probability_of_win (init + 1) target) + (1 - p) * (probability_of_win (init - 1) target)"
  unfolding probability_of_win.simps
proof-
  have "emeasure M {x\<in> space M. success init x target}
 = emeasure M {x\<in> space M. success init x target \<and> shd x} 
+ emeasure M {x\<in> space M. success init x target \<and> \<not> (shd x)}"
  proof-
    have "{x\<in> space M. success init x target \<and> \<not> (shd x)} \<union> {x\<in> space M. success init x target \<and> (shd x)} =
{x\<in> space M. success init x target}"
      by auto
    moreover have "{x\<in> space M. success init x target \<and> \<not> (shd x)} \<inter> {x\<in> space M. success init x target \<and> (shd x)} = {}"
      by auto
    moreover have "{x \<in> space M. success init x target \<and> \<not> shd x} \<in> sets M"
      using success_measurable_shd_false
            success_measurable_shd
            success_measurable[of init target]
            assms
            Sigma_Algebra.sets.Int
      by auto
    moreover have "{x \<in> space M. success init x target \<and> shd x} \<in> sets M"
      using success_measurable_shd_false
            success_measurable_shd
            success_measurable[of init target]
            assms
            Sigma_Algebra.sets.Int
      by auto
    moreover have "emeasure M {} = 0"
      by auto
    ultimately show ?thesis
      using emeasure_Un_Int[of "{x\<in> space M. success init x target \<and> \<not> (shd x)}" M  "{x\<in> space M. success init x target \<and>(shd x)}"]
      by (metis (no_types, lifting) add.commute plus_emeasure)
  qed
  moreover have "emeasure M {x \<in> space M. success init x target \<and> shd x} = 
emeasure M {x \<in> space M. shd x} * emeasure M {x \<in> space M. success (init + 1) x target}"
    using semi_goal_true[of init target]
          conditional_set_equation[of init target]
          assms
    by (smt (verit, ccfv_SIG) Collect_cong mem_Collect_eq)
  moreover have "emeasure M {x \<in> space M. success init x target \<and> \<not> shd x} = 
emeasure M {x \<in> space M. \<not> shd x} * emeasure M {x \<in> space M. success (init - 1) x target}"
    using semi_goal_false[of init target]
          conditional_set_equation_false[of init target]
          assms
    by (smt (verit, ccfv_SIG) Collect_cong mem_Collect_eq)
  moreover have "emeasure M {x \<in> space M. \<not> shd x} = 1-p"
  proof-
    have "\<forall>n. emeasure M {w \<in> space M. \<not> w !! n} = ennreal (1-p)"
      using bernoulli_stream_component_probability_compl[of M p]
          bernoulli
          p_gt_0
          p_lt_1
          snth.simps(1)
    by auto
    then show ?thesis
      using snth.simps(1)
      by (metis (no_types, lifting) Collect_cong)
  qed
  moreover have "emeasure M {x \<in> space M. shd x} = p"
  proof-
    have "\<forall>n. emeasure M {w \<in> space M. w !! n} = ennreal p"
    using bernoulli_stream_component_probability[of M p]
          bernoulli
          p_gt_0
          p_lt_1
          snth.simps(1)
    by auto
    then show ?thesis
      using snth.simps(1)
      by (metis (no_types, lifting) Collect_cong)
  qed
  ultimately show "emeasure M {x \<in> space M. success init x target} =
  ennreal p * emeasure M {x \<in> space M. success (init + 1) x target} +
  ennreal (1 - p) * emeasure M {x \<in> space M. success (init - 1) x target}"
    by force
qed

end
end