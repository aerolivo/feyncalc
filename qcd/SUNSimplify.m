(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: SUNSimplify *)

(* :Author: Rolf Mertig *)

(* ------------------------------------------------------------------------ *)
(* :History: File created on 19 January '99 at 20:38 *)
(* ------------------------------------------------------------------------ *)

(* :Summary: SUNSimplify *)

(* ------------------------------------------------------------------------ *)

BeginPackage["HighEnergyPhysics`qcd`SUNSimplify`",
             "HighEnergyPhysics`FeynCalc`"];

SUNSimplify::usage =
"SUNSimplify simplifies products of sunt (and complex conjugated)
matrices. Renaming of dummy indices may be performed.
If the option SUNTrace is set to False, then any SUNT-matrices are
taken out of DiracTrace[...]; otherwise a color-trace is taken (by 
SUNTrace) before taking the SUN-objects in front of DiracTrace[...].
Whether SUNF is replaced by traces is determined by the option Explicit.";

(* ------------------------------------------------------------------------ *)

Begin["`Private`"];
   

(* repeat basically suntrace here, since several subfunctions are
   needed anyway 
*)

(* *********************************************************************** *)

ComplexIndex = MakeContext["ComplexIndex"];
diractrick := diractrick = MakeContext["DiracTrick"];
Trick := Trick = MakeContext["Trick"];
CA                       = MakeContext["CA"];
CF                       = MakeContext["CF"];
DiracTrace    := DiracTrace    = MakeContext["DiracTrace"];
diracgamma               = MakeContext["DiracGamma"];
dot                      = MakeContext["DOT"];
DotSimplify              = MakeContext["DotSimplify"];
Expanding                = MakeContext["Expanding"];
Expand2                  = MakeContext["Expand2"];
Explicit                 = MakeContext["Explicit"];
factoring                = MakeContext["Factoring"];
factor2                  = MakeContext["Factor2"];
factorfull               = MakeContext["FactorFull"];
fci                      = MakeContext["FeynCalcInternal"];
freeq2                   = MakeContext["FreeQ2"];
MemSet                   = MakeContext["MemSet"];
Select1                  = MakeContext["Select1"];
Select2                  = MakeContext["Select2"];
spinor                   = MakeContext["Spinor"];
SUND                     = MakeContext["SUND"];
SUNDelta                 = MakeContext["SUNDelta"];
SUNDeltaContract         = MakeContext["SUNDeltaContract"];
SUNIndex                 = MakeContext["SUNIndex"];
SUNIndexRename           = MakeContext["SUNIndexRename"];
SUNF                     = MakeContext["SUNF"];
SUNFJacobi               = MakeContext["SUNFJacobi"];
SUNNToCACF               = MakeContext["SUNNToCACF"];
sunt                     = MakeContext["SUNT"];
suntrace                 = MakeContext["SUNTrace"];
SUNN                     = MakeContext["SUNN"];

fcis[z_ /; FreeQ[z, Pattern]] := (fcis[z] = fci[z]);
(* change SUNT' which are multiplied with each other to lambdaT's *)
lambdaT[1]=1;
gm2lambdaT[]=1;
gm2lambdaT[x__]:= (gmlin@@( {x}/.sunt->lambdaT ) )/.gmlin->Dot;
(********************* linearity  ********************************* *)
(* noncomQdef : checking non-commutativity *)
noncomQ[z_]:= TrueQ[noncQ[z]];
noncQ[x_ ?NumberQ]:=True;
noncQ[x_suntrace]:=True;
noncQ[x_] := If[freeq2[FixedPoint[ReleaseHold, x], $NonComm],
                      True, False];

gmlin/: HoldPattern[gmlin[gmlin[x__]]] := gmlin[x];
gmlin[ a___, b_ c_, d___ ] := b gmlin[a,c,d]/;FreeQ[b, lambdaT] && 
                                              noncomQ[b];
gmlin[ a___, b_ , d___ ]   := b gmlin[a,d]/;FreeQ[b, lambdaT] &&
                                                noncomQ[b];
gmlin[]=1;
gellm1[x_, y__] := gellm1[x. y];
gellm2[x_, y__] := gellm2[x. y];
(******************* cyclicity *********************************** *)
gmcyc[x__] := gellm1 @@ 
              First[NestList[RotateLeft, {x}, Length[{x}]-1]//Sort];
(************* define the properties of trace of T-matrices *)
gellm2[ ] = gmcyc[ ] = SUNN;         (* unit trace  *)
(************** each single T-matrix has vanishing trace *)
gellm2[ lambdaT[_] ] := 0;
(************** Cvitanovic - rules ******************************* *)
gellm2[HoldPattern[Dot[a___, lambdaT[i_], b___, lambdaT[i_], c___]]]:=
       (1/2 gmcyc[b] gmcyc[a, c] - 1/2/SUNN gmcyc[a, b, c]
       ) /; Head[i] === SUNIndex; 

gellm2/: gellm2[HoldPattern[Dot[a___, lambdaT[i_], b___]]]^2 :=
         (1/2 gmcyc[a, b, a, b] - 1/2/SUNN gmcyc[a, b]^2
         ) /; Head[i] === SUNIndex;

gellm2/: gellm2[HoldPattern[Dot[a___, lambdaT[i_], b___]]] * 
         gellm2[HoldPattern[Dot[c___, lambdaT[i_], d___]]]:=
         (1/2 gmcyc[a, d, c, b] - 1/2/SUNN gmcyc[a, b] gmcyc[c, d]
         ) /; Head[i] === SUNIndex;

f2tr[i_,j_,k_,___]:= 
  2 I (gmcyc @@ lambdaT/@{i,k,j} - gmcyc @@ lambdaT/@{i,j,k});
(* do the application of the Cvitanovic - relations step by step *)
cvit[x_Plus] := cvit/@x;
cvit[x_]:= (cvit[x]=ExpandAll[ x /. gellm1 -> gellm2 ]);

gellm1[x_Plus]:=gellm1 /@ x;
gellm1/: gellm1[x_ y_] := x gellm1[y]/;FreeQ[x,lambdaT];
gellm1/: gellm1[x_Dot gellm1[y___]]:=gellm1[y] gellm1[x];
gellex[z_]:=gellm1[ExpandAll[z]];
fixgell[x_]:=(fixgell[x]=
FixedPoint[cvit, ( gellm1[ExpandAll[x/.suntrace->gellex/.
                   dot->gm2lambdaT/.SUNF->f2tr]]
                 )/.gellm1->gellm2, 9
          ]/.lambdaT->sunt);

(* *********************************************************************** *)

(*Renamed*)
Options[Rename] = {Expanding -> False};
SetAttributes[Rename, Listable];

Rename[exp_,ru___Rule] := Block[{new=exp,old,subst,uh,ne,uhc=0, uuh, suI,
                 expan, suh= {}, sub={}, sam, dummy = Unique["Global`c"]}, 
expan = Expanding /. {ru} /. Options[Rename];
 sam[iii_, uuh_ ] := (AppendTo[sub, SUNIndex[uuh] -> SUNIndex[iii]]
                     ) /; FreeQ[sub, SUNIndex[uuh]];
uuh[] := SUNIndex[dummy[uhc++]];
suii[0] = 0;
suii[a_Plus] := suii /@ a;
suii[y_] := Block[{ste, ste2, dumy},
                  ste = Select[y dumy, !freeq2[#, {SUNIndex}]&];
                  ste2 = Select[y dumy, freeq2[#, {SUNIndex}]&];
                  (ste2 suI[ste])/.dumy->1](* /. suI -> Identity*);

(* Added check for integers - noint. F.Orellana, 24/9-2000 *)
noint[x___] := 
    Not[Or @@ 
        Join[IntegerQ /@ {x}, IntegerQ /@
	({x} /. {SUNIndex -> Identity,
	        HighEnergyPhysics`qcd`ExplicitSUNIndex`ExplicitSUNIndex -> Identity})]];
	
subst = {suI[sunt[SUNIndex[ii_]] ff_] :>
           (sam[ii, uh[]]; (sunt[SUNIndex[ii]] (ff /. suI -> Identity)) /. 
           SUNIndex[ii]-> uh[])/;
           (!FreeQ[ff,SUNIndex[ii]]) && FreeQ[ii,dummy[_]],

        dot[ A___,sunt[SUNIndex[ii_]], B___, 
                  sunt[SUNIndex[ii_]], Z___]      :> 
           (sam[ii, uh[]];
            dot[ A,sunt[SUNIndex[ii]],B,sunt[SUNIndex[ii]],Z ] /.
               SUNIndex[ii] -> uh[] 
           ) /; FreeQ[ii, dummy[_]] , (* 
        suI[suntrace[dot[ A___,sunt[SUNIndex[jj_]], B___]] ff_]   :>
           (sam[jj, uh[]]; (sTr[dot[ A,sunt[SUNIndex[jj]],B ]] ff
                           ) /. SUNIndex[jj] -> uh[] /. sTr -> suntrace
           )/; !freeq2[ff,{SUNIndex[jj]}] && FreeQ[jj,dummy[_]], *)
        suI[dot[ A___,sunt[SUNIndex[jj_]], B___] ff_]   :>
           (sam[jj, uh[]]; (dot[ A,sunt[SUNIndex[jj]],B ] ff
                           ) /. SUNIndex[jj] -> uh[] 
           )/; !FreeQ[ff,SUNIndex[jj]] && FreeQ[jj,dummy[_]],
        suI[SUNF[A___,SUNIndex[ij_],B___] *
            SUNF[V___,SUNIndex[ij_],W___] ff_] :> 
           (sam[ij, uh[]]; (SUNF[A, SUNIndex[ij], B] *
                            SUNF[V, SUNIndex[ij], W] ff
                           )/. SUNIndex[ij] -> uh[]
           )/; FreeQ[ij, dummy[_]],
        suI[ SUNF[SUNIndex[a_], SUNIndex[ci4_], SUNIndex[ci6_]]*
             SUNF[SUNIndex[b_], SUNIndex[ci4_], SUNIndex[ci7_]]*
             SUNF[SUNIndex[c_], SUNIndex[ci6_], SUNIndex[ci7_]] ef_.
           ] :> (ef SUNN/2 SUNF[SUNIndex[a],SUNIndex[b],SUNIndex[c]]) /; noint[ci4,ci6,ci7],
        suI[ SUNF[SUNIndex[ci4_], SUNIndex[ci6_],SUNIndex[a_]]*
             SUNF[SUNIndex[ci4_], SUNIndex[ci7_],SUNIndex[b_]]*
             SUNF[SUNIndex[ci6_], SUNIndex[ci7_],SUNIndex[c_]] ef_.
           ] :> (ef SUNN/2 SUNF[SUNIndex[a],SUNIndex[b],SUNIndex[c]]) /; noint[ci4,ci6,ci7],
        suI[ SUNF[SUNIndex[a_], SUNIndex[ci4_], SUNIndex[ci6_]]*
             SUNF[SUNIndex[b_], SUNIndex[ci4_], SUNIndex[ci6_]] ef_.
           ] :> (ef SUNN SUNDelta[SUNIndex[a], SUNIndex[b]]) /; noint[ci4,ci6],
        suI[SUNF[A___,SUNIndex[ij_],B___] ff_] :> 
           (sam[ij, uh[]];(SUNF[A,SUNIndex[ij],B] ff
                          )/. SUNIndex[ij] -> uh[]
           )/; !FreeQ[ff, SUNIndex[ij]] && FreeQ[ij, dummy[_]]
          ,
        suI[SUNF[SUNIndex[a1_], SUNIndex[ci4_], SUNIndex[ci5_]]*
   SUNF[SUNIndex[a2_], SUNIndex[ci5_], SUNIndex[e_]]*
   SUNF[SUNIndex[a3_], SUNIndex[ci4_], SUNIndex[e_]] ef_.
           ] :> -ef CA/2 SUNF[SUNIndex[a1],SUNIndex[a2],SUNIndex[a3]] /; noint[ci4,ci5]
          ,
        suI[SUNF[SUNIndex[a1_], SUNIndex[ci4_], SUNIndex[ci5_]]*
   SUNF[SUNIndex[a2_], SUNIndex[ci4_], SUNIndex[e_]]*
   SUNF[SUNIndex[a3_], SUNIndex[ci5_], SUNIndex[e_]] ef_.
           ] :> ef CA/2 SUNF[SUNIndex[a1],SUNIndex[a2],SUNIndex[a3]] /; noint[ci4,ci5]
          ,
        suI[SUNF[SUNIndex[a1_], SUNIndex[ci4_], SUNIndex[ci5_]]*
   SUNF[SUNIndex[a2_], SUNIndex[a3_], SUNIndex[e_]]*
   SUNF[SUNIndex[ci4_], SUNIndex[ci5_], SUNIndex[e_]] ef_.
           ] :> ef CA SUNF[SUNIndex[a1],SUNIndex[a2],SUNIndex[a3]] /; noint[ci4,ci5]
           ,
   SUNF[a_,b_,c_]^2 :> 2CA^2 CF /; noint[a,b,c]
           ,
(* SUNDRULES*)
   SUND[a_,b_,c_]^2 :> -2 (4-CA^2) CF /; noint[a,b,c],
   SUND[a_,b_,c_] SUND[d_,b_,c_] :> -(4 - CA^2) (CA - 2 CF) SUNDelta[a,d] /; noint[b,c], 
   SUNF[a_,b_,c_] SUND[d_,b_,c_] :> 0 /; noint[b,c],
   SUNF[b_,a_,c_] SUND[d_,b_,c_] :> 0 /; noint[b,c],
   SUNF[b_,c_,a_] SUND[d_,b_,c_] :> 0 /; noint[b,c]
(*
   SUNF[a_,b_,e_] SUNF[c_,d_,e_] :>  2/SUNN SUNDelta[a,b] SUNDelta[c,d] +
   SUND[a,c,e] SUND[b,d,e] - SUND[a,d,e] SUND[b,c,e]
*)
        };
(* CHANGE 28.6. 93 *)
suff[x_] := x /; FreeQ[x, SUNIndex];
suff[x_] := FixedPoint[(uh[] = uuh[]; 
                       (suii[#]//.subst)/.suI->Identity)&, x, 42];
(*
suff[x_] := FixedPoint[(uh[] = uuh[]; 
                       (suii[#]/.subst)/.suI->Identity)&, x, 42];
*)
If[expan === True,
If[$VeryVerbose>1,Print["expanding w.r.t. sunf done "]];
new = Expand2[new, SUNIndex];
If[$VeryVerbose>1,Print["expanding w.r.t. sunf done "]];
  ];
If[Head[new] === Plus,
   new = Select1[new, SUNIndex] + suff[Select2[new, SUNIndex]],
   new = suff[new];
  ];
new = backsubfun[new, sub];
new];

backsubfun[xxx_, {}]:=xxx;
backsubfun[xxx_, {a_ -> b_, c___Rule}] := 
 If[FreeQ[xxx, b], backsubfun[xxx /. a -> b,{c}], backsubfun[xxx, {c}]];
(* *********************************************************************** *)
SetAttributes[setdel, HoldRest];
setdel[x_, y_] := SetDelayed[x, y];

setdel[
HoldPattern[sunTRACEcyc[dottt[z:sunttt[_]..]]] /.dottt->dot/.sunttt->sunt ,
sunTRACE[dot@@RotateLeft[{z}, Position[{z},Last[Sort[{z}]]][[1,1]]]]
      ];

(*SUNSimplifydef*)
SetAttributes[SUNSimplify, Listable];
Options[SUNSimplify] = {
                        Expanding    -> False,
                        Explicit     -> False,
                        factoring    -> False,
                        SUNIndexRename -> True,
                        SUNFJacobi   -> False,
                        SUNNToCACF   -> True, 
                        suntrace   -> True};

SUNSimplify[x_, opts___Rule] := FixedPoint[sunsimp[#, opts]&, x, 6];

sunsimp[x_, opts___Rule] := MemSet[sunsimp[x, opts],
           Block[{af, temp = fcis[x], sft, sunf, suntraceoption,surule,
                  diractr,doot,expan,sunsi, jac, expanding, 
                                       factoring,ntemp,dotT,
                   sunindexrename, tfac = 1},
expanding = Expanding /. {opts} /. Options[SUNSimplify];
factoring = factoring/. {opts} /. Options[SUNSimplify];
sunindexrename = SUNIndexRename /. {opts} /. Options[SUNSimplify];
af = SUNNToCACF /. {opts} /. Options[SUNSimplify];
sft = Explicit /. {opts} /. Options[SUNSimplify];
jac = SUNFJacobi /. {opts} /. Options[SUNSimplify];
suntraceoption = suntrace /. {opts} /. Options[SUNSimplify];
If[Head[temp] === Times,
   tfac = Select[temp,  freeq2[#, {SUNIndex, SUNN, CA, CF}]&];
   temp = Select[temp, !freeq2[#, {SUNIndex, SUNN, CA, CF}]&];
  ];

temp = temp /. SUNDelta -> SUNDeltaContract;

If[(!FreeQ[temp, SUNIndex]) || (!FreeQ[temp, SUNN]),
sunsi = {
         dot[xx___, sunt[a_SUNIndex],
                    sunt[a_SUNIndex], yy___] :>
         ((SUNN^2 -1)/(2 SUNN) dotT[xx,yy]) /; noint[a],
         dot[xx___, sunt[a_SUNIndex], sunt[b_SUNIndex],
                  sunt[a_SUNIndex], yy___] :>
         ((-1)/(2 SUNN) dotT[xx, sunt[b], yy]) /; noint[a],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
            dotT[aa___, sunt[xx_SUNIndex], sunt[yy_SUNIndex], 
                        sunt[zz_SUNIndex], bb___] :>
            I/2 CA CF dotT[aa,bb] /; noint[xx,yy,zz],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
            dotT[aa___, sunt[xx_SUNIndex], sunt[zz_SUNIndex], 
                        sunt[yy_SUNIndex], bb___] :>
           -I/2 CA CF dotT[aa,bb] /; noint[xx,yy,zz],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
            dotT[aa___, sunt[zz_SUNIndex], sunt[xx_SUNIndex], 
                        sunt[yy_SUNIndex], bb___] :>
            I/2 CA CF dotT[aa,bb] /; noint[xx,yy,zz],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
            dotT[aa___, sunt[yy_SUNIndex], sunt[xx_SUNIndex], 
                        sunt[zz_SUNIndex], bb___] :>
           -I/2 CA CF dotT[aa,bb] /; noint[xx,yy,zz],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
            dotT[aa___, sunt[yy_SUNIndex], sunt[zz_SUNIndex], 
                        sunt[xx_SUNIndex], bb___] :>
            I/2 CA CF dotT[aa,bb] /; noint[xx,yy,zz],

         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] * 
            dotT[aa___, sunt[zz_SUNIndex], sunt[yy_SUNIndex],
                bb___] :>
          -I/2 SUNN dotT[aa,sunt[xx],bb] /; noint[yy,zz],
         SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] * 
          dotT[aa___, sunt[yy_SUNIndex], sunt[zz_SUNIndex], bb___] :>
          I/2 SUNN dotT[aa,sunt[xx],bb] /; noint[yy,zz],
          SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
                 sunt[xx_SUNIndex]  :>
         I sunt[zz] . sunt[yy] - I sunt[yy] . sunt[zz] /; noint[xx],
          SUNF[xx_SUNIndex, yy_SUNIndex, zz_SUNIndex] *
                 sunt[zz_SUNIndex] :>
         I sunt[yy] . sunt[xx] - I sunt[xx] . sunt[yy] /; noint[zz]
         }  /. dotT[] -> 1 //. {dotT[a___,1,b___] :> dotT[a,b]} /. 
               dotT[] -> 1 /. dotT -> dot;
If[sft === True, 
   sunfL[a__] := SUNF[a, Explicit -> True];
   sundL[a__] := SUND[a, Explicit -> True]
   , 
   SetOptions[SUND, Explicit-> False];
   SetOptions[SUNF, Explicit-> False];
   sundL[a__] := SUND[a];
   sunfL[a__] := SUNF[a]
  ];

If[CheckContext["DiracGamma"],
   If[!FreeQ[temp, diracgamma], 
      temp = DotSimplify[temp,Expanding->False]];
      temp = temp /. dot[a___diracgamma, b___sunt] :>
                     (dot[a] dot[b])
  ];
If[sunindexrename === True, 
If[$VeryVerbose > 0, Print["renaming in SUNSimplify"]];
temp = Rename[temp /. sunsi , Expanding -> expanding];
If[$VeryVerbose > 0, Print["renaming in SUNSimplify done"]];
  ];

If[CheckContext["DiracTrace"],
   If[!FreeQ[temp, DiracTrace],
      If[suntraceoption === True,
       surule = {diractr[doot[xx__sunt] (dd_.) , dops___Rule] :>
                 suntrace[dot[xx] Select2[dd, SUNIndex]]*
                   DiracTrace[Select1[dd, SUNIndex], dops],
                 diractr[doot[xx__sunt, y__] (dd_.), dops___Rule] :>
                 suntrace[dot[xx] Select2[dd, SUNIndex]] *
                   DiracTrace[doot[y] Select1[dd, SUNIndex], dops ]/;
                  FreeQ[{y}, SUNIndex],
                 diractr[doot[sunt[_], dd_], ___Rule] :> 0 /; 
                  freeq2[dd,{SUNIndex,sunt}],
                 diractr[sunt[_]  dd_., ___Rule] :> 0 /; 
                  freeq2[dd,{SUNIndex,sunt}]
                },
       surule = {diractr[doot[xx__sunt] (dd_.) , dops___Rule] :>
                  dot[xx] Select2[dd, SUNIndex] *
                    DiracTrace[Select1[dd, SUNIndex], dops],
                 diractr[doot[xx__sunt, y__] (dd_.) , dops___Rule] :>
                  dot[xx] Select2[dd, SUNIndex] *
                    DiracTrace[doot[y] Select1[dd, SUNIndex], dops] /;
                   FreeQ[{y}, SUNIndex]
                }
        ];
       temp = Trick[temp] /. DiracTrace->diractr /. 
                                  dot -> doot /. surule /.
                                  doot -> dot /. diractr -> DiracTrace/.
                                  SUNDelta -> SUNDeltaContract /.
                                  SUNDeltaContract->SUNDelta
     ]
  ];

If[freeq2[temp, {suntrace}] && sft === False,
(*
   expan = Identity, expan = Expand2(*All*)[#, SUNIndex]&
*)
(*XXX*)
   expan = Identity, expan = Expand2(*All*)[#, SUNIndex]&
  ];

temp = FixedPoint[expan, temp /. suntrace -> sunTRACEcyc /.
                        dot -> gm2lambdaT /.lambdaT -> sunt /.
                        sunTRACEcyc -> suntrace /.
                     sunTRACE -> suntrace /. {SUNF :> sunfL, SUND :> sundL}
                 ];

If[jac === True && !FreeQ[temp, SUNF],
   temp = temp /. SUNF -> sUNF /.
                  (sUNF[a_, b_, c_] * sUNF[d_, c_, e_] ) ->
                   (- sUNF[a, b, c] sUNF[d, e, c]) /.
                  (sUNF[a_, b_, c_] * sUNF[c_, d_, e_] ) ->
                      (sUNF[a, b, c] sUNF[d, e, c])/.
                  { sUNF[SUNIndex[a_], SUNIndex[c_], SUNIndex[e_]]*
                    sUNF[SUNIndex[b_], SUNIndex[d_], SUNIndex[e_]] :>
                    (sUNF[SUNIndex[a], SUNIndex[b], SUNIndex[e]]* 
                     sUNF[SUNIndex[c], SUNIndex[d], SUNIndex[e]] +
                      sUNF[SUNIndex[b], SUNIndex[c], SUNIndex[e]]*
                      sUNF[SUNIndex[a], SUNIndex[d], SUNIndex[e]]
                     ) /; noint[e] && Sort[{ {a,c,e, b,d,e}, {a,b,e, c,d,e}, 
                                 {b,c,e, a,d,e} 
                               }][[1]] === {a,c,e, b,d,e}
                  } /. sUNF -> SUNF;
  ];

If[!FreeQ[temp, ComplexIndex],
   temp = temp /. dot -> dooot /. 
  {
   (sunt[SUNIndex[unfL_]] /; FreeQ[{a}, ComplexIndex]) * 
    sunt[SUNIndex[ComplexIndex[b_]]] :>
   suntrace[sunt[SUNIndex[a]] . sunt[SUNIndex[b]] ], 

   (sunt[SUNIndex[ComplexIndex[a_]]] ) * 
   dooot[(b:sunt[SUNIndex[_]]..) /; FreeQ[{b}, ComplexIndex]]  :> 
   suntrace[sunt[SUNIndex[a]] . b ], 

   (sunt[SUNIndex[a_ /; FreeQ[{a}, ComplexIndex]] ]) * 
   dooot[b:sunt[SUNIndex[ComplexIndex[_]]]..]  :> 
   suntrace[sunt[SUNIndex[a]] . b ], 

   dooot[(a:sunt[SUNIndex[_]]..) /; FreeQ[{a}, ComplexIndex]] * 
   dooot[b:sunt[SUNIndex[ComplexIndex[_]]]..] :>
   suntrace[dooot @@ Join[{a}, Reverse[{b}]/.ComplexIndex -> Identity]] 
  } /. dooot -> dot;
 ];

If[!FreeQ[temp, SUNIndex], 
   temp = temp /. sunsi;
  ];

If[expanding === True, temp = Expand[temp],
   If[LeafCount[temp] < 242 && Head[temp] === Plus, 
      ntemp = Expand[temp];
      If[LeafCount[ntemp] < LeafCount[temp], temp = ntemp]
     ];
  ];
      
If[factoring === True, temp = factor2[temp, factorfull -> False]];

 ](*thatsthemainIf*);

If[ af === True, 
    If[LeafCount[temp] < 442, temp = factor2[temp, factorfull -> False]];
    temp = temp /. (1-SUNN^2) -> (-CF 2 CA) /. 
            SUNN -> CA /. (-1 + CA^2)->(2 CA CF) /.
            (1-CA^2) -> (-2 CA CF) /.
            (1/CA) -> (CA - 2 CF) /. 
            ((1 - CA^2)*(CA - 2*CF)) -> (-2*CF) /. 
            (CA (CA-2 CF)) -> 1
    ,
    temp = temp /. CA -> SUNN /. CF -> ((SUNN^2-1)/(2 SUNN))
  ];
If[tfac =!= 1, temp = temp tfac];
temp = temp /. SUNDeltaContract -> SUNDelta;
If[!FreeQ[temp, CA], temp = temp /. (CA (CA-2 CF)) -> 1];
temp = DotSimplify[temp, Expanding -> False];
temp]];

End[]; EndPackage[];
(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
If[$VeryVerbose > 0,WriteString["stdout", "SUNSimplify | \n "]];
Null
