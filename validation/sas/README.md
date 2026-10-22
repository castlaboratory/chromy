# Validação cruzada: chromy × SAS PROC SURVEYSELECT (METHOD=PPS_SEQ)

Roteiro para validar o pacote [`chromy`](https://castlaboratory.github.io/chromy/)
contra a implementação de referência do método de Chromy no SAS. Os dois
sistemas rodam o **mesmo desenho sobre o mesmo cadastro** (60 unidades,
embutido no programa SAS): seleção sequencial PPS com reposição mínima,
`n = 15`, ordenação serpentina por `region × district × size`, com duas
unidades de certeza (λ = 1) para exercitar a iteração de certezas.

## Para o Cristiano (lado SAS)

1. Abra `surveyselect_chromy.sas` e ajuste a primeira linha útil
   (`%let outdir = ...`) para uma pasta sua.
2. Submeta o programa inteiro. A parte B roda 2 000 `PROC SURVEYSELECT`
   com sementes 100001–102000 (rápido; poucos minutos no máximo).
3. Devolva quatro coisas: `sas_single_run.csv`, `sas_sorted_frame.csv`,
   `sas_replications.csv` e o **log** (ele imprime a versão do SAS e duas
   conferências: soma dos hits por semente e violações de reposição mínima,
   que já devem sair 15/15 e 0).

Se o `outsort=` não for aceito pela sua versão do SAS, remova só essa
opção e avise — a ordem serpentina fica de fora da comparação, o resto vale.

## O que validamos (lado R)

Com os CSVs nesta pasta, `Rscript validate.R` confere:

1. **ExpectedHits idênticos** — determinísticos, devem bater até a precisão
   de exportação (≤ 1e-8);
2. **n exato** — a soma dos hits é 15 em todas as 2 000 sementes;
3. **Reposição mínima** — todo hit em {⌊λ⌋, ⌈λ⌉};
4. **Frequência → λ** — a média dos hits de cada unidade a menos de 4 erros
   de Monte Carlo do esperado;
5. **Ordem serpentina** — posição a posição contra `serpentine_order()`.

A comparação sorteio-a-sorteio entre SAS e chromy não é possível (cada
sistema consome o próprio gerador); dentro do chromy ela existe contra o
protótipo R original (`tests/testthat/test-equivalence.R`).

## Arquivos

| arquivo | origem | conteúdo |
|---|---|---|
| `surveyselect_chromy.sas` | nós | o programa completo, cadastro embutido |
| `frame.csv` | nós | o mesmo cadastro, para o lado R |
| `chromy_reference.csv` | nós | λ e posição serpentina segundo o chromy |
| `frame_datalines.txt` | nós | as datalines (fonte do bloco no .sas) |
| `validate.R` | nós | as cinco verificações acima |
| `sas_*.csv` + log | Cristiano | as saídas do SAS |
