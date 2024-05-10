#!/bin/bash

function echo_time() {
    echo "======================================"
    now=`date '+%Y/%m/%d %H:%M:%S'`
    echo "[INFO] $now"
    echo "======================================"
}

function clone_repo() {
    if [ ! -d "llama.cpp/" ]; then
        git clone https://github.com/ggerganov/llama.cpp.git
    fi
}

function build_docker_image() {
    image_name="llava-cli-sample-llava-cli:latest"
    if docker image inspect "$image_name" &> /dev/null; then
        echo "Dockerイメージが既に存在します。この処理をスキップします。"
    else
        echo "Dockerイメージのビルドを行います。"
        docker-compose build
    fi
}

function download_model() {
    if [ ! -f "llama.cpp/models/$1" ]; then
        echo "モデルファイルをダウンロードします。"
        wget -O $1 --no-clobber https://huggingface.co/mys/ggml_llava-v1.5-7b/resolve/main/$1?download=true
        mv $1 llama.cpp/models/
    else
        echo "ファイルが既に存在します。ダウンロードをスキップします。"
    fi
}

INPUT_TEXT='この画像を詳細に説明してください。回答は日本語にしてください。'
IMAGE_DIR="data"
IMAGE="sample.jpg"
LLAVA_MODEL="ggml-model-q4_k.gguf"
CLIP_MODEL="mmproj-model-f16.gguf"

clone_repo
build_docker_image

download_model $LLAVA_MODEL
download_model $CLIP_MODEL

if [ ! -f "llama.cpp/$IMAGE_DIR/$IMAGE" ]; then
    echo "https://huggingface.co/rinna/bilingual-gpt-neox-4b-minigpt4/resolve/main/sample.jpg から入力画像をダウンロードします。"
    wget -O $IMAGE --no-clobber https://huggingface.co/rinna/bilingual-gpt-neox-4b-minigpt4/resolve/main/sample.jpg
    mkdir -p llama.cpp/$IMAGE_DIR/
    cp $IMAGE llama.cpp/$IMAGE_DIR/
else
    echo "すでにローカルに$IMAGEの画像ファイルがありますので、ダウンロードはスキップします。"
fi

echo "START"
echo_time
docker-compose run --rm llava-cli make
echo_time
echo "[INPUT] $INPUT_TEXT"
echo "======================================"
docker-compose run --rm llava-cli ./llava-cli -m "models/$LLAVA_MODEL" --mmproj "models/$CLIP_MODEL" --image "$IMAGE_DIR/$IMAGE" -p "$INPUT_TEXT"
echo_time
echo "END"
echo "======================================"
