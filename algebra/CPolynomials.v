(* $Id$ *)

(** printing _X_ %\ensuremath{x}% *)
(** printing _C_ %\ensuremath\diamond% *)
(** printing [+X*] %\ensuremath{+x\times}% #+x&times;# *)
(** printing RX %\ensuremath{R[x]}% #R[x]# *)
(** printing FX %\ensuremath{F[x]}% #F[x]# *)

Require Export RingReflection.

(** * Polynomials
The first section only proves the polynomials form a ring, and nothing more
interesting.
Section%~\ref{section:poly-equality}% gives some basic properties of
equality and induction of polynomials.
** Definition of polynomials; they form a ring
%\label{section:poly-ring}%
*)

Section CPoly_CRing.
(**
%\begin{convention}% Let [CR] be a ring.
%\end{convention}%
*)

Variable CR : CRing.

(**
The intuition behind the type [cpoly] is the following
- [(cpoly CR)] is $CR[X]$ #CR[X]#;
- [cpoly_zero] is the `empty' polynomial with no coefficients;
- [(cpoly_linear c p)] is [c[+]X[*]p]

*)

Inductive cpoly : Type :=
  | cpoly_zero   : cpoly
  | cpoly_linear : CR -> cpoly -> cpoly.

Definition cpoly_constant (c : CR) : cpoly := cpoly_linear c cpoly_zero.

Definition cpoly_one : cpoly := cpoly_constant One.

(**
Some useful induction lemmas for doubly quantified propositions.
*)

Lemma Ccpoly_double_ind0 : forall P : cpoly -> cpoly -> CProp,
 (forall p, P p cpoly_zero) -> (forall p, P cpoly_zero p) ->
 (forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
simple induction p; auto.
simple induction q; auto.
Qed.

Lemma Ccpoly_double_sym_ind0 : forall P : cpoly -> cpoly -> CProp,
 Csymmetric P -> (forall p, P p cpoly_zero) -> 
(forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
intros.
apply Ccpoly_double_ind0; auto.
Qed.

Lemma Ccpoly_double_ind0' : forall P : cpoly -> cpoly -> CProp,
 (forall p, P cpoly_zero p) -> (forall p c, P (cpoly_linear c p) cpoly_zero) ->
 (forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
simple induction p; auto.
simple induction q; auto.
Qed.

Lemma cpoly_double_ind0 : forall P : cpoly -> cpoly -> Prop,
 (forall p, P p cpoly_zero) -> (forall p, P cpoly_zero p) ->
 (forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
simple induction p; auto.
simple induction q; auto.
Qed.

Lemma cpoly_double_sym_ind0 : forall P : cpoly -> cpoly -> Prop,
 Tsymmetric P -> (forall p, P p cpoly_zero) ->
 (forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
intros.
apply cpoly_double_ind0; auto.
Qed.

Lemma cpoly_double_ind0' : forall P : cpoly -> cpoly -> Prop,
 (forall p, P cpoly_zero p) -> (forall p c, P (cpoly_linear c p) cpoly_zero) ->
 (forall p q c d, P p q -> P (cpoly_linear c p) (cpoly_linear d q)) -> forall p q, P p q.
simple induction p; auto.
simple induction q; auto.
Qed.

(** *** The polynomials form a setoid
*)
Fixpoint cpoly_eq_zero (p : cpoly) : Prop :=
  match p with
  | cpoly_zero        => True
  | cpoly_linear c p1 => c [=] Zero /\ cpoly_eq_zero p1
  end.

Fixpoint cpoly_eq (p q : cpoly) {struct p} : Prop :=
  match p with
  | cpoly_zero        => cpoly_eq_zero q
  | cpoly_linear c p1 =>
      match q with
      | cpoly_zero        => cpoly_eq_zero p
      | cpoly_linear d q1 => c [=] d /\ cpoly_eq p1 q1
      end
  end.

Lemma cpoly_eq_p_zero : forall p, cpoly_eq p cpoly_zero = cpoly_eq_zero p.
simple induction p; auto.
Qed.

Fixpoint cpoly_ap_zero (p : cpoly) : CProp :=
  match p with
  | cpoly_zero        => CFalse
  | cpoly_linear c p1 => c [#] Zero or cpoly_ap_zero p1
  end.

Fixpoint cpoly_ap (p q : cpoly) {struct p} : CProp :=
  match p with
  | cpoly_zero        => cpoly_ap_zero q
  | cpoly_linear c p1 =>
      match q with
      | cpoly_zero        => cpoly_ap_zero p
      | cpoly_linear d q1 => c [#] d or cpoly_ap p1 q1
      end
  end.

Lemma cpoly_ap_p_zero : forall p, cpoly_ap_zero p = cpoly_ap p cpoly_zero.
simple induction p; auto.
Qed.

Lemma irreflexive_cpoly_ap : irreflexive cpoly_ap.
red in |- *.
intro p; induction  p as [| s p Hrecp].
intro H; elim H.
intro H.
elim H.
 apply ap_irreflexive_unfolded.
assumption.
Qed.

Lemma symmetric_cpoly_ap : Csymmetric cpoly_ap.
red in |- *.
intros x y.
pattern x, y in |- *.
apply Ccpoly_double_ind0'.
  simpl in |- *; simple induction p; auto.
 simpl in |- *; auto.
simpl in |- *.
intros p q c d H H0.
elim H0; intro H1.
 left.
 apply ap_symmetric_unfolded.
 assumption.
auto.
Qed.

Lemma cotransitive_cpoly_ap : cotransitive cpoly_ap.
red in |- *.
intros x y.
pattern x, y in |- *.
apply Ccpoly_double_sym_ind0.
  red in |- *; intros p q H H0 r.
  generalize (symmetric_cpoly_ap _ _ H0); intro H1.
  elim (H H1 r); intro H2; [ right | left ]; apply symmetric_cpoly_ap;
   assumption.
 simpl in |- *; intros p H z.
 generalize H.
 pattern p, z in |- *.
 apply Ccpoly_double_ind0'.
   simpl in |- *; intros q H0; elim H0.
  simpl in |- *; auto.
 simpl in |- *; intros r q c d H0 H1.
 elim H1; intro H2.
  generalize (ap_cotransitive_unfolded _ _ _ H2 d); intro H3.
  elim H3; auto.
 rewrite cpoly_ap_p_zero in H2.
 elim (H0 H2); auto.
 right; right; rewrite cpoly_ap_p_zero; assumption.
intros p q c d H H0 r.
simpl in H0.
elim H0; intro H1.
 induction  r as [| s r Hrecr].
  simpl in |- *.
  generalize (ap_cotransitive_unfolded _ _ _ H1 Zero); intro H2.
  elim H2; auto.
  intro H3.
  right; left; apply ap_symmetric_unfolded; assumption.
 simpl in |- *.
 generalize (ap_cotransitive_unfolded _ _ _ H1 s); intro H2.
 elim H2; auto.
induction  r as [| s r Hrecr].
 simpl in |- *.
 cut (cpoly_ap_zero p or cpoly_ap_zero q).
  intro H2; elim H2; auto.
 generalize H1; pattern p, q in |- *; apply Ccpoly_double_ind0.
   simpl in |- *.
   intros r H2.
   left; rewrite cpoly_ap_p_zero; assumption.
  auto.
 simpl in |- *.
 intros p0 q0 c0 d0 H2 H3.
 elim H3; intro H4.
  elim (ap_cotransitive_unfolded _ _ _ H4 Zero); intro H5.
   auto.
  right; left; apply ap_symmetric_unfolded; assumption.
 elim (H2 H4); auto.
simpl in |- *.
elim (H H1 r); auto.
Qed.

Lemma tight_apart_cpoly_ap : tight_apart cpoly_eq cpoly_ap.
red in |- *.
intros x y.
pattern x, y in |- *.
apply cpoly_double_ind0'.
  simple induction p.
   simpl in |- *.
   unfold iff in |- *.
   unfold Not in |- *.
   split.
    auto.
   intros H H0; inversion H0.
  simpl in |- *.
  intros s c H.
  cut (Not (s [#] Zero) <-> s [=] Zero).
   unfold Not in |- *.
   intro H0.
   elim H0; intros H1 H2.
   split.
    intro H3.
    split; auto.
    elim H; intros H4 H5.
    apply H4.
    intro H6.
    auto.
   intros H3 H4.
   elim H3; intros H5 H6.
   elim H4; intros H7.
    auto.
   elim H; intros H8 H9.
   unfold Not in H8.
   elim H9; assumption.
  apply (ap_tight CR).
 simple induction p.
  simpl in |- *.
  intro c.
  cut (Not (c [#] Zero) <-> c [=] Zero).
   unfold Not in |- *.
   intro H.
   elim H; intros H0 H1.
   split.
    auto.
   intros H2 H3.
   elim H3; intro H4.
    tauto.
   elim H4.
  apply (ap_tight CR).
 simpl in |- *.
 intros s c H d.
 generalize (H d).
 generalize (ap_tight CR d Zero).
 generalize (ap_tight CR s Zero).
 unfold Not in |- *.
 intros H0 H1 H2.
 elim H0; clear H0; intros H3 H4.
 elim H1; clear H1; intros H0 H5.
 elim H2; clear H2; intros H1 H6.
 tauto.
simpl in |- *.
unfold Not in |- *.
intros p q c d H.
elim H; intros H0 H1.
split.
 intro H2.
 split.
  generalize (ap_tight CR c d).
  unfold Not in |- *; tauto.
 tauto.
intros H2 H3.
elim H3.
 elim H2.
 intros H4 H5 H6.
 generalize (ap_tight CR c d).
 unfold Not in |- *.
 tauto.
elim H2.
auto.
Qed.

Lemma cpoly_is_CSetoid : is_CSetoid _ cpoly_eq cpoly_ap.
apply Build_is_CSetoid.
exact irreflexive_cpoly_ap.
exact symmetric_cpoly_ap.
exact cotransitive_cpoly_ap.
exact tight_apart_cpoly_ap.
Qed.

Definition cpoly_csetoid := Build_CSetoid _ _ _ cpoly_is_CSetoid.

(**
Now that we know that the polynomials form a setoid, we can use the
notation with [ [#] ] and [ [=] ]. In order to use this notation,
we introduce [cpoly_zero_cs] and [cpoly_linear_cs], so that Coq
recognizes we are talking about a setoid.
We formulate the induction properties and
the most basic properties of equality and apartness
in terms of these generators.
*)

Let cpoly_zero_cs : cpoly_csetoid := cpoly_zero.

Let cpoly_linear_cs c (p : cpoly_csetoid) : cpoly_csetoid := cpoly_linear c p.

Lemma Ccpoly_ind_cs : forall P : cpoly_csetoid -> CProp,
 P cpoly_zero_cs -> (forall p c, P p -> P (cpoly_linear_cs c p)) -> forall p, P p.
simple induction p; auto.
unfold cpoly_linear_cs in X0.
auto.
Qed.

Lemma Ccpoly_double_ind0_cs : forall P : cpoly_csetoid -> cpoly_csetoid -> CProp,
 (forall p, P p cpoly_zero_cs) -> (forall p, P cpoly_zero_cs p) ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
simple induction p.
auto.
simple induction q.
auto.
simpl in X1.
unfold cpoly_linear_cs in X1.
auto.
Qed.

Lemma Ccpoly_double_sym_ind0_cs : forall P : cpoly_csetoid -> cpoly_csetoid -> CProp,
 Csymmetric P -> (forall p, P p cpoly_zero_cs) ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
intros.
apply Ccpoly_double_ind0; auto.
Qed.

Lemma cpoly_ind_cs : forall P : cpoly_csetoid -> Prop,
 P cpoly_zero_cs -> (forall p c, P p -> P (cpoly_linear_cs c p)) -> forall p, P p.
simple induction p; auto.
unfold cpoly_linear_cs in H0.
auto.
Qed.

Lemma cpoly_double_ind0_cs : forall P : cpoly_csetoid -> cpoly_csetoid -> Prop,
 (forall p, P p cpoly_zero_cs) -> (forall p, P cpoly_zero_cs p) ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
simple induction p.
auto.
simple induction q.
auto.
simpl in H1.
unfold cpoly_linear_cs in H1.
auto.
Qed.

Lemma cpoly_double_sym_ind0_cs : forall P : cpoly_csetoid -> cpoly_csetoid -> Prop,
 Tsymmetric P -> (forall p, P p cpoly_zero_cs) ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
intros.
apply cpoly_double_ind0; auto.
Qed.

Lemma cpoly_lin_eq_zero_ : forall p c,
 cpoly_linear_cs c p [=] cpoly_zero_cs -> c [=] Zero /\ p [=] cpoly_zero_cs.
unfold cpoly_linear_cs in |- *.
unfold cpoly_zero_cs in |- *.
simpl in |- *.
intros p c H.
elim H; intros.
split; auto.
rewrite cpoly_eq_p_zero.
assumption.
Qed.

Lemma _cpoly_lin_eq_zero : forall p c,
 c [=] Zero /\ p [=] cpoly_zero_cs -> cpoly_linear_cs c p [=] cpoly_zero_cs.
unfold cpoly_linear_cs in |- *.
unfold cpoly_zero_cs in |- *.
simpl in |- *.
intros p c H.
elim H; intros.
split; auto.
rewrite <- cpoly_eq_p_zero.
assumption.
Qed.

Lemma cpoly_zero_eq_lin_ : forall p c,
 cpoly_zero_cs [=] cpoly_linear_cs c p -> c [=] Zero /\ cpoly_zero_cs [=] p.
auto.
Qed.

Lemma _cpoly_zero_eq_lin : forall p c,
 c [=] Zero /\ cpoly_zero_cs [=] p -> cpoly_zero_cs [=] cpoly_linear_cs c p.
auto.
Qed.

Lemma cpoly_lin_eq_lin_ : forall p q c d,
 cpoly_linear_cs c p [=] cpoly_linear_cs d q -> c [=] d /\ p [=] q.
auto.
Qed.


Lemma _cpoly_lin_eq_lin : forall p q c d,
 c [=] d /\ p [=] q -> cpoly_linear_cs c p [=] cpoly_linear_cs d q.
auto.
Qed.


Lemma cpoly_lin_ap_zero_ : forall p c,
 cpoly_linear_cs c p [#] cpoly_zero_cs -> c [#] Zero or p [#] cpoly_zero_cs.
unfold cpoly_zero_cs in |- *.
intros p c H.
cut (cpoly_ap (cpoly_linear c p) cpoly_zero); auto.
intro H0.
simpl in H0.
elim H0; auto.
right.
rewrite <- cpoly_ap_p_zero.
assumption.
Qed.

Lemma _cpoly_lin_ap_zero : forall p c,
 c [#] Zero or p [#] cpoly_zero_cs -> cpoly_linear_cs c p [#] cpoly_zero_cs.
unfold cpoly_zero_cs in |- *.
intros.
simpl in |- *.
elim X; try auto.
intros.
right.
rewrite cpoly_ap_p_zero.
assumption.
Qed.

Lemma cpoly_lin_ap_zero : forall p c,
 (cpoly_linear_cs c p [#] cpoly_zero_cs) = (c [#] Zero or p [#] cpoly_zero_cs).
intros.
simpl in |- *.
unfold cpoly_zero_cs in |- *.
rewrite cpoly_ap_p_zero.
reflexivity.
Qed.

Lemma cpoly_zero_ap_lin_ : forall p c,
 cpoly_zero_cs [#] cpoly_linear_cs c p -> c [#] Zero or cpoly_zero_cs [#] p.
intros.
simpl in |- *.
assumption.
Qed.

Lemma _cpoly_zero_ap_lin : forall p c,
 c [#] Zero or cpoly_zero_cs [#] p -> cpoly_zero_cs [#] cpoly_linear_cs c p.
intros.
simpl in |- *.
assumption.
Qed.

Lemma cpoly_zero_ap_lin : forall p c,
 (cpoly_zero_cs [#] cpoly_linear_cs c p) = (c [#] Zero or cpoly_zero_cs [#] p).
intros.
simpl in |- *.
reflexivity.
Qed.

Lemma cpoly_lin_ap_lin_ : forall p q c d,
 cpoly_linear_cs c p [#] cpoly_linear_cs d q -> c [#] d or p [#] q.
auto.
Qed.

Lemma _cpoly_lin_ap_lin : forall p q c d,
 c [#] d or p [#] q -> cpoly_linear_cs c p [#] cpoly_linear_cs d q.
auto.
Qed.

Lemma cpoly_lin_ap_lin : forall p q c d,
 (cpoly_linear_cs c p [#] cpoly_linear_cs d q) = (c [#] d or p [#] q).
intros.
simpl in |- *.
reflexivity.
Qed.

Lemma cpoly_linear_strext : bin_fun_strext _ _ _ cpoly_linear_cs.
unfold bin_fun_strext in |- *.
intros.
apply cpoly_lin_ap_lin_.
assumption.
Qed.

Lemma cpoly_linear_wd : bin_fun_wd _ _ _ cpoly_linear_cs.
apply bin_fun_strext_imp_wd.
exact cpoly_linear_strext.
Qed.

Definition cpoly_linear_fun := Build_CSetoid_bin_fun _ _ _ _ cpoly_linear_strext.

Lemma Ccpoly_double_comp_ind : forall P : cpoly_csetoid -> cpoly_csetoid -> CProp,
 (forall p1 p2 q1 q2, p1 [=] p2 -> q1 [=] q2 -> P p1 q1 -> P p2 q2) ->
 P cpoly_zero_cs cpoly_zero_cs ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
intros.
apply Ccpoly_double_ind0_cs.
intro p0; pattern p0 in |- *; apply Ccpoly_ind_cs.
assumption.
intros p1 c. intros.
apply X with (cpoly_linear_cs c p1) (cpoly_linear_cs Zero cpoly_zero_cs).
Algebra.
apply _cpoly_lin_eq_zero.
split; Algebra.
apply X1.
assumption.

intro p0; pattern p0 in |- *; apply Ccpoly_ind_cs.
assumption.
intros.
apply X with (cpoly_linear_cs Zero cpoly_zero_cs) (cpoly_linear_cs c p1).
apply _cpoly_lin_eq_zero.
split; Algebra.
Algebra.
apply X1.
assumption.
intros.
apply X1.
assumption.
Qed.

Lemma Ccpoly_triple_comp_ind :
 forall P : cpoly_csetoid -> cpoly_csetoid -> cpoly_csetoid -> CProp,
 (forall p1 p2 q1 q2 r1 r2,
  p1 [=] p2 -> q1 [=] q2 -> r1 [=] r2 -> P p1 q1 r1 -> P p2 q2 r2) ->
 P cpoly_zero_cs cpoly_zero_cs cpoly_zero_cs ->
 (forall p q r c d e,
  P p q r -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q) (cpoly_linear_cs e r)) ->
 forall p q r, P p q r.
do 6 intro.
pattern p, q in |- *.
apply Ccpoly_double_comp_ind.
intros.
apply X with p1 q1 r.
assumption.
assumption.
Algebra.
apply X2.

intro r; pattern r in |- *; apply Ccpoly_ind_cs.
assumption.
intros.
apply
 X
  with
    (cpoly_linear_cs Zero cpoly_zero_cs)
    (cpoly_linear_cs Zero cpoly_zero_cs)
    (cpoly_linear_cs c p0).
apply _cpoly_lin_eq_zero; split; Algebra.
apply _cpoly_lin_eq_zero; split; Algebra.
Algebra.
apply X1.
assumption.

do 6 intro.
pattern r in |- *; apply Ccpoly_ind_cs.
apply
 X
  with
    (cpoly_linear_cs c p0)
    (cpoly_linear_cs d q0)
    (cpoly_linear_cs Zero cpoly_zero_cs).
Algebra.
Algebra.
apply _cpoly_lin_eq_zero; split; Algebra.
apply X1.
apply X2.
intros.
apply X1.
apply X2.
Qed.

Lemma cpoly_double_comp_ind : forall P : cpoly_csetoid -> cpoly_csetoid -> Prop,
 (forall p1 p2 q1 q2, p1 [=] p2 -> q1 [=] q2 -> P p1 q1 -> P p2 q2) ->
 P cpoly_zero_cs cpoly_zero_cs ->
 (forall p q c d, P p q -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q)) -> forall p q, P p q.
intros.
apply cpoly_double_ind0_cs.
intro p0; pattern p0 in |- *; apply cpoly_ind_cs.
assumption.
intros.
apply H with (cpoly_linear_cs c p1) (cpoly_linear_cs Zero cpoly_zero_cs).
Algebra.
apply _cpoly_lin_eq_zero.
split; Algebra.
apply H1.
assumption.

intro p0; pattern p0 in |- *; apply cpoly_ind_cs.
assumption.
intros.
apply H with (cpoly_linear_cs Zero cpoly_zero_cs) (cpoly_linear_cs c p1).
apply _cpoly_lin_eq_zero.
split; Algebra.
Algebra.
apply H1.
assumption.
intros.
apply H1.
assumption.
Qed.

Lemma cpoly_triple_comp_ind :
 forall P : cpoly_csetoid -> cpoly_csetoid -> cpoly_csetoid -> Prop,
 (forall p1 p2 q1 q2 r1 r2,
  p1 [=] p2 -> q1 [=] q2 -> r1 [=] r2 -> P p1 q1 r1 -> P p2 q2 r2) ->
 P cpoly_zero_cs cpoly_zero_cs cpoly_zero_cs ->
 (forall p q r c d e,
  P p q r -> P (cpoly_linear_cs c p) (cpoly_linear_cs d q) (cpoly_linear_cs e r)) ->
 forall p q r, P p q r.
do 6 intro.
pattern p, q in |- *.
apply cpoly_double_comp_ind.
intros.
apply H with p1 q1 r.
assumption.
assumption.
Algebra.
apply H4.

intro r; pattern r in |- *; apply cpoly_ind_cs.
assumption.
intros.
apply
 H
  with
    (cpoly_linear_cs Zero cpoly_zero_cs)
    (cpoly_linear_cs Zero cpoly_zero_cs)
    (cpoly_linear_cs c p0).
apply _cpoly_lin_eq_zero; split; Algebra.
apply _cpoly_lin_eq_zero; split; Algebra.
Algebra.
apply H1.
assumption.

do 6 intro.
pattern r in |- *; apply cpoly_ind_cs.
apply
 H
  with
    (cpoly_linear_cs c p0)
    (cpoly_linear_cs d q0)
    (cpoly_linear_cs Zero cpoly_zero_cs).
Algebra.
Algebra.
apply _cpoly_lin_eq_zero; split; Algebra.
apply H1.
apply H2.
intros.
apply H1.
apply H2.
Qed.

(**
*** The polynomials form a semi-group and a monoid
*)

Fixpoint cpoly_plus (p q : cpoly) {struct p} : cpoly :=
  match p with
  | cpoly_zero        => q
  | cpoly_linear c p1 =>
      match q with
      | cpoly_zero        => p
      | cpoly_linear d q1 => cpoly_linear (c[+]d) (cpoly_plus p1 q1)
      end
  end.

Definition cpoly_plus_cs (p q : cpoly_csetoid) : cpoly_csetoid := cpoly_plus p q.

Lemma cpoly_zero_plus : forall p, cpoly_plus_cs cpoly_zero_cs p = p.
auto.
Qed.

Lemma cpoly_plus_zero : forall p, cpoly_plus_cs p cpoly_zero_cs = p.
simple induction p.
auto.
auto.
Qed.

Lemma cpoly_lin_plus_lin : forall p q c d,
 cpoly_plus_cs (cpoly_linear_cs c p) (cpoly_linear_cs d q) =
  cpoly_linear_cs (c[+]d) (cpoly_plus_cs p q).
auto.
Qed.

Lemma cpoly_plus_commutative : forall p q, cpoly_plus_cs p q [=] cpoly_plus_cs q p.
intros.
pattern p, q in |- *.
apply cpoly_double_sym_ind0_cs.
unfold Tsymmetric in |- *.
intros.
Algebra.
intro p0.
rewrite cpoly_zero_plus.
rewrite cpoly_plus_zero.
Algebra.
intros.
repeat rewrite cpoly_lin_plus_lin.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_plus_q_ap_q : forall p q, cpoly_plus_cs p q [#] q -> p [#] cpoly_zero_cs.
intro p; pattern p in |- *; apply Ccpoly_ind_cs.
intro.
rewrite cpoly_zero_plus.
intro H.
elimtype False.
apply (ap_irreflexive _ _ H).
do 4 intro.
pattern q in |- *; apply Ccpoly_ind_cs.
rewrite cpoly_plus_zero.
auto.
do 3 intro.
rewrite cpoly_lin_plus_lin.
intros.
cut (c[+]c0 [#] c0 or cpoly_plus_cs p0 p1 [#] p1).
intros.
2: apply cpoly_lin_ap_lin_.
2: assumption.
cut (c [#] Zero or p0 [#] cpoly_zero_cs).
intro. apply _cpoly_lin_ap_zero. assumption.
elim X1; intro.
left.
apply cg_ap_cancel_rht with c0.
astepr c0. auto.
right.
generalize (X _ b); intro.
assumption.
Qed.

Lemma cpoly_p_plus_ap_p : forall p q, cpoly_plus_cs p q [#] p -> q [#] cpoly_zero.
intros.
apply cpoly_plus_q_ap_q with p.
apply ap_wdl_unfolded with (cpoly_plus_cs p q).
assumption.
apply cpoly_plus_commutative.
Qed.


Lemma cpoly_ap_zero_plus : forall p q,
 cpoly_plus_cs p q [#] cpoly_zero_cs -> p [#] cpoly_zero_cs or q [#] cpoly_zero_cs.
intros p q; pattern p, q in |- *; apply Ccpoly_double_sym_ind0_cs.
unfold Csymmetric in |- *.
intros x y H H0.
elim H.
auto. auto.
astepl (cpoly_plus_cs y x). auto.
apply cpoly_plus_commutative.
intros p0 H.
left.
rewrite cpoly_plus_zero in H.
assumption.
intros p0 q0 c d.
rewrite cpoly_lin_plus_lin.
intros.
cut (c[+]d [#] Zero or cpoly_plus_cs p0 q0 [#] cpoly_zero_cs).
2: apply cpoly_lin_ap_zero_.
2: assumption.
clear X0.
intros H0.
elim H0; intro H1.
cut (c[+]d [#] Zero[+]Zero).
intro H2.
elim (cs_bin_op_strext _ _ _ _ _ _ H2); intro H3.
left.
simpl in |- *.
left.
assumption.
right.
cut (d [#] Zero or q0 [#] cpoly_zero_cs).
intro H4.
apply _cpoly_lin_ap_zero.
auto.
left.
assumption.
astepr (Zero:CR). auto.
elim (X H1); intro.
left.
cut (c [#] Zero or p0 [#] cpoly_zero_cs).
intro; apply _cpoly_lin_ap_zero.
auto.
right.
assumption.
right.
cut (d [#] Zero or q0 [#] cpoly_zero_cs).
intro.
apply _cpoly_lin_ap_zero.
auto.
right.
assumption.
Qed.

Lemma cpoly_plus_op_strext : bin_op_strext cpoly_csetoid cpoly_plus_cs.
unfold bin_op_strext in |- *.
unfold bin_fun_strext in |- *.
intros x1 x2.
pattern x1, x2 in |- *.
apply Ccpoly_double_sym_ind0_cs.
unfold Csymmetric in |- *.
intros.
generalize (ap_symmetric_unfolded _ _ _ X0); intro H1.
generalize (X _ _ H1); intro H2.
elim H2; intro H3; generalize (ap_symmetric_unfolded _ _ _ H3); auto.
intro p; pattern p in |- *; apply Ccpoly_ind_cs.
intro; intro H.
simpl in |- *; auto.
intros s c H y1 y2.
pattern y1, y2 in |- *.
apply Ccpoly_double_ind0_cs.
intros p0 H0.
apply cpoly_ap_zero_plus.
apply H0.
intro p0.
intro H0.
elim (ap_cotransitive _ _ _ H0 cpoly_zero_cs); auto.
do 4 intro.
intros.
cut (c[+]c0 [#] d or cpoly_plus_cs s p0 [#] q).
2: apply cpoly_lin_ap_lin_; assumption.
clear X0; intro H1.
elim H1; intro H2.
cut (c[+]c0 [#] Zero[+]d).
intro H3.
elim (cs_bin_op_strext _ _ _ _ _ _ H3).
intro H4.
left.
apply _cpoly_lin_ap_zero.
auto.
intro.
right.
apply _cpoly_lin_ap_lin.
auto.
astepr d. auto.
elim (H _ _ H2); auto.
intro.
left.
apply _cpoly_lin_ap_zero.
auto.
right.
apply _cpoly_lin_ap_lin.
auto.

do 7 intro.
pattern y1, y2 in |- *.
apply Ccpoly_double_ind0_cs.
intro p0; pattern p0 in |- *; apply Ccpoly_ind_cs.
auto.
intros.
cut (c[+]c0 [#] d or cpoly_plus_cs p p1 [#] q).
intro H2.
2: apply cpoly_lin_ap_lin_.
2: auto.
elim H2; intro H3.
cut (c[+]c0 [#] d[+]Zero).
intro H4.
elim (cs_bin_op_strext _ _ _ _ _ _ H4).
intro.
left.
apply _cpoly_lin_ap_lin.
auto.
intro.
right.
apply _cpoly_lin_ap_zero.
auto.
astepr d. auto.
elim X with p1 cpoly_zero_cs.
intro.
left.
apply _cpoly_lin_ap_lin.
auto.
right.
apply _cpoly_lin_ap_zero.
auto.
rewrite cpoly_plus_zero.
assumption.
intro p0; pattern p0 in |- *; apply Ccpoly_ind_cs.
auto.
intros.
cut (c [#] d[+]c0 or p [#] cpoly_plus_cs q p1).
2: apply cpoly_lin_ap_lin_.
2: assumption.
clear X1; intro H1.
elim H1; intro H2.
cut (c[+]Zero [#] d[+]c0).
intro H3.
elim (cs_bin_op_strext _ _ _ _ _ _ H3).
intro.
left.
unfold cpoly_linear_cs in |- *; simpl in |- *; auto.
intro.
right.
left.
apply ap_symmetric_unfolded.
assumption.
astepl c. auto.
elim X with cpoly_zero_cs p1.
intro.
left.
unfold cpoly_linear_cs in |- *; simpl in |- *; auto.
intro.
right.
right; auto.
rewrite cpoly_plus_zero.
assumption.
intros.
elim X1; intro H2.
elim (cs_bin_op_strext _ _ _ _ _ _ H2); auto.
intro.
left.
left; auto.
intro. right.
left; auto.
simpl in H2.
elim (X _ _ H2).
intro.
left; right; auto.
right; right; auto.
Qed.

Lemma cpoly_plus_op_wd : bin_op_wd cpoly_csetoid cpoly_plus_cs.
unfold bin_op_wd in |- *.
apply bin_fun_strext_imp_wd.
exact cpoly_plus_op_strext.
Qed.

Definition cpoly_plus_op := Build_CSetoid_bin_op _ _ cpoly_plus_op_strext.

Lemma cpoly_plus_associative : associative cpoly_plus_op.
unfold associative in |- *.
intros p q r.
change
  (cpoly_plus_cs p (cpoly_plus_cs q r) [=] cpoly_plus_cs (cpoly_plus_cs p q) r)
 in |- *.
pattern p, q, r in |- *; apply cpoly_triple_comp_ind.
intros.
apply eq_transitive_unfolded with (cpoly_plus_cs p1 (cpoly_plus_cs q1 r1)).
apply eq_symmetric_unfolded.
apply cpoly_plus_op_wd.
assumption.
apply cpoly_plus_op_wd.
assumption.
assumption.
astepl (cpoly_plus_cs (cpoly_plus_cs p1 q1) r1).
apply cpoly_plus_op_wd.
apply cpoly_plus_op_wd.
assumption.
assumption.
assumption.
simpl in |- *.
auto.
intros.
repeat rewrite cpoly_lin_plus_lin.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
Qed.

Definition cpoly_csemi_grp := Build_CSemiGroup _ _ cpoly_plus_associative.

Lemma cpoly_cm_proof : is_CMonoid cpoly_csemi_grp cpoly_zero.
apply Build_is_CMonoid.
unfold is_rht_unit in |- *.
intro.
rewrite cpoly_plus_zero.
Algebra.
unfold is_lft_unit in |- *.
intros.
eapply eq_transitive_unfolded.
apply cpoly_plus_commutative.
rewrite cpoly_plus_zero.
Algebra.
Qed.

Definition cpoly_cmonoid := Build_CMonoid _ _ cpoly_cm_proof.

(** *** The polynomials form a group
*)

Fixpoint cpoly_inv (p : cpoly) : cpoly :=
  match p with
  | cpoly_zero        => cpoly_zero
  | cpoly_linear c p1 => cpoly_linear [--]c (cpoly_inv p1)
  end.

Definition cpoly_inv_cs (p : cpoly_csetoid) : cpoly_csetoid := cpoly_inv p.

Lemma cpoly_inv_zero : cpoly_inv_cs cpoly_zero_cs = cpoly_zero_cs.
auto.
Qed.

Lemma cpoly_inv_lin : forall p c,
 cpoly_inv_cs (cpoly_linear_cs c p) = cpoly_linear_cs [--]c (cpoly_inv_cs p).
simple induction p.
auto.
auto.
Qed.

Lemma cpoly_inv_op_strext : un_op_strext cpoly_csetoid cpoly_inv_cs.
unfold un_op_strext in |- *.
unfold fun_strext in |- *.
intros x y.
pattern x, y in |- *.
apply Ccpoly_double_sym_ind0_cs.
unfold Csymmetric in |- *.
intros.
apply ap_symmetric_unfolded.
apply X.
apply ap_symmetric_unfolded.
assumption.
intro p; pattern p in |- *; apply Ccpoly_ind_cs.
auto.
intros.
cut ( [--]c [#] Zero or cpoly_inv_cs p0 [#] cpoly_zero_cs).
2: apply cpoly_lin_ap_zero_.
2: auto.
clear X0; intro H0.
apply _cpoly_lin_ap_zero.
auto.
elim H0.
left.
astepl ( [--][--]c). Algebra.
right.
apply X.
assumption.
intros.
cut ( [--]c [#] [--]d or cpoly_inv_cs p [#] cpoly_inv_cs q).
2: apply cpoly_lin_ap_lin_.
2: auto.
clear X0; intro H0.
auto.
elim H0; intro.
left.
astepl ( [--][--]c).
astepr ( [--][--]d).
apply inv_resp_ap.
assumption.
right.
apply X.
assumption.
Qed.

Lemma cpoly_inv_op_wd : un_op_wd cpoly_csetoid cpoly_inv_cs.
unfold un_op_wd in |- *.
apply fun_strext_imp_wd.
exact cpoly_inv_op_strext.
Qed.

Definition cpoly_inv_op := Build_CSetoid_un_op _ _ cpoly_inv_op_strext.

Lemma cpoly_cg_proof : is_CGroup cpoly_cmonoid cpoly_inv_op.
unfold is_CGroup in |- *.
intro.
unfold is_inverse in |- *.
assert (x[+]cpoly_inv_cs x [=] Zero).
pattern x in |- *; apply cpoly_ind_cs.
rewrite cpoly_inv_zero.
rewrite cpoly_plus_zero.
simpl in |- *.
auto.
intros.
rewrite cpoly_inv_lin.
rewrite cpoly_lin_plus_lin.
apply _cpoly_lin_eq_zero.
split.
Algebra.
assumption.
split; auto.
eapply eq_transitive_unfolded.
apply cpoly_plus_commutative.
auto.
Qed.

Definition cpoly_cgroup := Build_CGroup _ _ cpoly_cg_proof.

Lemma cpoly_cag_proof : is_CAbGroup cpoly_cgroup.
unfold is_CAbGroup in |- *.
red in |- *; intros.
apply cpoly_plus_commutative.
Qed.

Definition cpoly_cabgroup := Build_CAbGroup _ cpoly_cag_proof.

(** *** The polynomials form a ring
*)

Fixpoint cpoly_mult_cr (q : cpoly) (c : CR) {struct q} : cpoly :=
  match q with
  | cpoly_zero        => cpoly_zero
  | cpoly_linear d q1 => cpoly_linear (c[*]d) (cpoly_mult_cr q1 c)
  end.

Fixpoint cpoly_mult (p q : cpoly) {struct p} : cpoly :=
  match p with
  | cpoly_zero        => cpoly_zero
  | cpoly_linear c p1 =>
      cpoly_plus (cpoly_mult_cr q c) (cpoly_linear Zero (cpoly_mult p1 q))
  end.

Definition cpoly_mult_cr_cs (p : cpoly_csetoid) c : cpoly_csetoid :=
  cpoly_mult_cr p c.

Lemma cpoly_zero_mult_cr : forall c,
 cpoly_mult_cr_cs cpoly_zero_cs c = cpoly_zero_cs.
auto.
Qed.

Lemma cpoly_lin_mult_cr : forall c d q,
 cpoly_mult_cr_cs (cpoly_linear_cs d q) c =
  cpoly_linear_cs (c[*]d) (cpoly_mult_cr_cs q c).
auto.
Qed.

Lemma cpoly_mult_cr_zero : forall p, cpoly_mult_cr_cs p Zero [=] cpoly_zero_cs.
intro; pattern p in |- *; apply cpoly_ind_cs.
rewrite cpoly_zero_mult_cr.
Algebra.
intros.
rewrite cpoly_lin_mult_cr.
apply _cpoly_lin_eq_zero.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_cr_strext : bin_fun_strext _ _ _ cpoly_mult_cr_cs.
unfold bin_fun_strext in |- *.
do 4 intro.
pattern x1, x2 in |- *.
apply Ccpoly_double_ind0_cs.
intro.
rewrite cpoly_zero_mult_cr.
intro H.
left.
generalize H.
pattern p in |- *.
apply Ccpoly_ind_cs.
rewrite cpoly_zero_mult_cr.
auto.
do 2 intro.
rewrite cpoly_lin_mult_cr.
intros.
cut (y1[*]c [#] Zero or cpoly_mult_cr_cs p0 y1 [#] cpoly_zero_cs).
2: apply cpoly_lin_ap_zero_.
2: auto.
clear H0; intro H1.
cut (c [#] Zero or p0 [#] cpoly_zero_cs).
intro; apply _cpoly_lin_ap_zero.
auto.
elim H1; intro H2.
generalize (cring_mult_ap_zero_op _ _ _ H2); intro.
auto.
right.
auto.

rewrite cpoly_zero_mult_cr.
intros.
left.
generalize X.
pattern p in |- *; apply Ccpoly_ind_cs.
rewrite cpoly_zero_mult_cr.
auto.
do 2 intro.
rewrite cpoly_lin_mult_cr.
intros.
cut (y2[*]c [#] Zero or cpoly_zero_cs [#] cpoly_mult_cr_cs p0 y2).
2: apply cpoly_zero_ap_lin_.
2: auto.
clear X1; intro H1.
cut (c [#] Zero or cpoly_zero_cs [#] p0).
intro.
apply _cpoly_zero_ap_lin. auto.
elim H1; intro H2.
generalize (cring_mult_ap_zero_op _ _ _ H2); auto.
right.
auto.

do 4 intro.
repeat rewrite cpoly_lin_mult_cr.
intros.
cut (y1[*]c [#] y2[*]d or cpoly_mult_cr_cs p y1 [#] cpoly_mult_cr_cs q y2).
2: apply cpoly_lin_ap_lin_.
2: auto.
clear X0; intro H0.
cut ((c [#] d or p [#] q) or y1 [#] y2).
intro.
elim X0; try auto.
elim H0; intro H1.
generalize (cs_bin_op_strext _ _ _ _ _ _ H1); tauto.
elim X; auto.
Qed.

Lemma cpoly_mult_cr_wd : bin_fun_wd _ _ _ cpoly_mult_cr_cs.
apply bin_fun_strext_imp_wd.
exact cpoly_mult_cr_strext.
Qed.

Definition cpoly_mult_cs (p q : cpoly_csetoid) : cpoly_csetoid := cpoly_mult p q.

Lemma cpoly_zero_mult : forall q, cpoly_mult_cs cpoly_zero_cs q = cpoly_zero_cs.
auto.
Qed.

Lemma cpoly_lin_mult : forall c p q,
 cpoly_mult_cs (cpoly_linear_cs c p) q =
  cpoly_plus_cs (cpoly_mult_cr_cs q c) (cpoly_linear_cs Zero (cpoly_mult_cs p q)).
auto.
Qed.

Lemma cpoly_mult_op_strext : bin_op_strext cpoly_csetoid cpoly_mult_cs.
do 4 intro.
pattern x1, x2 in |- *.
apply Ccpoly_double_ind0_cs.
rewrite cpoly_zero_mult.
intro; pattern p in |- *; apply Ccpoly_ind_cs.
rewrite cpoly_zero_mult.
auto.
do 2 intro.
rewrite cpoly_lin_mult.
intros.
cut ((c [#] Zero or p0 [#] cpoly_zero_cs) or y1 [#] y2).
intro H1. elim H1.  intro; left; apply _cpoly_lin_ap_zero; assumption.
auto.
cut
 (cpoly_plus_cs (cpoly_mult_cr_cs y1 c)
    (cpoly_linear_cs Zero (cpoly_mult_cs p0 y1)) [#] 
  cpoly_plus_cs (cpoly_mult_cr_cs y2 Zero)
    (cpoly_linear_cs Zero (cpoly_mult_cs cpoly_zero_cs y2))).
intro H1.
elim (cpoly_plus_op_strext _ _ _ _ H1); intro H2.
elim (cpoly_mult_cr_strext _ _ _ _ H2); auto.
elim H2; intro H3.
elim (ap_irreflexive _ _ H3).
rewrite cpoly_zero_mult in H3.
elim X; auto.
rewrite cpoly_zero_mult.
apply ap_wdr_unfolded with cpoly_zero_cs.
assumption.
astepl (cpoly_plus_cs cpoly_zero_cs cpoly_zero_cs).
apply cpoly_plus_op_wd.
apply eq_symmetric_unfolded.
apply cpoly_mult_cr_zero.
apply _cpoly_zero_eq_lin.
split; Algebra.

intro; pattern p in |- *; apply Ccpoly_ind_cs.
auto.
intros.
cut ((c [#] Zero or cpoly_zero_cs [#] p0) or y1 [#] y2).
intro.
elim X1; try auto.
cut
 (cpoly_plus_cs (cpoly_mult_cr_cs y1 Zero)
    (cpoly_linear_cs Zero (cpoly_mult_cs cpoly_zero_cs y1)) [#] 
  cpoly_plus_cs (cpoly_mult_cr_cs y2 c)
    (cpoly_linear_cs Zero (cpoly_mult_cs p0 y2))).
intro H1.
elim (cpoly_plus_op_strext _ _ _ _ H1); intro H2.
elim (cpoly_mult_cr_strext _ _ _ _ H2); auto.
intro.
left. left.
apply ap_symmetric_unfolded.
assumption.
cut
 ((Zero:CR) [#] Zero or cpoly_mult_cs cpoly_zero_cs y1 [#] cpoly_mult_cs p0 y2).
2: apply cpoly_lin_ap_lin_; auto.
clear H2; intro H2.
elim H2; intro H3.
elim (ap_irreflexive _ _ H3).
rewrite cpoly_zero_mult in H3.
elim X; auto.
rewrite cpoly_zero_mult.
apply ap_wdl_unfolded with cpoly_zero_cs.
assumption.
astepl (cpoly_plus_cs cpoly_zero_cs cpoly_zero_cs).
apply cpoly_plus_op_wd.
apply eq_symmetric_unfolded.
apply cpoly_mult_cr_zero.
apply _cpoly_zero_eq_lin.
split; Algebra.

intros.
cut ((c [#] d or p [#] q) or y1 [#] y2).
intro.
auto.
elim (cpoly_plus_op_strext _ _ _ _ X0); intro H1.
elim (cpoly_mult_cr_strext _ _ _ _ H1); auto.
elim H1; intro H2.
elim (ap_irreflexive _ _ H2).
elim X; auto.
Qed.

Lemma cpoly_mult_op_wd : bin_op_wd cpoly_csetoid cpoly_mult.
unfold bin_op_wd in |- *.
apply bin_fun_strext_imp_wd.
exact cpoly_mult_op_strext.
Qed.

Definition cpoly_mult_op := Build_CSetoid_bin_op _ _ cpoly_mult_op_strext.

Lemma cpoly_mult_cr_dist : forall p q c,
 cpoly_mult_cr_cs (cpoly_plus_cs p q) c [=] 
  cpoly_plus_cs (cpoly_mult_cr_cs p c) (cpoly_mult_cr_cs q c).
intros.
pattern p, q in |- *.
apply cpoly_double_comp_ind.
intros.
apply eq_transitive_unfolded with (cpoly_mult_cr_cs (cpoly_plus_cs p1 q1) c).
apply eq_symmetric_unfolded.
apply cpoly_mult_cr_wd.
apply cpoly_plus_op_wd.
assumption.
assumption.
Algebra.
astepl (cpoly_plus_cs (cpoly_mult_cr_cs p1 c) (cpoly_mult_cr_cs q1 c)).
apply cpoly_plus_op_wd.
apply cpoly_mult_cr_wd; Algebra.
apply cpoly_mult_cr_wd; Algebra.
repeat rewrite cpoly_zero_plus.
Algebra.
intros.
repeat rewrite cpoly_lin_mult_cr.
repeat rewrite cpoly_lin_plus_lin.
rewrite cpoly_lin_mult_cr.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_cr_dist : distributive cpoly_mult_op cpoly_plus_op.
unfold distributive in |- *.
intros p q r.
change
  (cpoly_mult_cs p (cpoly_plus_cs q r) [=] 
   cpoly_plus_cs (cpoly_mult_cs p q) (cpoly_mult_cs p r)) 
 in |- *.
pattern p in |- *. apply cpoly_ind_cs.
repeat rewrite cpoly_zero_mult.
rewrite cpoly_zero_plus.
Algebra.
intros.
repeat rewrite cpoly_lin_mult.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs
       (cpoly_plus_cs (cpoly_mult_cr_cs q c) (cpoly_mult_cr_cs r c))
       (cpoly_plus_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))
          (cpoly_linear_cs Zero (cpoly_mult_cs p0 r)))).
apply cpoly_plus_op_wd.
apply cpoly_mult_cr_dist.
rewrite cpoly_lin_plus_lin.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
clear H.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cr_cs q c)
       (cpoly_plus_cs (cpoly_mult_cr_cs r c)
          (cpoly_plus_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))
             (cpoly_linear_cs Zero (cpoly_mult_cs p0 r))))).
apply eq_symmetric_unfolded.
apply cpoly_plus_associative.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cr_cs q c)
       (cpoly_plus_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))
          (cpoly_plus_cs (cpoly_mult_cr_cs r c)
             (cpoly_linear_cs Zero (cpoly_mult_cs p0 r))))).
apply cpoly_plus_op_wd.
Algebra.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs
       (cpoly_plus_cs (cpoly_mult_cr_cs r c)
          (cpoly_linear_cs Zero (cpoly_mult_cs p0 q)))
       (cpoly_linear_cs Zero (cpoly_mult_cs p0 r))).
apply cpoly_plus_associative.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs
       (cpoly_plus_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))
          (cpoly_mult_cr_cs r c)) (cpoly_linear_cs Zero (cpoly_mult_cs p0 r))).
apply cpoly_plus_op_wd.
apply cpoly_plus_commutative.
Algebra.
apply eq_symmetric_unfolded.
apply cpoly_plus_associative.
apply cpoly_plus_associative.
Qed.

Lemma cpoly_mult_cr_assoc_mult_cr : forall p c d,
 cpoly_mult_cr_cs (cpoly_mult_cr_cs p c) d [=] cpoly_mult_cr_cs p (d[*]c).
intros.
pattern p in |- *; apply cpoly_ind_cs.
repeat rewrite cpoly_zero_mult_cr.
Algebra.
intros.
repeat rewrite cpoly_lin_mult_cr.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_cr_assoc_mult : forall p q c,
 cpoly_mult_cr_cs (cpoly_mult_cs p q) c [=] cpoly_mult_cs (cpoly_mult_cr_cs p c) q.
intros.
pattern p in |- *; apply cpoly_ind_cs.
rewrite cpoly_zero_mult.
repeat rewrite cpoly_zero_mult_cr.
rewrite cpoly_zero_mult.
Algebra.
intros.
rewrite cpoly_lin_mult.
repeat rewrite cpoly_lin_mult_cr.
rewrite cpoly_lin_mult.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cr_cs (cpoly_mult_cr_cs q c0) c)
       (cpoly_mult_cr_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q)) c)).
apply cpoly_mult_cr_dist.
apply cpoly_plus_op_wd.
apply cpoly_mult_cr_assoc_mult_cr.
rewrite cpoly_lin_mult_cr.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_zero : forall p, cpoly_mult_cs p cpoly_zero_cs [=] cpoly_zero_cs.
intros.
pattern p in |- *; apply cpoly_ind_cs.
Algebra.
intros.
rewrite cpoly_lin_mult.
rewrite cpoly_zero_mult_cr.
rewrite cpoly_zero_plus.
apply _cpoly_lin_eq_zero.
split.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_lin : forall c p q,
 cpoly_mult_cs p (cpoly_linear_cs c q) [=] 
  cpoly_plus_cs (cpoly_mult_cr_cs p c) (cpoly_linear_cs Zero (cpoly_mult_cs p q)).
intros.
pattern p in |- *; apply cpoly_ind_cs.
repeat rewrite cpoly_zero_mult.
rewrite cpoly_zero_mult_cr.
rewrite cpoly_zero_plus.
apply _cpoly_zero_eq_lin.
Algebra.
intros.
repeat rewrite cpoly_lin_mult.
repeat rewrite cpoly_lin_mult_cr.
repeat rewrite cpoly_lin_plus_lin.
apply _cpoly_lin_eq_lin. split.
Algebra.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs
       (cpoly_plus_cs (cpoly_mult_cr_cs p0 c) (cpoly_mult_cr_cs q c0))
       (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))).
2: apply eq_symmetric_unfolded.
2: apply cpoly_plus_associative.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs
       (cpoly_plus_cs (cpoly_mult_cr_cs q c0) (cpoly_mult_cr_cs p0 c))
       (cpoly_linear_cs Zero (cpoly_mult_cs p0 q))).
2: apply cpoly_plus_op_wd.
3: Algebra.
2: apply cpoly_plus_commutative.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cr_cs q c0)
       (cpoly_plus_cs (cpoly_mult_cr_cs p0 c)
          (cpoly_linear_cs Zero (cpoly_mult_cs p0 q)))).
2: apply cpoly_plus_associative.
apply cpoly_plus_op_wd.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_commutative :
 forall p q : cpoly_csetoid, cpoly_mult_cs p q [=] cpoly_mult_cs q p.
intros.
pattern p in |- *.
apply cpoly_ind_cs.
rewrite cpoly_zero_mult.
apply eq_symmetric_unfolded.
apply cpoly_mult_zero.
intros.
rewrite cpoly_lin_mult.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cr_cs q c)
       (cpoly_linear_cs Zero (cpoly_mult_cs q p0))).
2: apply eq_symmetric_unfolded; apply cpoly_mult_lin.
apply cpoly_plus_op_wd.
Algebra.
apply cpoly_linear_wd.
Algebra.
assumption.
Qed.

Lemma cpoly_mult_dist_rht : forall p q r,
 cpoly_mult_cs (cpoly_plus_cs p q) r [=]
  cpoly_plus_cs (cpoly_mult_cs p r) (cpoly_mult_cs q r).
intros.
apply eq_transitive_unfolded with (cpoly_mult_cs r (cpoly_plus_cs p q)).
apply cpoly_mult_commutative.
apply
 eq_transitive_unfolded
  with (cpoly_plus_cs (cpoly_mult_cs r p) (cpoly_mult_cs r q)).
generalize cpoly_cr_dist; intro.
unfold distributive in H.
simpl in H.
simpl in |- *.
apply H.
apply cpoly_plus_op_wd.
apply cpoly_mult_commutative.
apply cpoly_mult_commutative.
Qed.

Lemma cpoly_mult_assoc : associative cpoly_mult_op.
unfold associative in |- *.
intros p q r.
change
  (cpoly_mult_cs p (cpoly_mult_cs q r) [=] cpoly_mult_cs (cpoly_mult_cs p q) r)
 in |- *.
pattern p in |- *; apply cpoly_ind_cs.
repeat rewrite cpoly_zero_mult.
Algebra.
intros.
repeat rewrite cpoly_lin_mult.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs (cpoly_mult_cs (cpoly_mult_cr_cs q c) r)
       (cpoly_mult_cs (cpoly_linear_cs Zero (cpoly_mult_cs p0 q)) r)).
apply cpoly_plus_op_wd.
apply cpoly_mult_cr_assoc_mult.
rewrite cpoly_lin_mult.
apply
 eq_transitive_unfolded
  with
    (cpoly_plus_cs cpoly_zero_cs
       (cpoly_linear_cs Zero (cpoly_mult_cs (cpoly_mult_cs p0 q) r))).
rewrite cpoly_zero_plus.
apply _cpoly_lin_eq_lin.
split.
Algebra.
assumption.
apply cpoly_plus_op_wd.
apply eq_symmetric_unfolded.
apply cpoly_mult_cr_zero.
apply _cpoly_lin_eq_lin.
split.
Algebra.
Algebra.
apply eq_symmetric_unfolded.
apply cpoly_mult_dist_rht.
Qed.

Lemma cpoly_mult_cr_one : forall p, cpoly_mult_cr_cs p One [=] p.
intro.
pattern p in |- *; apply cpoly_ind_cs.
Algebra.
intros.
rewrite cpoly_lin_mult_cr.
apply _cpoly_lin_eq_lin.
Algebra.
Qed.

Lemma cpoly_one_mult : forall p, cpoly_mult_cs cpoly_one p [=] p.
intro.
unfold cpoly_one in |- *.
unfold cpoly_constant in |- *.
replace (cpoly_linear One cpoly_zero) with (cpoly_linear_cs One cpoly_zero).
2: reflexivity.
rewrite cpoly_lin_mult.
rewrite cpoly_zero_mult.
apply eq_transitive_unfolded with (cpoly_plus_cs p cpoly_zero_cs).
apply cpoly_plus_op_wd.
apply cpoly_mult_cr_one.
apply _cpoly_lin_eq_zero; Algebra.
rewrite cpoly_plus_zero; Algebra.
Qed.

Lemma cpoly_mult_one : forall p, cpoly_mult_cs p cpoly_one [=] p.
intro.
apply eq_transitive_unfolded with (cpoly_mult_cs cpoly_one p).
apply cpoly_mult_commutative.
apply cpoly_one_mult.
Qed.

Lemma cpoly_mult_monoid : 
 is_CMonoid (Build_CSemiGroup _ _ cpoly_mult_assoc) cpoly_one.
apply Build_is_CMonoid.
exact cpoly_mult_one.
exact cpoly_one_mult.
Qed.

Lemma cpoly_cr_non_triv : cpoly_ap cpoly_one cpoly_zero.
change (cpoly_linear_cs One cpoly_zero_cs [#] cpoly_zero_cs) in |- *.
cut ((One:CR) [#] Zero or cpoly_zero_cs [#] cpoly_zero_cs).
auto.
left.
Algebra.
Qed.

Lemma cpoly_is_CRing : is_CRing cpoly_cabgroup cpoly_one cpoly_mult_op.
apply Build_is_CRing with cpoly_mult_assoc.
exact cpoly_mult_monoid.
exact cpoly_mult_commutative.
exact cpoly_cr_dist.
exact cpoly_cr_non_triv.
Qed.

Definition cpoly_cring : CRing := Build_CRing _ _ _ cpoly_is_CRing.

Lemma cpoly_constant_strext :
 fun_strext (S1:=CR) (S2:=cpoly_cring) cpoly_constant.
unfold fun_strext in |- *.
unfold cpoly_constant in |- *.
simpl in |- *.
intros x y H.
elim H.
auto.
intro.
elim b.
Qed.

Lemma cpoly_constant_wd : fun_wd (S1:=CR) (S2:=cpoly_cring) cpoly_constant.
apply fun_strext_imp_wd.
exact cpoly_constant_strext.
Qed.

Definition _C_ := Build_CSetoid_fun _ _ _ cpoly_constant_strext.

Definition _X_ : cpoly_cring := cpoly_linear_cs Zero (One:cpoly_cring).

Definition cpoly_x_minus_c c : cpoly_cring :=
 cpoly_linear_cs [--]c (One:cpoly_cring).

Lemma cpoly_x_minus_c_strext :
 fun_strext (S1:=CR) (S2:=cpoly_cring) cpoly_x_minus_c.
unfold fun_strext in |- *.
unfold cpoly_x_minus_c in |- *.
simpl in |- *.
intros x y H.
elim H; intro H0.
apply (cs_un_op_strext _ _ _ _ H0).
elim H0; intro H1.
elim (ap_irreflexive_unfolded _ _ H1).
elim H1.
Qed.

Lemma cpoly_x_minus_c_wd : fun_wd (S1:=CR) (S2:=cpoly_cring) cpoly_x_minus_c.
apply fun_strext_imp_wd.
exact cpoly_x_minus_c_strext.
Qed.

End CPoly_CRing.

Implicit Arguments _C_ [CR].
Implicit Arguments _X_ [CR].

Definition cpoly_linear_fun' (CR : CRing) :
 CSetoid_bin_fun CR (cpoly_cring CR) (cpoly_cring CR) := cpoly_linear_fun CR.

Implicit Arguments cpoly_linear_fun' [CR].
Infix "[+X*]" := cpoly_linear_fun' (at level 50, left associativity).


(** ** Apartness, equality, and induction
%\label{section:poly-equality}%
*)

Section CPoly_CRing_ctd.

(**
%\begin{convention}%
Let [CR] be a ring, [p] and [q] polynomials over that ring, and [c] and [d]
elements of the ring.
%\end{convention}%
*)
Variable CR : CRing.

Notation RX := (cpoly_cring CR).

Section helpful_section.

Variables p q : RX.
Variables c d : CR.

Lemma linear_eq_zero_ : c[+X*]p [=] Zero -> c [=] Zero /\ p [=] Zero.
Proof cpoly_lin_eq_zero_ CR p c.

Lemma _linear_eq_zero : c [=] Zero /\ p [=] Zero -> c[+X*]p [=] Zero.
Proof _cpoly_lin_eq_zero CR p c.

Lemma zero_eq_linear_ : Zero [=] c[+X*]p -> c [=] Zero /\ Zero [=] p.
Proof cpoly_zero_eq_lin_ CR p c.

Lemma _zero_eq_linear : c [=] Zero /\ Zero [=] p -> Zero [=] c[+X*]p.
Proof _cpoly_zero_eq_lin CR p c.

Lemma linear_eq_linear_ : c[+X*]p [=] d[+X*]q -> c [=] d /\ p [=] q.
Proof cpoly_lin_eq_lin_ CR p q c d.

Lemma _linear_eq_linear : c [=] d /\ p [=] q -> c[+X*]p [=] d[+X*]q.
Proof _cpoly_lin_eq_lin CR p q c d.

Lemma linear_ap_zero_ : c[+X*]p [#] Zero -> c [#] Zero or p [#] Zero.
Proof cpoly_lin_ap_zero_ CR p c.

Lemma _linear_ap_zero : c [#] Zero or p [#] Zero -> c[+X*]p [#] Zero.
Proof _cpoly_lin_ap_zero CR p c.

Lemma linear_ap_zero : (c[+X*]p [#] Zero) = (c [#] Zero or p [#] Zero).
Proof cpoly_lin_ap_zero CR p c.

Lemma zero_ap_linear_ : Zero [#] c[+X*]p -> c [#] Zero or Zero [#] p.
Proof cpoly_zero_ap_lin_ CR p c.

Lemma _zero_ap_linear : c [#] Zero or Zero [#] p -> Zero [#] c[+X*]p.
Proof _cpoly_zero_ap_lin CR p c.

Lemma zero_ap_linear : (Zero [#] c[+X*]p) = (c [#] Zero or Zero [#] p).
Proof cpoly_zero_ap_lin CR p c.

Lemma linear_ap_linear_ : c[+X*]p [#] d[+X*]q -> c [#] d or p [#] q.
Proof cpoly_lin_ap_lin_ CR p q c d.

Lemma _linear_ap_linear : c [#] d or p [#] q -> c[+X*]p [#] d[+X*]q.
Proof _cpoly_lin_ap_lin CR p q c d.

Lemma linear_ap_linear : (c[+X*]p [#] d[+X*]q) = (c [#] d or p [#] q).
Proof cpoly_lin_ap_lin CR p q c d.

End helpful_section.

Lemma Ccpoly_induc : forall P : RX -> CProp, P Zero ->
 (forall p c, P p -> P (c[+X*]p)) -> forall p, P p.
exact (Ccpoly_ind_cs CR).
Qed.

Lemma Ccpoly_double_sym_ind : forall P : RX -> RX -> CProp,
 Csymmetric P -> (forall p, P p Zero) ->
 (forall p q c d, P p q -> P (c[+X*]p) (d[+X*]q)) -> forall p q, P p q.
exact (Ccpoly_double_sym_ind0_cs CR).
Qed.

Lemma Cpoly_double_comp_ind : forall P : RX -> RX -> CProp,
 (forall p1 p2 q1 q2, p1 [=] p2 -> q1 [=] q2 -> P p1 q1 -> P p2 q2) -> P Zero Zero ->
 (forall p q c d, P p q -> P (c[+X*]p) (d[+X*]q)) -> forall p q, P p q.
exact (Ccpoly_double_comp_ind CR).
Qed.

Lemma Cpoly_triple_comp_ind : forall P : RX -> RX -> RX -> CProp,
 (forall p1 p2 q1 q2 r1 r2,
  p1 [=] p2 -> q1 [=] q2 -> r1 [=] r2 -> P p1 q1 r1 -> P p2 q2 r2) ->
 P Zero Zero Zero -> (forall p q r c d e, P p q r -> P (c[+X*]p) (d[+X*]q) (e[+X*]r)) ->
 forall p q r, P p q r.
exact (Ccpoly_triple_comp_ind CR).
Qed.

Lemma cpoly_induc : forall P : RX -> Prop,
 P Zero -> (forall p c, P p -> P (c[+X*]p)) -> forall p, P p.
exact (cpoly_ind_cs CR).
Qed.

Lemma cpoly_double_sym_ind : forall P : RX -> RX -> Prop,
 Tsymmetric P -> (forall p, P p Zero) ->
 (forall p q c d, P p q -> P (c[+X*]p) (d[+X*]q)) -> forall p q, P p q.
exact (cpoly_double_sym_ind0_cs CR).
Qed.

Lemma poly_double_comp_ind : forall P : RX -> RX -> Prop,
 (forall p1 p2 q1 q2, p1 [=] p2 -> q1 [=] q2 -> P p1 q1 -> P p2 q2) -> P Zero Zero ->
 (forall p q c d, P p q -> P (c[+X*]p) (d[+X*]q)) -> forall p q, P p q.
exact (cpoly_double_comp_ind CR).
Qed.

Lemma poly_triple_comp_ind : forall P : RX -> RX -> RX -> Prop,
 (forall p1 p2 q1 q2 r1 r2,
  p1 [=] p2 -> q1 [=] q2 -> r1 [=] r2 -> P p1 q1 r1 -> P p2 q2 r2) ->
 P Zero Zero Zero ->
 (forall p q r c d e, P p q r -> P (c[+X*]p) (d[+X*]q) (e[+X*]r)) -> forall p q r, P p q r.
exact (cpoly_triple_comp_ind CR).
Qed.

Transparent cpoly_cring.
Transparent cpoly_cgroup.
Transparent cpoly_csetoid.

Fixpoint cpoly_apply (p : RX) (x : CR) {struct p} : CR :=
  match p with
  | cpoly_zero        => Zero
  | cpoly_linear c p1 => c[+]x[*]cpoly_apply p1 x
  end.

Lemma cpoly_apply_strext : bin_fun_strext _ _ _ cpoly_apply.
unfold bin_fun_strext in |- *.
do 2 intro.
pattern x1, x2 in |- *.
apply Ccpoly_double_sym_ind.
unfold Csymmetric in |- *.
intros.
generalize (ap_symmetric _ _ _ X0); intro.
elim (X _ _ X1); intro.
left.
apply ap_symmetric_unfolded.
assumption.
right.
apply ap_symmetric_unfolded.
assumption.
do 3 intro.
pattern p in |- *.
apply Ccpoly_induc.
simpl in |- *.
intro H.
elim (ap_irreflexive _ _ H).
intros.
simpl in X0.
simpl in X.
cut (c[+]y1[*]cpoly_apply p0 y1 [#] Zero[+]y1[*]Zero).
intro.
elim (cs_bin_op_strext _ _ _ _ _ _ X1); intro H2.
left.
cut (c [#] Zero or p0 [#] Zero).
intro.
apply _linear_ap_zero.
auto.
left.
assumption.
elim (cs_bin_op_strext _ _ _ _ _ _ H2); intro H3.
elim (ap_irreflexive _ _ H3).
elim (X H3); intro H4.
left.
cut (c [#] Zero or p0 [#] Zero).
intro; apply _linear_ap_zero.
auto.
right.
exact H4.
auto.
astepr (Zero[+](Zero:CR)).
astepr (Zero:CR). auto.
simpl in |- *.
intros.
elim (cs_bin_op_strext _ _ _ _ _ _ X0); intro H1.
auto.
elim (cs_bin_op_strext _ _ _ _ _ _ H1); intro H2.
auto.
elim (X _ _ H2); auto.
Qed.

Lemma cpoly_apply_wd : bin_fun_wd _ _ _ cpoly_apply.
apply bin_fun_strext_imp_wd.
exact cpoly_apply_strext.
Qed.

Definition cpoly_apply_fun := Build_CSetoid_bin_fun _ _ _ _ cpoly_apply_strext.

End CPoly_CRing_ctd.

(**
%\begin{convention}%
[cpoly_apply_fun] is denoted infix by [!]
The first argument is left implicit, so the application of
polynomial [f] (seen as a function) to argument [x] can be written as [f!x].
In the names of lemmas, we write [apply].
%\end{convention}%
*)

Implicit Arguments cpoly_apply_fun [CR].
Infix "!" := cpoly_apply_fun (at level 1, no associativity).

(**
** Basic properties of polynomials
%\begin{convention}%
Let [R] be a ring and write [RX] for the ring of polynomials over [R].
%\end{convention}%
*)

Section Poly_properties.
Variable R : CRing.

Notation RX := (cpoly_cring R).

(**
*** Constant and identity
*)

Lemma cpoly_X_ : _X_ [=] (Zero:RX) [+X*]One.
Algebra.
Qed.

Lemma cpoly_C_ : forall c : RX, _C_ c [=] c[+X*]Zero.
Algebra.
Qed.

Hint Resolve cpoly_X_ cpoly_C_: algebra.

Lemma cpoly_const_eq : forall c d : R, c [=] d -> _C_ c [=] _C_ d.
intros.
Algebra.
Qed.

Lemma _c_zero : Zero [=] _C_ (Zero:R).
simpl in |- *.
split; Algebra.
Qed.

Lemma _c_one : One [=] _C_ (One:R).
simpl in |- *; split; Algebra.
Qed.

Lemma _c_mult : forall a b : R, _C_ (a[*]b) [=] _C_ a[*]_C_ b.
simpl in |- *; split; Algebra.
Qed.

Lemma cpoly_lin : forall (p : RX) (c : R), c[+X*]p [=] _C_ c[+]_X_[*]p.
intros.
astepr
 (c[+X*]Zero[+]
  ((cpoly_mult_cr_cs _ p Zero:RX) [+]
   (cpoly_linear _ (Zero:R)
      (cpoly_mult_cs _ (cpoly_one R) (p:cpoly_csetoid R))
    :cpoly_csetoid R))).
cut (cpoly_mult_cr_cs R p Zero [=] (Zero:RX)).
intro.
astepr
 (c[+X*]Zero[+]
  ((Zero:RX) [+]
   (cpoly_linear _ (Zero:R)
      (cpoly_mult_cs _ (cpoly_one R) (p:cpoly_csetoid R))
    :cpoly_csetoid R))).
2: apply (cpoly_mult_cr_zero R p).
cut ((cpoly_mult_cs _ (cpoly_one R) (p:cpoly_csetoid R):cpoly_csetoid R) [=] p).
intro.
apply
 eq_transitive_unfolded
  with
    (c[+X*]Zero[+]((Zero:RX) [+]cpoly_linear _ (Zero:R) (p:cpoly_csetoid R))).
2: apply bin_op_wd_unfolded.
2: Algebra.
2: apply bin_op_wd_unfolded.
2: Algebra.
2: apply (cpoly_linear_wd R).
2: Algebra.
2: apply eq_symmetric_unfolded.
2: apply cpoly_one_mult.
astepr (c[+X*]Zero[+]cpoly_linear _ (Zero:R) (p:cpoly_csetoid R)).
astepr (c[+]Zero[+X*](Zero[+]p)).
astepr (c[+X*]p).
Algebra.
apply cpoly_one_mult.
Qed.

Hint Resolve cpoly_lin: algebra.

(* SUPERFLUOUS *)
Lemma poly_linear : forall c f, (cpoly_linear _ c f:RX) [=] _X_[*]f[+]_C_ c.
intros.
astepr (_C_ c[+]_X_[*]f).
exact (cpoly_lin f c).
Qed.

Lemma poly_c_apzero : forall a : R, _C_ a [#] Zero -> a [#] Zero.
intros.
cut (_C_ a [#] _C_ Zero).
intro H0.
generalize (csf_strext _ _ _ _ _ H0); auto.
Hint Resolve _c_zero: algebra.
astepr (Zero:RX). auto.
Qed.

Lemma _c_mult_lin : forall (p : RX) c d, _C_ c[*] (d[+X*]p) [=] c[*]d[+X*]_C_ c[*]p.
intros.
pattern p in |- *.
apply cpoly_induc.
simpl in |- *.
repeat split; Algebra.
intros. simpl in |- *.
repeat split; Algebra.
change ((cpoly_mult_cr R p0 c:RX) [=] (cpoly_mult_cr R p0 c:RX)[+]Zero) in |- *.
Algebra.
Qed.


(* SUPERFLUOUS ? *)
Lemma lin_mult : forall (p q : RX) c, (c[+X*]p) [*]q [=] _C_ c[*]q[+]_X_[*] (p[*]q).
intros.
astepl ((_C_ c[+]_X_[*]p)[*]q).
astepl (_C_ c[*]q[+]_X_[*]p[*]q).
Algebra.
Qed.

Hint Resolve lin_mult: algebra.

(** *** Application of polynomials
*)

Lemma poly_eq_zero : forall p : RX, p [=] cpoly_zero R -> forall x, p ! x [=] Zero.
intros.
astepl (cpoly_zero R) ! x.
change (Zero ! x [=] Zero) in |- *.
Algebra.
Qed.

Lemma apply_wd : forall (p p' : RX) x x', p [=] p' -> x [=] x' -> p ! x [=] p' ! x'.
intros.
Algebra.
Qed.

Lemma cpolyap_pres_eq : forall (f : RX) x y, x [=] y -> f ! x [=] f ! y.
intros.
Algebra.
Qed.

Lemma cpolyap_strext : forall (f : RX) x y, f ! x [#] f ! y -> x [#] y.
intros f x y H.
elim (csbf_strext _ _ _ _ _ _ _ _ H); intro H0.
elim (ap_irreflexive_unfolded _ _ H0).
assumption.
Qed.

Definition cpoly_csetoid_op (f : RX) : CSetoid_un_op R :=
 Build_CSetoid_fun _ _ (fun x => f ! x) (cpolyap_strext f).

Lemma _c_apply : forall c x : R, (_C_ c) ! x [=] c.
intros.
simpl in |- *.
astepl (c[+]Zero).
Algebra.
Qed.

Lemma _x_apply : forall x : R, _X_ ! x [=] x.
intros.
simpl in |- *.
astepl (x[*](One[+]x[*]Zero)).
astepl (x[*](One[+]Zero)).
astepl (x[*]One).
Algebra.
Qed.

Lemma plus_apply : forall (p q : RX) x, (p[+]q) ! x [=] p ! x[+]q ! x.
intros.
pattern p, q in |- *; apply poly_double_comp_ind.
intros.
astepl (p1[+]q1) ! x.
astepr (p1 ! x[+]q1 ! x).
Algebra.
simpl in |- *.
Algebra.
intros.
astepl (c[+]d[+]x[*](p0[+]q0) ! x).
astepr (c[+]x[*]p0 ! x[+](d[+]x[*]q0 ! x)).
astepl (c[+]d[+]x[*](p0 ! x[+]q0 ! x)).
astepl (c[+]d[+](x[*]p0 ! x[+]x[*]q0 ! x)).
astepl (c[+](d[+](x[*]p0 ! x[+]x[*]q0 ! x))).
astepr (c[+](x[*]p0 ! x[+](d[+]x[*]q0 ! x))).
astepl (c[+](d[+]x[*]p0 ! x[+]x[*]q0 ! x)).
astepr (c[+](x[*]p0 ! x[+]d[+]x[*]q0 ! x)).
Algebra.
Qed.

Lemma inv_apply : forall (p : RX) x, ( [--]p) ! x [=] [--]p ! x.
intros.
pattern p in |- *.
apply cpoly_induc.
simpl in |- *.
Algebra.
intros.
astepl ( [--]c[+]x[*]( [--]p0) ! x).
astepr ( [--](c[+]x[*]p0 ! x)).
astepr ( [--]c[+][--](x[*]p0 ! x)).
astepr ( [--]c[+]x[*][--]p0 ! x).
Algebra.
Qed.

Hint Resolve plus_apply inv_apply: algebra.

Lemma minus_apply : forall (p q : RX) x, (p[-]q) ! x [=] p ! x[-]q ! x.
intros.
astepl (p[+][--]q) ! x.
astepr (p ! x[+][--]q ! x).
astepl (p ! x[+]( [--]q) ! x).
Algebra.
Qed.

Lemma _c_mult_apply : forall (q : RX) c x, (_C_ c[*]q) ! x [=] c[*]q ! x.
intros.
astepl ((cpoly_mult_cr R q c:RX)[+](Zero[+X*]Zero)) ! x.
astepl ((cpoly_mult_cr R q c) ! x[+](Zero[+X*]Zero) ! x).
astepl ((cpoly_mult_cr R q c) ! x[+](Zero[+]x[*]Zero)).
astepl ((cpoly_mult_cr R q c) ! x[+](Zero[+]Zero)).
astepl ((cpoly_mult_cr R q c) ! x[+]Zero).
astepl (cpoly_mult_cr R q c) ! x.
pattern q in |- *.
apply cpoly_induc.
simpl in |- *.
Algebra.
intros.
astepl (c[*]c0[+X*]cpoly_mult_cr R p c) ! x.
astepl (c[*]c0[+]x[*](cpoly_mult_cr R p c) ! x).
astepl (c[*]c0[+]x[*](c[*]p ! x)).
astepr (c[*](c0[+]x[*]p ! x)).
astepr (c[*]c0[+]c[*](x[*]p ! x)).
apply bin_op_wd_unfolded.
Algebra.
astepl (x[*]c[*]p ! x).
astepr (c[*]x[*]p ! x).
Algebra.
Qed.

Hint Resolve _c_mult_apply: algebra.

Lemma mult_apply : forall (p q : RX) x, (p[*]q) ! x [=] p ! x[*]q ! x.
intros.
pattern p in |- *.
apply cpoly_induc.
simpl in |- *.
Algebra.
intros.
astepl (_C_ c[*]q[+]_X_[*](p0[*]q)) ! x.
astepl ((_C_ c[*]q) ! x[+](_X_[*](p0[*]q)) ! x).
astepl ((_C_ c[*]q) ! x[+](Zero[+]_X_[*](p0[*]q)) ! x).
astepl ((_C_ c[*]q) ! x[+](_C_ Zero[+]_X_[*](p0[*]q)) ! x).
astepl ((_C_ c[*]q) ! x[+](Zero[+X*]p0[*]q) ! x).
astepl ((_C_ c[*]q) ! x[+](Zero[+]x[*](p0[*]q) ! x)).
astepl (c[*]q ! x[+]x[*](p0[*]q) ! x).
astepl (c[*]q ! x[+]x[*](p0 ! x[*]q ! x)).
astepr ((c[+]x[*]p0 ! x)[*]q ! x).
astepr (c[*]q ! x[+]x[*]p0 ! x[*]q ! x).
Algebra.
Qed.

Hint Resolve mult_apply: algebra.

Lemma one_apply : forall x : R, One ! x [=] One.
intro.
astepl (_C_ One) ! x.
apply _c_apply.
Qed.

Hint Resolve one_apply: algebra.

Lemma nexp_apply : forall (p : RX) n x, (p[^]n) ! x [=] p ! x[^]n.
intros.
induction  n as [| n Hrecn].
astepl (One:RX) ! x.
astepl (One:R).
Algebra.
astepl (p[*]p[^]n) ! x.
astepl (p ! x[*](p[^]n) ! x).
astepl (p ! x[*]p ! x[^]n).
Algebra.
Qed.

(* SUPERFLUOUS *)
Lemma poly_inv_apply : forall (p : RX) x, (cpoly_inv _ p) ! x [=] [--]p ! x.
exact inv_apply.
Qed.

Lemma Sum0_cpoly_ap : forall (f : nat -> RX) a k, (Sum0 k f) ! a [=] Sum0 k (fun i => (f i) ! a).
intros.
induction  k as [| k Hreck].
simpl in |- *.
Algebra.
astepl (Sum0 k f[+]f k) ! a.
astepl ((Sum0 k f) ! a[+](f k) ! a).
astepl (Sum0 k (fun i : nat => (f i) ! a)[+](f k) ! a).
simpl in |- *.
Algebra.
Qed.

Lemma Sum_cpoly_ap : forall (f : nat -> RX) a k l,
 (Sum k l f) ! a [=] Sum k l (fun i => (f i) ! a).
unfold Sum in |- *.
unfold Sum1 in |- *.
intros.
unfold cg_minus in |- *.
astepl ((Sum0 (S l) f) ! a[+]( [--](Sum0 k f)) ! a).
astepl ((Sum0 (S l) f) ! a[+][--](Sum0 k f) ! a).
apply bin_op_wd_unfolded.
apply Sum0_cpoly_ap.
apply un_op_wd_unfolded.
apply Sum0_cpoly_ap.
Qed.

End Poly_properties.

(** ** Induction properties of polynomials for [Prop]
*)
Section Poly_Prop_Induction.

Variable CR : CRing.

Notation Cpoly := (cpoly CR).

Notation Cpoly_zero := (cpoly_zero CR).

Notation Cpoly_linear := (cpoly_linear CR).

Notation Cpoly_cring := (cpoly_cring CR).

Lemma cpoly_double_ind : forall P : Cpoly_cring -> Cpoly_cring -> Prop,
 (forall p, P p Zero) -> (forall p, P Zero p) ->
 (forall p q c d, P p q -> P (c[+X*]p) (d[+X*]q)) -> forall p q, P p q.
exact (cpoly_double_ind0_cs CR).
Qed.

End Poly_Prop_Induction.

Hint Resolve poly_linear cpoly_lin: algebra.
Hint Resolve apply_wd cpoly_const_eq: algebra_c.
Hint Resolve _c_apply _x_apply inv_apply plus_apply minus_apply mult_apply
  nexp_apply: algebra.
Hint Resolve one_apply _c_zero _c_one _c_mult: algebra.
Hint Resolve poly_inv_apply: algebra.
Hint Resolve _c_mult_lin: algebra.