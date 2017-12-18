default: key

workspace=$(shell echo "$$(pwd)/.aes_256_gcm")

# actual key-file generation logic
SHELL_KEY="$(shell echo "$$AES_256_GCM_SECRET")"
ifeq (${SHELL_KEY}, "")
_generate_new_key:
	@echo "No AES_256_GCM_SECRET detected. If you need one, please run:"
	@echo "    openssl enc -aes-256-cbc -k secret -P -md sha1 | grep key= | cut -d= -f2"
	@echo "to generate a new one for testing"
	exit 1
else
_generate_new_key:
	@mkdir -p ${workspace} 2>/dev/null
	@echo "Using existing ENV Var AES_256_GCM_SECRET"
endif

# detect key file, create if DNE via logic above
key:
	@[ ! -d "${workspace}" ] && mkdir -p ${workspace} || :
	@[ ! -z ${SHELL_KEY} ] && \
	  echo "Using env-var AES_256_GCM_SECRET" \
	  || $(MAKE) _generate_new_key

# more a utility target to generate IVs for targets below
iv-path=${workspace}/iv
iv:
	# Generating Initialization Vector
	@echo ${iv-path}
	@date +%s | md5 > ${iv-path}

# meat of automations - crypto-black magicks
.PHONY: encrypt decrypt clean clean-all

# workspace specific meta files used for intermediate operations
#  - used for encrypt
encrypted-val-file=${workspace}/${secret}-encrypted
meta-file=${workspace}/meta.txt
#  - used for decrypt
enc-dat-file=${workspace}/encrypted-data

# resulting file from an encryption
json-file=${secret}-encrypted.json

clean-files=${workspace}/*-encrypted ${meta-file} ${iv-path} ${encrypted-val-file} ${enc-dat-file}
clean:
ifeq (${cleanroom}, true)
	@echo "WARNING: cleanroom=true; destroying workspace ${workspace} !!!"
	@rm -rf ${workspace}
else
	@rm ${clean-files} 2> /dev/null || :
endif

all-clean-files=${clean-files}
clean-all:
	# Cleaning ALL files...
	@$(MAKE) clean
	@rm *-decrypted *-encrypted.json 2> /dev/null || :

encrypt: key iv
	# Checking for input file (secret=<YOUR_FILE>)
	@if [ -z "${secret}" ] || [ ! -f "${secret}" ]; then echo "INVALID FILE (DNE?): ${secret}" && exit 1; fi
	# Generating secrets file
	@openssl enc -aes-256-gcm -p -salt \
	  -iv "$$(cat ${iv-path})" \
	  -K "$$AES_256_GCM_SECRET" \
	  -in ${secret} -out ${encrypted-val-file} | grep -v 'key=' > ${meta-file}
	@echo "{" > ${secret}-encrypted.json
	@echo "    \"salt\": \"$$(cat ${meta-file} |grep salt=|cut -d= -f2)\"," >> ${json-file}
	@echo "    \"iv\": \"$$(cat ${iv-path})\"," >> ${json-file}
	@echo "    \"value-base64-encoded\": \"$$(cat ${encrypted-val-file}|base64)\"" >> ${json-file}
	@echo "}" >> ${json-file}
	@$(MAKE) clean
	# Generated File:
	@cat ${json-file}
	# Path:
	@echo ${json-file}

decrypted-file=${encrypted}-decrypted
decrypt: key
	# Checking for input file (encrypted=<YOUR_FILE> - generated via "make encrypt")
	@if [ -z "${encrypted}" ] || [ ! -f "${encrypted}" ]; then echo "INVALID FILE (DNE?): ${encrypted}" && exit 1; fi
	# Reading encrypted metadata...
	@jq '.["value-base64-encoded"]' -r ${encrypted} | base64 --decode > ${enc-dat-file}
	# Decrypting...
	@[ -z ${SHELL_KEY} ] && echo "No such env-var: AES_256_GCM_SECRET" && \
		echo "You may have to run:" && \
		echo "\n    make key\n" && \
		echo "or encrypt a file (make encrypt) first!\n" && exit 1 || :
	@openssl aes-256-gcm \
	  -iv "$$(jq .iv -r ${encrypted})" \
	  -S "$$(jq .salt -r ${encrypted})" \
	  -K ${SHELL_KEY} \
	  -in ${enc-dat-file} -out ${decrypted-file}
	@$(MAKE) clean
	# Decryption cmd returned; PLEASE CHECK FILE:
	@echo ${decrypted-file}
