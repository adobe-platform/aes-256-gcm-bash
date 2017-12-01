default: encrypt

key-path="$(shell echo "$$(pwd)/key" )"
SHELL_KEY="$(shell echo "$$AES_256_GCM_SECRET")"
ifeq (${SHELL_KEY}, "")
_generate_new_key:
	@echo "Generating NEW key!"
	@openssl enc -aes-256-cbc -k secret -P -md sha1 | grep key= | cut -d= -f2 > key
	@echo "Wrote key to ${key-path}"
else
_generate_new_key:
	@echo "Using ENV Var AES_256_GCM_SECRET"
	@echo "$$AES_256_GCM_SECRET" > key
	@echo "Wrote key to ${key-path}"
endif

generate-key:
	@[ -f "${key-path}" ] && echo "${key-path} already exists, reusing!" || $(MAKE) _generate_new_key

generate-iv:
	date +%s | md5 > iv

encrypted-val-file=${secret}-encrypted
json-file=${secret}-encrypted.json
encrypt: generate-key generate-iv
	# Checking for input file (secret=<YOUR_FILE>)
	if [ -z "${secret}" ]; then exit 1; fi
	# Generating secrets file
	@openssl enc -aes-256-gcm -p -salt \
	  -iv "$$(cat iv)" \
	  -K "$$(cat key)" \
	  -in ${secret} -out ${encrypted-val-file} | grep -v 'key=' > meta.txt
	@echo "{" > ${secret}-encrypted.json
	@echo "    \"salt\": \"$$(cat meta.txt |grep salt=|cut -d= -f2)\"," >> ${json-file}
	@echo "    \"iv\": \"$$(cat iv)\"," >> ${json-file}
	@echo "    \"value-base64-encoded\": \"$$(cat ${encrypted-val-file}|base64)\"" >> ${json-file}
	@echo "}" >> ${json-file}
	@rm iv meta.txt ${encrypted-val-file}
	@echo ${json-file}
	@cat ${json-file}

decrypt:
	# Checking for input file (encrypted=<YOUR_FILE> - generated via "make encrypt")
	if [ -z "${encrypted}" ]; then exit 1; fi
	# Reading encrypted metadata...
	@jq '.["value-base64-encoded"]' -r ${encrypted} | base64 --decode > encrypted-data
	# Decrypting...
	@openssl aes-256-gcm \
	  -iv "$$(jq .iv -r ${encrypted})" \
	  -S "$$(jq .salt -r ${encrypted})" \
	  -K "$$(cat key)" \
	  -in encrypted-data -out decrypt-val.attempt.json
	@rm encrypted-data
	@echo "Decrypted decrypt-val.attempt.json from ${encrypted}"
