#! /bin/bash

for tex in $(ls ./src); do
  pdflatex ./src/$tex
  pdflatex ./src/$tex
  mv *.pdf ./out
done

rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb

