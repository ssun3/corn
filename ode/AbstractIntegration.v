(** An abstract interface for integrable uniformly continuous functions from Q to CR,
 with a proof that integrals satisfying this interface are unique. *)

Require Import
 Unicode.Utf8 Program
 CRArith CRabs
 Qauto Qround Qmetric
 stdlib_omissions.P
 stdlib_omissions.Z
 stdlib_omissions.Q
 stdlib_omissions.N.
Require Import metric FromMetric2 SimpleIntegration.

Require Qinf QnonNeg QnnInf CRball.
Import Qinf.notations QnonNeg.notations QnnInf.notations CRball.notations Qabs (*canonical_names*).

Require CRtrans ARtrans. (* This is almost all CoRN *)

Ltac done :=
  trivial; hnf; intros; solve
   [ repeat (first [solve [trivial | apply: sym_equal; trivial]
         | discriminate | contradiction | split])
(*   | case not_locked_false_eq_true; assumption*)
   | match goal with H : ~ _ |- _ => solve [case H; trivial] end ].

Local Open Scope Q_scope.
Local Open Scope CR_scope.

(* [SearchAbout ((Cmap _ _) (Cunit _)).] does not find anything, but it
should find metric2.Prelength.fast_MonadLaw3 *)

(** Any nonnegative width can be split up into an integral number of
 equal-sized pieces no bigger than a given bound: *)

Add Field Qfield : Qsft
 (decidable Qeq_bool_eq,
  completeness Qeq_eq_bool,
  constants [Qcst],
  power_tac Qpower_theory [Qpow_tac]).

(* To be added to stdlib.omissions.Q *)
Section QFacts.

Open Scope Q_scope.

Lemma Qmult_inv_l (x : Q) : ~ x == 0 -> / x * x == 1.
Proof. intros; rewrite Qmult_comm; apply Qmult_inv_r; trivial. Qed.

Lemma Qinv_0 (x : Q) : / x == 0 <-> x == 0.
Proof.
split; intro H; [| now rewrite H].
destruct x as [m n]; destruct m as [| p | p]; unfold Qinv in *; simpl in *; [reflexivity | |];
unfold Qeq in H; simpl in H; rewrite Pos.mul_1_r in H; discriminate H.
Qed.

Lemma Qinv_not_0 (x : Q) : ~ / x == 0 <-> ~ x == 0.
Proof. now rewrite Qinv_0. Qed.

Lemma Qdiv_l (x y z : Q) : ~ x == 0 -> (x * y == z <-> y == z / x).
Proof.
intro H1.
rewrite <- (Qmult_injective_l x H1 y (z / x)). unfold Qdiv.
now rewrite <- Qmult_assoc, (Qmult_inv_l x H1), Qmult_1_r, Qmult_comm.
Qed.

Lemma Qdiv_r (x y z : Q) : ~ y == 0 -> (x * y == z <-> x == z / y).
Proof. rewrite Qmult_comm; apply Qdiv_l. Qed.

Lemma Q_of_nat_inj (m n : nat) : m == n <-> m = n.
Proof.
split; intro H; [| now rewrite H].
rewrite QArith_base.inject_Z_injective in H. now apply Nat2Z.inj in H.
Qed.

End QFacts.

Definition split (w: QnonNeg) (bound: QposInf):
  { x: nat * QnonNeg | (fst x * snd x == w)%Qnn /\ (snd x <= bound)%QnnInf }.
