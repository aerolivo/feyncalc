(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: OneLoopSimplify *)

(* :Author: Rolf Mertig *)

(* ------------------------------------------------------------------------ *)
(* :History: File created on 19 January '99 at 1:11 *)
(* ------------------------------------------------------------------------ *)

(* :Summary: OneLoopSimplify *) 

(* ------------------------------------------------------------------------ *)

BeginPackage["HighEnergyPhysics`fctools`OneLoopSimplify`",
             "HighEnergyPhysics`FeynCalc`"];

OneLoopSimplify::usage = 
"OneLoopSimplify[amp, q] simplifies the one-loop amplitude amp.
The second argument denotes the integration momentum.
If the first argument has head FeynAmp then
OneLoopSimplify[FeynAmp[name, k, expr], k] tranforms to
OneLoopSimplify[expr, k].";

OneLoopSimplify::nivar =
"The integration variable is not found in the integrand. 
Please check that the name of the second argument is 
correct.";

(* ------------------------------------------------------------------------ *)

Begin["`Private`"];
   

Contract3 = MakeContext["Contract", "Contract3"];

MakeContext[
Cases2,
ChangeDimension,
Collect2,
Collecting,
Contract,
Dimension,
DimensionalReduction,
DiracGamma,
DiracOrder,
DiracSimplify,
DiracTrick,
DotSimplify,
Expand2,
Expanding,
ExpandScalarProduct,
Explicit,
Factoring,
FeynAmp,
FeynAmpDenominator,
FeynAmpDenominatorSimplify,
FeynCalcForm,
FeynCalcInternal,
Factor2,
FeynAmpDenominatorCombine,
FinalSubstitutions,
FreeQ2,
IntegralTable,
Isolate,
MemSet,
OPE1Loop,
Pair,
Power2,
PowerSimplify,
ScalarProductCancel,
Select1,
Select2,
SUNIndex,
SUNFToTraces,
SUNNToCACF,
SUNSimplify,
SUNTrace,
TID,
Trick];

DiracTrace := DiracTrace = MakeContext["DiracTrace"];
Tr         := Tr  = MakeContext["Tr"];

write[x_String, y_] :=
 (WriteString["stdout","\n\n", x, "\n\n"];
  Print[FeynCalcForm[y]]
 ) /; $VeryVerbose > 0;

Options[OneLoopSimplify] = {Collecting -> False,
                            Dimension -> D,
                            DimensionalReduction -> False,
                            DiracSimplify -> True,
                            FinalSubstitutions -> {},
                            IntegralTable -> {},
                            OPE1Loop -> False,
                            ScalarProductCancel -> True,
                            SUNNToCACF -> True,
                            SUNTrace -> False
                           };


OneLoopSimplify[qu_ /; Head[qu]=== Symbol, amp_ /;Head[amp]=!=Symbol,
                opt___Rule] := OneLoopSimplify[amp,qu,opt] /; 
               !FreeQ[amp,qu];

OneLoopSimplify[FeynAmp[_, qu_Symbol, expr_], ___, opts___Rule] :=
 OneLoopSimplify[ expr, qu, opts];

OneLoopSimplify[amp_, qu_, opt___Rule] := 
 If[FreeQ[amp, qu], Message[OneLoopSimplify::nivar, qu]; amp,
Block[
{q, dim, sunntocacf, t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, spc,
 substis, pae, dimred,lt6, lnt6,dirsimplify, nt6,dirsimp,
 ope1loop, integraltable},

q = qu;
dim = Dimension /. {opt} /. Options[OneLoopSimplify];
dirsimplify = DiracSimplify/. {opt} /. Options[OneLoopSimplify];
dimred  = DimensionalReduction /. {opt} /. Options[OneLoopSimplify];
sunntocacf = SUNNToCACF /. {opt} /. Options[OneLoopSimplify];
suntrace = SUNTrace /. {opt} /. Options[OneLoopSimplify];
ope1loop = OPE1Loop /. {opt} /. Options[OneLoopSimplify];
substis = FinalSubstitutions /. {opt} /. Options[OneLoopSimplify];
spc = ScalarProductCancel /. {opt} /. Options[OneLoopSimplify];
integraltable = IntegralTable /. {opt} /. Options[OneLoopSimplify];

If[$VeryVerbose>1,Print["Using dimension ",dim]];

If[dimred =!= True,
   t1  = Trick[ChangeDimension[FeynCalcInternal[amp], dim]],
   t1  = Trick[FeynCalcInternal[amp]]
  ];
If[dimred =!= True, substis = ChangeDimension[substis, dim]];
t1 = FeynAmpDenominatorCombine[t1//Explicit];

If[$VeryVerbose>1,Print["FeynAmpDenominatorCombine done. t1 = ",t1]];

t1 = FeynAmpDenominatorSimplify[Collect2[t1,q,Factoring->False], q,
                                IntegralTable -> integraltable];

If[$VeryVerbose>1,Print["FeynAmpDenominatorCombine done. t1 = ",t1]];

If[!FreeQ[t1, SUNIndex],
   t2 = SUNSimplify[t1,  SUNNToCACF   -> sunntocacf, 
                         SUNTrace     -> suntrace,
                         SUNFToTraces -> False],
   t2 = t1
  ];


If[!FreeQ[t2, DiracGamma],
   t2 = DiracTrick[t2];
   t2 =  t2 /. DiracTrace -> Tr
  ];
If[$VeryVerbose > 0, Print["contracting ", t2]];
If[FreeQ2[t2, {DiracGamma, Eps}], 
   t3 = Contract3[t2],
   t3 = Contract[t2]
  ];
If[(!FreeQ[t3, DiracGamma]) && (dirsimplify === True),
   If[$VeryVerbose > 0, Print["Applying DiracSimplify on ", t3]];
   t3 = DiracSimplify[Collect2[t3, DiracGamma, Factoring -> False]];
   t3 =  t3 /. DiracTrace -> Tr
  ];

If[(!FreeQ[t3, DiracGamma]) &&  (dirsimplify === True), 
   If[$VeryVerbose > 0, Print["DiracOrdering ", t3]];
   t3 = Collect2[t3, DiracGamma, Factoring->False];
   If[Head[t3] =!= Plus,
      t3 = DiracSimplify[DiracOrder[t3]]
     ,
      t3 = Sum[DiracSimplify[t3[[iji]]//DiracOrder],{iji,Length[t3]}]
     ];
  If[$VeryVerbose > 0, Print["DiracOrdering done"]];
  ];

If[(Collecting /. {opt} /. Options[OneLoopSimplify]) === True,
   t4 = Collect2[ExpandScalarProduct[t3], q, Factoring->Factor],
   t4 = ExpandScalarProduct[t3]
  ];

If[spc =!= True, t5 = t4, 
   t5 = ScalarProductCancel[t4, q, FeynAmpDenominatorSimplify->True];
   t5 = ScalarProductCancel[t5, q, FeynAmpDenominatorSimplify->True];
   If[!FreeQ[t5, DiracGamma],
      dirsimp[z__] := dirsimp[z] = If[!FreeQ[{z}, DiracGamma], 
                                      DiracSimplify[Dot[z]], Dot[z]];
      t5 = t5 /. Dot -> dirsimp
     ]
  ];

t5 = Collect2[t5, q, Factoring->Factor];

write["after cancelling scalar products ", t5];

If[(!FreeQ[t5, OPEDelta]) && (ope1loop === True),
   t5 = Collect2[ OPE1Loop[q, t5, SUNNToCACF -> sunntocacf,
                              SUNFToTraces -> False 
                      ] /. dummyhead->Identity, q,
                  Factoring->Factor
             ]
  ];
(* XXX *)
t6 = t5;

If[$VeryVerbose > 1, Print["doing TID on",t6]];
If[Head[t6] =!= Plus, t6 = t6 + null1+null2];

nt6 = 0;
lnt6 = Length[t6];

Do[If[$VeryVerbose > 0, 
   Print["TIDPART ",ij," out of ",lnt6," le = ",Length[nt6]]];
   nt6 = nt6 + TID[t6[[ij]], q, ScalarProductCancel -> spc,
                   DimensionalReduction -> dimred,
                   FeynAmpDenominatorSimplify -> True,
                   Isolate -> True,
                   Contract -> True,
                   Collecting -> True,
		   (*Added 7/8-2000, F.Orellana*)
		   Dimension -> dim,
		   ChangeDimension -> dim
                  ];
   ,{ij, lnt6}
  ];

t6 = nt6 /. {null1 :> 0, null2 :>0};
If[$VeryVerbose > 0, Print["first TID done "]];
If[$VeryVerbose > 1, Print["expression is now ",t6]];
t6 = Collect2[t6, q, Factoring->False, Expanding->False];
If[$VeryVerbose > 0, Print["collect2 after first TID done ",Length[t6]]];
If[$VeryVerbose > 1, Print["expression is now ",t6]];

If[Head[t6] === Plus && (!FreeQ[Cases2[t6, Pair], q])
   ,
   lt6 = Length[t6];
   t6  = Sum[If[$VeryVerbose > 0, Print["TID 2 #" , j," out of " , lt6]]; 
             If[$VeryVerbose > 0, Print["dimension ",dim, " on: ", StandardForm[Select2[t6[[j]],q]]]]; 
             tmpres=Select1[t6[[j]], q]  * 
               TID[Select2[t6[[j]],q],  q,
                   ScalarProductCancel -> spc,
                   DimensionalReduction -> dimred,
                   FeynAmpDenominatorSimplify -> True,
                   Contract -> True,
                   Collecting -> True,
		   (*Added 7/8-2000, F.Orellana*)
		   Dimension -> dim,
		   ChangeDimension -> dim
                  ];
	      If[$VeryVerbose > 0, Print["got: ", tmpres,q]];
	      tmpres,
	{j, lt6}];
   If[$VeryVerbose > 1, Print["expression is now ",t6]];
   t6 = Collect2[t6, q, Factoring -> Factor];
  ];

If[$VeryVerbose > 1, Print["expression is now ",t6]];

If[Head[t6] === Plus && (!FreeQ[Cases2[t6, Pair], q])
   ,
   t6 = FixedPoint[(If[$VeryVerbose > 1,
                       Print["Applying TID on",#]];
                    TID[#,q, ScalarProductCancel -> spc,
                         DimensionalReduction -> dimred,
                         FeynAmpDenominatorSimplify -> True,
                         Contract -> True,
                         Collecting -> True,
		         (*Added 7/8-2000, F.Orellana*)
		         Dimension -> dim])&, t6, 3
               ];
  ];

If[$VeryVerbose > 0, Print["TID  returned: ",t6]];

If[!FreeQ[t6,FeynAmpDenominator],
   t6 = Select2[Expand2[t6+null1+null2,FeynAmpDenominator
                       ], FeynAmpDenominator]
  ];

If[$VeryVerbose > 0, Print["doing TID  done ", t6]];

t6 = t6 /. substis /. {null1 :> 0, null2 :> 0};
t6 = FixedPoint[ReleaseHold,t6];

If[!FreeQ[t6,DiracGamma],
If[$VeryVerbose > 0, Print["collecing after FRH in TID",t6]];
t6 = Collect2[t6, DiracGamma, Factoring -> False];
If[$VeryVerbose > 0, Print["collecing after FRH in TID done",t6]];
If[Head[t6] === Plus,
   t6 = Map[ExpandScalarProduct[DiracOrder[DiracSimplify[#]]]&, 
         t6];
   t6 = Collect2[t6, q];
   t6 = ScalarProductCancel[t6, q]
  ];
  ];

If[dimred =!= True,
   t6 = PowerSimplify[ChangeDimension[t6,dim]/.substis],
   t6 = PowerSimplify[t6]/.substis
  ];

t6 = Expand2[t6,q];
If[Head[t6] =!= Plus,
   t6 = FeynAmpDenominatorSimplify[t6, q, IntegralTable -> integraltable]
   ,
  fdisav[za_] := fdisav[za] = FeynAmpDenominatorSimplify[za,q,
                         IntegralTable -> integraltable];
  t6 = Sum[Select1[t6[[i]],q] fdisav[fdisav[Select2[t6[[i]],q]]],
           {i,Length[t6]}];
  ];
t7 = PowerSimplify[Collect2[t6, qu, Expanding->False, 
                    Factoring -> False]/.substis
                  ];
pae[a_,b_] := MemSet[pae[a,b], ExpandScalarProduct[a,b]];
t7 = t7 /. Pair -> pae /. Power2->Power;
If[LeafCount[t7]<1000, t7 = Collect2[t7, qu, Expanding->False],
            t7 = Collect2[t7,qu,Factoring->False,Expanding->False];
  ];
t7] ];

End[]; EndPackage[];
(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
If[$VeryVerbose > 0,WriteString["stdout", "OneLoopSimplify | \n "]];
Null
