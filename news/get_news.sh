#!/bin/bash
apiurl="https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=54e4865a7d78420bb7f65caf5d8e251d"
response=$(curl -s "$apiurl")

# Obtener el número total de artículos
total_articles=$(echo "$response" | jq '.articles | length')

# Generar un índice aleatorio
random_index=$(shuf -i 0-$(($total_articles - 1)) -n 1)

# Obtener los detalles del artículo aleatorio
title=$(echo "$response" | jq -r ".articles[$random_index].title")
url=$(echo "$response" | jq -r ".articles[$random_index].urlToImage")
author=$(echo "$response" | jq -r ".articles[$random_index].author")
link=$(echo "$response" | jq -r ".articles[$random_index].url")

if [ "$url" != "null" ]; then
    image_path=$(mktemp /tmp/news_image_XXXXXX.jpg)
    curl -s "$url" -o "$image_path"
else
    image_path="/home/ghost/.config/awesome/notCenter/news/notimage.png"
fi

echo "$title"
echo "$image_path"
echo "$author"
echo "$link"