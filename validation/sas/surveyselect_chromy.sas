/*--------------------------------------------------------------------------
  chromy x SAS PROC SURVEYSELECT (METHOD=PPS_SEQ) - roteiro de validacao
  ---------------------------------------------------------------------------
  O pacote R/Rust "chromy" (castlaboratory) implementa o metodo sequencial
  de Chromy (1979) com reposicao minima de probabilidade. Este programa roda
  o MESMO desenho no SAS, sobre o MESMO cadastro (60 unidades, embutido
  abaixo), para validacao cruzada:

    A. uma selecao detalhada (semente 20261022), com ordenacao serpentina
       por region x district x size, exportando tambem o cadastro ordenado;
    B. 2000 selecoes com sementes 100001..102000, para comparar a frequencia
       observada de hits com os ExpectedHits.

  Como cada sistema consome o proprio gerador, a comparacao e distribucional
  (e as pecas deterministicas, exatas): ExpectedHits identicos, soma dos
  hits sempre igual a n, hits sempre em {floor,ceil} do esperado, media dos
  hits convergindo ao esperado, e a ordem serpentina.

  COMO RODAR
  1. Ajuste &outdir abaixo para uma pasta sua.
  2. Submeta o programa inteiro (rodada B: ~2000 PROC SURVEYSELECT, rapido).
  3. Devolva: sas_single_run.csv, sas_sorted_frame.csv,
     sas_replications.csv e o LOG.
--------------------------------------------------------------------------*/

%let outdir = C:\temp;        /* <-- AJUSTE para uma pasta sua */
%let n      = 15;
%let nseeds = 2000;

%put NOTE: SAS &sysvlong no sistema &sysscp;

data frame;
  length unit $3 region $5 district $3;
  input unit $ region $ district $ size;
  datalines;
u01 north d03 14.644
u02 south d01 16.744
u03 north d03 14.971
u04 south d03 10.000
u05 north d02 12.150
u06 west d02 47.672
u07 west d02 20.696
u08 south d03 44.540
u09 west d03 16.310
u10 north d03 10.521
u11 south d03 10.792
u12 west d02 13.770
u13 south d02 35.165
u14 south d02 115.410
u15 west d01 21.453
u16 south d01 13.513
u17 west d03 27.270
u18 east d02 8.454
u19 east d02 24.530
u20 north d01 31.286
u21 east d03 26.056
u22 north d01 40.299
u23 south d02 41.275
u24 west d03 53.712
u25 west d01 76.864
u26 south d02 8.520
u27 north d01 22.787
u28 east d03 14.717
u29 south d02 55.914
u30 west d03 42.807
u31 east d03 35.469
u32 south d01 6.165
u33 east d02 151.626
u34 east d03 15.245
u35 south d03 20.691
u36 east d03 7.452
u37 south d02 21.379
u38 east d01 50.717
u39 west d02 25.109
u40 south d03 12.012
u41 south d03 19.528
u42 west d02 30.526
u43 north d03 2.654
u44 south d02 15.317
u45 north d03 6.075
u46 north d02 104.750
u47 south d01 21.242
u48 north d03 3.141
u49 south d03 18.832
u50 north d02 10.334
u51 south d02 38.536
u52 north d01 3.296
u53 north d03 11.923
u54 north d02 35.767
u55 east d03 19.554
u56 south d03 27.638
u57 north d02 23.244
u58 west d01 7.887
u59 south d02 7.966
u60 north d02 22.180
;
run;

/*---- A. uma selecao detalhada, com a ordenacao serpentina ----------------*/
proc surveyselect data=frame method=pps_seq n=&n seed=20261022 sort=serp
                  out=single_run outsort=sorted_frame;
  size size;
  control region district size;
run;

proc export data=single_run  outfile="&outdir./sas_single_run.csv"
  dbms=csv replace; run;
proc export data=sorted_frame outfile="&outdir./sas_sorted_frame.csv"
  dbms=csv replace; run;

/*---- B. replicacoes para a validacao distribucional ----------------------*/
proc datasets lib=work nolist; delete all_reps; quit;

%macro replicate;
  %do s = 1 %to &nseeds;
    proc surveyselect data=frame method=pps_seq n=&n seed=%eval(100000 + &s)
                      sort=serp out=_rep noprint;
      size size;
      control region district size;
    run;
    data _rep; set _rep; seed = %eval(100000 + &s); run;
    proc append base=all_reps data=_rep force; run;
  %end;
%mend replicate;
%replicate

proc export data=all_reps outfile="&outdir./sas_replications.csv"
  dbms=csv replace; run;

/*---- conferencias rapidas no proprio log ---------------------------------*/
proc sql;
  title "Soma dos hits por semente (deve ser sempre &n)";
  select min(soma) as min_hits, max(soma) as max_hits
  from (select seed, sum(NumberHits) as soma from all_reps group by seed);

  title "Hits fora de {floor,ceil} do esperado (deve ser 0)";
  select count(*) as violacoes
  from all_reps
  where NumberHits ne floor(ExpectedHits)
    and NumberHits ne ceil(ExpectedHits);
quit;
title;
