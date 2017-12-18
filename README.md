AES-256-GCM Encryption Tool
====

Because encrypting things in bash is hard.

# Getting Started

## Install LibreSSL (OSX)

```
brew install libressl
```

## Generate a AES-256-GCM `key` file

```
make key
```

This will create a `key` file. Do NOT lose it as it is required to encrypt & decrypt files.
If the `key` file already exists, it will use it. This target also looks @ the `AES_256_GCM_SECRET` env var too. In order of precedence:

1. `$(pwd)/key`
2. `AES_256_GCM_SECRET` env var (which then gets written to `$(pwd)/key`)
3. Generate a *NEW* one via openssl

## Encrypt Your File(s)

Running `make encrypt secret=<YOUR FILE>` will generate a JSON blob/file. This, be default, will call `generate-key` (above), so if you have a `key` file from before or not this should just work.

So given a file, this target will attempt to encrypt it and write the contents into a file named <YOUR-FILE>-encrypted.json

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
