AES-256-GCM Encryption Tool
====

Because encrypting things in bash is hard.

# Getting Started

## Generate a AES-256-GCM `key` file

```
make generate-key
```

This will create a `key` file. Do NOT lose it as it is required to encrypt & decrypt files.

## Encrypt Your File(s)

Running `make secret=<YOUR FILE>` or `make encrypt secret=<YOUR FILE>` will generate a JSON blob/file

e.g. in `decrypt-val-encrypted.json`:

```json
{
    "salt": "60C189E7FE7F0000",
    "iv": "da301c3f6ba2142ad8108da5120b74a8",
    "value-base64-encoded": "Nw0cXjZeetA4lxHpfmuiaVg="
}
```

## Decrypt

`decrypt-val-encrypted.json` from above can be decrypted, assuming that you still have the same `key` file that was used to encrypt it present.

`make decrypt encrypted=<FILE>` will then write a new file containing the decrypted contents.

e.g.:

```
$ make decrypt encrypted=val.json-encrypted.json
# Checking for input file (encrypted=<YOUR_FILE> - generated via "make encrypt")
if [ -z "val.json-encrypted.json" ]; then exit 1; fi
# Reading encrypted metadata...
# Decrypting...
Decrypted decrypt-val.attempt.json from val.json-encrypted.json
$
$
$ cat decrypt-val.attempt.json
{"secret":"val"}
```
