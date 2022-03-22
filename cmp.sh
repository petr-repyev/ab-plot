#!/bin/bash

# Эталонный сайт
LEFT=$1

# Название для результирующего файла
LEFT_=$(echo "$LEFT" | sed -E "s/https?:\/\/(www.)?//")
LEFT_=$(echo "$LEFT_" | sed -E "s/(\/)?$//")

# Кол-во запросов
N=10

# Конкурентность
C=2

if [ ! -f "$2" ]; then
    echo "File $2 is not readable"
    exit
fi

# Кол-во сайтов
MAX=$(wc -l $2 | awk '{print $1}' |  tr -d '\040\011\012\015')

# Лог
echo "LEFT URL: ${LEFT} -n ${N} -c ${C}"

# Счетчик строк
i=1

# AB эталона
ab -q -n ${N} -c ${C} -g LEFT.tsv ${LEFT} > /dev/null

# Сравнение доменов
while read RIGHT; do

    echo "[${i}/${MAX}] ${RIGHT}"

    ab -q -n ${N} -c ${C} -g target.tsv ${RIGHT} > /dev/null

    # PLOT-1
    echo 'set terminal png; ' \
    'set output "graph.png"; ' \
    'set title "Всего запросов: '$N', конкурентность '$C'"; ' \
    'set size 1,0.7; ' \
    'set grid y; ' \
    'set xlabel "Количество запросов"; ' \
    'set ylabel "Время ответа (милисекунды)"; ' \
    'plot "target.tsv" using 9 smooth sbezier with lines title "'$RIGHT'", ' \
    '"LEFT.tsv" using 9 smooth sbezier with lines title "'$LEFT'" ' | gnuplot -p

    # Пермеиновываем график по названию домена
    RIGHT=$(echo "$RIGHT" | sed -E "s/https?:\/\/(www.)?//")
    RIGHT=$(echo "$RIGHT" | sed -E "s/(\/)?$//")
    mv graph.png "${RIGHT}__vs__${LEFT_}.png"

    # PLOT-2
    echo 'set terminal jpeg size 500,500; ' \
    'set size 1, 1; ' \
    'set output "'$RIGHT'.jpg"; ' \
    'set title "'$RIGHT'"; ' \
    'set key left top; ' \
    'set grid y; ' \
    'set xdata time; ' \
    'set timefmt "%s"; ' \
    'set format x "%S"; ' \
    'set xlabel "сек"; ' \
    'set ylabel "время ответа (мс)"; ' \
    'set datafile separator "\t"; ' \
    'plot "target.tsv" every ::2 using 2:5 title "время ответа ('$RIGHT')" with points ' | gnuplot -p

    # CLR
    rm -rf target.tsv

    # Инкремент
    i=$((i+1))

done < $2

rm -rf LEFT.tsv