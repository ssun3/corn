(* $Id$ *)

(* begin hide *)
Require Export CAbGroups.
Require Export AlgReflection.

Section Group_Interpretation_Function.

Variable G : CAbGroup.
Variable val : varindex -> G.
Variable unop : unopindex -> CSetoid_un_op G.
Variable binop : binopindex -> CSetoid_bin_op G.
Variable pfun : pfunindex -> PartFunct G.

Inductive interpG : expr -> G -> CProp :=
  | interpG_var :
      forall (i : varindex) (z : G), (val i[=]z) -> interpG (expr_var i) z
  | interpG_zero : forall z : G, (z[=]Zero) -> interpG expr_zero z
  | interpG_plus :
      forall (e f : expr) (x y z : G),
      (x[+]y[=]z) -> interpG e x -> interpG f y -> interpG (expr_plus e f) z
  | interpG_mult_int :
      forall (e : expr) (k : Z) (x z : G),
      (zmult x k[=]z) -> interpG e x -> interpG (expr_mult e (expr_int k)) z
  | interpG_unop :
      forall (e : expr) (f : unopindex) (x z : G),
      (unop f x[=]z) -> interpG e x -> interpG (expr_unop f e) z
  | interpG_binop :
      forall (e e' : expr) (f : binopindex) (x y z : G),
      (binop f x y[=]z) ->
      interpG e x -> interpG e' y -> interpG (expr_binop f e e') z
  | interpG_part :
      forall (e : expr) (f : pfunindex) (x z : G) (Hx : Dom (pfun f) x),
      (pfun f x Hx[=]z) -> interpG e x -> interpG (expr_part f e) z.

Definition wfG (e : expr) := sigT (interpG e).

Inductive xexprG : G -> Type :=
  | xexprG_var : forall i : varindex, xexprG (val i)
  | xexprG_zero : xexprG Zero
  | xexprG_plus :
      forall (x y : G) (e : xexprG x) (f : xexprG y), xexprG (x[+]y)
  | xexprG_mult_int :
      forall (x : G) (k : Z) (e : xexprG x), xexprG (zmult x k)
  | xexprG_unop :
      forall (x : G) (f : unopindex) (e : xexprG x), xexprG (unop f x)
  | xexprG_binop :
      forall (x y : G) (f : binopindex) (e : xexprG x) (e' : xexprG y),
      xexprG (binop f x y)
  | xexprG_part :
      forall (x : G) (f : pfunindex) (e : xexprG x) (Hx : Dom (pfun f) x),
      xexprG (pfun f x Hx)
      (* more things rrational translates: *)
  | xexprG_inv : forall (x : G) (e : xexprG x), xexprG [--]x
  | xexprG_minus :
      forall (x y : G) (e : xexprG x) (f : xexprG y), xexprG (x[-]y).

Fixpoint xforgetG (x : G) (e : xexprG x) {struct e} : expr :=
  match e with
  | xexprG_var i => expr_var i
  | xexprG_zero => expr_zero
  | xexprG_plus _ _ e f => expr_plus (xforgetG _ e) (xforgetG _ f)
  | xexprG_mult_int _ k e => expr_mult (xforgetG _ e) (expr_int k)
  | xexprG_unop _ f e => expr_unop f (xforgetG _ e)
  | xexprG_binop _ _ f e e' => expr_binop f (xforgetG _ e) (xforgetG _ e')
  | xexprG_part _ f e _ => expr_part f (xforgetG _ e)
  | xexprG_inv _ e => expr_inv (xforgetG _ e)
  | xexprG_minus _ _ e f => expr_minus (xforgetG _ e) (xforgetG _ f)
  end.

Definition xinterpG (x : G) (e : xexprG x) := x.

Lemma xexprG2interpG :
 forall (x : G) (e : xexprG x), interpG (xforgetG _ e) x.
