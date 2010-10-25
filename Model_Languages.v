(**************************************************************************)
(*  This is part of ATBR, it is distributed under the terms of the        *)
(*         GNU Lesser General Public License version 3                    *)
(*              (see file LICENSE for more details)                       *)
(*                                                                        *)
(*       Copyright 2009-2010: Thomas Braibant, Damien Pous.               *)
(**************************************************************************)

(** Languages form a model of Kleene algebras *)

Require Import Common.
Require Import Classes.
Require Import MxGraph.
Require        Converse.
Require Import List.
Set Implicit Arguments.
Unset Strict Implicit.

Section Def.

  Context {A: Type}.

  (* a language is a predicate of words, i.e., list of letters *)
  Definition lang := list A -> Prop.
  Definition lang_equal (L L': lang): Prop := forall x, L x <-> L' x.
  Definition lang_union (L L': lang): lang := fun x => L x \/ L' x.
  Definition lang_Union I (L: I -> lang): lang := fun x => exists i, L i x.
  Definition lang_inter (L L': lang): lang := fun x => L x /\ L' x.
  Definition lang_comp  (L L': lang): lang := fun x => exists2 u, L u & exists2 v, L' v & x=u++v.
  Definition lang_conv  (L: lang): lang := fun x => L (rev x).
  Definition lang_id: lang := fun x => x=nil.
  Definition lang_empty: lang := fun x => False.
  Definition lang_top: lang := fun x => True.
  Fixpoint lang_iter (L: lang) n: lang :=
    match n with
      | 0 => lang_id
      | S n => lang_comp (lang_iter L n) L
    end.
  Definition lang_star (L: lang): lang := fun x => exists n, lang_iter L n x.

  Program Instance Lang_Graph: Graph := {
    T := unit;
    X A B := lang;
    equal A B := lang_equal
  }.
  Next Obligation.
    constructor; unfold lang_equal; repeat intro; firstorder.
  Qed.

  Instance Lang_SemiLattice_Ops: SemiLattice_Ops := {
    plus A B := lang_union;
    zero A B := lang_empty
  }.

  Instance Lang_Monoid_Ops: Monoid_Ops := {
    dot A B C := lang_comp;
    one A := lang_id
  }.
  
  Instance Lang_Star_Op: Star_Op := { 
    star A := lang_star
  }.

  Instance Lang_Converse_Op: Converse_Op := { 
    conv A B := lang_conv
  }.
  
  Transparent equal.

  Instance Lang_SemiLattice: SemiLattice.
  Proof.
    constructor; compute; firstorder.
  Qed.

  Instance Lang_ConverseSemiRing: ConverseIdemSemiRing.
  Proof.
    constructor; (exact Lang_SemiLattice || (try solve [intros; compute; firstorder])).
 
     intros ? ? ? ? L M N x. simpl. unfold lang_comp. 
      split; intros [u Hu [v Hv ->]].
       destruct Hv as [v' Hv [w Hw ->]]. repeat eexists; eauto. symmetry. apply app_ass.
       destruct Hu as [v' Hv' [w Hw ->]]. repeat eexists; eauto. apply app_ass.
     
     intros ? ? L x. simpl. unfold lang_comp.
      split; intro H.
       destruct H as [u -> [v Hv ->]]. assumption. 
       exists nil; eauto. reflexivity.

     intros ? ? L x. unfold conv, Lang_Converse_Op, lang_conv. rewrite rev_involutive. reflexivity.

     intros ? ? ? L M x. simpl. unfold conv, Lang_Converse_Op, lang_conv, lang_comp.
      split; intros [u Hu [v Hv H]].
       assert (Hx: x=rev v++rev u). rewrite <- distr_rev, <- H, rev_involutive. reflexivity.
       rewrite Hx. repeat eexists; rewrite rev_involutive; assumption.
       rewrite H, distr_rev. eauto.
  Qed.

  Definition Lang_IdemSemiRing: IdemSemiRing := Converse.CISR_ISR.  

  Notation LX := (@X Lang_Graph tt tt).

  Lemma lang_leq n m: forall (a b: @X (Lang_Graph) n m), a<==b <-> forall x, a x -> b x.
  Proof. compute. firstorder. Qed.

  Lemma lang_Union_spec I (L: I -> LX): forall L': LX, (lang_Union L: LX) <== L' <-> forall i, L i <== L'.
  Proof.
    intros. split; intro H.
    intro j. rewrite <- H. apply <- lang_leq. intros w Hw. exists j; assumption.
    apply <- lang_leq. intros w [j Hw]. setoid_rewrite lang_leq in H. eauto.
  Qed.
  
  Lemma leq_lang_Union I (L: I -> LX): forall i, L i <== lang_Union L.
  Proof.
    intros. apply -> (lang_Union_spec L). apply plus_idem.
  Qed.

  Instance Lang_ConverseKleeneAlgebra: ConverseKleeneAlgebra.
  Proof.
    constructor; 
      first [ 
        exact Lang_ConverseSemiRing |
        intros
      ].
    intros p; split; intro H.
    destruct H as [H|[u [n Hu] [v Hv H]]].
    exists O; trivial. 
    exists (S n). exists u; trivial. exists v; trivial.
    destruct H as [[|n] H].
    left; trivial.
    right. destruct H as [u Hu [v Hv H]]. exists u; trivial. exists n; trivial. exists v; trivial.
    
    apply <- lang_leq. intros w [u [n Hu] [v Hv ->]]. 
    revert u Hu v Hv. induction n; intros u Hu v Hv.
     rewrite Hu. trivial.
     destruct Hu as [x Hx [y Hy ->]].
     rewrite app_ass. apply IHn; trivial.
     apply -> lang_leq; eauto. repeat eexists; trivial. 
  Qed.

  Definition Lang_KleeneAlgebra: KleeneAlgebra := Converse.CKA_KA.  

End Def.


(** Import this module to work with languages *)
Module Load.

  Existing Instance Lang_Graph.
  Existing Instance Lang_SemiLattice_Ops.
  Existing Instance Lang_Monoid_Ops.
  Existing Instance Lang_Converse_Op.
  Existing Instance Lang_SemiLattice.
  Existing Instance Lang_Star_Op.
  Existing Instance Lang_KleeneAlgebra.
  
  Canonical Structure Lang_Graph.
  
  Transparent equal plus dot one zero star. 

  Notation LX A := (@X (@Lang_Graph A) tt tt).
  Notation LMX A n m := (@X (@mx_Graph (@Lang_Graph A)) (n,tt) (m,tt)).

  Ltac fold_LangAlg A := 
    change (@lang_equal A) with (@equal (@Lang_Graph A) tt tt); 
      change (@lang_id A) with (@one (@Lang_Graph A) (@Lang_Monoid_Ops A) tt);
        change (@lang_comp A) with (@dot (@Lang_Graph A) (@Lang_Monoid_Ops A) tt tt tt);
          change (@lang_union A) with (@plus (@Lang_Graph A) (@Lang_SemiLattice_Ops A) tt tt);
            change (@lang_empty A) with (@zero (@Lang_Graph A) (@Lang_SemiLattice_Ops A) tt tt);
              change (@lang_star A) with (@star (@Lang_Graph A) (@Lang_Star_Op A) tt).
    
End Load.

