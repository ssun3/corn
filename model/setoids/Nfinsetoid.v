(* $Id$ *)

Require Import CSetoids.

(** **Setoids of the first [n] natural numbers
*)

Record F (n:nat):Set:=
{F_crr:> nat ;
F_prf: F_crr<n
}.

Definition Feq (n : nat) : F n -> F n -> Prop.
intros n a b.
case a.
case b.
intros x H x0 H0.
exact (x = x0).
Defined.

Definition Fap (n : nat) : F n -> F n -> CProp.
intros n a b.
case a.
case b.
intros x H x0 H0.
exact (x <> x0).
Defined.

Lemma Fap_irreflexive : forall n : nat, irreflexive (Fap n).
unfold irreflexive in |- *.
unfold Fap in |- *.
intros n x.
case x.
intuition.
red in |- *.
intuition.
Qed.

Lemma Fap_symmetric : forall n : nat, Csymmetric (Fap n).
intro n.
unfold Csymmetric in |- *.
unfold Fap in |- *.
intros x y.
case x.
case y.
intuition.
Qed.

Lemma Fap_cotransitive : forall n : nat, cotransitive (Fap n).
intro n.
unfold cotransitive in |- *.
unfold Fap in |- *.
intros x y.
case x.
case y.
intros x0 H0 x1 H1 H2 z.
case z.
intros x2 H.
set (H5 := eq_nat_dec x2 x1) in *.
elim H5.
clear H5.
intro H5.
right.
rewrite H5.
exact H2.

clear H5.
intro H5.
left. 
exact H5.
Qed.

Lemma Fap_tight : forall n : nat, tight_apart (Feq n) (Fap n).
unfold tight_apart in |- *.
unfold Fap in |- *.
unfold Feq in |- *.
intros n x y.
case x.
case y.
intros x0 H0 x1 H1.
red in |- *.
unfold not in |- *.
unfold Not in |- *.
intuition.
Qed.

Definition less (n : nat) :=
  Build_is_CSetoid (F n) (Feq n) (Fap n) (Fap_irreflexive n)
    (Fap_symmetric n) (Fap_cotransitive n) (Fap_tight n).

Definition CSetoid_of_less (n : nat) : CSetoid :=
  Build_CSetoid (F n) (Feq n) (Fap n) (less n).