intros x e.
induction  e
 as
  [i|
   |
   x
   y
   e1
   Hrece1
   e0
   Hrece0|
   x
   k
   e
   Hrece|
   x
   f
   e
   Hrece|
   x
   y
   f
   e1
   Hrece1
   e0
   Hrece0|
   x
   f
   e
   Hrece
   Hx|
   x
   e
   Hrece|
   x
   y
   e1
   Hrece1
   e0
   Hrece0].

apply (interpG_var i); Algebra.

apply interpG_zero; Algebra.

apply (interpG_plus (xforgetG _ e1) (xforgetG _ e0) x y (x[+]y)); Algebra.

apply (interpG_mult_int (xforgetG _ e) k x (zmult x k)); Algebra.

apply (interpG_unop (xforgetG _ e) f x (unop f x)); Algebra.

apply (interpG_binop (xforgetG _ e1) (xforgetG _ e0) f x y (binop f x y));
 Algebra.

eapply (interpG_part (xforgetG _ e) f x (pfun f x Hx)).
 apply eq_reflexive_unfolded.
Algebra.

apply (interpG_mult_int (xforgetG _ e) (-1) x); Algebra.

apply
 (interpG_plus (xforgetG _ e1) (xforgetG _ (xexprG_inv _ e0)) x [--]y (x[-]y));
 Algebra.
apply (interpG_mult_int (xforgetG _ e0) (-1) y); Algebra.
Qed.

Definition xexprG_diagram_commutes :
  forall (x : G) (e : xexprG x), interpG (xforgetG _ e) (xinterpG _ e) :=
  xexprG2interpG.

Lemma xexprG2wfG : forall (x : G) (e : xexprG x), wfG (xforgetG _ e).
intros x e.
exists x.
apply xexprG2interpG.
Qed.

Record fexprG : Type :=  {finterpG : G; fexprG2xexprG : xexprG finterpG}.

