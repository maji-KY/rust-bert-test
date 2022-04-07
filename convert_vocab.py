import json

vocab = {}
num = 0

with open('./vocab.txt') as f:
    for i, line in enumerate(f):
        vocab[line.split('\t')[0]] = i
        num = i

vocab['<|endoftext|>'] = num + 1

with open('./vocab.json', 'w', encoding='utf-8') as f:
    json.dump(vocab, f)
