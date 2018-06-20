chmod +x maws-linux
mv maws-linux /usr/local/bin/maws
which maws

echo 'source <(maws completion bash)' >> ~/.bashrc
source ~/.bashrc