Proof with simpl; auto with *.
 unfold QnonNeg.eq. simpl.
 destruct bound; simpl.
  Focus 2. exists (1%nat, w). simpl. split... ring.
 induction w using QnonNeg.rect.
  exists (0%nat, 0%Qnn)...
 set (p := Qpossec.QposCeiling (QposMake n d / q)%Qpos).
 exists (nat_of_P p, ((QposMake n d / p)%Qpos):QnonNeg)...
 split.
  rewrite <- Zpos_eq_Z_of_nat_o_nat_of_P.
  change (p * ((n#d) * / p) == (n#d))%Q.
  field. discriminate.
 subst p.
 apply Qle_shift_div_r...
 rewrite Qpossec.QposCeiling_Qceiling. simpl.
 setoid_replace (n#d:Q) with (q * ((n#d) * / q))%Q at 1 by (simpl; field)...
 do 2 rewrite (Qmult_comm q).
 apply Qmult_le_compat_r...
Qed.

(** Riemann sums will play an important role in the theory about integrals, so let's
define very simple summation and a key property thereof: *)

Definition cmΣ {M: CMonoid} (n: nat) (f: nat -> M): M := cm_Sum (map f (enum n)).

(*Lemma cmΣ_sum {M: CMonoid} (n : nat) (f g : nat -> M) : cmΣ n 

M := cm_Sum (map f (enum n)).

SearchAbout cm_Sum.*)

(** If the elementwise distance between two summations over the same domain
 is bounded, then so is the distance between the summations: *)

(*
Lemma CRΣ_gball_ex (f g: nat -> CR) (e: QnnInf) (n: nat):
   (forall m, (m < n)%nat -> gball_ex e (f m) (g m)) ->
   (gball_ex (n * e)%QnnInf (cmΣ n f) (cmΣ n g)).
Proof with simpl; auto.
 destruct e...
 induction n.
  reflexivity.
 intros.
 change (gball (inject_Z (S n) * `q) (cmΣ (S n) f) (cmΣ (S n) g)).
 rewrite Q.S_Qplus.
 setoid_replace ((n+1) * q)%Q with (q + n * q)%Q by (simpl; ring).
 unfold cmΣ. simpl @cm_Sum.
 apply CRgball_plus...
Qed.
*)

Lemma cmΣ_0 (f : nat -> CR) (n : nat) :
  (forall m, (m < n)%nat -> f m [=] 0) -> cmΣ n f [=] 0.
Proof.
induction n as [| n IH]; intro H; [reflexivity |].
unfold cmΣ. simpl @cm_Sum. rewrite H by apply lt_n_Sn.
rewrite IH; [apply CRplus_0_l |].
intros m H1; apply H. now apply lt_S.
Qed.

Lemma CRΣ_gball (f g: nat -> CR) (e : Q) (n : nat):
   (forall m, (m < n)%nat -> gball e (f m) (g m)) ->
   (gball (n * e) (cmΣ n f) (cmΣ n g)).
Proof.
 induction n; [reflexivity |].
 intros.
 rewrite Q.S_Qplus.
 setoid_replace ((n + 1) * e)%Q with (e + n * e)%Q by ring.
 unfold cmΣ. simpl @cm_Sum.
 apply CRgball_plus; auto.
Qed.

(*Instance cmΣ_proper : Proper (eq ==> @ext_equiv nat _ CR _ ==> @st_eq CR) cmΣ.
Proof.
intros n1 n2 E1 f1 f2 E2. rewrite E1.
change (gball 0 (cmΣ n2 f1) (cmΣ n2 f2)).
setoid_replace 0%Q with (n2 * 0)%Q by ring.
apply CRΣ_gball. now intros m _; apply E2.
Qed.*)

Hint Immediate ball_refl Qle_refl.

(** Next up, the actual interface for integrable functions. *)

Bind Scope Q_scope with Q.

(*Arguments integral_additive {f} {_} {_} a b c _ _.*)

Section integral_approximation.

  Context (f: Q → CR) `{Int: Integrable f}.

    (** The additive property implies that zero width intervals have zero surface: *)

    Lemma zero_width_integral q: ∫ f q 0%Qnn == 0.
    Proof with auto.
     apply CRplus_eq_l with (∫ f q 0%Qnn).
     generalize (integral_additive q 0%Qnn 0%Qnn).
     rewrite Qplus_0_r, QnonNeg.plus_0_l, CRplus_0_l...
    Qed.

    (** Iterating the additive property yields: *)

    Lemma integral_repeated_additive (a: Q) (b: QnonNeg) (n: nat):
        cmΣ n (fun i: nat => ∫ f (a + i * ` b) b) == ∫ f a (n * b)%Qnn.
    Proof with try ring.
     unfold cmΣ.
     induction n; simpl @cm_Sum.
      setoid_replace (QnonNeg.from_nat 0) with 0%Qnn by reflexivity.
      rewrite QnonNeg.mult_0_l, zero_width_integral...
     rewrite IHn.
     rewrite CRplus_comm.
     setoid_replace (S n * b)%Qnn with (n * b + b)%Qnn.
      rewrite integral_additive...
     change (S n * b == n * b + b)%Q.
     rewrite S_Qplus...
    Qed.

    (** As promised, we now move toward the aforementioned generalizations of the
    boundedness property. We start by generalizing mid to CR: *)

    Lemma bounded_with_real_mid (from: Q) (width: Qpos) (mid: CR) (r: Qpos):
      (forall x, from <= x <= from+width -> ball r (f x) mid) ->
      ball (width * r) (∫ f from width) (scale width mid).
    Proof with auto.
     intros H d1 d2.
     simpl approximate.
     destruct (Qscale_modulus_pos width d2) as [P E].
     rewrite E. simpl.
     set (v := (exist (Qlt 0) (/ width * d2)%Q P)).
     setoid_replace (d1 + width * r + d2)%Qpos with (d1 + width * (r + v))%Qpos by
       (unfold QposEq; simpl; field)...
     apply regFunBall_Cunit.
     apply integral_bounded_prim.
     intros.
     apply ball_triangle with mid...
     apply ball_approx_r.
    Qed.

    (** Next, we generalize r to QnonNeg: *)

    Lemma bounded_with_nonneg_radius (from: Q) (width: Qpos) (mid: CR) (r: QnonNeg):
      (forall (x: Q), (from <= x <= from+width) -> gball r (f x) mid) ->
      gball (width * r) (∫ f from width) (scale width mid).
    Proof with auto.
     pattern r.
     apply QnonNeg.Qpos_ind.
       intros ?? E.
       split. intros H ?. rewrite <- E. apply H. intros. rewrite E...
       intros H ?. rewrite E. apply H. intros. rewrite <- E...
      rewrite Qmult_0_r, gball_0.
      intros.
      apply ball_eq. intro .
      setoid_replace e with (width * (e * Qpos_inv width))%Qpos by (unfold QposEq; simpl; field)...
      apply bounded_with_real_mid.
      intros q ?.
      setoid_replace (f q) with mid...
      apply -> (@gball_0 CR)...
     intros.
     apply (ball_gball (width * q)%Qpos), bounded_with_real_mid.
     intros. apply ball_gball...
    Qed.

    (** Next, we generalize r to a full CR: *)

    Lemma bounded_with_real_radius (from: Q) (width: Qpos) (mid: CR) (r: CR) (rnn: CRnonNeg r):
      (forall (x: Q), from <= x <= from+` width -> CRball r mid (f x)) ->
      CRball (scale width r) (∫ f from width) (scale width mid).
    Proof with auto.
     intro A.
     unfold CRball.
     intros.
     unfold CRball in A.
     setoid_replace q with (width * (q / width))%Q by (simpl; field; auto).
     assert (r <= ' (q / width)).
      apply (mult_cancel_leEq CRasCOrdField) with (' width).
       simpl. apply CRlt_Qlt...
      rewrite mult_commutes.
      change (' width * r <= ' (q / width) * ' width).
      rewrite CRmult_Qmult.
      unfold Qdiv.
      rewrite <- Qmult_assoc.
      rewrite (Qmult_comm (/width)).
      rewrite Qmult_inv_r...
      rewrite Qmult_1_r.
      rewrite CRmult_scale...
     assert (0 <= (q / width))%Q as E.
      apply CRle_Qle.
      apply CRle_trans with r...
      apply -> CRnonNeg_le_0...
     apply (bounded_with_nonneg_radius from width mid (exist _ _ E)).
     intros. simpl. apply gball_sym...
    Qed.

    (** Finally, we generalize to nonnegative width: *)

    Lemma integral_bounded (from: Q) (width: QnonNeg) (mid: CR) (r: CR) (rnn: CRnonNeg r)
      (A: forall (x: Q), (from <= x <= from+` width) -> CRball r mid (f x)):
      CRball (scale width r) (∫ f from width) (scale width mid).
    Proof with auto.
     revert A.
     pattern width.
     apply QnonNeg.Qpos_ind; intros.
       intros ?? E.
       split; intro; intros.
        rewrite <- E. apply H. intros. apply A. rewrite <- E...
       rewrite E. apply H. intros. apply A. rewrite E...
      rewrite zero_width_integral, scale_0, scale_0.
      apply CRball.reflexive, CRnonNeg_0.
     apply (bounded_with_real_radius from q mid r rnn)...
    Qed.

    (** In some context a lower-bound-upper-bound formulation is more convenient
    than the the ball-based formulation: *)

    Lemma integral_lower_upper_bounded (from: Q) (width: QnonNeg) (lo hi: CR):
      (forall (x: Q), (from <= x <= from+` width)%Q -> lo <= f x /\ f x <= hi) ->
      scale (` width) lo <= ∫ f from width /\ ∫ f from width <= scale (` width) hi.
    Proof with auto with *.
     intro A.
     assert (from <= from <= from + `width) as B.
      split...
      rewrite <- (Qplus_0_r from) at 1.
      apply Qplus_le_compat...
     assert (lo <= hi) as lohi by (destruct (A _ B); now apply CRle_trans with (f from)).
     set (r := ' (1#2) * (hi - lo)).
     set (mid := ' (1#2) * (lo + hi)).
     assert (mid - r == lo) as loE by (subst mid r; ring).
     assert (mid + r == hi) as hiE by (subst mid r; ring).
     rewrite <- loE, <- hiE.
     rewrite scale_CRplus, scale_CRplus, scale_CRopp, CRdistance_CRle, CRdistance_comm.
     apply CRball.as_distance_bound.
     apply integral_bounded.
      subst r.
      apply CRnonNeg_le_0.
      apply mult_resp_nonneg.
       simpl. apply CRle_Qle...
      rewrite <- (CRplus_opp lo).
      apply (CRplus_le_r lo hi (-lo))...
     intros.
     apply CRball.as_distance_bound. apply -> CRdistance_CRle.
     rewrite loE, hiE...
    Qed.

    (** We now work towards unicity, for which we use that implementations must agree with Riemann
     approximations. But since those are only valid for locally uniformly continuous functions, our proof
     of unicity only works for such functions. Todo: There should really be a proof that does not depend
     on continuity. *)

    Context `{L : !IsLocallyUniformlyContinuous f lmu}.

(*
    Lemma gball_integral (e: Qpos) (a a': Q) (ww: Qpos) (w: QnonNeg):
      (w <= @uc_mu _ _ _ (@luc_mu Q _ CR f _ (a, ww)) e)%QnnInf ->
      gball ww a a' ->
      gball_ex (w * e)%QnnInf (' w * f a') (∫ f a' w).
    Proof with auto.
     intros ??.
     simpl QnnInf.mult.
     apply in_CRgball.
     simpl.
     rewrite <- CRmult_Qmult.
     CRring_replace (' w * f a' - ' w * ' e) (' w * (f a' - ' e)).
     CRring_replace (' w * f a' + ' w * ' e) (' w * (f a' + ' e)).
     repeat rewrite CRmult_scale.
     apply (integral_lower_upper_bounded a' w (f a' - ' e) (f a' + ' e)).
     intros x [lo hi].
     apply in_CRball.
     apply (locallyUniformlyContinuous f a ww e).
      apply ball_gball...
     set (luc_mu f a ww e) in *.
     destruct q...
     apply in_Qball.
     split.
      unfold Qminus.
      rewrite <- (Qplus_0_r x).
      apply Qplus_le_compat...
      change (-q <= -0)%Q.
      apply Qopp_le_compat...
     apply Qle_trans with (a' + `w)%Q...
     apply Qplus_le_compat...
    Qed.
*)
    (** Iterating this result shows that Riemann sums are arbitrarily good approximations: *)

    Open Scope Q_scope.

    Lemma luc_gball (a w delta eps x y : Q) :
      0 < eps ->
      (delta <= lmu a w eps)%Qinf ->
      gball w a x -> gball w a y -> gball delta x y -> gball eps (f x) (f y).
    Proof.
     intros A A1 A2 A3 A4.
     destruct (luc_prf f lmu a w) as [_ H].
     change (f x) with (restrict f a w (exist _ _ A2)).
     change (f y) with (restrict f a w (exist _ _ A3)).
     apply H; [apply A |].
     destruct (lmu a w eps) as [q |] eqn:A5; [| easy].
     apply (mspc_monotone delta); [apply A1 | apply A4].
    Qed.

    Lemma Riemann_sums_approximate_integral (a: Q) (w: QnonNeg) (e: Qpos) (iw: Q) (n: nat):
     (S n * iw == w)%Q ->
     (iw <= lmu a w e)%Qinf ->
     gball (e * w) (cmΣ (S n) (fun i => 'iw * f (a + i * iw))%CR) (∫ f a w).
    Proof.
     intros A B.
     assert (ne_sn_0 : ~ S n == 0) by
        (change 0 with (inject_Z (Z.of_nat 0)); rewrite Q_of_nat_inj; apply S_O).
     assert (iw_nn : 0 <= iw) by
       (apply Qdiv_l in A; [| assumption]; rewrite A; apply Qmult_le_0_compat; [now auto|];
        apply Qinv_le_0_compat, Qle_nat). (* This should be automated *)
     set (iw' := exist _ iw iw_nn : QnonNeg ).
     change iw with (QnonNeg.to_Q iw').
     change (S n * iw' == w)%Qnn in A.
     rewrite <- A at 2.
     rewrite <- integral_repeated_additive.
     setoid_replace (e * w)%Q with (S n * (iw * e))%Q by
       (unfold QnonNeg.eq in A; simpl in A;
        rewrite Qmult_assoc; rewrite A; apply Qmult_comm).
     apply CRΣ_gball.
     intros m H.
     rewrite CRmult_scale.
     apply gball_sym. apply CRball.rational.
     setoid_replace (' (iw * e)) with (scale iw' (' ` e)) by now rewrite <- scale_Qmult.
     apply integral_bounded; [apply CRnonNegQpos |].
     intros x [A1 A2]. apply CRball.rational. apply (luc_gball a w (`iw')); trivial.
     + apply gball_Qabs.
       setoid_replace (a - (a + m * iw')) with (- (m * iw')) by ring.
       rewrite Qabs_opp. apply Qabs_le_nonneg; [Qauto_nonneg |].
       apply Qle_trans with (y := (S n * iw')).
       apply Qmult_le_compat_r. apply Qlt_le_weak. rewrite <- Zlt_Qlt. now apply inj_lt.
       apply (proj2_sig iw').
       change (S n * iw' == w) in A. rewrite <- A; reflexivity.
     + apply gball_Qabs, Qabs_Qle_condition.
       split.
       apply Qplus_le_l with (z := x), Qplus_le_l with (z := w).
       setoid_replace (- w + x + w) with x by ring. setoid_replace (a - x + x + w) with (a + w) by ring.
       apply Qle_trans with (y := (a + m * ` iw' + ` iw')); [easy |].
       setoid_rewrite <- (Qmult_1_l (` iw')) at 2. change 1%Q with (inject_Z (Z.of_nat 1)).
       rewrite <- Qplus_assoc, <- Qmult_plus_distr_l, <- Zplus_Qplus, <- Nat2Z.inj_add.
       apply Qplus_le_r. change (S n * iw' == w) in A. rewrite <- A.
       apply Qmult_le_compat_r. rewrite <- Zle_Qle. apply inj_le. rewrite Plus.plus_comm.
       now apply lt_le_S.
       apply (proj2_sig iw').
       apply Qplus_le_l with (z := x), Qplus_le_l with (z := -w).
       setoid_replace (a - x + x + - w) with (a - w) by ring.
       setoid_replace (w + x + - w) with x by ring.
       apply Qle_trans with (y := a). rewrite <- (Qplus_0_r a) at 2.
       apply Qplus_le_r. change 0 with (-0). apply Qopp_le_compat, (proj2_sig w).
       apply Qle_trans with (y := a + m * ` iw'); [| easy].
       rewrite <- (Qplus_0_r a) at 1. apply Qplus_le_r, Qmult_le_0_compat; [apply Qle_nat | apply (proj2_sig iw')].
     + apply gball_Qabs, Qabs_Qle_condition; split.
       apply (Qplus_le_r (x + `iw')).
       setoid_replace (x + `iw' + - `iw') with x by ring.
       setoid_replace (x + `iw' + (a + m * iw' - x)) with (a + m * iw' + `iw') by ring. apply A2.
       apply (Qplus_le_r (x - `iw')).
       setoid_replace (x - `iw' + (a + m * iw' - x)) with (a + m * iw' - `iw') by ring.
       setoid_replace (x - `iw' + `iw') with x by ring.
       apply Qle_trans with (y := a + m * iw'); [| easy].
       apply Qminus_less. apply (proj2_sig iw').
    Qed.

    Definition step (w : Q) (n : positive) : Q := w * (1 # n).

    Lemma step_nonneg (w : Q) (n : positive) : 0 <= w -> 0 <= step w n.
    Proof. intros w_nn; unfold step; Qauto_nonneg. Qed.

    Lemma step_0 (n : positive) : step 0 n == 0.
    Proof. unfold step; now rewrite Qmult_0_l. Qed.

    Lemma step_mult (w : Q) (n : positive) : (n : Q) * step w n == w.
    Proof.
      unfold step.
      rewrite Qmake_Qdiv. unfold Qdiv. rewrite Qmult_1_l, (Qmult_comm w), Qmult_assoc.
      rewrite Qmult_inv_r, Qmult_1_l; [reflexivity | auto with qarith].
    Qed.

    Definition riemann_sum (a w : Q) (n : positive) :=
      let iw := step w n in
        cmΣ (Pos.to_nat n) (fun i => 'iw * f (a + i * iw))%CR.

    (*Instance : Proper (Qeq ==> Qeq ==> eq ==> @st_eq CR) riemann_sum.
    Proof.
      intros a1 a2 Ea w1 w2 Ew n1 n2 En. apply cmΣ_proper; [now rewrite En |].
      intros i1 i2 Ei.*)

    Lemma riemann_sum_0 (a : Q) (n : positive) : riemann_sum a 0 n [=] 0%CR.
    Proof.
      unfold riemann_sum. apply cmΣ_0.
      intros m _. rewrite step_0.
      now setoid_replace (0 * f (a + m * 0))%CR with 0%CR by ring.
    Qed.

    Lemma Riemann_sums_approximate_integral' (a : Q) (w : QnonNeg) (e : Qpos) (n : positive) :
      (step w n <= lmu a w e)%Qinf ->
      gball (e * w) (riemann_sum a w n) (∫ f a w).
    Proof.
      intro A; unfold riemann_sum.
      destruct (Pos2Nat.is_succ n) as [m M]. rewrite M.
      apply Riemann_sums_approximate_integral; [rewrite <- M | easy].
      unfold step. change (Pos.to_nat n * (w * (1 # n)) == w).
      rewrite positive_nat_Z. unfold inject_Z. rewrite !Qmake_Qdiv; field; auto.
    Qed.

    Lemma integral_approximation (a : Q) (w : QnonNeg) (e : Qpos) :
      exists N : positive, forall n : positive, (N <= n)%positive ->
        mspc_ball e (riemann_sum a w n) (∫ f a w).
    Proof.
    destruct (Qlt_le_dec 1 w) as [A1 | A1].
    * assert (0 < w) by (apply (Qlt_trans _ 1); auto with qarith).
      set (N := Z.to_pos (Qceiling (comp_inf (λ x, w / x) (lmu a w) 0 (e / w)))).
      exists N; intros n A2.
      setoid_replace (QposAsQ e) with (e / w * w) by (field; auto with qarith).
      (* [apply Riemann_sums_approximate_integral'] does not unify because in
      this lemma, the radius is [(QposAsQ e) * (QnonNeg.to_Q w)], and in the
      goal the radius is [(QposAsQ e) / (QnonNeg.to_Q w) * (QnonNeg.to_Q w)]. *)
      assert (P : 0 < e / w) by (apply Qmult_lt_0_compat; [| apply Qinv_lt_0_compat]; auto).
      change (e / w) with (QposAsQ (mkQpos P)).
      apply Riemann_sums_approximate_integral'.
      change (QposAsQ (mkQpos P)) with (e / w).
      destruct (lmu a w (e / w)) as [mu |] eqn:A3; [| easy].
      subst N; unfold comp_inf in A2; rewrite A3 in A2.
      change (step w n <= mu); unfold step.
      rewrite Qmake_Qdiv, injZ_One; unfold Qdiv; rewrite Qmult_assoc, Qmult_1_r.
      assert (A4 : 0 < mu) by (change (Qinf.lt 0 mu); rewrite <- A3;
        apply (uc_pos (restrict f a w) (lmu a w)); trivial).
      apply Qle_div_l; auto.
      now apply Z.Ple_Zle_to_pos, Q.Zle_Qle_Qceiling in A2.
    * set (N := Z.to_pos (Qceiling (comp_inf (λ x, 1 / x) (lmu a w) 0 e))).
      exists N; intros n A2.
      apply (mspc_monotone (e * w)).
      + change (e * w <= e). rewrite <- (Qmult_1_r e) at 2. apply Qmult_le_compat_l; auto.
      + apply Riemann_sums_approximate_integral'.
        destruct (lmu a w e) as [mu |] eqn:A3; [| easy].
        subst N; unfold comp_inf in A2; rewrite A3 in A2.
        change (step w n <= mu); unfold step.
        rewrite Qmake_Qdiv, injZ_One; unfold Qdiv; rewrite Qmult_assoc, Qmult_1_r.
        assert (A4 : 0 < mu) by (change (Qinf.lt 0 mu); rewrite <- A3;
          apply (uc_pos (restrict f a w) (lmu a w)), (proj2_sig e)).
        apply Qle_div_l; auto.
        apply Z.Ple_Zle_to_pos, Q.Zle_Qle_Qceiling in A2.
        apply (Qle_trans _ (1 / mu)); trivial. apply Qmult_le_compat_r; trivial.
        now apply Qinv_le_0_compat, Qlt_le_weak.
    Qed.

  (** Unicity itself will of course have to be stated w.r.t. *two* integrals: *)
(*
  Lemma unique
    `{!LocallyUniformlyContinuous_mu f} `{!LocallyUniformlyContinuous f}
    (c1: Integral f)
    (c2: Integral f)
    (P1: @Integrable c1)
    (P2: @Integrable c2):
  forall (a: Q) (w: QnonNeg),
    @integrate f c1 a w == @integrate f c2 a w.
  Proof with auto.
   intros. apply ball_eq. intros.
   revert w.
   apply QnonNeg.Qpos_ind.
     intros ?? E. rewrite E. reflexivity.
    do 2 rewrite zero_width_integral...
   intro x.
   destruct (split x (@uc_mu _ _ _ (@luc_mu Q _ CR f _ (a, x)) ((1 # 2) * e * Qpos_inv x)))%Qpos as [[n t] [H H0]].
   simpl in H.
   simpl @snd in H0.
   setoid_replace e with (((1 # 2) * e / x) * x + ((1 # 2) * e / x) * x)%Qpos by (unfold QposEq; simpl; field)...
   apply ball_triangle with (cmΣ n (fun i: nat => (' `t * f (a + i * `t)%Q))).
    apply ball_sym.
    apply ball_gball.
    apply (Riemann_sums_approximate_integral a x ((1 # 2) * e / x)%Qpos t n H H0).
   apply ball_gball.
   apply (Riemann_sums_approximate_integral a x ((1 # 2) * e / x)%Qpos t n H H0).
  Qed.
*)

End integral_approximation.

(** If f==g, then an integral for f is an integral for g. *)

Lemma Integrable_proper_l (f g: Q → CR) {fint: Integral f}:
  canonical_names.equiv f g → Integrable f → @Integrable g fint.
Proof with auto.
 constructor.
   replace (@integrate g) with (@integrate f) by reflexivity.
   intros.
   apply integral_additive.
  replace (@integrate g) with (@integrate f) by reflexivity.
  intros.
  apply integral_bounded_prim...
  intros.
  rewrite (H x x (refl_equal _))...
 replace (@integrate g) with (@integrate f) by reflexivity.
 apply integral_wd...
Qed.

Import canonical_names abstract_algebra.

Local Open Scope mc_scope.

Add Ring CR : (rings.stdlib_ring_theory CR).

Lemma mult_comm `{SemiRing R} : Commutative (.*.).
Proof. apply commonoid_commutative with (Aunit := one), _. Qed.

Lemma mult_assoc `{SemiRing R} (x y z : R) : x * (y * z) = x * y * z.
Proof. apply sg_ass, _. Qed.

(* Should this lemma be used to CoRN.reals.fast.CRabs? That file does not use
type class notations from canonical_names like ≤ *)

Lemma CRabs_nonneg (x : CR) : 0 ≤ abs x.
Proof.
apply -> CRabs_cases; [| apply _ | apply _].
split; [trivial | apply (proj1 (rings.flip_nonpos_negate x))].
Qed.

Lemma cmΣ_empty {M : CMonoid} (f : nat -> M) : cmΣ 0 f = [0].
Proof. reflexivity. Qed.

Lemma cmΣ_succ {M : CMonoid} (n : nat) (f : nat -> M) : cmΣ (S n) f = f n [+] cmΣ n f.
Proof. reflexivity. Qed.

Lemma cmΣ_plus (n : nat) (f g : nat -> CR) : cmΣ n (f + g) = cmΣ n f + cmΣ n g.
Proof.
induction n as [| n IH].
+ symmetry; apply cm_rht_unit.
+ rewrite !cmΣ_succ. rewrite IH.
  change (f n + g n + (cmΣ n f + cmΣ n g) = f n + cmΣ n f + (g n + cmΣ n g)).
  change (CRasCMonoid : Type) with (CR : Type). ring.
Qed.

Lemma cmΣ_negate (n : nat) (f : nat -> CR) : cmΣ n (- f) = - cmΣ n f.
Proof.
induction n as [| n IH].
+ change ((0 : CR) = - 0). (* [change (0 = - 0)] loops *) ring.
+ rewrite !cmΣ_succ. rewrite IH.
  change (- f n - cmΣ n f = - (f n + cmΣ n f)).
  change (CRasCMonoid : Type) with (CR : Type). (* Why the last command? *) ring.
Qed.

Lemma cmΣ_const (n : nat) (m : CR) : cmΣ n (λ _, m) = m * '(n : Q).
Proof.
induction n as [| n IH].
+ rewrite cmΣ_empty. change (0 = m * 0). symmetry; apply rings.mult_0_r.
+ rewrite cmΣ_succ, IH, S_Qplus, <- CRplus_Qplus.
  change (m + m * '(n : Q) = m * ('(n : Q) + 1)). ring.
Qed.

Lemma riemann_sum_const (a : Q) (w : Q) (m : CR) (n : positive) :
  riemann_sum (λ _, m) a w n = 'w * m.
Proof.
unfold riemann_sum. rewrite cmΣ_const, positive_nat_Z.
change ('step w n * m * '(n : Q) = 'w * m).
rewrite (mult_comm _ ('(n : Q))), mult_assoc, CRmult_Qmult, step_mult; reflexivity.
Qed.

Lemma riemann_sum_plus (f g : Q -> CR) (a w : Q) (n : positive) :
  riemann_sum (f + g) a w n = riemann_sum f a w n + riemann_sum g a w n.
Proof.
unfold riemann_sum. rewrite <- cmΣ_plus. apply cm_Sum_eq. intro k.
change (
  cast Q CR (step w n) * (f (a + (k : Q) * step w n) + g (a + (k : Q) * step w n)) =
  cast Q CR (step w n) * f (a + (k : Q) * step w n) + cast Q CR (step w n) * g (a + (k : Q) * step w n)).
apply rings.plus_mult_distr_l. (* Without [change] unification fails, [apply:] loops *)
Qed.

Lemma riemann_sum_negate (f : Q -> CR) (a w : Q) (n : positive) :
  riemann_sum (- f) a w n = - riemann_sum f a w n.
Proof.
unfold riemann_sum. rewrite <- cmΣ_negate. apply cm_Sum_eq. intro k.
change ('step w n * (- f (a + (k : Q) * step w n)) = -('step w n * f (a + (k : Q) * step w n))).
ring.
Qed.

Section RiemannSumBounds.

Context (f : Q -> CR).

Global Instance Qle_nat (n : nat) : PropHolds (0 ≤ (n : Q)).
Proof. apply Qle_nat. Qed.

Instance step_nonneg' (w : Q) (n : positive) : PropHolds (0 ≤ w) -> PropHolds (0 ≤ step w n).
Proof. apply step_nonneg. Qed.

Lemma index_inside_l (a w : Q) (k : nat) (n : positive) :
  0 ≤ w -> k < Pos.to_nat n -> a ≤ a + (k : Q) * step w n.
Proof. intros; apply semirings.nonneg_plus_le_compat_r; solve_propholds. Qed.

Lemma index_inside_r (a w : Q) (k : nat) (n : positive) :
  0 ≤ w -> k < Pos.to_nat n -> a + (k : Q) * step w n ≤ a + w.
Proof.
intros A1 A2. apply (orders.order_preserving (a +)).
mc_setoid_replace w with ((n : Q) * (step w n)) at 2 by (symmetry; apply step_mult).
apply (orders.order_preserving (.* step w n)).
rewrite <- Zle_Qle, <- positive_nat_Z. apply inj_le. change (k ≤ Pos.to_nat n). solve_propholds.
Qed.

Lemma riemann_sum_bounds (a w : Q) (m : CR) (e : Q) (n : positive) :
  0 ≤ w -> (forall (x : Q), (a ≤ x ≤ a + w) -> gball e (f x) m) ->
  gball (w * e) (riemann_sum f a w n) ('w * m).
Proof.
intros w_nn A. rewrite <- (riemann_sum_const a w m n). unfold riemann_sum.
rewrite <- (step_mult w n), <- (Qmult_assoc n _ e), <- (positive_nat_Z n).
apply CRΣ_gball. intros k A1. apply CRball.gball_CRmult_Q_nonneg; [now apply step_nonneg |].
apply A. split; [apply index_inside_l | apply index_inside_r]; trivial.
Qed.

End RiemannSumBounds.

Section IntegralBound.

Context (f : Q -> CR) `{Integrable f}.

Lemma scale_0_r (x : Q) : scale x 0 = 0.
Proof. rewrite <- CRmult_scale; change (cast Q CR x * 0 = 0); ring. Qed.

Require Import propholds.

Lemma integral_abs_bound (from : Q) (width : QnonNeg) (M : Q) :
  (forall (x : Q), (from ≤ x ≤ from + width) -> CRabs (f x) ≤ 'M) ->
  CRabs (∫ f from width) ≤ '(`width * M).
Proof.
intro A. rewrite <- (CRplus_0_r (∫ f from width)), <- CRopp_0.
apply CRball.as_distance_bound. rewrite <- (scale_0_r width).
rewrite <- CRmult_Qmult, CRmult_scale.
apply integral_bounded; trivial.
+ apply CRnonNeg_le_0.
  apply CRle_trans with (y := CRabs (f from)); [apply CRabs_nonneg |].
  apply A. split; [reflexivity |].
  apply semirings.nonneg_plus_le_compat_r; change (0 <= width)%Q; Qauto_nonneg.
+ intros x A2. apply CRball.as_distance_bound. rewrite CRdistance_comm.
  change (CRabs (f x - 0) ≤ 'M).
  rewrite rings.minus_0_r; now apply A.
Qed.

(*apply CRball.as_distance_bound, CRball.rational. rewrite <- (scale_0_r width).
assert (A1 : 0 ≤ M).
+ apply CRle_Qle. apply CRle_trans with (y := CRabs (f from)); [apply CRabs_nonneg |].
  apply A. split; [reflexivity |].
  apply semirings.nonneg_plus_le_compat_r; change (0 <= width)%Q; Qauto_nonneg.
+ change M with (QnonNeg.to_Q (exist _ M A1)).
  apply bounded_with_nonneg_radius; [easy |].
  intros x A2. apply CRball.gball_CRabs. change (f x - 0%mc)%CR with (f x - 0).
  rewrite rings.minus_0_r; now apply A.
Qed.*)

End IntegralBound.

(*
Section IntegralOfSum.

Context (f g : Q -> CR)
        `{!IsLocallyUniformlyContinuous f f_mu, !IsLocallyUniformlyContinuous g g_mu}
        `{Integral f, !Integrable f, Integral g, !Integrable g}.

Global Instance integrate_sum : Integral (f + g) := λ a w, integrate f a w + integrate g a w.
Global Instance integrate_negate : Integral (- f) := λ a w, - integrate f a w.

Lemma integral_sum_additive (a : Q) (b c : QnonNeg) :
   ∫ (f + g) a b + ∫ (f + g) (a + ` b) c = ∫ (f + g) a (b + c)%Qnn.
Proof.
unfold integrate, integrate_sum.
rewrite <- !integral_additive; trivial.
change (
  ∫ f a b + ∫ g a b + (∫ f (a + ` b) c + ∫ g (a + ` b) c) =
  (∫ f a b + ∫ f (a + ` b) c) + (∫ g a b + ∫ g (a + ` b) c)). ring.
Qed.

Lemma integral_negate_additive (a : Q) (b c : QnonNeg) :
   ∫ (- f) a b + ∫ (- f) (a + ` b) c = ∫ (- f) a (b + c)%Qnn.
Proof.
unfold integrate, integrate_negate.
rewrite <- rings.negate_plus_distr. apply CRopp_wd_Proper. (* Where is it defined? *)
now apply integral_additive.
Qed.


(* When the last argument of ball is ('(width * mid)), typechecking diverges *)

Lemma integral_sum_integrable (from : Q) (width : Qpos) (mid : Q) (r : Qpos) :
 (∀ x : Q, from ≤ x ≤ from + width → ball r (f x + g x) ('mid))
 → ball (width * r) (∫ (f + g) from width) ('((width : Q) * mid)).
Proof.
intros A. apply ball_gball; simpl. apply gball_closed. intros e e_pos.
setoid_replace (width * r + e)%Q with (e + width * r)%Q by apply Qplus_comm.
destruct (Riemann_sums_approximate_integral'' f from width ((1#2) * mkQpos e_pos)%Qpos) as [Nf F].
destruct (Riemann_sums_approximate_integral'' g from width ((1#2) * mkQpos e_pos)%Qpos) as [Ng G].
set (n := Pos.max Nf Ng).
assert (le_Nf_n : (Nf <= n)%positive) by apply Pos.le_max_l.
assert (le_Ng_n : (Ng <= n)%positive) by apply Pos.le_max_r.
specialize (F n le_Nf_n). specialize (G n le_Ng_n).
apply gball_triangle with (b := riemann_sum (f + g) from width n).
+ rewrite riemann_sum_plus. setoid_replace e with ((1#2) * e + (1#2) * e)%Q by ring.
  apply CRgball_plus; apply gball_sym; trivial.
+ (* apply riemann_sum_bounds. diverges *)
  rewrite <- CRmult_Qmult. apply riemann_sum_bounds; [solve_propholds |].
  intros. apply ball_gball. apply A; trivial.
Qed.

(*Lemma integral_negate_integrable (from : Q) (width : Qpos) (mid : Q) (r : Qpos) :
 (∀ x : Q, from ≤ x ≤ from + width → ball r ((- f) x) ('mid))
 → ball (width * r) (∫ (- f) from width) ('((width : Q) * mid)).
Proof.
intros A. unfold integrate, integrate_negate.
SearchAbout gball CRopp.
SearchAbout (gball _ (CRopp _) (CRopp _)).*)

Global Instance : Integrable (f + g).
constructor.
+ apply integral_sum_additive.
+ apply integral_sum_integrable.
+ intros a1 a2 A1 w1 w2 A2. unfold integrate, integrate_sum. rewrite A1, A2; reflexivity.
Qed.

End IntegralOfSum.
*)

Add Field Q : (dec_fields.stdlib_field_theory Q).

(* In theory.rings, we have

[rings.plus_assoc : ... Associative plus]

and

[rings.plus_comm : ... Commutative plus].

One difference is that [Commutative] is defined directly while
[Associative] is defined through [HeteroAssociative]. For this or some
other reason, rewriting [rings.plus_comm] works while rewriting
[rings.plus_assoc] does not. Interestingly, all arguments before x y z in
[rings.plus_assoc] are implicit, and when we make [R] explicit, rewriting
works. However, in this case [rewrite] leaves a goal [SemiRing R], which is
not solved by [trivial], [auto] or [easy], but only by [apply _]. If
[rings.plus_assoc] is formulated as [x + (y + z) = (x + y) + z] instead of
[Associative plus], then rewriting works; however, then it cannot be an
instance (of [Associative]). Make this change in theory.rings? *)

Lemma plus_assoc `{SemiRing R} : forall (x y z : R), x + (y + z) = (x + y) + z.
Proof. exact simple_associativity. Qed.

Section RingFacts.

Context `{Ring R}.

Lemma plus_left_cancel (z x y : R) : z + x = z + y <-> x = y.
Proof.
split.
(* [apply (left_cancellation (+)).] leaves the goal [LeftCancellation plus z],
which is solved by [apply _]. Why is it left? *)
+ apply (left_cancellation (+) z).
+ intro A; now rewrite A.
Qed.

Lemma plus_right_cancel (z x y : R) : x + z = y + z <-> x = y.
Proof. rewrite (rings.plus_comm x z), (rings.plus_comm y z); apply plus_left_cancel. Qed.

Lemma plus_eq_minus (x y z : R) : x + y = z <-> x = z - y.
Proof.
split; intro A.
+ apply (right_cancellation (+) y).
  now rewrite <- plus_assoc, rings.plus_negate_l, rings.plus_0_r.
+ apply (right_cancellation (+) (-y)).
  now rewrite <- plus_assoc, rings.plus_negate_r, rings.plus_0_r.
Qed.

Lemma minus_eq_plus (x y z : R) : x - y = z <-> x = z + y.
Proof. now rewrite plus_eq_minus, rings.negate_involutive. Qed.

Lemma negate_inj (x y : R) : -x = -y <-> x = y.
Proof. now rewrite rings.flip_negate, rings.negate_involutive. Qed.

End RingFacts.

Import interfaces.orders orders.minmax theory.rings.

Lemma join_comm `{JoinSemiLatticeOrder L} : Commutative join.
Proof.
intros x y. apply antisymmetry with (R := (≤)); [apply _ | |];
(apply join_lub; [apply join_ub_r | apply join_ub_l]).
(* why is [apply _] needed? *)
Qed.

Lemma meet_comm `{MeetSemiLatticeOrder L} : Commutative meet.
Proof.
intros x y. apply antisymmetry with (R := (≤)); [apply _ | |];
(apply meet_glb; [apply meet_lb_r | apply meet_lb_l]).
Qed.

Definition Range (T : Type) := prod T T.

Instance contains_Q : Contains Q (Range Q) := λ x s, (fst s ⊓ snd s ≤ x ≤ fst s ⊔ snd s).

Lemma Qrange_comm (a b x : Q) : x ∈ (a, b) <-> x ∈ (b, a).
Proof.
unfold contains, contains_Q; simpl.
rewrite join_comm, meet_comm; reflexivity.
Qed.

Lemma range_le (a b : Q) : a ≤ b -> forall x, a ≤ x ≤ b <-> x ∈ (a, b).
Proof.
intros A x; unfold contains, contains_Q; simpl.
mc_setoid_replace (meet a b) with a by now apply lattices.meet_l.
mc_setoid_replace (join a b) with b by now apply lattices.join_r. reflexivity.
Qed.

Lemma CRabs_negate (x : CR) : abs (-x) = abs x.
Proof.
change (abs (-x)) with (CRabs (-x)).
rewrite CRabs_opp; reflexivity.
Qed.

Lemma mspc_ball_Qle (r a x : Q) : mspc_ball r a x <-> a - r ≤ x ≤ a + r.
Proof. rewrite mspc_ball_Qabs; apply Qabs_diff_Qle. Qed.

Lemma mspc_ball_convex (x1 x2 r a x : Q) :
  mspc_ball r a x1 -> mspc_ball r a x2 -> x ∈ (x1, x2) -> mspc_ball r a x.
Proof.
intros A1 A2 A3.
rewrite mspc_ball_Qle in A1, A2. apply mspc_ball_Qle.
destruct A1 as [A1' A1'']; destruct A2 as [A2' A2'']; destruct A3 as [A3' A3'']. split.
+ now transitivity (meet x1 x2); [apply meet_glb |].
+ now transitivity (join x1 x2); [| apply join_lub].
Qed.

Section IntegralTotal.

Context (f : Q -> CR) `{Integrable f}.

Program Definition int (from to : Q) :=
  if (decide (from ≤ to))
  then integrate f from (to - from)
  else -integrate f to (from - to).
Next Obligation.
change (0 ≤ to - from). (* without [change], the following [apply] does not work *)
now apply rings.flip_nonneg_minus.
Qed.
Next Obligation.
change (0 ≤ from - to).
(* [apply rings.flip_nonneg_minus, orders.le_flip] does not work *)
apply rings.flip_nonneg_minus; now apply orders.le_flip.
Qed.

Lemma integral_additive' (a b : Q) (u v w : QnonNeg) :
  a + `u = b -> `u + `v = `w -> ∫ f a u + ∫ f b v = ∫ f a w.
Proof.
intros A1 A2. change (u + v = w)%Qnn in A2.
rewrite <- A1, <- A2. now apply integral_additive.
Qed.

Lemma int_add (a b c : Q) : int a b + int b c = int a c.
Proof with apply integral_additive'; simpl; ring.
unfold int.
destruct (decide (a ≤ b)) as [AB | AB];
destruct (decide (b ≤ c)) as [BC | BC];
destruct (decide (a ≤ c)) as [AC | AC].
+ idtac...
+ assert (A : a ≤ c) by (now transitivity b); elim (AC A).
+ apply minus_eq_plus; symmetry...
+ rewrite minus_eq_plus, (rings.plus_comm (-integrate _ _ _)), <- plus_eq_minus, (rings.plus_comm (integrate _ _ _))...
+ rewrite (rings.plus_comm (-integrate _ _ _)), minus_eq_plus, (rings.plus_comm (integrate _ _ _)); symmetry...
+ rewrite (rings.plus_comm (-integrate _ _ _)), minus_eq_plus, (rings.plus_comm (-integrate _ _ _)), <- plus_eq_minus...
+ assert (b ≤ a) by (now apply orders.le_flip); assert (B : b ≤ c) by (now transitivity a); elim (BC B).
+ rewrite <- rings.negate_plus_distr, negate_inj, (rings.plus_comm (integrate _ _ _))...
Qed.

Lemma int_diff (a b c : Q) : int a b - int a c = int c b.
Proof. apply minus_eq_plus. rewrite rings.plus_comm. symmetry; apply int_add. Qed.

Lemma int_zero_width (a : Q) : int a a = 0.
Proof. apply (plus_right_cancel (int a a)); rewrite rings.plus_0_l; apply int_add. Qed.

Lemma int_opposite (a b : Q) : int a b = - int b a.
Proof.
apply rings.equal_by_zero_sum. rewrite rings.negate_involutive, int_add. apply int_zero_width.
Qed.

Lemma int_abs_bound (a b M : Q) :
  (forall x : Q, x ∈ (a, b) -> abs (f x) ≤ 'M) -> abs (int a b) ≤ '(abs (b - a) * M).
Proof.
intros A. unfold int. 
(* Looks like a type class regression *)
 admit. (*destruct (decide (a ≤ b)) as [AB | AB];
[| pose proof (orders.le_flip _ _ AB); mc_setoid_replace (b - a) with (-(a - b)) by ring;
   rewrite CRabs_negate, abs.abs_negate];
rewrite abs.abs_nonneg by (now apply rings.flip_nonneg_minus);
apply integral_abs_bound; trivial; (* [Integrable f] is not discharged *)
intros x A1; apply A.
+ apply -> range_le; [| easy].
  now mc_setoid_replace b with (a + (b - a)) by ring.
+ apply Qrange_comm. apply -> range_le; [| easy].
  now mc_setoid_replace a with (b + (a - b)) by ring.*)
Qed.

(* [SearchAbout (CRabs (- ?x)%CR)] does not find [CRabs_opp] *)

End IntegralTotal.

(*Lemma int_plus (f g : Q -> CR) `{Integrable f, Integrable g}
  `{!IsLocallyUniformlyContinuous f f_mu, !IsLocallyUniformlyContinuous f f_mu} (a b : Q) :
  int f a b + int g a b = int (f + g) a b.
Proof.
unfold int. destruct (decide (a ≤ b)); [reflexivity |].
symmetry; unfold integrate at 1, integrate_sum.
apply rings.negate_plus_distr. (* does not work without unfold *)
Qed.*)

Lemma integrate_plus (f g : Q -> CR)
  `{!IsUniformlyContinuous f f_mu, !IsUniformlyContinuous g g_mu} (a : Q) (w : QnonNeg) :
  ∫ (f + g) a w = ∫ f a w + ∫ g a w.
Proof.
apply mspc_closed. intros e e_pos. (* Why is 0%Q? *)
mc_setoid_replace (0 + e) with e by ring.
assert (he_pos : 0 < e / 2) by solve_propholds.
assert (qe_pos : 0 < e / 4) by solve_propholds.
destruct (integral_approximation f a w (mkQpos qe_pos)) as [Nf F].
destruct (integral_approximation g a w (mkQpos qe_pos)) as [Ng G].
destruct (integral_approximation (f + g) a w (mkQpos he_pos)) as [Ns S].
(* [Le positive] is not yet defined *)
set (n := Pos.max (Pos.max Nf Ng) Ns).
assert (Nf <= n)%positive by (transitivity (Pos.max Nf Ng); apply Pos.le_max_l).
assert (Ng <= n)%positive by (transitivity (Pos.max Nf Ng); [apply Pos.le_max_r | apply Pos.le_max_l]).
assert (Ns <= n)%positive by apply Pos.le_max_r.
apply (mspc_triangle' (e / 2) (e / 2) (riemann_sum (f + g) a w n)). 
  (* regression connected to numbers ? [field; discriminate | |].*) admit.
* apply mspc_symm, S; assumption.
* rewrite riemann_sum_plus.
  mc_setoid_replace (e / 2) with (e / 4 + e / 4) by (field; split; discriminate).
  now apply mspc_ball_CRplus; [apply F | apply G].
Qed.

Lemma integrate_negate (f : Q -> CR)
  `{!IsUniformlyContinuous f f_mu} (a : Q) (w : QnonNeg) : ∫ (- f) a w = - ∫ f a w.
Proof.
apply mspc_closed. intros e e_pos.
mc_setoid_replace (0 + e) with e by ring.
assert (he_pos : 0 < e / 2) by solve_propholds.
destruct (integral_approximation (- f) a w (mkQpos he_pos)) as [N1 F1].
destruct (integral_approximation f a w (mkQpos he_pos)) as [N2 F2].
set (n := Pos.max N1 N2).
assert (N1 <= n)%positive by apply Pos.le_max_l.
assert (N2 <= n)%positive by apply Pos.le_max_r.
apply (mspc_triangle' (e / 2) (e / 2) (riemann_sum (- f) a w n)).
(* regression connected to numbers ? [field; discriminate | |].*) admit.
* now apply mspc_symm, F1.
* rewrite riemann_sum_negate. now apply mspc_ball_CRnegate, F2.
Qed.

Lemma int_plus (f g : Q -> CR)
  `{!IsUniformlyContinuous f f_mu, !IsUniformlyContinuous g g_mu} (a b : Q) :
  int (f + g) a b = int f a b + int g a b.
Proof.
unfold int; destruct (decide (a ≤ b)); rewrite integrate_plus; ring.
Qed.

Lemma int_negate (f : Q -> CR) `{!IsUniformlyContinuous f f_mu} (a b : Q) :
  int (- f) a b = - int f a b.
Proof.
unfold int; destruct (decide (a ≤ b)); rewrite integrate_negate; reflexivity.
Qed.

Lemma int_minus (f g : Q -> CR)
  `{!IsUniformlyContinuous f f_mu, !IsUniformlyContinuous g g_mu} (a b : Q) :
  int (f - g) a b = int f a b - int g a b.
Proof. rewrite int_plus, int_negate; reflexivity. Qed.

Import interfaces.orders orders.semirings.

Definition Qupper_bound (x : CR) := approximate x 1%Qpos + 1.

(* To be proved by lifting from Q.
Lemma CRabs_triang (x y z : CR) : x = y + z -> abs x ≤ abs y + abs z.
*)

(* The section IntegralLipschitz is not used in the ODE solver through
Picard iterations. Instead of assuming the function that is being
integrated to be Lipschitz, the development assumes that it is uniformly
continuous and bounded. Then integral is Lispchitz, but it is only proved
that it is uniformly continuous. *)

Section IntegralLipschitz.

Notation ball := mspc_ball.

Context (f : Q -> CR) (x0 : Q) `{!IsLocallyLipschitz f L} `{Integral f, !Integrable f}.

Let F (x : Q) := int f x0 x.

Section IntegralLipschitzBall.

Variables (a r x1 x2 : Q).

Hypotheses (I1 : ball r a x1) (I2 : ball r a x2) (r_nonneg : 0 ≤ r).

Let La := L a r.

Lemma int_lip (e M : Q) :
  (∀ x, ball r a x -> abs (f x) ≤ 'M) -> ball e x1 x2 -> ball (M * e) (F x1) (F x2).
Proof.
intros A1 A2. apply CRball.gball_CRabs. subst F; cbv beta.
change (int f x0 x1 - int f x0 x2)%CR with (int f x0 x1 - int f x0 x2).
rewrite int_diff; [| trivial]. (* Why does it leave the second subgoal [Integrable f]? *)
change (abs (int f x2 x1) ≤ '(M * e)).
transitivity ('(M * abs (x1 - x2))).
+ rewrite mult_comm. apply int_abs_bound; trivial. intros x A3; apply A1, (mspc_ball_convex x2 x1); easy.
+ apply CRle_Qle. assert (0 ≤ M).
  - apply CRle_Qle. transitivity (abs (f a)); [apply CRabs_nonneg | apply A1, mspc_refl]; easy.
  - change (M * abs (x1 - x2) ≤ M * e). apply (orders.order_preserving (M *.)).
    apply gball_Qabs, A2.
Qed.

End IntegralLipschitzBall.

Lemma lipschitz_bounded (a r M x : Q) :
  abs (f a) ≤ 'M -> ball r a x -> abs (f x) ≤ '(M + L a r * r).
Proof.
intros A1 A2. mc_setoid_replace (f x) with (f x - 0) by ring.
apply mspc_ball_CRabs, mspc_symm.
(* [apply mspc_triangle with (c := f a)] does not work *)
apply (mspc_triangle _ _ _ (f a)).
+ apply mspc_ball_CRabs. mc_setoid_replace (0 - f a) with (- f a) by ring.
  now rewrite CRabs_negate.
+ apply llip; trivial. now apply mspc_refl, (radius_nonneg a x).
Qed.

Global Instance integral_lipschitz :
  IsLocallyLipschitz F (λ a r, Qupper_bound (abs (f a)) + L a r * r).
Proof.
intros a r r_nonneg. constructor.
+ apply nonneg_plus_compat.
  - apply CRle_Qle. transitivity (abs (f a)); [apply CRabs_nonneg | apply upper_CRapproximation].
  - apply nonneg_mult_compat; [apply (lip_nonneg (restrict f a r)) |]; auto.
    (* Not good to provide [(restrict f a r)]. [IsLipschitz (restrict f a r) (L a r)] is generated *)
+ intros x1 x2 d A.
  destruct x1 as [x1 A1]; destruct x2 as [x2 A2].
  change (ball ((Qupper_bound (abs (f a)) + L a r * r) * d) (F x1) (F x2)).
  apply (int_lip a r); trivial.
  intros x B. now apply lipschitz_bounded; [apply upper_CRapproximation |].
Qed.

End IntegralLipschitz.

Import minmax (*Coq.Program.*)Basics.

(*Global Instance Qball_decidable (r : Qinf) (a x : Q) : Decision (mspc_ball r a x).
destruct r as [r |]; [| now left].
apply (decision_proper (Qabs (a - x) <= r)%Q); [symmetry; apply gball_Qabs | apply _].
Defined.*)

Section AbsFacts.

Context `{Ring R} `{!FullPseudoSemiRingOrder Rle Rlt} `{!Abs R}.

(* Should this be made a Class? It seems particular and complicated *)
Definition abs_cases_statement (P : R -> Prop) :=
  Proper (equiv ==> iff) P -> (forall x, Stable (P x)) ->
    forall x : R, (0 ≤ x -> P x) /\ (x ≤ 0 -> P (- x)) -> P (abs x).

Context `(abs_cases : forall P : R -> Prop, abs_cases_statement P)
        `{le_stable : forall x y : R, Stable (x ≤ y)}.

Lemma abs_nonneg' (x : R) : 0 ≤ abs x.
Proof.
apply abs_cases.
+ intros y1 y2 E; now rewrite E.
+ apply _.
+ split; [trivial |]. intros ?; now apply rings.flip_nonpos_negate.
Qed.

End AbsFacts.

Lemma Qabs_cases : forall P : Q -> Prop, abs_cases_statement P.
Proof.
intros P Pp Ps x [? ?].
destruct (decide (0 ≤ x)) as [A | A];
  [rewrite abs.abs_nonneg | apply le_flip in A; rewrite abs.abs_nonpos]; auto.
(* [easy] instead of [auto] does not work *)
Qed.

Lemma Qabs_nonneg (x : Q) : 0 ≤ abs x.
Proof. apply abs_nonneg'; [apply Qabs_cases | apply _]. Qed.

(*
Lemma integrate_proper
  (f g: Q → CR)
  `{!LocallyUniformlyContinuous_mu g}
  `{!LocallyUniformlyContinuous g}
  {fint: Integral f}
  {gint: Integral g}
  `{!@Integrable f fint}
  `{!@Integrable g gint}:
  canonical_names.equiv f g →
  ∀ (a: Q) (w: QnonNeg),
  @integrate f fint a w == @integrate g gint a w.
    (* This requires continuity for g only because [unique] does. *)
Proof with try assumption.
 intros.
 apply (unique g)...
 apply (Integrable_proper_l f)...
Qed.
*)