Definition fexprG_var (i : varindex) := Build_fexprG _ (xexprG_var i).
Definition fexprG_zero := Build_fexprG _ xexprG_zero.
Definition fexprG_plus (e e' : fexprG) :=
  Build_fexprG _
    (xexprG_plus (finterpG e) (finterpG e') (fexprG2xexprG e)
       (fexprG2xexprG e')).
Definition fexprG_mult_int (e : fexprG) (k : Z) :=
  Build_fexprG _ (xexprG_mult_int (finterpG e) k (fexprG2xexprG e)).

Definition fforgetG (e : fexprG) := xforgetG (finterpG e) (fexprG2xexprG e).

Lemma fexprG2interp : forall e : fexprG, interpG (fforgetG e) (finterpG e).
intros e.
elim e. intros x e'.
unfold fforgetG in |- *. simpl in |- *.
apply xexprG2interpG.
Qed.

Lemma fexprG2wf : forall e : fexprG, wfG (fforgetG e).
intro e.
unfold fforgetG in |- *.
apply xexprG2wfG.
Qed.

Opaque csg_crr.
Opaque cm_crr.
Opaque cg_crr.
Opaque csf_fun.
Opaque csbf_fun.
Opaque csr_rel.
Opaque cs_eq.
Opaque cs_neq.
Opaque cs_ap.
Opaque cm_unit.
Opaque csg_op.
Opaque cg_inv.
Opaque cg_minus.

Lemma refl_interpG :
 forall (e : expr) (x y : G), interpG e x -> interpG e y -> x[=]y.
intro e.
induction  e
 as
  [v|
   z|
   e1
   Hrece1
   e0
   Hrece0|
   e1
   Hrece1
   e0
   Hrece0|
   e1
   Hrece1
   e0
   Hrece0|
   u
   e
   Hrece|
   b
   e1
   Hrece1
   e0
   Hrece0|
   p
   e
   Hrece].

intros x y Hx Hy.
inversion Hx.
inversion Hy.
Step_final (val v).

intros x y Hx Hy.
inversion Hx.
inversion Hy.
Step_final (Zero:G).

intros x y H1 H2.
inversion H1.
inversion H2.
astepl (x0[+]y0).
Step_final (x1[+]y1).

intros x y Hx.
inversion Hx; intro Hy; inversion Hy.
astepl (zmult x0 k). Step_final (zmult x1 k).

intros x y H0 H1.
inversion H0.

intros x y H0 H1.
inversion H0.
inversion H1.
astepl (unop u x0); Step_final (unop u x1).

intros x y H0 H1.
inversion H0.
inversion H1.
astepl (binop b x0 y0); Step_final (binop b x1 y1).

intros x y H0 H1.
inversion H0.
inversion H1.
astepl (pfun p x0 Hx); Step_final (pfun p x1 Hx0).
Qed.

Lemma interpG_wd :
 forall (e : expr) (x y : G), interpG e x -> (x[=]y) -> interpG e y.
intros e x y H H0.
inversion H; rewrite <- H2; rewrite H3 in H1.
apply interpG_var. Step_final x.
apply interpG_zero. Step_final x.
apply interpG_plus with x0 y0; auto. Step_final x.
apply interpG_mult_int with x0; auto. Step_final x.
apply interpG_unop with x0; auto. Step_final x.
apply interpG_binop with x0 y0; auto. Step_final x.
apply interpG_part with x0 Hx; auto. Step_final x.
Qed.

End Group_Interpretation_Function.

Section Group_NormCorrect.

Variable G : CAbGroup.
Variable val : varindex -> G.
Variable unop : unopindex -> CSetoid_un_op G.
Variable binop : binopindex -> CSetoid_bin_op G.
Variable pfun : pfunindex -> PartFunct G.

Notation II := (interpG G val unop binop pfun).

(*
four kinds of exprs:

  I	(expr_int _)
  V	(expr_var _)
  M	(expr_mult V M)
	I
  P	(expr_plus M P)
	I

M: sorted on V
P: sorted on M, all M's not an I
*)

Lemma MI_mult_comm_int :
 forall k z : Z,
 MI_mult (expr_int k) (expr_int z) = MI_mult (expr_int z) (expr_int k).
simple induction z;
 [ induction  k as [| p| p]
 | induction  k as [| p| p]
 | induction  k as [| p| p] ]; simpl in |- *; auto; 
 intros; rewrite Pmult_comm; auto.
Qed.

Opaque Zmult.
Lemma MI_mult_corr_G :
 forall (e f : expr) (x : G), II (expr_mult e f) x -> II (MI_mult e f) x.
intro e; case e; simpl in |- *; auto.

intros n f; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros. apply interpG_zero. inversion X. Step_final (zmult x0 0).

intros z f; case f; simpl in |- *; auto.
intro z0; case z0; simpl in |- *; auto.
  intros. inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
  apply interpG_zero. Step_final (zmult x0 0).
 intros. inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
 inversion X0. rewrite <- H3. rewrite H5 in H4.
 rewrite Zmult_comm. rewrite <- Zmult_0_r_reverse. apply interpG_zero.
 astepr (zmult (G:=G) Zero (Zpos p)). Step_final (zmult x0 (Zpos p)).
intros. inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
inversion X0. rewrite <- H3. rewrite H5 in H4.
rewrite Zmult_comm. rewrite <- Zmult_0_r_reverse. apply interpG_zero.
astepr (zmult (G:=G) Zero (Zneg p)). Step_final (zmult x0 (Zneg p)).

intros e0 e1 f; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros. inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply interpG_zero. Step_final (zmult x0 0).

intros e0 e1 f; case f; simpl in |- *; auto; try (intros; inversion X; fail).
intro z; case z; simpl in |- *; auto.
  intros. inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
  apply interpG_zero. Step_final (zmult x0 0).
 intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
 inversion X0. rewrite H3 in X1. rewrite H4 in H6. rewrite <- H5.
 simpl in |- *; apply interpG_mult_int with x1; auto.
 astepr (zmult x0 (Zpos p)). Step_final (zmult (zmult x1 k0) (Zpos p)).
intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
inversion X0. rewrite H3 in X1. rewrite H4 in H6. rewrite <- H5.
simpl in |- *; apply interpG_mult_int with x1; auto.
astepr (zmult x0 (Zneg p)). Step_final (zmult (zmult x1 k0) (Zneg p)).

intros e0 e1 f; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply interpG_zero. Step_final (zmult x0 0).

intros n e0 f x; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply interpG_zero. Step_final (zmult x0 0).

intros n e0 e1 f x; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply interpG_zero. Step_final (zmult x0 0).

intros n e0 f x; case f; simpl in |- *; auto.
intro z; case z; simpl in |- *; auto.
intros; inversion X. rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply interpG_zero. Step_final (zmult x0 0).
Qed.
Transparent Zmult.

Opaque MI_mult.
Lemma MV_mult_corr_G :
 forall (e f : expr) (x : G), II (expr_mult f e) x -> II (MV_mult e f) x.
intro e; case e; simpl in |- *; intros; inversion X.
rewrite H in X0. rewrite H1 in H2. rewrite H0 in H2.
apply MI_mult_corr_G.
apply interpG_mult_int with x0; auto.
unfold expr_one in |- *. apply interpG_mult_int with x0; Algebra.
Qed.

Opaque MV_mult.
Lemma MM_mult_corr_G :
 forall (e f : expr) (x : G),
 II (expr_mult e f) x or II (expr_mult f e) x -> II (MM_mult e f) x.
intro e; case e; simpl in |- *; intros; elim X; clear X; intro X; inversion X;
 rewrite H in X0; rewrite H0 in H2; rewrite <- H1.

apply interpG_mult_int with x0; auto.

rewrite MI_mult_comm_int.
apply MI_mult_corr_G. apply interpG_mult_int with x0; auto.

apply MI_mult_corr_G. apply interpG_mult_int with x0; auto.

apply interpG_mult_int with x0; auto.

apply MV_mult_corr_G.
inversion X0. rewrite H3 in X1. rewrite <- H5. rewrite H4 in H6.
replace (MM_mult (expr_int k0) (expr_int k)) with (expr_int (k0 * k)).
 apply interpG_mult_int with x1; auto.
 astepr (zmult x0 k). Step_final (zmult (zmult x1 k0) k).
simpl in |- *. case k0; auto; intros; rewrite Zmult_comm; auto.
inversion X0.

apply interpG_mult_int with x0; auto.

apply interpG_mult_int with x0; auto.

apply interpG_mult_int with x0; auto.
Qed.
Transparent MV_mult MI_mult.

Opaque MV_mult.
Lemma MM_plus_corr_G :
 forall (e f : expr) (x y : G), II e x -> II f y -> II (MM_plus e f) (x[+]y).
cut
 (forall (i j : Z) (x y : G),
  II (expr_int i) x -> II (expr_int j) y -> II (expr_int (i + j)) (x[+]y)).
cut
 (forall (e f : expr) (x y : G),
  II e x -> II f y -> II (expr_plus e f) (x[+]y)).
intros H H0 e; elim e.
simpl in |- *; auto.
intros z f; elim f; simpl in |- *; auto.
simpl in |- *; auto.
intros e1 H1 e2 H2.
elim e1; simpl in |- *; auto.
intros n f.
elim f; simpl in |- *; auto.
intros f1 H3 f2 H4.
elim f1; simpl in |- *; auto.
intro m.
cut (eq_nat n m = true -> n = m).
elim (eq_nat n m); simpl in |- *; auto.
intros. inversion X. rewrite H6 in X1. rewrite <- H8. rewrite H7 in H9.
inversion X0. rewrite H10 in X2. rewrite <- H12. rewrite H11 in H13.
apply MV_mult_corr_G.
simpl in |- *. apply interpG_mult_int with x0; auto.
astepr (zmult x0 k[+]zmult x1 k0).
cut (x0[=]x1); intros.
Step_final (zmult x0 k[+]zmult x0 k0).
apply refl_interpG with val unop binop pfun (expr_var n).
assumption.
rewrite (H5 (refl_equal true)). assumption.
intros; apply eq_nat_corr; auto.

intros u e0 H3 f.
elim f; simpl in |- *; auto.
intros e3 H4 e4 H5.
elim e3; simpl in |- *; auto.
intros u0 e5 H6.
cut (andb (eq_nat u u0) (eq_expr e0 e5) = true -> u = u0).
cut (andb (eq_nat u u0) (eq_expr e0 e5) = true -> e0 = e5).
elim andb; simpl in |- *; auto.
intros H' H''. intros.
inversion X. rewrite <- H7. rewrite <- H9. rewrite H8 in H10.
inversion X0. rewrite H11 in X2. rewrite <- H13. rewrite H12 in H14.
apply MV_mult_corr_G.
simpl in |- *. apply interpG_mult_int with x0; auto.
astepr (zmult x0 k[+]zmult x1 k0).
cut (x0[=]x1); intros.
Step_final (zmult x0 k[+]zmult x0 k0).
apply refl_interpG with val unop binop pfun (expr_unop u e0).
rewrite <- H7; auto. rewrite H'. rewrite H''. auto. auto. auto.
intro. elim (andb_prop _ _ H7); intros. apply eq_expr_corr; auto. 
intro. elim (andb_prop _ _ H7); intros. apply eq_nat_corr; auto.

intros u e0 H3 e3 H4 f.
elim f; simpl in |- *; auto.
intros e4 H5 e5 H6.
elim e4; simpl in |- *; auto.
intros u0 e6 H7 e7 H8.
cut
 (andb (eq_nat u u0) (andb (eq_expr e0 e6) (eq_expr e3 e7)) = true -> u = u0).
cut
 (andb (eq_nat u u0) (andb (eq_expr e0 e6) (eq_expr e3 e7)) = true -> e0 = e6).
cut
 (andb (eq_nat u u0) (andb (eq_expr e0 e6) (eq_expr e3 e7)) = true -> e3 = e7).
elim andb; simpl in |- *; auto.
intros H' H'' H'''. intros.
inversion X. rewrite <- H9. rewrite <- H11. rewrite H10 in H12.
inversion X0. rewrite H13 in X2. rewrite <- H15. rewrite H14 in H16.
apply MV_mult_corr_G.
simpl in |- *. apply interpG_mult_int with x0; auto.
astepr (zmult x0 k[+]zmult x1 k0).
cut (x0[=]x1); intros.
Step_final (zmult x0 k[+]zmult x0 k0).
apply refl_interpG with val unop binop pfun (expr_binop u e0 e3).
rewrite <- H9; auto. rewrite H'. rewrite H''. rewrite H'''. auto. auto. auto.
auto.
intro. elim (andb_prop _ _ H9); intros. elim (andb_prop _ _ H11); intros.
 apply eq_expr_corr; auto. 
intro. elim (andb_prop _ _ H9); intros. elim (andb_prop _ _ H11); intros.
 apply eq_expr_corr; auto. 
intro. elim (andb_prop _ _ H9); intros. apply eq_nat_corr; auto.

intros u e0 H3 f.
elim f; simpl in |- *; auto.
intros e3 H4 e4 H5.
elim e3; simpl in |- *; auto.
intros u0 e5 H6.
cut (andb (eq_nat u u0) (eq_expr e0 e5) = true -> u = u0).
cut (andb (eq_nat u u0) (eq_expr e0 e5) = true -> e0 = e5).
elim andb; simpl in |- *; auto.
intros H' H''. intros.
inversion X. rewrite <- H7. rewrite <- H9. rewrite H8 in H10.
inversion X0. rewrite H11 in X2. rewrite <- H13. rewrite H12 in H14.
apply MV_mult_corr_G.
simpl in |- *. apply interpG_mult_int with x0; auto.
astepr (zmult x0 k[+]zmult x1 k0).
cut (x0[=]x1); intros.
Step_final (zmult x0 k[+]zmult x0 k0).
apply refl_interpG with val unop binop pfun (expr_part u e0).
rewrite <- H7; auto. rewrite H'. rewrite H''. auto. auto. auto.
intro. elim (andb_prop _ _ H7); intros. apply eq_expr_corr; auto. 
intro. elim (andb_prop _ _ H7); intros. apply eq_nat_corr; auto.

intros. inversion X1.
intros u e0 H1 f.
elim f; simpl in |- *; auto.
intros u e0 H1 e1 H2 f.
elim f; simpl in |- *; auto.
intros u e0 H1 f.
elim f; simpl in |- *; auto.

intros; apply interpG_plus with x y; Algebra.
intros. inversion X.  rewrite H1 in H0. rewrite <- H.
inversion X0. rewrite <- H2. rewrite H4 in H3.
simpl in |- *. apply interpG_zero.
Step_final ((Zero:G)[+]Zero).
Qed.
Transparent MV_mult.

Opaque MM_plus.
Lemma PM_plus_corr_G :
 forall (e f : expr) (x y : G), II e x -> II f y -> II (PM_plus e f) (x[+]y).
cut
 (forall (e1 e2 f : expr) (x y : G),
  (forall (f : expr) (x y : G),
   II e2 x -> II f y -> II (PM_plus e2 f) (x[+]y)) ->
  II (expr_plus e1 e2) x ->
  II f y -> II (expr_plus e1 (PM_plus e2 f)) (x[+]y)).
cut
 (forall (e1 e2 f : expr) (x y : G),
  (forall (f : expr) (x y : G),
   II e2 x -> II f y -> II (PM_plus e2 f) (x[+]y)) ->
  II (expr_plus e1 e2) x -> II f y -> II (PM_plus e2 (MM_plus e1 f)) (x[+]y)).
cut
 (forall (e f : expr) (x y : G), II e x -> II f y -> II (MM_plus e f) (x[+]y)).
cut
 (forall (e f : expr) (x y : G),
  II e x -> II f y -> II (expr_plus e f) (x[+]y)).
cut
 (forall (e f : expr) (x y : G),
  II e x -> II f y -> II (expr_plus f e) (x[+]y)).
intros H H0 H1 H2 H3 e. elim e.
simpl in |- *; auto.
intros z f; elim f; intros; simpl in |- *; auto.
intros e1 H4 e2 H5 f. simpl in |- *.
elim (lt_monom e1 f); elim (eq_monom e1 f); elim f; intros; simpl in |- *;
 auto.
simpl in |- *; auto.
simpl in |- *; auto.
simpl in |- *; auto.
simpl in |- *; auto.
simpl in |- *; auto.
intros; apply interpG_wd with (y[+]x); Algebra.
apply interpG_plus with y x; Algebra.
intros; apply interpG_plus with x y; Algebra.
intros; apply MM_plus_corr_G; auto.
intros. inversion X0. rewrite H in X2. rewrite H1 in X3. rewrite <- H0.
apply interpG_wd with (y0[+](x0[+]y)).
apply X; auto.
apply MM_plus_corr_G; auto.
astepl (y0[+]x0[+]y).
Step_final (x0[+]y0[+]y).
intros. inversion X0. rewrite H in X2. rewrite H1 in X3. rewrite <- H0.
apply interpG_wd with (x0[+](y0[+]y)).
apply interpG_plus with x0 (y0[+]y); Algebra.
Step_final (x0[+]y0[+]y).
Qed.
Transparent MM_plus.

Opaque PM_plus.
Lemma PP_plus_corr_G :
 forall (e f : expr) (x y : G), II e x -> II f y -> II (PP_plus e f) (x[+]y).
cut
 (forall (e1 e2 f : expr) (x y : G),
  (forall (f : expr) (x y : G),
   II e2 x -> II f y -> II (PP_plus e2 f) (x[+]y)) ->
  II (expr_plus e1 e2) x -> II f y -> II (PM_plus (PP_plus e2 f) e1) (x[+]y)).
cut
 (forall (i : Z) (f : expr) (x y : G),
  II (expr_int i) x -> II f y -> II (PM_plus f (expr_int i)) (x[+]y)).
cut
 (forall (e f : expr) (x y : G),
  II e x -> II f y -> II (expr_plus e f) (x[+]y)).
intros H H0 H1 e.
elim e; intros; simpl in |- *; auto.
intros. apply interpG_plus with x y; Algebra.
intros. apply interpG_wd with (y[+]x); Algebra.
apply PM_plus_corr_G; auto.
intros. inversion X0. rewrite H in X2. rewrite H1 in X3. rewrite <- H0.
apply interpG_wd with (y0[+]y[+]x0).
apply PM_plus_corr_G; auto.
astepl (x0[+](y0[+]y)).
Step_final (x0[+]y0[+]y).
Qed.
Transparent PM_plus.

Opaque PM_plus MM_mult MI_mult.
Lemma PM_mult_corr_G :
 forall (e f : expr) (x : G),
 II (expr_mult e f) x or II (expr_mult f e) x -> II (PM_mult e f) x.
intro e;
 induction  e
  as
   [v|
    z|
    e1
    Hrece1
    e0
    Hrece0|
    e1
    Hrece1
    e0
    Hrece0|
    e1
    Hrece1
    e0
    Hrece0|
    u
    e
    Hrece|
    b
    e1
    Hrece1
    e0
    Hrece0|
    p
    e
    Hrece]; simpl in |- *; auto.

intros f x H; elim H; clear H; intro H; inversion H.
 rewrite H0 in X. rewrite <- H2. rewrite H1 in H3.
 apply interpG_mult_int with x0; auto.

intros f x H; elim H; clear H; intro H; inversion H.
 rewrite H0 in X. rewrite <- H2. rewrite H1 in H3.
 apply interpG_wd with (Zero[+]x); Algebra.
 apply PM_plus_corr_G. apply interpG_zero; Algebra.
 rewrite MI_mult_comm_int.
 apply MI_mult_corr_G. apply interpG_mult_int with x0; auto.
apply interpG_wd with (Zero[+]x); Algebra.
apply PM_plus_corr_G. apply interpG_zero; Algebra.
apply MI_mult_corr_G. auto.

intros f x H; elim H; clear H; intro H; inversion H.
rewrite H0 in X. rewrite <- H2. rewrite H1 in H3.
inversion X. rewrite H4 in X0. rewrite H6 in X1. rewrite H5 in H7.
apply interpG_wd with (zmult y k[+]zmult x1 k).
 2: astepl (zmult (y[+]x1) k); astepl (zmult (x1[+]y) k);
     Step_final (zmult x0 k).
apply PM_plus_corr_G.
 apply Hrece0. left. apply interpG_mult_int with y; Algebra.
apply MM_mult_corr_G; left.
apply interpG_mult_int with x1; Algebra.

intros f x H; inversion H; simpl in |- *; auto.
inversion X.

intros f x H; inversion H; simpl in |- *; auto.
inversion X.

intros f x H; inversion H; simpl in |- *; auto.
inversion X.

intros f x H; inversion H; simpl in |- *; auto.
inversion X.

intros f x H; inversion H; simpl in |- *; auto.
inversion X.
Qed.

Opaque PM_mult.
Lemma PP_mult_corr_G :
 forall (e f : expr) (x : G), II (expr_mult e f) x -> II (PP_mult e f) x.
intro e;
 induction  e
  as
   [v|
    z|
    e1
    Hrece1
    e0
    Hrece0|
    e1
    Hrece1
    e0
    Hrece0|
    e1
    Hrece1
    e0
    Hrece0|
    u
    e
    Hrece|
    b
    e1
    Hrece1
    e0
    Hrece0|
    p
    e
    Hrece]; simpl in |- *; auto.

intros f x H.
apply PM_mult_corr_G; auto.

intros f x H. inversion H. rewrite H0 in X; rewrite <- H2; rewrite <- H1.
inversion X. rewrite H4 in X0. rewrite H6 in X1. rewrite H5 in H7.
apply interpG_wd with (zmult x1 k[+]zmult y k).
 2: astepl (zmult (x1[+]y) k); Step_final (zmult x0 k).
apply PP_plus_corr_G.
 apply PM_mult_corr_G; right. apply interpG_mult_int with x1; Algebra.
apply Hrece0. apply interpG_mult_int with y; Algebra.
Qed.

Lemma NormG_corr_G : forall (e : expr) (x : G), II e x -> II (NormG e) x.
intro; elim e; intros; simpl in |- *.
apply
 (interpG_plus G val unop binop pfun (expr_mult (expr_var v) expr_one)
    expr_zero x (Zero:G) x).
Algebra.
apply (interpG_mult_int G val unop binop pfun (expr_var v) 1 x); Algebra.
apply interpG_zero; Algebra.
auto.
inversion X1. rewrite H in X2. rewrite H1 in X3. rewrite H0 in H2.
 apply interpG_wd with (x0[+]y). apply PP_plus_corr_G; auto. auto.
inversion X1. rewrite H in X2. rewrite <- H1. rewrite H0 in H2.
 simpl in |- *. apply interpG_wd with (zmult x0 k).
apply PP_mult_corr_G. apply interpG_mult_int with x0; Algebra. auto.
auto.

inversion X0. rewrite H in H2. rewrite H1 in X1. rewrite H0 in H2.
apply
 (interpG_plus G val unop binop pfun
    (expr_mult (expr_unop u (NormG e0)) expr_one) expr_zero x (
    Zero:G) x).
Algebra.
apply (interpG_mult_int G val unop binop pfun (expr_unop u (NormG e0)) 1 x);
 Algebra.
apply (interpG_unop G val unop binop pfun (NormG e0) u x0); Algebra.
apply interpG_zero; Algebra.

inversion X1. rewrite H in H3. rewrite H1 in X2. rewrite H2 in X3. rewrite H0 in H3.
apply
 (interpG_plus G val unop binop pfun
    (expr_mult (expr_binop b (NormG e0) (NormG e1)) expr_one) expr_zero x
    (Zero:G) x).
Algebra.
apply
 (interpG_mult_int G val unop binop pfun (expr_binop b (NormG e0) (NormG e1))
    1 x); Algebra.
apply (interpG_binop G val unop binop pfun (NormG e0) (NormG e1) b x0 y);
 Algebra.
apply interpG_zero; Algebra.

inversion X0. rewrite <- H. rewrite H1 in X1. rewrite H0 in H2.
apply
 (interpG_plus G val unop binop pfun
    (expr_mult (expr_part f (NormG e0)) expr_one) expr_zero x (
    Zero:G) x).
Algebra.
apply (interpG_mult_int G val unop binop pfun (expr_part f (NormG e0)) 1 x);
 Algebra.
apply (interpG_part G val unop binop pfun (NormG e0) f x0) with (Hx := Hx);
 Algebra.
apply interpG_zero; Algebra.
Qed.

Lemma Tactic_lemmaG :
 forall (x y : G) (e : xexprG G val unop binop pfun x)
   (f : xexprG G val unop binop pfun y),
 eq_expr (NormG (xforgetG _ _ _ _ _ _ e)) (NormG (xforgetG _ _ _ _ _ _ f)) =
 true -> x[=]y.
intros x y e f H.
apply refl_interpG with val unop binop pfun (NormG (xforgetG _ _ _ _ _ _ e)).
apply NormG_corr_G; apply xexprG2interpG.
rewrite (eq_expr_corr _ _ H).
apply NormG_corr_G; apply xexprG2interpG.
Qed.

End Group_NormCorrect.
(* end hide *)